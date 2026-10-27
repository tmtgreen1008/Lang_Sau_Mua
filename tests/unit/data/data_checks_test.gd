extends GdUnitTestSuite
## Unit tests for DataChecks (src/core/data/data_checks.gd, ADR-0003 rule 7: whole numbers).


func test_is_number_accepts_ints_and_floats() -> void:
	# Arrange / Act / Assert
	assert_bool(DataChecks.is_number(1)).is_true()
	assert_bool(DataChecks.is_number(1.5)).is_true()
	assert_bool(DataChecks.is_number(0)).is_true()
	assert_bool(DataChecks.is_number(-2.5)).is_true()


func test_is_number_rejects_non_numbers_and_non_finite_floats() -> void:
	# Arrange / Act / Assert
	assert_bool(DataChecks.is_number("1")).is_false()
	assert_bool(DataChecks.is_number(true)).is_false()
	assert_bool(DataChecks.is_number(null)).is_false()
	assert_bool(DataChecks.is_number(NAN)).is_false()
	assert_bool(DataChecks.is_number(INF)).is_false()


func test_is_whole_accepts_ints_and_floats_without_a_fraction() -> void:
	# Arrange / Act / Assert: JSON turns every number into a float, so 3.0 must count.
	assert_bool(DataChecks.is_whole(3)).is_true()
	assert_bool(DataChecks.is_whole(3.0)).is_true()
	assert_bool(DataChecks.is_whole(-2.0)).is_true()
	assert_bool(DataChecks.is_whole(0)).is_true()


func test_is_valid_colour_accepts_hash_hex_with_or_without_alpha() -> void:
	# Arrange / Act / Assert: the file format is #rrggbb or #rrggbbaa (engine verified on 4.7.2).
	assert_bool(DataChecks.is_valid_colour("#5fbf4a")).is_true()
	assert_bool(DataChecks.is_valid_colour("#5fbf4acc")).is_true()
	assert_bool(DataChecks.is_valid_colour("#fff")).is_true()


func test_is_valid_colour_rejects_names_missing_hash_and_non_text() -> void:
	# Arrange / Act / Assert: "red" parses with Color.from_string but is not in the format,
	# and html_is_valid alone would accept a string with no leading hash.
	assert_bool(DataChecks.is_valid_colour("red")).is_false()
	assert_bool(DataChecks.is_valid_colour("5fbf4a")).is_false()
	assert_bool(DataChecks.is_valid_colour("")).is_false()
	assert_bool(DataChecks.is_valid_colour("#12")).is_false()
	assert_bool(DataChecks.is_valid_colour(" #5fbf4a")).is_false()
	assert_bool(DataChecks.is_valid_colour(5)).is_false()
	assert_bool(DataChecks.is_valid_colour(null)).is_false()


func test_warn_unknown_keys_warns_for_each_unknown_key_and_skips_underscore_keys() -> void:
	# Arrange
	var data: Dictionary = {"a": 1, "_note": "ignored", "typo": 2, "other": 3}
	var result := DataResult.new()

	# Act
	DataChecks.warn_unknown_keys(data, ["a"], "file.json: item", result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(2)
	assert_str("\n".join(result.warnings)).contains("file.json: item")
	assert_str("\n".join(result.warnings)).contains("typo")
	assert_str("\n".join(result.warnings)).contains("other")


func test_error_count_includes_errors_dropped_beyond_the_cap() -> void:
	# Arrange
	var result := DataResult.new()
	for i: int in DataResult.MAX_ENTRIES + 3:
		result.add_error("file.json", "error %d" % i)

	# Act / Assert
	assert_int(DataChecks.error_count(result)).is_equal(DataResult.MAX_ENTRIES + 3)


func test_is_whole_rejects_fractions_strings_bools_and_non_finite_floats() -> void:
	# Arrange / Act / Assert
	assert_bool(DataChecks.is_whole(2.5)).is_false()
	assert_bool(DataChecks.is_whole("3")).is_false()
	assert_bool(DataChecks.is_whole(true)).is_false()
	assert_bool(DataChecks.is_whole(NAN)).is_false()
	assert_bool(DataChecks.is_whole(INF)).is_false()
	assert_bool(DataChecks.is_whole(null)).is_false()
