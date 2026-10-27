extends GdUnitTestSuite
## Unit tests for DataResult (src/core/data/data_result.gd, ADR-0003 rule 3).


func test_new_result_is_ok_and_empty() -> void:
	# Arrange / Act
	var result := DataResult.new()

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.errors).is_empty()
	assert_array(result.warnings).is_empty()
	assert_dict(result.data).is_empty()


func test_add_error_makes_result_not_ok_and_keeps_location_and_reason() -> void:
	# Arrange
	var result := DataResult.new()

	# Act
	result.add_error("crops.json: crops[2]", "growth_days must be greater than 0")

	# Assert
	assert_bool(result.ok()).is_false()
	assert_array(result.errors).has_size(1)
	assert_str(result.errors[0]).contains("crops.json: crops[2]")
	assert_str(result.errors[0]).contains("growth_days must be greater than 0")


func test_add_warning_keeps_result_ok() -> void:
	# Arrange
	var result := DataResult.new()

	# Act
	result.add_warning("crops.json: crops[0].color", "not a valid colour, using the default")

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(1)
	assert_str(result.warnings[0]).contains("crops[0].color")


func test_errors_beyond_the_cap_are_counted_not_stored() -> void:
	# Arrange
	var result := DataResult.new()
	var extra: int = 5

	# Act
	for i: int in DataResult.MAX_ENTRIES + extra:
		result.add_error("file.json", "error %d" % i)

	# Assert
	assert_array(result.errors).has_size(DataResult.MAX_ENTRIES)
	assert_int(result.dropped_errors).is_equal(extra)
	assert_bool(result.ok()).is_false()


func test_warnings_beyond_the_cap_are_counted_not_stored() -> void:
	# Arrange
	var result := DataResult.new()
	var extra: int = 5

	# Act
	for i: int in DataResult.MAX_ENTRIES + extra:
		result.add_warning("file.json", "warning %d" % i)

	# Assert
	assert_array(result.warnings).has_size(DataResult.MAX_ENTRIES)
	assert_int(result.dropped_warnings).is_equal(extra)
	assert_bool(result.ok()).is_true()
