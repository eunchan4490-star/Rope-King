extends Node2D

enum GameState { TITLE, PLAYING, HIT, GAME_OVER }
enum TurnerTeam { STUDENT, ATHLETE, SLEEPY, PRANKSTER, WIZARD }
enum TurnerTransitionPhase { NONE, TURNER_EXIT, TURNER_ENTRY_COUNTDOWN }

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const PLAYER_GROUND_Y := 890.0
const TURNER_GROUND_Y := 910.0
const LEFT_HAND := Vector2(140.0, 855.0)
const RIGHT_HAND := Vector2(580.0, 855.0)
const ROPE_OVERHEAD_RADIUS := 170.0
const ROPE_GROUND_RADIUS := 40.0
# The front half reaches the player's feet without sinking deep into the ground.
const ROPE_CROSSING_ANGLE := 0.9
const ROPE_PIXEL_GRID := 4.0
const ROPE_PIXEL_OUTLINE_SIZE := Vector2(14.0, 14.0)
const ROPE_PIXEL_CORE_SIZE := Vector2(8.0, 8.0)
const HIT_REVEAL_SECONDS := 0.42
const TURNER_CHANGE_INTERVAL := 10
const ATHLETE_NORMAL_TURNS := 2
const ATHLETE_MAX_BURST_TURNS := 2
const SLEEPY_START_SCORE := 30
const SLEEPY_MIN_SLOW_TURNS := 1
const SLEEPY_MAX_SLOW_TURNS := 3
const SLEEPY_WAKE_WARNING_SECONDS := 1.0
const SLEEPY_SLOW_MULTIPLIER := 0.34
const SLEEPY_FAST_MULTIPLIER := 2.0
const PRANKSTER_START_SCORE := 50
const ROPE_OVERHEAD_ANGLE := PI * 1.5
const PRANKSTER_STOP_SECONDS := 1.0
const PRANKSTER_REVERSE_SECONDS := 1.0
const PRANKSTER_REVERSE_SPEED_MULTIPLIER := 0.45
const PRANKSTER_MIN_NORMAL_TURNS := 1
const PRANKSTER_MAX_NORMAL_TURNS := 3
const WIZARD_START_SCORE := 70
const WIZARD_BASE_SPEED_MULTIPLIER := 0.60
const WIZARD_SPEED_MULTIPLIERS := [0.75, 1.0, 1.35, 1.8]
const WIZARD_SPEED_PAIR_TURNS := 2
const TURNER_EXIT_SECONDS := 0.7
const ATHLETE_ENTRY_SECONDS := 0.8
const COUNTDOWN_NUMBER_SECONDS := 0.65
const COUNTDOWN_GO_SECONDS := 1.0
const COUNTDOWN_TOTAL_SECONDS := COUNTDOWN_NUMBER_SECONDS * 3.0 + COUNTDOWN_GO_SECONDS
const LEFT_TURNER_FEET := Vector2(108.0, TURNER_GROUND_Y)
const RIGHT_TURNER_FEET := Vector2(612.0, TURNER_GROUND_Y)
const LEFT_TURNER_ENTRY_FEET := Vector2(-120.0, TURNER_GROUND_Y)
const RIGHT_TURNER_ENTRY_FEET := Vector2(840.0, TURNER_GROUND_Y)
const CHARACTER_ASSET_ROOT := "res://assets/characters"
const DEFAULT_BACKGROUND_PATH := "res://assets/backgrounds/neighborhood.png"
const DEFAULT_TURNER_PATH := "res://assets/turners/bowl_cut_student.png"
const ATHLETE_TURNER_PATH := "res://assets/turners/athlete_student.png"
const SLEEPY_TURNER_ASLEEP_PATH := "res://assets/turners/sleepy_student_asleep.png"
const SLEEPY_TURNER_AWAKE_PATH := "res://assets/turners/sleepy_student_awake.png"
const PRANKSTER_TURNER_PATH := "res://assets/turners/prankster_student.png"
const WIZARD_TURNER_PATH := "res://assets/turners/wizard_student.png"
const MENU_CHARACTER_TEXTURE_PATH := "res://assets/ui/menu_character.png"
const MENU_UPGRADE_TEXTURE_PATH := "res://assets/ui/menu_upgrade.png"
const MENU_SETTINGS_TEXTURE_PATH := "res://assets/ui/menu_settings.png"
const HUD_TITLE_FRAME_PATH := "res://assets/ui/title_frame.png"
const HUD_TITLE_LOGO_PATH := "res://assets/ui/title_logo.png"
const BEST_SCORE_FRAME_PATH := "res://assets/ui/best_score_frame.png"
const RESOURCE_COUNTER_FRAME_PATH := "res://assets/ui/resource_counter_frame.png"
const TAP_PROMPT_PATH := "res://assets/ui/tap_to_start.png"
const COIN_ICON_PATH := "res://assets/ui/coin_icon.png"
const RUBY_ICON_PATH := "res://assets/ui/ruby_icon.png"
const COUNTDOWN_PATHS := [
	"res://assets/ui/countdown_3.png",
	"res://assets/ui/countdown_2.png",
	"res://assets/ui/countdown_1.png",
	"res://assets/ui/countdown_go.png",
]
const DEFAULT_CHARACTER_ID := "default"
const JUMP_FRAME_COUNT := 4
const CHARACTERS_PER_PAGE := 3
const DEFAULT_BALANCE := preload("res://resources/balance/default_balance.tres")
const CHARACTER_BUTTON_RECT := Rect2(25.0, 1055.0, 210.0, 195.0)
const UPGRADE_BUTTON_RECT := Rect2(255.0, 1055.0, 210.0, 195.0)
const SETTINGS_BUTTON_RECT := Rect2(485.0, 1055.0, 210.0, 195.0)
const TEST_START_50_RECT := Rect2(555.0, 670.0, 145.0, 82.0)
const GAME_OVER_CLOSE_RECT := Rect2(548.0, 394.0, 58.0, 58.0)
const CHARACTER_PANEL_RECT := Rect2(30.0, 185.0, 660.0, 700.0)
const CHARACTER_PANEL_CLOSE_RECT := Rect2(616.0, 205.0, 52.0, 52.0)
const CHARACTER_PAGE_PREV_RECT := Rect2(242.0, 785.0, 70.0, 58.0)
const CHARACTER_PAGE_NEXT_RECT := Rect2(408.0, 785.0, 70.0, 58.0)
const CHARACTER_CARD_RECTS := [
	Rect2(52.0, 330.0, 190.0, 400.0),
	Rect2(265.0, 330.0, 190.0, 400.0),
	Rect2(478.0, 330.0, 190.0, 400.0),
]

@export_group("Player Sprite")
@export var player_sprite: Texture2D
@export var player_jump_sprite: Texture2D
@export var player_sprite_max_size := Vector2(160.0, 160.0)
@export var player_sprite_ground_offset := Vector2.ZERO
@export_group("Background")
@export var background_texture: Texture2D
@export_group("Rope Turner")
@export var turner_texture: Texture2D
@export var athlete_turner_texture: Texture2D
@export var sleepy_turner_asleep_texture: Texture2D
@export var sleepy_turner_awake_texture: Texture2D
@export var prankster_turner_texture: Texture2D
@export var wizard_turner_texture: Texture2D
@export_group("Menu Button Assets")
@export var character_button_texture: Texture2D
@export var upgrade_button_texture: Texture2D
@export var settings_button_texture: Texture2D
@export_group("HUD Title Assets")
@export var hud_title_frame_texture: Texture2D
@export var hud_title_logo_texture: Texture2D
@export var best_score_frame_texture: Texture2D
@export var resource_counter_frame_texture: Texture2D
@export var tap_prompt_texture: Texture2D
@export var coin_icon_texture: Texture2D
@export var ruby_icon_texture: Texture2D
@export_group("Game Balance")
@export var balance: RopeGameBalance = DEFAULT_BALANCE

var score := 0
var best_score := 0
var rope_angle := PI
var rope_speed := 0.0
var jump_height := 0.0
var jump_velocity := 0.0
var jump_animation_time := 0.0
var is_jumping := false
var jump_started_in_cue := false
var accepting_input := true
var game_state := GameState.TITLE
var challenge_pattern := 0
var turner_team := TurnerTeam.STUDENT
var athlete_normal_turns_remaining := 0
var athlete_burst_turns_remaining := 0
var sleepy_slow_turns_remaining := 0
var sleepy_wake_warning_time := 0.0
var sleepy_fast_turns_remaining := 0
var prankster_normal_turns_remaining := 0
var prankster_fake_pending := false
var prankster_fake_mode := 0
var prankster_fake_time := 0.0
var wizard_rope_hidden := false
var wizard_speed_multiplier := 1.0
var wizard_speed_turns_remaining := 0
var turner_transition_active := false
var turner_transition_time := 0.0
var turner_transition_phase := TurnerTransitionPhase.NONE
var departing_turner_team := TurnerTeam.STUDENT
var flash_time := 0.0
var message := "화면을 눌러 시작"
var message_color := Color.WHITE
var menu_notice := ""
var coins := 100
var gems := 0
var run_start_best := 0
var new_best_this_run := false
var feedback: RopeFeedbackManager
var save_manager: RopeSaveManager
var run_coins_earned := 0
var total_runs := 0
var total_success := 0
var hit_reveal_time := 0.0
var selected_character_id := DEFAULT_CHARACTER_ID
var player_base_region := Rect2()
var player_jump_regions: Array[Rect2] = []
var player_base_scale := 1.0
var player_jump_scale := Vector2.ONE
var character_menu_open := false
var character_preview_textures: Dictionary = {}
var character_preview_regions: Dictionary = {}
var character_ids: Array[String] = []
var character_names: Dictionary = {}
var owned_character_ids: Array[String] = []
var character_page := 0
var turner_used_region := Rect2()
var mirrored_turner_texture: Texture2D
var mirrored_turner_used_region := Rect2()
var athlete_turner_used_region := Rect2()
var mirrored_athlete_turner_texture: Texture2D
var mirrored_athlete_turner_used_region := Rect2()
var sleepy_turner_asleep_used_region := Rect2()
var mirrored_sleepy_turner_asleep_texture: Texture2D
var mirrored_sleepy_turner_asleep_used_region := Rect2()
var sleepy_turner_awake_used_region := Rect2()
var mirrored_sleepy_turner_awake_texture: Texture2D
var mirrored_sleepy_turner_awake_used_region := Rect2()
var prankster_turner_used_region := Rect2()
var mirrored_prankster_turner_texture: Texture2D
var mirrored_prankster_turner_used_region := Rect2()
var wizard_turner_used_region := Rect2()
var mirrored_wizard_turner_texture: Texture2D
var mirrored_wizard_turner_used_region := Rect2()
var character_button_used_region := Rect2()
var upgrade_button_used_region := Rect2()
var settings_button_used_region := Rect2()
var best_score_frame_used_region := Rect2()
var resource_counter_frame_used_region := Rect2()
var tap_prompt_used_region := Rect2()
var coin_icon_used_region := Rect2()
var ruby_icon_used_region := Rect2()
var countdown_textures: Array[Texture2D] = []
var countdown_used_regions: Array[Rect2] = []
var design_draw_offset := Vector2.ZERO
var design_draw_scale := 1.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	feedback = RopeFeedbackManager.new()
	add_child(feedback)
	save_manager = RopeSaveManager.new()
	add_child(save_manager)
	_load_character_catalog()
	_load_saved_progress()
	rope_speed = balance.base_rope_speed
	_load_character_visuals(selected_character_id)
	if background_texture == null and ResourceLoader.exists(DEFAULT_BACKGROUND_PATH):
		background_texture = load(DEFAULT_BACKGROUND_PATH) as Texture2D
	_prepare_turner_visuals()
	if character_button_texture == null and ResourceLoader.exists(MENU_CHARACTER_TEXTURE_PATH):
		character_button_texture = load(MENU_CHARACTER_TEXTURE_PATH) as Texture2D
	if upgrade_button_texture == null and ResourceLoader.exists(MENU_UPGRADE_TEXTURE_PATH):
		upgrade_button_texture = load(MENU_UPGRADE_TEXTURE_PATH) as Texture2D
	if settings_button_texture == null and ResourceLoader.exists(MENU_SETTINGS_TEXTURE_PATH):
		settings_button_texture = load(MENU_SETTINGS_TEXTURE_PATH) as Texture2D
	if hud_title_frame_texture == null and ResourceLoader.exists(HUD_TITLE_FRAME_PATH):
		hud_title_frame_texture = load(HUD_TITLE_FRAME_PATH) as Texture2D
	if hud_title_logo_texture == null and ResourceLoader.exists(HUD_TITLE_LOGO_PATH):
		hud_title_logo_texture = load(HUD_TITLE_LOGO_PATH) as Texture2D
	if best_score_frame_texture == null and ResourceLoader.exists(BEST_SCORE_FRAME_PATH):
		best_score_frame_texture = load(BEST_SCORE_FRAME_PATH) as Texture2D
	if resource_counter_frame_texture == null and ResourceLoader.exists(RESOURCE_COUNTER_FRAME_PATH):
		resource_counter_frame_texture = load(RESOURCE_COUNTER_FRAME_PATH) as Texture2D
	if tap_prompt_texture == null and ResourceLoader.exists(TAP_PROMPT_PATH):
		tap_prompt_texture = load(TAP_PROMPT_PATH) as Texture2D
	if coin_icon_texture == null and ResourceLoader.exists(COIN_ICON_PATH):
		coin_icon_texture = load(COIN_ICON_PATH) as Texture2D
	if ruby_icon_texture == null and ResourceLoader.exists(RUBY_ICON_PATH):
		ruby_icon_texture = load(RUBY_ICON_PATH) as Texture2D
	character_button_used_region = _texture_used_region(character_button_texture)
	upgrade_button_used_region = _texture_used_region(upgrade_button_texture)
	settings_button_used_region = _texture_used_region(settings_button_texture)
	best_score_frame_used_region = _texture_used_region(best_score_frame_texture)
	resource_counter_frame_used_region = _texture_used_region(resource_counter_frame_texture)
	tap_prompt_used_region = _texture_used_region(tap_prompt_texture)
	coin_icon_used_region = _texture_used_region(coin_icon_texture)
	ruby_icon_used_region = _texture_used_region(ruby_icon_texture)
	_prepare_countdown_visuals()
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()


func _prepare_turner_visuals() -> void:
	if turner_texture == null and ResourceLoader.exists(DEFAULT_TURNER_PATH):
		turner_texture = load(DEFAULT_TURNER_PATH) as Texture2D
	if turner_texture != null:
		turner_used_region = _texture_used_region(turner_texture)
		var turner_image := turner_texture.get_image()
		if turner_image != null and not turner_image.is_empty():
			var mirrored_image := turner_image.duplicate()
			mirrored_image.flip_x()
			mirrored_turner_texture = ImageTexture.create_from_image(mirrored_image)
			mirrored_turner_used_region = _texture_used_region(mirrored_turner_texture)
	if athlete_turner_texture == null and ResourceLoader.exists(ATHLETE_TURNER_PATH):
		athlete_turner_texture = load(ATHLETE_TURNER_PATH) as Texture2D
	if athlete_turner_texture != null:
		athlete_turner_used_region = _texture_used_region(athlete_turner_texture)
		var athlete_image := athlete_turner_texture.get_image()
		if athlete_image != null and not athlete_image.is_empty():
			var mirrored_athlete_image := athlete_image.duplicate()
			mirrored_athlete_image.flip_x()
			mirrored_athlete_turner_texture = ImageTexture.create_from_image(mirrored_athlete_image)
			mirrored_athlete_turner_used_region = _texture_used_region(mirrored_athlete_turner_texture)
	if sleepy_turner_asleep_texture == null and ResourceLoader.exists(SLEEPY_TURNER_ASLEEP_PATH):
		sleepy_turner_asleep_texture = load(SLEEPY_TURNER_ASLEEP_PATH) as Texture2D
	if sleepy_turner_asleep_texture != null:
		sleepy_turner_asleep_used_region = _texture_used_region(sleepy_turner_asleep_texture)
		var asleep_image := sleepy_turner_asleep_texture.get_image()
		if asleep_image != null and not asleep_image.is_empty():
			var mirrored_asleep_image := asleep_image.duplicate()
			mirrored_asleep_image.flip_x()
			mirrored_sleepy_turner_asleep_texture = ImageTexture.create_from_image(mirrored_asleep_image)
			mirrored_sleepy_turner_asleep_used_region = _texture_used_region(mirrored_sleepy_turner_asleep_texture)
	if sleepy_turner_awake_texture == null and ResourceLoader.exists(SLEEPY_TURNER_AWAKE_PATH):
		sleepy_turner_awake_texture = load(SLEEPY_TURNER_AWAKE_PATH) as Texture2D
	if sleepy_turner_awake_texture != null:
		sleepy_turner_awake_used_region = _texture_used_region(sleepy_turner_awake_texture)
		var awake_image := sleepy_turner_awake_texture.get_image()
		if awake_image != null and not awake_image.is_empty():
			var mirrored_awake_image := awake_image.duplicate()
			mirrored_awake_image.flip_x()
			mirrored_sleepy_turner_awake_texture = ImageTexture.create_from_image(mirrored_awake_image)
			mirrored_sleepy_turner_awake_used_region = _texture_used_region(mirrored_sleepy_turner_awake_texture)
	if prankster_turner_texture == null and ResourceLoader.exists(PRANKSTER_TURNER_PATH):
		prankster_turner_texture = load(PRANKSTER_TURNER_PATH) as Texture2D
	if prankster_turner_texture != null:
		prankster_turner_used_region = _texture_used_region(prankster_turner_texture)
		var prankster_image := prankster_turner_texture.get_image()
		if prankster_image != null and not prankster_image.is_empty():
			var mirrored_prankster_image := prankster_image.duplicate()
			mirrored_prankster_image.flip_x()
			mirrored_prankster_turner_texture = ImageTexture.create_from_image(mirrored_prankster_image)
			mirrored_prankster_turner_used_region = _texture_used_region(mirrored_prankster_turner_texture)
	if wizard_turner_texture == null and ResourceLoader.exists(WIZARD_TURNER_PATH):
		wizard_turner_texture = load(WIZARD_TURNER_PATH) as Texture2D
	if wizard_turner_texture != null:
		wizard_turner_used_region = _texture_used_region(wizard_turner_texture)
		var wizard_image := wizard_turner_texture.get_image()
		if wizard_image != null and not wizard_image.is_empty():
			var mirrored_wizard_image := wizard_image.duplicate()
			mirrored_wizard_image.flip_x()
			mirrored_wizard_turner_texture = ImageTexture.create_from_image(mirrored_wizard_image)
			mirrored_wizard_turner_used_region = _texture_used_region(mirrored_wizard_turner_texture)


func _prepare_countdown_visuals() -> void:
	countdown_textures.clear()
	countdown_used_regions.clear()
	for path in COUNTDOWN_PATHS:
		var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
		countdown_textures.append(texture)
		countdown_used_regions.append(_texture_used_region(texture))


func _process(delta: float) -> void:
	if game_state == GameState.PLAYING:
		if is_jumping:
			jump_animation_time += delta
			jump_velocity += 1900.0 * delta
			jump_height += jump_velocity * delta
			if jump_height >= 0.0:
				jump_height = 0.0
				jump_velocity = 0.0
				jump_animation_time = 0.0
				is_jumping = false
				accepting_input = not turner_transition_active
		if turner_transition_active:
			accepting_input = false
			_advance_turner_transition(delta)
		else:
			_update_sleepy_warning(delta)
			if _update_prankster_fake(delta):
				queue_redraw()
				return
			var previous_rope_angle := rope_angle
			rope_angle = fposmod(rope_angle + _effective_rope_speed() * delta, TAU)
			if _angle_crossed(previous_rope_angle, rope_angle, ROPE_CROSSING_ANGLE):
				_resolve_rope_crossing()
	elif game_state == GameState.HIT:
		hit_reveal_time -= delta
		if hit_reveal_time <= 0.0:
			game_state = GameState.GAME_OVER
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()


func _advance_turner_transition(delta: float) -> void:
	turner_transition_time += delta
	if turner_transition_phase == TurnerTransitionPhase.TURNER_EXIT and turner_transition_time >= TURNER_EXIT_SECONDS:
		turner_transition_time -= TURNER_EXIT_SECONDS
		turner_transition_phase = TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN
	if turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN and turner_transition_time >= COUNTDOWN_TOTAL_SECONDS:
		turner_transition_active = false
		turner_transition_phase = TurnerTransitionPhase.NONE
		turner_transition_time = 0.0
		rope_angle = PI
		accepting_input = not is_jumping


func _unhandled_input(event: InputEvent) -> void:
	var pressed := event.is_action_pressed("jump")
	var pointer_position := Vector2(-1.0, -1.0)
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pointer_position = event.position
	elif event is InputEventMouseButton:
		pointer_position = event.position
	if pressed:
		if game_state == GameState.GAME_OVER and pointer_position.x >= 0.0:
			var game_over_position := _screen_to_design(pointer_position)
			if GAME_OVER_CLOSE_RECT.has_point(game_over_position):
				_return_to_main()
				get_viewport().set_input_as_handled()
				return
		if game_state == GameState.TITLE and pointer_position.x >= 0.0:
			var design_position := _screen_to_design(pointer_position)
			if character_menu_open:
				_handle_character_menu_input(design_position)
				get_viewport().set_input_as_handled()
				return
			if TEST_START_50_RECT.has_point(design_position):
				_start_game_at_score(50)
				get_viewport().set_input_as_handled()
				return
			if CHARACTER_BUTTON_RECT.has_point(design_position):
				character_menu_open = true
				get_viewport().set_input_as_handled()
				return
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
	if game_state == GameState.HIT:
		return
	if game_state != GameState.PLAYING:
		_start_game()
		return
	if not accepting_input or is_jumping:
		return
	accepting_input = false
	is_jumping = true
	jump_animation_time = 0.0
	jump_started_in_cue = _is_jump_cue()
	jump_velocity = -820.0


func _resolve_rope_crossing() -> void:
	# Success is decided when the visible rope actually reaches the player's feet.
	if _player_clears_rope_at_crossing():
		score += 1
		if score > best_score:
			best_score = score
			new_best_this_run = true
		rope_speed = _base_speed_for_score(score)
		total_success += 1
		var previous_team := turner_team
		var team_changed := _update_turner_team_and_pattern()
		if team_changed:
			_start_turner_transition(previous_team)
			match turner_team:
				TurnerTeam.ATHLETE:
					message = "운동부 등장!  기본 2회 뒤 급가속!"
				TurnerTeam.SLEEPY:
					message = "졸보 등장!  깨면 1초 뒤 초고속!"
				TurnerTeam.PRANKSTER:
					message = "장난꾸러기 등장!  멈추는 척을 조심!"
				TurnerTeam.WIZARD:
					message = "마법사 등장!  사라진 줄은 빨간색을 봐!"
		elif turner_team == TurnerTeam.SLEEPY and sleepy_wake_warning_time > 0.0:
			message = "번쩍!  1초 뒤 초고속!"
		elif turner_team == TurnerTeam.ATHLETE and challenge_pattern == 2:
			message = "운동부 급가속!"
		else:
			message = "좋아요!  +1"
		message_color = Color("73f7b4")
		flash_time = 0.22
		jump_started_in_cue = false
		feedback.play_success(score)
	else:
		# Freeze at the visible contact point before revealing the result panel.
		rope_angle = ROPE_CROSSING_ANGLE
		game_state = GameState.HIT
		hit_reveal_time = HIT_REVEAL_SECONDS
		accepting_input = false
		message = "앗! 줄에 걸렸어요!"
		message_color = Color("ff7892")
		flash_time = 0.5
		run_coins_earned = score + (5 if new_best_this_run else 0)
		coins += run_coins_earned
		total_runs += 1
		_save_progress()
		feedback.play_failure()


func _player_clears_rope_at_crossing() -> bool:
	if not is_jumping:
		return false
	var rope_center_y := _rope_midpoint_y(ROPE_CROSSING_ANGLE)
	var rope_top_y := rope_center_y - ROPE_PIXEL_OUTLINE_SIZE.y * 0.5
	var player_feet_y := PLAYER_GROUND_Y + jump_height + player_sprite_ground_offset.y
	return player_feet_y < rope_top_y


func _start_game() -> void:
	run_start_best = best_score
	new_best_this_run = false
	run_coins_earned = 0
	hit_reveal_time = 0.0
	score = 0
	rope_angle = PI
	rope_speed = balance.base_rope_speed
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	is_jumping = false
	jump_started_in_cue = false
	accepting_input = true
	game_state = GameState.PLAYING
	_reset_turner_run()
	menu_notice = ""
	message = "줄이 빨간색일 때 점프!"
	message_color = Color.WHITE
	feedback.play_start()


func _start_game_at_score(start_score: int) -> void:
	_start_game()
	score = maxi(0, start_score)
	rope_speed = _base_speed_for_score(score)
	if score >= WIZARD_START_SCORE:
		turner_team = TurnerTeam.WIZARD
		wizard_rope_hidden = false
		wizard_speed_multiplier = _roll_wizard_speed_multiplier()
		wizard_speed_turns_remaining = WIZARD_SPEED_PAIR_TURNS
	elif score >= PRANKSTER_START_SCORE:
		turner_team = TurnerTeam.PRANKSTER
		prankster_normal_turns_remaining = _roll_prankster_normal_turns()
	elif score >= SLEEPY_START_SCORE:
		turner_team = TurnerTeam.SLEEPY
		sleepy_slow_turns_remaining = _roll_sleepy_slow_turns()
	elif score >= TURNER_CHANGE_INTERVAL:
		turner_team = TurnerTeam.ATHLETE
		athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
	message = "테스트 모드: %d회부터 시작!" % score
	message_color = Color("ffd84a")


func _return_to_main() -> void:
	game_state = GameState.TITLE
	score = 0
	rope_angle = PI
	rope_speed = balance.base_rope_speed
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	is_jumping = false
	jump_started_in_cue = false
	accepting_input = true
	_reset_turner_run()
	hit_reveal_time = 0.0
	menu_notice = ""
	message = "화면을 눌러 시작"
	message_color = Color.WHITE
	queue_redraw()


func _load_saved_progress() -> void:
	var data := save_manager.load_game()
	best_score = int(data.best_score)
	coins = int(data.coins)
	gems = int(data.gems)
	total_runs = int(data.stats.total_runs)
	total_success = int(data.stats.total_success)
	for owned_id in data.owned_characters:
		var character_id := str(owned_id)
		if character_ids.has(character_id) and not owned_character_ids.has(character_id):
			owned_character_ids.append(character_id)
	var saved_character := str(data.selected_character)
	selected_character_id = saved_character if owned_character_ids.has(saved_character) else DEFAULT_CHARACTER_ID
	feedback.sound_enabled = bool(data.settings.sound)
	feedback.vibration_enabled = bool(data.settings.vibration)


func _save_progress() -> void:
	save_manager.save_game({
		"save_version": RopeSaveManager.SAVE_VERSION,
		"best_score": best_score,
		"coins": coins,
		"gems": gems,
		"selected_character": selected_character_id,
		"owned_characters": owned_character_ids,
		"settings": {
			"sound": feedback.sound_enabled,
			"vibration": feedback.vibration_enabled,
		},
		"stats": {
			"total_runs": total_runs,
			"total_success": total_success,
		},
	})


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	design_draw_offset = offset
	design_draw_scale = scale_factor
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)

	_draw_background()
	_draw_ground()
	# Draw the rear half first so only the parts covered by people are hidden.
	if not turner_transition_active and _rope_is_behind():
		_draw_rope()
	var left_turner_feet := LEFT_TURNER_FEET
	var right_turner_feet := RIGHT_TURNER_FEET
	var visible_turner_team := -1
	if turner_transition_phase == TurnerTransitionPhase.TURNER_EXIT:
		var exit_progress := clampf(turner_transition_time / TURNER_EXIT_SECONDS, 0.0, 1.0)
		var eased_exit := exit_progress * exit_progress
		left_turner_feet = LEFT_TURNER_FEET.lerp(LEFT_TURNER_ENTRY_FEET, eased_exit)
		right_turner_feet = RIGHT_TURNER_FEET.lerp(RIGHT_TURNER_ENTRY_FEET, eased_exit)
		visible_turner_team = departing_turner_team
	elif turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		var entry_progress := clampf(turner_transition_time / ATHLETE_ENTRY_SECONDS, 0.0, 1.0)
		var eased_entry := 1.0 - pow(1.0 - entry_progress, 3.0)
		left_turner_feet = LEFT_TURNER_ENTRY_FEET.lerp(LEFT_TURNER_FEET, eased_entry)
		right_turner_feet = RIGHT_TURNER_ENTRY_FEET.lerp(RIGHT_TURNER_FEET, eased_entry)
		visible_turner_team = turner_team
	_draw_turner(left_turner_feet, false, visible_turner_team)
	_draw_turner(right_turner_feet, true, visible_turner_team)
	_draw_player()
	if turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		_draw_countdown_overlay()
	# Draw the front half last so it visibly passes in front of the player.
	if not turner_transition_active and not _rope_is_behind():
		_draw_rope()
	if game_state == GameState.HIT:
		_draw_hit_feedback()
	_draw_hud()


func _draw_countdown_overlay() -> void:
	var countdown_index := mini(3, int(turner_transition_time / COUNTDOWN_NUMBER_SECONDS))
	if countdown_index < 0 or countdown_index >= countdown_textures.size():
		return
	var texture := countdown_textures[countdown_index]
	var used_region := countdown_used_regions[countdown_index]
	if texture == null or used_region.size.x <= 0.0 or used_region.size.y <= 0.0:
		return
	var target_size := Vector2(220.0, 220.0)
	var center := Vector2(360.0, 470.0)
	if countdown_index == 3:
		target_size = Vector2(430.0, 240.0)
		var go_time := turner_transition_time - COUNTDOWN_NUMBER_SECONDS * 3.0
		center.x += roundf(sin(go_time * TAU * 14.0) * 11.0)
	var scale_factor := minf(target_size.x / used_region.size.x, target_size.y / used_region.size.y)
	var draw_size := used_region.size * scale_factor
	var draw_rect := Rect2(center - draw_size * 0.5, draw_size)
	draw_texture_rect_region(texture, draw_rect, used_region)


func _draw_background() -> void:
	if background_texture != null:
		_draw_cover_texture(background_texture, Rect2(Vector2.ZERO, DESIGN_SIZE))
		if flash_time > 0.0:
			draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(1, 1, 1, flash_time * 0.32))
		return
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
	if background_texture != null:
		return
	draw_rect(Rect2(0, 650, 720, 630), Color("75c86b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(130, 1280), Vector2(255, 650), Vector2(465, 650), Vector2(590, 1280)
	]), Color("e6c98c"))
	for x in range(35, 720, 95):
		draw_line(Vector2(x, 1010), Vector2(x + 18, 990), Color("5eae58"), 5.0, true)


func _draw_cover_texture(texture: Texture2D, target: Rect2) -> void:
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var target_aspect := target.size.x / target.size.y
	var source_aspect := source_size.x / source_size.y
	var source_rect := Rect2(Vector2.ZERO, source_size)
	if source_aspect > target_aspect:
		var cropped_width := source_size.y * target_aspect
		source_rect.position.x = (source_size.x - cropped_width) * 0.5
		source_rect.size.x = cropped_width
	elif source_aspect < target_aspect:
		var cropped_height := source_size.x / target_aspect
		source_rect.position.y = (source_size.y - cropped_height) * 0.5
		source_rect.size.y = cropped_height
	draw_texture_rect_region(texture, target, source_rect)


func _draw_rope() -> void:
	var midpoint_y := _rope_midpoint_y(rope_angle)
	var pixel_points := PackedVector2Array()
	for i in range(97):
		var t := float(i) / 96.0
		var x := lerpf(LEFT_HAND.x, RIGHT_HAND.x, t)
		# 4t(1-t) is zero at both hands and one at the middle.
		var y := lerpf(LEFT_HAND.y, RIGHT_HAND.y, t) + 4.0 * t * (1.0 - t) * (midpoint_y - LEFT_HAND.y)
		var pixel_point := Vector2(
			roundf(x / ROPE_PIXEL_GRID) * ROPE_PIXEL_GRID,
			roundf(y / ROPE_PIXEL_GRID) * ROPE_PIXEL_GRID
		)
		if pixel_points.is_empty() or pixel_points[-1] != pixel_point:
			pixel_points.append(pixel_point)

	var show_jump_cue := _is_jump_cue()
	var wizard_ghosted := _wizard_rope_is_ghosted()
	var rope_color := Color("ff334f") if show_jump_cue else Color("f6b73c")
	var highlight_color := Color("ff9a8d") if show_jump_cue else Color("ffe27a")
	var outline_color := Color("3b2119")
	var shadow_color := Color(0, 0, 0, 0.22)
	if wizard_ghosted:
		rope_color = Color(0.20, 0.72, 1.0, 0.34)
		highlight_color = Color(0.62, 0.94, 1.0, 0.46)
		outline_color = Color(0.05, 0.22, 0.42, 0.28)
		shadow_color = Color(0.02, 0.15, 0.30, 0.12)

	# Draw in separate passes so the square pieces merge into one outlined pixel rope.
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_OUTLINE_SIZE * 0.5 + Vector2(2.0, 3.0), ROPE_PIXEL_OUTLINE_SIZE), shadow_color)
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_OUTLINE_SIZE * 0.5, ROPE_PIXEL_OUTLINE_SIZE), outline_color)
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_CORE_SIZE * 0.5, ROPE_PIXEL_CORE_SIZE), rope_color)
	for i in range(0, pixel_points.size(), 3):
		draw_rect(Rect2(pixel_points[i] + Vector2(-3.0, -3.0), Vector2(3.0, 3.0)), highlight_color)

	_draw_pixel_rope_grip(LEFT_HAND, wizard_ghosted)
	_draw_pixel_rope_grip(RIGHT_HAND, wizard_ghosted)


func _wizard_rope_is_ghosted() -> bool:
	return turner_team == TurnerTeam.WIZARD and wizard_rope_hidden and not _is_jump_cue()


func _rope_midpoint_y(angle: float) -> float:
	var vertical_phase := sin(angle)
	var radius := ROPE_GROUND_RADIUS if vertical_phase >= 0.0 else ROPE_OVERHEAD_RADIUS
	return LEFT_HAND.y + vertical_phase * radius


func _draw_pixel_rope_grip(center: Vector2, ghosted := false) -> void:
	var outline := Color(0.05, 0.22, 0.42, 0.28) if ghosted else Color("3b2119")
	var core := Color(0.20, 0.72, 1.0, 0.34) if ghosted else Color("f6b73c")
	var shine := Color(0.62, 0.94, 1.0, 0.46) if ghosted else Color("ffe27a")
	draw_rect(Rect2(center - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), outline)
	draw_rect(Rect2(center - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), core)
	draw_rect(Rect2(center + Vector2(-4.0, -4.0), Vector2(4.0, 4.0)), shine)


func _draw_hit_feedback() -> void:
	var contact := Vector2(PLAYER_X, PLAYER_GROUND_Y - 3.0)
	draw_circle(contact, 24.0, Color(1.0, 0.18, 0.28, 0.34))
	for direction in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 0.35), Vector2(1.0, 0.35)]:
		draw_line(contact + direction * 12.0, contact + direction * 35.0, Color("ff334f"), 6.0, true)


func _rope_is_behind() -> bool:
	# The descending half comes toward the player; the rising half moves behind.
	return cos(rope_angle) < 0.0


func _is_jump_cue() -> bool:
	if game_state != GameState.PLAYING or rope_speed <= 0.0 or _rope_is_behind():
		return false
	var seconds_until_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_angle, TAU) / _cue_reference_speed()
	return seconds_until_crossing <= balance.jump_cue_seconds


func _cue_reference_speed() -> float:
	if turner_team == TurnerTeam.WIZARD:
		return rope_speed * WIZARD_BASE_SPEED_MULTIPLIER * wizard_speed_multiplier
	return rope_speed


func _effective_rope_speed() -> float:
	if turner_team == TurnerTeam.WIZARD:
		return rope_speed * WIZARD_BASE_SPEED_MULTIPLIER * wizard_speed_multiplier
	if turner_team == TurnerTeam.SLEEPY:
		if sleepy_fast_turns_remaining > 0:
			return rope_speed if _is_jump_cue() else rope_speed * SLEEPY_FAST_MULTIPLIER
		return rope_speed * SLEEPY_SLOW_MULTIPLIER
	# Keep a stable, fair speed throughout the red input window.
	if challenge_pattern == 0 or _is_jump_cue():
		return rope_speed

	var speed_multiplier := 1.0
	match challenge_pattern:
		1: # Off-beat: linger behind the player, then catch up in front.
			speed_multiplier = balance.offbeat_behind_multiplier if _rope_is_behind() else balance.offbeat_front_multiplier
		2: # Athlete: several whole turns are much faster than the normal rhythm.
			speed_multiplier = balance.athlete_burst_multiplier
		3: # Wave: repeatedly changes tempo during one turn.
			speed_multiplier = balance.wave_min_multiplier + balance.wave_range * (0.5 + 0.5 * sin(rope_angle * 3.0))
	return rope_speed * speed_multiplier


func _base_speed_for_score(current_score: int) -> float:
	# The athlete's difficulty comes from its burst pattern, not a constantly
	# rising baseline. Hold the score-10 baseline until the sleepy team enters.
	if current_score >= TURNER_CHANGE_INTERVAL and current_score < SLEEPY_START_SCORE:
		return balance.speed_for_score(TURNER_CHANGE_INTERVAL)
	if current_score >= PRANKSTER_START_SCORE:
		return balance.speed_for_score(TURNER_CHANGE_INTERVAL)
	return balance.speed_for_score(current_score)


func _reset_turner_run() -> void:
	turner_team = TurnerTeam.STUDENT
	challenge_pattern = 0
	athlete_normal_turns_remaining = 0
	athlete_burst_turns_remaining = 0
	sleepy_slow_turns_remaining = 0
	sleepy_wake_warning_time = 0.0
	sleepy_fast_turns_remaining = 0
	prankster_normal_turns_remaining = 0
	prankster_fake_pending = false
	prankster_fake_mode = 0
	prankster_fake_time = 0.0
	wizard_rope_hidden = false
	wizard_speed_multiplier = 1.0
	wizard_speed_turns_remaining = 0
	turner_transition_active = false
	turner_transition_time = 0.0
	turner_transition_phase = TurnerTransitionPhase.NONE
	departing_turner_team = TurnerTeam.STUDENT


func _start_turner_transition(previous_team := TurnerTeam.STUDENT) -> void:
	turner_transition_active = true
	turner_transition_time = 0.0
	turner_transition_phase = TurnerTransitionPhase.TURNER_EXIT
	departing_turner_team = previous_team
	accepting_input = false
	# Resume with the rope safely behind the player after GO! finishes.
	rope_angle = PI


func _update_turner_team_and_pattern() -> bool:
	if turner_team == TurnerTeam.STUDENT:
		if score < TURNER_CHANGE_INTERVAL:
			challenge_pattern = 0
			return false
		turner_team = TurnerTeam.ATHLETE
		challenge_pattern = 0
		athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
		athlete_burst_turns_remaining = 0
		return true
	if turner_team == TurnerTeam.ATHLETE and score >= SLEEPY_START_SCORE:
		turner_team = TurnerTeam.SLEEPY
		challenge_pattern = 0
		sleepy_slow_turns_remaining = _roll_sleepy_slow_turns()
		sleepy_wake_warning_time = 0.0
		sleepy_fast_turns_remaining = 0
		return true
	if turner_team == TurnerTeam.SLEEPY and score >= PRANKSTER_START_SCORE:
		turner_team = TurnerTeam.PRANKSTER
		challenge_pattern = 0
		sleepy_wake_warning_time = 0.0
		sleepy_fast_turns_remaining = 0
		prankster_normal_turns_remaining = _roll_prankster_normal_turns()
		prankster_fake_pending = false
		prankster_fake_mode = 0
		prankster_fake_time = 0.0
		return true
	if turner_team == TurnerTeam.PRANKSTER and score >= WIZARD_START_SCORE:
		turner_team = TurnerTeam.WIZARD
		challenge_pattern = 0
		prankster_fake_pending = false
		prankster_fake_mode = 0
		prankster_fake_time = 0.0
		wizard_rope_hidden = false
		wizard_speed_multiplier = _roll_wizard_speed_multiplier()
		wizard_speed_turns_remaining = WIZARD_SPEED_PAIR_TURNS
		return true
	if turner_team == TurnerTeam.SLEEPY:
		if sleepy_fast_turns_remaining > 0:
			sleepy_fast_turns_remaining -= 1
			if sleepy_fast_turns_remaining <= 0:
				# Always return to at least one sleeping turn, so awake/fast
				# turns can never occur twice in a row.
				sleepy_slow_turns_remaining = _roll_sleepy_slow_turns()
		elif sleepy_wake_warning_time <= 0.0:
			sleepy_slow_turns_remaining -= 1
			if sleepy_slow_turns_remaining <= 0:
				sleepy_wake_warning_time = SLEEPY_WAKE_WARNING_SECONDS
		return false
	if turner_team == TurnerTeam.PRANKSTER:
		prankster_normal_turns_remaining -= 1
		if prankster_normal_turns_remaining <= 0:
			prankster_fake_pending = true
		return false
	if turner_team == TurnerTeam.WIZARD:
		wizard_rope_hidden = not wizard_rope_hidden
		wizard_speed_turns_remaining -= 1
		if wizard_speed_turns_remaining <= 0:
			wizard_speed_multiplier = _roll_wizard_speed_multiplier(wizard_speed_multiplier)
			wizard_speed_turns_remaining = WIZARD_SPEED_PAIR_TURNS
		return false

	if challenge_pattern == 2:
		athlete_burst_turns_remaining -= 1
		if athlete_burst_turns_remaining <= 0:
			challenge_pattern = 0
			athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
	else:
		athlete_normal_turns_remaining -= 1
		if athlete_normal_turns_remaining <= 0:
			challenge_pattern = 2
			# Never exceed two consecutive high-speed turns; longer bursts are
			# not realistically reactable on a mobile touch screen.
			athlete_burst_turns_remaining = ATHLETE_MAX_BURST_TURNS
	return false


func _update_sleepy_warning(delta: float) -> void:
	if turner_team != TurnerTeam.SLEEPY or sleepy_wake_warning_time <= 0.0:
		return
	sleepy_wake_warning_time = maxf(0.0, sleepy_wake_warning_time - delta)
	if sleepy_wake_warning_time <= 0.0:
		sleepy_fast_turns_remaining = 1
		message = "지금!"
		message_color = Color("ff5c65")


func _roll_sleepy_slow_turns() -> int:
	return randi_range(SLEEPY_MIN_SLOW_TURNS, SLEEPY_MAX_SLOW_TURNS)


func _roll_prankster_normal_turns() -> int:
	return randi_range(PRANKSTER_MIN_NORMAL_TURNS, PRANKSTER_MAX_NORMAL_TURNS)


func _roll_wizard_speed_multiplier(previous_multiplier := -1.0) -> float:
	var candidates := WIZARD_SPEED_MULTIPLIERS.duplicate()
	for index in range(candidates.size() - 1, -1, -1):
		if is_equal_approx(float(candidates[index]), previous_multiplier):
			candidates.remove_at(index)
	return float(candidates[randi_range(0, candidates.size() - 1)])


func _update_prankster_fake(delta: float) -> bool:
	if turner_team != TurnerTeam.PRANKSTER:
		return false
	if prankster_fake_time > 0.0:
		if prankster_fake_mode == 2:
			# A short visible rewind at the top makes the fake readable without
			# ever reversing through the player's collision point.
			var reverse_delta := minf(delta, prankster_fake_time)
			rope_angle = fposmod(rope_angle - rope_speed * PRANKSTER_REVERSE_SPEED_MULTIPLIER * reverse_delta, TAU)
		prankster_fake_time = maxf(0.0, prankster_fake_time - delta)
		if prankster_fake_time <= 0.0:
			prankster_fake_mode = 0
			prankster_fake_pending = false
			prankster_normal_turns_remaining = _roll_prankster_normal_turns()
			message = "다시 돈다!"
			message_color = Color("73f7b4")
		return true
	if prankster_fake_pending:
		var projected_angle := fposmod(rope_angle + _effective_rope_speed() * delta, TAU)
		if not _angle_crossed(rope_angle, projected_angle, ROPE_OVERHEAD_ANGLE):
			return false
		rope_angle = ROPE_OVERHEAD_ANGLE
		prankster_fake_mode = randi_range(1, 2)
		prankster_fake_time = PRANKSTER_STOP_SECONDS if prankster_fake_mode == 1 else PRANKSTER_REVERSE_SECONDS
		message = "멈칫!" if prankster_fake_mode == 1 else "역회전!"
		message_color = Color("ffd84a")
		return true
	return false


func _sleepy_is_awake() -> bool:
	return sleepy_wake_warning_time > 0.0 or sleepy_fast_turns_remaining > 0


func _angle_crossed(previous_angle: float, current_angle: float, target_angle: float) -> bool:
	var travelled := fposmod(current_angle - previous_angle, TAU)
	var target_distance := fposmod(target_angle - previous_angle, TAU)
	return target_distance > 0.0 and target_distance <= travelled


func _draw_turner(feet: Vector2, faces_left: bool, display_team := -1) -> void:
	var render_feet := feet
	var active_team := turner_team if display_team < 0 else display_team
	var base_texture := turner_texture
	var base_region := turner_used_region
	var mirror_texture := mirrored_turner_texture
	var mirror_region := mirrored_turner_used_region
	if active_team == TurnerTeam.ATHLETE:
		base_texture = athlete_turner_texture
		base_region = athlete_turner_used_region
		mirror_texture = mirrored_athlete_turner_texture
		mirror_region = mirrored_athlete_turner_used_region
	elif active_team == TurnerTeam.SLEEPY:
		var awake := _sleepy_is_awake()
		base_texture = sleepy_turner_awake_texture if awake else sleepy_turner_asleep_texture
		base_region = sleepy_turner_awake_used_region if awake else sleepy_turner_asleep_used_region
		mirror_texture = mirrored_sleepy_turner_awake_texture if awake else mirrored_sleepy_turner_asleep_texture
		mirror_region = mirrored_sleepy_turner_awake_used_region if awake else mirrored_sleepy_turner_asleep_used_region
	elif active_team == TurnerTeam.PRANKSTER:
		base_texture = prankster_turner_texture
		base_region = prankster_turner_used_region
		mirror_texture = mirrored_prankster_turner_texture
		mirror_region = mirrored_prankster_turner_used_region
	elif active_team == TurnerTeam.WIZARD:
		base_texture = wizard_turner_texture
		base_region = wizard_turner_used_region
		mirror_texture = mirrored_wizard_turner_texture
		mirror_region = mirrored_wizard_turner_used_region
	if base_texture != null and base_region.size.x > 0.0:
		var active_texture := mirror_texture if faces_left and mirror_texture != null else base_texture
		var active_region := mirror_region if faces_left and mirror_texture != null else base_region
		# Match the helper's height to the playable character and preserve the
		# original aspect ratio so the sprite never looks stretched sideways.
		var sprite_height := 165.0
		var sprite_width := sprite_height * active_region.size.x / active_region.size.y
		var sprite_size := Vector2(sprite_width, sprite_height)
		_draw_shadow_ellipse(render_feet + Vector2(0, 13), Vector2(sprite_width * 0.34, 11), Color(0, 0, 0, 0.2))
		var sprite_rect := Rect2(render_feet + Vector2(-sprite_width * 0.5, -sprite_height), sprite_size)
		draw_texture_rect_region(active_texture, sprite_rect, active_region)
		return
	var direction := -1.0 if faces_left else 1.0
	feet = render_feet
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
	var p := Vector2(PLAYER_X, PLAYER_GROUND_Y + jump_height)
	# Shadow
	var shadow_scale := clampf(1.0 + jump_height / 650.0, 0.45, 1.0)
	_draw_shadow_ellipse(Vector2(PLAYER_X, PLAYER_GROUND_Y + 18.0), Vector2(70.0 * shadow_scale, 18.0), Color(0, 0, 0, 0.28))
	if player_sprite != null:
		_draw_player_sprite(p)
	else:
		_draw_default_player(p)


func _draw_player_sprite(feet_position: Vector2) -> void:
	var active_texture := player_sprite
	var source_rect := player_base_region
	var using_jump_sheet := false
	if is_jumping and player_jump_sprite != null and player_jump_regions.size() == JUMP_FRAME_COUNT:
		using_jump_sheet = true
		active_texture = player_jump_sprite
		var frame := 3
		if jump_velocity < -500.0 or jump_velocity >= 500.0:
			frame = 1
		elif jump_velocity < -100.0 or jump_velocity >= 100.0:
			frame = 2
		source_rect = player_jump_regions[frame]
	var texture_size := source_rect.size
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_draw_default_player(feet_position)
		return
	var draw_size := texture_size * player_jump_scale if using_jump_sheet else texture_size * player_base_scale
	var anchored_feet := feet_position + player_sprite_ground_offset
	var draw_position := anchored_feet - Vector2(draw_size.x * 0.5, draw_size.y)
	draw_texture_rect_region(active_texture, Rect2(draw_position, draw_size), source_rect)


func set_player_character(character_id: String) -> bool:
	if not _is_safe_character_id(character_id):
		return false
	var idle_path := _character_asset_path(character_id, "idle.png")
	if not ResourceLoader.exists(idle_path):
		return false
	selected_character_id = character_id
	player_sprite = null
	player_jump_sprite = null
	_load_character_visuals(character_id)
	queue_redraw()
	return player_sprite != null


func _handle_character_menu_input(position: Vector2) -> void:
	if CHARACTER_PANEL_CLOSE_RECT.has_point(position):
		character_menu_open = false
		return
	var page_count := _character_page_count()
	if CHARACTER_PAGE_PREV_RECT.has_point(position) and page_count > 1:
		character_page = posmod(character_page - 1, page_count)
		return
	if CHARACTER_PAGE_NEXT_RECT.has_point(position) and page_count > 1:
		character_page = (character_page + 1) % page_count
		return
	var page_ids := _current_character_page_ids()
	for index in range(mini(page_ids.size(), CHARACTER_CARD_RECTS.size())):
		if CHARACTER_CARD_RECTS[index].has_point(position):
			var character_id: String = page_ids[index]
			if set_player_character(character_id):
				menu_notice = "%s 선택" % character_names.get(character_id, character_id)
				_save_progress()
			return


func _load_character_catalog() -> void:
	character_ids.clear()
	character_names.clear()
	owned_character_ids.clear()
	var entries: Array[Dictionary] = []
	for character_id in DirAccess.get_directories_at(CHARACTER_ASSET_ROOT):
		if not _is_safe_character_id(character_id):
			continue
		if not ResourceLoader.exists(_character_asset_path(character_id, "idle.png")):
			continue
		var metadata := {
			"id": character_id,
			"display_name": character_id,
			"order": 9999,
			"unlocked_by_default": false,
		}
		var metadata_path := _character_asset_path(character_id, "character.json")
		if FileAccess.file_exists(metadata_path):
			var file := FileAccess.open(metadata_path, FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
			if parsed is Dictionary:
				metadata.merge(parsed as Dictionary, true)
		entries.append(metadata)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.order) < int(b.order))
	for entry in entries:
		var character_id := str(entry.id)
		character_ids.append(character_id)
		character_names[character_id] = str(entry.display_name)
		if bool(entry.unlocked_by_default):
			owned_character_ids.append(character_id)
	if character_ids.has(DEFAULT_CHARACTER_ID) and not owned_character_ids.has(DEFAULT_CHARACTER_ID):
		owned_character_ids.push_front(DEFAULT_CHARACTER_ID)


func _character_page_count() -> int:
	return maxi(1, int(ceil(float(owned_character_ids.size()) / float(CHARACTERS_PER_PAGE))))


func _current_character_page_ids() -> Array[String]:
	var result: Array[String] = []
	var page_count := _character_page_count()
	character_page = clampi(character_page, 0, page_count - 1)
	var first_index := character_page * CHARACTERS_PER_PAGE
	for index in range(first_index, mini(first_index + CHARACTERS_PER_PAGE, owned_character_ids.size())):
		result.append(owned_character_ids[index])
	return result


func _load_character_visuals(character_id: String) -> void:
	var safe_id := character_id if _is_safe_character_id(character_id) else DEFAULT_CHARACTER_ID
	selected_character_id = safe_id
	var idle_path := _character_asset_path(safe_id, "idle.png")
	var jump_path := _character_asset_path(safe_id, "jump_sheet.png")
	if player_sprite == null and ResourceLoader.exists(idle_path):
		player_sprite = load(idle_path) as Texture2D
	if player_jump_sprite == null and ResourceLoader.exists(jump_path):
		player_jump_sprite = load(jump_path) as Texture2D
	if player_sprite == null and safe_id != DEFAULT_CHARACTER_ID:
		selected_character_id = DEFAULT_CHARACTER_ID
		_load_character_visuals(DEFAULT_CHARACTER_ID)
		return
	_prepare_character_regions()


func _prepare_character_regions() -> void:
	player_base_region = _texture_used_region(player_sprite)
	player_base_scale = _scale_for_region(player_base_region)
	player_jump_regions.clear()
	if player_jump_sprite == null:
		return
	var sheet_image := player_jump_sprite.get_image()
	if sheet_image == null or sheet_image.is_empty():
		return
	var cell_width := sheet_image.get_width() / JUMP_FRAME_COUNT
	if cell_width <= 0:
		return
	for frame in range(JUMP_FRAME_COUNT):
		var cell_rect := Rect2i(frame * cell_width, 0, cell_width, sheet_image.get_height())
		var used := _image_visible_region(sheet_image, cell_rect)
		if used.size.x <= 0 or used.size.y <= 0:
			used = cell_rect
		player_jump_regions.append(Rect2(used))
	if not player_jump_regions.is_empty():
		var base_draw_size := player_base_region.size * player_base_scale
		var jump_reference_size := player_jump_regions[0].size
		player_jump_scale = Vector2(
			base_draw_size.x / jump_reference_size.x,
			base_draw_size.y / jump_reference_size.y
		)


func _texture_used_region(texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2()
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Rect2(Vector2.ZERO, texture.get_size())
	var used := _image_visible_region(image, Rect2i(Vector2i.ZERO, image.get_size()))
	return Rect2(used) if used.size.x > 0 and used.size.y > 0 else Rect2(Vector2.ZERO, texture.get_size())


func _image_visible_region(image: Image, search_rect: Rect2i, alpha_threshold: int = 8) -> Rect2i:
	var rgba: Image = image.duplicate()
	if rgba.get_format() != Image.FORMAT_RGBA8:
		rgba.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = rgba.get_data()
	var image_width: int = rgba.get_width()
	var minimum := search_rect.end
	var maximum := search_rect.position - Vector2i.ONE
	for y in range(search_rect.position.y, search_rect.end.y):
		var row_offset: int = y * image_width * 4
		for x in range(search_rect.position.x, search_rect.end.x):
			if data[row_offset + x * 4 + 3] > alpha_threshold:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _scale_for_region(region: Rect2) -> float:
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return 1.0
	return minf(player_sprite_max_size.y / region.size.y, player_sprite_max_size.x / region.size.x)


func _character_asset_path(character_id: String, file_name: String) -> String:
	return "%s/%s/%s" % [CHARACTER_ASSET_ROOT, character_id, file_name]


func _is_safe_character_id(character_id: String) -> bool:
	if character_id.is_empty():
		return false
	for character in character_id:
		if not "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".contains(character):
			return false
	return true


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
		if character_menu_open:
			_draw_character_menu(font)
		return
	draw_string(font, Vector2(42, 82), "줄넘킹", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("91a4cc"))
	draw_string(font, Vector2(42, 158), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color.WHITE)
	draw_string(font, Vector2(480, 83), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffd166"))
	if game_state != GameState.GAME_OVER:
		draw_string(font, Vector2(0, 1120), message, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 31, message_color)
	var control_text := "화면 터치 · 마우스 클릭 · SPACE"
	if game_state == GameState.GAME_OVER:
		control_text = "화면을 눌러 즉시 재시작"
	draw_string(font, Vector2(0, 1190), control_text, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("8293b7"))
	if game_state == GameState.GAME_OVER:
		_draw_game_over_panel(font)


func _draw_game_over_panel(font: Font) -> void:
	var panel := Rect2(95.0, 380.0, 530.0, 430.0)
	draw_rect(panel, Color(0.035, 0.055, 0.10, 0.94), true)
	draw_rect(panel, Color("fff0a6"), false, 7.0)
	draw_circle(GAME_OVER_CLOSE_RECT.get_center(), 26.0, Color("ff4d67"))
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(-9.0, -9.0), GAME_OVER_CLOSE_RECT.get_center() + Vector2(9.0, 9.0), Color.WHITE, 5.0, true)
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(9.0, -9.0), GAME_OVER_CLOSE_RECT.get_center() + Vector2(-9.0, 9.0), Color.WHITE, 5.0, true)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 76.0), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 54, Color("ff4d67"))
	draw_string(font, Vector2(panel.position.x, panel.position.y + 146.0), "이번 기록  %d" % score, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 34, Color.WHITE)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 198.0), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 28, Color("ffd166"))
	var record_message := ""
	if new_best_this_run:
		record_message = "새 최고 기록!"
	elif score == run_start_best:
		record_message = "최고 기록과 같아요!"
	else:
		record_message = "최고 기록까지 %d회" % maxi(1, run_start_best - score)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 252.0), record_message, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 27, Color("73f7b4"))
	draw_string(font, Vector2(panel.position.x, panel.position.y + 300.0), "코인  +%d" % run_coins_earned, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 25, Color("ffd166"))
	var retry_rect := Rect2(panel.position + Vector2(75.0, 330.0), Vector2(380.0, 72.0))
	draw_rect(retry_rect, Color("ffd23f"), true)
	draw_rect(retry_rect, Color("fff0a6"), false, 5.0)
	draw_string(font, Vector2(retry_rect.position.x, retry_rect.position.y + 48.0), "화면을 눌러 다시 도전", HORIZONTAL_ALIGNMENT_CENTER, retry_rect.size.x, 25, Color("633913"))


func _draw_main_menu(font: Font) -> void:
	_draw_resource_counter(font, Rect2(40.0, 22.0, 300.0, 62.0), coin_icon_texture, coin_icon_used_region, coins)
	_draw_resource_counter(font, Rect2(380.0, 22.0, 300.0, 62.0), ruby_icon_texture, ruby_icon_used_region, gems)

	_draw_main_menu_title(font)
	var best_rect := Rect2(235.0, 306.0, 250.0, 64.0)
	if best_score_frame_texture != null and best_score_frame_used_region.size.x > 0.0:
		draw_texture_rect_region(best_score_frame_texture, best_rect, best_score_frame_used_region)
	else:
		draw_rect(best_rect, Color(0.23, 0.14, 0.09, 0.88), true)
	draw_string(font, Vector2(284.0, 347.0), "최고 기록  %d" % best_score, HORIZONTAL_ALIGNMENT_CENTER, 178.0, 23, Color("fff0a6"))

	var prompt_alpha := 0.78 + sin(Time.get_ticks_msec() * 0.004) * 0.18
	var prompt_rect := Rect2(225.0, 505.0, 340.0, 128.0)
	if tap_prompt_texture != null and tap_prompt_used_region.size.x > 0.0:
		_draw_rotated_texture_region(tap_prompt_texture, prompt_rect, tap_prompt_used_region, 0.12, Color(1.0, 1.0, 1.0, prompt_alpha))
	else:
		draw_string(font, Vector2(prompt_rect.position.x, 980.0), "TAP TO START", HORIZONTAL_ALIGNMENT_CENTER, prompt_rect.size.x, 30, Color(1.0, 1.0, 1.0, prompt_alpha))

	_draw_menu_asset_or_fallback(character_button_texture, character_button_used_region, font, CHARACTER_BUTTON_RECT, "CHARACTER", "캐릭터", Color("ef8f6b"))
	_draw_menu_asset_or_fallback(upgrade_button_texture, upgrade_button_used_region, font, UPGRADE_BUTTON_RECT, "UPGRADE", "업그레이드", Color("65b7f3"))
	_draw_menu_asset_or_fallback(settings_button_texture, settings_button_used_region, font, SETTINGS_BUTTON_RECT, "SETTINGS", "설정", Color("9b8bea"))
	_draw_test_start_button(font)
	if not menu_notice.is_empty():
		draw_string(font, Vector2(0, 925), menu_notice, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("ffd166"))


func _draw_test_start_button(font: Font) -> void:
	draw_rect(TEST_START_50_RECT, Color("3b2119"), true)
	draw_rect(TEST_START_50_RECT.grow(-5.0), Color("ffd23f"), true)
	draw_rect(TEST_START_50_RECT.grow(-9.0), Color("7a4317"), false, 3.0)
	draw_string(font, Vector2(TEST_START_50_RECT.position.x, TEST_START_50_RECT.position.y + 31.0), "TEST", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_50_RECT.size.x, 18, Color("633913"))
	draw_string(font, Vector2(TEST_START_50_RECT.position.x, TEST_START_50_RECT.position.y + 62.0), "50 START", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_50_RECT.size.x, 25, Color("3b2119"))


func _draw_rotated_texture_region(texture: Texture2D, target: Rect2, source: Rect2, rotation: float, modulate: Color = Color.WHITE) -> void:
	var center := target.get_center()
	draw_set_transform(design_draw_offset + center * design_draw_scale, rotation, Vector2.ONE * design_draw_scale)
	draw_texture_rect_region(texture, Rect2(-target.size * 0.5, target.size), source, modulate)
	draw_set_transform(design_draw_offset, 0.0, Vector2.ONE * design_draw_scale)


func _draw_main_menu_title(font: Font) -> void:
	# Both rectangles share the exact screen center (x = 360).
	var frame_rect := Rect2(125.0, 116.0, 470.0, 188.0)
	if hud_title_frame_texture != null:
		draw_texture_rect(hud_title_frame_texture, frame_rect, false)
	else:
		draw_rect(frame_rect, Color("3a2418"), true)
		draw_rect(frame_rect, Color("ffd23f"), false, 7.0)
	var logo_rect := Rect2(255.0, 154.0, 210.0, 112.0)
	if hud_title_logo_texture != null:
		draw_texture_rect(hud_title_logo_texture, logo_rect, false)
	else:
		draw_string(font, Vector2(160.0, 225.0), "줄넘킹", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 54, Color("ffd23f"))


func _draw_character_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	draw_rect(CHARACTER_PANEL_RECT, Color("17243b"), true)
	draw_rect(CHARACTER_PANEL_RECT, Color("fff0a6"), false, 7.0)
	draw_string(font, Vector2(CHARACTER_PANEL_RECT.position.x, 260.0), "보유 캐릭터", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PANEL_RECT.size.x, 38, Color.WHITE)
	draw_string(font, Vector2(CHARACTER_PANEL_RECT.position.x, 300.0), "캐릭터 사진을 눌러 선택", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PANEL_RECT.size.x, 22, Color("a9bad8"))
	draw_circle(CHARACTER_PANEL_CLOSE_RECT.get_center(), 24.0, Color("ff4d67"))
	draw_line(CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, -8.0), CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, 8.0), Color.WHITE, 5.0, true)
	draw_line(CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, -8.0), CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, 8.0), Color.WHITE, 5.0, true)
	var page_ids := _current_character_page_ids()
	for index in range(mini(page_ids.size(), CHARACTER_CARD_RECTS.size())):
		_draw_character_card(font, page_ids[index], CHARACTER_CARD_RECTS[index])
	var page_count := _character_page_count()
	if page_count > 1:
		draw_rect(CHARACTER_PAGE_PREV_RECT, Color("263a57"), true)
		draw_rect(CHARACTER_PAGE_PREV_RECT, Color("fff0a6"), false, 4.0)
		draw_rect(CHARACTER_PAGE_NEXT_RECT, Color("263a57"), true)
		draw_rect(CHARACTER_PAGE_NEXT_RECT, Color("fff0a6"), false, 4.0)
		draw_string(font, Vector2(CHARACTER_PAGE_PREV_RECT.position.x, CHARACTER_PAGE_PREV_RECT.position.y + 40.0), "<", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PAGE_PREV_RECT.size.x, 28, Color.WHITE)
		draw_string(font, Vector2(CHARACTER_PAGE_NEXT_RECT.position.x, CHARACTER_PAGE_NEXT_RECT.position.y + 40.0), ">", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PAGE_NEXT_RECT.size.x, 28, Color.WHITE)
		draw_string(font, Vector2(312.0, 825.0), "%d / %d" % [character_page + 1, page_count], HORIZONTAL_ALIGNMENT_CENTER, 96.0, 22, Color("a9bad8"))


func _draw_character_card(font: Font, character_id: String, card: Rect2) -> void:
	var selected := character_id == selected_character_id
	var border_color := Color("73f7b4") if selected else Color("fff0a6")
	draw_rect(card, Color("263a57"), true)
	draw_rect(card, border_color, false, 6.0)
	var preview_rect := Rect2(card.position + Vector2(14.0, 16.0), Vector2(card.size.x - 28.0, 245.0))
	var texture := _character_preview_texture(character_id)
	if texture != null:
		var source: Rect2 = character_preview_regions.get(character_id, Rect2(Vector2.ZERO, texture.get_size()))
		var scale := minf(preview_rect.size.x / source.size.x, preview_rect.size.y / source.size.y)
		var size := source.size * scale
		var position := Vector2(preview_rect.get_center().x - size.x * 0.5, preview_rect.end.y - size.y)
		draw_texture_rect_region(texture, Rect2(position, size), source)
	var name: String = character_names.get(character_id, character_id)
	draw_string(font, Vector2(card.position.x + 8.0, card.position.y + 305.0), name, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 20, Color.WHITE)
	draw_string(font, Vector2(card.position.x + 8.0, card.position.y + 342.0), "보유", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("ffd166"))
	var state_text := "사용 중" if selected else "선택"
	draw_string(font, Vector2(card.position.x + 8.0, card.position.y + 378.0), state_text, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, border_color)


func _character_preview_texture(character_id: String) -> Texture2D:
	if character_preview_textures.has(character_id):
		return character_preview_textures[character_id] as Texture2D
	var path := _character_asset_path(character_id, "idle.png")
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	character_preview_textures[character_id] = texture
	character_preview_regions[character_id] = _texture_used_region(texture)
	return texture


func _draw_resource_counter(font: Font, rect: Rect2, icon_texture: Texture2D, icon_region: Rect2, amount: int) -> void:
	if resource_counter_frame_texture != null and resource_counter_frame_used_region.size.x > 0.0:
		draw_texture_rect_region(resource_counter_frame_texture, rect, resource_counter_frame_used_region)
	else:
		draw_rect(rect, Color(0.23, 0.14, 0.09, 0.92), true)
		draw_rect(rect, Color("ffd23f"), false, 4.0)
	var icon_rect := Rect2(rect.position + Vector2(9.0, 7.0), Vector2(48.0, 48.0))
	if icon_texture != null and icon_region.size.x > 0.0:
		draw_texture_rect_region(icon_texture, icon_rect, icon_region)
	# The icon already identifies the resource. A single large number stays clear
	# on narrow mobile screens and cannot collide with a second label line.
	var amount_position := Vector2(rect.position.x + 76.0, rect.position.y + 43.0)
	var amount_width := rect.size.x - 92.0
	draw_string(font, amount_position + Vector2(2.0, 2.0), str(amount), HORIZONTAL_ALIGNMENT_LEFT, amount_width, 27, Color(0.12, 0.06, 0.03, 0.85))
	draw_string(font, amount_position, str(amount), HORIZONTAL_ALIGNMENT_LEFT, amount_width, 27, Color.WHITE)


func _draw_menu_asset_or_fallback(texture: Texture2D, used_region: Rect2, font: Font, rect: Rect2, title: String, subtitle: String, face_color: Color) -> void:
	if texture != null and used_region.size.x > 0.0 and used_region.size.y > 0.0:
		# Crop each PNG's different transparent padding before fitting it into the
		# shared button rectangle, so all three buttons have the same visible size.
		draw_texture_rect_region(texture, rect, used_region)
		return
	_draw_menu_button(font, rect, title, subtitle, face_color)


func _draw_menu_button(font: Font, rect: Rect2, title: String, subtitle: String, face_color: Color) -> void:
	draw_rect(rect, Color("633913"), true)
	var face := Rect2(rect.position + Vector2(0.0, -7.0), rect.size - Vector2(0.0, 7.0))
	draw_rect(face, face_color, true)
	draw_rect(face, Color("fff0a6"), false, 5.0)
	draw_string(font, Vector2(face.position.x, face.position.y + 43.0), title, HORIZONTAL_ALIGNMENT_CENTER, face.size.x, 21, Color.WHITE)
	draw_string(font, Vector2(face.position.x, face.position.y + 80.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, face.size.x, 24, Color("263a57"))
