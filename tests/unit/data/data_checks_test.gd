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


func test_is_whole_rejects_fractions_strings_bools_and_non_finite_floats() -> void:
	# Arrange / Act / Assert
	assert_bool(DataChecks.is_whole(2.5)).is_false()
	assert_bool(DataChecks.is_whole("3")).is_false()
	assert_bool(DataChecks.is_whole(true)).is_false()
	assert_bool(DataChecks.is_whole(NAN)).is_false()
	assert_bool(DataChecks.is_whole(INF)).is_false()
	assert_bool(DataChecks.is_whole(null)).is_false()
