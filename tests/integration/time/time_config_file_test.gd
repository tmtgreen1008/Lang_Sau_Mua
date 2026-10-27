extends GdUnitTestSuite
## Integration test: the real assets/data/time_config.json must load through DataLoader and
## DayClock.configure with no errors and no warnings (ADR-0003 rule 10), so CI guards the
## shipped content. Reads a file, hence not a unit test.

const TIME_CONFIG_PATH: String = "res://assets/data/time_config.json"


func test_shipped_time_config_loads_without_errors_or_warnings() -> void:
	# Arrange
	var clock := DayClock.new()
	var result: DataResult = DataLoader.read_json(TIME_CONFIG_PATH)

	# Act
	clock.configure(result.data, result)

	# Assert
	assert_array(result.errors).is_empty()
	assert_array(result.warnings).is_empty()
	assert_str(clock.get_phase_id()).is_equal("morning")


func test_shipped_time_config_clamps_a_huge_tick_to_a_small_step() -> void:
	# Arrange
	var clock := DayClock.new()
	var result: DataResult = DataLoader.read_json(TIME_CONFIG_PATH)
	clock.configure(result.data, result)

	# Act
	clock.tick(300.0)

	# Assert: the first phase is not left, and the clock moved by a small positive step.
	assert_str(clock.get_phase_id()).is_equal("morning")
	assert_float(clock.to_dict()["phase_elapsed"]).is_greater(0.0)
	assert_float(clock.to_dict()["phase_elapsed"]).is_less(1.0)
