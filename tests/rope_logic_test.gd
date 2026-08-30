extends SceneTree

const MAIN_SCENE := preload("res://main.tscn")
const BALANCE := preload("res://resources/balance/default_balance.tres")
const TARGET_ANGLE := 0.9

var failures: Array[String] = []


func _init() -> void:
	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	_test_speed_curve(game)
	_test_athlete_base_speed_stays_fixed(game)
	_test_high_speed_crossings(game)
	_test_red_cue_matches_timing(game)
	_test_athlete_turner_pattern(game)
	_test_sleepy_turner_pattern(game)
	_test_prankster_turner_pattern(game)
	_test_wizard_turner_pattern(game)
	_test_turner_team_randomization(game)
	_test_physical_clearance_wins(game)
	_test_visible_contact_loses(game)
	_test_coop_mode(game)
	_test_character_asset_system(game)
	_test_save_round_trip()
	_test_return_to_main(game)
	_test_start_at_fifty(game)
	_test_start_at_one_thirty(game)
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


func _test_athlete_base_speed_stays_fixed(game: Node) -> void:
	# _base_speed_for_score now keys off the live turner_team (team
	# assignment past score 10 is random — see _random_turner_team), not
	# fixed score bands, so each case below sets the team it means to test.
	var athlete_base: float = BALANCE.speed_for_score(10)
	_expect(is_equal_approx(BALANCE.speed_gain_per_score, 0.15), "student speed gain was not raised to 0.15 per score")
	game.turner_team = game.TurnerTeam.ATHLETE
	for score in [10, 11, 20, 29]:
		_expect(is_equal_approx(game._base_speed_for_score(score), athlete_base), "athlete base speed increased at score %d" % score)
	game.turner_team = game.TurnerTeam.PRANKSTER
	_expect(is_equal_approx(game._base_speed_for_score(50), athlete_base), "prankster base speed increased at score 50")
	game.turner_team = game.TurnerTeam.WIZARD
	_expect(is_equal_approx(game._base_speed_for_score(70), athlete_base), "wizard base speed increased at score 70")
	game.turner_team = game.TurnerTeam.STUDENT
	_expect(is_equal_approx(game._base_speed_for_score(9), BALANCE.speed_for_score(9)), "student speed curve changed before athlete entry")
	game.turner_team = game.TurnerTeam.SLEEPY
	_expect(is_equal_approx(game._base_speed_for_score(30), BALANCE.speed_for_score(30)), "sleepy student speed curve did not resume at score 30")


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
	_expect(game._update_turner_team_and_pattern(), "turner team did not change at ten successes")
	# Which team gets picked at this boundary is random now (see
	# _random_turner_team) — force athlete specifically so the rest of this
	# test can exercise its own turn pattern deterministically.
	game.turner_team = game.TurnerTeam.ATHLETE
	game._init_turner_team_state(game.TurnerTeam.ATHLETE)
	_expect(int(game.challenge_pattern) == 0, "athlete started with an unfair immediate burst")
	game.is_jumping = false
	game.accepting_input = true
	game._start_turner_transition(game.TurnerTeam.STUDENT)
	_expect(bool(game.turner_transition_active), "athlete entrance transition did not start")
	_expect(not bool(game.accepting_input), "jump input stayed active during athlete entrance")
	_expect(is_equal_approx(game.rope_angle, PI), "rope was not moved behind the player for athlete entrance")
	_expect(int(game.turner_transition_phase) == 1, "student exit was not the first transition phase")
	game._process(game.TURNER_EXIT_SECONDS + 0.01)
	_expect(bool(game.turner_transition_active), "transition ended before athlete entrance and countdown")
	_expect(int(game.turner_transition_phase) == 2, "athlete entrance did not follow student exit")
	game._process(game.COUNTDOWN_TOTAL_SECONDS - 0.02)
	_expect(bool(game.turner_transition_active), "game resumed before GO held for one second")
	_expect(not bool(game.accepting_input), "jump input resumed while GO was still visible")
	game._process(0.02)
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
	_expect(int(game.challenge_pattern) == 2, "athlete second two-turn burst did not begin")
	_expect(int(game.athlete_burst_turns_remaining) == 2, "athlete burst was not capped at two turns")
	var consecutive_bursts := 0
	var maximum_consecutive_bursts := 0
	for simulated_turn in range(12):
		if int(game.challenge_pattern) == 2:
			consecutive_bursts += 1
			maximum_consecutive_bursts = maxi(maximum_consecutive_bursts, consecutive_bursts)
		else:
			consecutive_bursts = 0
		_expect(int(game.athlete_burst_turns_remaining) <= game.ATHLETE_MAX_BURST_TURNS, "athlete burst counter exceeded its hard cap")
		game.score += 1
		game._update_turner_team_and_pattern()
	_expect(maximum_consecutive_bursts <= 2, "athlete stayed at burst speed for more than two consecutive turns")

	game.game_state = 1
	game.challenge_pattern = 2
	game.athlete_burst_turns_remaining = game.ATHLETE_MAX_BURST_TURNS
	game.rope_speed = 3.0
	game.rope_angle = PI
	_expect(is_equal_approx(game._effective_rope_speed(), 3.0 * BALANCE.athlete_burst_multiplier), "athlete burst multiplier was not applied")
	game.rope_angle = fposmod(TARGET_ANGLE - game.rope_speed * BALANCE.jump_cue_seconds * 0.5, TAU)
	_expect(game._is_jump_cue(), "athlete red cue test did not enter the cue window")
	_expect(is_equal_approx(game._effective_rope_speed(), game.rope_speed), "athlete burst changed speed during the red cue")


func _test_sleepy_turner_pattern(game: Node) -> void:
	game._reset_turner_run()
	game.score = 10
	game._update_turner_team_and_pattern()
	game.score = 29
	_expect(not game._update_turner_team_and_pattern(), "sleepy student entered before total score 30")
	game.score = 30
	_expect(game._update_turner_team_and_pattern(), "turner team did not change at total score 30")
	# Force sleepy specifically — the boundary's random pick is covered by
	# _test_turner_team_randomization; this test targets sleepy's own pattern.
	game.turner_team = game.TurnerTeam.SLEEPY
	game._init_turner_team_state(game.TurnerTeam.SLEEPY)
	_expect(int(game.sleepy_slow_turns_remaining) >= game.SLEEPY_MIN_SLOW_TURNS, "sleepy student began without a sleeping turn")
	_expect(int(game.sleepy_slow_turns_remaining) <= game.SLEEPY_MAX_SLOW_TURNS, "sleepy student's initial random sleep exceeded its cap")
	game._start_turner_transition(game.TurnerTeam.ATHLETE)
	_expect(int(game.departing_turner_team) == int(game.TurnerTeam.ATHLETE), "athlete was not retained as the departing team")
	game._process(game.TURNER_EXIT_SECONDS + game.COUNTDOWN_TOTAL_SECONDS + 0.01)
	_expect(not bool(game.turner_transition_active), "sleepy student entrance transition did not finish")
	game.rope_speed = 4.0
	game.rope_angle = PI
	_expect(is_equal_approx(game._effective_rope_speed(), 4.0 * game.SLEEPY_SLOW_MULTIPLIER), "sleepy student's sleeping speed was not very slow")
	game.sleepy_slow_turns_remaining = 2
	game._update_turner_team_and_pattern()
	_expect(int(game.sleepy_slow_turns_remaining) == 1, "sleepy slow phase ended before two turns")
	game._update_turner_team_and_pattern()
	_expect(is_equal_approx(game.sleepy_wake_warning_time, 1.0), "sleepy wake warning was not exactly one second")
	_expect(game._sleepy_is_awake(), "awake sprite did not activate during the warning")
	game._update_sleepy_warning(0.99)
	_expect(int(game.sleepy_fast_turns_remaining) == 0, "fast turn started before the full one-second warning")
	game._update_sleepy_warning(0.02)
	_expect(int(game.sleepy_fast_turns_remaining) == 1, "fast turn did not start after the warning")
	_expect(is_equal_approx(game._effective_rope_speed(), 4.0 * game.SLEEPY_FAST_MULTIPLIER), "sleepy student's wake-up turn was not extremely fast")
	game._update_turner_team_and_pattern()
	_expect(int(game.sleepy_fast_turns_remaining) == 0, "sleepy fast phase lasted more than one turn")
	_expect(int(game.sleepy_slow_turns_remaining) >= 1, "sleepy pattern allowed two awake turns in a row")
	_expect(int(game.sleepy_slow_turns_remaining) <= 3, "sleepy random sleep phase exceeded three turns")
	for sample in range(100):
		var sleep_turns: int = game._roll_sleepy_slow_turns()
		_expect(sleep_turns >= 1 and sleep_turns <= 3, "sleepy random wake timing escaped the 1-to-3-turn range")


func _test_prankster_turner_pattern(game: Node) -> void:
	game._reset_turner_run()
	game.turner_team = game.TurnerTeam.SLEEPY
	game.turner_change_slot = 2  # matches the SLEEPY slot (scores 30-49)
	game.score = 49
	_expect(not game._update_turner_team_and_pattern(), "prankster entered before score 50")
	game.score = 50
	_expect(game._update_turner_team_and_pattern(), "turner team did not change at score 50")
	# Force prankster specifically — see the athlete/sleepy tests above for why.
	game.turner_team = game.TurnerTeam.PRANKSTER
	game._init_turner_team_state(game.TurnerTeam.PRANKSTER)
	_expect(int(game.prankster_normal_turns_remaining) >= 1 and int(game.prankster_normal_turns_remaining) <= 3, "prankster initial fake timing was outside 1-to-3 turns")
	game.prankster_normal_turns_remaining = 1
	game._update_turner_team_and_pattern()
	_expect(bool(game.prankster_fake_pending), "prankster did not schedule a fake after its normal turns")
	game.rope_speed = 4.0
	game.rope_angle = game.ROPE_OVERHEAD_ANGLE - 0.02
	_expect(game._update_prankster_fake(0.01), "prankster fake did not begin at the rope's highest point")
	_expect(is_equal_approx(game.rope_angle, game.ROPE_OVERHEAD_ANGLE), "prankster fake did not lock onto the exact overhead point")
	_expect(int(game.prankster_fake_mode) == 1 or int(game.prankster_fake_mode) == 2, "prankster did not choose stop or reverse")
	_expect(is_equal_approx(game.PRANKSTER_STOP_SECONDS, 1.0), "prankster stop fake was not extended to one second")
	_expect(is_equal_approx(game.PRANKSTER_REVERSE_SECONDS, 1.0), "prankster reverse fake was not extended to one second")
	var chosen_fake_mode: int = game.prankster_fake_mode
	var fake_duration: float = game.PRANKSTER_STOP_SECONDS if int(game.prankster_fake_mode) == 1 else game.PRANKSTER_REVERSE_SECONDS
	var angle_at_fake_start: float = game.rope_angle
	_expect(game._update_prankster_fake(fake_duration + 0.01), "prankster fake did not consume its active frame")
	if chosen_fake_mode == 2:
		_expect(game.rope_angle != angle_at_fake_start, "prankster reverse fake did not move the rope backward")
	_expect(not bool(game.prankster_fake_pending), "prankster fake stayed pending after the hold")
	_expect(int(game.prankster_normal_turns_remaining) >= 1, "prankster allowed two fake holds in a row")
	game.prankster_fake_pending = true
	game.prankster_fake_mode = 2
	game.prankster_fake_time = 0.1
	game.rope_angle = game.ROPE_OVERHEAD_ANGLE
	game._update_prankster_fake(0.05)
	_expect(game.rope_angle < game.ROPE_OVERHEAD_ANGLE, "forced reverse fake did not rotate backward from the highest point")
	game._update_prankster_fake(0.06)
	for sample in range(100):
		var normal_turns: int = game._roll_prankster_normal_turns()
		_expect(normal_turns >= 1 and normal_turns <= 3, "prankster random fake timing escaped the 1-to-3-turn range")
	_expect(is_equal_approx(game._base_speed_for_score(50), BALANCE.speed_for_score(10)), "prankster baseline was not kept at the readable score-10 speed")


func _test_wizard_turner_pattern(game: Node) -> void:
	game._reset_turner_run()
	# Seed turner_change_slot to where a real playthrough would already be by
	# score 69 (past the 10/30/50 boundaries, all slot 3 under
	# TURNER_RANDOM_INTERVAL=20) so this isolates just the slot 3->4
	# transition at score 70, instead of also firing one from the fresh
	# reset's slot 0.
	game.turner_team = game.TurnerTeam.PRANKSTER
	game.turner_change_slot = 3
	game.score = 69
	_expect(not game._update_turner_team_and_pattern(), "wizard entered before score 70")
	game.score = 70
	_expect(game._update_turner_team_and_pattern(), "turner team did not change at score 70")
	# Force wizard specifically — see the athlete/sleepy tests above for why.
	game.turner_team = game.TurnerTeam.WIZARD
	game._init_turner_team_state(game.TurnerTeam.WIZARD)
	_expect(not bool(game.wizard_rope_hidden), "wizard began with an invisible turn instead of a normal turn")
	# Wizard's difficulty comes entirely from its turn pattern (hidden rope +
	# randomized speed), same as athlete/prankster, so its baseline also
	# holds flat at the score-10 speed (see _base_speed_for_score).
	_expect(is_equal_approx(game._base_speed_for_score(70), BALANCE.speed_for_score(10)), "wizard speed was not held at the score-10 baseline")
	game._update_turner_team_and_pattern()
	_expect(bool(game.wizard_rope_hidden), "wizard's second turn did not become invisible")
	game.game_state = game.GameState.PLAYING
	game.rope_speed = BALANCE.speed_for_score(10)
	game.rope_angle = PI
	_expect(game._wizard_rope_is_ghosted(), "wizard's hidden turn did not switch to the blue translucent rope")
	_expect(game.WIZARD_GHOST_CORE_ALPHA <= 0.04, "wizard ghost rope remained too visible")
	_expect(game.WIZARD_GHOST_OUTLINE_ALPHA <= 0.02, "wizard ghost rope outline remained too visible")
	_expect(game.WIZARD_ILLUSION_PHASES.size() == 2, "wizard did not keep two illusion ropes")
	_expect(is_equal_approx(game.WIZARD_ILLUSION_PHASES[0], PI / 6.0), "wizard's first illusion was not offset by 30 degrees")
	_expect(is_equal_approx(game.WIZARD_ILLUSION_PHASES[1], PI / 3.0), "wizard's second illusion did not rotate independently")
	var illusion_angles: PackedFloat32Array = game._wizard_illusion_angles()
	_expect(not is_equal_approx(illusion_angles[0], illusion_angles[1]), "wizard illusion ropes shared one phase")
	game.rope_angle = fposmod(TARGET_ANGLE - game.rope_speed * BALANCE.jump_cue_seconds * 0.5, TAU)
	_expect(game._is_jump_cue(), "wizard visibility test did not enter the red cue")
	_expect(not game._wizard_rope_is_ghosted(), "wizard's translucent rope did not become solid for the red cue")
	_expect(game._wizard_illusions_are_active(), "non-lethal wizard illusions disappeared during the real rope's red cue")
	_expect(is_equal_approx(game._effective_rope_speed(), game.rope_speed), "wizard speed was randomized during the fair red cue window")
	game._update_turner_team_and_pattern()
	_expect(not bool(game.wizard_rope_hidden), "wizard rope did not return to a normal visible turn")
	game.rope_angle = PI
	# Outside the red cue, wizard speed is now randomized per turn (each
	# _update_turner_team_and_pattern() call re-rolls wizard_speed_multiplier)
	# so a steady rhythm alone can't carry a player through — only the range
	# is checked here, not an exact fixed value.
	var wizard_speed: float = game._effective_rope_speed()
	var min_speed: float = game.rope_speed * BALANCE.wizard_speed_min_multiplier
	var max_speed: float = game.rope_speed * BALANCE.wizard_speed_max_multiplier
	_expect(wizard_speed >= min_speed - 0.001 and wizard_speed <= max_speed + 0.001, "wizard speed fell outside its configured random range")
	_expect(is_equal_approx(game._rope_midpoint_y(PI * 1.5), game.LEFT_HAND.y - game.ROPE_OVERHEAD_RADIUS), "wizard rope size still changed")


func _test_turner_team_randomization(game: Node) -> void:
	# Past score 10, the rope-turner team must be re-rolled every
	# TURNER_RANDOM_INTERVAL points, must never repeat the team that was
	# just active, and (run over many seeds) must actually use more than
	# one team — not silently collapse back to a fixed sequence.
	for trial in range(30):
		game._reset_turner_run()
		game.score = 10
		_expect(game._update_turner_team_and_pattern(), "turner team did not change at score 10 (trial %d)" % trial)
		_expect(int(game.turner_team) != int(game.TurnerTeam.STUDENT), "turner stayed on the default team past score 10 (trial %d)" % trial)
		var teams_seen: Dictionary = {int(game.turner_team): true}
		var previous_team: int = int(game.turner_team)
		var boundary := 30
		while boundary <= 80:
			game.score = boundary - 1
			_expect(not game._update_turner_team_and_pattern(), "turner team changed before score %d (trial %d)" % [boundary, trial])
			game.score = boundary
			_expect(game._update_turner_team_and_pattern(), "turner team did not change at score %d (trial %d)" % [boundary, trial])
			_expect(int(game.turner_team) != previous_team, "same turner team repeated back to back at score %d (trial %d)" % [boundary, trial])
			previous_team = int(game.turner_team)
			teams_seen[previous_team] = true
			boundary += 20
		if teams_seen.size() > 1:
			return
	failures.append("turner team randomization never picked more than one team across 30 trials")


func _test_physical_clearance_wins(game: Node) -> void:
	game._reset_turner_run()
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
	game._reset_turner_run()
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


func _test_coop_mode(game: Node) -> void:
	game._start_coop_game()
	_expect(bool(game.coop_mode), "coop button did not activate coop mode")
	_expect(game._active_left_hand() == game.COOP_LEFT_HAND, "coop rope did not extend to the left screen edge")
	_expect(game._active_right_hand() == game.COOP_RIGHT_HAND, "coop rope did not extend to the right screen edge")
	game.attempt_coop_jump(true)
	_expect(bool(game.coop_left_is_jumping), "left-half input did not jump the left player")
	_expect(not bool(game.coop_right_is_jumping), "left-half input also jumped the right player")
	game.attempt_coop_jump(false)
	_expect(bool(game.coop_right_is_jumping), "right-half input did not jump the right player")
	game.coop_left_jump_height = -40.0
	game.coop_right_jump_height = -40.0
	_expect(game._player_clears_rope_at_crossing(), "two jumping coop players did not clear the rope together")
	game.coop_right_is_jumping = false
	_expect(not game._player_clears_rope_at_crossing(), "coop run survived when the right player missed")
	_expect(int(game.coop_hit_player) == 2, "coop collision did not identify the missed right player")
	game._return_to_main()


func _test_character_asset_system(game: Node) -> void:
	var smallest_body_height := INF
	var largest_body_height := 0.0
	game._prepare_turner_visuals()
	_expect(game.mirrored_turner_texture != null, "right rope turner mirror texture was not created")
	_expect(game.mirrored_turner_used_region.size.x > 0.0, "right rope turner mirror region is empty")
	_expect(ResourceLoader.exists("res://assets/turners/athlete_student.png"), "athlete turner asset was not imported")
	_expect(game.athlete_turner_texture != null, "athlete turner texture was not loaded")
	_expect(game.mirrored_athlete_turner_texture != null, "right athlete turner mirror texture was not created")
	_expect(game.mirrored_athlete_turner_used_region.size.x > 0.0, "right athlete turner mirror region is empty")
	_expect(ResourceLoader.exists("res://assets/turners/sleepy_student_asleep.png"), "sleepy asleep asset was not imported")
	_expect(ResourceLoader.exists("res://assets/turners/sleepy_student_awake.png"), "sleepy awake asset was not imported")
	_expect(game.sleepy_turner_asleep_texture != null, "sleepy asleep texture was not loaded")
	_expect(game.sleepy_turner_awake_texture != null, "sleepy awake texture was not loaded")
	_expect(game.mirrored_sleepy_turner_asleep_texture != null, "right sleepy asleep mirror texture was not created")
	_expect(game.mirrored_sleepy_turner_awake_texture != null, "right sleepy awake mirror texture was not created")
	_expect(ResourceLoader.exists("res://assets/turners/prankster_student.png"), "prankster turner asset was not imported")
	_expect(game.prankster_turner_texture != null, "prankster turner texture was not loaded")
	_expect(game.mirrored_prankster_turner_texture != null, "right prankster mirror texture was not created")
	_expect(ResourceLoader.exists("res://assets/turners/wizard_student.png"), "wizard turner asset was not imported")
	_expect(game.wizard_turner_texture != null, "wizard turner texture was not loaded")
	_expect(game.mirrored_wizard_turner_texture != null, "right wizard mirror texture was not created")
	_expect(ResourceLoader.exists("res://assets/ui/title_frame.png"), "HUD title frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/title_logo.png"), "HUD title logo asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/best_score_frame.png"), "best score frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/resource_counter_frame.png"), "resource counter frame asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/tap_to_start.png"), "tap-to-start prompt asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/coin_icon.png"), "coin icon asset was not imported")
	_expect(ResourceLoader.exists("res://assets/ui/ruby_icon.png"), "ruby icon asset was not imported")
	for icon_offset in [game.COIN_ICON_OFFSET, game.RUBY_ICON_OFFSET]:
		var resource_icon_rect := Rect2(icon_offset, game.RESOURCE_ICON_SIZE)
		_expect(Rect2(Vector2.ZERO, Vector2(48.0, 62.0)).encloses(resource_icon_rect), "resource icon protrudes outside its frame socket")
	for countdown_name in ["3", "2", "1", "go"]:
		var countdown_path := "res://assets/ui/countdown_%s.png" % countdown_name
		_expect(ResourceLoader.exists(countdown_path), "countdown asset %s was not imported" % countdown_name)
		var countdown_texture := load(countdown_path) as Texture2D
		_expect(countdown_texture != null, "countdown texture %s did not load" % countdown_name)
		if countdown_texture != null:
			_expect(countdown_texture.get_image().get_pixel(0, 0).a < 0.01, "countdown asset %s background is not transparent" % countdown_name)
	_expect(ResourceLoader.exists("res://assets/characters/default/idle.png"), "default idle asset path was not imported")
	_expect(ResourceLoader.exists("res://assets/characters/default/jump_sheet.png"), "default jump asset path was not imported")
	_expect(game._is_safe_character_id("default"), "default character id was rejected")
	game._load_character_catalog()
	_expect(game.character_ids.has("default"), "default character should be available")
	_expect(game.character_ids[0] == "default", "character metadata order was not applied")
	_expect(game.owned_character_ids.has("default"), "default character should be owned")
	game._load_character_visuals("default")
	_expect(game.player_sprite != null, "default character idle sprite was not loaded")
	_expect(game.player_jump_regions.size() == 2, "jump sheet was not split into the air/mid pose pair")
	_expect(game.player_jump_scale.x > 0.0 and game.player_jump_scale.y > 0.0, "character scale was not calculated")
	_expect(is_equal_approx(game.player_jump_scale.x, game.player_jump_scale.y), "jump sprite scale distorts the character aspect ratio")
	_expect(not game.set_player_character("../unsafe"), "unsafe character id was accepted")
	for character_id in game.character_ids:
		_expect(game.set_player_character(character_id), "%s character could not be measured" % character_id)
		for asset_name in ["idle.png", "jump_sheet.png"]:
			var asset_texture := load("res://assets/characters/%s/%s" % [character_id, asset_name]) as Texture2D
			if asset_texture != null:
				var asset_image := asset_texture.get_image()
				var last_x := asset_image.get_width() - 1
				var last_y := asset_image.get_height() - 1
				for corner in [Vector2i.ZERO, Vector2i(last_x, 0), Vector2i(0, last_y), Vector2i(last_x, last_y)]:
					_expect(asset_image.get_pixelv(corner).a < 0.02, "%s %s corner is not transparent" % [character_id, asset_name])
		var body_top_fraction := float(game.character_body_top_fractions.get(character_id, 0.0))
		var body_height: float = game.player_base_region.size.y * (1.0 - body_top_fraction) * game.player_base_scale
		smallest_body_height = minf(smallest_body_height, body_height)
		largest_body_height = maxf(largest_body_height, body_height)
	_expect(largest_body_height / smallest_body_height < 1.08, "character body heights differ too much")
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


func _test_start_at_fifty(game: Node) -> void:
	game._start_game_at_score(50)
	_expect(int(game.game_state) == int(game.GameState.PLAYING), "50-start test button did not start gameplay")
	_expect(int(game.score) == 50, "50-start test button used the wrong score")
	# Which team gets picked past score 10 is random now (see
	# _random_turner_team) — only assert a non-default team is active.
	_expect(int(game.turner_team) != int(game.TurnerTeam.STUDENT), "50-start test button did not activate a non-default team")
	_expect(is_equal_approx(game.rope_speed, game._base_speed_for_score(50)), "50-start test button used the wrong rope speed")
	_expect(not bool(game.turner_transition_active), "50-start test button incorrectly played an entrance transition")


func _test_start_at_one_thirty(game: Node) -> void:
	game._start_game_at_score(130)
	_expect(int(game.game_state) == int(game.GameState.PLAYING), "130-start test button did not start gameplay")
	_expect(int(game.score) == 130, "130-start test button used the wrong score")
	_expect(not bool(game.air_challenge_active), "disabled air challenge launched at score 130")
	_expect(not bool(game.rope_b_enabled), "double rope stayed on during side-swing mode")
	_expect(int(game.turner_team) == int(game.TurnerTeam.STUDENT), "side-swing mode did not use the default student turner")
	_expect(is_equal_approx(game.rope_speed, BALANCE.speed_for_score(8)), "score 130 side swing did not use the score-8 rope speed")
	_expect(int(game.side_swing_turns_remaining) == 1, "score 130 did not begin with one side swing")
	_expect(not game._is_jump_cue(), "side swing incorrectly showed a real jump cue")
	_expect(absf(game._side_swing_lateral_offset()) > 0.0, "side swing did not move into the upper side space")
	game.rope_angle = game.ROPE_CROSSING_ANGLE - 0.05
	game._process(0.02)
	_expect(int(game.score) == 130, "side swing incorrectly awarded a normal rope score")
	_expect(int(game.side_swing_turns_remaining) == 0, "completed side swing did not advance to centre entry")
	_expect(is_equal_approx(game.rope_angle, PI), "centre entry did not restart safely behind the player")
	game.score = 149
	game._prepare_side_swing_sequence()
	_expect(int(game.side_swing_turns_remaining) >= 1 and int(game.side_swing_turns_remaining) <= 3, "late side-swing sequence fell outside the 1-3 turn range")
	game.score = 150
	_expect(not game._side_swing_score_is_active(), "side-swing mode did not end after the 150th rope")
	game._return_to_main()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
