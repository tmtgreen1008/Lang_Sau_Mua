extends GdUnitTestSuite
## Unit tests for GameConfig (src/core/data/game_config.gd, ADR-0003 rule 8): gameplay numbers
## that used to be written into the code. A key that is missing is a fatal error; there is no
## built-in default in the code to fall back on. Content is a hand-written Dictionary.

## Every key of the file as [section, key], for the tests that remove or break them one by one.
const KEYS: Array[Array] = [
	["player", "speed"], ["player", "radius"],
	["field", "columns"], ["field", "rows"], ["field", "tile_size"],
	["hud", "message_seconds"],
]


func test_configure_valid_data_exposes_typed_getters() -> void:
	# Arrange
	var config := GameConfig.new()
	var result := DataResult.new()

	# Act
	config.configure(_valid_data(), result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_float(config.player_speed()).is_equal(300.0)
	assert_float(config.player_radius()).is_equal(12.5)
	assert_int(config.field_columns()).is_equal(6)
	assert_int(config.field_rows()).is_equal(3)
	assert_float(config.tile_size()).is_equal(64.0)
	assert_float(config.message_seconds()).is_equal(1.5)


func test_is_configured_is_false_until_a_valid_configure() -> void:
	# Arrange
	var config := GameConfig.new()
	var before: bool = config.is_configured()

	# Act
	config.configure(_valid_data(), DataResult.new())

	# Assert
	assert_bool(before).is_false()
	assert_bool(config.is_configured()).is_true()


func test_configure_every_missing_key_reports_error_naming_it() -> void:
	# Arrange
	for pair: Array in KEYS:
		var data: Dictionary = _valid_data()
		(data[pair[0]] as Dictionary).erase(pair[1])

		# Act / Assert
		_assert_error(data, "%s.%s" % [pair[0], pair[1]])


func test_configure_missing_or_non_object_section_reports_error() -> void:
	# Arrange
	for section: String in ["player", "field", "hud"]:
		var missing: Dictionary = _valid_data()
		missing.erase(section)
		var wrong_type: Dictionary = _valid_data()
		wrong_type[section] = 5

		# Act / Assert
		_assert_error(missing, section)
		_assert_error(wrong_type, section)


func test_configure_numbers_that_must_be_above_zero_reject_zero_negative_and_text() -> void:
	# Arrange
	var positive: Array[Array] = [["player", "speed"], ["player", "radius"],
			["field", "tile_size"], ["hud", "message_seconds"]]
	for pair: Array in positive:
		for bad: Variant in [0, -1.5, "3", true, null]:
			var data: Dictionary = _valid_data()
			(data[pair[0]] as Dictionary)[pair[1]] = bad

			# Act / Assert
			_assert_error(data, "%s.%s" % [pair[0], pair[1]])


func test_configure_grid_size_must_be_a_whole_number_of_at_least_one() -> void:
	# Arrange
	for key: String in ["columns", "rows"]:
		for bad: Variant in [0, -2, 2.5, "5", true, null]:
			var data: Dictionary = _valid_data()
			(data["field"] as Dictionary)[key] = bad

			# Act / Assert
			_assert_error(data, "field.%s" % key)


func test_configure_whole_float_grid_size_is_accepted() -> void:
	# Arrange: JSON gives every number back as a float.
	var data: Dictionary = _valid_data()
	(data["field"] as Dictionary)["columns"] = 5.0
	var config := GameConfig.new()

	# Act
	var result := DataResult.new()
	config.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_int(config.field_columns()).is_equal(5)


func test_configure_unknown_keys_warn_and_underscore_keys_are_ignored() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	data["_schema"] = {"doc": "ignored"}
	data["fild"] = {}
	(data["player"] as Dictionary)["spead"] = 1
	(data["player"] as Dictionary)["_note"] = "ignored"

	# Act
	var result := DataResult.new()
	GameConfig.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(2)
	assert_str(text).contains("fild")
	assert_str(text).contains("spead")


func test_configure_with_errors_keeps_the_previous_values() -> void:
	# Arrange
	var config := GameConfig.new()
	config.configure(_valid_data(), DataResult.new())
	var broken: Dictionary = _valid_data()
	(broken["player"] as Dictionary)["speed"] = 0

	# Act
	var result := DataResult.new()
	config.configure(broken, result)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_float(config.player_speed()).is_equal(300.0)


func test_configure_reports_every_problem_not_just_the_first() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(data["player"] as Dictionary)["speed"] = 0
	(data["field"] as Dictionary).erase("rows")

	# Act
	var result := DataResult.new()
	GameConfig.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.errors)
	assert_str(text).contains("player.speed")
	assert_str(text).contains("field.rows")


func test_configure_ignores_errors_already_in_the_result() -> void:
	# Arrange
	var config := GameConfig.new()
	var result := DataResult.new()
	result.add_error("crops.json", "unrelated problem")

	# Act
	config.configure(_valid_data(), result)

	# Assert
	assert_array(result.errors).has_size(1)
	assert_bool(config.is_configured()).is_true()


func test_getters_before_configure_return_zero_instead_of_a_hidden_default() -> void:
	# Arrange / Act
	var config := GameConfig.new()

	# Assert: 0 breaks the game visibly; a plausible default would hide a missing configure.
	assert_float(config.player_speed()).is_equal(0.0)
	assert_int(config.field_columns()).is_equal(0)


# --- helpers -------------------------------------------------------------------------

## Valid values that differ from the shipped file, so a test cannot pass by reading the real one.
func _valid_data() -> Dictionary:
	return {
		"player": {"speed": 300.0, "radius": 12.5},
		"field": {"columns": 6, "rows": 3, "tile_size": 64.0},
		"hud": {"message_seconds": 1.5},
	}


func _assert_error(data: Dictionary, expected_text: String) -> void:
	var result := DataResult.new()
	GameConfig.new().configure(data, result)
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains(expected_text)
