extends GdUnitTestSuite
## Unit tests for VillageProgress.configure(data, result) (src/gameplay/village/village_progress.gd,
## ADR-0003 rules 4, 5 and 7). Checks this file's own structure; how the piece and level
## numbers relate to the number of requests is the DataValidator's job.


func test_configure_valid_data_fills_levels_pieces_and_effect() -> void:
	# Arrange
	var village := VillageProgress.new()
	var result := DataResult.new()

	# Act
	village.configure(_valid_data(), result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_int(village.get_level()).is_equal(1)
	assert_str(village.get_level_name()).is_equal("Hoang tàn")
	assert_array(village.get_piece_defs()).has_size(2)
	assert_str(village.get_piece_name("house_1")).is_equal("một ngôi nhà")
	assert_float(float(village.get_effect()["duration"])).is_equal(1.0)
	assert_array(village.get_level_defs()).has_size(2)


func test_configure_sorts_levels_by_min_requests() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(data["levels"] as Array).reverse()
	var village := VillageProgress.new()

	# Act
	village.configure(data, DataResult.new())

	# Assert
	assert_int(int(village.get_level_defs()[0]["min_requests"])).is_equal(0)


func test_configure_effect_that_is_missing_or_out_of_range_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	missing.erase("effect")
	var zero_duration: Dictionary = _valid_data()
	(zero_duration["effect"] as Dictionary)["duration"] = 0.0
	var flash_too_big: Dictionary = _valid_data()
	(flash_too_big["effect"] as Dictionary)["flash"] = 1.5
	var negative_pulse: Dictionary = _valid_data()
	(negative_pulse["effect"] as Dictionary)["pulse_scale"] = -0.1
	var text_duration: Dictionary = _valid_data()
	(text_duration["effect"] as Dictionary)["duration"] = "1"

	# Act / Assert
	_assert_error(missing, "effect")
	_assert_error(zero_duration, "duration")
	_assert_error(flash_too_big, "flash")
	_assert_error(negative_pulse, "pulse_scale")
	_assert_error(text_duration, "duration")


func test_configure_missing_or_empty_levels_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	missing.erase("levels")
	var empty: Dictionary = _valid_data()
	empty["levels"] = []

	# Act / Assert
	_assert_error(missing, "levels")
	_assert_error(empty, "levels")


func test_configure_level_with_a_bad_number_or_duplicate_reports_error() -> void:
	# Arrange
	var missing_level: Dictionary = _valid_data()
	_level(missing_level, 1).erase("level")
	var duplicate_level: Dictionary = _valid_data()
	_level(duplicate_level, 1)["level"] = 1
	var negative_min: Dictionary = _valid_data()
	_level(negative_min, 1)["min_requests"] = -1
	var fractional_min: Dictionary = _valid_data()
	_level(fractional_min, 1)["min_requests"] = 1.5

	# Act / Assert
	_assert_error(missing_level, "levels[1]")
	_assert_error(duplicate_level, "duplicate")
	_assert_error(negative_min, "min_requests")
	_assert_error(fractional_min, "min_requests")


func test_configure_level_with_a_bad_tint_or_empty_name_warns() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_level(data, 0)["ground_tint"] = "brown"
	_level(data, 1)["name"] = ""

	# Act
	var result := DataResult.new()
	VillageProgress.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_str(text).contains("ground_tint")
	assert_str(text).contains("name")


func test_configure_missing_or_empty_pieces_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	missing.erase("pieces")
	var empty: Dictionary = _valid_data()
	empty["pieces"] = []

	# Act / Assert
	_assert_error(missing, "pieces")
	_assert_error(empty, "pieces")


func test_configure_piece_that_is_not_an_object_or_has_no_id_reports_error() -> void:
	# Arrange
	var not_an_object: Dictionary = _valid_data()
	(not_an_object["pieces"] as Array)[1] = 3
	var no_id: Dictionary = _valid_data()
	_piece(no_id, 1).erase("id")

	# Act / Assert
	_assert_error(not_an_object, "pieces[1]")
	_assert_error(no_id, "pieces[1]")


func test_configure_duplicate_piece_id_reports_error() -> void:
	# Arrange: a duplicate piece is fatal (GDD village-restoration), not skipped.
	var data: Dictionary = _valid_data()
	_piece(data, 1)["id"] = "house_1"

	# Act / Assert
	_assert_error(data, "duplicate")


func test_configure_unlock_at_that_is_not_a_positive_whole_number_reports_error() -> void:
	# Arrange
	for bad: Variant in [0, -1, 1.5, "1", null]:
		var data: Dictionary = _valid_data()
		_piece(data, 0)["unlock_at"] = bad

		# Act / Assert
		_assert_error(data, "unlock_at")


func test_configure_origin_and_size_must_be_two_numbers_and_size_positive() -> void:
	# Arrange
	var origin_short: Dictionary = _valid_data()
	_piece(origin_short, 0)["origin"] = [1]
	var origin_text: Dictionary = _valid_data()
	_piece(origin_text, 0)["origin"] = ["a", "b"]
	var size_zero: Dictionary = _valid_data()
	_piece(size_zero, 0)["size"] = [0, 10]
	var size_missing: Dictionary = _valid_data()
	_piece(size_missing, 0).erase("size")

	# Act / Assert
	_assert_error(origin_short, "origin")
	_assert_error(origin_text, "origin")
	_assert_error(size_zero, "size")
	_assert_error(size_missing, "size")


func test_configure_piece_without_shapes_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_piece(missing, 0).erase("shapes")
	var empty: Dictionary = _valid_data()
	_piece(empty, 0)["shapes"] = []

	# Act / Assert
	_assert_error(missing, "shapes")
	_assert_error(empty, "shapes")


func test_configure_shape_with_an_unknown_kind_or_wrong_geometry_reports_error() -> void:
	# Arrange
	var unknown_kind: Dictionary = _valid_data()
	_shape(unknown_kind, 0, 0)["kind"] = "star"
	var rect_short: Dictionary = _valid_data()
	_shape(rect_short, 0, 0)["ruined"] = {"g": [0, 0, 10], "color": "#4a3524"}
	var ellipse_long: Dictionary = _valid_data()
	_shape(ellipse_long, 0, 1)["restored"] = {"g": [1, 2, 3, 4, 5], "color": "#ffffff"}
	var poly_odd: Dictionary = _valid_data()
	_shape(poly_odd, 0, 2)["ruined"] = {"g": [0, 0, 10, 0, 5, 8, 4], "color": "#4a3524"}
	var poly_two_points: Dictionary = _valid_data()
	_shape(poly_two_points, 0, 2)["ruined"] = {"g": [0, 0, 10, 0], "color": "#4a3524"}
	var text_number: Dictionary = _valid_data()
	_shape(text_number, 0, 0)["ruined"] = {"g": [0, 0, "10", 10], "color": "#4a3524"}

	# Act / Assert
	_assert_error(unknown_kind, "kind")
	_assert_error(rect_short, "shapes[0]")
	_assert_error(ellipse_long, "shapes[1]")
	_assert_error(poly_odd, "shapes[2]")
	_assert_error(poly_two_points, "shapes[2]")
	_assert_error(text_number, "shapes[0]")


func test_configure_shape_with_neither_side_reports_error() -> void:
	# Arrange: both sides null means there is nothing to draw.
	var data: Dictionary = _valid_data()
	_shape(data, 0, 0)["ruined"] = null
	_shape(data, 0, 0)["restored"] = null

	# Act / Assert
	_assert_error(data, "shapes[0]")


func test_configure_shape_colour_that_is_invalid_warns() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(_shape(data, 0, 0)["ruined"] as Dictionary)["color"] = "dark"

	# Act
	var result := DataResult.new()
	VillageProgress.new().configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_str("\n".join(result.warnings)).contains("color")


func test_configure_unknown_keys_warn_and_underscore_keys_are_ignored() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	data["_schema"] = {"doc": "ignored"}
	data["pices"] = []
	_piece(data, 0)["unlock_att"] = 3

	# Act
	var result := DataResult.new()
	VillageProgress.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(2)
	assert_str(text).contains("pices")
	assert_str(text).contains("unlock_att")


func test_configure_with_errors_keeps_the_previous_content() -> void:
	# Arrange
	var village := VillageProgress.new()
	village.configure(_valid_data(), DataResult.new())
	var broken: Dictionary = _valid_data()
	broken["pieces"] = []

	# Act
	var result := DataResult.new()
	village.configure(broken, result)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_array(village.get_piece_defs()).has_size(2)


func test_configure_again_resets_progress_to_zero() -> void:
	# Arrange
	var village := VillageProgress.new()
	village.configure(_valid_data(), DataResult.new())
	village.from_dict({"completed_requests": 3})

	# Act
	village.configure(_valid_data(), DataResult.new())

	# Assert
	assert_int(village.get_completed_count()).is_equal(0)
	assert_int(village.get_level()).is_equal(1)


func test_configure_reports_every_problem_not_just_the_first() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(data["effect"] as Dictionary)["duration"] = 0.0
	_piece(data, 1)["unlock_at"] = 0

	# Act
	var result := DataResult.new()
	VillageProgress.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.errors)
	assert_str(text).contains("duration")
	assert_str(text).contains("pieces[1]")


func test_configure_ignores_errors_already_in_the_result() -> void:
	# Arrange
	var village := VillageProgress.new()
	var result := DataResult.new()
	result.add_error("crops.json", "unrelated problem")

	# Act
	village.configure(_valid_data(), result)

	# Assert
	assert_array(result.errors).has_size(1)
	assert_array(village.get_piece_defs()).has_size(2)


# --- helpers -------------------------------------------------------------------------

func _valid_data() -> Dictionary:
	return {
		"effect": {"duration": 1.0, "flash": 0.45, "pulse_scale": 0.08},
		"levels": [
			{"level": 1, "min_requests": 0, "name": "Hoang tàn", "ground_tint": "#5a4630b0"},
			{"level": 2, "min_requests": 2, "name": "Đang hồi sinh", "ground_tint": "#d8b86020"},
		],
		"pieces": [
			{"id": "house_1", "name": "một ngôi nhà", "unlock_at": 1, "origin": [-352, 196],
					"size": [100, 96], "shapes": _valid_shapes()},
			{"id": "well_1", "name": "cái giếng", "unlock_at": 2, "origin": [10, 20],
					"size": [40, 40], "shapes": _valid_shapes()},
		],
	}


func _valid_shapes() -> Array:
	return [
		{"kind": "rect", "ruined": {"g": [0, 0, 10, 10], "color": "#4a3524"},
				"restored": {"g": [0, 0, 12, 12], "color": "#a0522d"}},
		{"kind": "ellipse", "ruined": null, "restored": {"g": [5, 5, 3, 3], "color": "#ffffff"}},
		{"kind": "poly", "ruined": {"g": [0, 0, 10, 0, 5, 8], "color": "#4a3524"}, "restored": null},
	]


func _level(data: Dictionary, index: int) -> Dictionary:
	return (data["levels"] as Array)[index] as Dictionary


func _piece(data: Dictionary, index: int) -> Dictionary:
	return (data["pieces"] as Array)[index] as Dictionary


func _shape(data: Dictionary, piece_index: int, shape_index: int) -> Dictionary:
	return (_piece(data, piece_index)["shapes"] as Array)[shape_index] as Dictionary


func _assert_error(data: Dictionary, expected_text: String) -> void:
	var result := DataResult.new()
	VillageProgress.new().configure(data, result)
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains(expected_text)
