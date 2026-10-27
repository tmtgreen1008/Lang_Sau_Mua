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


func test_absorb_appends_the_other_errors_and_warnings_in_order() -> void:
	# Arrange
	var target := DataResult.new()
	target.add_error("a.json", "first")
	var other := DataResult.new()
	other.add_error("b.json", "second")
	other.add_warning("b.json", "careful")

	# Act
	target.absorb(other)

	# Assert
	assert_array(target.errors).has_size(2)
	assert_str(target.errors[0]).contains("a.json")
	assert_str(target.errors[1]).contains("b.json")
	assert_array(target.warnings).has_size(1)
	assert_bool(target.ok()).is_false()


func test_absorb_keeps_the_cap_and_counts_what_does_not_fit() -> void:
	# Arrange: the target already holds 198 errors, the other brings 5.
	var target := DataResult.new()
	for i: int in DataResult.MAX_ENTRIES - 2:
		target.add_error("a.json", "e%d" % i)
	var other := DataResult.new()
	for i: int in 5:
		other.add_error("b.json", "e%d" % i)

	# Act
	target.absorb(other)

	# Assert
	assert_array(target.errors).has_size(DataResult.MAX_ENTRIES)
	assert_int(target.dropped_errors).is_equal(3)


func test_absorb_adds_the_errors_the_other_result_had_already_dropped() -> void:
	# Arrange
	var other := DataResult.new()
	for i: int in DataResult.MAX_ENTRIES + 4:
		other.add_error("b.json", "e%d" % i)
	var target := DataResult.new()

	# Act
	target.absorb(other)

	# Assert
	assert_array(target.errors).has_size(DataResult.MAX_ENTRIES)
	assert_int(target.dropped_errors).is_equal(4)


func test_absorb_a_clean_result_changes_nothing() -> void:
	# Arrange
	var target := DataResult.new()
	target.add_warning("a.json", "careful")

	# Act
	target.absorb(DataResult.new())

	# Assert
	assert_bool(target.ok()).is_true()
	assert_array(target.warnings).has_size(1)


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
