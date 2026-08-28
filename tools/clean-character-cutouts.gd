extends SceneTree

const CHARACTER_IDS := [
	"chef", "astronaut", "grandma_hiker", "retro_robot", "ballerina",
	"dino_onesie", "bunny_performer", "pastel_goth", "cafe_maid",
]
const ALPHA_THRESHOLD := 8.0 / 255.0
const MIN_COMPONENT_PIXELS := 24
const RELATIVE_COMPONENT_SIZE := 0.0015
const MATTE_MIN_VALUE := 0.78
const MATTE_MAX_SATURATION := 0.22
const MATTE_NEIGHBOR_MAX_VALUE := 0.68
const MATTE_SEARCH_RADIUS := 2


func _init() -> void:
	for character_id in CHARACTER_IDS:
		_clean_file("res://assets/characters/%s/idle.png" % character_id, 1)
		_clean_file("res://assets/characters/%s/jump_sheet.png" % character_id, 4)
	quit()


func _clean_file(path: String, frame_count: int) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Cannot load %s" % path)
		return
	image.convert(Image.FORMAT_RGBA8)
	var cell_width := image.get_width() / frame_count
	var removed := 0
	for frame in range(frame_count):
		var frame_rect := Rect2i(frame * cell_width, 0, cell_width, image.get_height())
		removed += _remove_small_components(image, frame_rect)
		removed += _remove_white_edge_matte(image, frame_rect)
	var absolute_path := ProjectSettings.globalize_path(path)
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("Cannot save %s: %s" % [path, error_string(error)])
	else:
		print("CLEANED %s (%d pixels removed)" % [path, removed])


func _remove_small_components(image: Image, rect: Rect2i) -> int:
	var width := image.get_width()
	var visited := PackedByteArray()
	visited.resize(image.get_width() * image.get_height())
	var components: Array[PackedVector2Array] = []
	var largest_size := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var index := y * width + x
			if visited[index] != 0:
				continue
			visited[index] = 1
			if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			var component := PackedVector2Array()
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			var cursor := 0
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				component.append(point)
				for neighbor: Vector2i in [point + Vector2i.LEFT, point + Vector2i.RIGHT, point + Vector2i.UP, point + Vector2i.DOWN]:
					if not rect.has_point(neighbor):
						continue
					var neighbor_index: int = neighbor.y * width + neighbor.x
					if visited[neighbor_index] != 0:
						continue
					visited[neighbor_index] = 1
					if image.get_pixelv(neighbor).a > ALPHA_THRESHOLD:
						queue.append(neighbor)
			components.append(component)
			largest_size = maxi(largest_size, component.size())
	var minimum_size := maxi(MIN_COMPONENT_PIXELS, int(ceil(largest_size * RELATIVE_COMPONENT_SIZE)))
	var removed := 0
	for component in components:
		if component.size() >= minimum_size:
			continue
		for point in component:
			image.set_pixelv(point, Color.TRANSPARENT)
			removed += 1
	return removed


func _remove_white_edge_matte(image: Image, rect: Rect2i) -> int:
	# Generated cutouts can retain a one-pixel white/gray matte connected to the
	# character. Component cleanup cannot see it as debris, so trim only bright,
	# low-saturation pixels that directly touch transparency. A single pass keeps
	# intentional white areas (clothes, hats and helmets) intact behind the edge.
	var to_clear := PackedVector2Array()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var color := image.get_pixel(x, y)
			if color.a <= ALPHA_THRESHOLD:
				continue
			if color.v < MATTE_MIN_VALUE or color.s > MATTE_MAX_SATURATION:
				continue
			var point := Vector2i(x, y)
			if not _has_darker_sprite_neighbor(image, rect, point):
				continue
			for neighbor: Vector2i in [point + Vector2i.LEFT, point + Vector2i.RIGHT, point + Vector2i.UP, point + Vector2i.DOWN]:
				if not rect.has_point(neighbor) or image.get_pixelv(neighbor).a <= ALPHA_THRESHOLD:
					to_clear.append(point)
					break
	for point in to_clear:
		image.set_pixelv(point, Color.TRANSPARENT)
	return to_clear.size()


func _has_darker_sprite_neighbor(image: Image, rect: Rect2i, point: Vector2i) -> bool:
	for offset_y in range(-MATTE_SEARCH_RADIUS, MATTE_SEARCH_RADIUS + 1):
		for offset_x in range(-MATTE_SEARCH_RADIUS, MATTE_SEARCH_RADIUS + 1):
			if offset_x == 0 and offset_y == 0:
				continue
			var neighbor := point + Vector2i(offset_x, offset_y)
			if not rect.has_point(neighbor):
				continue
			var neighbor_color := image.get_pixelv(neighbor)
			if neighbor_color.a > ALPHA_THRESHOLD and neighbor_color.v <= MATTE_NEIGHBOR_MAX_VALUE:
				return true
	return false
