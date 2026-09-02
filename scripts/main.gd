extends Node2D

enum GameState { TITLE, PLAYING, HIT, GAME_OVER }
enum TurnerTeam { STUDENT, ATHLETE, SLEEPY, PRANKSTER, WIZARD, DUO, WIZARD_PRANKSTER_DUO }
enum TurnerTransitionPhase { NONE, TURNER_EXIT, TURNER_ENTRY_COUNTDOWN }

const SUPABASE_URL := "https://zjluakxiiynlzbfxztrl.supabase.co"
const SUPABASE_ANON_KEY := "sb_publishable_oFUSCvNA6oyZCHP5vNuqXw_gfYXFD_e"
const LEADERBOARD_TOP_N := 10
# Separate Supabase project — the character-shop website (see
# character-shop/ and GAME_INTEGRATION.md), not the leaderboard one above.
# Only used for redeem_code(), which is intentionally callable anonymously
# (no login exists in the game) — see supabase/schema.sql's redeem_code()
# for why that's safe (unguessable one-time code, atomic single-use flip).
const SHOP_SUPABASE_URL := "https://htaepwozdnwknhewkals.supabase.co"
const SHOP_SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0YWVwd296ZG53a25oZXdrYWxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyNTA1ODgsImV4cCI6MjEwMzgyNjU4OH0.9cgueCOcdlrhgRmFgtZ8iy3eJCRZ-GbRc16hbZOW8hA"
const DESIGN_SIZE := Vector2(720.0, 1280.0)
const PLAYER_X := 360.0
const COOP_LEFT_PLAYER_X := 240.0
const COOP_RIGHT_PLAYER_X := 480.0
const PLAYER_GROUND_Y := 890.0
const TURNER_GROUND_Y := 910.0
const LEFT_HAND := Vector2(140.0, 855.0)
const RIGHT_HAND := Vector2(580.0, 855.0)
# LEFT_HAND/RIGHT_HAND.y (855) sits 55px above a normal turner's feet
# (TURNER_GROUND_Y, 910) — 55 / 165 (the normal sprite height) down from the
# sprite's bottom, i.e. this far down from its top. Used to keep the boss
# turner's hand fixed at that same on-screen height when its sprite is
# scaled up (see _draw_turner).
const TURNER_HAND_FRACTION_FROM_TOP := 1.0 - 55.0 / 165.0
const COOP_LEFT_HAND := Vector2(72.0, 855.0)
const COOP_RIGHT_HAND := Vector2(648.0, 855.0)
const COOP_LEFT_TURNER_FEET := Vector2(42.0, TURNER_GROUND_Y)
const COOP_RIGHT_TURNER_FEET := Vector2(678.0, TURNER_GROUND_Y)
const ROPE_OVERHEAD_RADIUS := 170.0
const ROPE_GROUND_RADIUS := 40.0
# The front half reaches the player's feet without sinking deep into the ground.
const ROPE_CROSSING_ANGLE := 0.9
const PERFECT_MIN_HEIGHT := 105.0
const PERFECT_MAX_RISING_SPEED := 300.0
const PERFECT_MAX_FALLING_SPEED := 520.0
const PERFECT_DISPLAY_SECONDS := 0.7
const ROPE_PIXEL_GRID := 4.0
const ROPE_PIXEL_OUTLINE_SIZE := Vector2(14.0, 14.0)
const ROPE_PIXEL_CORE_SIZE := Vector2(8.0, 8.0)
const HIT_REVEAL_SECONDS := 0.42
const TURNER_CHANGE_INTERVAL := 10
# After the initial score-10 grace period, a new random team is rolled every
# TURNER_RANDOM_INTERVAL points — matching the spacing the fixed sequence
# used to have (ATHLETE@10, SLEEPY@30, PRANKSTER@50, WIZARD@70), just with
# the team at each of those boundaries now chosen at random instead of fixed.
const TURNER_RANDOM_INTERVAL := 20
# From BOSS_TURNER_SCORE_THRESHOLD to the double-rope reveal, the turner
# team still rerolls much more often so every existing pattern (athlete/
# sleepy/prankster/wizard) gets a chance to show up before the boss's real
# gimmick (the second rope, plus the pattern locking to plain default) kicks
# in — see _turner_slot_for_score.
const BOSS_GAUNTLET_TURNER_INTERVAL := 3
const BOSS_GAUNTLET_SLOT := 99999
const ATHLETE_NORMAL_TURNS := 2
const ATHLETE_MAX_BURST_TURNS := 2
const SLEEPY_START_SCORE := 30
const SLEEPY_MIN_SLOW_TURNS := 1
const SLEEPY_MAX_SLOW_TURNS := 2
const SLEEPY_WAKE_WARNING_SECONDS := 1.0
const SLEEPY_SLOW_MULTIPLIER := 0.5544 # 0.462 base + 20%
const SLEEPY_FAST_MULTIPLIER := 3.6 # 2.4 base + 50%
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
const BGM_MUSIC_PATH := "res://assets/audio/bgm.mp3"
const DEFAULT_TURNER_PATH := "res://assets/turners/bowl_cut_student.png"
const ATHLETE_TURNER_PATH := "res://assets/turners/athlete_student.png"
const SLEEPY_TURNER_ASLEEP_PATH := "res://assets/turners/sleepy_student_asleep.png"
const SLEEPY_TURNER_AWAKE_PATH := "res://assets/turners/sleepy_student_awake.png"
const PRANKSTER_TURNER_PATH := "res://assets/turners/prankster_student.png"
const WIZARD_TURNER_PATH := "res://assets/turners/wizard_student.png"
const BOSS_TURNER_PATH := "res://assets/turners/boss_king.png"
const BOSS_TURNER_ANGRY_PATH := "res://assets/turners/boss_king_angry.png"
const BOSS_TURNER_SHOCKED_PATH := "res://assets/turners/boss_king_shocked.png"
const BOSS_TURNER_SCORE_THRESHOLD := 90
const MENU_CHARACTER_TEXTURE_PATH := "res://assets/ui/menu_character.png"
const RANKING_BUTTON_TEXTURE_PATH := "res://assets/ui/ranking_button.png"
const ATTENDANCE_BUTTON_TEXTURE_PATH := "res://assets/ui/attendance_button.png"
const SHOP_BUTTON_TEXTURE_PATH := "res://assets/ui/shop_button.png"
const ATTENDANCE_TRACK_BG_PATH := "res://assets/ui/checkin_track_bg.png"
const ATTENDANCE_RUBY_ICON_PATH := "res://assets/ui/checkin_ruby_icon.png"
const ATTENDANCE_COMPLETE_BADGE_PATH := "res://assets/ui/checkin_complete_badge.png"
const ATTENDANCE_CHEST_CLOSED_PATH := "res://assets/ui/checkin_chest_closed.png"
const ATTENDANCE_CHEST_OPEN_PATH := "res://assets/ui/checkin_chest_open.png"
# Slot centers measured from the track art itself (as fractions of its own
# width/height) — the 7 punched-out circles are evenly spaced but not
# perfectly centered in the frame, so computing fractions instead of
# guessing even spacing keeps the reward icons sitting inside the holes.
const ATTENDANCE_TRACK_SLOT_X_FRACTIONS := [0.1453, 0.2634, 0.3813, 0.4991, 0.6161, 0.7332, 0.8497]
const ATTENDANCE_TRACK_SLOT_Y_FRACTION := 0.4877
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
const GAME_OVER_PANEL_PATH := "res://assets/ui/panel_frame.png"
const REVIVE_GEM_COST := 1
# Shown once, the very first time a new player taps the title screen — a
# guided tour through the player's actual first game AND the surrounding
# menus (character/coop/ranking/attendance/nickname), not a separate
# slideshow. Progress lives in tutorial_stage (1..TUTORIAL_STAGE_COUNT, 0 =
# inactive/finished); each stage is either a full-freeze explanation (see
# tutorial_pause_active, _draw_tutorial_pause_banner) or a non-blocking
# arrow/hint pointing at the next thing to tap (see _draw_tutorial_layer).
# Advancing happens at the specific spot each stage's action actually
# occurs (see the "tutorial_stage ==" checks scattered through input/menu
# handlers) rather than a generic dismiss, since stages 5 onward span
# different menus entirely.
const TUTORIAL_STAGE_COUNT := 12
const TUTORIAL_REWARD_GOLD := 100
# Godot's built-in ThemeDB.fallback_font has no Hangul glyphs, so every piece
# of Korean text drawn via draw_string() rendered as tofu boxes until this
# was added — it just went unnoticed because most Korean text on screen is
# actually baked into the button/panel PNGs, not live-rendered.
const UI_FONT_PATH := "res://assets/fonts/Mulmaru.ttf"
const PANEL_FRAME_PATH := "res://assets/ui/panel_frame.png"
# Character panel gets its own taller frame (settings/ranking keep the
# shorter shared one) so more of the card grid fits before scrolling.
const CHARACTER_PANEL_FRAME_PATH := "res://assets/ui/panel_frame_long.png"
const CLOSE_BUTTON_TEXTURE_PATH := "res://assets/ui/close_button.png"
const TAB_INACTIVE_TEXTURE_PATH := "res://assets/ui/tab_inactive.png"
const TAB_ACTIVE_TEXTURE_PATH := "res://assets/ui/tab_active.png"
const LOCK_ICON_TEXTURE_PATH := "res://assets/ui/lock_icon.png"
const CHARACTER_CARD_FRAME_PATH := "res://assets/ui/character_card_frame.png"
const INPUT_ROW_BG_TEXTURE_PATH := "res://assets/ui/input_row_bg.png"
const TOGGLE_ON_TEXTURE_PATH := "res://assets/ui/toggle_on.png"
const TOGGLE_OFF_TEXTURE_PATH := "res://assets/ui/toggle_off.png"
const GOLD_DIGIT_SHEET_PATH := "res://assets/ui/gold_digit_sheet.png"
const COUNTDOWN_PATHS := [
	"res://assets/ui/countdown_3.png",
	"res://assets/ui/countdown_2.png",
	"res://assets/ui/countdown_1.png",
	"res://assets/ui/countdown_go.png",
]
const BOSS_WARNING_PATH := "res://assets/ui/boss_warning.png"
const DEFAULT_CHARACTER_ID := "default"
const JUMP_FRAME_COUNT := 2
const JUMP_FRAME_AIR := 0
const JUMP_FRAME_MID := 1
const JUMP_APEX_VELOCITY_BAND := 180.0
const DEFAULT_BALANCE := preload("res://resources/balance/default_balance.tres")
# The current title_logo.png bakes the "최고기록" plaque into the same image
# as the "줄넘킹" title (crown, clouds, and an empty gold-bordered number
# slot near the bottom) — MAIN_MENU_TITLE_RECT positions that whole image,
# and MAIN_MENU_BEST_SCORE_NUMBER_RECT is where the number slot lands within
# it, both measured by eye against a screenshot of the actual render (see
# the title_logo art's proportions — the slot sits at roughly 63%/78% of the
# image's width/height, matching these two rects' relationship).
const MAIN_MENU_TITLE_RECT := Rect2(107.0, 80.0, 506.0, 380.0)
const MAIN_MENU_BEST_SCORE_NUMBER_RECT := Rect2(375.0, 367.0, 100.0, 18.0)
const CHARACTER_BUTTON_RECT := Rect2(25.0, 1055.0, 210.0, 195.0)
const COOP_BUTTON_RECT := Rect2(255.0, 1055.0, 210.0, 195.0)
const SETTINGS_BUTTON_RECT := Rect2(485.0, 1055.0, 210.0, 195.0)
# Moved up to sit just above the character/co-op/settings row, freeing the
# slot below the attendance button (551..658) for SHOP_BUTTON_RECT.
const TEST_START_130_RECT := Rect2(25.0, 940.0, 320.0, 100.0)
const TEST_START_170_RECT := Rect2(365.0, 940.0, 320.0, 100.0)
const GAME_OVER_CLOSE_RECT := Rect2(538.0, 304.0, 78.0, 78.0)
# Character panel uses its own taller frame (panel_frame_long.png) instead
# of the shared square one settings/ranking use, so this rect is much taller
# than SETTINGS_PANEL_RECT/RANKING_PANEL_RECT even though all three used to
# share identical dimensions. Width kept at 660 to match the frame art's own
# aspect ratio (407:612) — changing width alone would stretch/distort it.
const CHARACTER_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 992.0)
const CHARACTER_PANEL_CLOSE_RECT := Rect2(580.0, 191.0, 52.0, 52.0)
# Category filter tabs (전체/기록/골드) sit below panel_frame_long's crown
# decoration. x/width (130..590) match the frame's actual clean interior for
# this taller art, which is narrower and differently centered than the
# shared panel_frame.png's — measured from the image directly, not reused
# from the other panels' insets.
const CHARACTER_CATEGORY_ROW_RECT := Rect2(130.0, 320.0, 460.0, 44.0)
const CHARACTER_CATEGORY_TAB_RECTS := {
	"all": Rect2(130.0, 320.0, 148.0, 44.0),
	"score": Rect2(286.0, 320.0, 148.0, 44.0),
	"gold": Rect2(442.0, 320.0, 148.0, 44.0),
}
# The character grid scrolls vertically inside this viewport (a clipped child
# Control — see character_list_viewport) instead of paging left/right.
# Column x-positions and card size are LOCAL to that viewport. Columns sit
# flush against each other (zero gutter) so 3 cards exactly fill the 460px
# clean interior width without any spilling past the frame's side borders.
# Height (630) is tall enough for one full row plus a peek of the next,
# thanks to panel_frame_long's much taller clean interior — the old shared
# frame only had room for one row with barely any peek.
const CHARACTER_LIST_VIEWPORT_RECT := Rect2(130.0, 370.0, 460.0, 630.0)
const CHARACTER_CARD_WIDTH := 460.0 / 3.0
const CHARACTER_CARD_COLUMN_X := [0.0, CHARACTER_CARD_WIDTH, CHARACTER_CARD_WIDTH * 2.0]
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
const RANKING_SCROLL_DRAG_THRESHOLD := 6.0
const SETTINGS_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const SETTINGS_PANEL_CLOSE_RECT := Rect2(596.0, 211.0, 52.0, 52.0)
const SOUND_TOGGLE_RECT := Rect2(105.0, 360.0, 505.0, 80.0)
const VIBRATION_TOGGLE_RECT := Rect2(105.0, 460.0, 505.0, 80.0)
const NICKNAME_ROW_RECT := Rect2(105.0, 560.0, 505.0, 70.0)
const NICKNAME_FIELD_RECT := Rect2(235.0, 560.0, 245.0, 70.0)
const NICKNAME_SAVE_BUTTON_RECT := Rect2(490.0, 560.0, 120.0, 70.0)
const CODE_ROW_RECT := Rect2(105.0, 650.0, 505.0, 70.0)
const DATA_RESET_ROW_RECT := Rect2(105.0, 735.0, 505.0, 70.0)
# Tutorial stage 12's own small popup — deliberately separate from the full
# settings panel so it doesn't compete with whatever else was open (e.g.
# the attendance panel stage 10/11 just opened) for the same screen.
const TUTORIAL_NICKNAME_PANEL_RECT := Rect2(60.0, 480.0, 600.0, 300.0)
const TUTORIAL_NICKNAME_FIELD_RECT := Rect2(100.0, 640.0, 380.0, 70.0)
const TUTORIAL_NICKNAME_SAVE_RECT := Rect2(495.0, 640.0, 125.0, 70.0)
const CODE_FIELD_RECT := Rect2(235.0, 650.0, 245.0, 70.0)
const CODE_SUBMIT_BUTTON_RECT := Rect2(490.0, 650.0, 120.0, 70.0)
const RANKING_MAIN_BUTTON_RECT := Rect2(531.0, 306.0, 189.0, 107.0)
const RANKING_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const RANKING_PANEL_CLOSE_RECT := Rect2(596.0, 211.0, 52.0, 52.0)
const ATTENDANCE_MAIN_BUTTON_RECT := Rect2(531.0, 428.0, 189.0, 107.0)
const ATTENDANCE_PANEL_RECT := Rect2(30.0, 100.0, 660.0, 785.0)
const ATTENDANCE_PANEL_CLOSE_RECT := Rect2(596.0, 211.0, 52.0, 52.0)
# Same size/column as RANKING/ATTENDANCE_MAIN_BUTTON_RECT, stacked directly
# below attendance with the same 15px gap those two share.
const SHOP_BUTTON_RECT := Rect2(531.0, 551.0, 189.0, 107.0)
const SHOP_URL := "https://rope-king.vercel.app/shop"
const ATTENDANCE_CLAIM_BUTTON_RECT := Rect2(110.0, 560.0, 500.0, 90.0)
const ATTENDANCE_DAY_REWARDS := [1, 2, 2, 3, 3, 4, 5]
const RANKING_PERIOD_TAB_RECTS := {
	"all": Rect2(105.0, 335.0, 163.0, 44.0),
	"week": Rect2(276.0, 335.0, 163.0, 44.0),
	"perfect": Rect2(447.0, 335.0, 163.0, 44.0),
}
const RANKING_LIST_RECT := Rect2(105.0, 425.0, 505.0, 335.0)
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
@export var boss_turner_texture: Texture2D
@export var boss_turner_angry_texture: Texture2D
@export var boss_turner_shocked_texture: Texture2D
@export_group("Menu Button Assets")
@export var character_button_texture: Texture2D
@export var ranking_button_texture: Texture2D
@export var attendance_button_texture: Texture2D
@export var shop_button_texture: Texture2D
@export var attendance_track_bg_texture: Texture2D
@export var attendance_ruby_icon_texture: Texture2D
@export var attendance_complete_badge_texture: Texture2D
@export var attendance_chest_closed_texture: Texture2D
@export var attendance_chest_open_texture: Texture2D
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
@export var panel_frame_texture: Texture2D
@export var character_panel_frame_texture: Texture2D
@export var ui_font: FontFile
@export var close_button_texture: Texture2D
@export var tab_inactive_texture: Texture2D
@export var tab_active_texture: Texture2D
@export var lock_icon_texture: Texture2D
@export var character_card_frame_texture: Texture2D
@export var input_row_bg_texture: Texture2D
@export var toggle_on_texture: Texture2D
@export var toggle_off_texture: Texture2D
@export var gold_digit_sheet_texture: Texture2D
@export_group("Game Balance")
@export var balance: RopeGameBalance = DEFAULT_BALANCE

var score := 0
var best_score := 0
var rope_angle := PI
var rope_speed := 0.0

# Boss "double dutch" rope: a second independent rope, offset in phase so it
# crosses exactly between the main rope's crossings. Prototype toggle only —
# not yet wired to a real round-100 boss trigger.
const DOUBLE_ROPE_TEST_ENABLED := true
const DOUBLE_ROPE_TEST_SCORE_THRESHOLD := 110
const ROPE_B_PHASE_OFFSET := PI
# Built but held off for now — past AIR_CHALLENGE_START_SCORE the game just
# holds a plain single-rope basic pattern (see _turner_slot_for_score and
# _resolve_rope_crossing) until this is tuned and ready to turn on.
const AIR_CHALLENGE_ENABLED := false
const AIR_CHALLENGE_START_SCORE := 130
const AIR_CHALLENGE_INTERVAL := 5
const AIR_CHALLENGE_GRAVITY := 1500.0
const AIR_CHALLENGE_JUMP_VELOCITY := -1350.0
# Rough first pass at a "went to space" late-game reskin — no new assets
# yet, just a starfield background swap and lighter gravity (same launch
# velocity, weaker pull down = a floatier, higher jump).
const SPACE_SCORE_THRESHOLD := 170
const SPACE_GRAVITY_MULTIPLIER := 0.55
# The space zone's second rope isn't a ground-level double-dutch rope like
# the boss's — it's installed up high, only cleared by getting genuinely
# high in the air (see _resolve_rope_b_crossing), which a single jump alone
# mostly can't reach — that's the whole point of the double jump here.
const SPACE_OVERHEAD_ROPE_Y_OFFSET := -190.0
const SPACE_OVERHEAD_CLEAR_HEIGHT := 280.0
const AIR_CHALLENGE_TAP_TOLERANCE := 72.0
const AIR_CHALLENGE_LANDING_PAUSE := 1.0
const AIR_ROPE_HEIGHTS := [-235.0, -410.0, -555.0]
# Duo stage: from AIR_CHALLENGE_START_SCORE (130) to DUO_STAGE_END_SCORE
# (150), the left turner is always athlete and the right is always sleepy
# (see _draw_turner) — normally running athlete's burst pattern, but the
# sleepy half randomly "wakes up" for one sudden-burst turn before going
# back to normal (see _update_turner_team_and_pattern). DUO_STAGE_SLOT is
# just a sentinel distinct from every gauntlet slot number so
# _update_turner_team_and_pattern detects the one-time entry into this
# stage instead of re-rolling a random team.
const DUO_STAGE_END_SCORE := 150
const DUO_STAGE_SLOT := 100000
const DUO_MIN_NORMAL_TURNS := 2
const DUO_MAX_NORMAL_TURNS := 5
var duo_normal_turns_remaining := 0
# The athlete half keeps running its own normal/burst cycle (same shape as
# the standalone ATHLETE team) every turn, independent of the sleepy
# countdown above. Dedicated counters so this never collides with the
# standalone ATHLETE team's own athlete_normal_turns_remaining/
# athlete_burst_turns_remaining (only one team is ever active at a time, but
# keeping them separate avoids any cross-talk if that assumption changes).
var duo_athlete_bursting := false
var duo_athlete_normal_turns_remaining := 0
var duo_athlete_burst_turns_remaining := 0
# When true, sleepy's single-turn burst overrides whatever the athlete half
# would otherwise be doing this turn (speed + visual) — sleepy always takes
# priority over athlete's own cycle.
var duo_sleepy_awake := false
# Second duo stage: from WIZARD_PRANKSTER_DUO_START_SCORE (150, right where
# the athlete/sleepy duo ends — no plain-student gap turn in between) onward,
# the left turner is always wizard and the right is always prankster (see
# _draw_turner). The rope is invisible on every turn (see
# _wizard_rope_is_ghosted) — wizard's own speed variance still applies by
# default, and every so often the turn's pattern switches to prankster's
# stop/reverse fake instead, still under the same permanently invisible rope.
# WIZARD_PRANKSTER_DUO_SLOT is a sentinel distinct from DUO_STAGE_SLOT and
# every gauntlet slot number, same purpose as that one.
const WIZARD_PRANKSTER_DUO_START_SCORE := 150
const WIZARD_PRANKSTER_DUO_SLOT := 100001
const WIZARD_PRANKSTER_DUO_MIN_NORMAL_TURNS := 2
const WIZARD_PRANKSTER_DUO_MAX_NORMAL_TURNS := 5
# Space stage (SPACE_SCORE_THRESHOLD, 170): plain default turner + fixed
# score-10 baseline speed, same "no gimmick" treatment as BOSS_GAUNTLET_SLOT
# — see _turner_slot_for_score/_update_turner_team_and_pattern/
# _base_speed_for_score. The rope-freeze-while-airborne rule lives in
# _process instead, since it's about the player's jump state, not the
# turner's pattern.
const SPACE_SLOT := 100002
# 210+: a second, smaller jump can be triggered mid-air (once per jump) —
# distinct from every other team's rope-timing gimmicks since it changes
# the PLAYER's own move instead of the rope's pattern.
const DOUBLE_JUMP_SCORE_THRESHOLD := SPACE_SCORE_THRESHOLD
const DOUBLE_JUMP_VELOCITY := -620.0
var used_double_jump := false
# 230+: every few turns, one turn's rope speed spikes hard with a warning
# beforehand — same "everything else in the space zone is the plain fixed
# baseline, but this one thing changes" shape as SLEEPY's wake-up, just
# turn-counted like ATHLETE's burst instead of time-counted.
const COMET_RUSH_SCORE_THRESHOLD := 230
const COMET_RUSH_INTERVAL := 4
const COMET_RUSH_MULTIPLIER := 2.0
var comet_rush_turns_remaining := COMET_RUSH_INTERVAL
var comet_rush_active := false
var duo2_normal_turns_remaining := 0
# True only during the one turn prankster's fake overrides wizard's own
# pattern — drives both the fake motion (_update_prankster_fake, gated to
# also accept this team) and the rope's forced invisibility.
var duo2_prankster_triggered := false
var rope_b_enabled := false
# The turn score first reaches DOUBLE_ROPE_TEST_SCORE_THRESHOLD stays a
# single rope so the player gets one normal turn to read the stage change
# before ropes start doubling — this tracks whether that intro turn has
# already happened this run. After it, double rope appears at most every
# other turn (never two in a row) — see boss_double_rope_was_double_last_turn
# and the per-turn toggle in _resolve_rope_crossing.
var boss_double_rope_intro_shown := false
var boss_double_rope_was_double_last_turn := false
var rope_b_angle := PI
var jump_height := 0.0
var jump_velocity := 0.0
var jump_animation_time := 0.0
var is_jumping := false
var jump_started_in_cue := false
var air_challenge_active := false
var air_challenge_next_rope := 0
var air_challenge_combo := 0
var air_challenge_landing_time := 0.0
var air_challenge_last_score := -1
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
var turner_change_slot := 0
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
var turner_transition_active := false
var turner_transition_time := 0.0
var countdown_vibration_index := -1
var turner_transition_phase := TurnerTransitionPhase.NONE
var departing_turner_team := TurnerTeam.STUDENT
# True when the current transition's entry countdown should show the boss's
# shaking red warning instead of the normal "3,2,1,GO" numbers.
var turner_transition_is_boss := false
var flash_time := 0.0
var perfect_display_time := 0.0
# Counts PERFECT! crossings for the current run only (reset in _start_run),
# submitted to the leaderboard alongside score so the "perfect" ranking tab
# can rank by a single run's best perfect-jump count.
var perfect_count := 0
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
var data_reset_confirm_pending := false
var tutorial_seen := false
var tutorial_active := false
var tutorial_pause_active := false
var tutorial_stage := 0
var tutorial_nickname_prompt_active := false
var character_menu_open := false
var settings_menu_open := false
var nickname := RopeSaveManager.DEFAULT_NICKNAME
var nickname_edit: LineEdit
var code_edit: LineEdit
var settings_message := ""
var ranking_menu_open := false
var attendance_menu_open := false
var attendance_streak := 0
var attendance_last_claim_date := ""
var ranking_loading := false
var ranking_error := ""
var ranking_entries: Array = []
var ranking_period_filter := "all"
var leaderboard_submit_request: HTTPRequest
var leaderboard_fetch_request: HTTPRequest
var redeem_code_request: HTTPRequest
var redeem_code_pending := false
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
var revived_this_run := false
var newly_unlocked_this_run: Array[String] = []
var character_reveal_active := false
var character_reveal_index := 0
var character_reveal_time := 0.0
var character_list_viewport: Control
var character_scroll_offset := 0.0
var character_scroll_dragging := false
var character_scroll_moved := false
var character_scroll_press_position := Vector2.ZERO
var character_scroll_press_offset := 0.0
var ranking_list_viewport: Control
var ranking_scroll_offset := 0.0
var ranking_scroll_dragging := false
var ranking_scroll_moved := false
var ranking_scroll_press_position := Vector2.ZERO
var ranking_scroll_press_offset := 0.0
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
var boss_turner_used_region := Rect2()
var mirrored_boss_turner_texture: Texture2D
var mirrored_boss_turner_used_region := Rect2()
var boss_turner_angry_used_region := Rect2()
var mirrored_boss_turner_angry_texture: Texture2D
var mirrored_boss_turner_angry_used_region := Rect2()
var boss_turner_shocked_used_region := Rect2()
var mirrored_boss_turner_shocked_texture: Texture2D
var mirrored_boss_turner_shocked_used_region := Rect2()
var character_button_used_region := Rect2()
var ranking_button_used_region := Rect2()
var attendance_button_used_region := Rect2()
var shop_button_used_region := Rect2()
var attendance_track_bg_used_region := Rect2()
var attendance_ruby_icon_used_region := Rect2()
var attendance_complete_badge_used_region := Rect2()
var attendance_chest_closed_used_region := Rect2()
var attendance_chest_open_used_region := Rect2()
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
var panel_frame_used_region := Rect2()
var character_panel_frame_used_region := Rect2()
var close_button_used_region := Rect2()
var tab_inactive_used_region := Rect2()
var tab_active_used_region := Rect2()
var lock_icon_used_region := Rect2()
var character_card_frame_used_region := Rect2()
var input_row_bg_used_region := Rect2()
var toggle_on_used_region := Rect2()
var toggle_off_used_region := Rect2()
var gold_digit_regions: Array[Rect2] = []
var countdown_textures: Array[Texture2D] = []
var countdown_used_regions: Array[Rect2] = []
var boss_warning_texture: Texture2D
var boss_warning_used_region := Rect2()
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
	feedback.play_bgm(BGM_MUSIC_PATH)
	rope_speed = balance.base_rope_speed
	_load_character_visuals(selected_character_id)
	if background_texture == null and ResourceLoader.exists(DEFAULT_BACKGROUND_PATH):
		background_texture = load(DEFAULT_BACKGROUND_PATH) as Texture2D
	_prepare_turner_visuals()
	if character_button_texture == null and ResourceLoader.exists(MENU_CHARACTER_TEXTURE_PATH):
		character_button_texture = load(MENU_CHARACTER_TEXTURE_PATH) as Texture2D
	if ranking_button_texture == null and ResourceLoader.exists(RANKING_BUTTON_TEXTURE_PATH):
		ranking_button_texture = load(RANKING_BUTTON_TEXTURE_PATH) as Texture2D
	if attendance_button_texture == null and ResourceLoader.exists(ATTENDANCE_BUTTON_TEXTURE_PATH):
		attendance_button_texture = load(ATTENDANCE_BUTTON_TEXTURE_PATH) as Texture2D
	if shop_button_texture == null and ResourceLoader.exists(SHOP_BUTTON_TEXTURE_PATH):
		shop_button_texture = load(SHOP_BUTTON_TEXTURE_PATH) as Texture2D
	if attendance_track_bg_texture == null and ResourceLoader.exists(ATTENDANCE_TRACK_BG_PATH):
		attendance_track_bg_texture = load(ATTENDANCE_TRACK_BG_PATH) as Texture2D
	if attendance_ruby_icon_texture == null and ResourceLoader.exists(ATTENDANCE_RUBY_ICON_PATH):
		attendance_ruby_icon_texture = load(ATTENDANCE_RUBY_ICON_PATH) as Texture2D
	if attendance_complete_badge_texture == null and ResourceLoader.exists(ATTENDANCE_COMPLETE_BADGE_PATH):
		attendance_complete_badge_texture = load(ATTENDANCE_COMPLETE_BADGE_PATH) as Texture2D
	if attendance_chest_closed_texture == null and ResourceLoader.exists(ATTENDANCE_CHEST_CLOSED_PATH):
		attendance_chest_closed_texture = load(ATTENDANCE_CHEST_CLOSED_PATH) as Texture2D
	if attendance_chest_open_texture == null and ResourceLoader.exists(ATTENDANCE_CHEST_OPEN_PATH):
		attendance_chest_open_texture = load(ATTENDANCE_CHEST_OPEN_PATH) as Texture2D
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
	if ui_font == null and ResourceLoader.exists(UI_FONT_PATH):
		ui_font = load(UI_FONT_PATH) as FontFile
	if panel_frame_texture == null and ResourceLoader.exists(PANEL_FRAME_PATH):
		panel_frame_texture = load(PANEL_FRAME_PATH) as Texture2D
	if character_panel_frame_texture == null and ResourceLoader.exists(CHARACTER_PANEL_FRAME_PATH):
		character_panel_frame_texture = load(CHARACTER_PANEL_FRAME_PATH) as Texture2D
	if close_button_texture == null and ResourceLoader.exists(CLOSE_BUTTON_TEXTURE_PATH):
		close_button_texture = load(CLOSE_BUTTON_TEXTURE_PATH) as Texture2D
	if tab_inactive_texture == null and ResourceLoader.exists(TAB_INACTIVE_TEXTURE_PATH):
		tab_inactive_texture = load(TAB_INACTIVE_TEXTURE_PATH) as Texture2D
	if tab_active_texture == null and ResourceLoader.exists(TAB_ACTIVE_TEXTURE_PATH):
		tab_active_texture = load(TAB_ACTIVE_TEXTURE_PATH) as Texture2D
	if lock_icon_texture == null and ResourceLoader.exists(LOCK_ICON_TEXTURE_PATH):
		lock_icon_texture = load(LOCK_ICON_TEXTURE_PATH) as Texture2D
	if character_card_frame_texture == null and ResourceLoader.exists(CHARACTER_CARD_FRAME_PATH):
		character_card_frame_texture = load(CHARACTER_CARD_FRAME_PATH) as Texture2D
	if input_row_bg_texture == null and ResourceLoader.exists(INPUT_ROW_BG_TEXTURE_PATH):
		input_row_bg_texture = load(INPUT_ROW_BG_TEXTURE_PATH) as Texture2D
	if toggle_on_texture == null and ResourceLoader.exists(TOGGLE_ON_TEXTURE_PATH):
		toggle_on_texture = load(TOGGLE_ON_TEXTURE_PATH) as Texture2D
	if toggle_off_texture == null and ResourceLoader.exists(TOGGLE_OFF_TEXTURE_PATH):
		toggle_off_texture = load(TOGGLE_OFF_TEXTURE_PATH) as Texture2D
	if gold_digit_sheet_texture == null and ResourceLoader.exists(GOLD_DIGIT_SHEET_PATH):
		gold_digit_sheet_texture = load(GOLD_DIGIT_SHEET_PATH) as Texture2D
	character_button_used_region = _texture_used_region(character_button_texture)
	ranking_button_used_region = _texture_used_region(ranking_button_texture)
	attendance_button_used_region = _texture_used_region(attendance_button_texture)
	shop_button_used_region = _texture_used_region(shop_button_texture)
	attendance_track_bg_used_region = _texture_used_region(attendance_track_bg_texture)
	attendance_ruby_icon_used_region = _texture_used_region(attendance_ruby_icon_texture)
	attendance_complete_badge_used_region = _texture_used_region(attendance_complete_badge_texture)
	attendance_chest_closed_used_region = _texture_used_region(attendance_chest_closed_texture)
	attendance_chest_open_used_region = _texture_used_region(attendance_chest_open_texture)
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
	panel_frame_used_region = _texture_used_region(panel_frame_texture)
	character_panel_frame_used_region = _texture_used_region(character_panel_frame_texture)
	close_button_used_region = _texture_used_region(close_button_texture)
	tab_inactive_used_region = _texture_used_region(tab_inactive_texture)
	tab_active_used_region = _texture_used_region(tab_active_texture)
	lock_icon_used_region = _texture_used_region(lock_icon_texture)
	character_card_frame_used_region = _texture_used_region(character_card_frame_texture)
	input_row_bg_used_region = _texture_used_region(input_row_bg_texture)
	toggle_on_used_region = _texture_used_region(toggle_on_texture)
	toggle_off_used_region = _texture_used_region(toggle_off_texture)
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
	if boss_turner_texture == null and ResourceLoader.exists(BOSS_TURNER_PATH):
		boss_turner_texture = load(BOSS_TURNER_PATH) as Texture2D
	if boss_turner_texture != null:
		boss_turner_used_region = _texture_used_region(boss_turner_texture)
		var boss_image := boss_turner_texture.get_image()
		if boss_image != null and not boss_image.is_empty():
			var mirrored_boss_image := boss_image.duplicate()
			mirrored_boss_image.flip_x()
			mirrored_boss_turner_texture = ImageTexture.create_from_image(mirrored_boss_image)
			mirrored_boss_turner_used_region = _texture_used_region(mirrored_boss_turner_texture)
	if boss_turner_angry_texture == null and ResourceLoader.exists(BOSS_TURNER_ANGRY_PATH):
		boss_turner_angry_texture = load(BOSS_TURNER_ANGRY_PATH) as Texture2D
	if boss_turner_angry_texture != null:
		boss_turner_angry_used_region = _texture_used_region(boss_turner_angry_texture)
		var boss_angry_image := boss_turner_angry_texture.get_image()
		if boss_angry_image != null and not boss_angry_image.is_empty():
			var mirrored_boss_angry_image := boss_angry_image.duplicate()
			mirrored_boss_angry_image.flip_x()
			mirrored_boss_turner_angry_texture = ImageTexture.create_from_image(mirrored_boss_angry_image)
			mirrored_boss_turner_angry_used_region = _texture_used_region(mirrored_boss_turner_angry_texture)
	if boss_turner_shocked_texture == null and ResourceLoader.exists(BOSS_TURNER_SHOCKED_PATH):
		boss_turner_shocked_texture = load(BOSS_TURNER_SHOCKED_PATH) as Texture2D
	if boss_turner_shocked_texture != null:
		boss_turner_shocked_used_region = _texture_used_region(boss_turner_shocked_texture)
		var boss_shocked_image := boss_turner_shocked_texture.get_image()
		if boss_shocked_image != null and not boss_shocked_image.is_empty():
			var mirrored_boss_shocked_image := boss_shocked_image.duplicate()
			mirrored_boss_shocked_image.flip_x()
			mirrored_boss_turner_shocked_texture = ImageTexture.create_from_image(mirrored_boss_shocked_image)
			mirrored_boss_turner_shocked_used_region = _texture_used_region(mirrored_boss_turner_shocked_texture)


func _prepare_countdown_visuals() -> void:
	countdown_textures.clear()
	countdown_used_regions.clear()
	for path in COUNTDOWN_PATHS:
		var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
		countdown_textures.append(texture)
		countdown_used_regions.append(_texture_used_region(texture))
	if boss_warning_texture == null and ResourceLoader.exists(BOSS_WARNING_PATH):
		boss_warning_texture = load(BOSS_WARNING_PATH) as Texture2D
	boss_warning_used_region = _texture_used_region(boss_warning_texture)


func _process(delta: float) -> void:
	if tutorial_pause_active:
		queue_redraw()
		return
	if game_state == GameState.PLAYING:
		if coop_mode:
			_advance_coop_jumps(delta)
		elif air_challenge_active:
			_advance_air_challenge(delta)
		elif is_jumping:
			jump_animation_time += delta
			var gravity_multiplier := SPACE_GRAVITY_MULTIPLIER if score >= SPACE_SCORE_THRESHOLD else 1.0
			jump_velocity += 1900.0 * gravity_multiplier * delta
			jump_height += jump_velocity * delta
			if jump_height >= 0.0:
				jump_height = 0.0
				jump_velocity = 0.0
				jump_animation_time = 0.0
				is_jumping = false
				used_double_jump = false
				accepting_input = not turner_transition_active
				if score >= SPACE_SCORE_THRESHOLD:
					# The rope sat frozen wherever it happened to be when this
					# jump started (see the SPACE_SCORE_THRESHOLD freeze
					# below) — resuming from that exact spot could land it
					# right on the crossing angle with zero warning. Only
					# nudge it back to the start of a fair cue window when
					# landing would otherwise be unsafe — an unconditional
					# reset to a fixed safe angle on every single landing let
					# spamming jump forever dodge the rope for free, since no
					# crossing could ever actually occur.
					var seconds_until_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_angle, TAU) / maxf(rope_speed, 0.01)
					if seconds_until_crossing < balance.jump_cue_seconds:
						rope_angle = fposmod(ROPE_CROSSING_ANGLE - rope_speed * balance.jump_cue_seconds, TAU)
		if air_challenge_landing_time > 0.0:
			air_challenge_landing_time = maxf(0.0, air_challenge_landing_time - delta)
			accepting_input = false
			if air_challenge_landing_time <= 0.0:
				rope_angle = PI
				rope_b_angle = fposmod(PI + ROPE_B_PHASE_OFFSET, TAU)
				accepting_input = true
				message = "다시 줄넘기!"
				message_color = Color("73f7b4")
		elif air_challenge_active:
			# The lower ropes visibly wait behind the player for the entire
			# high-jump sequence, so landing can never produce a surprise hit.
			accepting_input = true
		elif turner_transition_active:
			accepting_input = false
			_advance_turner_transition(delta)
		else:
			# The ropes deliberately do NOT pause while airborne here — with
			# SPACE_GRAVITY_MULTIPLIER's long float time, staying live means
			# a single jump can genuinely face more than one pass of either
			# rope, which is the actual difficulty of this zone. (An earlier
			# version froze both ropes once their first crossing resolved —
			# that made a well-timed jump nearly unloseable, since nothing
			# could touch you again until you chose to land.)
			if tutorial_active and tutorial_stage == 2 and _is_jump_cue():
				# Freeze the instant the rope turns red for the very first
				# time (before this frame advances it further) instead of at
				# an arbitrary score — the whole point of this stage is to
				# catch that exact moment for the explanation.
				tutorial_pause_active = true
				queue_redraw()
				return
			_update_sleepy_warning(delta)
			if _update_prankster_fake(delta):
				queue_redraw()
				return
			var previous_rope_angle := rope_angle
			rope_angle = fposmod(rope_angle + _effective_rope_speed() * delta, TAU)
			if _angle_crossed(previous_rope_angle, rope_angle, ROPE_CROSSING_ANGLE):
				_resolve_rope_crossing()
			if rope_b_enabled and game_state == GameState.PLAYING:
				var previous_rope_b_angle := rope_b_angle
				rope_b_angle = fposmod(rope_b_angle + _effective_rope_speed() * delta, TAU)
				if _angle_crossed(previous_rope_b_angle, rope_b_angle, ROPE_CROSSING_ANGLE):
					_resolve_rope_b_crossing()
	elif game_state == GameState.HIT:
		hit_reveal_time -= delta
		if hit_reveal_time <= 0.0:
			game_state = GameState.GAME_OVER
			# A gem-revive continues the same run past its first death, so the
			# score at this point already includes revive-earned progress.
			# Ranking should reflect the run's very first death only — that
			# submission already happened before any revive was possible.
			if not revived_this_run:
				_submit_score(score)
			if not coop_mode and not newly_unlocked_this_run.is_empty():
				newly_unlocked_this_run.sort_custom(func(a: String, b: String) -> bool:
					return int(character_unlock_scores.get(a, 0)) < int(character_unlock_scores.get(b, 0)))
				character_reveal_active = true
				character_reveal_index = 0
				character_reveal_time = 0.0
			if tutorial_active and tutorial_stage == 5:
				# Stage 5 is "waiting for the tour's first death" — skip the
				# game-over screen entirely and land straight back on the
				# title so its arrow (pointing at the CHARACTER button) can
				# show immediately.
				_return_to_main()
	if character_reveal_active:
		character_reveal_time += delta
	if flash_time > 0.0:
		flash_time -= delta
	if perfect_display_time > 0.0:
		perfect_display_time = maxf(0.0, perfect_display_time - delta)
	queue_redraw()


func _advance_turner_transition(delta: float) -> void:
	turner_transition_time += delta
	if turner_transition_phase == TurnerTransitionPhase.TURNER_EXIT and turner_transition_time >= TURNER_EXIT_SECONDS:
		turner_transition_time -= TURNER_EXIT_SECONDS
		turner_transition_phase = TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN
		countdown_vibration_index = -1
	if turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		# One buzz per number and a stronger one for GO — keyed off the same
		# index _draw_countdown_overlay uses, so it fires exactly once per
		# step instead of every frame that step is on screen.
		var countdown_index := mini(3, int(turner_transition_time / COUNTDOWN_NUMBER_SECONDS))
		if countdown_index != countdown_vibration_index:
			countdown_vibration_index = countdown_index
			if feedback != null:
				if countdown_index == 3:
					feedback.play_countdown_go()
				else:
					feedback.play_countdown_tick()
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
	if ranking_menu_open and ranking_scroll_dragging:
		var motion_position := Vector2(-1.0, -1.0)
		if event is InputEventScreenDrag:
			motion_position = (event as InputEventScreenDrag).position
		elif event is InputEventMouseMotion:
			motion_position = (event as InputEventMouseMotion).position
		if motion_position.x >= 0.0:
			var local_position := _screen_to_design(motion_position) - RANKING_LIST_RECT.position
			_update_ranking_list_drag(local_position)
			get_viewport().set_input_as_handled()
			return
		var released := (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed) \
			or (event is InputEventMouseButton and not (event as InputEventMouseButton).pressed)
		if released:
			_end_ranking_list_drag()
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
		if tutorial_pause_active:
			var dismissed_stage := tutorial_stage
			tutorial_pause_active = false
			tutorial_stage += 1
			if dismissed_stage == 2:
				# Stage 2's freeze holds the very instant the rope turns red;
				# this exact tap is the player's real first jump attempt at
				# that cue, so — uniquely among stages — it falls through to
				# the normal jump handling below instead of just resuming.
				pass
			else:
				if dismissed_stage == 11:
					# Stage 11 (reward message) hands off straight into a
					# small dedicated nickname prompt — not the full settings
					# panel, which was still showing the attendance panel
					# open behind it and drawing both at once.
					attendance_menu_open = false
					_show_tutorial_nickname_prompt()
				get_viewport().set_input_as_handled()
				return
		if tutorial_nickname_prompt_active and pointer_position.x >= 0.0:
			var nickname_prompt_position := _screen_to_design(pointer_position)
			if TUTORIAL_NICKNAME_SAVE_RECT.has_point(nickname_prompt_position):
				_confirm_tutorial_nickname()
			get_viewport().set_input_as_handled()
			return
		if game_state == GameState.GAME_OVER and character_reveal_active:
			character_reveal_index += 1
			character_reveal_time = 0.0
			if character_reveal_index >= newly_unlocked_this_run.size():
				character_reveal_active = false
			get_viewport().set_input_as_handled()
			return
		if game_state == GameState.GAME_OVER and pointer_position.x >= 0.0:
			var game_over_position := _screen_to_design(pointer_position)
			if GAME_OVER_CLOSE_RECT.has_point(game_over_position):
				_return_to_main()
				get_viewport().set_input_as_handled()
				return
			if _can_revive() and _game_over_revive_rect().has_point(game_over_position):
				_revive_with_gem()
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
			if attendance_menu_open:
				_handle_attendance_menu_input(design_position)
				get_viewport().set_input_as_handled()
				return
			if settings_menu_open:
				_handle_settings_menu_input(design_position)
				get_viewport().set_input_as_handled()
				return
			if TEST_START_170_RECT.has_point(design_position):
				_start_game_at_score(170)
				get_viewport().set_input_as_handled()
				return
			if TEST_START_130_RECT.has_point(design_position):
				_start_game_at_score(130)
				get_viewport().set_input_as_handled()
				return
			if CHARACTER_BUTTON_RECT.has_point(design_position):
				character_menu_open = true
				if tutorial_active and tutorial_stage == 5:
					tutorial_stage = 6
				get_viewport().set_input_as_handled()
				return
			if COOP_BUTTON_RECT.has_point(design_position):
				if tutorial_active and tutorial_stage == 8:
					tutorial_stage = 9
				_start_coop_game()
				get_viewport().set_input_as_handled()
				return
			if SETTINGS_BUTTON_RECT.has_point(design_position):
				_open_settings_menu()
				get_viewport().set_input_as_handled()
				return
			if RANKING_MAIN_BUTTON_RECT.has_point(design_position):
				_open_ranking_menu()
				get_viewport().set_input_as_handled()
				return
			if ATTENDANCE_MAIN_BUTTON_RECT.has_point(design_position):
				_open_attendance_menu()
				get_viewport().set_input_as_handled()
				return
			if SHOP_BUTTON_RECT.has_point(design_position):
				_open_shop_url()
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
		if game_state == GameState.TITLE and not tutorial_seen:
			_start_tutorial_run()
			return
		_start_game()
		return
	if air_challenge_active:
		_attempt_air_rope_tap()
		return
	if is_jumping:
		# accepting_input is deliberately NOT checked here — it's false for
		# the whole flight (it always has been, to block spamming a second
		# normal jump), but the space zone's double jump needs to land a
		# tap precisely while that's true, so it has to sit ahead of that
		# gate instead of behind it like every other jump path.
		if score >= DOUBLE_JUMP_SCORE_THRESHOLD and not coop_mode and not used_double_jump:
			used_double_jump = true
			jump_velocity = DOUBLE_JUMP_VELOCITY
			jump_animation_time = 0.0
		return
	if not accepting_input:
		return
	accepting_input = false
	is_jumping = true
	jump_animation_time = 0.0
	jump_started_in_cue = _is_jump_cue()
	jump_velocity = -820.0
	used_double_jump = false


func _start_air_challenge() -> void:
	if coop_mode or air_challenge_active or game_state != GameState.PLAYING:
		return
	air_challenge_active = true
	air_challenge_next_rope = 0
	air_challenge_combo = 0
	air_challenge_last_score = score
	air_challenge_landing_time = 0.0
	turner_transition_active = false
	turner_transition_phase = TurnerTransitionPhase.NONE
	rope_angle = PI
	rope_b_angle = fposmod(PI + ROPE_B_PHASE_OFFSET, TAU)
	is_jumping = true
	jump_height = 0.0
	jump_velocity = AIR_CHALLENGE_JUMP_VELOCITY
	jump_animation_time = 0.0
	jump_started_in_cue = false
	accepting_input = true
	message = "공중 줄 3개를 타이밍에 맞춰 탭!"
	message_color = Color("ffd84a")
	flash_time = 0.22


func _advance_air_challenge(delta: float) -> void:
	jump_animation_time += delta
	jump_velocity += AIR_CHALLENGE_GRAVITY * delta
	jump_height += jump_velocity * delta
	if jump_height < 0.0:
		return
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	is_jumping = false
	air_challenge_active = false
	air_challenge_landing_time = AIR_CHALLENGE_LANDING_PAUSE
	accepting_input = false
	rope_angle = PI
	rope_b_angle = fposmod(PI + ROPE_B_PHASE_OFFSET, TAU)
	message = "착지!  공중 콤보 %d/3" % air_challenge_combo
	message_color = Color("73f7b4") if air_challenge_combo >= AIR_ROPE_HEIGHTS.size() else Color("ffd84a")


func _attempt_air_rope_tap() -> void:
	if air_challenge_next_rope >= AIR_ROPE_HEIGHTS.size():
		return
	var target_height := float(AIR_ROPE_HEIGHTS[air_challenge_next_rope])
	if absf(jump_height - target_height) > AIR_CHALLENGE_TAP_TOLERANCE:
		message = "조금 더 가까이!"
		message_color = Color("ffd84a")
		return
	air_challenge_combo += 1
	air_challenge_next_rope += 1
	message = "공중 콤보 %d!" % air_challenge_combo
	message_color = Color("73f7b4")
	flash_time = 0.16


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
		if _is_perfect_crossing():
			perfect_display_time = PERFECT_DISPLAY_SECONDS
			perfect_count += 1
		score += 1
		if score > best_score:
			best_score = score
			new_best_this_run = true
			_check_score_unlocks()
		total_success += 1
		if rope_b_enabled and score >= AIR_CHALLENGE_START_SCORE and score < SPACE_SCORE_THRESHOLD:
			# Double rope is a boss-only gimmick between the two thresholds,
			# capped at the same score the (still disabled — see
			# AIR_CHALLENGE_ENABLED) air challenge would otherwise start —
			# it drops back to a plain single rope there instead of running
			# forever. The space zone (SPACE_SCORE_THRESHOLD) deliberately
			# re-enables its own second rope right after, so this must not
			# also switch that one back off.
			rope_b_enabled = false
		if DOUBLE_ROPE_TEST_ENABLED and score >= DOUBLE_ROPE_TEST_SCORE_THRESHOLD and score < AIR_CHALLENGE_START_SCORE:
			if not boss_double_rope_intro_shown:
				# The very first turn past the threshold stays a single rope
				# — starting the second rope immediately was too big a jump
				# in difficulty. This one turn just announces what's coming;
				# the actual toggle starts on the turn after.
				boss_double_rope_intro_shown = true
				boss_double_rope_was_double_last_turn = false
				rope_b_enabled = false
				rope_speed = _base_speed_for_score(score)
				# Same exit+countdown pause and red "경고!" warning as the boss's
				# initial pattern-random entry at BOSS_TURNER_SCORE_THRESHOLD —
				# adding a second rope mid-run is a big enough rule change to
				# deserve the same heads-up instead of appearing instantly.
				_start_turner_transition(turner_team, true)
				message = "보스 등장! 곧 줄이 2개가 됩니다!"
				message_color = Color("ff6b6b")
				flash_time = 0.22
				jump_started_in_cue = false
				feedback.play_success(score)
				return
			# Every turn after the intro: double rope appears at most every
			# other turn — never twice in a row — so the player isn't forced
			# to track two ropes on literally every single jump.
			if boss_double_rope_was_double_last_turn:
				rope_b_enabled = false
			else:
				rope_b_enabled = randf() < 0.5
			boss_double_rope_was_double_last_turn = rope_b_enabled
			if rope_b_enabled:
				rope_b_angle = fposmod(rope_angle + ROPE_B_PHASE_OFFSET, TAU)
		if AIR_CHALLENGE_ENABLED and _should_start_air_challenge():
			_start_air_challenge()
			feedback.play_success(score)
			return
		var previous_team := turner_team
		var team_changed := _update_turner_team_and_pattern()
		# Recompute after the team update, not before — _base_speed_for_score
		# now depends on the live turner_team (flat for athlete/prankster/
		# wizard, ramping for student/sleepy), so computing it with the
		# about-to-be-replaced team baked in a stale speed into the new
		# team's very first turn (e.g. a sleepy-ramped high baseline carried
		# into athlete's burst multiplier, or vice versa into sleepy looking
		# like it barely moves).
		rope_speed = _base_speed_for_score(score)
		message_color = Color("73f7b4")
		if team_changed:
			# Boss fight has two halves (see _turner_slot_for_score): 90..110
			# still rerolls the normal pattern every BOSS_GAUNTLET_TURNER_
			# INTERVAL points — same as before the boss showed up, just under
			# the calm-king reskin — so only the very first entry gets an
			# announcement; every later reroll in that stretch swaps silently.
			# 110..AIR_CHALLENGE_START_SCORE locks to the plain default pattern
			# (the angry king's phase) — that transition is silent too, since
			# the double-rope intro turn already announced the phase change.
			var is_boss_change := score >= BOSS_TURNER_SCORE_THRESHOLD and score < AIR_CHALLENGE_START_SCORE
			var is_first_boss_entry := score == BOSS_TURNER_SCORE_THRESHOLD
			if is_boss_change and not is_first_boss_entry:
				message = "좋아요!  +1"
			elif is_boss_change:
				_start_turner_transition(previous_team, true)
				message = "보스 등장!  패턴이 계속 무작위로 바뀝니다!"
				message_color = Color("ff6b6b")
			else:
				_start_turner_transition(previous_team, false)
				match turner_team:
					TurnerTeam.ATHLETE:
						message = "운동부 등장!  기본 2회 뒤 급가속!"
					TurnerTeam.SLEEPY:
						message = "졸보 등장!  깨면 1초 뒤 초고속!"
					TurnerTeam.PRANKSTER:
						message = "장난꾸러기 등장!  멈추는 척을 조심!"
					TurnerTeam.WIZARD:
						message = "마법사 등장!  사라진 줄은 빨간색을 봐!"
					TurnerTeam.DUO:
						message = "운동부&잠꾸러기 등장!  잠꾸러기가 깨면 급발진!"
					TurnerTeam.WIZARD_PRANKSTER_DUO:
						message = "마법사&장난꾸러기 등장!  줄이 항상 안 보여요!"
				if tutorial_active and tutorial_stage == 3:
					# The tour's very first turner-team change (always score
					# 10, TURNER_CHANGE_INTERVAL) doubles as its own
					# checkpoint — freeze on top of the normal entrance
					# transition with a generic pattern-awareness warning.
					tutorial_stage = 4
					tutorial_pause_active = true
		elif turner_team == TurnerTeam.SLEEPY and sleepy_wake_warning_time > 0.0:
			message = "번쩍!  1초 뒤 초고속!"
		elif turner_team == TurnerTeam.ATHLETE and challenge_pattern == 2:
			message = "운동부 급가속!"
		elif turner_team == TurnerTeam.DUO and sleepy_wake_warning_time > 0.0:
			message = "번쩍!  1초 뒤 잠꾸러기 급발진!"
		elif turner_team == TurnerTeam.DUO and duo_sleepy_awake:
			message = "잠꾸러기 급발진!"
		elif turner_team == TurnerTeam.DUO and duo_athlete_bursting:
			message = "운동부 급가속!"
		elif turner_team == TurnerTeam.WIZARD_PRANKSTER_DUO and duo2_prankster_triggered:
			message = "장난꾸러기 줄속임!"
			message_color = Color("ffd84a")
		elif turner_team == TurnerTeam.STUDENT and comet_rush_active:
			message = "혜성이 지나가요!"
			message_color = Color("ff6b6b")
		else:
			message = "좋아요!  +1"
		flash_time = 0.22
		jump_started_in_cue = false
		feedback.play_success(score)
	else:
		rope_angle = ROPE_CROSSING_ANGLE
		_trigger_rope_miss()


func _resolve_rope_b_crossing() -> void:
	# A pass while grounded is a no-op, not a miss — this rope only exists
	# to threaten an actual jump attempt (clear it or don't), same as the
	# main rope requires you to actually be jumping to be judged at all
	# (_player_clears_rope_at_crossing's own is_jumping check). Without this
	# guard, the space zone's slow fixed baseline gives such a long grounded
	# gap between jumps that rope_b's own half-turn phase offset (see
	# ROPE_B_PHASE_OFFSET) reliably completes and "hits" the player while
	# they're simply standing there waiting for the main rope's next cue —
	# an unavoidable, un-timeable death with no real interaction at all.
	if not is_jumping:
		return
	# The boss double-dutch rope never awards score on its own — it's an
	# extra fail condition layered on top of the main rope's rhythm. In the
	# space zone this same rope is the overhead one instead (see
	# SPACE_OVERHEAD_ROPE_Y_OFFSET), so clearing it means being genuinely
	# high up — the ordinary ground-rope clearance height wouldn't require
	# the double jump at all.
	var cleared := jump_height <= -SPACE_OVERHEAD_CLEAR_HEIGHT if turner_change_slot == SPACE_SLOT else _player_clears_rope_at_crossing()
	if not cleared:
		rope_b_angle = ROPE_CROSSING_ANGLE
		_trigger_rope_miss()


func _trigger_rope_miss() -> void:
	# Freeze at the visible contact point before revealing the result panel.
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


func _is_perfect_crossing() -> bool:
	# Judge the same frame as the visible rope/feet collision. Requiring both
	# enough height and low vertical speed keeps early rising or late falling
	# clears as ordinary successes instead of rewarding input time alone.
	return not coop_mode \
		and is_jumping \
		and jump_height <= -PERFECT_MIN_HEIGHT \
		and jump_velocity >= -PERFECT_MAX_RISING_SPEED \
		and jump_velocity <= PERFECT_MAX_FALLING_SPEED


func _coop_player_clears_rope(player_x: float, jumping: bool, height: float) -> bool:
	if not jumping:
		return false
	var rope_top_y := _rope_y_at_x(ROPE_CROSSING_ANGLE, player_x) - ROPE_PIXEL_OUTLINE_SIZE.y * 0.5
	return PLAYER_GROUND_Y + height + player_sprite_ground_offset.y < rope_top_y


func _start_tutorial_run() -> void:
	# Marked seen immediately, not on completion — a player who bails out
	# mid-tutorial (backs out, gets hit early) should still never see it
	# again, same as most games' one-shot onboarding.
	tutorial_seen = true
	_save_progress()
	_start_game()
	tutorial_active = true
	# Stage 1 ("tap to start") is now shown on the title screen itself
	# before this tap even happens (see the tutorial_seen check in
	# _draw_main_menu) — this very tap already fulfilled it, so the tour
	# starts directly at stage 2 instead of freezing again to ask for a
	# second, redundant tap.
	tutorial_stage = 2
	tutorial_pause_active = false


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
	# Deliberately does NOT touch tutorial_active/tutorial_stage — the guided
	# tour spans multiple runs (its coop stage starts a fresh run via
	# _start_coop_game -> _start_run), so only the per-run pause flag resets
	# here. tutorial_active is only ever cleared when the tour itself
	# finishes (see the settings-menu tutorial_stage == TUTORIAL_STAGE_COUNT
	# checks).
	tutorial_pause_active = false
	run_start_best = best_score
	new_best_this_run = false
	run_coins_earned = 0
	hit_reveal_time = 0.0
	revived_this_run = false
	newly_unlocked_this_run.clear()
	character_reveal_active = false
	character_reveal_index = 0
	character_reveal_time = 0.0
	score = 0
	rope_angle = PI
	rope_speed = balance.base_rope_speed
	rope_b_enabled = false
	rope_b_angle = fposmod(PI + ROPE_B_PHASE_OFFSET, TAU)
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	is_jumping = false
	jump_started_in_cue = false
	perfect_display_time = 0.0
	perfect_count = 0
	_reset_air_challenge()
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
	turner_change_slot = _turner_slot_for_score(score)
	if turner_change_slot == DUO_STAGE_SLOT:
		turner_team = TurnerTeam.DUO
		_init_turner_team_state(turner_team)
	elif turner_change_slot == WIZARD_PRANKSTER_DUO_SLOT:
		turner_team = TurnerTeam.WIZARD_PRANKSTER_DUO
		_init_turner_team_state(turner_team)
	elif turner_change_slot == SPACE_SLOT:
		turner_team = TurnerTeam.STUDENT
		_init_turner_team_state(turner_team)
		rope_b_enabled = true
		rope_b_angle = fposmod(rope_angle + ROPE_B_PHASE_OFFSET, TAU)
	elif turner_change_slot > 0:
		turner_team = _random_turner_team(TurnerTeam.STUDENT)
		_init_turner_team_state(turner_team)
	else:
		turner_team = TurnerTeam.STUDENT
	rope_speed = _base_speed_for_score(score)
	message = "테스트 모드: %d회부터 시작!" % score
	message_color = Color("ffd84a")
	if AIR_CHALLENGE_ENABLED and score >= AIR_CHALLENGE_START_SCORE:
		_start_air_challenge()


func _return_to_main() -> void:
	game_state = GameState.TITLE
	score = 0
	rope_angle = PI
	rope_speed = balance.base_rope_speed
	rope_b_enabled = false
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	is_jumping = false
	coop_mode = false
	_reset_coop_players()
	jump_started_in_cue = false
	_reset_air_challenge()
	accepting_input = true
	_reset_turner_run()
	hit_reveal_time = 0.0
	menu_notice = ""
	message = "화면을 눌러 시작"
	message_color = Color.WHITE
	queue_redraw()


func _reset_air_challenge() -> void:
	air_challenge_active = false
	air_challenge_next_rope = 0
	air_challenge_combo = 0
	air_challenge_landing_time = 0.0
	air_challenge_last_score = -1


func _should_start_air_challenge() -> bool:
	return not coop_mode \
		and score >= AIR_CHALLENGE_START_SCORE \
		and score % AIR_CHALLENGE_INTERVAL == 0 \
		and air_challenge_last_score != score


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


func _reset_all_data() -> void:
	# Settings → "데이터 초기화", gated behind a second confirming tap (see
	# _handle_settings_menu_input). Wipes the save file back to defaults and
	# reloads every in-memory field from it, same as a fresh install — most
	# notably tutorial_seen goes back to false, so the very next title tap
	# runs the guided first-run tutorial again.
	save_manager.save_game(save_manager.default_data())
	owned_character_ids.clear()
	_load_character_catalog()
	_load_saved_progress()
	character_reveal_active = false
	newly_unlocked_this_run.clear()
	data_reset_confirm_pending = false
	settings_message = "초기화 완료! 처음부터 다시 시작합니다"


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
	attendance_streak = int(data.attendance.streak)
	attendance_last_claim_date = str(data.attendance.last_claim_date)
	tutorial_seen = bool(data.tutorial_seen)


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
			newly_unlocked_this_run.append(character_id)


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
		"attendance": {
			"streak": attendance_streak,
			"last_claim_date": attendance_last_claim_date,
		},
		"tutorial_seen": tutorial_seen,
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
	if air_challenge_active:
		_draw_air_challenge_ropes()
	if coop_mode:
		_draw_coop_players()
	else:
		_draw_player()
	if turner_transition_phase == TurnerTransitionPhase.TURNER_ENTRY_COUNTDOWN:
		_draw_countdown_overlay()
	if perfect_display_time > 0.0:
		_draw_perfect_overlay()
	# Front ropes pass over the character visually, but only the real rope owns
	# the crossing/game-over rule.
	if not turner_transition_active:
		_draw_rope_layer(false)
	if game_state == GameState.HIT:
		_draw_hit_feedback()
	if game_state != GameState.TITLE and score >= BOSS_TURNER_SCORE_THRESHOLD and score < AIR_CHALLENGE_START_SCORE:
		_draw_boss_edge_vignette()
	_draw_hud()
	_draw_tutorial_layer()


func _draw_coop_divider() -> void:
	draw_rect(Rect2(0.0, 0.0, DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(0.20, 0.55, 1.0, 0.055), true)
	draw_rect(Rect2(DESIGN_SIZE.x * 0.5, 0.0, DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(1.0, 0.35, 0.48, 0.055), true)
	draw_line(Vector2(DESIGN_SIZE.x * 0.5, 0.0), Vector2(DESIGN_SIZE.x * 0.5, DESIGN_SIZE.y), Color(1.0, 1.0, 1.0, 0.72), 5.0, true)


func _draw_boss_edge_vignette() -> void:
	# A pulsing red frame around the screen edges for the whole boss gauntlet
	# (90..AIR_CHALLENGE_START_SCORE), not just the entrance warning — layered
	# semi-transparent strokes fake a vignette without needing a shader.
	# Noticeably stronger from 110 on (angry king + locked pattern + double
	# rope) so the edge glow itself telegraphs the difficulty spike, not just
	# the character reskin.
	var intensity := 1.5 if score >= DOUBLE_ROPE_TEST_SCORE_THRESHOLD else 1.0
	var pulse := (0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.0035)) * intensity
	var full := Rect2(Vector2.ZERO, DESIGN_SIZE)
	for i in range(4):
		var width := 18.0 + float(i) * 24.0
		var alpha := (0.22 - float(i) * 0.045) * pulse
		draw_rect(full, Color(0.85, 0.05, 0.05, alpha), false, width)


func _draw_boss_warning_overlay() -> void:
	# Stands in for the normal "3,2,1,GO" countdown during a boss pattern
	# change — same transition timing (see _start_turner_transition), just
	# a continuously shaking red warning instead of counting down numbers,
	# to read as urgent rather than a calm countdown.
	var shake_x := roundf(sin(turner_transition_time * TAU * 9.0) * 16.0)
	var pulse := 0.5 + 0.5 * sin(turner_transition_time * TAU * 5.0)
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.75, 0.03, 0.05, 0.10 + pulse * 0.14), true)
	if boss_warning_texture != null and boss_warning_used_region.size.x > 0.0:
		var target_size := Vector2(600.0, 200.0)
		var scale_factor := minf(target_size.x / boss_warning_used_region.size.x, target_size.y / boss_warning_used_region.size.y)
		var draw_size := boss_warning_used_region.size * scale_factor
		var center := Vector2(360.0 + shake_x, 450.0)
		draw_texture_rect_region(boss_warning_texture, Rect2(center - draw_size * 0.5, draw_size), boss_warning_used_region)
		return
	var font := _ui_font()
	var box := Rect2(shake_x + 60.0, 400.0, 600.0, 100.0)
	draw_string(font, box.position + Vector2(0.0, 4.0), "경고!", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 76, Color(0.0, 0.0, 0.0, 0.6))
	draw_string(font, box.position + Vector2(-4.0, 0.0), "경고!", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 76, Color("ff1f33"))


func _draw_countdown_overlay() -> void:
	if turner_transition_is_boss:
		_draw_boss_warning_overlay()
		return
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


func _draw_perfect_overlay() -> void:
	# Reuse the countdown GO position so the timing result appears in the
	# player's existing focal area without covering the character or rope.
	var progress := 1.0 - perfect_display_time / PERFECT_DISPLAY_SECONDS
	var alpha := clampf(perfect_display_time / 0.18, 0.0, 1.0)
	var pop_scale := 1.0 + maxf(0.0, 1.0 - progress * 5.0) * 0.18
	var width := 600.0 * pop_scale
	var box := Rect2(Vector2(360.0 - width * 0.5, 425.0), Vector2(width, 100.0))
	var font := _ui_font()
	var shadow_color := Color(0.18, 0.05, 0.22, 0.75 * alpha)
	var perfect_color := Color(1.0, 0.86, 0.22, alpha)
	draw_string(font, box.position + Vector2(5.0, 7.0), "PERFECT!", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 68, shadow_color)
	draw_string(font, box.position, "PERFECT!", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 68, perfect_color)


func _draw_background() -> void:
	if game_state != GameState.TITLE and score >= SPACE_SCORE_THRESHOLD:
		_draw_space_background()
		return
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


func _draw_space_background() -> void:
	# Rough first pass, no dedicated art yet — dark sky, a fixed (not
	# randomized-per-frame) starfield via a deterministic formula so stars
	# don't jitter every redraw, and a distant planet standing in for the
	# sun. See _draw_space_ground for the matching ground swap.
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color("060818"))
	for i in range(55):
		var star_x := fmod(float(i) * 137.5, DESIGN_SIZE.x)
		var star_y := fmod(float(i) * 71.3 + 40.0, 650.0)
		var star_alpha: float = 0.35 + 0.5 * absf(sin(float(i) * 12.9))
		var star_radius: float = 1.5 + 1.5 * absf(sin(float(i) * 4.7))
		draw_circle(Vector2(star_x, star_y), star_radius, Color(1.0, 1.0, 1.0, star_alpha))
	draw_circle(Vector2(580.0, 170.0), 58.0, Color("ff9f6b"))
	draw_circle(Vector2(580.0, 170.0), 58.0, Color(0.1, 0.05, 0.15, 0.35))
	draw_arc(Vector2(580.0, 170.0), 74.0, -0.5, 0.5, 24, Color("ffd7b0"), 6.0, true)
	if flash_time > 0.0:
		draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(1, 1, 1, flash_time * 0.32))


func _draw_space_ground() -> void:
	# Plain grey moon-surface stand-in — the daytime ground (grass/pavement,
	# or the background_texture image which bakes ground into the same
	# picture as the sky) would look completely out of place under a dark
	# starfield.
	draw_rect(Rect2(0.0, 650.0, DESIGN_SIZE.x, 630.0), Color("3a3a45"))
	for i in range(10):
		var crater_x := fmod(float(i) * 211.0 + 40.0, DESIGN_SIZE.x)
		var crater_y := 700.0 + fmod(float(i) * 97.0, 500.0)
		draw_circle(Vector2(crater_x, crater_y), 14.0 + 6.0 * absf(sin(float(i) * 3.1)), Color("2c2c36"))


func _draw_ground() -> void:
	if game_state != GameState.TITLE and score >= SPACE_SCORE_THRESHOLD:
		_draw_space_ground()
		return
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
	if rope_b_enabled and _rope_angle_is_behind(rope_b_angle) == draw_behind:
		# rope_b is offset by ROPE_B_PHASE_OFFSET (half a turn) from the main
		# rope, so it reaches its own crossing at a different moment — using
		# the main rope's show_jump_cue here left it blue right through its
		# own crossing. It needs its own cue check against rope_b_angle.
		var show_rope_b_cue := _is_rope_b_jump_cue()
		var rope_b_color := Color("ff334f") if show_rope_b_cue else Color("35d0ff")
		var rope_b_highlight := Color("ff9a8d") if show_rope_b_cue else Color("bdf3ff")
		# In the space zone this isn't a second ground-level rope — it's an
		# overhead one, drawn well above the normal rope so it visibly reads
		# as "up high" (see SPACE_OVERHEAD_ROPE_Y_OFFSET / the double-jump
		# clearance check in _resolve_rope_b_crossing).
		var rope_b_vertical_offset := SPACE_OVERHEAD_ROPE_Y_OFFSET if turner_change_slot == SPACE_SLOT else 0.0
		_draw_rope_curve(rope_b_angle, rope_b_color, rope_b_highlight, outline_color, shadow_color, 0.0, rope_b_vertical_offset)


func _draw_rope_curve(curve_angle: float, rope_color: Color, highlight_color: Color, outline_color: Color, shadow_color: Color, lateral_offset := 0.0, vertical_offset := 0.0) -> void:
	var midpoint_y := _rope_midpoint_y(curve_angle) + vertical_offset
	var left_hand := _active_left_hand()
	var right_hand := _active_right_hand()
	var left_hand_y := left_hand.y + vertical_offset
	var right_hand_y := right_hand.y + vertical_offset
	var pixel_points := PackedVector2Array()
	for i in range(97):
		var t := float(i) / 96.0
		var x := lerpf(left_hand.x, right_hand.x, t) + 4.0 * t * (1.0 - t) * lateral_offset
		# 4t(1-t) is zero at both hands and one at the middle.
		var y := lerpf(left_hand_y, right_hand_y, t) + 4.0 * t * (1.0 - t) * (midpoint_y - left_hand_y)
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
	if turner_team == TurnerTeam.WIZARD_PRANKSTER_DUO:
		# Always invisible here, whether or not prankster's trick has
		# triggered this turn — unlike standalone WIZARD, which only hides
		# the rope on alternating turns (wizard_rope_hidden).
		return not _is_jump_cue()
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


func _is_rope_b_jump_cue() -> bool:
	# Same check as _is_jump_cue(), but against rope_b_angle — the boss's
	# second rope shares the main rope's angular speed (see the _process
	# update) but is offset by ROPE_B_PHASE_OFFSET, so it needs its own
	# independent cue window rather than borrowing the main rope's.
	if game_state != GameState.PLAYING or rope_speed <= 0.0 or cos(rope_b_angle) < 0.0:
		return false
	var seconds_until_crossing := fposmod(ROPE_CROSSING_ANGLE - rope_b_angle, TAU) / rope_speed
	return seconds_until_crossing <= balance.jump_cue_seconds


const DOUBLE_ROPE_SPEED_MULTIPLIER := 0.65
# Deviation from the fair rope_speed baseline gets pulled in during the
# double-rope stretch specifically — with two ropes to track at once, a full
# team-pattern speed swing (e.g. sleepy's fast-turn multiplier) compounding
# on top read as too jarring, even after the flat DOUBLE_ROPE_SPEED_
# MULTIPLIER slowdown above (that scales everything down uniformly, so it
# doesn't reduce how much faster/slower a burst feels relative to the calm
# turns). This only softens the swing, not the fair jump-cue window, since
# _effective_rope_speed_raw() already returns exactly rope_speed (zero
# deviation) during the visible red cue for every team.
const DOUBLE_ROPE_VARIANCE_DAMPING := 0.5


func _effective_rope_speed() -> float:
	var speed := _effective_rope_speed_raw()
	if rope_b_enabled:
		var deviation := speed - rope_speed
		speed = rope_speed + deviation * DOUBLE_ROPE_VARIANCE_DAMPING
		speed *= DOUBLE_ROPE_SPEED_MULTIPLIER
	return speed


func _effective_rope_speed_raw() -> float:
	if turner_team == TurnerTeam.STUDENT and comet_rush_active:
		return rope_speed if _is_jump_cue() else rope_speed * COMET_RUSH_MULTIPLIER
	if turner_team == TurnerTeam.SLEEPY:
		if sleepy_fast_turns_remaining > 0:
			return rope_speed if _is_jump_cue() else rope_speed * SLEEPY_FAST_MULTIPLIER
		return rope_speed * SLEEPY_SLOW_MULTIPLIER
	if turner_team == TurnerTeam.WIZARD:
		# A fresh random multiplier every turn (see _update_turner_team_and_pattern)
		# means the hidden-rope wait can't be timed by a steady rhythm — but the
		# visible red jump-cue window still runs at the fair, un-randomized speed.
		return rope_speed if _is_jump_cue() else rope_speed * wizard_speed_multiplier
	if turner_team == TurnerTeam.DUO:
		# Sleepy's sudden burst reuses sleepy's own fast multiplier (not the
		# athlete's) and overrides athlete's cycle for that single turn.
		# Otherwise athlete's own normal/burst cycle runs continuously with
		# its own multiplier, exactly like the standalone ATHLETE team.
		if duo_sleepy_awake:
			return rope_speed if _is_jump_cue() else rope_speed * SLEEPY_FAST_MULTIPLIER
		if duo_athlete_bursting:
			return rope_speed if _is_jump_cue() else rope_speed * balance.athlete_burst_multiplier
		return rope_speed
	if turner_team == TurnerTeam.WIZARD_PRANKSTER_DUO:
		# During prankster's triggered turn, the fake stop/reverse itself
		# (see _update_prankster_fake) manipulates rope_angle directly rather
		# than a speed multiplier — same as standalone PRANKSTER, which never
		# sets challenge_pattern either — so speed just stays flat here.
		if duo2_prankster_triggered:
			return rope_speed
		return rope_speed if _is_jump_cue() else rope_speed * wizard_speed_multiplier
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
	# Only the plain student turner has its baseline speed keep rising with
	# score. Every patterned team's difficulty — including the boss gauntlet
	# (90..AIR_CHALLENGE_START_SCORE) — comes entirely from its own turn
	# pattern (athlete/duo bursts, sleepy's slow/fast swings, prankster
	# fakes, wizard ghosting) — a rising baseline on top of that made both
	# sleepy and the boss stretch feel disproportionately fast at high
	# scores, since a fast-turn multiplier was compounding with an
	# ever-rising number instead of staying at a fixed, learnable pace.
	# Team assignment is random past score 10 (see
	# _update_turner_team_and_pattern), so this keys off the live team
	# instead of fixed score bands.
	# The boss gauntlet's locked-in basic pattern (110..AIR_CHALLENGE_START_
	# SCORE) reuses the STUDENT team id for "no gimmick, just the plain
	# rhythm" — but unlike the real early-game student (score < 10), it must
	# NOT ramp by the actual (now-huge) score, or the double-rope phase
	# becomes absurdly fast. Only the genuine early-game student ramps.
	if turner_team == TurnerTeam.STUDENT and turner_change_slot != BOSS_GAUNTLET_SLOT and turner_change_slot != SPACE_SLOT:
		return balance.speed_for_score(current_score)
	return balance.speed_for_score(TURNER_CHANGE_INTERVAL)


func _reset_turner_run() -> void:
	turner_team = TurnerTeam.STUDENT
	turner_change_slot = 0
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
	duo_normal_turns_remaining = 0
	duo_athlete_bursting = false
	duo_athlete_normal_turns_remaining = 0
	duo_athlete_burst_turns_remaining = 0
	duo_sleepy_awake = false
	duo2_normal_turns_remaining = 0
	duo2_prankster_triggered = false
	comet_rush_turns_remaining = COMET_RUSH_INTERVAL
	comet_rush_active = false
	used_double_jump = false
	boss_double_rope_intro_shown = false
	boss_double_rope_was_double_last_turn = false
	turner_transition_active = false
	turner_transition_time = 0.0
	turner_transition_phase = TurnerTransitionPhase.NONE
	departing_turner_team = TurnerTeam.STUDENT
	turner_transition_is_boss = false


func _start_turner_transition(previous_team := TurnerTeam.STUDENT, is_boss := false) -> void:
	turner_transition_active = true
	turner_transition_time = 0.0
	turner_transition_phase = TurnerTransitionPhase.TURNER_EXIT
	departing_turner_team = previous_team
	turner_transition_is_boss = is_boss
	accepting_input = false
	# Resume with the rope safely behind the player after GO! finishes.
	rope_angle = PI


func _turner_slot_for_score(current_score: int) -> int:
	# Slot number only matters for detecting "did it change" — the exact
	# value doesn't matter as long as it's monotonic and distinct per stretch.
	if current_score < TURNER_CHANGE_INTERVAL:
		return 0
	if current_score >= SPACE_SCORE_THRESHOLD:
		return SPACE_SLOT
	if current_score >= WIZARD_PRANKSTER_DUO_START_SCORE:
		# WIZARD_PRANKSTER_DUO_START_SCORE == DUO_STAGE_END_SCORE — this duo
		# picks up on the exact turn the athlete/sleepy duo ends, with no
		# plain-student gap turn in between.
		return WIZARD_PRANKSTER_DUO_SLOT
	if current_score >= AIR_CHALLENGE_START_SCORE:
		return DUO_STAGE_SLOT
	# Boss fight has two halves: BOSS_TURNER_SCORE_THRESHOLD (90) to
	# DOUBLE_ROPE_TEST_SCORE_THRESHOLD (110) still rerolls the normal
	# athlete/sleepy/prankster/wizard pattern at random, same as before the
	# boss even showed up — only the calm-king reskin is new. From 110
	# onward the pattern locks to the plain default (the angry king's phase,
	# double rope included), since stacking a second rope on top of a still-
	# randomizing pattern was too much at once.
	if current_score >= DOUBLE_ROPE_TEST_SCORE_THRESHOLD:
		return BOSS_GAUNTLET_SLOT
	if current_score < BOSS_TURNER_SCORE_THRESHOLD:
		return int((current_score - TURNER_CHANGE_INTERVAL) / TURNER_RANDOM_INTERVAL) + 1
	var pre_gauntlet_slot := int((BOSS_TURNER_SCORE_THRESHOLD - TURNER_CHANGE_INTERVAL) / TURNER_RANDOM_INTERVAL) + 1
	return pre_gauntlet_slot + int((current_score - BOSS_TURNER_SCORE_THRESHOLD) / BOSS_GAUNTLET_TURNER_INTERVAL) + 1


func _random_turner_team(exclude: TurnerTeam) -> TurnerTeam:
	# Picks the next rope-turner team at random, excluding whichever team is
	# currently active so the same team never plays two change-intervals in
	# a row.
	var choices: Array[TurnerTeam] = [TurnerTeam.ATHLETE, TurnerTeam.SLEEPY, TurnerTeam.PRANKSTER, TurnerTeam.WIZARD]
	choices.erase(exclude)
	return choices[randi() % choices.size()]


func _init_turner_team_state(team: TurnerTeam) -> void:
	sleepy_wake_warning_time = 0.0
	sleepy_fast_turns_remaining = 0
	prankster_fake_pending = false
	prankster_fake_mode = 0
	prankster_fake_time = 0.0
	match team:
		TurnerTeam.ATHLETE:
			athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
			athlete_burst_turns_remaining = 0
		TurnerTeam.SLEEPY:
			sleepy_slow_turns_remaining = _roll_sleepy_slow_turns()
		TurnerTeam.PRANKSTER:
			prankster_normal_turns_remaining = _roll_prankster_normal_turns()
		TurnerTeam.WIZARD:
			wizard_rope_hidden = false
		TurnerTeam.DUO:
			duo_normal_turns_remaining = _roll_duo_normal_turns()
			duo_athlete_bursting = false
			duo_athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
			duo_athlete_burst_turns_remaining = 0
			duo_sleepy_awake = false
		TurnerTeam.WIZARD_PRANKSTER_DUO:
			wizard_speed_multiplier = 1.0
			duo2_normal_turns_remaining = _roll_duo2_normal_turns()
			duo2_prankster_triggered = false


func _update_turner_team_and_pattern() -> bool:
	# The default (STUDENT) rope-turner holds until score 10, exactly as
	# before. Past that, a new team is rolled at random (never repeating the
	# just-active one) every TURNER_RANDOM_INTERVAL points, instead of the
	# old fixed STUDENT->ATHLETE->SLEEPY->PRANKSTER->WIZARD sequence.
	var target_slot := _turner_slot_for_score(score)
	if target_slot != turner_change_slot:
		turner_change_slot = target_slot
		challenge_pattern = 0
		if target_slot <= 0:
			turner_team = TurnerTeam.STUDENT
			return false
		var new_team := TurnerTeam.STUDENT if (target_slot == BOSS_GAUNTLET_SLOT or target_slot == SPACE_SLOT) else _random_turner_team(turner_team)
		if target_slot == DUO_STAGE_SLOT:
			new_team = TurnerTeam.DUO
		elif target_slot == WIZARD_PRANKSTER_DUO_SLOT:
			new_team = TurnerTeam.WIZARD_PRANKSTER_DUO
		turner_team = new_team
		_init_turner_team_state(new_team)
		if target_slot == SPACE_SLOT:
			# An overhead rope (reusing the boss gauntlet's own rope_b, see
			# _resolve_rope_b_crossing/SPACE_OVERHEAD_CLEAR_HEIGHT) runs for
			# the whole space zone, on top of the ground rope — neither one
			# pauses while airborne, so a long low-gravity float can
			# genuinely face more than one pass of either.
			rope_b_enabled = true
			rope_b_angle = fposmod(rope_angle + ROPE_B_PHASE_OFFSET, TAU)
		return true
	if turner_team == TurnerTeam.STUDENT:
		if turner_change_slot == SPACE_SLOT and score >= COMET_RUSH_SCORE_THRESHOLD:
			if comet_rush_active:
				comet_rush_active = false
				comet_rush_turns_remaining = COMET_RUSH_INTERVAL
			else:
				comet_rush_turns_remaining -= 1
				if comet_rush_turns_remaining <= 0:
					comet_rush_active = true
		return false
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
		# Re-rolled every turn so the wait before the rope reappears can't be
		# timed by a steady rhythm alone — only the actual jump-cue window
		# (checked in _effective_rope_speed) stays at the fair, visible speed.
		wizard_speed_multiplier = randf_range(balance.wizard_speed_min_multiplier, balance.wizard_speed_max_multiplier)
		return false
	if turner_team == TurnerTeam.DUO:
		# Sleepy's own single-turn burst always takes priority over whatever
		# the athlete half's cycle is doing that turn — it wakes up, bursts
		# once, then goes right back to sleep instead of athlete's own
		# multi-turn burst.
		if duo_sleepy_awake:
			duo_sleepy_awake = false
			duo_normal_turns_remaining = _roll_duo_normal_turns()
		elif sleepy_wake_warning_time <= 0.0:
			duo_normal_turns_remaining -= 1
			if duo_normal_turns_remaining <= 0:
				# Same 1-second "eyes open" warning as standalone SLEEPY (see
				# _update_sleepy_warning) before the burst actually starts —
				# without this, sleepy's duo-stage wake read as an instant
				# unfair speed spike with no telegraph at all.
				sleepy_wake_warning_time = SLEEPY_WAKE_WARNING_SECONDS
		# The athlete half keeps running its own normal-2/burst-2 cycle every
		# turn regardless of whether sleepy's burst is overriding this turn,
		# so athlete's characteristic pattern stays visible throughout the
		# duo stage instead of going flat.
		if duo_athlete_bursting:
			duo_athlete_burst_turns_remaining -= 1
			if duo_athlete_burst_turns_remaining <= 0:
				duo_athlete_bursting = false
				duo_athlete_normal_turns_remaining = ATHLETE_NORMAL_TURNS
		else:
			duo_athlete_normal_turns_remaining -= 1
			if duo_athlete_normal_turns_remaining <= 0:
				duo_athlete_bursting = true
				duo_athlete_burst_turns_remaining = ATHLETE_MAX_BURST_TURNS
		return false
	if turner_team == TurnerTeam.WIZARD_PRANKSTER_DUO:
		# The rope is invisible on every turn here (_wizard_rope_is_ghosted),
		# so there's no visibility toggle to run — only wizard's speed
		# variance re-rolls by default. When the countdown below hits zero,
		# this turn's pattern switches to prankster's stop/reverse fake
		# instead (see _update_prankster_fake, extended to also accept this
		# team) — duo2_prankster_triggered is cleared and the gap re-rolled
		# once that fake finishes, not here.
		duo2_normal_turns_remaining -= 1
		if duo2_normal_turns_remaining <= 0:
			duo2_prankster_triggered = true
			prankster_fake_pending = true
		else:
			wizard_speed_multiplier = randf_range(balance.wizard_speed_min_multiplier, balance.wizard_speed_max_multiplier)
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
	if sleepy_wake_warning_time <= 0.0:
		return
	if turner_team != TurnerTeam.SLEEPY and turner_team != TurnerTeam.DUO:
		return
	sleepy_wake_warning_time = maxf(0.0, sleepy_wake_warning_time - delta)
	if sleepy_wake_warning_time <= 0.0:
		if turner_team == TurnerTeam.DUO:
			duo_sleepy_awake = true
		else:
			sleepy_fast_turns_remaining = 1
		message = "지금!"
		message_color = Color("ff5c65")


func _roll_sleepy_slow_turns() -> int:
	return randi_range(SLEEPY_MIN_SLOW_TURNS, SLEEPY_MAX_SLOW_TURNS)


func _roll_prankster_normal_turns() -> int:
	return randi_range(PRANKSTER_MIN_NORMAL_TURNS, PRANKSTER_MAX_NORMAL_TURNS)


func _roll_duo_normal_turns() -> int:
	return randi_range(DUO_MIN_NORMAL_TURNS, DUO_MAX_NORMAL_TURNS)


func _roll_duo2_normal_turns() -> int:
	return randi_range(WIZARD_PRANKSTER_DUO_MIN_NORMAL_TURNS, WIZARD_PRANKSTER_DUO_MAX_NORMAL_TURNS)


func _update_prankster_fake(delta: float) -> bool:
	if turner_team != TurnerTeam.PRANKSTER and turner_team != TurnerTeam.WIZARD_PRANKSTER_DUO:
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
			if turner_team == TurnerTeam.WIZARD_PRANKSTER_DUO:
				duo2_prankster_triggered = false
				duo2_normal_turns_remaining = _roll_duo2_normal_turns()
			else:
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
	if active_team == TurnerTeam.DUO:
		# Left turner (faces_left == false — see the two _draw_turner call
		# sites) is always athlete; right (faces_left == true) is always
		# sleepy, awake only during the sudden-burst turn (see
		# _update_turner_team_and_pattern) and asleep otherwise.
		if faces_left:
			var duo_sleepy_visibly_awake := duo_sleepy_awake or sleepy_wake_warning_time > 0.0
			base_texture = sleepy_turner_awake_texture if duo_sleepy_visibly_awake else sleepy_turner_asleep_texture
			base_region = sleepy_turner_awake_used_region if duo_sleepy_visibly_awake else sleepy_turner_asleep_used_region
			mirror_texture = mirrored_sleepy_turner_awake_texture if duo_sleepy_visibly_awake else mirrored_sleepy_turner_asleep_texture
			mirror_region = mirrored_sleepy_turner_awake_used_region if duo_sleepy_visibly_awake else mirrored_sleepy_turner_asleep_used_region
		else:
			base_texture = athlete_turner_texture
			base_region = athlete_turner_used_region
			mirror_texture = mirrored_athlete_turner_texture
			mirror_region = mirrored_athlete_turner_used_region
	elif active_team == TurnerTeam.ATHLETE:
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
	elif active_team == TurnerTeam.WIZARD_PRANKSTER_DUO:
		# Left turner (faces_left == false) is always wizard; right
		# (faces_left == true) is always prankster — same fixed-side
		# convention as TurnerTeam.DUO. Unlike that duo's sleepy half, this
		# doesn't swap sprite/pose when prankster's pattern triggers — only
		# the rope itself changes (see _wizard_rope_is_ghosted).
		if faces_left:
			base_texture = prankster_turner_texture
			base_region = prankster_turner_used_region
			mirror_texture = mirrored_prankster_turner_texture
			mirror_region = mirrored_prankster_turner_used_region
		else:
			base_texture = wizard_turner_texture
			base_region = wizard_turner_used_region
			mirror_texture = mirrored_wizard_turner_texture
			mirror_region = mirrored_wizard_turner_used_region
	# From score 90 up to AIR_CHALLENGE_START_SCORE, the boss look takes over
	# the rope turners regardless of whichever team pattern is currently
	# active underneath. Past that there's no designed content yet, so it
	# reverts to whatever the plain (student) turner_texture resolved to
	# above instead of staying boss-skinned forever.
	var boss_active := score >= BOSS_TURNER_SCORE_THRESHOLD and score < AIR_CHALLENGE_START_SCORE
	# 90..110 is the calm king (pattern still randomizing underneath, same
	# rules as before the boss showed up); 110..AIR_CHALLENGE_START_SCORE
	# switches to the angry king once the pattern locks and the double rope
	# joins in — the angrier look sells the difficulty spike visually.
	var boss_is_angry := score >= DOUBLE_ROPE_TEST_SCORE_THRESHOLD
	# During the calm-king half (90..110), the sleepy pattern can still come
	# up in the random rotation — its wake-warning + fast-burst turn swaps in
	# a wide-eyed "shocked" king for the duration, then reverts to the calm
	# king once the burst is over (back to a normal sleeping/slow turn).
	var boss_is_shocked := not boss_is_angry and turner_team == TurnerTeam.SLEEPY and _sleepy_is_awake()
	if boss_active and boss_is_shocked and boss_turner_shocked_texture != null:
		base_texture = boss_turner_shocked_texture
		base_region = boss_turner_shocked_used_region
		mirror_texture = mirrored_boss_turner_shocked_texture
		mirror_region = mirrored_boss_turner_shocked_used_region
	elif boss_active and boss_is_angry and boss_turner_angry_texture != null:
		base_texture = boss_turner_angry_texture
		base_region = boss_turner_angry_used_region
		mirror_texture = mirrored_boss_turner_angry_texture
		mirror_region = mirrored_boss_turner_angry_used_region
	elif boss_active and boss_turner_texture != null:
		base_texture = boss_turner_texture
		base_region = boss_turner_used_region
		mirror_texture = mirrored_boss_turner_texture
		mirror_region = mirrored_boss_turner_used_region
	if base_texture != null and base_region.size.x > 0.0:
		var active_texture := mirror_texture if faces_left and mirror_texture != null else base_texture
		var active_region := mirror_region if faces_left and mirror_texture != null else base_region
		# Match the helper's height to the playable character and preserve the
		# original aspect ratio so the sprite never looks stretched sideways.
		var sprite_height := 165.0
		var is_boss := boss_active and (boss_turner_texture != null or boss_turner_angry_texture != null or boss_turner_shocked_texture != null)
		if is_boss:
			sprite_height *= 1.5
		var sprite_width := sprite_height * active_region.size.x / active_region.size.y
		var sprite_size := Vector2(sprite_width, sprite_height)
		_draw_shadow_ellipse(render_feet + Vector2(0, 13), Vector2(sprite_width * 0.34, 11), Color(0, 0, 0, 0.2))
		var sprite_top_y := render_feet.y - sprite_height
		if is_boss:
			# The rope's grip point (LEFT_HAND/RIGHT_HAND) is fixed, so a
			# feet-anchored sprite would drag the boss's hand away from it as
			# the sprite grows. Anchor by hand height instead — the same
			# on-screen y the hand sits at on the normal 165px sprite — so
			# only the body grows around a fixed hand.
			var base_hand_y := render_feet.y - (1.0 - TURNER_HAND_FRACTION_FROM_TOP) * 165.0
			sprite_top_y = base_hand_y - TURNER_HAND_FRACTION_FROM_TOP * sprite_height
		var sprite_rect := Rect2(Vector2(render_feet.x - sprite_width * 0.5, sprite_top_y), sprite_size)
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


func _draw_air_challenge_ropes() -> void:
	for index in range(AIR_ROPE_HEIGHTS.size()):
		var rope_y := PLAYER_GROUND_Y + float(AIR_ROPE_HEIGHTS[index])
		var cleared := index < air_challenge_next_rope
		var active := index == air_challenge_next_rope
		var core_color := Color("73f7b4") if cleared else (Color("ffd84a") if active else Color("8bc7e8"))
		var outline_color := Color("3b2119")
		var left_handle := Vector2(175.0, rope_y - 12.0)
		var right_handle := Vector2(545.0, rope_y - 12.0)
		draw_circle(left_handle, 13.0, outline_color)
		draw_circle(right_handle, 13.0, outline_color)
		draw_circle(left_handle, 8.0, core_color)
		draw_circle(right_handle, 8.0, core_color)
		var points := PackedVector2Array()
		for step in range(33):
			var t := float(step) / 32.0
			var x := lerpf(left_handle.x, right_handle.x, t)
			var y := lerpf(left_handle.y, right_handle.y, t) + 4.0 * t * (1.0 - t) * 30.0
			points.append(Vector2(x, y))
		draw_polyline(points, outline_color, 11.0, true)
		draw_polyline(points, core_color, 6.0, true)
		if active:
			draw_string(ThemeDB.fallback_font, Vector2(250.0, rope_y - 30.0), "TAP!", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 22, Color("3b2119"))


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
			if tutorial_active and tutorial_stage == 6:
				tutorial_stage = 7
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
	if tutorial_active and tutorial_stage == 7:
		tutorial_stage = 8


func _show_tutorial_nickname_prompt() -> void:
	tutorial_nickname_prompt_active = true
	if nickname_edit == null:
		nickname_edit = LineEdit.new()
		nickname_edit.max_length = RopeSaveManager.NICKNAME_MAX_LENGTH
		nickname_edit.add_theme_font_override("font", _ui_font())
		add_child(nickname_edit)
	nickname_edit.text = nickname
	nickname_edit.size = _design_to_screen_rect(TUTORIAL_NICKNAME_FIELD_RECT).size
	nickname_edit.position = _design_to_screen_rect(TUTORIAL_NICKNAME_FIELD_RECT).position
	nickname_edit.visible = true


func _confirm_tutorial_nickname() -> void:
	var new_nickname := nickname_edit.text.strip_edges()
	nickname = new_nickname if not new_nickname.is_empty() else RopeSaveManager.DEFAULT_NICKNAME
	_save_progress()
	nickname_edit.visible = false
	tutorial_nickname_prompt_active = false
	tutorial_active = false
	tutorial_stage = 0


func _open_settings_menu() -> void:
	settings_menu_open = true
	settings_message = ""
	data_reset_confirm_pending = false
	if nickname_edit == null:
		nickname_edit = LineEdit.new()
		nickname_edit.max_length = RopeSaveManager.NICKNAME_MAX_LENGTH
		nickname_edit.add_theme_font_override("font", _ui_font())
		add_child(nickname_edit)
	nickname_edit.text = nickname
	nickname_edit.size = _design_to_screen_rect(NICKNAME_FIELD_RECT).size
	nickname_edit.position = _design_to_screen_rect(NICKNAME_FIELD_RECT).position
	nickname_edit.visible = true
	if code_edit == null:
		code_edit = LineEdit.new()
		code_edit.add_theme_font_override("font", _ui_font())
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
	if tutorial_active and tutorial_stage == TUTORIAL_STAGE_COUNT:
		tutorial_active = false
		tutorial_stage = 0


func _open_ranking_menu() -> void:
	if tutorial_active and tutorial_stage == 9:
		tutorial_stage = 10
	ranking_menu_open = true
	ranking_scroll_offset = 0.0
	if nickname_edit != null:
		nickname_edit.visible = false
	if code_edit != null:
		code_edit.visible = false
	_fetch_ranking()


func _close_ranking_menu() -> void:
	ranking_menu_open = false
	ranking_scroll_dragging = false
	if ranking_list_viewport != null:
		ranking_list_viewport.visible = false
	# Only settings actually uses these fields — closing ranking should not
	# force them visible on the main menu if settings isn't open.
	if nickname_edit != null:
		nickname_edit.visible = settings_menu_open
	if code_edit != null:
		code_edit.visible = settings_menu_open


func _handle_ranking_menu_input(position: Vector2) -> void:
	if RANKING_PANEL_CLOSE_RECT.has_point(position):
		_close_ranking_menu()
		return
	if _handle_ranking_period_tap(position):
		return
	if RANKING_LIST_RECT.has_point(position):
		_begin_ranking_list_drag(position - RANKING_LIST_RECT.position)


func _ranking_scroll_max() -> float:
	var count := mini(ranking_entries.size(), LEADERBOARD_TOP_N)
	var content_height := float(count) * RANKING_ROW_HEIGHT
	return maxf(0.0, content_height - RANKING_LIST_RECT.size.y)


func _begin_ranking_list_drag(position: Vector2) -> void:
	ranking_scroll_dragging = true
	ranking_scroll_moved = false
	ranking_scroll_press_position = position
	ranking_scroll_press_offset = ranking_scroll_offset


func _update_ranking_list_drag(position: Vector2) -> void:
	var delta_y := position.y - ranking_scroll_press_position.y
	if absf(delta_y) > RANKING_SCROLL_DRAG_THRESHOLD:
		ranking_scroll_moved = true
	ranking_scroll_offset = clampf(ranking_scroll_press_offset - delta_y, 0.0, _ranking_scroll_max())
	if ranking_list_viewport != null:
		ranking_list_viewport.queue_redraw()


func _end_ranking_list_drag() -> void:
	ranking_scroll_dragging = false


func _ensure_ranking_list_viewport() -> void:
	if ranking_list_viewport == null:
		ranking_list_viewport = Control.new()
		ranking_list_viewport.clip_contents = true
		ranking_list_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ranking_list_viewport.draw.connect(_draw_ranking_list_contents)
		add_child(ranking_list_viewport)
	var screen_rect := _design_to_screen_rect(RANKING_LIST_RECT)
	ranking_list_viewport.position = screen_rect.position
	ranking_list_viewport.size = screen_rect.size
	ranking_list_viewport.visible = true
	ranking_list_viewport.queue_redraw()


func _draw_ranking_list_contents() -> void:
	var font := _ui_font()
	var canvas := ranking_list_viewport
	if ranking_loading:
		canvas.draw_string(font, Vector2(0.0, 40.0), "불러오는 중...", HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("a9bad8"))
		return
	if not ranking_error.is_empty():
		canvas.draw_string(font, Vector2(0.0, 40.0), ranking_error, HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("ff8b8b"))
		return
	if ranking_entries.is_empty():
		canvas.draw_string(font, Vector2(0.0, 40.0), "아직 기록이 없습니다", HORIZONTAL_ALIGNMENT_CENTER, RANKING_LIST_RECT.size.x, 22, Color("a9bad8"))
		return
	# Gold/silver/bronze accents for the top 3 make the leaderboard read at a
	# glance instead of every row looking identical.
	var rank_colors := [Color("ffd23f"), Color("d7dde6"), Color("e2a15c")]
	for index in range(mini(ranking_entries.size(), LEADERBOARD_TOP_N)):
		var entry: Dictionary = ranking_entries[index]
		var row_y := float(index) * RANKING_ROW_HEIGHT - ranking_scroll_offset
		if row_y + RANKING_ROW_HEIGHT < 0.0 or row_y > RANKING_LIST_RECT.size.y:
			continue
		var row := Rect2(0.0, row_y, RANKING_LIST_RECT.size.x, RANKING_ROW_HEIGHT - 8.0)
		_draw_row_background_on(canvas, row)
		var rank_color: Color = rank_colors[index] if index < rank_colors.size() else Color("a9bad8")
		canvas.draw_string(font, Vector2(row.position.x + 16.0, row.position.y + 38.0), "%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 60.0, 22, rank_color)
		canvas.draw_string(font, Vector2(row.position.x + 90.0, row.position.y + 38.0), str(entry.get("nickname", "")), HORIZONTAL_ALIGNMENT_LEFT, 280.0, 22, Color.WHITE)
		var value_field := "perfect_count" if ranking_period_filter == "perfect" else "score"
		canvas.draw_string(font, Vector2(row.end.x - 150.0, row.position.y + 38.0), str(int(entry.get(value_field, 0))), HORIZONTAL_ALIGNMENT_RIGHT, 130.0, 22, Color("73f7b4"))


func _open_attendance_menu() -> void:
	if tutorial_active and tutorial_stage == 10:
		# Hands off into stage 11's freeze banner (reward message + gold) —
		# see the tutorial_pause_active check in _draw_tutorial_layer.
		tutorial_stage = 11
		tutorial_pause_active = true
		coins += TUTORIAL_REWARD_GOLD
		_save_progress()
	attendance_menu_open = true
	if nickname_edit != null:
		nickname_edit.visible = false
	if code_edit != null:
		code_edit.visible = false


func _close_attendance_menu() -> void:
	attendance_menu_open = false
	# Only settings actually uses these fields — closing attendance should not
	# force them visible on the main menu if settings isn't open.
	if nickname_edit != null:
		nickname_edit.visible = settings_menu_open
	if code_edit != null:
		code_edit.visible = settings_menu_open


func _handle_attendance_menu_input(position: Vector2) -> void:
	if ATTENDANCE_PANEL_CLOSE_RECT.has_point(position):
		_close_attendance_menu()
		return
	if ATTENDANCE_CLAIM_BUTTON_RECT.has_point(position):
		_claim_attendance_reward()


func _current_date_string() -> String:
	return Time.get_date_string_from_system()


func _yesterday_date_string() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)


func _is_attendance_claimed_today() -> bool:
	return not attendance_last_claim_date.is_empty() and attendance_last_claim_date == _current_date_string()


func _attendance_display_day() -> int:
	# The 1-based day-in-cycle (1..7) to highlight in the reward track: the
	# day just claimed if today's claim is already done, otherwise the day
	# that would be claimed if the player taps the button right now. Wrapping
	# via modulo naturally resets the display to day 1 for a new cycle
	# without tracking cycle number separately.
	if _is_attendance_claimed_today():
		return (attendance_streak - 1) % ATTENDANCE_DAY_REWARDS.size() + 1
	var prospective_streak := attendance_streak + 1 if attendance_last_claim_date == _yesterday_date_string() else 1
	return (prospective_streak - 1) % ATTENDANCE_DAY_REWARDS.size() + 1


func _claim_attendance_reward() -> void:
	if _is_attendance_claimed_today():
		return
	attendance_streak = attendance_streak + 1 if attendance_last_claim_date == _yesterday_date_string() else 1
	attendance_last_claim_date = _current_date_string()
	var day_index := (attendance_streak - 1) % ATTENDANCE_DAY_REWARDS.size()
	gems += int(ATTENDANCE_DAY_REWARDS[day_index])
	_save_progress()


func _handle_ranking_period_tap(position: Vector2) -> bool:
	for period in RANKING_PERIOD_TAB_RECTS.keys():
		if (RANKING_PERIOD_TAB_RECTS[period] as Rect2).has_point(position):
			if ranking_period_filter != period:
				ranking_period_filter = period
				ranking_scroll_offset = 0.0
				_fetch_ranking()
			return true
	return false


func _ranking_period_cutoff_unix() -> float:
	# "주간" is a calendar-boundary window (this week since Monday 00:00
	# UTC), not a rolling N-day average — recomputed fresh on every fetch,
	# so no backend reset job is needed for the ranking to "roll over".
	# "perfect" is an all-time ranking (like "all") just ordered by a
	# different column, so it has no time cutoff either.
	var now_unix := Time.get_unix_time_from_system()
	if ranking_period_filter == "week":
		var weekday: int = Time.get_datetime_dict_from_unix_time(now_unix)["weekday"]
		var days_since_monday := (weekday + 6) % 7
		var day_dict := Time.get_datetime_dict_from_unix_time(now_unix - float(days_since_monday) * 86400.0)
		day_dict["hour"] = 0
		day_dict["minute"] = 0
		day_dict["second"] = 0
		return Time.get_unix_time_from_datetime_dict(day_dict)
	return -1.0


func _ranking_period_query_filter() -> String:
	var cutoff_unix := _ranking_period_cutoff_unix()
	if cutoff_unix < 0.0:
		return ""
	# get_datetime_string_from_unix_time's 2nd arg is use_space (date/time
	# separator), not UTC as its name might suggest — passing true here
	# produced "2026-08-24 00:00:00Z" with a literal, unencoded space
	# instead of ISO8601's "T" separator, and that space broke the Supabase
	# query URL (400 Bad Request). false gives the correct "T" separator.
	return "&created_at=gte.%sZ" % Time.get_datetime_string_from_unix_time(int(cutoff_unix), false)


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
	# The "perfect" tab ranks by a run's best perfect-jump count instead of
	# score — everything else about the fetch (limit, top-N) stays the same.
	var order_column := "perfect_count" if ranking_period_filter == "perfect" else "score"
	var select_fields := "nickname,perfect_count" if ranking_period_filter == "perfect" else "nickname,score"
	var url := "%s/rest/v1/leaderboard?select=%s&order=%s.desc&limit=%d%s" % [SUPABASE_URL, select_fields, order_column, LEADERBOARD_TOP_N, _ranking_period_query_filter()]
	var headers := ["apikey: %s" % SUPABASE_ANON_KEY, "Accept-Encoding: identity"]
	var error := leaderboard_fetch_request.request(url, headers)
	if error != OK:
		ranking_loading = false
		ranking_error = "랭킹을 불러올 수 없습니다 (요청 실패: %d)" % error
		_redraw_ranking()


func _redraw_ranking() -> void:
	queue_redraw()
	if ranking_list_viewport != null:
		ranking_list_viewport.queue_redraw()


func _on_ranking_fetched(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	ranking_loading = false
	if result != HTTPRequest.RESULT_SUCCESS:
		# result codes: see HTTPRequest.Result — e.g. CANT_CONNECT, CANT_RESOLVE,
		# TLS_HANDSHAKE_ERROR. Surfacing the number lets us tell a DNS/TLS
		# failure apart from a plain HTTP error without needing device logs.
		ranking_error = "랭킹을 불러올 수 없습니다 (연결 실패: %d)" % result
		_redraw_ranking()
		return
	if response_code < 200 or response_code >= 300:
		ranking_error = "랭킹을 불러올 수 없습니다 (서버 응답: %d)" % response_code
		_redraw_ranking()
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array:
		ranking_error = "랭킹을 불러올 수 없습니다 (응답 해석 실패)"
		_redraw_ranking()
		return
	ranking_entries = parsed as Array
	ranking_scroll_offset = 0.0
	_redraw_ranking()


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
	var payload := JSON.stringify({"nickname": nickname, "score": final_score, "perfect_count": perfect_count})
	leaderboard_submit_request.request(url, headers, HTTPClient.METHOD_POST, payload)


func _open_shop_url() -> void:
	# OS.shell_open() on the Web export goes through window.open(), which
	# browsers frequently popup-block once the click has passed through
	# Godot's input pipeline (it no longer counts as directly inside the
	# original DOM click handler by the time this runs) — reported as
	# silently doing nothing, exactly what happened here. Navigating the
	# current tab via JavaScriptBridge isn't subject to that popup-blocker
	# check, so use that on Web and keep shell_open (opens the system
	# browser) everywhere else, e.g. Android.
	if OS.get_name() == "Web" and JavaScriptBridge:
		JavaScriptBridge.eval("window.location.href = %s;" % JSON.stringify(SHOP_URL), true)
	else:
		OS.shell_open(SHOP_URL)


func _submit_redeem_code(code: String) -> void:
	# Calls the character-shop's redeem_code() RPC anonymously (see
	# SHOP_SUPABASE_URL above and supabase/schema.sql) — there's no login in
	# the game, so this is the entire "am I allowed to claim this" check:
	# the code itself, generated server-side and single-use.
	if redeem_code_request == null:
		redeem_code_request = HTTPRequest.new()
		add_child(redeem_code_request)
		redeem_code_request.accept_gzip = false
		redeem_code_request.request_completed.connect(_on_redeem_code_response)
	var url := "%s/rest/v1/rpc/redeem_code" % SHOP_SUPABASE_URL
	var headers := [
		"apikey: %s" % SHOP_SUPABASE_ANON_KEY,
		"Content-Type: application/json",
		"Accept-Encoding: identity",
	]
	var payload := JSON.stringify({"p_code": code})
	var error := redeem_code_request.request(url, headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		settings_message = "네트워크 오류로 코드 확인에 실패했습니다"
		return
	redeem_code_pending = true
	settings_message = "코드 확인 중..."


func _on_redeem_code_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	redeem_code_pending = false
	if result != OK:
		settings_message = "네트워크 오류로 코드 확인에 실패했습니다"
		return
	var text := body.get_string_from_utf8()
	if response_code == 200:
		# redeem_code() returns a bare integer (not a table), so PostgREST
		# hands back the raw JSON number as the whole body — e.g. "100".
		var parsed: Variant = JSON.parse_string(text)
		var amount := int(parsed) if parsed != null else 0
		if amount > 0:
			gems += amount
			_save_progress()
			settings_message = "%d루비 지급 완료!" % amount
		else:
			settings_message = "코드 확인에 실패했습니다"
	else:
		# redeem_code() raises on an invalid/already-used code, which
		# PostgREST surfaces as a 4xx with an error payload — the exact
		# wording isn't user-friendly, so show one fixed message instead of
		# whatever's in the response body.
		settings_message = "이미 사용됐거나 잘못된 코드입니다"


func _handle_settings_menu_input(position: Vector2) -> void:
	# Any tap that isn't the second confirming tap on the reset row cancels
	# a pending confirmation — stray taps elsewhere in the panel should
	# never leave the "one more tap wipes your data" state armed silently.
	if data_reset_confirm_pending and not DATA_RESET_ROW_RECT.has_point(position):
		data_reset_confirm_pending = false
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
		if tutorial_active and tutorial_stage == TUTORIAL_STAGE_COUNT:
			tutorial_active = false
			tutorial_stage = 0
		return
	if CODE_SUBMIT_BUTTON_RECT.has_point(position):
		var code := code_edit.text.strip_edges()
		if code.is_empty():
			settings_message = "코드를 입력해주세요"
			return
		if redeem_code_pending:
			return
		_submit_redeem_code(code)
		code_edit.text = ""
		return
	if DATA_RESET_ROW_RECT.has_point(position):
		if data_reset_confirm_pending:
			_reset_all_data()
		else:
			data_reset_confirm_pending = true
			settings_message = "정말 초기화할까요? 한 번 더 누르면 처음부터 다시 시작합니다"
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
	var font := _ui_font()
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


func _ui_font() -> Font:
	return ui_font if ui_font != null else ThemeDB.fallback_font


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
	var font := _ui_font()
	if game_state == GameState.TITLE:
		_draw_main_menu(font)
		if character_menu_open:
			_draw_character_menu(font)
		if settings_menu_open:
			_draw_settings_menu(font)
		if ranking_menu_open:
			_draw_ranking_menu(font)
		if attendance_menu_open:
			_draw_attendance_menu(font)
		return
	if gameplay_score_label_texture != null and gameplay_score_label_used_region.size.x > 0.0:
		var score_label_rect := Rect2(38.0, 34.0, 144.0, 62.0)
		draw_texture_rect_region(gameplay_score_label_texture, score_label_rect, gameplay_score_label_used_region)
	else:
		draw_string(font, Vector2(42, 82), "줄넘킹", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("91a4cc"))
	var score_cell_size := 10.0 + clampf(flash_time / 0.22, 0.0, 1.0) * 2.0
	_draw_image_number(str(score), Vector2(42.0, 101.0), score_cell_size * 7.0)
	if gameplay_best_label_texture != null and gameplay_best_label_used_region.size.x > 0.0:
		var best_label_rect := Rect2(434.0, 45.0, 115.0, 50.0)
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
		if character_reveal_active:
			_draw_character_unlock_reveal(font)


func _game_over_panel_rect() -> Rect2:
	# Keep panel_frame.png's real (tall/portrait) aspect ratio instead of
	# stretching it to an arbitrary box — width drives the size, height
	# follows the source art so the frame never looks squashed.
	var panel_width := 530.0
	var panel_height := panel_width
	if game_over_panel_used_region.size.x > 0.0:
		panel_height = panel_width * game_over_panel_used_region.size.y / game_over_panel_used_region.size.x
	return Rect2((DESIGN_SIZE.x - panel_width) * 0.5, 300.0, panel_width, panel_height)


func _game_over_revive_rect() -> Rect2:
	var panel := _game_over_panel_rect()
	var retry_rect := _game_over_retry_rect()
	return Rect2(Vector2(panel.position.x + 75.0, retry_rect.position.y - 68.0), Vector2(380.0, 58.0))


func _game_over_retry_rect() -> Rect2:
	var panel := _game_over_panel_rect()
	# Anchor the retry button to the panel's actual bottom edge. Scaling the old
	# y-offset independently placed the 58px button below the ornate frame.
	return Rect2(Vector2(panel.position.x + 75.0, panel.end.y - 74.0), Vector2(380.0, 58.0))


func _can_revive() -> bool:
	return game_state == GameState.GAME_OVER and gems >= REVIVE_GEM_COST


func _revive_with_gem() -> void:
	if not _can_revive():
		return
	gems -= REVIVE_GEM_COST
	revived_this_run = true
	game_state = GameState.PLAYING
	is_jumping = false
	jump_height = 0.0
	jump_velocity = 0.0
	jump_animation_time = 0.0
	jump_started_in_cue = false
	hit_reveal_time = 0.0
	accepting_input = true
	# Drop back to a single plain rope on revive — resuming straight into a
	# double-rope boss beat or a mid-transition state the player never saw
	# coming would just be an unfair second death. Re-showing the boss
	# double-rope intro turn (if that stage is still active) gives the same
	# one-turn grace period a fresh entry into it would.
	rope_b_enabled = false
	boss_double_rope_intro_shown = false
	boss_double_rope_was_double_last_turn = false
	rope_angle = PI
	turner_transition_active = false
	turner_transition_phase = TurnerTransitionPhase.NONE
	message = "부활!  다시 도전하세요!"
	message_color = Color("73f7b4")
	flash_time = 0.3
	_save_progress()


func _draw_game_over_panel(font: Font) -> void:
	var panel := _game_over_panel_rect()
	var panel_height := panel.size.y
	if game_over_panel_texture != null and game_over_panel_used_region.size.x > 0.0:
		draw_texture_rect_region(game_over_panel_texture, panel, game_over_panel_used_region)
	else:
		draw_rect(panel, Color(0.035, 0.055, 0.10, 0.94), true)
		draw_rect(panel, Color("fff0a6"), false, 7.0)
	draw_circle(GAME_OVER_CLOSE_RECT.get_center(), 39.0, Color("ff4d67"))
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(-13.5, -13.5), GAME_OVER_CLOSE_RECT.get_center() + Vector2(13.5, 13.5), Color.WHITE, 7.5, true)
	draw_line(GAME_OVER_CLOSE_RECT.get_center() + Vector2(13.5, -13.5), GAME_OVER_CLOSE_RECT.get_center() + Vector2(-13.5, 13.5), Color.WHITE, 7.5, true)
	# Content offsets are scaled up from the original 430-tall panel's layout
	# so they spread through the taller frame instead of clumping at the top.
	var content_scale := panel_height / 430.0
	draw_string(font, Vector2(panel.position.x, panel.position.y + 116.0 * content_scale), "도전 종료!", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 40, Color("ff6b6b"))
	draw_string(font, Vector2(panel.position.x, panel.position.y + 151.0 * content_scale), "이번 기록", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 22, Color("fff0a6"))
	_draw_image_number(str(score), Vector2(panel.position.x + 65.0, panel.position.y + 163.0 * content_scale), 48.0, panel.size.x - 130.0, HORIZONTAL_ALIGNMENT_CENTER)

	var best_rect := Rect2(panel.position + Vector2(60.0, 230.0 * content_scale), Vector2(250.0, 54.0))
	var coin_rect := Rect2(panel.position + Vector2(320.0, 230.0 * content_scale), Vector2(150.0, 54.0))
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
	draw_string(font, Vector2(panel.position.x, panel.position.y + 318.0 * content_scale), record_message, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 23, Color("73f7b4"))

	var revive_rect := _game_over_revive_rect()
	var revive_possible := _can_revive()
	draw_rect(revive_rect, Color("35d0ff") if revive_possible else Color("2a3346"), true)
	draw_rect(revive_rect, Color("fff0a6") if revive_possible else Color(1.0, 1.0, 1.0, 0.2), false, 5.0)
	var revive_label := "보석 %d개로 부활!" % REVIVE_GEM_COST if revive_possible else "보석이 부족해요 (%d개 필요)" % REVIVE_GEM_COST
	draw_string(font, Vector2(revive_rect.position.x, revive_rect.position.y + 39.0), revive_label, HORIZONTAL_ALIGNMENT_CENTER, revive_rect.size.x, 24, Color("102030") if revive_possible else Color("6b7690"))

	var retry_rect := _game_over_retry_rect()
	draw_rect(retry_rect, Color("ffd23f"), true)
	draw_rect(retry_rect, Color("fff0a6"), false, 5.0)
	draw_string(font, Vector2(retry_rect.position.x, retry_rect.position.y + 39.0), "터치해서 다시 도전!", HORIZONTAL_ALIGNMENT_CENTER, retry_rect.size.x, 24, Color("633913"))


func _draw_character_unlock_reveal(font: Font) -> void:
	# Fullscreen "짜잔" card shown once per newly-crossed unlock_score
	# threshold, on top of the normal game-over panel — tap advances to the
	# next unlocked character (if several thresholds were crossed in one
	# run) or dismisses back to the plain game-over panel.
	if character_reveal_index >= newly_unlocked_this_run.size():
		return
	var character_id: String = newly_unlocked_this_run[character_reveal_index]
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.03, 0.04, 0.08, 0.88), true)
	# Pop-in scale eases from slightly-big down to 1.0 instead of growing
	# from zero, so the card reads as "landing" rather than inflating.
	var pop_progress := clampf(character_reveal_time / 0.28, 0.0, 1.0)
	var eased_pop := 1.0 - pow(1.0 - pop_progress, 3.0)
	var pop_scale := lerpf(1.35, 1.0, eased_pop)
	var glow_pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)

	var card_center := DESIGN_SIZE * 0.5
	var card_size := Vector2(460.0, 560.0)
	var card_rect := Rect2(card_center - card_size * 0.5, card_size)
	for i in range(4):
		var grow_amount := 6.0 + float(i) * 10.0
		var alpha := (0.30 - float(i) * 0.06) * glow_pulse
		draw_rect(card_rect.grow(grow_amount * pop_scale), Color(1.0, 0.82, 0.32, alpha), true)
	draw_rect(card_rect, Color(0.09, 0.07, 0.04, 0.96), true)
	draw_rect(card_rect, Color("ffd23f"), false, 6.0)

	draw_string(font, Vector2(card_rect.position.x, card_rect.position.y + 54.0), "NEW 캐릭터 해금!", HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x, 30, Color("ffd23f"))

	var preview_rect := Rect2(card_rect.position + Vector2(30.0, 90.0), Vector2(card_rect.size.x - 60.0, 300.0))
	var texture := _character_preview_texture(character_id)
	if texture != null:
		var source: Rect2 = character_preview_regions.get(character_id, Rect2(Vector2.ZERO, texture.get_size()))
		var scale := minf(preview_rect.size.x / source.size.x, preview_rect.size.y / source.size.y)
		scale *= float(character_scale_multipliers.get(character_id, 1.0)) * pop_scale
		var size := source.size * scale
		var position := Vector2(preview_rect.get_center().x - size.x * 0.5, preview_rect.end.y - size.y)
		draw_texture_rect_region(texture, Rect2(position, size), source)

	var name: String = character_names.get(character_id, character_id)
	var required_score := int(character_unlock_scores.get(character_id, 0))
	draw_string(font, Vector2(card_rect.position.x, card_rect.end.y - 150.0), name, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x, 32, Color.WHITE)
	draw_string(font, Vector2(card_rect.position.x, card_rect.end.y - 112.0), "기록 %d회 달성 보상" % required_score, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x, 22, Color("8dd6ff"))

	var hint := "화면을 눌러 계속" if character_reveal_index >= newly_unlocked_this_run.size() - 1 else "화면을 눌러 다음 캐릭터"
	var hint_alpha := 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.006)
	draw_string(font, Vector2(card_rect.position.x, card_rect.end.y - 40.0), hint, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x, 20, Color(1.0, 1.0, 1.0, hint_alpha))


func _draw_tutorial_layer() -> void:
	# Dispatches every visual for the guided first-run tour — see
	# TUTORIAL_STAGE_COUNT's comment for the overall design. Called
	# unconditionally at the end of _draw() (not from inside _draw_hud's
	# branchy TITLE/gameplay split) because stages span both: gameplay
	# freezes (1,2,4), a gameplay hint (3), menu-open hints/arrows
	# (6,7,12), and title-screen arrows (5,8,9,10). Stage 11's freeze can
	# happen with attendance_menu_open still true underneath it.
	if not tutorial_active:
		return
	var font := _ui_font()
	match tutorial_stage:
		1:
			if tutorial_pause_active:
				_draw_tutorial_pause_banner(font, "화면을 터치하여 시작하세요!")
		2:
			if tutorial_pause_active:
				_draw_tutorial_pause_banner(font, "줄이 빨간색이 됐어요!\n화면을 터치하여 점프하세요!")
		3:
			_draw_tutorial_hint_banner(font, "성공해서 점수 10까지 도달해보세요!")
		4:
			if tutorial_pause_active:
				_draw_tutorial_pause_banner(font, "줄 돌리는 애들마다 돌리는 패턴이 다르니 주의하세요!")
		5:
			if game_state == GameState.TITLE and not character_menu_open:
				_draw_tutorial_arrow_pointer(CHARACTER_BUTTON_RECT, "캐릭터를 눌러 새로 해금된 캐릭터를 확인해보세요!")
		6:
			if character_menu_open:
				_draw_tutorial_hint_banner(font, "잠금 해제된 새 캐릭터를 눌러보세요!")
		7:
			if character_menu_open:
				_draw_tutorial_arrow_pointer(CHARACTER_PANEL_CLOSE_RECT, "X를 눌러 나가보세요!")
		8:
			if game_state == GameState.TITLE and not character_menu_open and not ranking_menu_open and not attendance_menu_open and not settings_menu_open:
				_draw_tutorial_arrow_pointer(COOP_BUTTON_RECT, "협동 모드도 해봐요!")
		9:
			if game_state == GameState.TITLE and not character_menu_open and not ranking_menu_open and not attendance_menu_open and not settings_menu_open:
				_draw_tutorial_arrow_pointer(RANKING_MAIN_BUTTON_RECT, "랭킹도 확인해보세요!")
		10:
			if game_state == GameState.TITLE and not character_menu_open and not ranking_menu_open and not attendance_menu_open and not settings_menu_open:
				_draw_tutorial_arrow_pointer(ATTENDANCE_MAIN_BUTTON_RECT, "출석 체크도 받아보세요!")
		11:
			if tutorial_pause_active:
				_draw_tutorial_pause_banner(font, "열심히 해서 랭킹에 들어보세요!\n(보상으로 %d골드 지급!)" % TUTORIAL_REWARD_GOLD)
		12:
			if tutorial_nickname_prompt_active:
				_draw_tutorial_nickname_panel(font)


func _draw_tutorial_pause_banner(font: Font, text: String) -> void:
	# Full freeze (see _process's tutorial_pause_active early-return) — the
	# real character/rope/HUD stay visible behind a translucent band so the
	# explanation reads like a pause on the real game, not a screen swap.
	var band := Rect2(0.0, 520.0, DESIGN_SIZE.x, 220.0)
	draw_rect(band, Color(0.03, 0.04, 0.08, 0.82), true)
	draw_rect(Rect2(band.position.x, band.position.y, band.size.x, 4.0), Color("ffd23f"))
	draw_rect(Rect2(band.position.x, band.end.y - 4.0, band.size.x, 4.0), Color("ffd23f"))

	draw_multiline_string(font, Vector2(40.0, band.position.y + 76.0), text, HORIZONTAL_ALIGNMENT_CENTER, band.size.x - 80.0, 26, -1, Color.WHITE)
	var hint_alpha := 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.006)
	draw_string(font, Vector2(band.position.x, band.end.y - 34.0), "화면을 터치해서 계속", HORIZONTAL_ALIGNMENT_CENTER, band.size.x, 20, Color(1.0, 0.85, 0.35, hint_alpha))


func _draw_tutorial_hint_banner(font: Font, text: String) -> void:
	# Small non-blocking reminder — gameplay/menus keep running underneath;
	# it just disappears on its own once the stage advances.
	var band := Rect2(20.0, 195.0, DESIGN_SIZE.x - 40.0, 60.0)
	draw_rect(band, Color(0.03, 0.04, 0.08, 0.78), true)
	draw_rect(band, Color("ffd23f"), false, 3.0)
	draw_multiline_string(font, Vector2(band.position.x + 10.0, band.position.y + 38.0), text, HORIZONTAL_ALIGNMENT_CENTER, band.size.x - 20.0, 22, -1, Color.WHITE)


func _draw_tutorial_arrow_pointer(target: Rect2, text: String) -> void:
	# Points at whatever the next tutorial tap should land on. Targets near
	# the top of the screen (the character panel's X button) get the arrow
	# below them pointing up, since an arrow above would fall off-screen;
	# everything else gets the usual arrow-above-pointing-down.
	var font := _ui_font()
	var bounce := sin(Time.get_ticks_msec() * 0.006) * 10.0
	var points_down := target.position.y >= 220.0
	var tip_y := target.position.y - 14.0 - bounce if points_down else target.end.y + 14.0 + bounce
	var base_y := tip_y - 34.0 if points_down else tip_y + 34.0
	var target_center_x := target.get_center().x

	var points := PackedVector2Array()
	points.append(Vector2(target_center_x, tip_y))
	points.append(Vector2(target_center_x - 22.0, base_y))
	points.append(Vector2(target_center_x + 22.0, base_y))
	draw_colored_polygon(points, Color("ffd23f"))
	draw_rect(target.grow(6.0), Color("ffd23f"), false, 4.0)

	var text_y := base_y - 30.0 if points_down else base_y + 60.0
	var band := Rect2(20.0, text_y - 34.0, DESIGN_SIZE.x - 40.0, 56.0)
	draw_rect(band, Color(0.03, 0.04, 0.08, 0.82), true)
	draw_multiline_string(font, Vector2(band.position.x + 10.0, text_y), text, HORIZONTAL_ALIGNMENT_CENTER, band.size.x - 20.0, 21, -1, Color.WHITE)


func _draw_tutorial_nickname_panel(font: Font) -> void:
	# Tutorial stage 12's dedicated last step — a small standalone popup
	# (not the full settings panel) so it never competes for the screen
	# with whatever menu the previous stage had open.
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.03, 0.04, 0.08, 0.82), true)
	draw_rect(TUTORIAL_NICKNAME_PANEL_RECT, Color(0.09, 0.07, 0.04, 0.97), true)
	draw_rect(TUTORIAL_NICKNAME_PANEL_RECT, Color("ffd23f"), false, 5.0)
	draw_string(font, Vector2(TUTORIAL_NICKNAME_PANEL_RECT.position.x, TUTORIAL_NICKNAME_PANEL_RECT.position.y + 70.0), "마지막이에요!", HORIZONTAL_ALIGNMENT_CENTER, TUTORIAL_NICKNAME_PANEL_RECT.size.x, 28, Color("ffd23f"))
	draw_multiline_string(font, Vector2(TUTORIAL_NICKNAME_PANEL_RECT.position.x + 20.0, TUTORIAL_NICKNAME_PANEL_RECT.position.y + 120.0), "닉네임을 자유롭게 정해보세요!", HORIZONTAL_ALIGNMENT_CENTER, TUTORIAL_NICKNAME_PANEL_RECT.size.x - 40.0, 24, -1, Color.WHITE)
	_draw_row_background(TUTORIAL_NICKNAME_FIELD_RECT)
	draw_rect(TUTORIAL_NICKNAME_SAVE_RECT, Color("3b2119"), true)
	draw_rect(TUTORIAL_NICKNAME_SAVE_RECT, Color("ffd23f"), false, 3.0)
	draw_string(font, Vector2(TUTORIAL_NICKNAME_SAVE_RECT.position.x, TUTORIAL_NICKNAME_SAVE_RECT.position.y + 46.0), "저장", HORIZONTAL_ALIGNMENT_CENTER, TUTORIAL_NICKNAME_SAVE_RECT.size.x, 24, Color("ffd23f"))


func _draw_main_menu(font: Font) -> void:
	_draw_resource_counter(font, Rect2(40.0, 22.0, 300.0, 62.0), coin_icon_texture, coin_icon_used_region, coins, COIN_ICON_OFFSET)
	_draw_resource_counter(font, Rect2(380.0, 22.0, 300.0, 62.0), ruby_icon_texture, ruby_icon_used_region, gems, RUBY_ICON_OFFSET)

	_draw_main_menu_title(font)
	if hud_title_logo_texture == null and best_score_frame_texture != null and best_score_frame_used_region.size.x > 0.0:
		# title_logo.png now bakes the "최고기록" plaque into the same image as
		# the title (see MAIN_MENU_TITLE_RECT) — this separate frame is only a
		# fallback for if that combined asset fails to load.
		var best_rect := Rect2(235.0, 306.0, 250.0, 64.0)
		draw_texture_rect_region(best_score_frame_texture, best_rect, best_score_frame_used_region)
	elif hud_title_logo_texture == null:
		draw_string(font, Vector2(278.0, 347.0), "최고 기록", HORIZONTAL_ALIGNMENT_CENTER, 105.0, 21, Color("fff0a6"))
	var best_number_rect := MAIN_MENU_BEST_SCORE_NUMBER_RECT
	_draw_image_number(str(best_score), best_number_rect.position, best_number_rect.size.y, best_number_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)

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
	if not tutorial_seen:
		# The guided first-run tour used to only reveal itself after a
		# player's first (otherwise unexplained) blind tap — now the very
		# first thing shown on a fresh install is this explicit prompt,
		# and that tap itself starts the tour (see _start_tutorial_run).
		draw_string(font, Vector2(0.0, 1020.0), "화면을 터치하여 시작하세요!", HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 26, Color(1.0, 0.85, 0.35, prompt_alpha))

	_draw_menu_asset_or_fallback(character_button_texture, character_button_used_region, font, CHARACTER_BUTTON_RECT, "CHARACTER", "캐릭터", Color("ef8f6b"))
	_draw_menu_asset_or_fallback(coop_button_texture, coop_button_used_region, font, COOP_BUTTON_RECT, "CO-OP", "협동 모드", Color("65b7f3"))
	_draw_menu_asset_or_fallback(settings_button_texture, settings_button_used_region, font, SETTINGS_BUTTON_RECT, "SETTINGS", "설정", Color("9b8bea"))
	_draw_test_start_button(font)
	_draw_ranking_main_button(font)
	_draw_attendance_main_button(font)
	_draw_shop_main_button(font)
	if not menu_notice.is_empty():
		draw_string(font, Vector2(0, 925), menu_notice, HORIZONTAL_ALIGNMENT_CENTER, DESIGN_SIZE.x, 22, Color("ffd166"))


func _draw_test_start_button(font: Font) -> void:
	draw_rect(TEST_START_130_RECT, Color("3b2119"), true)
	draw_rect(TEST_START_130_RECT.grow(-5.0), Color("73f7b4"), true)
	draw_rect(TEST_START_130_RECT.grow(-9.0), Color("24705b"), false, 3.0)
	draw_string(font, Vector2(TEST_START_130_RECT.position.x, TEST_START_130_RECT.position.y + 31.0), "DUO TEST", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_130_RECT.size.x, 16, Color("245446"))
	draw_string(font, Vector2(TEST_START_130_RECT.position.x, TEST_START_130_RECT.position.y + 62.0), "130 START", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_130_RECT.size.x, 23, Color("173f35"))
	draw_rect(TEST_START_170_RECT, Color("3b2119"), true)
	draw_rect(TEST_START_170_RECT.grow(-5.0), Color("ffd23f"), true)
	draw_rect(TEST_START_170_RECT.grow(-9.0), Color("7a4317"), false, 3.0)
	draw_string(font, Vector2(TEST_START_170_RECT.position.x, TEST_START_170_RECT.position.y + 31.0), "SPACE TEST", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_170_RECT.size.x, 16, Color("633913"))
	draw_string(font, Vector2(TEST_START_170_RECT.position.x, TEST_START_170_RECT.position.y + 62.0), "170 START", HORIZONTAL_ALIGNMENT_CENTER, TEST_START_170_RECT.size.x, 23, Color("3b2119"))


func _draw_shop_main_button(font: Font) -> void:
	if shop_button_texture != null and shop_button_used_region.size.x > 0.0:
		# Same aspect-preserving fit as the ranking/attendance buttons — fit
		# by height and center horizontally instead of stretching sideways.
		var icon_aspect := shop_button_used_region.size.x / shop_button_used_region.size.y
		var icon_size := Vector2(SHOP_BUTTON_RECT.size.y * icon_aspect, SHOP_BUTTON_RECT.size.y)
		if icon_size.x > SHOP_BUTTON_RECT.size.x:
			icon_size = Vector2(SHOP_BUTTON_RECT.size.x, SHOP_BUTTON_RECT.size.x / icon_aspect)
		var icon_rect := Rect2(SHOP_BUTTON_RECT.position + (SHOP_BUTTON_RECT.size - icon_size) * 0.5, icon_size)
		draw_texture_rect_region(shop_button_texture, icon_rect, shop_button_used_region)
		return
	draw_rect(SHOP_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(SHOP_BUTTON_RECT.grow(-5.0), Color("ff9ecf"), true)
	draw_rect(SHOP_BUTTON_RECT.grow(-9.0), Color("8a2e58"), false, 3.0)
	draw_string(font, Vector2(SHOP_BUTTON_RECT.position.x, SHOP_BUTTON_RECT.position.y + 31.0), "상점", HORIZONTAL_ALIGNMENT_CENTER, SHOP_BUTTON_RECT.size.x, 18, Color("4a1633"))
	draw_string(font, Vector2(SHOP_BUTTON_RECT.position.x, SHOP_BUTTON_RECT.position.y + 62.0), "루비 충전", HORIZONTAL_ALIGNMENT_CENTER, SHOP_BUTTON_RECT.size.x, 22, Color("4a1633"))


func _draw_ranking_main_button(font: Font) -> void:
	if ranking_button_texture != null and ranking_button_used_region.size.x > 0.0:
		# The source art is a square icon; stretching it to the wide button
		# rect distorts it. Fit it by height and center it horizontally so it
		# keeps its own aspect ratio instead of being squashed sideways.
		var icon_aspect := ranking_button_used_region.size.x / ranking_button_used_region.size.y
		var icon_size := Vector2(RANKING_MAIN_BUTTON_RECT.size.y * icon_aspect, RANKING_MAIN_BUTTON_RECT.size.y)
		if icon_size.x > RANKING_MAIN_BUTTON_RECT.size.x:
			icon_size = Vector2(RANKING_MAIN_BUTTON_RECT.size.x, RANKING_MAIN_BUTTON_RECT.size.x / icon_aspect)
		var icon_rect := Rect2(RANKING_MAIN_BUTTON_RECT.position + (RANKING_MAIN_BUTTON_RECT.size - icon_size) * 0.5, icon_size)
		draw_texture_rect_region(ranking_button_texture, icon_rect, ranking_button_used_region)
		return
	draw_rect(RANKING_MAIN_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(RANKING_MAIN_BUTTON_RECT.grow(-5.0), Color("ffd23f"), true)
	draw_rect(RANKING_MAIN_BUTTON_RECT.grow(-9.0), Color("7a4317"), false, 3.0)
	draw_string(font, Vector2(RANKING_MAIN_BUTTON_RECT.position.x, RANKING_MAIN_BUTTON_RECT.position.y + 31.0), "랭킹", HORIZONTAL_ALIGNMENT_CENTER, RANKING_MAIN_BUTTON_RECT.size.x, 18, Color("633913"))
	draw_string(font, Vector2(RANKING_MAIN_BUTTON_RECT.position.x, RANKING_MAIN_BUTTON_RECT.position.y + 62.0), "보기", HORIZONTAL_ALIGNMENT_CENTER, RANKING_MAIN_BUTTON_RECT.size.x, 25, Color("3b2119"))


func _draw_attendance_main_button(font: Font) -> void:
	var claimable := not _is_attendance_claimed_today()
	if attendance_button_texture != null and attendance_button_used_region.size.x > 0.0:
		# Same aspect-preserving fit as the ranking button — the source art
		# is a square icon and the button slot is wide, so fit by height and
		# center horizontally instead of stretching it sideways.
		var icon_aspect := attendance_button_used_region.size.x / attendance_button_used_region.size.y
		var icon_size := Vector2(ATTENDANCE_MAIN_BUTTON_RECT.size.y * icon_aspect, ATTENDANCE_MAIN_BUTTON_RECT.size.y)
		if icon_size.x > ATTENDANCE_MAIN_BUTTON_RECT.size.x:
			icon_size = Vector2(ATTENDANCE_MAIN_BUTTON_RECT.size.x, ATTENDANCE_MAIN_BUTTON_RECT.size.x / icon_aspect)
		var icon_rect := Rect2(ATTENDANCE_MAIN_BUTTON_RECT.position + (ATTENDANCE_MAIN_BUTTON_RECT.size - icon_size) * 0.5, icon_size)
		draw_texture_rect_region(attendance_button_texture, icon_rect, attendance_button_used_region)
	else:
		draw_rect(ATTENDANCE_MAIN_BUTTON_RECT, Color("3b2119"), true)
		draw_rect(ATTENDANCE_MAIN_BUTTON_RECT.grow(-5.0), Color("73f7b4") if claimable else Color("ffd23f"), true)
		draw_rect(ATTENDANCE_MAIN_BUTTON_RECT.grow(-9.0), Color("7a4317"), false, 3.0)
		draw_string(font, Vector2(ATTENDANCE_MAIN_BUTTON_RECT.position.x, ATTENDANCE_MAIN_BUTTON_RECT.position.y + 31.0), "출석", HORIZONTAL_ALIGNMENT_CENTER, ATTENDANCE_MAIN_BUTTON_RECT.size.x, 18, Color("3b2119"))
		draw_string(font, Vector2(ATTENDANCE_MAIN_BUTTON_RECT.position.x, ATTENDANCE_MAIN_BUTTON_RECT.position.y + 62.0), "받기!" if claimable else "완료", HORIZONTAL_ALIGNMENT_CENTER, ATTENDANCE_MAIN_BUTTON_RECT.size.x, 25, Color("3b2119"))
	if claimable:
		var badge_center := ATTENDANCE_MAIN_BUTTON_RECT.position + Vector2(ATTENDANCE_MAIN_BUTTON_RECT.size.x - 14.0, 14.0)
		draw_circle(badge_center, 12.0, Color("ff4d67"))
		draw_string(font, badge_center - Vector2(6.0, -7.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 18, Color.WHITE)


func _draw_attendance_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	_draw_panel_frame(ATTENDANCE_PANEL_RECT)
	draw_string(font, Vector2(ATTENDANCE_PANEL_RECT.position.x, 270.0), "출석 보상", HORIZONTAL_ALIGNMENT_CENTER, ATTENDANCE_PANEL_RECT.size.x, 38, Color.WHITE)
	_draw_close_button(ATTENDANCE_PANEL_CLOSE_RECT)

	var streak_text := "연속 출석 %d일째" % attendance_streak if attendance_streak > 0 else "첫 출석을 기다리고 있어요"
	draw_string(font, Vector2(ATTENDANCE_PANEL_RECT.position.x, 320.0), streak_text, HORIZONTAL_ALIGNMENT_CENTER, ATTENDANCE_PANEL_RECT.size.x, 24, Color("a9bad8"))

	var display_day := _attendance_display_day()
	var day_count := ATTENDANCE_DAY_REWARDS.size()

	if attendance_track_bg_texture != null and attendance_track_bg_used_region.size.x > 0.0:
		var track_rect := Rect2(ATTENDANCE_PANEL_RECT.position.x + 40.0, 395.0, ATTENDANCE_PANEL_RECT.size.x - 80.0, 0.0)
		track_rect.size.y = track_rect.size.x * (attendance_track_bg_used_region.size.y / attendance_track_bg_used_region.size.x)
		draw_texture_rect_region(attendance_track_bg_texture, track_rect, attendance_track_bg_used_region)
		var icon_diameter := track_rect.size.x * 0.088
		for i in range(day_count):
			var day_number := i + 1
			var done_today := day_number == display_day and _is_attendance_claimed_today()
			var already_passed := day_number < display_day
			var is_today := day_number == display_day and not _is_attendance_claimed_today()
			var slot_center := track_rect.position + Vector2(
				ATTENDANCE_TRACK_SLOT_X_FRACTIONS[i] * track_rect.size.x,
				ATTENDANCE_TRACK_SLOT_Y_FRACTION * track_rect.size.y
			)
			var is_last_day := day_number == day_count
			var icon_texture := attendance_ruby_icon_texture
			var icon_region := attendance_ruby_icon_used_region
			if is_last_day and (already_passed or done_today) and attendance_chest_open_texture != null:
				icon_texture = attendance_chest_open_texture
				icon_region = attendance_chest_open_used_region
			elif is_last_day and attendance_chest_closed_texture != null:
				icon_texture = attendance_chest_closed_texture
				icon_region = attendance_chest_closed_used_region
			if icon_texture != null and icon_region.size.x > 0.0:
				var icon_aspect := icon_region.size.x / icon_region.size.y
				var icon_size := Vector2(icon_diameter * icon_aspect, icon_diameter) if icon_aspect < 1.0 else Vector2(icon_diameter, icon_diameter / icon_aspect)
				var dim := Color(0.5, 0.5, 0.5, 1.0) if (not already_passed and not done_today and not is_today) else Color.WHITE
				draw_texture_rect_region(icon_texture, Rect2(slot_center - icon_size * 0.5, icon_size), icon_region, dim)
			if (already_passed or done_today) and attendance_complete_badge_texture != null and attendance_complete_badge_used_region.size.x > 0.0:
				var badge_size := Vector2.ONE * icon_diameter * 0.55
				var badge_pos := slot_center + Vector2(icon_diameter, -icon_diameter) * 0.32
				draw_texture_rect_region(attendance_complete_badge_texture, Rect2(badge_pos - badge_size * 0.5, badge_size), attendance_complete_badge_used_region)
			draw_string(font, Vector2(slot_center.x - icon_diameter, slot_center.y + icon_diameter * 0.62), "%d" % int(ATTENDANCE_DAY_REWARDS[i]), HORIZONTAL_ALIGNMENT_CENTER, icon_diameter * 2.0, 16, Color("fff0a6") if is_today else Color("d8c9a3"))
	else:
		var box_gap := 10.0
		var box_width := (ATTENDANCE_PANEL_RECT.size.x - 80.0 - box_gap * float(day_count - 1)) / float(day_count)
		var box_top := 395.0
		for i in range(day_count):
			var box := Rect2(ATTENDANCE_PANEL_RECT.position.x + 40.0 + float(i) * (box_width + box_gap), box_top, box_width, 200.0)
			var day_number := i + 1
			var done_today := day_number == display_day and _is_attendance_claimed_today()
			var already_passed := day_number < display_day
			var is_today := day_number == display_day and not _is_attendance_claimed_today()
			var fill_color := Color("73f7b4") if (already_passed or done_today) else (Color("ffd23f") if is_today else Color("263a57"))
			draw_rect(box, fill_color, true)
			draw_rect(box, Color("fff0a6") if is_today else Color(1.0, 1.0, 1.0, 0.25), false, 4.0 if is_today else 2.0)
			draw_string(font, Vector2(box.position.x, box.position.y + 30.0), "%d일" % day_number, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 18, Color.BLACK if (already_passed or done_today or is_today) else Color("a9bad8"))
			draw_string(font, Vector2(box.position.x, box.position.y + 110.0), "%d" % int(ATTENDANCE_DAY_REWARDS[i]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 26, Color.BLACK if (already_passed or done_today or is_today) else Color("a9bad8"))
			if already_passed or done_today:
				draw_string(font, Vector2(box.position.x, box.position.y + 170.0), "완료", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 18, Color.BLACK)

	var claimable := not _is_attendance_claimed_today()
	draw_rect(ATTENDANCE_CLAIM_BUTTON_RECT, Color("ffd23f") if claimable else Color("4a4f5c"), true)
	draw_rect(ATTENDANCE_CLAIM_BUTTON_RECT, Color("fff0a6"), false, 4.0)
	var claim_label := "받기 (+%d 루비)" % int(ATTENDANCE_DAY_REWARDS[display_day - 1]) if claimable else "내일 또 만나요!"
	draw_string(font, Vector2(ATTENDANCE_CLAIM_BUTTON_RECT.position.x, ATTENDANCE_CLAIM_BUTTON_RECT.position.y + 56.0), claim_label, HORIZONTAL_ALIGNMENT_CENTER, ATTENDANCE_CLAIM_BUTTON_RECT.size.x, 28, Color("633913") if claimable else Color("a9bad8"))


func _draw_rotated_texture_region(texture: Texture2D, target: Rect2, source: Rect2, rotation: float, modulate: Color = Color.WHITE) -> void:
	var center := target.get_center()
	draw_set_transform(design_draw_offset + center * design_draw_scale, rotation, Vector2.ONE * design_draw_scale)
	draw_texture_rect_region(texture, Rect2(-target.size * 0.5, target.size), source, modulate)
	draw_set_transform(design_draw_offset, 0.0, Vector2.ONE * design_draw_scale)


func _draw_main_menu_title(font: Font) -> void:
	var frame_rect := MAIN_MENU_TITLE_RECT
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


func _draw_tab_button(font: Font, tab: Rect2, active: bool, label: String) -> void:
	var texture := tab_active_texture if active else tab_inactive_texture
	var region := tab_active_used_region if active else tab_inactive_used_region
	if texture != null and region.size.x > 0.0:
		draw_texture_rect_region(texture, tab, region)
		draw_string(font, Vector2(tab.position.x, tab.position.y + 30.0), label, HORIZONTAL_ALIGNMENT_CENTER, tab.size.x, 20, Color.BLACK if active else Color("d7e0f2"))
		return
	draw_rect(tab, Color("73f7b4") if active else Color("263a57"), true)
	draw_rect(tab, Color("fff0a6"), false, 3.0)
	draw_string(font, Vector2(tab.position.x, tab.position.y + 30.0), label, HORIZONTAL_ALIGNMENT_CENTER, tab.size.x, 20, Color.BLACK if active else Color("a9bad8"))


func _draw_character_category_tabs(font: Font) -> void:
	var labels := {"all": "전체", "score": "기록", "gold": "골드"}
	var categories: Array[String] = ["all", "score", "gold"]
	for category in categories:
		var tab: Rect2 = CHARACTER_CATEGORY_TAB_RECTS[category]
		var active: bool = character_category_filter == category
		_draw_tab_button(font, tab, active, labels[category])


func _draw_panel_frame(rect: Rect2) -> void:
	if panel_frame_texture != null and panel_frame_used_region.size.x > 0.0:
		draw_texture_rect_region(panel_frame_texture, rect, panel_frame_used_region)
		return
	draw_rect(rect, Color("17243b"), true)
	draw_rect(rect, Color("fff0a6"), false, 7.0)


func _draw_character_panel_frame(rect: Rect2) -> void:
	if character_panel_frame_texture != null and character_panel_frame_used_region.size.x > 0.0:
		draw_texture_rect_region(character_panel_frame_texture, rect, character_panel_frame_used_region)
		return
	_draw_panel_frame(rect)


func _draw_row_background(rect: Rect2) -> void:
	_draw_row_background_on(self, rect)


func _draw_row_background_on(canvas: CanvasItem, rect: Rect2) -> void:
	if input_row_bg_texture != null and input_row_bg_used_region.size.x > 0.0:
		canvas.draw_texture_rect_region(input_row_bg_texture, rect, input_row_bg_used_region)
		return
	canvas.draw_rect(rect, Color("263a57"), true)
	canvas.draw_rect(rect, Color("fff0a6"), false, 4.0)


func _draw_close_button(rect: Rect2) -> void:
	if close_button_texture != null and close_button_used_region.size.x > 0.0:
		draw_texture_rect_region(close_button_texture, rect, close_button_used_region)
		return
	draw_circle(rect.get_center(), 24.0, Color("ff4d67"))
	draw_line(rect.get_center() + Vector2(-8.0, -8.0), rect.get_center() + Vector2(8.0, 8.0), Color.WHITE, 5.0, true)
	draw_line(rect.get_center() + Vector2(8.0, -8.0), rect.get_center() + Vector2(-8.0, 8.0), Color.WHITE, 5.0, true)


func _draw_character_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	_draw_character_panel_frame(CHARACTER_PANEL_RECT)
	draw_string(font, Vector2(CHARACTER_PANEL_RECT.position.x, 300.0), "캐릭터", HORIZONTAL_ALIGNMENT_CENTER, CHARACTER_PANEL_RECT.size.x, 38, Color.WHITE)
	_draw_close_button(CHARACTER_PANEL_CLOSE_RECT)
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
	_draw_panel_frame(SETTINGS_PANEL_RECT)
	draw_string(font, Vector2(SETTINGS_PANEL_RECT.position.x, 300.0), "설정", HORIZONTAL_ALIGNMENT_CENTER, SETTINGS_PANEL_RECT.size.x, 38, Color.WHITE)
	_draw_close_button(SETTINGS_PANEL_CLOSE_RECT)

	_draw_settings_toggle_row(font, SOUND_TOGGLE_RECT, "소리", feedback.sound_enabled)
	_draw_settings_toggle_row(font, VIBRATION_TOGGLE_RECT, "진동", feedback.vibration_enabled)

	_draw_row_background(NICKNAME_ROW_RECT)
	draw_string(font, Vector2(NICKNAME_ROW_RECT.position.x + 16.0, NICKNAME_ROW_RECT.position.y + 46.0), "닉네임", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 22, Color.WHITE)
	draw_rect(NICKNAME_SAVE_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(NICKNAME_SAVE_BUTTON_RECT, Color("ffd23f"), false, 3.0)
	draw_string(font, Vector2(NICKNAME_SAVE_BUTTON_RECT.position.x, NICKNAME_SAVE_BUTTON_RECT.position.y + 46.0), "저장", HORIZONTAL_ALIGNMENT_CENTER, NICKNAME_SAVE_BUTTON_RECT.size.x, 22, Color("ffd23f"))

	_draw_row_background(CODE_ROW_RECT)
	draw_string(font, Vector2(CODE_ROW_RECT.position.x + 16.0, CODE_ROW_RECT.position.y + 46.0), "코드", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 22, Color.WHITE)
	draw_rect(CODE_SUBMIT_BUTTON_RECT, Color("3b2119"), true)
	draw_rect(CODE_SUBMIT_BUTTON_RECT, Color("ffd23f"), false, 3.0)
	draw_string(font, Vector2(CODE_SUBMIT_BUTTON_RECT.position.x, CODE_SUBMIT_BUTTON_RECT.position.y + 46.0), "확인", HORIZONTAL_ALIGNMENT_CENTER, CODE_SUBMIT_BUTTON_RECT.size.x, 22, Color("ffd23f"))

	_draw_row_background(DATA_RESET_ROW_RECT)
	var reset_label := "한 번 더 눌러 확인" if data_reset_confirm_pending else "데이터 초기화"
	var reset_color := Color("ff6b6b") if data_reset_confirm_pending else Color("ff9f9f")
	draw_string(font, Vector2(DATA_RESET_ROW_RECT.position.x, DATA_RESET_ROW_RECT.position.y + 46.0), reset_label, HORIZONTAL_ALIGNMENT_CENTER, DATA_RESET_ROW_RECT.size.x, 22, reset_color)

	if not settings_message.is_empty():
		draw_multiline_string(font, Vector2(SETTINGS_PANEL_RECT.position.x + 20.0, 830.0), settings_message, HORIZONTAL_ALIGNMENT_CENTER, SETTINGS_PANEL_RECT.size.x - 40.0, 20, -1, Color("ffd166"))


func _draw_ranking_period_tabs(font: Font) -> void:
	var labels := {"all": "전체", "week": "주간", "perfect": "퍼펙트"}
	var periods: Array[String] = ["all", "week", "perfect"]
	for period in periods:
		var tab: Rect2 = RANKING_PERIOD_TAB_RECTS[period]
		var active: bool = ranking_period_filter == period
		_draw_tab_button(font, tab, active, labels[period])


func _draw_ranking_menu(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.02, 0.03, 0.06, 0.72), true)
	_draw_panel_frame(RANKING_PANEL_RECT)
	draw_string(font, Vector2(RANKING_PANEL_RECT.position.x, 300.0), "랭킹", HORIZONTAL_ALIGNMENT_CENTER, RANKING_PANEL_RECT.size.x, 38, Color.WHITE)
	_draw_close_button(RANKING_PANEL_CLOSE_RECT)
	_draw_ranking_period_tabs(font)
	draw_string(font, Vector2(RANKING_PANEL_RECT.position.x, 410.0), "TOP %d" % LEADERBOARD_TOP_N, HORIZONTAL_ALIGNMENT_CENTER, RANKING_PANEL_RECT.size.x, 22, Color("a9bad8"))

	_ensure_ranking_list_viewport()
	var scroll_max := _ranking_scroll_max()
	if scroll_max > 0.0:
		# Same thin track + thumb hint used by the character list — the
		# ranking list can now hold more rows (LEADERBOARD_TOP_N) than fit
		# in RANKING_LIST_RECT, so it scrolls instead of spilling out of the
		# panel frame.
		var track := Rect2(RANKING_LIST_RECT.end.x - 6.0, RANKING_LIST_RECT.position.y, 6.0, RANKING_LIST_RECT.size.y)
		draw_rect(track, Color(1.0, 1.0, 1.0, 0.12), true)
		var thumb_height := maxf(40.0, track.size.y * (track.size.y / (track.size.y + scroll_max)))
		var thumb_y := track.position.y + (track.size.y - thumb_height) * (ranking_scroll_offset / scroll_max)
		draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_height), Color("ffd23f"), true)


func _draw_settings_toggle_row(font: Font, row: Rect2, label: String, is_on: bool) -> void:
	_draw_row_background(row)
	draw_string(font, Vector2(row.position.x + 16.0, row.position.y + 50.0), label, HORIZONTAL_ALIGNMENT_LEFT, 200.0, 24, Color.WHITE)
	var toggle_rect := Rect2(row.end.x - 140.0, row.position.y + 15.0, 120.0, 50.0)
	var toggle_texture := toggle_on_texture if is_on else toggle_off_texture
	var toggle_region := toggle_on_used_region if is_on else toggle_off_used_region
	if toggle_texture != null and toggle_region.size.x > 0.0:
		# The source art keeps its own aspect ratio rather than stretching to
		# the toggle_rect's fixed 120x50 box, so it fits by height and stays
		# centered instead of looking squashed.
		var aspect := toggle_region.size.x / toggle_region.size.y
		var size := Vector2(toggle_rect.size.y * aspect, toggle_rect.size.y)
		if size.x > toggle_rect.size.x:
			size = Vector2(toggle_rect.size.x, toggle_rect.size.x / aspect)
		draw_texture_rect_region(toggle_texture, Rect2(toggle_rect.get_center() - size * 0.5, size), toggle_region)
		return
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
	if character_card_frame_texture != null and character_card_frame_used_region.size.x > 0.0:
		if selected:
			# A hard-edged green rectangle clashed with the card's own gold/
			# wood carving, so selection instead reads as a soft warm glow
			# radiating from behind the card — layered rects growing outward
			# with falling alpha, drawn *before* the frame texture so only
			# the glow peeking past the card's own edges stays visible once
			# the (larger, opaque) frame is drawn on top.
			var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.0035)
			for i in range(5):
				var grow_amount := 5.0 + float(i) * 6.0
				var alpha := (0.32 - float(i) * 0.055) * pulse
				canvas.draw_rect(card.grow(grow_amount), Color(1.0, 0.82, 0.32, alpha), true)
		var frame_tint := Color(0.62, 0.6, 0.66) if not owned else Color.WHITE
		canvas.draw_texture_rect_region(character_card_frame_texture, card, character_card_frame_used_region, frame_tint)
	else:
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
		if not owned and lock_icon_texture != null and lock_icon_used_region.size.x > 0.0:
			var lock_size := Vector2(64.0, 64.0)
			var lock_rect := Rect2(preview_rect.get_center() - lock_size * 0.5, lock_size)
			canvas.draw_texture_rect_region(lock_icon_texture, lock_rect, lock_icon_used_region)
	# Offsets are anchored from the card's BOTTOM (not top) so they keep the
	# same absolute position regardless of how much extra headroom the top of
	# the card has for oversized character art.
	# Text colors here are tuned for the tan/parchment card art, not the old
	# dark-navy card — the previous white/pale-gold palette nearly vanished
	# against the light background.
	var name: String = character_names.get(character_id, character_id)
	canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 95.0), name, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 20, Color("3f2712") if owned else Color("8a7154"))
	if owned:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "보유", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("8a5a1a"))
		var state_text := "사용 중" if selected else "선택"
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), state_text, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, Color("1f7a52") if selected else Color("8a5a1a"))
		return
	var price := int(character_prices.get(character_id, 0))
	var required_score := int(character_unlock_scores.get(character_id, 0))
	if price > 0:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "%d 골드" % price, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("8a5a1a"))
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), "구매", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, Color("1f7a52") if coins >= price else Color("b0362f"))
	else:
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 58.0), "최고기록 %d" % required_score, HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 19, Color("6b5842"))
		canvas.draw_string(font, Vector2(card.position.x + 8.0, card.end.y - 22.0), "잠김", HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 16.0, 21, Color("6b5842"))


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
