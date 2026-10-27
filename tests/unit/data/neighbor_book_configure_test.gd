extends GdUnitTestSuite
## Unit tests for NeighborBook.configure(data, result) (src/gameplay/neighbors/neighbor_book.gd,
## ADR-0003 rules 4, 5 and 7). Checks one file's own structure; references to crops, seasons
## and dishes are the DataValidator's job. Content is a hand-written Dictionary.


func test_configure_valid_data_fills_the_book_and_starts_a_new_game() -> void:
	# Arrange
	var book := NeighborBook.new()
	var result := DataResult.new()

	# Act
	book.configure(_valid_data(), result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_array(book.get_neighbor_ids()).contains_exactly(["ba_tu", "chu_ba"])
	assert_str(book.get_neighbor_name("ba_tu")).is_equal("Bà Tư")
	assert_str(book.get_status("ba_tu_1")).is_equal(NeighborBook.STATE_ACTIVE)
	assert_str(book.get_status("ba_tu_2")).is_equal(NeighborBook.STATE_NOT_STARTED)
	assert_bool(book.is_crop_unlocked("ngo")).is_true()
	assert_str(book.get_dish_name("bap_luoc")).is_equal("Bắp luộc")


func test_configure_missing_or_empty_neighbors_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	missing.erase("neighbors")
	var empty: Dictionary = _valid_data()
	empty["neighbors"] = []

	# Act / Assert
	_assert_error(missing, "neighbors")
	_assert_error(empty, "neighbors")


func test_configure_neighbor_that_is_not_an_object_reports_error_naming_it() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(data["neighbors"] as Array)[1] = "chu_ba"

	# Act / Assert
	_assert_error(data, "neighbors[1]")


func test_configure_missing_empty_or_duplicate_neighbor_id_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_neighbor(missing, 1).erase("id")
	var empty: Dictionary = _valid_data()
	_neighbor(empty, 1)["id"] = ""
	var duplicate: Dictionary = _valid_data()
	_neighbor(duplicate, 1)["id"] = "ba_tu"

	# Act / Assert
	_assert_error(missing, "neighbors[1]")
	_assert_error(empty, "neighbors[1]")
	_assert_error(duplicate, "duplicate")


func test_configure_neighbor_without_requests_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_neighbor(missing, 0).erase("requests")
	var empty: Dictionary = _valid_data()
	_neighbor(empty, 0)["requests"] = []

	# Act / Assert
	_assert_error(missing, "requests")
	_assert_error(empty, "requests")


func test_configure_missing_empty_or_duplicate_request_id_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_request(missing, 0, 1).erase("id")
	var duplicate_in_neighbor: Dictionary = _valid_data()
	_request(duplicate_in_neighbor, 0, 1)["id"] = "ba_tu_1"
	var duplicate_across_neighbors: Dictionary = _valid_data()
	_request(duplicate_across_neighbors, 1, 0)["id"] = "ba_tu_1"

	# Act / Assert
	_assert_error(missing, "requests[1]")
	_assert_error(duplicate_in_neighbor, "duplicate")
	_assert_error(duplicate_across_neighbors, "duplicate")


func test_configure_missing_or_empty_season_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_request(missing, 0, 0).erase("season")
	var empty: Dictionary = _valid_data()
	_request(empty, 0, 0)["season"] = ""

	# Act / Assert
	_assert_error(missing, "season")
	_assert_error(empty, "season")


func test_configure_require_that_is_missing_empty_or_not_an_object_reports_error() -> void:
	# Arrange
	for bad: Variant in [null, {}, [], "ngo"]:
		var data: Dictionary = _valid_data()
		if bad == null:
			_request(data, 0, 0).erase("require")
		else:
			_request(data, 0, 0)["require"] = bad

		# Act / Assert
		_assert_error(data, "require")


func test_configure_required_quantity_that_is_not_a_positive_whole_number_reports_error() -> void:
	# Arrange
	for bad: Variant in [0, -2, 1.5, "2", true, null]:
		var data: Dictionary = _valid_data()
		_request(data, 0, 0)["require"] = {"ngo": bad}

		# Act / Assert
		_assert_error(data, "require")


func test_configure_whole_float_quantity_is_accepted() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_request(data, 0, 0)["require"] = {"ngo": 2.0}
	var book := NeighborBook.new()

	# Act
	var result := DataResult.new()
	book.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_int(book.get_required("ba_tu")["ngo"]).is_equal(2)


func test_configure_reward_that_is_missing_or_not_an_object_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	_request(missing, 0, 0).erase("reward")
	var wrong_type: Dictionary = _valid_data()
	_request(wrong_type, 0, 0)["reward"] = 30

	# Act / Assert
	_assert_error(missing, "reward")
	_assert_error(wrong_type, "reward")


func test_configure_reward_money_that_is_not_a_number_reports_error() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(_request(data, 0, 0)["reward"] as Dictionary)["money"] = "30"

	# Act / Assert
	_assert_error(data, "money")


func test_configure_negative_reward_money_warns_and_still_loads() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	(_request(data, 0, 0)["reward"] as Dictionary)["money"] = -5

	# Act
	var result := DataResult.new()
	NeighborBook.new().configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_str("\n".join(result.warnings)).contains("money")


func test_configure_unlock_reference_that_is_not_text_reports_error() -> void:
	# Arrange
	var crop: Dictionary = _valid_data()
	(_request(crop, 0, 0)["reward"] as Dictionary)["unlock_crop"] = 5
	var dish: Dictionary = _valid_data()
	(_request(dish, 0, 0)["reward"] as Dictionary)["unlock_dish"] = []

	# Act / Assert
	_assert_error(crop, "unlock_crop")
	_assert_error(dish, "unlock_dish")


func test_configure_empty_request_texts_warn() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_request(data, 0, 0)["offer_text"] = ""
	_request(data, 0, 0).erase("done_text")

	# Act
	var result := DataResult.new()
	NeighborBook.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_str(text).contains("offer_text")
	assert_str(text).contains("done_text")


func test_configure_missing_dishes_or_start_unlocked_crops_reports_error() -> void:
	# Arrange: both are required keys (an empty list is fine, a missing key is a typo).
	var no_dishes: Dictionary = _valid_data()
	no_dishes.erase("dishes")
	var no_start: Dictionary = _valid_data()
	no_start.erase("start_unlocked_crops")

	# Act / Assert
	_assert_error(no_dishes, "dishes")
	_assert_error(no_start, "start_unlocked_crops")


func test_configure_min_level_is_optional_but_must_be_a_non_negative_whole_number() -> void:
	# Arrange
	var valid: Dictionary = _valid_data()
	_request(valid, 0, 1)["min_level"] = 2
	var negative: Dictionary = _valid_data()
	_request(negative, 0, 1)["min_level"] = -1
	var fractional: Dictionary = _valid_data()
	_request(fractional, 0, 1)["min_level"] = 1.5

	# Act
	var result := DataResult.new()
	NeighborBook.new().configure(valid, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	_assert_error(negative, "min_level")
	_assert_error(fractional, "min_level")


func test_configure_dish_without_id_or_with_a_duplicate_id_reports_error() -> void:
	# Arrange
	var missing: Dictionary = _valid_data()
	(missing["dishes"] as Array)[0] = {"name": "Không có id"}
	var duplicate: Dictionary = _valid_data()
	(duplicate["dishes"] as Array).append({"id": "bap_luoc", "name": "Lại bắp luộc"})

	# Act / Assert
	_assert_error(missing, "dishes[0]")
	_assert_error(duplicate, "duplicate")


func test_configure_start_unlocked_crops_that_is_not_a_list_of_text_reports_error() -> void:
	# Arrange
	var not_a_list: Dictionary = _valid_data()
	not_a_list["start_unlocked_crops"] = "ngo"
	var bad_entry: Dictionary = _valid_data()
	bad_entry["start_unlocked_crops"] = ["ngo", 4]

	# Act / Assert
	_assert_error(not_a_list, "start_unlocked_crops")
	_assert_error(bad_entry, "start_unlocked_crops")


func test_configure_invalid_neighbor_colour_warns() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_neighbor(data, 0)["color"] = "blue-ish"
	var book := NeighborBook.new()

	# Act
	var result := DataResult.new()
	book.configure(data, result)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_str("\n".join(result.warnings)).contains("color")
	assert_bool(book.get_neighbor_color("ba_tu").is_equal_approx(Color.WHITE)).is_true()


func test_configure_unknown_keys_warn_at_every_level_and_underscore_keys_are_ignored() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	data["_schema"] = {"doc": "ignored"}
	data["dishs"] = []
	_neighbor(data, 0)["thank_text"] = "typo"
	_request(data, 0, 0)["mising_text"] = "typo"
	_request(data, 0, 0)["_note"] = "ignored"

	# Act
	var result := DataResult.new()
	NeighborBook.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.warnings)
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(3)
	assert_str(text).contains("dishs")
	assert_str(text).contains("thank_text")
	assert_str(text).contains("mising_text")


func test_configure_with_errors_keeps_the_previous_content() -> void:
	# Arrange
	var book := NeighborBook.new()
	book.configure(_valid_data(), DataResult.new())
	var broken: Dictionary = _valid_data()
	broken["neighbors"] = []

	# Act
	var result := DataResult.new()
	book.configure(broken, result)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_array(book.get_neighbor_ids()).contains_exactly(["ba_tu", "chu_ba"])


func test_configure_again_resets_progress_to_a_new_game() -> void:
	# Arrange
	var book := NeighborBook.new()
	book.configure(_valid_data(), DataResult.new())
	var inventory: Dictionary = {"ngo": 5}
	book.complete_request("ba_tu", inventory)

	# Act
	book.configure(_valid_data(), DataResult.new())

	# Assert
	assert_str(book.get_status("ba_tu_1")).is_equal(NeighborBook.STATE_ACTIVE)
	assert_bool(book.is_crop_unlocked("ca_chua")).is_false()


func test_configure_reports_every_problem_not_just_the_first() -> void:
	# Arrange
	var data: Dictionary = _valid_data()
	_request(data, 0, 0)["require"] = {}
	_request(data, 1, 0).erase("season")

	# Act
	var result := DataResult.new()
	NeighborBook.new().configure(data, result)

	# Assert
	var text: String = "\n".join(result.errors)
	assert_str(text).contains("neighbors[0]")
	assert_str(text).contains("neighbors[1]")


func test_configure_ignores_errors_already_in_the_result() -> void:
	# Arrange
	var book := NeighborBook.new()
	var result := DataResult.new()
	result.add_error("crops.json", "unrelated problem")

	# Act
	book.configure(_valid_data(), result)

	# Assert
	assert_array(result.errors).has_size(1)
	assert_array(book.get_neighbor_ids()).contains_exactly(["ba_tu", "chu_ba"])


# --- accessors the DataValidator needs -----------------------------------------------

func test_start_crops_and_dish_ids_are_exposed_for_cross_checks() -> void:
	# Arrange
	var book := NeighborBook.new()

	# Act
	book.configure(_valid_data(), DataResult.new())

	# Assert
	assert_array(book.get_start_crops()).contains_exactly(["ngo"])
	assert_array(book.get_dish_ids()).contains_exactly(["bap_luoc"])


# --- helpers -------------------------------------------------------------------------

func _valid_data() -> Dictionary:
	return {
		"start_unlocked_crops": ["ngo"],
		"dishes": [{"id": "bap_luoc", "name": "Bắp luộc"}],
		"neighbors": [
			{"id": "ba_tu", "name": "Bà Tư", "color": "#c0653b", "thanks_text": "Cảm ơn con.",
					"requests": [
						_valid_request("ba_tu_1", "ha", {"ngo": 2}, "ca_chua", ""),
						_valid_request("ba_tu_2", "thu", {"ca_chua": 3}, "", "bap_luoc"),
					]},
			{"id": "chu_ba", "name": "Chú Ba", "color": "#3b7ec0",
					"requests": [_valid_request("chu_ba_1", "ha", {"ngo": 3}, "", "")]},
		],
	}


func _valid_request(id: String, season: String, require: Dictionary, unlock_crop: String,
		unlock_dish: String) -> Dictionary:
	return {
		"id": id, "season": season,
		"offer_text": "Con giúp bà nhé.", "missing_text": "Chưa đủ đâu.", "done_text": "Cảm ơn con.",
		"require": require,
		"reward": {"money": 30, "unlock_crop": unlock_crop, "unlock_dish": unlock_dish},
	}


func _neighbor(data: Dictionary, index: int) -> Dictionary:
	return (data["neighbors"] as Array)[index] as Dictionary


func _request(data: Dictionary, neighbor_index: int, request_index: int) -> Dictionary:
	return (_neighbor(data, neighbor_index)["requests"] as Array)[request_index] as Dictionary


func _assert_error(data: Dictionary, expected_text: String) -> void:
	var result := DataResult.new()
	NeighborBook.new().configure(data, result)
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains(expected_text)
