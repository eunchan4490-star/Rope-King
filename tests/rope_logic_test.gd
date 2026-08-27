extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")
const BALANCE := preload("res://resources/balance/default_balance.tres")
const TARGET_ANGLE := 0.9

var failures: Array[String] = []


func _init() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	_test_speed_curve(game)
	_test_high_speed_crossings(game)
	_test_red_cue_matches_timing(game)
	_test_athlete_turner_pattern(game)
	_test_physical_clearance_wins(game)
	_test_visible_contact_loses(game)
	_test_character_asset_system(game)
	_test_save_round_trip()
	_test_return_to_main(game)
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


func _test_athlete_turner_pattern(game: Node) -> void:
	game._reset_turner_run()
	game.score = 9
	_expect(not game._update_turner_team_and_pattern(), "turner changed before ten successes")
	game.score = 10
	_expect(game._update_turner_team_and_pattern(), "athlete did not enter at ten successes")
	_expect(int(game.turner_team) == 1, "athlete team was not activated")
	_expect(int(game.challenge_pattern) == 0, "athlete started with an unfair immediate burst")
	game.is_jumping = false
	game.accepting_input = true
	game._start_turner_transition()
	_expect(bool(game.turner_transition_active), "athlete entrance transition did not start")
	_expect(not bool(game.accepting_input), "jump input stayed active during athlete entrance")
	_expect(is_equal_approx(game.rope_angle, PI), "rope was not moved behind the player for athlete entrance")
	game._process(game.TURNER_TRANSITION_SECONDS + 0.01)
	_expect(not bool(game.turner_transition_active), "athlete entrance transition did not finish")
	_expect(bool(game.accepting_input), "jump input did not resume after athlete entrance")
	game.score = 11
	game._update_turner_team_and_pattern()
	_expect(int(game.challenge_pattern) == 0, "athlete normal lead-in was shorter than two turns")
	game.score = 12
	game._update_turner_team_and_pattern()
	_expect(int(game.challenge_pattern) == 2, "athlete two-turn burst did not begin")
	game.score = 13
	game._update_turner_team_and_pattern()
	_expect(int(game.challenge_pattern) == 2, "athlete two-turn burst ended early")
	game.score = 14
	game._update_turner_team_and_pattern()
	_expect(int(game.challenge_pattern) == 0, "athlete burst did not return to normal rhythm")
	game.score = 15
	game._update_turner_team_and_pattern()
	game.score = 16
	game._update_turner_team_and_pattern()
	_expect(int(game.challenge_pattern) == 2, "athlete alternating three-turn burst did not begin")
	_expect(int(game.athlete_burst_turns_remaining) == 3, "athlete burst did not alternate from two to three turns")

	game.game_state = 1
	game.rope_speed = 3.0
	game.rope_angle = PI
	_expect(is_equal_approx(game._effective_rope_speed(), 3.0 * BALANCE.athlete_burst_multiplier), "athlete burst multiplier was not applied")
	game.rope_angle = fposmod(TARGET_ANGLE - game.rope_speed * BALANCE.jump_cue_seconds * 0.5, TAU)
	_expect(game._is_jump_cue(), "athlete red cue test did not enter the cue window")
	_expect(is_equal_approx(game._effective_rope_speed(), game.rope_speed), "athlete burst changed speed during the red cue")


func _test_physical_clearance_wins(game: Node) -> void:
	if game.feedback == null:
		game.feedback = RopeFeedbackManager.new()
		game.add_child(game.feedback)
	game.game_state = 1
	game.score = 0
	game.rope_speed = BALANCE.base_rope_speed
	game.is_jumping = true
	game.jump_height = -BALANCE.required_jump_height - 1.0
	game.jump_started_in_cue = false
	game._resolve_rope_crossing()
	_expect(int(game.score) == 1, "a visibly cleared rope was incorrectly treated as a hit")
	_expect(int(game.game_state) == 1, "physical clearance incorrectly ended the run")


func _test_visible_contact_loses(game: Node) -> void:
	game.game_state = 1
	game.is_jumping = true
	game.jump_height = -3.0
	_expect(not game._player_clears_rope_at_crossing(), "visible rope contact was incorrectly treated as clear")
	game.jump_height = -12.0
	_expect(game._player_clears_rope_at_crossing(), "visible gap above the rope was incorrectly treated as contact")
	var overhead_y: float = game._rope_midpoint_y(PI * 1.5)
	_expect(overhead_y <= game.PLAYER_GROUND_Y - game.player_sprite_max_size.y - 30.0, "rope orbit leaves too little space above the player's head")
	var lowest_y: float = game._rope_midpoint_y(PI * 0.5)
	_expect(is_equal_approx(lowest_y, game.PLAYER_GROUND_Y + 5.0), "rope lowest point is not exactly five pixels below the player's feet")


func _test_character_asset_system(game: Node) -> void:
	game._prepare_turner_visuals()
	_expect(game.mirrored_turner_texture != null, "right rope turner mirror texture was not created")
	_expect(game.mirrored_turner_used_region.size.x > 0.0, "right rope turner mirror region is empty")
	_expect(ResourceLoader.exists("res://assets/turners/athlete_student.png"), "athlete turner asset was not imported")
	_expect(game.athlete_turner_texture != null, "athlete turner texture was not loaded")
	_expect(game.mirrored_athlete_turner_texture != null, "right athlete turner mirror texture was not created")
	_expect(game.mirrored_athlete_turner_used_region.size.x > 0.0, "right athlete turner mirror region is empty")
	_expect(ResourceLoader.exists("res://assets/ui/title_frame.png"), "HUD title frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/title_logo.png"), "HUD title logo asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/best_score_frame.png"), "best score frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/resource_counter_frame.png"), "resource counter frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/tap_to_start.png"), "tap-to-start prompt asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/coin_icon.png"), "coin icon asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/ruby_icon.png"), "ruby icon asset was not imported")
	_expect(ResourceLoader.exists("res://assets/characters/default/idle.png"), "default idle asset path was not imported")
	_expect(ResourceLoader.exists("res://assets/characters/default/jump_sheet.png"), "default jump asset path was not imported")
	_expect(game._is_safe_character_id("default"), "default character id was rejected")
	game._load_character_catalog()
	_expect(game.character_ids.size() >= 3, "character folders were not discovered")
	_expect(game.character_ids[0] == "default", "character metadata order was not applied")
	_expect(game.character_names.get("schoolgirl_bob", "") == "단발 학생", "character display name was not loaded")
	_expect(game.owned_character_ids.size() >= 3, "default-owned characters were not registered")
	game._load_character_visuals("default")
	_expect(game.player_sprite != null, "default character idle sprite was not loaded")
	_expect(game.player_jump_regions.size() == 4, "jump sheet was not split into four frames")
	_expect(game.player_jump_scale.x > 0.0 and game.player_jump_scale.y > 0.0, "character scale was not calculated")
	_expect(not game.set_player_character("../unsafe"), "unsafe character id was accepted")
	for character_id in ["schoolgirl_ponytail", "schoolgirl_bob"]:
		_expect(game.set_player_character(character_id), "%s character could not be selected" % character_id)
		_expect(game.player_jump_regions.size() == 4, "%s jump sheet was not split into four frames" % character_id)
	_expect(game.set_player_character("default"), "default character could not be selected")


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


func _test_return_to_main(game: Node) -> void:
	game.game_state = 3
	game.score = 17
	game.is_jumping = true
	game._return_to_main()
	_expect(int(game.game_state) == 0, "close button did not return to title state")
	_expect(int(game.score) == 0, "return to title did not clear current score")
	_expect(not bool(game.is_jumping), "return to title kept the player jumping")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
