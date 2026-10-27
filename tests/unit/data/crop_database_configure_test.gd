extends GdUnitTestSuite
## Unit tests for CropDatabase.configure(data, result) (src/gameplay/farming/crop_database.gd,
## ADR-0003 rules 4, 5 and 7). Content is a hand-written Dictionary, never a file. Errors
## block startup; warnings do not.


func test_configure_valid_data_fills_the_database() -> void:
	# Arrange
	var db := CropDatabase.new()
	var result := DataResult.new()

	# Act
	db.configure(_valid_data(), result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_array(db.get_crop_ids()).contains_exactly(["ngo", "cai_xanh"])
	assert_str(db.get_crop_name("ngo")).is_equal("Ngô")
	assert_int(db.get_growth_days("ngo")).is_equal(4)
	assert_int(db.get_sell_price("ngo")).is_equal(50)
	assert_array(db.get_crop("ngo")["seasons"]).contains_exactly(["ha", "thu"])
	assert_bool(db.get_crop_color("ngo").is_equal_approx(Color("#f0c93c"))).is_true()


func test_configure_colour_with_alpha_is_kept() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 0)["color"] = "#5fbf4acc"
	var db := CropDatabase.new()

	# Act
	var result := DataResult.new()
	db.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_float(db.get_crop_color("ngo").a).is_equal_approx(0.8, 0.01)


func test_configure_missing_crops_list_reports_error() -> void:
	# Arrange / Act / Assert
	_assert_error({}, "crops")


func test_configure_empty_crops_list_reports_error() -> void:
	# Arrange / Act / Assert
	_assert_error({"crops": []}, "crops")


func test_configure_entry_that_is_not_an_object_reports_error_naming_it() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(data["crops"] as Array)[1] = 7

	# Act / Assert
	_assert_error(data, "crops[1]")


func test_configure_missing_or_empty_id_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_crop(missing, 1).erase("id")
	var empty: Dictionary = _valid_data()
	_crop(empty, 1)["id"] = ""

	# Act / Assert
	_assert_error(missing, "crops[1]")
	_assert_error(empty, "crops[1]")


func test_configure_duplicate_id_reports_error() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 1)["id"] = "ngo"

	# Act / Assert
	_assert_error(data, "duplicate")


func test_configure_growth_days_that_is_not_a_positive_whole_number_reports_error() -> void:
	# Arrange: zero, negative, fractional and string values all mean a broken crop.
	for bad: Variant in [0, -1, 2.5, "3", true, null]:
		var data: Dictionary = _valid_data()
		_crop(data, 0)["growth_days"] = bad

		# Act / Assert
		_assert_error(data, "growth_days")


func test_configure_whole_float_growth_days_is_accepted() -> void:
	# Arrange: JSON gives every number back as a float, so 3.0 is a valid day count.
	var data: Dictionary = _valid_data()
	_crop(data, 0)["growth_days"] = 3.0
	var db := CropDatabase.new()

	# Act
	var result := DataResult.new()
	db.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_int(db.get_growth_days("ngo")).is_equal(3)


func test_configure_missing_sell_price_reports_error() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 0).erase("sell_price")

	# Act / Assert
	_assert_error(data, "sell_price")


func test_configure_negative_sell_price_warns_and_clamps_to_zero() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 0)["sell_price"] = -5
	var db := CropDatabase.new()

	# Act
	var result := DataResult.new()
	db.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_str("\n".join(result.warnings)).contains("sell_price")
	assert_int(db.get_sell_price("ngo")).is_equal(0)


func test_configure_missing_empty_or_non_text_seasons_reports_error() -> void:
	# Arrange
	for bad: Variant in [null, [], "ha", [3], [""]]:
		var data: Dictionary = _valid_data()
		if bad == null:
			_crop(data, 0).erase("seasons")
		else:
			_crop(data, 0)["seasons"] = bad

		# Act / Assert
		_assert_error(data, "seasons")


func test_configure_invalid_colour_warns_and_uses_white() -> void:
	# Arrange: "red" is rejected on purpose, the file format is #rrggbb or #rrggbbaa.
	for bad: String in ["not a colour", "#12", "red", ""]:
		var data: Dictionary = _valid_data()
		_crop(data, 0)["color"] = bad
		var db := CropDatabase.new()

		# Act
		var result := DataResult.new()
		db.configure(data, result)

		# Assert
		assert_bool(result.ok()).is_true()
		assert_str("\n".join(result.warnings)).contains("color")
		assert_bool(db.get_crop_color("ngo").is_equal_approx(Color.WHITE)).is_true()


func test_configure_empty_name_warns_and_falls_back_to_the_id() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 0)["name"] = ""
	var db := CropDatabase.new()

	# Act
	var result := DataResult.new()
	db.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_str("\n".join(result.warnings)).contains("name")
	assert_str(db.get_crop_name("ngo")).is_equal("ngo")


func test_configure_unknown_keys_warn_but_underscore_keys_are_ignored() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	data["_schema"] = "documentation"
	data["crop"] = []
	_crop(data, 0)["sell_prise"] = 1
	_crop(data, 0)["_note"] = "ignored"

	# Act
	var result := DataResult.new()
	CropDatabase.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(2)
	assert_str(text).contains("crop")
	assert_str(text).contains("sell_prise")


func test_configure_with_errors_keeps_the_previous_content() -> void:
	# Arrange
	var db := CropDatabase.new()
	db.configure(_valid_data(), DataResult.new())
	var broken: Dictionary = _valid_data()
	_crop(broken, 0)["growth_days"] = 0

	# Act
	var result := DataResult.new()
	db.configure(broken, result)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_array(db.get_crop_ids()).contains_exactly(["ngo", "cai_xanh"])
	assert_int(db.get_growth_days("ngo")).is_equal(4)


func test_configure_reports_every_problem_not_just_the_first() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_crop(data, 0)["growth_days"] = 0
	_crop(data, 1).erase("sell_price")

	# Act
	var result := DataResult.new()
	CropDatabase.new().configure(data, result)

	# Assert
	assert_int(result.errors.size()).is_greater_equal(2)
	assert_str("\n".join(result.errors)).contains("crops[0]")
	assert_str("\n".join(result.errors)).contains("crops[1]")


func test_configure_ignores_errors_already_in_the_result() -> void:
	# Arrange: another data file already failed; this content is fine.
	var db := CropDatabase.new()
	var result := DataResult.new()
	result.add_error("neighbors.json", "unrelated problem")

	# Act
	db.configure(_valid_data(), result)

	# Assert
	assert_array(result.errors).has_size(1)
	assert_array(db.get_crop_ids()).contains_exactly(["ngo", "cai_xanh"])


# --- helpers -------------------------------------------------------------------------

func _valid_data() -> Dictionary:
	return {
		"crops": [
			{"id": "ngo", "name": "Ngô", "growth_days": 4, "sell_price": 50,
					"seasons": ["ha", "thu"], "color": "#f0c93c"},
			{"id": "cai_xanh", "name": "Cải xanh", "growth_days": 2, "sell_price": 15,
					"seasons": ["thu"], "color": "#5fbf4a"},
		],
	}


func _crop(data: Dictionary, index: int) -> Dictionary:
	return (data["crops"] as Array)[index] as Dictionary


func _assert_error(data: Dictionary, expected_text: String) -> void:
	var result := DataResult.new()
	CropDatabase.new().configure(data, result)
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains(expected_text)
