extends Node2D

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const PLAYER_GROUND_Y := 890.0
const TURNER_GROUND_Y := 910.0
const LEFT_HAND := Vector2(145.0, 690.0)
const RIGHT_HAND := Vector2(575.0, 690.0)
const ROPE_SWING_RADIUS := 300.0
const BASE_ROPE_SPEED := 2.35
const MAX_ROPE_SPEED := 4.8
const JUMP_TARGET_ANGLE := 0.82
const HIT_WINDOW := 0.62

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

	# Score against the same visible timing window used by the rope color.
	if _is_jump_timing():
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
	_draw_ground()
	# The upper half of the rope passes behind everyone.
	if _rope_is_behind():
		_draw_rope()
	_draw_turner(Vector2(85.0, TURNER_GROUND_Y), false)
	_draw_turner(Vector2(635.0, TURNER_GROUND_Y), true)
	_draw_player()
	# The lower half passes in front of the player, like a real long rope.
	if not _rope_is_behind():
		_draw_rope()
	_draw_hud()


func _draw_background() -> void:
	# Sky, distant clouds, and a simple park backdrop.
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("9edcff"))
	draw_circle(Vector2(610.0, 150.0), 66.0, Color("fff0a6"))
	for cloud_x in [105.0, 420.0]:
		draw_circle(Vector2(cloud_x, 210.0), 34.0, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(cloud_x + 38.0, 195.0), 43.0, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(cloud_x + 82.0, 214.0), 31.0, Color(1, 1, 1, 0.85))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 590), Vector2(135, 440), Vector2(260, 590),
		Vector2(410, 405), Vector2(590, 590), Vector2(720, 475), Vector2(720, 760), Vector2(0, 760)
	]), Color("78bd83"))
	if flash_time > 0.0:
		draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(1, 1, 1, flash_time * 0.32))


func _draw_ground() -> void:
	draw_rect(Rect2(0, 650, 720, 630), Color("75c86b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(130, 1280), Vector2(255, 650), Vector2(465, 650), Vector2(590, 1280)
	]), Color("e6c98c"))
	for x in range(35, 720, 95):
		draw_line(Vector2(x, 1010), Vector2(x + 18, 990), Color("5eae58"), 5.0, true)


func _draw_rope() -> void:
	var midpoint_y := LEFT_HAND.y + sin(rope_angle) * ROPE_SWING_RADIUS
	var points := PackedVector2Array()
	for i in range(49):
		var t := float(i) / 48.0
		var x := lerpf(LEFT_HAND.x, RIGHT_HAND.x, t)
		# 4t(1-t) is zero at both hands and one at the middle.
		var y := lerpf(LEFT_HAND.y, RIGHT_HAND.y, t) + 4.0 * t * (1.0 - t) * (midpoint_y - LEFT_HAND.y)
		points.append(Vector2(x, y))
	var rope_color := Color("ff334f") if _is_jump_timing() else Color("f6b73c")
	if _rope_is_behind():
		rope_color = Color("d9982d")
	draw_polyline(points, Color(0, 0, 0, 0.16), 13.0, true)
	draw_polyline(points, rope_color, 8.0, true)
	draw_circle(LEFT_HAND, 7.0, Color("f6b73c"))
	draw_circle(RIGHT_HAND, 7.0, Color("f6b73c"))


func _rope_is_behind() -> bool:
	return sin(rope_angle) < 0.0


func _is_jump_timing() -> bool:
	var timing_error := absf(wrapf(rope_angle - JUMP_TARGET_ANGLE, -PI, PI))
	return timing_error <= HIT_WINDOW


func _draw_turner(feet: Vector2, faces_left: bool) -> void:
	var direction := -1.0 if faces_left else 1.0
	_draw_shadow_ellipse(feet + Vector2(0, 13), Vector2(45, 13), Color(0, 0, 0, 0.2))
	# Legs, torso, head, and the arm holding the rope.
	draw_line(feet + Vector2(-10, -5), feet + Vector2(-18, -63), Color("334b73"), 15.0, true)
	draw_line(feet + Vector2(10, -5), feet + Vector2(18, -63), Color("334b73"), 15.0, true)
	draw_line(feet + Vector2(0, -62), feet + Vector2(0, -150), Color("ff7a68"), 39.0, true)
	draw_circle(feet + Vector2(0, -190), 30.0, Color("ffe0bd"))
	draw_arc(feet + Vector2(0, -195), 28.0, PI, TAU, 18, Color("49382f"), 12.0, true)
	var hand := LEFT_HAND if not faces_left else RIGHT_HAND
	draw_line(feet + Vector2(direction * 6, -135), hand, Color("ff7a68"), 13.0, true)
	draw_circle(hand, 9.0, Color("ffe0bd"))
	draw_line(feet + Vector2(-direction * 5, -132), feet + Vector2(-direction * 36, -105), Color("ff7a68"), 13.0, true)


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
	draw_string(font, Vector2(42, 82), "줄넘킹", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("91a4cc"))
	draw_string(font, Vector2(42, 158), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color.WHITE)
	draw_string(font, Vector2(480, 83), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffd166"))
	draw_string(font, Vector2(0, 1120), message, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 31, message_color)
	draw_string(font, Vector2(0, 1190), "화면 터치 · 마우스 클릭 · SPACE", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("8293b7"))
