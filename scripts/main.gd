extends Node2D

enum GameState { TITLE, PLAYING, GAME_OVER }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const PLAYER_GROUND_Y := 890.0
const TURNER_GROUND_Y := 910.0
const LEFT_HAND := Vector2(165.0, 785.0)
const RIGHT_HAND := Vector2(555.0, 785.0)
const ROPE_SWING_RADIUS := 115.0
const BASE_ROPE_SPEED := 2.35
const MAX_ROPE_SPEED := 4.8
const SPEED_GAIN_PER_SCORE := 0.075
const ROPE_CROSSING_ANGLE := 1.38
const JUMP_CUE_SECONDS := 0.34
const REQUIRED_JUMP_HEIGHT := 36.0
const CHALLENGE_START_SCORE := 10
const MAX_PATTERN_SPEED := 6.2
const DEFAULT_PLAYER_SPRITE_PATH := "res://assets/player/player.png"
const UPGRADE_BUTTON_RECT := Rect2(55.0, 1090.0, 285.0, 92.0)
const SETTINGS_BUTTON_RECT := Rect2(380.0, 1090.0, 285.0, 92.0)

@export_group("Player Sprite")
@export var player_sprite: Texture2D
@export var player_sprite_max_size := Vector2(160.0, 190.0)
@export var player_sprite_ground_offset := Vector2.ZERO

var score := 0
var best_score := 0
var rope_angle := PI
var rope_speed := BASE_ROPE_SPEED
var jump_height := 0.0
var jump_velocity := 0.0
var is_jumping := false
var jump_started_in_cue := false
var accepting_input := true
var game_state := GameState.TITLE
var challenge_pattern := 0
var flash_time := 0.0
var message := "화면을 눌러 시작"
var message_color := Color.WHITE
var menu_notice := ""


func _ready() -> void:
	if player_sprite == null and ResourceLoader.exists(DEFAULT_PLAYER_SPRITE_PATH):
		player_sprite = load(DEFAULT_PLAYER_SPRITE_PATH) as Texture2D
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	if game_state == GameState.PLAYING:
		var previous_rope_angle := rope_angle
		rope_angle = fposmod(rope_angle + _effective_rope_speed() * delta, TAU)
		if is_jumping:
			jump_velocity += 1900.0 * delta
			jump_height += jump_velocity * delta
			if jump_height >= 0.0:
				jump_height = 0.0
				jump_velocity = 0.0
				is_jumping = false
				accepting_input = true
		if _angle_crossed(previous_rope_angle, rope_angle, ROPE_CROSSING_ANGLE):
			_resolve_rope_crossing()
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var pressed := event.is_action_pressed("jump")
	var pointer_position := Vector2(-1.0, -1.0)
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pointer_position = event.position
	elif event is InputEventMouseButton:
		pointer_position = event.position
	if pressed:
		if game_state == GameState.TITLE and pointer_position.x >= 0.0:
			var design_position := _screen_to_design(pointer_position)
			if UPGRADE_BUTTON_RECT.has_point(design_position):
				menu_notice = "업그레이드 메뉴 준비 중"
				get_viewport().set_input_as_handled()
				return
			if SETTINGS_BUTTON_RECT.has_point(design_position):
				menu_notice = "설정 메뉴 준비 중"
				get_viewport().set_input_as_handled()
				return
		attempt_jump()
		get_viewport().set_input_as_handled()


func _screen_to_design(screen_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	return (screen_position - offset) / scale_factor


func attempt_jump() -> void:
	if game_state != GameState.PLAYING:
		_start_game()
		return
	if not accepting_input or is_jumping:
		return
	accepting_input = false
	is_jumping = true
	jump_started_in_cue = _is_jump_cue()
	jump_velocity = -820.0


func _resolve_rope_crossing() -> void:
	# Success is decided when the visible rope actually reaches the player's feet.
	if jump_started_in_cue and is_jumping and jump_height <= -REQUIRED_JUMP_HEIGHT:
		score += 1
		best_score = maxi(best_score, score)
		rope_speed = minf(BASE_ROPE_SPEED + score * SPEED_GAIN_PER_SCORE, MAX_ROPE_SPEED)
		_update_challenge_pattern()
		message = "좋아요!  +1"
		message_color = Color("73f7b4")
		flash_time = 0.22
		jump_started_in_cue = false
	else:
		game_state = GameState.GAME_OVER
		accepting_input = true
		message = "줄에 걸렸어요!"
		message_color = Color("ff7892")
		flash_time = 0.5


func _start_game() -> void:
	score = 0
	rope_angle = PI
	rope_speed = BASE_ROPE_SPEED
	jump_height = 0.0
	jump_velocity = 0.0
	is_jumping = false
	jump_started_in_cue = false
	accepting_input = true
	game_state = GameState.PLAYING
	challenge_pattern = 0
	menu_notice = ""
	message = "줄이 빨간색일 때 점프!"
	message_color = Color.WHITE


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)

	_draw_background()
	_draw_ground()
	# Draw the rear half first so only the parts covered by people are hidden.
	if _rope_is_behind():
		_draw_rope()
	_draw_turner(Vector2(85.0, TURNER_GROUND_Y), false)
	_draw_turner(Vector2(635.0, TURNER_GROUND_Y), true)
	_draw_player()
	# Draw the front half last so it visibly passes in front of the player.
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
	var show_jump_cue := _is_jump_cue()
	var rope_color := Color("ff334f") if show_jump_cue else Color("f6b73c")
	draw_polyline(points, Color(0, 0, 0, 0.16), 13.0, true)
	draw_polyline(points, rope_color, 8.0, true)
	draw_circle(LEFT_HAND, 7.0, Color("f6b73c"))
	draw_circle(RIGHT_HAND, 7.0, Color("f6b73c"))


func _rope_is_behind() -> bool:
	# The descending half comes toward the player; the rising half moves behind.
	return cos(rope_angle) < 0.0


func _is_jump_cue() -> bool:
	if game_state != GameState.PLAYING or rope_speed <= 0.0 or _rope_is_behind():
		return false
	var seconds_until_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_angle, TAU) / rope_speed
	return seconds_until_crossing <= JUMP_CUE_SECONDS


func _effective_rope_speed() -> float:
	# Keep a stable, fair speed throughout the red input window.
	if challenge_pattern == 0 or _is_jump_cue():
		return rope_speed

	var speed_multiplier := 1.0
	match challenge_pattern:
		1: # Off-beat: linger behind the player, then catch up in front.
			speed_multiplier = 0.58 if _rope_is_behind() else 1.18
		2: # Burst: a slow wind-up followed by a sudden approach.
			var distance_to_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_angle, TAU)
			var burst_start_distance := rope_speed * JUMP_CUE_SECONDS + 0.75
			speed_multiplier = 1.48 if distance_to_crossing < burst_start_distance else 0.72
		3: # Wave: repeatedly changes tempo during one turn.
			speed_multiplier = 0.78 + 0.42 * (0.5 + 0.5 * sin(rope_angle * 3.0))
	return minf(rope_speed * speed_multiplier, MAX_PATTERN_SPEED)


func _update_challenge_pattern() -> void:
	if score < CHALLENGE_START_SCORE:
		challenge_pattern = 0
	else:
		challenge_pattern = 1 + posmod(score - CHALLENGE_START_SCORE, 3)


func _angle_crossed(previous_angle: float, current_angle: float, target_angle: float) -> bool:
	var travelled := fposmod(current_angle - previous_angle, TAU)
	var target_distance := fposmod(target_angle - previous_angle, TAU)
	return target_distance > 0.0 and target_distance <= travelled


func _draw_turner(feet: Vector2, faces_left: bool) -> void:
	var direction := -1.0 if faces_left else 1.0
	_draw_shadow_ellipse(feet + Vector2(0, 13), Vector2(45, 13), Color(0, 0, 0, 0.2))
	# Bent knees and a forward-leaning torso keep the turners low like real helpers.
	var hip := feet + Vector2(direction * 7.0, -54.0)
	var shoulder := feet + Vector2(direction * 22.0, -91.0)
	var head := feet + Vector2(direction * 25.0, -122.0)
	var left_knee := feet + Vector2(-29.0, -29.0)
	var right_knee := feet + Vector2(29.0, -29.0)
	draw_line(feet + Vector2(-35.0, 0.0), left_knee, Color("334b73"), 15.0, true)
	draw_line(left_knee, hip + Vector2(-9.0, 0.0), Color("334b73"), 15.0, true)
	draw_line(feet + Vector2(35.0, 0.0), right_knee, Color("334b73"), 15.0, true)
	draw_line(right_knee, hip + Vector2(9.0, 0.0), Color("334b73"), 15.0, true)
	draw_line(hip, shoulder, Color("ff7a68"), 39.0, true)
	draw_circle(head, 28.0, Color("ffe0bd"))
	draw_arc(head + Vector2(0.0, -4.0), 27.0, PI, TAU, 18, Color("49382f"), 12.0, true)
	var hand := LEFT_HAND if not faces_left else RIGHT_HAND
	draw_line(shoulder + Vector2(direction * 4.0, 2.0), hand, Color("ff7a68"), 13.0, true)
	draw_circle(hand, 9.0, Color("ffe0bd"))
	draw_line(shoulder - Vector2(direction * 5.0, -2.0), feet + Vector2(-direction * 25.0, -64.0), Color("ff7a68"), 13.0, true)


func _draw_player() -> void:
	var idle_bob := sin(Time.get_ticks_msec() * 0.004) * 3.0 if game_state == GameState.TITLE else 0.0
	var p := Vector2(PLAYER_X, PLAYER_GROUND_Y + jump_height + idle_bob)
	# Shadow
	var shadow_scale := clampf(1.0 + jump_height / 650.0, 0.45, 1.0)
	_draw_shadow_ellipse(Vector2(PLAYER_X, PLAYER_GROUND_Y + 18.0), Vector2(70.0 * shadow_scale, 18.0), Color(0, 0, 0, 0.28))
	if player_sprite != null:
		_draw_player_sprite(p)
	else:
		_draw_default_player(p)


func _draw_player_sprite(feet_position: Vector2) -> void:
	var texture_size := player_sprite.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_draw_default_player(feet_position)
		return
	var sprite_scale := minf(player_sprite_max_size.x / texture_size.x, player_sprite_max_size.y / texture_size.y)
	var draw_size := texture_size * sprite_scale
	var anchored_feet := feet_position + player_sprite_ground_offset
	var draw_position := anchored_feet - Vector2(draw_size.x * 0.5, draw_size.y)
	draw_texture_rect(player_sprite, Rect2(draw_position, draw_size), false)


func _draw_default_player(p: Vector2) -> void:
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
	if game_state == GameState.TITLE:
		_draw_main_menu(font)
		return
	draw_string(font, Vector2(42, 82), "줄넘킹", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("91a4cc"))
	draw_string(font, Vector2(42, 158), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color.WHITE)
	draw_string(font, Vector2(480, 83), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffd166"))
	draw_string(font, Vector2(0, 1120), message, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 31, message_color)
	var control_text := "화면 터치 · 마우스 클릭 · SPACE"
	if game_state == GameState.GAME_OVER:
		control_text = "화면을 눌러 즉시 재시작"
	draw_string(font, Vector2(0, 1190), control_text, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("8293b7"))
	if game_state == GameState.GAME_OVER:
		draw_string(font, Vector2(0, 520), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 62, Color("ff334f"))


func _draw_main_menu(font: Font) -> void:
	draw_string(font, Vector2(0, 125), "줄넘킹", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 74, Color.WHITE)
	draw_string(font, Vector2(0, 182), "ROPE KING", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 24, Color("ffd166"))
	draw_rect(Rect2(245.0, 218.0, 230.0, 58.0), Color(0.05, 0.09, 0.17, 0.62), true)
	draw_string(font, Vector2(245.0, 257.0), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_CENTER, 230.0, 25, Color("fff0a6"))
	var pulse_alpha := 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.006)
	draw_string(font, Vector2(0, 1015), "Tap to Start", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 42, Color(1.0, 1.0, 1.0, pulse_alpha))
	_draw_menu_button(font, UPGRADE_BUTTON_RECT, "UPGRADE", "업그레이드")
	_draw_menu_button(font, SETTINGS_BUTTON_RECT, "SETTINGS", "설정")
	if not menu_notice.is_empty():
		draw_string(font, Vector2(0, 1065), menu_notice, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("ffd166"))


func _draw_menu_button(font: Font, rect: Rect2, title: String, subtitle: String) -> void:
	draw_rect(rect, Color(0.06, 0.10, 0.18, 0.88), true)
	draw_rect(rect, Color("91a4cc"), false, 4.0)
	draw_string(font, Vector2(rect.position.x, rect.position.y + 38.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 24, Color.WHITE)
	draw_string(font, Vector2(rect.position.x, rect.position.y + 70.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, Color("ffd166"))
