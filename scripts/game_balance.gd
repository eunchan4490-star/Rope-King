class_name RopeGameBalance
extends Resource

@export_group("Core Timing")
@export var base_rope_speed := 2.85
@export var speed_gain_per_score := 0.15
@export var jump_cue_seconds := 0.34
@export var required_jump_height := 36.0
@export var challenge_start_score := 10

@export_group("Pattern Multipliers")
@export var offbeat_behind_multiplier := 0.58
@export var offbeat_front_multiplier := 1.18
@export var burst_far_multiplier := 0.72
@export var burst_near_multiplier := 1.48
@export var burst_extra_distance := 0.75
@export var wave_min_multiplier := 0.78
@export var wave_range := 0.42
@export var athlete_burst_multiplier := 1.72


func speed_for_score(score: int) -> float:
	return base_rope_speed + float(maxi(score, 0)) * speed_gain_per_score
