extends Node2D

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const PLAYER_GROUND_Y := 890.0
const BASE_ROPE_SPEED := 2.35
const MAX_ROPE_SPEED := 4.8
const HIT_WINDOW := 0.38

var score := 0
var best_score := 0
var rope_angle := PI
var rope_speed := BASE_ROPE_SPEED
var jump_height := 0.0
var jump_velocity := 0.0
var is_jumping := false
var accepting_input := true
var flash_time := 0.0
var message := "화면을 눌러 점프!"
var message_color := Color.WHITE


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	rope_angle = fmod(rope_angle + rope_speed * delta, TAU)
	if is_jumping:
		jump_velocity += 1900.0 * delta
		jump_height += jump_velocity * delta
		if jump_height >= 0.0:
			jump_height = 0.0
			jump_velocity = 0.0
			is_jumping = false
			accepting_input = true
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var pressed := event.is_action_pressed("jump")
	if event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		attempt_jump()
		get_viewport().set_input_as_handled()


func attempt_jump() -> void:
	if not accepting_input or is_jumping:
		return
	accepting_input = false
	is_jumping = true
	jump_velocity = -820.0

	# The rope is dangerous while its lower half crosses the player's feet.
	var timing_error := absf(wrapf(rope_angle - PI * 0.5, -PI, PI))
	if timing_error <= HIT_WINDOW:
		score += 1
		best_score = maxi(best_score, score)
		rope_speed = minf(BASE_ROPE_SPEED + score * 0.075, MAX_ROPE_SPEED)
		message = "좋아요!  +1"
		message_color = Color("73f7b4")
		flash_time = 0.22
	else:
		score = 0
		rope_speed = BASE_ROPE_SPEED
		message = "앗! 타이밍을 맞춰보세요"
		message_color = Color("ff7892")
		flash_time = 0.3


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)

	_draw_background()
	_draw_steps()
	_draw_rope()
	_draw_player()
	_draw_hud()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("11182a"))
	for i in range(9):
		var y := float(i * 160)
		draw_circle(Vector2(90.0 + (i % 3) * 280.0, y + 55.0), 2.5, Color("6a7ca5"))
	if flash_time > 0.0:
		draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(1, 1, 1, flash_time * 0.32))


func _draw_steps() -> void:
	var scroll := float(score % 4) * 28.0
	for i in range(8):
		var step_y := 1030.0 - i * 112.0 + scroll
		var step_x := 78.0 + i * 54.0
		var width := 564.0 - i * 40.0
		var color := Color("293655") if i % 2 == 0 else Color("334363")
		draw_style_box(_step_box(color), Rect2(step_x, step_y, width, 72.0))


func _step_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 15
	box.corner_radius_top_right = 15
	box.corner_radius_bottom_left = 15
	box.corner_radius_bottom_right = 15
	return box


func _draw_rope() -> void:
	var center := Vector2(PLAYER_X, PLAYER_GROUND_Y - 118.0)
	var horizontal_radius := 215.0
	var vertical_radius := 250.0
	var points := PackedVector2Array()
	for i in range(41):
		var t := float(i) / 40.0 * TAU
		var x := center.x + cos(t) * horizontal_radius
		var depth := sin(t + rope_angle)
		var y := center.y + depth * vertical_radius
		points.append(Vector2(x, y))
	var rope_color := Color("ffd166")
	draw_polyline(points, rope_color, 9.0, true)
	draw_circle(points[0], 12.0, Color("ff9f43"))


func _draw_player() -> void:
	var p := Vector2(PLAYER_X, PLAYER_GROUND_Y + jump_height)
	# Shadow
	var shadow_scale := clampf(1.0 + jump_height / 650.0, 0.45, 1.0)
	_draw_shadow_ellipse(Vector2(PLAYER_X, PLAYER_GROUND_Y + 18.0), Vector2(70.0 * shadow_scale, 18.0), Color(0, 0, 0, 0.28))
	# Body, head, legs and arms
	draw_line(p + Vector2(0, -95), p + Vector2(0, -28), Color("62d8ff"), 28.0, true)
	draw_circle(p + Vector2(0, -132), 31.0, Color("ffe1bd"))
	draw_line(p + Vector2(-8, -32), p + Vector2(-25, 0), Color("edf5ff"), 13.0, true)
	draw_line(p + Vector2(8, -32), p + Vector2(25, 0), Color("edf5ff"), 13.0, true)
	draw_line(p + Vector2(-5, -80), p + Vector2(-60, -55), Color("62d8ff"), 13.0, true)
	draw_line(p + Vector2(5, -80), p + Vector2(60, -55), Color("62d8ff"), 13.0, true)
	draw_circle(p + Vector2(-61, -54), 9.0, Color("ff9f43"))
	draw_circle(p + Vector2(61, -54), 9.0, Color("ff9f43"))


func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var angle := float(i) / 24.0 * TAU
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(42, 82), "JUMP ROPE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("91a4cc"))
	draw_string(font, Vector2(42, 158), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color.WHITE)
	draw_string(font, Vector2(480, 83), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffd166"))
	draw_string(font, Vector2(0, 1120), message, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 31, message_color)
	draw_string(font, Vector2(0, 1190), "화면 터치 · 마우스 클릭 · SPACE", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("8293b7"))
