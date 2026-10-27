extends GdUnitTestSuite
## Unit tests for DataValidator (src/core/data/data_validator.gd, ADR-0003 rule 7): the checks
## that need two data files at once. Each file is valid on its own (DataFixtures); a test
## breaks one relation and expects an error that names both ends. Every rule here is fatal.


func test_validate_consistent_data_reports_nothing() -> void:
	# Arrange / Act
	var result: DataResult = _validate()

	# Assert
	assert_array(result.errors).is_empty()
	assert_array(result.warnings).is_empty()
	assert_bool(result.ok()).is_true()


# --- seasons --------------------------------------------------------------------------

func test_validate_crop_season_missing_from_the_clock_reports_crop_and_season() -> void:
	# Arrange
	var crops: Dictionary = DataFixtures.crops()
	((crops["crops"] as Array)[2] as Dictionary)["seasons"] = ["xuan"]

	# Act
	var result: DataResult = _validate(crops)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("cai_xanh")
	assert_str("\n".join(result.errors)).contains("xuan")


func test_validate_request_season_missing_from_the_clock_reports_request_and_season() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	DataFixtures.request(neighbors, 0, 1)["season"] = "dong"

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("ba_tu_2")
	assert_str("\n".join(result.errors)).contains("dong")


# --- references to crops and dishes ---------------------------------------------------

func test_validate_required_crop_that_does_not_exist_reports_request_and_crop() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	DataFixtures.request(neighbors, 0, 1)["require"] = {"khoai": 3}

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("ba_tu_2")
	assert_str("\n".join(result.errors)).contains("khoai")


func test_validate_unlock_crop_that_does_not_exist_reports_request_and_crop() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	(DataFixtures.request(neighbors, 0, 0)["reward"] as Dictionary)["unlock_crop"] = "khoai"

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_str("\n".join(result.errors)).contains("ba_tu_1")
	assert_str("\n".join(result.errors)).contains("khoai")


func test_validate_start_unlocked_crop_that_does_not_exist_reports_it() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	neighbors["start_unlocked_crops"] = ["ngo", "khoai"]

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("start_unlocked_crops")
	assert_str("\n".join(result.errors)).contains("khoai")


func test_validate_unlock_dish_that_does_not_exist_reports_request_and_dish() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	(DataFixtures.request(neighbors, 0, 1)["reward"] as Dictionary)["unlock_dish"] = "pho"

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_str("\n".join(result.errors)).contains("ba_tu_2")
	assert_str("\n".join(result.errors)).contains("pho")


# --- requests that can never be done --------------------------------------------------

func test_validate_request_needing_a_crop_nothing_unlocks_reports_a_dead_end() -> void:
	# Arrange: chu_ba_1 no longer unlocks cai_xanh, so chu_ba_2 can never be handed over.
	var neighbors: Dictionary = DataFixtures.neighbors()
	(DataFixtures.request(neighbors, 1, 0)["reward"] as Dictionary)["unlock_crop"] = ""

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("chu_ba_2")
	assert_str("\n".join(result.errors)).contains("cai_xanh")


func test_validate_two_requests_waiting_on_each_other_report_a_dead_end() -> void:
	# Arrange: ba_tu_1 needs ca_chua, which only ba_tu_2 (after it in the same chain) unlocks.
	var neighbors: Dictionary = DataFixtures.neighbors()
	DataFixtures.request(neighbors, 0, 0)["require"] = {"ca_chua": 1}
	(DataFixtures.request(neighbors, 0, 0)["reward"] as Dictionary)["unlock_crop"] = ""
	(DataFixtures.request(neighbors, 0, 1)["reward"] as Dictionary)["unlock_crop"] = "ca_chua"

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("ba_tu_1")
	assert_str("\n".join(result.errors)).contains("ca_chua")


func test_validate_crop_unlocked_by_another_neighbor_is_reachable() -> void:
	# Arrange: ba_tu_2 needs ca_chua; make it come from chu_ba_1 instead of ba_tu_1.
	var neighbors: Dictionary = DataFixtures.neighbors()
	(DataFixtures.request(neighbors, 0, 0)["reward"] as Dictionary)["unlock_crop"] = ""
	(DataFixtures.request(neighbors, 1, 0)["reward"] as Dictionary)["unlock_crop"] = "ca_chua"
	DataFixtures.request(neighbors, 1, 1)["require"] = {"ngo": 1}

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_true()


# --- village numbers ------------------------------------------------------------------

func test_validate_piece_unlocking_after_the_last_request_reports_the_piece() -> void:
	# Arrange: only four requests exist, a piece at five can never be restored.
	var village: Dictionary = DataFixtures.village()
	((village["pieces"] as Array)[1] as Dictionary)["unlock_at"] = DataFixtures.TOTAL_REQUESTS + 1

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("house_2")


func test_validate_piece_unlocking_at_exactly_the_last_request_is_allowed() -> void:
	# Arrange
	var village: Dictionary = DataFixtures.village()
	((village["pieces"] as Array)[1] as Dictionary)["unlock_at"] = DataFixtures.TOTAL_REQUESTS

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_true()


func test_validate_first_level_that_does_not_start_at_zero_reports_error() -> void:
	# Arrange
	var village: Dictionary = DataFixtures.village()
	_level(village, 0)["min_requests"] = 1

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("min_requests")


func test_validate_level_needing_more_requests_than_exist_reports_the_level() -> void:
	# Arrange
	var village: Dictionary = DataFixtures.village()
	_level(village, 2)["min_requests"] = DataFixtures.TOTAL_REQUESTS + 1

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("level 3")


func test_validate_two_levels_with_the_same_min_requests_reports_error() -> void:
	# Arrange
	var village: Dictionary = DataFixtures.village()
	_level(village, 2)["min_requests"] = 2

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("min_requests")


func test_validate_level_numbers_that_do_not_rise_with_min_requests_report_error() -> void:
	# Arrange: level 3 would appear before level 2.
	var village: Dictionary = DataFixtures.village()
	_level(village, 1)["level"] = 3
	_level(village, 2)["level"] = 2

	# Act
	var result: DataResult = _validate(null, null, null, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("level")


# --- min_level (only when the data uses it) ------------------------------------------

func test_validate_min_level_rule_is_skipped_when_no_request_has_min_level() -> void:
	# Arrange: the shipped data has no min_level yet, so nothing may be demanded of it.
	# Act
	var result: DataResult = _validate()

	# Assert
	assert_bool(result.ok()).is_true()


func test_validate_min_levels_that_keep_every_level_reachable_are_accepted() -> void:
	# Arrange: levels start at 0, 2 and 4 requests; min_levels 1,1,1,2 give 3 requests open at
	# level 1 (needs 2 for level 2) and 4 open by level 2 (needs 4 for level 3).
	var neighbors: Dictionary = DataFixtures.neighbors()
	_set_min_levels(neighbors, [1, 1, 1, 2])

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_true()


func test_validate_min_levels_that_lock_a_village_level_forever_report_it() -> void:
	# Arrange: only one request is open at level 1 but level 2 needs two completed requests.
	var neighbors: Dictionary = DataFixtures.neighbors()
	_set_min_levels(neighbors, [1, 2, 2, 3])

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("level 2")


func test_validate_min_level_above_the_highest_village_level_reports_the_request() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	_set_min_levels(neighbors, [1, 1, 1, 9])

	# Act
	var result: DataResult = _validate(null, null, neighbors)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("chu_ba_2")


func test_validate_min_level_counts_the_wait_for_earlier_requests_of_the_same_neighbor() -> void:
	# Arrange: ba_tu_2 asks for level 1 but follows ba_tu_1 (level 3), so it opens at level 3
	# too. With level 2 at 3 requests, only chu_ba_1 and chu_ba_2 are open at level 1.
	var neighbors: Dictionary = DataFixtures.neighbors()
	_set_min_levels(neighbors, [3, 1, 1, 1])
	var village: Dictionary = DataFixtures.village()
	_level(village, 1)["min_requests"] = 3

	# Act
	var result: DataResult = _validate(null, null, neighbors, village)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("level 2")


# --- reporting ------------------------------------------------------------------------

func test_validate_reports_every_broken_rule_not_just_the_first() -> void:
	# Arrange
	var crops: Dictionary = DataFixtures.crops()
	((crops["crops"] as Array)[0] as Dictionary)["seasons"] = ["xuan"]
	var neighbors: Dictionary = DataFixtures.neighbors()
	(DataFixtures.request(neighbors, 0, 1)["reward"] as Dictionary)["unlock_dish"] = "pho"

	# Act
	var result: DataResult = _validate(crops, null, neighbors)

	# Assert
	assert_int(result.errors.size()).is_greater_equal(2)
	assert_str("\n".join(result.errors)).contains("xuan")
	assert_str("\n".join(result.errors)).contains("pho")


func test_validate_errors_name_the_file_they_came_from() -> void:
	# Arrange
	var neighbors: Dictionary = DataFixtures.neighbors()
	DataFixtures.request(neighbors, 0, 1)["season"] = "dong"
	var village: Dictionary = DataFixtures.village()
	((village["pieces"] as Array)[1] as Dictionary)["unlock_at"] = 99

	# Act
	var result: DataResult = _validate(null, null, neighbors, village)

	# Assert
	var text: String = "\n".join(result.errors)
	assert_str(text).contains("neighbors.json")
	assert_str(text).contains("village_restoration.json")


# --- helpers -------------------------------------------------------------------------

## Builds the four modules from the fixtures (a null argument means the valid default), checks
## that each is valid on its own, and runs the validator.
func _validate(crops_data: Variant = null, clock_data: Variant = null, neighbors_data: Variant = null,
		village_data: Variant = null) -> DataResult:
	var own := DataResult.new()
	var crops := CropDatabase.new()
	crops.configure(crops_data if crops_data != null else DataFixtures.crops(), own)
	var clock := DayClock.new()
	clock.configure(clock_data if clock_data != null else DataFixtures.clock(), own)
	var book := NeighborBook.new()
	book.configure(neighbors_data if neighbors_data != null else DataFixtures.neighbors(), own)
	var village := VillageProgress.new()
	village.configure(village_data if village_data != null else DataFixtures.village(), own)
	assert_array(own.errors).is_empty()
	return DataValidator.new().validate(crops, clock, book, village)


func _level(village: Dictionary, index: int) -> Dictionary:
	return (village["levels"] as Array)[index] as Dictionary


## Sets min_level on the four requests in file order (ba_tu_1, ba_tu_2, chu_ba_1, chu_ba_2).
func _set_min_levels(neighbors: Dictionary, levels: Array) -> void:
	DataFixtures.request(neighbors, 0, 0)["min_level"] = levels[0]
	DataFixtures.request(neighbors, 0, 1)["min_level"] = levels[1]
	DataFixtures.request(neighbors, 1, 0)["min_level"] = levels[2]
	DataFixtures.request(neighbors, 1, 1)["min_level"] = levels[3]
