class_name RopeSaveManager
extends Node

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://rope_king_save.json"
const DEFAULT_NICKNAME := "플레이어"
const NICKNAME_MAX_LENGTH := 10

var save_path := DEFAULT_SAVE_PATH


func _init(custom_save_path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = custom_save_path


func load_game() -> Dictionary:
	var defaults := default_data()
	if not FileAccess.file_exists(save_path):
		return defaults
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return defaults
	return _sanitize(parsed as Dictionary, defaults)


func save_game(data: Dictionary) -> bool:
	var clean_data := _sanitize(data, default_data())
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open Rope-King save file: %s" % save_path)
		return false
	file.store_string(JSON.stringify(clean_data, "\t"))
	return true


func default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"best_score": 0,
		"coins": 100,
		"gems": 0,
		"selected_character": "default",
		"owned_characters": ["default"],
		"nickname": DEFAULT_NICKNAME,
		"settings": {
			"sound": true,
			"vibration": true,
		},
		"stats": {
			"total_runs": 0,
			"total_success": 0,
		},
		"attendance": {
			"streak": 0,
			"last_claim_date": "",
		},
		"tutorial_seen": false,
	}


func _sanitize(source: Dictionary, defaults: Dictionary) -> Dictionary:
	var settings_source: Dictionary = source.get("settings", {}) if source.get("settings", {}) is Dictionary else {}
	var stats_source: Dictionary = source.get("stats", {}) if source.get("stats", {}) is Dictionary else {}
	var attendance_source: Dictionary = source.get("attendance", {}) if source.get("attendance", {}) is Dictionary else {}
	var owned_source = source.get("owned_characters", defaults.owned_characters)
	var owned: Array = owned_source if owned_source is Array else defaults.owned_characters
	if owned.is_empty():
		owned = ["default"]
	var nickname := str(source.get("nickname", defaults.nickname)).strip_edges()
	if nickname.is_empty():
		nickname = DEFAULT_NICKNAME
	elif nickname.length() > NICKNAME_MAX_LENGTH:
		nickname = nickname.substr(0, NICKNAME_MAX_LENGTH)
	return {
		"save_version": SAVE_VERSION,
		"best_score": maxi(0, int(source.get("best_score", defaults.best_score))),
		"coins": maxi(0, int(source.get("coins", defaults.coins))),
		"gems": maxi(0, int(source.get("gems", defaults.gems))),
		"selected_character": str(source.get("selected_character", defaults.selected_character)),
		"owned_characters": owned,
		"nickname": nickname,
		"settings": {
			"sound": bool(settings_source.get("sound", defaults.settings.sound)),
			"vibration": bool(settings_source.get("vibration", defaults.settings.vibration)),
		},
		"stats": {
			"total_runs": maxi(0, int(stats_source.get("total_runs", defaults.stats.total_runs))),
			"total_success": maxi(0, int(stats_source.get("total_success", defaults.stats.total_success))),
		},
		"attendance": {
			"streak": maxi(0, int(attendance_source.get("streak", defaults.attendance.streak))),
			"last_claim_date": str(attendance_source.get("last_claim_date", defaults.attendance.last_claim_date)),
		},
		"tutorial_seen": bool(source.get("tutorial_seen", defaults.tutorial_seen)),
	}
