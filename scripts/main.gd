extends Node2D

enum GameState { TITLE, PLAYING, HIT, GAME_OVER }
enum TurnerTeam { STUDENT, ATHLETE, SLEEPY, PRANKSTER, WIZARD }
enum TurnerTransitionPhase { NONE, TURNER_EXIT, TURNER_ENTRY_COUNTDOWN }

const SUPABASE_URL := "https://zjluakxiiynlzbfxztrl.supabase.co"
const SUPABASE_ANON_KEY := "sb_publishable_oFUSCvNA6oyZCHP5vNuqXw_gfYXFD_e"
const LEADERBOARD_TOP_N := 10
const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const COOP_LEFT_PLAYER_X := 240.0
const COOP_RIGHT_PLAYER_X := 480.0
const PLAYER_GROUND_Y := 890.0
const TURNER_GROUND_Y := 910.0
const LEFT_HAND := Vector2(140.0, 855.0)
const RIGHT_HAND := Vector2(580.0, 855.0)
const COOP_LEFT_HAND := Vector2(72.0, 855.0)
const COOP_RIGHT_HAND := Vector2(648.0, 855.0)
const COOP_LEFT_TURNER_FEET := Vector2(42.0, TURNER_GROUND_Y)
const COOP_RIGHT_TURNER_FEET := Vector2(678.0, TURNER_GROUND_Y)
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
const WIZARD_GHOST_CORE_ALPHA := 0.04
const WIZARD_GHOST_HIGHLIGHT_ALPHA := 0.07
const WIZARD_GHOST_OUTLINE_ALPHA := 0.02
const WIZARD_ILLUSION_PHASES := [PI / 6.0, PI / 3.0]
const WIZARD_ILLUSION_LATERAL_SWAY := 28.0
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
const MENU_COOP_TEXTURE_PATH := "res://assets/ui/menu_coop.png"
const MENU_SETTINGS_TEXTURE_PATH := "res://assets/ui/menu_settings.png"
const HUD_TITLE_FRAME_PATH := "res://assets/ui/title_frame.png"
const HUD_TITLE_LOGO_PATH := "res://assets/ui/title_logo.png"
const BEST_SCORE_FRAME_PATH := "res://assets/ui/best_score_frame.png"
const GAMEPLAY_SCORE_LABEL_PATH := "res://assets/ui/score_label.png"
const GAMEPLAY_BEST_LABEL_PATH := "res://assets/ui/best_label.png"
const RESOURCE_COUNTER_FRAME_PATH := "res://assets/ui/resource_counter_frame.png"
const TAP_PROMPT_PATH := "res://assets/ui/tap_to_start.png"
const COIN_ICON_PATH := "res://assets/ui/coin_icon.png"
const RUBY_ICON_PATH := "res://assets/ui/ruby_icon.png"
const COIN_ICON_OFFSET := Vector2(8.0, 11.0)
const RUBY_ICON_OFFSET := Vector2(8.0, 12.0)
const RESOURCE_ICON_SIZE := Vector2(38.0, 38.0)
const GAME_OVER_PANEL_PATH := "res://assets/ui/game_over_panel.png"
const GOLD_DIGIT_SHEET_PATH := "res://assets/ui/gold_digit_sheet.png"
const COUNTDOWN_PATHS := [
	"res://assets/ui/countdown_3.png",
	"res://assets/ui/countdown_2.png",
	"res://assets/ui/countdown_1.png",
	"res://assets/ui/countdown_go.png",
]
const DEFAULT_CHARACTER_ID := "default"
const JUMP_FRAME_COUNT := 2
const JUMP_FRAME_AIR := 0
const JUMP_FRAME_MID := 1
const JUMP_APEX_VELOCITY_BAND := 180.0
const DEFAULT_BALANCE := preload("res://resources/balance/default_balance.tres")
const CHARACTER_BUTTON_RECT := Rect2(25.0, 1055.0, 210.0, 195.0)
const COOP_BUTTON_RECT := Rect2(255.0, 1055.0, 210.0, 195.0)
const SETTINGS_BUTTON_RECT := Rect2(485.0, 1055.0, 210.0, 195.0)
const TEST_START_50_RECT := Rect2(555.0, 670.0, 145.0, 82.0)
const GAME_OVER_CLOSE_RECT := Rect2(548.0, 394.0, 58.0, 58.0)
const CHARACTER_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const CHARACTER_PANEL_CLOSE_RECT := Rect2(616.0, 120.0, 52.0, 52.0)
# Category filter tabs (전체/기록/골드) sit in the space the old static
# instruction subtitle used to occupy. Everything below them (cards, page
# arrows) shifts down by this same amount so the bottom-anchored offsets in
# _draw_character_card stay correct without re-deriving them.
const CHARACTER_CATEGORY_ROW_RECT := Rect2(70.0, 215.0, 520.0, 44.0)
const CHARACTER_CATEGORY_TAB_RECTS := {
	"all": Rect2(70.0, 215.0, 168.0, 44.0),
	"score": Rect2(246.0, 215.0, 168.0, 44.0),
	"gold": Rect2(422.0, 215.0, 168.0, 44.0),
}
# The character grid scrolls vertically inside this viewport (a clipped child
# Control — see character_list_viewport) instead of paging left/right. Column
# x-positions and card size are LOCAL to that viewport, not full design space;
# they preserve the original card layout's proportions (panel inset ~22px,
# ~23px gutter between 190-wide cards).
const CHARACTER_LIST_VIEWPORT_RECT := Rect2(30.0, 265.0, 660.0, 605.0)
const CHARACTER_CARD_COLUMN_X := [22.0, 235.0, 448.0]
const CHARACTER_CARD_WIDTH := 190.0
# Cards are 445 tall so a character whose select-card preview is enlarged via
# scale_multiplier (e.g. tall ears at 1.3x) has headroom instead of poking out
# above the card's own top edge. The card BOTTOM (and therefore the name/
# 보유/선택 text, via the +85 offsets in _draw_character_card) is unchanged by
# this — only the top grows, both here and originally.
const CHARACTER_CARD_HEIGHT := 445.0
const CHARACTER_CARD_ROW_GAP := 20.0
const CHARACTER_CARD_ROW_HEIGHT := CHARACTER_CARD_HEIGHT + CHARACTER_CARD_ROW_GAP
const CHARACTER_GRID_COLUMNS := 3
const CHARACTER_SCROLL_DRAG_THRESHOLD := 6.0
const SETTINGS_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const SETTINGS_PANEL_CLOSE_RECT := Rect2(616.0, 120.0, 52.0, 52.0)
const SOUND_TOGGLE_RECT := Rect2(70.0, 280.0, 520.0, 80.0)
const VIBRATION_TOGGLE_RECT := Rect2(70.0, 380.0, 520.0, 80.0)
const NICKNAME_ROW_RECT := Rect2(70.0, 480.0, 520.0, 70.0)
const NICKNAME_FIELD_RECT := Rect2(200.0, 480.0, 260.0, 70.0)
const NICKNAME_SAVE_BUTTON_RECT := Rect2(470.0, 480.0, 120.0, 70.0)
const CODE_ROW_RECT := Rect2(70.0, 570.0, 520.0, 70.0)
const CODE_FIELD_RECT := Rect2(200.0, 570.0, 260.0, 70.0)
const CODE_SUBMIT_BUTTON_RECT := Rect2(470.0, 570.0, 120.0, 70.0)
const RANKING_BUTTON_RECT := Rect2(70.0, 660.0, 520.0, 80.0)
const RANKING_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const RANKING_PANEL_CLOSE_RECT := Rect2(616.0, 120.0, 52.0, 52.0)
const RANKING_LIST_RECT := Rect2(70.0, 280.0, 520.0, 480.0)
const RANKING_ROW_HEIGHT := 60.0

@export_group("Player Sprite")
@export var player_sprite: Texture2D
@export var player_jump_sprite: Texture2D
@export var player_sprite_max_size := Vector2(176.0, 176.0)
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
@export var coop_button_texture: Texture2D
@export var settings_button_texture: Texture2D
@export_group("HUD Title Assets")
@export var hud_title_frame_texture: Texture2D
@export var hud_title_logo_texture: Texture2D
@export var best_score_frame_texture: Texture2D
@export var gameplay_score_label_texture: Texture2D
@export var gameplay_best_label_texture: Texture2D
@export var resource_counter_frame_texture: Texture2D
@export var tap_prompt_texture: Texture2D
@export var coin_icon_texture: Texture2D
@export var ruby_icon_texture: Texture2D
@export var game_over_panel_texture: Texture2D
@export var gold_digit_sheet_texture: Texture2D
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
var coop_mode := false
var coop_left_jump_height := 0.0
var coop_left_jump_velocity := 0.0
var coop_left_jump_time := 0.0
var coop_left_is_jumping := false
var coop_right_jump_height := 0.0
var coop_right_jump_velocity := 0.0
var coop_right_jump_time := 0.0
var coop_right_is_jumping := false
var coop_hit_player := 0
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
var settings_menu_open := false
var nickname := RopeSaveManager.DEFAULT_NICKNAME
var nickname_edit: LineEdit
var code_edit: LineEdit
var settings_message := ""
var ranking_menu_open := false
var ranking_loading := false
var ranking_error := ""
var ranking_entries: Array = []
var leaderboard_submit_request: HTTPRequest
var leaderboard_fetch_request: HTTPRequest
var character_preview_textures: Dictionary = {}
var character_preview_regions: Dictionary = {}
var character_ids: Array[String] = []
var character_names: Dictionary = {}
var character_body_top_fractions: Dictionary = {}
var character_scale_multipliers: Dictionary = {}
var character_gameplay_scale_multipliers: Dictionary = {}
var character_air_pose_scale_multipliers: Dictionary = {}
var character_jump_pose_scale_multipliers: Dictionary = {}
var character_disable_jump_rescale: Dictionary = {}
var character_unlock_scores: Dictionary = {}
var character_prices: Dictionary = {}
var owned_character_ids: Array[String] = []
var character_list_viewport: Control
var character_scroll_offset := 0.0
var character_scroll_dragging := false
var character_scroll_moved := false
var character_scroll_press_position := Vector2.ZERO
var character_scroll_press_offset := 0.0
var character_category_filter := "all"
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
var coop_button_used_region := Rect2()
var settings_button_used_region := Rect2()
var best_score_frame_used_region := Rect2()
var gameplay_score_label_used_region := Rect2()
var gameplay_best_label_used_region := Rect2()
var resource_counter_frame_used_region := Rect2()
var tap_prompt_used_region := Rect2()
var coin_icon_used_region := Rect2()
var ruby_icon_used_region := Rect2()
var game_over_panel_used_region := Rect2()
var gold_digit_regions: Array[Rect2] = []
var countdown_textures: Array[Texture2D] = []
var countdown_used_regions: Array[Rect2] = []
var design_draw_offset := Vector2.ZERO
var design_draw_scale := 1.0


func _ready() -> void:
	# Character art is pixel-based. Nearest sampling prevents transparent
	# white matte pixels from being blended into the silhouette when previews
	# and in-game sprites are reduced to their display size.
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
	if coop_button_texture == null and ResourceLoader.exists(MENU_COOP_TEXTURE_PATH):
		coop_button_texture = load(MENU_COOP_TEXTURE_PATH) as Texture2D
	if settings_button_texture == null and ResourceLoader.exists(MENU_SETTINGS_TEXTURE_PATH):
		settings_button_texture = load(MENU_SETTINGS_TEXTURE_PATH) as Texture2D
	if hud_title_frame_texture == null and ResourceLoader.exists(HUD_TITLE_FRAME_PATH):
		hud_title_frame_texture = load(HUD_TITLE_FRAME_PATH) as Texture2D
	if hud_title_logo_texture == null and ResourceLoader.exists(HUD_TITLE_LOGO_PATH):
		hud_title_logo_texture = load(HUD_TITLE_LOGO_PATH) as Texture2D
	if best_score_frame_texture == null and ResourceLoader.exists(BEST_SCORE_FRAME_PATH):
		best_score_frame_texture = load(BEST_SCORE_FRAME_PATH) as Texture2D
	if gameplay_score_label_texture == null and ResourceLoader.exists(GAMEPLAY_SCORE_LABEL_PATH):
		gameplay_score_label_texture = load(GAMEPLAY_SCORE_LABEL_PATH) as Texture2D
	if gameplay_best_label_texture == null and ResourceLoader.exists(GAMEPLAY_BEST_LABEL_PATH):
		gameplay_best_label_texture = load(GAMEPLAY_BEST_LABEL_PATH) as Texture2D
	if resource_counter_frame_texture == null and ResourceLoader.exists(RESOURCE_COUNTER_FRAME_PATH):
		resource_counter_frame_texture = load(RESOURCE_COUNTER_FRAME_PATH) as Texture2D
	if tap_prompt_texture == null and ResourceLoader.exists(TAP_PROMPT_PATH):
		tap_prompt_texture = load(TAP_PROMPT_PATH) as Texture2D
	if coin_icon_texture == null and ResourceLoader.exists(COIN_ICON_PATH):
		coin_icon_texture = load(COIN_ICON_PATH) as Texture2D
	if ruby_icon_texture == null and ResourceLoader.exists(RUBY_ICON_PATH):
		ruby_icon_texture = load(RUBY_ICON_PATH) as Texture2D
	if game_over_panel_texture == null and ResourceLoader.exists(GAME_OVER_PANEL_PATH):
		game_over_panel_texture = load(GAME_OVER_PANEL_PATH) as Texture2D
	if gold_digit_sheet_texture == null and ResourceLoader.exists(GOLD_DIGIT_SHEET_PATH):
		gold_digit_sheet_texture = load(GOLD_DIGIT_SHEET_PATH) as Texture2D
	character_button_used_region = _texture_used_region(character_button_texture)
	coop_button_used_region = _texture_used_region(coop_button_texture)
	settings_button_used_region = _texture_used_region(settings_button_texture)
	best_score_frame_used_region = _texture_used_region(best_score_frame_texture)
	gameplay_score_label_used_region = _texture_used_region(gameplay_score_label_texture)
	gameplay_best_label_used_region = _texture_used_region(gameplay_best_label_texture)
	resource_counter_frame_used_region = _texture_used_region(resource_counter_frame_texture)
	tap_prompt_used_region = _texture_used_region(tap_prompt_texture)
	coin_icon_used_region = _texture_used_region(coin_icon_texture)
	ruby_icon_used_region = _texture_used_region(ruby_icon_texture)
	game_over_panel_used_region = _texture_used_region(game_over_panel_texture)
	_prepare_gold_digit_regions()
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
		if coop_mode:
			_advance_coop_jumps(delta)
		elif is_jumping:
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
			_submit_score(score)
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
	# The character list is drag-to-scroll, which needs press/move/release
	# tracked as a sequence — everything else in this game only ever cares
	# about a single press, so this lives as an early, self-contained branch
	# rather than reshaping the pressed-only model below for one screen.
	if character_menu_open and character_scroll_dragging:
		var motion_position := Vector2(-1.0, -1.0)
		if event is InputEventScreenDrag:
			motion_position = (event as InputEventScreenDrag).position
		elif event is InputEventMouseMotion:
			motion_position = (event as InputEventMouseMotion).position
		if motion_position.x >= 0.0:
			var local_position := _screen_to_design(motion_position) - CHARACTER_LIST_VIEWPORT_RECT.position
			_update_character_list_drag(local_position)
			get_viewport().set_input_as_handled()
			return
		var released := (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed) \
			or (event is InputEventMouseButton and not (event as InputEventMouseButton).pressed)
		if released:
			_end_character_list_drag()
			get_viewport().set_input_as_handled()
			return
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
				if CHARACTER_PANEL_CLOSE_RECT.has_point(design_position):
					_close_character_menu()
					get_viewport().set_input_as_handled()
					return
				if _handle_character_category_tap(design_position):
					get_viewport().set_input_as_handled()
					return
				if CHARACTER_LIST_VIEWPORT_RECT.has_point(design_position):
					_begin_character_list_drag(design_position - CHARACTER_LIST_VIEWPORT_RECT.position)
				get_viewport().set_input_as_handled()
				return
			if ranking_menu_open:
				_handle_ranking_menu_input(design_position)
				get_viewport().set_input_as_handled()
				return
			if settings_menu_open:
				_handle_settings_menu_input(design_position)
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
			if COOP_BUTTON_RECT.has_point(design_position):
				_start_coop_game()
				get_viewport().set_input_as_handled()
				return
			if SETTINGS_BUTTON_RECT.has_point(design_position):
				_open_settings_menu()
				get_viewport().set_input_as_handled()
				return
		if coop_mode:
			if pointer_position.x >= 0.0:
				attempt_coop_jump(_screen_to_design(pointer_position).x < DESIGN_SIZE.x * 0.5)
		else:
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


func attempt_coop_jump(left_player: bool) -> void:
	if game_state == GameState.HIT:
		return
	if game_state != GameState.PLAYING:
		_start_coop_game()
		return
	if not accepting_input:
		return
	if left_player:
		if coop_left_is_jumping:
			return
		coop_left_is_jumping = true
		coop_left_jump_height = 0.0
		coop_left_jump_velocity = -820.0
		coop_left_jump_time = 0.0
	else:
		if coop_right_is_jumping:
			return
		coop_right_is_jumping = true
		coop_right_jump_height = 0.0
		coop_right_jump_velocity = -820.0
		coop_right_jump_time = 0.0


func _advance_coop_jumps(delta: float) -> void:
	if coop_left_is_jumping:
		coop_left_jump_time += delta
		coop_left_jump_velocity += 1900.0 * delta
		coop_left_jump_height += coop_left_jump_velocity * delta
		if coop_left_jump_height >= 0.0:
			coop_left_jump_height = 0.0
			coop_left_jump_velocity = 0.0
			coop_left_jump_time = 0.0
			coop_left_is_jumping = false
	if coop_right_is_jumping:
		coop_right_jump_time += delta
		coop_right_jump_velocity += 1900.0 * delta
		coop_right_jump_height += coop_right_jump_velocity * delta
		if coop_right_jump_height >= 0.0:
			coop_right_jump_height = 0.0
			coop_right_jump_velocity = 0.0
			coop_right_jump_time = 0.0
			coop_right_is_jumping = false


func _resolve_rope_crossing() -> void:
	# Success is decided when the visible rope actually reaches the player's feet.
	if _player_clears_rope_at_crossing():
		score += 1
		if score > best_score:
			best_score = score
			new_best_this_run = true
			_check_score_unlocks()
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
		if coop_mode:
			message = "왼쪽 플레이어가 걸렸어요!" if coop_hit_player == 1 else "오른쪽 플레이어가 걸렸어요!"
		else:
			message = "앗! 줄에 걸렸어요!"
		message_color = Color("ff7892")
		flash_time = 0.5
		run_coins_earned = score + (5 if new_best_this_run else 0)
		coins += run_coins_earned
		total_runs += 1
		_save_progress()
		feedback.play_failure()


func _player_clears_rope_at_crossing() -> bool:
	if coop_mode:
		var left_clear := _coop_player_clears_rope(COOP_LEFT_PLAYER_X, coop_left_is_jumping, coop_left_jump_height)
		var right_clear := _coop_player_clears_rope(COOP_RIGHT_PLAYER_X, coop_right_is_jumping, coop_right_jump_height)
		coop_hit_player = 0 if left_clear and right_clear else (1 if not left_clear else 2)
		return left_clear and right_clear
	if not is_jumping:
		return false
	var rope_center_y := _rope_midpoint_y(ROPE_CROSSING_ANGLE)
	var rope_top_y := rope_center_y - ROPE_PIXEL_OUTLINE_SIZE.y * 0.5
	var player_feet_y := PLAYER_GROUND_Y + jump_height + player_sprite_ground_offset.y
	return player_feet_y < rope_top_y


func _coop_player_clears_rope(player_x: float, jumping: bool, height: float) -> bool:
	if not jumping:
		return false
	var rope_top_y := _rope_y_at_x(ROPE_CROSSING_ANGLE, player_x) - ROPE_PIXEL_OUTLINE_SIZE.y * 0.5
	return PLAYER_GROUND_Y + height + player_sprite_ground_offset.y < rope_top_y


func _start_game() -> void:
	coop_mode = false
	_reset_coop_players()
	_start_run()


func _start_coop_game() -> void:
	coop_mode = true
	_reset_coop_players()
	_start_run()
	message = "왼쪽과 오른쪽을 함께 점프!"


func _start_run() -> void:
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
	coop_mode = false
	_reset_coop_players()
	jump_started_in_cue = false
	accepting_input = true
	_reset_turner_run()
	hit_reveal_time = 0.0
	menu_notice = ""
	message = "화면을 눌러 시작"
	message_color = Color.WHITE
	queue_redraw()


func _reset_coop_players() -> void:
	coop_left_jump_height = 0.0
	coop_left_jump_velocity = 0.0
	coop_left_jump_time = 0.0
	coop_left_is_jumping = false
	coop_right_jump_height = 0.0
	coop_right_jump_velocity = 0.0
	coop_right_jump_time = 0.0
	coop_right_is_jumping = false
	coop_hit_player = 0


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
	_check_score_unlocks()
	var saved_character := str(data.selected_character)
	selected_character_id = saved_character if owned_character_ids.has(saved_character) else DEFAULT_CHARACTER_ID
	feedback.sound_enabled = bool(data.settings.sound)
	feedback.vibration_enabled = bool(data.settings.vibration)
	nickname = str(data.nickname)


func _check_score_unlocks() -> void:
	# Characters with a positive unlock_score in character.json start locked
	# and join owned_character_ids on their own once best_score reaches the
	# threshold — no purchase needed. Characters priced in gold instead (see
	# character_prices) are deliberately excluded from this: they only ever
	# unlock through the "buy" tap in the character menu.
	for character_id in character_ids:
		if owned_character_ids.has(character_id):
			continue
		var required_score := int(character_unlock_scores.get(character_id, 0))
		if required_score > 0 and best_score >= required_score:
			owned_character_ids.append(character_id)


func _save_progress() -> void:
	save_manager.save_game({
		"save_version": RopeSaveManager.SAVE_VERSION,
		"best_score": best_score,
		"coins": coins,
		"gems": gems,
		"selected_character": selected_character_id,
		"owned_characters": owned_character_ids,
		"nickname": nickname,
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
	if coop_mode and game_state != GameState.TITLE:
		_draw_coop_divider()
	# Each wizard illusion has its own phase and depth, so rear ropes are drawn
	# independently instead of sharing the real rope's layer.
	if not turner_transition_active:
		_draw_rope_layer(true)
	var left_turner_feet := COOP_LEFT_TURNER_FEET if coop_mode else LEFT_TURNER_FEET
	var right_turner_feet := COOP_RIGHT_TURNER_FEET if coop_mode else RIGHT_TURNER_FEET
	var active_left_turner_feet := left_turner_feet
	var active_right_turner_feet := right_turner_feet
	var visible_turner_team := -1
	if turner_transition_phase == TurnerTransitionPhase.TURNER_EXIT:
		var exit_progress := clampf(turner_transition_time / TURNER_EXIT_SECONDS, 0.0, 1.0)
		var eased_exit := exit_progress * exit_progress
		left_turner_feet = active_left_turner_feet.lerp(LEFT_TURNER_ENTRY_FEET, eased_exit)
		right_turner_feet = active_right_turner_feet.lerp(RIGHT_TURNER_ENTRY_FEET, eased_exit)
		visible_turner_team = departing_turner_team
	elif turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		var entry_progress := clampf(turner_transition_time / ATHLETE_ENTRY_SECONDS, 0.0, 1.0)
		var eased_entry := 1.0 - pow(1.0 - entry_progress, 3.0)
		left_turner_feet = LEFT_TURNER_ENTRY_FEET.lerp(active_left_turner_feet, eased_entry)
		right_turner_feet = RIGHT_TURNER_ENTRY_FEET.lerp(active_right_turner_feet, eased_entry)
		visible_turner_team = turner_team
	_draw_turner(left_turner_feet, false, visible_turner_team)
	_draw_turner(right_turner_feet, true, visible_turner_team)
	if coop_mode:
		_draw_coop_players()
	else:
		_draw_player()
	if turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		_draw_countdown_overlay()
	# Front ropes pass over the character visually, but only the real rope owns
	# the crossing/game-over rule.
	if not turner_transition_active:
		_draw_rope_layer(false)
	if game_state == GameState.HIT:
		_draw_hit_feedback()
	_draw_hud()


func _draw_coop_divider() -> void:
	draw_rect(Rect2(0.0, 0.0, DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(0.20, 0.55, 1.0, 0.055), true)
	draw_rect(Rect2(DESIGN_SIZE.x * 0.5, 0.0, DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(1.0, 0.35, 0.48, 0.055), true)
	draw_line(Vector2(DESIGN_SIZE.x * 0.5, 0.0), Vector2(DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(1.0, 1.0, 1.0, 0.72), 5.0, true)


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


func _draw_rope_layer(draw_behind: bool) -> void:
	var show_jump_cue := _is_jump_cue()
	var wizard_ghosted := _wizard_rope_is_ghosted()
	var rope_color := Color("ff334f") if show_jump_cue else Color("f6b73c")
	var highlight_color := Color("ff9a8d") if show_jump_cue else Color("ffe27a")
	var outline_color := Color("3b2119")
	var shadow_color := Color(0, 0, 0, 0.22)
	if wizard_ghosted:
		rope_color = Color(0.20, 0.72, 1.0, WIZARD_GHOST_CORE_ALPHA)
		highlight_color = Color(0.62, 0.94, 1.0, WIZARD_GHOST_HIGHLIGHT_ALPHA)
		outline_color = Color(0.05, 0.22, 0.42, WIZARD_GHOST_OUTLINE_ALPHA)
		shadow_color = Color(0.02, 0.15, 0.30, 0.0)
	if _wizard_illusions_are_active():
		var illusion_core := Color(0.20, 0.72, 1.0, WIZARD_GHOST_CORE_ALPHA * 0.55)
		var illusion_highlight := Color(0.62, 0.94, 1.0, WIZARD_GHOST_HIGHLIGHT_ALPHA * 0.45)
		var illusion_outline := Color(0.05, 0.22, 0.42, WIZARD_GHOST_OUTLINE_ALPHA * 0.45)
		for illusion_angle in _wizard_illusion_angles():
			if _rope_angle_is_behind(illusion_angle) == draw_behind:
				_draw_rope_curve(illusion_angle, illusion_core, illusion_highlight, illusion_outline, Color.TRANSPARENT, cos(illusion_angle) * WIZARD_ILLUSION_LATERAL_SWAY)
	if _rope_angle_is_behind(rope_angle) == draw_behind:
		_draw_rope_curve(rope_angle, rope_color, highlight_color, outline_color, shadow_color)
		_draw_pixel_rope_grip(_active_left_hand(), wizard_ghosted)
		_draw_pixel_rope_grip(_active_right_hand(), wizard_ghosted)


func _draw_rope_curve(curve_angle: float, rope_color: Color, highlight_color: Color, outline_color: Color, shadow_color: Color, lateral_offset := 0.0) -> void:
	var midpoint_y := _rope_midpoint_y(curve_angle)
	var left_hand := _active_left_hand()
	var right_hand := _active_right_hand()
	var pixel_points := PackedVector2Array()
	for i in range(97):
		var t := float(i) / 96.0
		var x := lerpf(left_hand.x, right_hand.x, t) + 4.0 * t * (1.0 - t) * lateral_offset
		# 4t(1-t) is zero at both hands and one at the middle.
		var y := lerpf(left_hand.y, right_hand.y, t) + 4.0 * t * (1.0 - t) * (midpoint_y - left_hand.y)
		var pixel_point := Vector2(
			roundf(x / ROPE_PIXEL_GRID) * ROPE_PIXEL_GRID,
			roundf(y / ROPE_PIXEL_GRID) * ROPE_PIXEL_GRID
		)
		if pixel_points.is_empty() or pixel_points[-1] != pixel_point:
			pixel_points.append(pixel_point)

	# Draw in separate passes so the square pieces merge into one outlined pixel rope.
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_OUTLINE_SIZE * 0.5 + Vector2(2.0, 3.0), ROPE_PIXEL_OUTLINE_SIZE), shadow_color)
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_OUTLINE_SIZE * 0.5, ROPE_PIXEL_OUTLINE_SIZE), outline_color)
	for point in pixel_points:
		draw_rect(Rect2(point - ROPE_PIXEL_CORE_SIZE * 0.5, ROPE_PIXEL_CORE_SIZE), rope_color)
	for i in range(0, pixel_points.size(), 3):
		draw_rect(Rect2(pixel_points[i] + Vector2(-3.0, -3.0), Vector2(3.0, 3.0)), highlight_color)


func _wizard_rope_is_ghosted() -> bool:
	return turner_team == TurnerTeam.WIZARD and wizard_rope_hidden and not _is_jump_cue()


func _wizard_illusions_are_active() -> bool:
	return turner_team == TurnerTeam.WIZARD and wizard_rope_hidden


func _wizard_illusion_angles() -> PackedFloat32Array:
	var angles := PackedFloat32Array()
	for phase in WIZARD_ILLUSION_PHASES:
		angles.append(fposmod(rope_angle + phase, TAU))
	return angles


func _rope_angle_is_behind(angle: float) -> bool:
	return cos(angle) < 0.0


func _rope_midpoint_y(angle: float) -> float:
	var vertical_phase := sin(angle)
	var radius := ROPE_GROUND_RADIUS if vertical_phase >= 0.0 else ROPE_OVERHEAD_RADIUS
	return _active_left_hand().y + vertical_phase * radius


func _rope_y_at_x(angle: float, x: float) -> float:
	var left_hand := _active_left_hand()
	var right_hand := _active_right_hand()
	var t := clampf((x - left_hand.x) / (right_hand.x - left_hand.x), 0.0, 1.0)
	return lerpf(left_hand.y, right_hand.y, t) + 4.0 * t * (1.0 - t) * (_rope_midpoint_y(angle) - left_hand.y)


func _active_left_hand() -> Vector2:
	return COOP_LEFT_HAND if coop_mode else LEFT_HAND


func _active_right_hand() -> Vector2:
	return COOP_RIGHT_HAND if coop_mode else RIGHT_HAND


func _draw_pixel_rope_grip(center: Vector2, ghosted := false) -> void:
	var outline := Color(0.05, 0.22, 0.42, WIZARD_GHOST_OUTLINE_ALPHA) if ghosted else Color("3b2119")
	var core := Color(0.20, 0.72, 1.0, WIZARD_GHOST_CORE_ALPHA) if ghosted else Color("f6b73c")
	var shine := Color(0.62, 0.94, 1.0, WIZARD_GHOST_HIGHLIGHT_ALPHA) if ghosted else Color("ffe27a")
	draw_rect(Rect2(center - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), outline)
	draw_rect(Rect2(center - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), core)
	draw_rect(Rect2(center + Vector2(-4.0, -4.0), Vector2(4.0, 4.0)), shine)


func _draw_hit_feedback() -> void:
	var contact_x := PLAYER_X
	if coop_mode:
		contact_x = COOP_LEFT_PLAYER_X if coop_hit_player == 1 else COOP_RIGHT_PLAYER_X
	var contact := Vector2(contact_x, PLAYER_GROUND_Y - 3.0)
	draw_circle(contact, 24.0, Color(1.0, 0.18, 0.28, 0.34))
	for direction in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 0.35), Vector2(1.0, 0.35)]:
		draw_line(contact + direction * 12.0, contact + direction * 35.0, Color("ff334f"), 6.0, true)


func _rope_is_behind() -> bool:
	# The descending half comes toward the player; the rising half moves behind.
	return cos(rope_angle) < 0.0


func _is_jump_cue() -> bool:
	if game_state != GameState.PLAYING or rope_speed <= 0.0 or _rope_is_behind():
		return false
	var seconds_until_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_angle, TAU) / rope_speed
	return seconds_until_crossing <= balance.jump_cue_seconds


func _effective_rope_speed() -> float:
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
	var hand := _active_left_hand() if not faces_left else _active_right_hand()
	draw_line(shoulder + Vector2(direction * 4.0, 2.0), hand, Color("ff7a68"), 13.0, true)
	draw_circle(hand, 9.0, Color("ffe0bd"))
	draw_line(shoulder - Vector2(direction * 5.0, -2.0), feet + Vector2(-direction * 25.0, -64.0), Color("ff7a68"), 13.0, true)


func _draw_player() -> void:
	var p := Vector2(PLAYER_X, PLAYER_GROUND_Y + jump_height)
	# Shadow
	var shadow_scale := clampf(1.0 + jump_height / 650.0, 0.45, 1.0)
	_draw_shadow_ellipse(Vector2(PLAYER_X, PLAYER_GROUND_Y + 18.0), Vector2(70.0 * shadow_scale, 18.0), Color(0, 0, 0, 0.28))
	if player_sprite != null:
		_draw_player_sprite(p, is_jumping, jump_velocity)
	else:
		_draw_default_player(p)


func _draw_coop_players() -> void:
	_draw_coop_player(COOP_LEFT_PLAYER_X, coop_left_jump_height, coop_left_is_jumping, coop_left_jump_velocity)
	_draw_coop_player(COOP_RIGHT_PLAYER_X, coop_right_jump_height, coop_right_is_jumping, coop_right_jump_velocity)


func _draw_coop_player(player_x: float, height: float, jumping: bool, velocity: float) -> void:
	var feet := Vector2(player_x, PLAYER_GROUND_Y + height)
	var shadow_scale := clampf(1.0 + height / 650.0, 0.45, 1.0)
	_draw_shadow_ellipse(Vector2(player_x, PLAYER_GROUND_Y + 18.0), Vector2(58.0 * shadow_scale, 16.0), Color(0, 0, 0, 0.28))
	if player_sprite != null:
		_draw_player_sprite(feet, jumping, velocity)
	else:
		_draw_default_player(feet)


func _draw_player_sprite(feet_position: Vector2, jumping: bool, velocity: float) -> void:
	var active_texture := player_sprite
	var source_rect := player_base_region
	var using_jump_sheet := false
	if jumping and player_jump_sprite != null and player_jump_regions.size() == JUMP_FRAME_COUNT:
		using_jump_sheet = true
		active_texture = player_jump_sprite
		# Jump sequence: idle -> mid -> air -> mid -> idle (1-3-2-3-1).
		# Idle (the still texture) plays before takeoff and after landing;
		# the mid pose plays on the way up and down, with the air pose only
		# at the velocity-near-zero apex.
		var frame := JUMP_FRAME_MID
		if absf(velocity) < JUMP_APEX_VELOCITY_BAND:
			frame = JUMP_FRAME_AIR
		source_rect = player_jump_regions[frame]
	var texture_size := source_rect.size
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_draw_default_player(feet_position)
		return
	var draw_size := texture_size * player_jump_scale if using_jump_sheet else texture_size * player_base_scale
	if using_jump_sheet and absf(velocity) < JUMP_APEX_VELOCITY_BAND:
		# Per-character correction for the air/apex pose specifically — some
		# source art has its arms flung wide in this pose, which (with jump
		# rescale disabled) reads as visibly bigger than the other frames even
		# though it's shorter in height. See air_pose_scale_multiplier in
		# character.json.
		draw_size *= float(character_air_pose_scale_multipliers.get(selected_character_id, 1.0))
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


func _handle_character_category_tap(position: Vector2) -> bool:
	for category in CHARACTER_CATEGORY_TAB_RECTS.keys():
		if (CHARACTER_CATEGORY_TAB_RECTS[category] as Rect2).has_point(position):
			if character_category_filter != category:
				character_category_filter = category
				character_scroll_offset = 0.0
			return true
	return false


func _character_scroll_max() -> float:
	var count := _filtered_character_ids().size()
	if count <= 0:
		return 0.0
	var rows := int(ceil(float(count) / float(CHARACTER_GRID_COLUMNS)))
	var content_height := float(rows) * CHARACTER_CARD_ROW_HEIGHT
	return maxf(0.0, content_height - CHARACTER_LIST_VIEWPORT_RECT.size.y)


func _begin_character_list_drag(position: Vector2) -> void:
	character_scroll_dragging = true
	character_scroll_moved = false
	character_scroll_press_position = position
	character_scroll_press_offset = character_scroll_offset


func _update_character_list_drag(position: Vector2) -> void:
	var delta_y := position.y - character_scroll_press_position.y
	if absf(delta_y) > CHARACTER_SCROLL_DRAG_THRESHOLD:
		character_scroll_moved = true
	character_scroll_offset = clampf(character_scroll_press_offset - delta_y, 0.0, _character_scroll_max())
	if character_list_viewport != null:
		character_list_viewport.queue_redraw()


func _end_character_list_drag() -> void:
	character_scroll_dragging = false
	if not character_scroll_moved:
		_handle_character_card_tap(character_scroll_press_position)


func _handle_character_card_tap(position: Vector2) -> void:
	# position is in CHARACTER_LIST_VIEWPORT_RECT design space (i.e. already
	# offset so (0,0) is the viewport's own top-left), matching the local
	# coordinates cards are drawn in inside _draw_character_list_contents.
	var filtered := _filtered_character_ids()
	var content_y := position.y + character_scroll_offset
	var row := int(floor(content_y / CHARACTER_CARD_ROW_HEIGHT))
	if row < 0:
		return
	if content_y - float(row) * CHARACTER_CARD_ROW_HEIGHT > CHARACTER_CARD_HEIGHT:
		return  # tapped in the gap between rows
	var col := -1
	for i in range(CHARACTER_CARD_COLUMN_X.size()):
		var column_x: float = CHARACTER_CARD_COLUMN_X[i]
		if position.x >= column_x and position.x <= column_x + CHARACTER_CARD_WIDTH:
			col = i
			break
	if col == -1:
		return
	var index := row * CHARACTER_GRID_COLUMNS + col
	if index < 0 or index >= filtered.size():
		return
	var character_id: String = filtered[index]
	if owned_character_ids.has(character_id):
		if set_player_character(character_id):
			menu_notice = "%s 선택" % character_names.get(character_id, character_id)
			_save_progress()
		return
	var price := int(character_prices.get(character_id, 0))
	if price > 0:
		if coins >= price:
			coins -= price
			owned_character_ids.append(character_id)
			set_player_character(character_id)
			menu_notice = "%s 구매 완료!" % character_names.get(character_id, character_id)
			_save_progress()
		else:
			menu_notice = "골드가 부족합니다 (%d 골드 필요)" % price
	else:
		var required_score := int(character_unlock_scores.get(character_id, 0))
		menu_notice = "최고 기록 %d점에 해금됩니다" % required_score


func _design_to_screen_rect(rect: Rect2) -> Rect2:
	return Rect2(design_draw_offset + rect.position * design_draw_scale, rect.size * design_draw_scale)


func _close_character_menu() -> void:
	character_menu_open = false
	character_scroll_dragging = false
	if character_list_viewport != null:
		character_list_viewport.visible = false


func _open_settings_menu() -> void:
	settings_menu_open = true
	settings_message = ""
	if nickname_edit == null:
		nickname_edit = LineEdit.new()
		nickname_edit.max_length = RopeSaveManager.NICKNAME_MAX_LENGTH
		add_child(nickname_edit)
	nickname_edit.text = nickname
	nickname_edit.size = _design_to_screen_rect(NICKNAME_FIELD_RECT).size
	nickname_edit.position = _design_to_screen_rect(NICKNAME_FIELD_RECT).position
	nickname_edit.visible = true
	if code_edit == null:
		code_edit = LineEdit.new()
		add_child(code_edit)
	code_edit.text = ""
	code_edit.placeholder_text = "코드 입력"
	code_edit.size = _design_to_screen_rect(CODE_FIELD_RECT).size
	code_edit.position = _design_to_screen_rect(CODE_FIELD_RECT).position
	code_edit.visible = true


func _close_settings_menu() -> void:
	settings_menu_open = false
	if nickname_edit != null:
		nickname_edit.visible = false
	if code_edit != null:
		code_edit.visible = false


func _open_ranking_menu() -> void:
	ranking_menu_open = true
	if nickname_edit != null:
		nickname_edit.visible = false
	if code_edit != null:
		code_edit.visible = false
	_fetch_ranking()


func _close_ranking_menu() -> void:
	ranking_menu_open = false
	if nickname_edit != null:
		nickname_edit.visible = true
	if code_edit != null:
		code_edit.visible = true


func _handle_ranking_menu_input(position: Vector2) -> void:
	if RANKING_PANEL_CLOSE_RECT.has_point(position):
		_close_ranking_menu()


func _fetch_ranking() -> void:
	ranking_loading = true
	ranking_error = ""
	if leaderboard_fetch_request == null:
		leaderboard_fetch_request = HTTPRequest.new()
		add_child(leaderboard_fetch_request)
		# The Web export's HTTPRequest can't reliably inflate a gzip-encoded
		# response body (stream_peer_gzip fails partway through), which
		# corrupts the JSON before we ever see it. Supabase compresses
		# responses by default, so ask for uncompressed output instead of
		# fighting the decompressor.
		leaderboard_fetch_request.accept_gzip = false
		leaderboard_fetch_request.request_completed.connect(_on_ranking_fetched)
	var url := "%s/rest/v1/leaderboard?select=nickname,score&order=score.desc&limit=%d" % [SUPABASE_URL, LEADERBOARD_TOP_N]
	var headers := ["apikey: %s" % SUPABASE_ANON_KEY, "Accept-Encoding: identity"]
	var error := leaderboard_fetch_request.request(url, headers)
	if error != OK:
		ranking_loading = false
		ranking_error = "랭킹을 불러올 수 없습니다 (요청 실패: %d)" % error
		queue_redraw()


func _on_ranking_fetched(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	ranking_loading = false
	if result != HTTPRequest.RESULT_SUCCESS:
		# result codes: see HTTPRequest.Result — e.g. CANT_CONNECT, CANT_RESOLVE,
		# TLS_HANDSHAKE_ERROR. Surfacing the number lets us tell a DNS/TLS
		# failure apart from a plain HTTP error without needing device logs.
		ranking_error = "랭킹을 불러올 수 없습니다 (연결 실패: %d)" % result
		queue_redraw()
		return
	if response_code < 200 or response_code >= 300:
		ranking_error = "랭킹을 불러올 수 없습니다 (서버 응답: %d)" % response_code
		queue_redraw()
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array:
		ranking_error = "랭킹을 불러올 수 없습니다 (응답 해석 실패)"
		queue_redraw()
		return
	ranking_entries = parsed as Array
	queue_redraw()


func _submit_score(final_score: int) -> void:
	if final_score <= 0:
		return
	if leaderboard_submit_request == null:
		leaderboard_submit_request = HTTPRequest.new()
		add_child(leaderboard_submit_request)
		leaderboard_submit_request.accept_gzip = false
	var url := "%s/rest/v1/leaderboard" % SUPABASE_URL
	var headers := [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Accept-Encoding: identity",
	]
	var payload := JSON.stringify({"nickname": nickname, "score": final_score})
	leaderboard_submit_request.request(url, headers, HTTPClient.METHOD_POST, payload)


func _handle_settings_menu_input(position: Vector2) -> void:
	if SETTINGS_PANEL_CLOSE_RECT.has_point(position):
		_close_settings_menu()
		return
	if SOUND_TOGGLE_RECT.has_point(position):
		feedback.sound_enabled = not feedback.sound_enabled
		_save_progress()
		return
	if VIBRATION_TOGGLE_RECT.has_point(position):
		feedback.vibration_enabled = not feedback.vibration_enabled
		_save_progress()
		return
	if NICKNAME_SAVE_BUTTON_RECT.has_point(position):
		var new_nickname := nickname_edit.text.strip_edges()
		nickname = new_nickname if not new_nickname.is_empty() else RopeSaveManager.DEFAULT_NICKNAME
		nickname_edit.text = nickname
		settings_message = "닉네임 저장됨"
		_save_progress()
		return
	if CODE_SUBMIT_BUTTON_RECT.has_point(position):
		# Redeem-code validation and hidden-character rewards are not
		# implemented yet — this just acknowledges the input for now.
		settings_message = "코드 확인 준비 중"
		code_edit.text = ""
		return
	if RANKING_BUTTON_RECT.has_point(position):
		_open_ranking_menu()
		return


func _load_character_catalog() -> void:
	character_ids.clear()
	character_names.clear()
	character_body_top_fractions.clear()
	character_scale_multipliers.clear()
	character_gameplay_scale_multipliers.clear()
	character_air_pose_scale_multipliers.clear()
	character_jump_pose_scale_multipliers.clear()
	character_disable_jump_rescale.clear()
	character_unlock_scores.clear()
	character_prices.clear()
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
			"body_top_fraction": 0.0,
			"scale_multiplier": 1.0,
			"gameplay_scale_multiplier": 1.0,
			"air_pose_scale_multiplier": 1.0,
			"jump_pose_scale_multiplier": 1.0,
			"disable_jump_rescale": false,
			"unlock_score": 0,
			"price": 0,
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
		character_body_top_fractions[character_id] = clampf(float(entry.body_top_fraction), 0.0, 0.45)
		character_scale_multipliers[character_id] = clampf(float(entry.scale_multiplier), 0.5, 2.0)
		character_gameplay_scale_multipliers[character_id] = clampf(float(entry.gameplay_scale_multiplier), 0.5, 2.0)
		character_air_pose_scale_multipliers[character_id] = clampf(float(entry.air_pose_scale_multiplier), 0.5, 1.5)
		character_jump_pose_scale_multipliers[character_id] = clampf(float(entry.jump_pose_scale_multiplier), 0.5, 1.5)
		character_disable_jump_rescale[character_id] = bool(entry.disable_jump_rescale)
		character_unlock_scores[character_id] = maxi(0, int(entry.unlock_score))
		character_prices[character_id] = maxi(0, int(entry.price))
		if bool(entry.unlocked_by_default):
			owned_character_ids.append(character_id)
	if character_ids.has(DEFAULT_CHARACTER_ID) and not owned_character_ids.has(DEFAULT_CHARACTER_ID):
		owned_character_ids.push_front(DEFAULT_CHARACTER_ID)


func _filtered_character_ids() -> Array[String]:
	# "score" and "gold" split the roster by how a locked character is
	# unlocked — a character always belongs to exactly one of those groups,
	# via character_unlock_scores / character_prices set in
	# _load_character_catalog. The starter (unlock_score 0, price 0) only
	# shows up under "all", since it isn't something to unlock at all.
	if character_category_filter == "all":
		return character_ids
	var result: Array[String] = []
	for character_id in character_ids:
		if character_category_filter == "score" and int(character_unlock_scores.get(character_id, 0)) > 0:
			result.append(character_id)
		elif character_category_filter == "gold" and int(character_prices.get(character_id, 0)) > 0:
			result.append(character_id)
	return result


func _ensure_character_list_viewport() -> void:
	if character_list_viewport == null:
		character_list_viewport = Control.new()
		character_list_viewport.clip_contents = true
		# All hit-testing for this panel already happens manually in
		# _unhandled_input against design-space rects, the same way every
		# other menu in this game works — this viewport exists purely to
		# clip card drawing to a scroll window, so it must never intercept
		# input itself (that would fight the manual drag/tap handling).
		character_list_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_list_viewport.draw.connect(_draw_character_list_contents)
		add_child(character_list_viewport)
	var screen_rect := _design_to_screen_rect(CHARACTER_LIST_VIEWPORT_RECT)
	character_list_viewport.position = screen_rect.position
	character_list_viewport.size = screen_rect.size
	character_list_viewport.visible = true
	character_list_viewport.queue_redraw()


func _draw_character_list_contents() -> void:
	var font := ThemeDB.fallback_font
	var filtered := _filtered_character_ids()
	for index in range(filtered.size()):
		var row := index / CHARACTER_GRID_COLUMNS
		var col := index % CHARACTER_GRID_COLUMNS
		var y := float(row) * CHARACTER_CARD_ROW_HEIGHT - character_scroll_offset
		if y + CHARACTER_CARD_HEIGHT < 0.0 or y > CHARACTER_LIST_VIEWPORT_RECT.size.y:
			continue
		var card_rect := Rect2(CHARACTER_CARD_COLUMN_X[col], y, CHARACTER_CARD_WIDTH, CHARACTER_CARD_HEIGHT)
		_draw_character_card(character_list_viewport, font, filtered[index], card_rect)


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
	if selected_character_id == "pirate_girl":
		# The source bullfighter art has extra transparent padding around its
		# standing pose; keep its in-game height consistent with the roster.
		player_base_scale *= 1.35
	# Per-character in-game size tweak (distinct from scale_multiplier, which
	# only affects the character-select card preview) — e.g. a deliberately
	# smaller/larger character while keeping the auto-fit sizing intact.
	var gameplay_scale := float(character_gameplay_scale_multipliers.get(selected_character_id, 1.0))
	player_base_scale *= gameplay_scale
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
		if bool(character_disable_jump_rescale.get(selected_character_id, false)):
			# This character's idle.png and jump_sheet.png were built from one
			# source image at one consistent scale (see the character-import
			# skill), so there is no real DPI mismatch to correct for. A
			# crouched jump pose is legitimately shorter than standing —
			# rescaling to match heights would make it visibly balloon
			# mid-jump instead of just looking crouched.
			player_jump_scale = Vector2.ONE * player_base_scale
		else:
			# Use whichever jump pose is tallest as the scale reference. A pose
			# with bent knees or tucked limbs has a shorter silhouette than
			# standing, and sizing off a short pose inflates the uniform
			# scale, making the character visibly grow mid-jump.
			var reference_height := 0.0
			for region in player_jump_regions:
				reference_height = maxf(reference_height, region.size.y)
			# Use one scale on both axes. The former per-axis fit forced every
			# jump pose into the idle pose's bounding box, visibly squeezing
			# wide poses.
			var uniform_jump_scale := player_base_region.size.y * player_base_scale / reference_height
			player_jump_scale = Vector2.ONE * uniform_jump_scale
		# Per-character correction applied to both jump frames (mid and air) —
		# distinct from air_pose_scale_multiplier, which only touches the apex
		# frame. Use when a character's whole jump sequence reads as too big
		# relative to its idle pose.
		player_jump_scale *= float(character_jump_pose_scale_multipliers.get(selected_character_id, 1.0))


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
	# Size the actual person, not hats, ears, or other tall accessories. This
	# keeps faces and bodies comparable without stretching the source artwork.
	var body_top_fraction := float(character_body_top_fractions.get(selected_character_id, 0.0))
	var body_height := region.size.y * (1.0 - body_top_fraction)
	var body_scale := player_sprite_max_size.y / body_height
	var width_limit := player_sprite_max_size.x / region.size.x
	var total_height_limit := player_sprite_max_size.y * 1.4 / region.size.y
	return minf(body_scale, minf(width_limit, total_height_limit))


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
		if settings_menu_open:
			_draw_settings_menu(font)
		if ranking_menu_open:
			_draw_ranking_menu(font)
		return
	if gameplay_score_label_texture != null and gameplay_score_label_used_region.size.x > 0.0:
		var score_label_rect := Rect2(38.0, 39.0, 180.0, 78.0)
		draw_texture_rect_region(gameplay_score_label_texture, score_label_rect, gameplay_score_label_used_region)
	else:
		draw_string(font, Vector2(42, 82), "줄넘킹", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("91a4cc"))
	var score_cell_size := 10.0 + clampf(flash_time / 0.22, 0.0, 1.0) * 2.0
	_draw_image_number(str(score), Vector2(42.0, 101.0), score_cell_size * 7.0)
	if gameplay_best_label_texture != null and gameplay_best_label_used_region.size.x > 0.0:
		var best_label_rect := Rect2(472.0, 45.0, 160.0, 70.0)
		draw_texture_rect_region(gameplay_best_label_texture, best_label_rect, gameplay_best_label_used_region)
	else:
		draw_string(font, Vector2(480, 82), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff0a6"))
	_draw_image_number(str(best_score), Vector2(570.0, 54.0), 31.0)
	if game_state != GameState.GAME_OVER:
		draw_string(font, Vector2(0, 1120), message, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 31, message_color)
	var control_text := "왼쪽 터치: 1P · 오른쪽 터치: 2P" if coop_mode else "화면 터치 · 마우스 클릭 · SPACE"
	if game_state == GameState.GAME_OVER:
		control_text = "화면을 눌러 즉시 재시작"
	draw_string(font, Vector2(0, 1190), control_text, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("8293b7"))
	if game_state == GameState.GAME_OVER:
		_draw_game_over_panel(font)


func _draw_game_over_panel(font: Font) -> void:
	var panel := Rect2(95.0, 380.0, 530.0, 430.0)
	if game_over_panel_texture != null and game_over_panel_used_region.size.x > 0.0:
		draw_texture_rect_region(game_over_panel_texture, panel, game_over_panel_used_region)
	else:
		draw_rect(panel, Color(0.035, 0.055, 0.10, 0.94), true)
		draw_rect(panel, Color("fff0a6"), false, 7.0)
	draw_circle(GAME_OVER_CLOSE_RECT.get_center(), 26.0, Color("ff4d67"))
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(-9.0, -9.0), GAME_OVER_CLOSE_RECT.get_center() + Vector2(9.0, 9.0), Color.WHITE, 5.0, true)
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(9.0, -9.0), GAME_OVER_CLOSE_RECT.get_center() + Vector2(-9.0, 9.0), Color.WHITE, 5.0, true)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 116.0), "도전 종료!", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 40, Color("ff6b6b"))
	draw_string(font, Vector2(panel.position.x, panel.position.y + 151.0), "이번 기록", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 22, Color("fff0a6"))
	_draw_image_number(str(score), Vector2(panel.position.x + 65.0, panel.position.y + 163.0), 48.0, panel.size.x - 130.0, HORIZONTAL_ALIGNMENT_CENTER)

	var best_rect := Rect2(panel.position + Vector2(60.0, 230.0), Vector2(250.0, 54.0))
	var coin_rect := Rect2(panel.position + Vector2(320.0, 230.0), Vector2(150.0, 54.0))
	draw_rect(best_rect, Color(0.12, 0.06, 0.025, 0.72), true)
	draw_rect(coin_rect, Color(0.12, 0.06, 0.025, 0.72), true)
	draw_rect(best_rect, Color("d99b2b"), false, 3.0)
	draw_rect(coin_rect, Color("d99b2b"), false, 3.0)
	draw_string(font, Vector2(best_rect.position.x + 12.0, best_rect.position.y + 35.0), "최고 기록", HORIZONTAL_ALIGNMENT_LEFT, 112.0, 20, Color("fff0a6"))
	_draw_image_number(str(best_score), Vector2(best_rect.position.x + 126.0, best_rect.position.y + 10.0), 25.0, 108.0, HORIZONTAL_ALIGNMENT_CENTER)
	draw_string(font, Vector2(coin_rect.position.x, coin_rect.position.y + 35.0), "코인  +%d" % run_coins_earned, HORIZONTAL_ALIGNMENT_CENTER, coin_rect.size.x, 20, Color("ffd166"))
	var record_message := ""
	if new_best_this_run:
		record_message = "왕관 갱신! 새 최고 기록"
	elif score == run_start_best:
		record_message = "최고 기록과 타이!"
	else:
		record_message = "최고 기록까지 단 %d회" % maxi(1, run_start_best - score)
	draw_string(font, Vector2(panel.position.x, panel.position.y + 318.0), record_message, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 23, Color("73f7b4"))
	var retry_rect := Rect2(panel.position + Vector2(75.0, 338.0), Vector2(380.0, 58.0))
	draw_rect(retry_rect, Color("ffd23f"), true)
	draw_rect(retry_rect, Color("fff0a6"), false, 5.0)
	draw_string(font, Vector2(retry_rect.position.x, retry_rect.position.y + 39.0), "터치해서 다시 도전!", HORIZONTAL_ALIGNMENT_CENTER, retry_rect.size.x, 24, Color("633913"))


func _draw_main_menu(font: Font) -> void:
	_draw_resource_counter(font, Rect2(40.0, 22.0, 300.0, 62.0), coin_icon_texture, coin_icon_used_region, coins, COIN_ICON_OFFSET)
	_draw_resource_counter(font, Rect2(380.0, 22.0, 300.0, 62.0), ruby_icon_texture, ruby_icon_used_region, gems, RUBY_ICON_OFFSET)

	_draw_main_menu_title(font)
	var best_rect := Rect2(235.0, 306.0, 250.0, 64.0)
	if best_score_frame_texture != null and best_score_frame_used_region.size.x > 0.0:
		draw_texture_rect_region(best_score_frame_texture, best_rect, best_score_frame_used_region)
		draw_string(font, Vector2(278.0, 347.0), "최고 기록", HORIZONTAL_ALIGNMENT_CENTER, 105.0, 21, Color("fff0a6"))
	_draw_image_number(str(best_score), Vector2(390.0, 326.0), 22.0, 76.0, HORIZONTAL_ALIGNMENT_CENTER)

	var prompt_alpha := 0.78 + sin(Time.get_ticks_msec() * 0.004) * 0.18
	var prompt_rect := Rect2(201.0, 462.0, 408.0, 154.0)
	if tap_prompt_texture != null and tap_prompt_used_region.size.x > 0.0:
		# The prompt art is a near-white silhouette, which disappears against
		# the light sky/street background behind it — a dark offset copy
		# (tinted via modulate, since the source is mostly white) reads as a
		# drop shadow and keeps it legible without redesigning the asset.
		var shadow_rect := Rect2(prompt_rect.position + Vector2(3.0, 4.0), prompt_rect.size)
		_draw_rotated_texture_region(tap_prompt_texture, shadow_rect, tap_prompt_used_region, 0.0, Color(0.0, 0.0, 0.0, prompt_alpha * 0.55))
		_draw_rotated_texture_region(tap_prompt_texture, prompt_rect, tap_prompt_used_region, 0.0, Color(1.0, 1.0, 1.0, prompt_alpha))
	else:
		draw_string(font, Vector2(prompt_rect.position.x, 980.0), "TAP TO START", HORIZONTAL_ALIGNMENT_CENTER, prompt_rect.size.x, 30, Color(1.0, 1.0, 1.0, prompt_alpha))

	_draw_menu_asset_or_fallback(character_button_texture, character_button_used_region, font, CHARACTER_BUTTON_RECT, "CHARACTER", "캐릭터", Color("ef8f6b"))
	_draw_menu_asset_or_fallback(coop_button_texture, coop_button_used_region, font, COOP_BUTTON_RECT, "CO-OP", "협동 모드", Color("65b7f3"))
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
	if hud_title_logo_texture != null:
		# The current title_logo art is a self-contained plaque with its own
		# border baked in, so it replaces the separate frame texture outright
		# — drawing both stacked a second box around it ("box inside a box").
		draw_texture_rect(hud_title_logo_texture, frame_rect, false)
	elif hud_title_frame_texture != null:
		draw_texture_rect(hud_title_frame_texture, frame_rect, false)
		draw_string(font, Vector2(160.0, 225.0), "줄넘킹", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 54, Color("ffd23f"))
	else:
		draw_rect(frame_rect, Color("3a2418"), true)
		draw_rect(frame_rect, Color("ffd23f"), false, 7.0)
		draw_string(font, Vector2(160.0, 225.0), "줄넘킹", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 54, Color("ffd23f"))


func _draw_character_category_tabs(font: Font) -> void:
	var labels := {"all": "전체", "score": "기록", "gold": "골드"}
	var categories: Array[String] = ["all", "score", "gold"]
	for category in categories:
		var tab: Rect2 = CHARACTER_CATEGORY_TAB_RECTS[category]
		var active: bool = character_category_filter == category
		draw_rect(tab, Color("73f7b4") if active else Color("263a57"), true)
		draw_rect(tab, Color("fff0a6"), false, 3.0)
		draw_string(font, Vector2(tab.position.x, tab.position.y + 30.0), labels[category], HORIZONTAL_ALIGNMENT_CENTER, tab.size.x, 20, Color.BLACK if active else Color("a9bad8"))


func _draw_character_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	draw_rect(CHARACTER_PANEL_RECT, Color("17243b"), true)
	draw_rect(CHARACTER_PANEL_RECT, Color("fff0a6"), false, 7.0)
	draw_string(font, Vector2(CHARACTER_PANEL_RECT.position.x, 175.0), "캐릭터", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PANEL_RECT.size.x, 38, Color.WHITE)
	draw_circle(CHARACTER_PANEL_CLOSE_RECT.get_center(), 24.0, Color("ff4d67"))
	draw_line(CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, -8.0), CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, 8.0), Color.WHITE, 5.0, true)
	draw_line(CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, -8.0), CHARACTER_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, 8.0), Color.WHITE, 5.0, true)
	_draw_character_category_tabs(font)
	_ensure_character_list_viewport()
	var scroll_max := _character_scroll_max()
	if scroll_max > 0.0:
		# A thin track + thumb on the right edge of the list area — the only
		# hint that there's more below since the arrows are gone and this is
		# a drag-to-scroll list now, not a paged one.
		var track := Rect2(CHARACTER_LIST_VIEWPORT_RECT.end.x - 6.0, CHARACTER_LIST_VIEWPORT_RECT.position.y, 6.0, CHARACTER_LIST_VIEWPORT_RECT.size.y)
		draw_rect(track, Color(1.0, 1.0, 1.0, 0.12), true)
		var thumb_height := maxf(40.0, track.size.y * (track.size.y / (track.size.y + scroll_max)))
		var thumb_y := track.position.y + (track.size.y - thumb_height) * (character_scroll_offset / scroll_max)
		draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_height), Color("ffd23f"), true)


func _draw_settings_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	draw_rect(SETTINGS_PANEL_RECT, Color("17243b"), true)
	draw_rect(SETTINGS_PANEL_RECT, Color("fff0a6"), false, 7.0)
	draw_string(font, Vector2(SETTINGS_PANEL_RECT.position.x, 175.0), "설정", HORIZONTAL_ALIGNMENT_CENTER, SETTINGS_PANEL_RECT.size.x, 38, Color.WHITE)
	draw_circle(SETTINGS_PANEL_CLOSE_RECT.get_center(), 24.0, Color("ff4d67"))
	draw_line(SETTINGS_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, -8.0), SETTINGS_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, 8.0), Color.WHITE, 5.0, true)
	draw_line(SETTINGS_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, -8.0), SETTINGS_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, 8.0), Color.WHITE, 5.0, true)

	_draw_settings_toggle_row(font, SOUND_TOGGLE_RECT, "소리", feedback.sound_enabled)
	_draw_settings_toggle_row(font, VIBRATION_TOGGLE_RECT, "진동", feedback.vibration_enabled)

	draw_rect(NICKNAME_ROW_RECT, Color("263a57"), true)
	draw_rect(NICKNAME_ROW_RECT, Color("fff0a6"), false, 4.0)
	draw_string(font, Vector2(NICKNAME_ROW_RECT.position.x + 16.0, NICKNAME_ROW_RECT.position.y + 46.0), "닉네임", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 22, Color.WHITE)
	draw_rect(NICKNAME_SAVE_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(NICKNAME_SAVE_BUTTON_RECT, Color("ffd23f"), false, 3.0)
	draw_string(font, Vector2(NICKNAME_SAVE_BUTTON_RECT.position.x, NICKNAME_SAVE_BUTTON_RECT.position.y + 46.0), "저장", HORIZONTAL_ALIGNMENT_CENTER, NICKNAME_SAVE_BUTTON_RECT.size.x, 22, Color("ffd23f"))

	draw_rect(CODE_ROW_RECT, Color("263a57"), true)
	draw_rect(CODE_ROW_RECT, Color("fff0a6"), false, 4.0)
	draw_string(font, Vector2(CODE_ROW_RECT.position.x + 16.0, CODE_ROW_RECT.position.y + 46.0), "코드", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 22, Color.WHITE)
	draw_rect(CODE_SUBMIT_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(CODE_SUBMIT_BUTTON_RECT, Color("ffd23f"), false, 3.0)
	draw_string(font, Vector2(CODE_SUBMIT_BUTTON_RECT.position.x, CODE_SUBMIT_BUTTON_RECT.position.y + 46.0), "확인", HORIZONTAL_ALIGNMENT_CENTER, CODE_SUBMIT_BUTTON_RECT.size.x, 22, Color("ffd23f"))

	draw_rect(RANKING_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(RANKING_BUTTON_RECT.grow(-5.0), Color("ffd23f"), true)
	draw_rect(RANKING_BUTTON_RECT.grow(-9.0), Color("7a4317"), false, 3.0)
	draw_string(font, Vector2(RANKING_BUTTON_RECT.position.x, RANKING_BUTTON_RECT.get_center().y + 8.0), "랭킹 보기", HORIZONTAL_ALIGNMENT_CENTER, RANKING_BUTTON_RECT.size.x, 26, Color("3b2119"))

	if not settings_message.is_empty():
		draw_string(font, Vector2(SETTINGS_PANEL_RECT.position.x, 770.0), settings_message, HORIZONTAL_ALIGNMENT_CENTER, SETTINGS_PANEL_RECT.size.x, 22, Color("ffd166"))


func _draw_ranking_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	draw_rect(RANKING_PANEL_RECT, Color("17243b"), true)
	draw_rect(RANKING_PANEL_RECT, Color("fff0a6"), false, 7.0)
	draw_string(font, Vector2(RANKING_PANEL_RECT.position.x, 175.0), "전체 랭킹", HORIZONTAL_ALIGNMENT_CENTER, RANKING_PANEL_RECT.size.x, 38, Color.WHITE)
	draw_string(font, Vector2(RANKING_PANEL_RECT.position.x, 215.0), "TOP %d" % LEADERBOARD_TOP_N, HORIZONTAL_ALIGNMENT_CENTER, RANKING_PANEL_RECT.size.x, 22, Color("a9bad8"))
	draw_circle(RANKING_PANEL_CLOSE_RECT.get_center(), 24.0, Color("ff4d67"))
	draw_line(RANKING_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, -8.0), RANKING_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, 8.0), Color.WHITE, 5.0, true)
	draw_line(RANKING_PANEL_CLOSE_RECT.get_center() + Vector2(8.0, -8.0), RANKING_PANEL_CLOSE_RECT.get_center() + Vector2(-8.0, 8.0), Color.WHITE, 5.0, true)

	if ranking_loading:
		draw_string(font, Vector2(RANKING_LIST_RECT.position.x, RANKING_LIST_RECT.position.y + 40.0), "불러오는 중...", HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("a9bad8"))
		return
	if not ranking_error.is_empty():
		draw_string(font, Vector2(RANKING_LIST_RECT.position.x, RANKING_LIST_RECT.position.y + 40.0), ranking_error, HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("ff8b8b"))
		return
	if ranking_entries.is_empty():
		draw_string(font, Vector2(RANKING_LIST_RECT.position.x, RANKING_LIST_RECT.position.y + 40.0), "아직 기록이 없습니다", HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("a9bad8"))
		return
	for index in range(mini(ranking_entries.size(), LEADERBOARD_TOP_N)):
		var entry: Dictionary = ranking_entries[index]
		var row_y := RANKING_LIST_RECT.position.y + float(index) * RANKING_ROW_HEIGHT
		var row := Rect2(RANKING_LIST_RECT.position.x, row_y, RANKING_LIST_RECT.size.x, RANKING_ROW_HEIGHT - 8.0)
		draw_rect(row, Color("263a57"), true)
		draw_rect(row, Color("fff0a6"), false, 3.0)
		draw_string(font, Vector2(row.position.x + 16.0, row.position.y + 38.0), "%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 60.0, 22, Color("ffd23f"))
		draw_string(font, Vector2(row.position.x + 90.0, row.position.y + 38.0), str(entry.get("nickname", "")), HORIZONTAL_ALIGNMENT_LEFT, 280.0, 22, Color.WHITE)
		draw_string(font, Vector2(row.end.x - 150.0, row.position.y + 38.0), str(int(entry.get("score", 0))), HORIZONTAL_ALIGNMENT_RIGHT, 130.0, 22, Color("73f7b4"))


func _draw_settings_toggle_row(font: Font, row: Rect2, label: String, is_on: bool) -> void:
	draw_rect(row, Color("263a57"), true)
	draw_rect(row, Color("fff0a6"), false, 4.0)
	draw_string(font, Vector2(row.position.x + 16.0, row.position.y + 50.0), label, HORIZONTAL_ALIGNMENT_LEFT, 200.0, 24, Color.WHITE)
	var toggle_rect := Rect2(row.end.x - 140.0, row.position.y + 15.0, 120.0, 50.0)
	draw_rect(toggle_rect, Color("73f7b4") if is_on else Color("4a4f5c"), true)
	draw_rect(toggle_rect, Color("fff0a6"), false, 3.0)
	draw_string(font, Vector2(toggle_rect.position.x, toggle_rect.position.y + 34.0), "ON" if is_on else "OFF", HORIZONTAL_ALIGNMENT_CENTER, toggle_rect.size.x, 20, Color.BLACK if is_on else Color.WHITE)


func _draw_character_card(canvas: CanvasItem, font: Font, character_id: String, card: Rect2) -> void:
	# Draws onto `canvas` explicitly (not implicit self) so this can be
	# called from character_list_viewport's own draw signal and still land
	# on that Control's clipped canvas instead of the root Node2D's.
	var owned := owned_character_ids.has(character_id)
	var selected := character_id == selected_character_id
	var border_color := Color("73f7b4") if selected else Color("fff0a6")
	if not owned:
		border_color = Color("6b7280")
	canvas.draw_rect(card, Color("263a57"), true)
	canvas.draw_rect(card, border_color, false, 6.0)
	# Anchored to the card's BOTTOM, not its top, so the extra height above
	# the minimum text layout needs becomes free headroom for tall/scaled-up
	# character previews instead of shifting the fit-scale math (and
	# therefore every other character's card size) along with it.
	var preview_bottom := card.end.y - 139.0
	var preview_rect := Rect2(Vector2(card.position.x + 14.0, preview_bottom - 245.0), Vector2(card.size.x - 28.0, 245.0))
	var texture := _character_preview_texture(character_id)
	if texture != null:
		var source: Rect2 = character_preview_regions.get(character_id, Rect2(Vector2.ZERO, texture.get_size()))
		var scale := minf(preview_rect.size.x / source.size.x, preview_rect.size.y / source.size.y)
		# The ninja hood is intentionally wide; fit it by height so it does not
		# look shorter than the other characters in the selection cards.
		if character_id == "gyaru_girl" or character_id == "pirate_girl":
			scale = preview_rect.size.y / source.size.y
		scale *= float(character_scale_multipliers.get(character_id, 1.0))
		var size := source.size * scale
		var position := Vector2(preview_rect.get_center().x - size.x * 0.5, preview_rect.end.y - size.y)
		# Locked characters are silhouetted dark instead of shown in full
		# color — a preview of the shape without giving away the art as a
		# reward for reaching the unlock condition.
		var tint := Color(1.0, 1.0, 1.0) if owned else Color(0.12, 0.14, 0.2)
		canvas.draw_texture_rect_region(texture, Rect2(position, size), source, tint)
	# Offsets are anchored from the card's BOTTOM (not top) so they keep the
	# same absolute position regardless of how much extra headroom the top of
	# the card has for oversized character art.
	var name: String = character_names.get(character_id, character_id)
	canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 95.0), name, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 20, Color.WHITE if owned else Color("9aa4b8"))
	if owned:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "보유", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("ffd166"))
		var state_text := "사용 중" if selected else "선택"
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), state_text, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, border_color)
		return
	var price := int(character_prices.get(character_id, 0))
	var required_score := int(character_unlock_scores.get(character_id, 0))
	if price > 0:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "%d 골드" % price, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("ffd166"))
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), "구매", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, Color("73f7b4") if coins >= price else Color("ff8b8b"))
	else:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "최고기록 %d" % required_score, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("9aa4b8"))
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), "잠김", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, Color("6b7280"))


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


func _draw_resource_counter(font: Font, rect: Rect2, icon_texture: Texture2D, icon_region: Rect2, amount: int, icon_offset: Vector2) -> void:
	var frame_rect := rect
	if resource_counter_frame_texture != null and resource_counter_frame_used_region.size.x > 0.0:
		# Preserve the frame artwork's original aspect ratio. The counter owns the
		# full `rect`, but unused width intentionally stays empty on the right.
		var original_aspect := resource_counter_frame_used_region.size.x / resource_counter_frame_used_region.size.y
		frame_rect.size.x = minf(rect.size.x, rect.size.y * original_aspect)
		draw_texture_rect_region(resource_counter_frame_texture, frame_rect, resource_counter_frame_used_region)
	else:
		frame_rect.size.x = minf(rect.size.x, 222.0)
		draw_rect(frame_rect, Color(0.23, 0.14, 0.09, 0.92), true)
		draw_rect(frame_rect, Color("ffd23f"), false, 4.0)
	# The frame already contains a circular icon socket. Keep the resource icon
	# inside that socket instead of letting its artwork cross the gold rim.
	var icon_rect := Rect2(frame_rect.position + icon_offset, RESOURCE_ICON_SIZE)
	if icon_texture != null and icon_region.size.x > 0.0:
		draw_texture_rect_region(icon_texture, icon_rect, icon_region)
	# The icon already identifies the resource. A single large number stays clear
	# on narrow mobile screens and cannot collide with a second label line.
	var amount_position := Vector2(frame_rect.position.x + 76.0, frame_rect.position.y + 19.0)
	_draw_image_number(str(amount), amount_position - Vector2(0.0, 4.0), 34.0)


func _prepare_gold_digit_regions() -> void:
	gold_digit_regions.clear()
	if gold_digit_sheet_texture == null:
		return
	var image := gold_digit_sheet_texture.get_image()
	if image == null or image.is_empty():
		return
	var image_size := image.get_size()
	for digit in range(10):
		var column := digit % 5
		var row := digit / 5
		var cell_start := Vector2i(
			roundi(float(column) * image_size.x / 5.0),
			roundi(float(row) * image_size.y / 2.0)
		)
		var cell_end := Vector2i(
			roundi(float(column + 1) * image_size.x / 5.0),
			roundi(float(row + 1) * image_size.y / 2.0)
		)
		# Ignore the generator's nearly invisible fringe pixels; otherwise those
		# pixels become fake whitespace and split numbers such as 130 into 13 0.
		var visible := _image_visible_region(image, Rect2i(cell_start, cell_end - cell_start), 96)
		gold_digit_regions.append(Rect2(visible))


func _draw_image_number(text: String, position: Vector2, height: float, align_width := 0.0, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if gold_digit_sheet_texture == null or gold_digit_regions.size() != 10:
		_draw_pixel_number(text, position, height / 7.0, Color("ffd23f"), Color("633913"), align_width, alignment)
		return
	# The sprites already include a thick down-right shadow, so an additional
	# typographic gap makes a continuous value look split (for example, 13 0).
	var gap := -height * 0.22
	var total_width := _image_number_width(text, height, gap)
	var draw_x := position.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		draw_x += (align_width - total_width) * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		draw_x += align_width - total_width
	for character in text:
		var digit := character.to_int()
		if digit < 0 or digit >= gold_digit_regions.size():
			continue
		var source := gold_digit_regions[digit]
		var width := height * source.size.x / source.size.y
		draw_texture_rect_region(gold_digit_sheet_texture, Rect2(Vector2(draw_x, position.y), Vector2(width, height)), source)
		draw_x += width + gap


func _image_number_width(text: String, height: float, gap: float) -> float:
	var width := 0.0
	var drawn_digits := 0
	for character in text:
		var digit := character.to_int()
		if digit < 0 or digit >= gold_digit_regions.size():
			continue
		var source := gold_digit_regions[digit]
		width += height * source.size.x / source.size.y
		drawn_digits += 1
	return width + maxf(0.0, drawn_digits - 1) * gap


func _draw_pixel_number(text: String, position: Vector2, cell_size: float, face_color: Color, outline_color: Color, align_width := 0.0, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var glyph_width := cell_size * 5.0
	var glyph_gap := cell_size
	var total_width := _pixel_number_width(text, cell_size)
	var start_x := position.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		start_x += (align_width - total_width) * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		start_x += align_width - total_width
	for glyph_index in range(text.length()):
		var rows := _pixel_number_glyph(text[glyph_index])
		var glyph_x := start_x + glyph_index * (glyph_width + glyph_gap)
		for row in range(rows.size()):
			for column in range(rows[row].length()):
				if rows[row][column] != "1":
					continue
				var cell_position := Vector2(glyph_x + column * cell_size, position.y + row * cell_size)
				draw_rect(Rect2(cell_position - Vector2.ONE, Vector2.ONE * (cell_size + 2.0)), outline_color)
				draw_rect(Rect2(cell_position, Vector2.ONE * cell_size), face_color)
				var shine_size := maxf(1.0, floorf(cell_size * 0.25))
				draw_rect(Rect2(cell_position, Vector2.ONE * shine_size), face_color.lightened(0.32))


func _pixel_number_width(text: String, cell_size: float) -> float:
	if text.is_empty():
		return 0.0
	return text.length() * cell_size * 5.0 + (text.length() - 1) * cell_size


func _pixel_number_glyph(character: String) -> PackedStringArray:
	match character:
		"0": return PackedStringArray(["11111", "10001", "10011", "10101", "11001", "10001", "11111"])
		"1": return PackedStringArray(["00100", "01100", "00100", "00100", "00100", "00100", "01110"])
		"2": return PackedStringArray(["11110", "00001", "00001", "11110", "10000", "10000", "11111"])
		"3": return PackedStringArray(["11110", "00001", "00001", "01110", "00001", "00001", "11110"])
		"4": return PackedStringArray(["10010", "10010", "10010", "11111", "00010", "00010", "00010"])
		"5": return PackedStringArray(["11111", "10000", "10000", "11110", "00001", "00001", "11110"])
		"6": return PackedStringArray(["01111", "10000", "10000", "11110", "10001", "10001", "01110"])
		"7": return PackedStringArray(["11111", "00001", "00010", "00100", "01000", "01000", "01000"])
		"8": return PackedStringArray(["01110", "10001", "10001", "01110", "10001", "10001", "01110"])
		"9": return PackedStringArray(["01110", "10001", "10001", "01111", "00001", "00001", "11110"])
		"+": return PackedStringArray(["00000", "00100", "00100", "11111", "00100", "00100", "00000"])
		_: return PackedStringArray(["00000", "00000", "00000", "00000", "00000", "00000", "00000"])


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
