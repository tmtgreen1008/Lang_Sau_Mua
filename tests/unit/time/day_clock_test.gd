extends GdUnitTestSuite
## Unit tests for DayClock (src/gameplay/time/day_clock.gd, ADR-0004 rules 1, 2, 4, 10 and
## ADR-0003 rule 4). Time is injected through tick(); nothing here reads a file or the
## wall clock. Config comes from _valid_config(), a hand-written Dictionary.

const PHASE_SECONDS: float = 10.0
const PHASE_COUNT: int = 3
const MAX_STEP: float = 1.0
const DAYS_PER_SEASON: int = 2


# --- configure -----------------------------------------------------------------------

func test_configure_valid_config_applies_and_starts_at_day_one() -> void:
	# Arrange
	var clock := DayClock.new()
	var result := DataResult.new()

	# Act
	clock.configure(_valid_config(), result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_int(clock.day_number).is_equal(1)
	assert_str(clock.get_phase_id()).is_equal("morning")
	assert_str(clock.get_season_id()).is_equal("ha")
	assert_str(String(clock.get_day_speed())).is_equal("normal")
	assert_bool(clock.is_paused()).is_false()


func test_configure_bad_config_keeps_previous_state() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.sleep()
	var broken: Dictionary = _valid_config()
	broken["phases"] = []

	# Act
	var result := DataResult.new()
	clock.configure(broken, result)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_int(clock.day_number).is_equal(2)
	assert_str(clock.get_phase_id()).is_equal("morning")


func test_configure_ignores_errors_already_in_the_result() -> void:
	# Arrange: another data file already failed; this config is fine.
	var clock := DayClock.new()
	var result := DataResult.new()
	result.add_error("crops.json", "unrelated problem")

	# Act
	clock.configure(_valid_config(), result)

	# Assert
	assert_array(result.errors).has_size(1)
	assert_str(clock.get_phase_id()).is_equal("morning")


func test_configure_missing_max_step_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config.erase("max_step_seconds")

	# Act / Assert
	_assert_config_error(config, "max_step_seconds")


func test_configure_zero_max_step_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["max_step_seconds"] = 0.0

	# Act / Assert
	_assert_config_error(config, "max_step_seconds")


func test_configure_max_step_longer_than_shortest_phase_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["max_step_seconds"] = PHASE_SECONDS + 0.5

	# Act / Assert
	_assert_config_error(config, "max_step_seconds")


func test_configure_missing_day_speed_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config.erase("day_speed")

	# Act / Assert
	_assert_config_error(config, "day_speed")


func test_configure_missing_day_speed_mode_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	(config["day_speed"] as Dictionary).erase("stop")

	# Act / Assert
	_assert_config_error(config, "stop")


func test_configure_zero_normal_speed_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	(config["day_speed"] as Dictionary)["normal"] = 0.0

	# Act / Assert
	_assert_config_error(config, "normal")


func test_configure_negative_speed_factor_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	(config["day_speed"] as Dictionary)["slow"] = -0.5

	# Act / Assert
	_assert_config_error(config, "slow")


func test_configure_non_positive_phase_seconds_reports_error_naming_the_phase() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	((config["phases"] as Array)[1] as Dictionary)["seconds"] = 0.0

	# Act / Assert
	_assert_config_error(config, "phases[1]")


func test_configure_phase_seconds_as_string_reports_error_without_crashing() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	((config["phases"] as Array)[0] as Dictionary)["seconds"] = "30"

	# Act / Assert
	_assert_config_error(config, "phases[0]")


func test_configure_duplicate_phase_id_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	((config["phases"] as Array)[1] as Dictionary)["id"] = "morning"

	# Act / Assert
	_assert_config_error(config, "duplicate")


func test_configure_fractional_days_per_season_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["days_per_season"] = 2.5

	# Act / Assert
	_assert_config_error(config, "days_per_season")


func test_configure_zero_days_per_season_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["days_per_season"] = 0

	# Act / Assert
	_assert_config_error(config, "days_per_season")


func test_configure_empty_phases_reports_error() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["phases"] = []

	# Act / Assert
	_assert_config_error(config, "phases")


func test_configure_unknown_key_warns_but_stays_ok() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["max_step_secnds"] = 1.0

	# Act
	var result := DataResult.new()
	DayClock.new().configure(config, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(1)
	assert_str(result.warnings[0]).contains("max_step_secnds")


func test_configure_underscore_keys_are_ignored_without_warning() -> void:
	# Arrange
	var config: Dictionary = _valid_config()
	config["_note"] = "documentation only"

	# Act
	var result := DataResult.new()
	DayClock.new().configure(config, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()


# --- tick ----------------------------------------------------------------------------

func test_tick_inside_a_phase_emits_nothing_and_adds_time() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	var events: Array[String] = _record(clock)

	# Act
	clock.tick(0.5)

	# Assert
	assert_array(events).is_empty()
	assert_float(clock.to_dict()["phase_elapsed"]).is_equal_approx(0.5, 0.0001)


func test_tick_zero_or_negative_delta_is_ignored() -> void:
	# Arrange
	var clock: DayClock = _make_clock()

	# Act
	clock.tick(0.0)
	clock.tick(-1.0)

	# Assert
	assert_float(clock.to_dict()["phase_elapsed"]).is_equal(0.0)


func test_tick_huge_delta_is_clamped_to_one_step() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	var events: Array[String] = _record(clock)

	# Act
	clock.tick(300.0)

	# Assert
	assert_array(events).is_empty()
	assert_float(clock.to_dict()["phase_elapsed"]).is_equal_approx(MAX_STEP, 0.0001)


func test_tick_huge_delta_near_phase_end_crosses_exactly_one_phase() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.from_dict({"day_number": 1, "phase_index": 0, "phase_elapsed": PHASE_SECONDS - 0.5})
	var events: Array[String] = _record(clock)

	# Act
	clock.tick(300.0)

	# Assert
	assert_array(events).is_equal(["phase:afternoon"])
	assert_int(clock.day_number).is_equal(1)


func test_tick_a_full_day_of_steps_advances_exactly_one_day() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	var events: Array[String] = _record(clock)
	var steps: int = int(PHASE_SECONDS * PHASE_COUNT / MAX_STEP)

	# Act
	for i: int in steps:
		clock.tick(MAX_STEP)

	# Assert
	assert_int(clock.day_number).is_equal(2)
	assert_int(events.count("day:2")).is_equal(1)


func test_day_change_across_a_season_boundary_emits_season_then_phase_then_day() -> void:
	# Arrange: DAYS_PER_SEASON is 2, so the change from day 2 to day 3 starts a new season.
	var clock: DayClock = _make_clock()
	clock.sleep()
	var events: Array[String] = _record(clock)

	# Act
	clock.sleep()

	# Assert
	assert_array(events).is_equal(["season:thu", "phase:morning", "day:3"])


func test_to_dict_then_from_dict_restores_the_same_state() -> void:
	# Arrange
	var source: DayClock = _make_clock()
	source.sleep()
	source.tick(MAX_STEP)
	source.tick(MAX_STEP)
	var saved: Dictionary = source.to_dict()
	var target: DayClock = _make_clock()

	# Act
	target.from_dict(saved)

	# Assert
	assert_dict(target.to_dict()).is_equal(saved)


# --- pause ---------------------------------------------------------------------------

func test_tick_while_paused_does_not_advance() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_paused(DayClock.PAUSE_PANEL, true)

	# Act
	for i: int in 5:
		clock.tick(MAX_STEP)

	# Assert
	assert_bool(clock.is_paused()).is_true()
	assert_float(clock.to_dict()["phase_elapsed"]).is_equal(0.0)


func test_clock_stays_paused_until_every_source_is_cleared() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_paused(DayClock.PAUSE_PANEL, true)
	clock.set_paused(DayClock.PAUSE_APP, true)

	# Act
	clock.set_paused(DayClock.PAUSE_PANEL, false)
	clock.tick(MAX_STEP)
	var still_paused: bool = clock.is_paused()
	var elapsed_while_paused: float = clock.to_dict()["phase_elapsed"]
	clock.set_paused(DayClock.PAUSE_APP, false)
	clock.tick(MAX_STEP)

	# Assert
	assert_bool(still_paused).is_true()
	assert_float(elapsed_while_paused).is_equal(0.0)
	assert_bool(clock.is_paused()).is_false()
	assert_float(clock.to_dict()["phase_elapsed"]).is_equal_approx(MAX_STEP, 0.0001)


func test_setting_the_same_source_twice_needs_only_one_clear() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_paused(DayClock.PAUSE_PANEL, true)
	clock.set_paused(DayClock.PAUSE_PANEL, true)

	# Act
	clock.set_paused(DayClock.PAUSE_PANEL, false)

	# Assert
	assert_bool(clock.is_paused()).is_false()


func test_unknown_pause_source_is_ignored() -> void:
	# Arrange
	var clock: DayClock = _make_clock()

	# Act
	clock.set_paused(&"bogus", true)

	# Assert
	assert_bool(clock.is_paused()).is_false()


func test_every_defined_pause_source_pauses_and_resumes() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	var sources: Array[StringName] = [DayClock.PAUSE_PANEL, DayClock.PAUSE_APP,
			DayClock.PAUSE_FOCUS, DayClock.PAUSE_WINDOW, DayClock.PAUSE_PLAYER]

	for source: StringName in sources:
		# Act
		clock.set_paused(source, true)
		var paused: bool = clock.is_paused()
		clock.set_paused(source, false)

		# Assert
		assert_bool(paused).is_true()
		assert_bool(clock.is_paused()).is_false()


func test_pause_source_names_match_adr_0004() -> void:
	# Arrange / Act / Assert: Main and the tests of its lifecycle mapping rely on these names.
	assert_str(String(DayClock.PAUSE_PANEL)).is_equal("panel")
	assert_str(String(DayClock.PAUSE_APP)).is_equal("app_paused")
	assert_str(String(DayClock.PAUSE_FOCUS)).is_equal("app_focus")
	assert_str(String(DayClock.PAUSE_WINDOW)).is_equal("window_focus")
	assert_str(String(DayClock.PAUSE_PLAYER)).is_equal("player")


# --- day speed and sleep -------------------------------------------------------------

func test_slow_speed_makes_a_phase_take_twice_as_long() -> void:
	# Arrange: slow is 0.5, so a 10 s phase needs 20 steps of 1 s.
	var clock: DayClock = _make_clock()
	clock.set_day_speed(&"slow")
	var events: Array[String] = _record(clock)
	var steps_to_cross: int = int(PHASE_SECONDS / MAX_STEP / 0.5)

	# Act
	for i: int in steps_to_cross - 1:
		clock.tick(MAX_STEP)
	var crossed_early: bool = not events.is_empty()
	clock.tick(MAX_STEP)

	# Assert
	assert_bool(crossed_early).is_false()
	assert_array(events).is_equal(["phase:afternoon"])


func test_stop_speed_freezes_the_clock_but_sleep_still_ends_the_day() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_day_speed(&"stop")

	# Act
	for i: int in 5:
		clock.tick(MAX_STEP)
	var elapsed_while_stopped: float = clock.to_dict()["phase_elapsed"]
	clock.sleep()

	# Assert
	assert_float(elapsed_while_stopped).is_equal(0.0)
	assert_int(clock.day_number).is_equal(2)


func test_unknown_day_speed_mode_keeps_the_current_mode() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_day_speed(&"slow")

	# Act
	clock.set_day_speed(&"turbo")

	# Assert
	assert_str(String(clock.get_day_speed())).is_equal("slow")


func test_sleep_ignores_pause() -> void:
	# Arrange
	var clock: DayClock = _make_clock()
	clock.set_paused(DayClock.PAUSE_PANEL, true)

	# Act
	clock.sleep()

	# Assert
	assert_int(clock.day_number).is_equal(2)


# --- helpers -------------------------------------------------------------------------

func _valid_config() -> Dictionary:
	return {
		"phases": [
			{"id": "morning", "name": "Sáng", "seconds": PHASE_SECONDS},
			{"id": "afternoon", "name": "Chiều", "seconds": PHASE_SECONDS},
			{"id": "evening", "name": "Tối", "seconds": PHASE_SECONDS},
		],
		"days_per_season": DAYS_PER_SEASON,
		"seasons": [
			{"id": "ha", "name": "Mùa hạ"},
			{"id": "thu", "name": "Mùa thu"},
		],
		"max_step_seconds": MAX_STEP,
		"day_speed": {"normal": 1.0, "slow": 0.5, "stop": 0.0},
	}


func _make_clock() -> DayClock:
	var clock := DayClock.new()
	var result := DataResult.new()
	clock.configure(_valid_config(), result)
	assert_bool(result.ok()).is_true()
	return clock


## Records every signal as "phase:<id>", "day:<n>" or "season:<id>", in emission order.
func _record(clock: DayClock) -> Array[String]:
	var events: Array[String] = []
	clock.phase_changed.connect(func(id: String) -> void: events.append("phase:" + id))
	clock.day_advanced.connect(func(n: int) -> void: events.append("day:%d" % n))
	clock.season_changed.connect(func(id: String) -> void: events.append("season:" + id))
	return events


func _assert_config_error(config: Dictionary, expected_text: String) -> void:
	var result := DataResult.new()
	DayClock.new().configure(config, result)
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains(expected_text)
