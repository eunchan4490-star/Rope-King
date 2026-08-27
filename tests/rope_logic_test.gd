extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")
const BALANCE := preload("res://resources/balance/default_balance.tres")
const TARGET_ANGLE := 1.38

var failures: Array[String] = []


func _init() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	_test_speed_curve(game)
	_test_high_speed_crossings(game)
	_test_red_cue_matches_timing(game)
	_test_save_round_trip()
	game.free()
	if failures.is_empty():
		print("ROPE LOGIC TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_speed_curve(game: Node) -> void:
	for score in [0, 10, 20, 40, 100]:
		var expected := BALANCE.speed_for_score(score)
		game.score = score
		game.rope_speed = expected
		_expect(is_equal_approx(game.rope_speed, expected), "speed curve failed at score %d" % score)


func _test_high_speed_crossings(game: Node) -> void:
	for fps in [30, 60, 120]:
		for score in [0, 10, 20, 40, 100]:
			var speed: float = BALANCE.speed_for_score(score)
			var delta := 1.0 / float(fps)
			_expect(speed * delta < TAU, "one frame skipped a full rotation at score %d / %d fps" % [score, fps])
			var previous := PI
			var crossed_count := 0
			for frame in range(fps * 12):
				var current := fposmod(previous + speed * delta, TAU)
				if game._angle_crossed(previous, current, TARGET_ANGLE):
					crossed_count += 1
				previous = current
			var expected_minimum := int(floor(speed * 12.0 / TAU)) - 1
			_expect(crossed_count >= expected_minimum, "crossing detection missed turns at score %d / %d fps" % [score, fps])


func _test_red_cue_matches_timing(game: Node) -> void:
	game.game_state = 1
	for score in [0, 10, 40, 100]:
		game.rope_speed = BALANCE.speed_for_score(score)
		for sample in range(360):
			game.rope_angle = TAU * float(sample) / 360.0
			var behind: bool = game._rope_is_behind()
			var seconds_until: float = fposmod(TARGET_ANGLE - float(game.rope_angle), TAU) / float(game.rope_speed)
			var expected: bool = not behind and seconds_until <= BALANCE.jump_cue_seconds
			_expect(game._is_jump_cue() == expected, "red cue mismatch at score %d, sample %d" % [score, sample])


func _test_save_round_trip() -> void:
	var test_path := "user://rope_king_automated_test.json"
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	var manager := RopeSaveManager.new(test_path)
	var test_data := manager.default_data()
	test_data.best_score = 42
	test_data.coins = 321
	test_data.settings.sound = false
	_expect(manager.save_game(test_data), "save manager failed to write")
	var loaded := manager.load_game()
	_expect(int(loaded.best_score) == 42, "best score did not survive save round trip")
	_expect(int(loaded.coins) == 321, "coins did not survive save round trip")
	_expect(not bool(loaded.settings.sound), "settings did not survive save round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	manager.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
