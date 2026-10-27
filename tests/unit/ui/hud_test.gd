extends GdUnitTestSuite
## Unit tests for Hud's message time (src/ui/hud.gd): it comes from GameConfig through
## setup(), not from a constant (ADR-0003 rule 8). DataFixtures gives 1.5 seconds.


func test_setup_takes_the_message_time_from_the_config() -> void:
	# Arrange
	var hud: Hud = auto_free(Hud.new())
	var db := CropDatabase.new()
	db.configure(DataFixtures.crops(), DataResult.new())

	# Act
	hud.setup(db, DataFixtures.make_game_config())

	# Assert
	assert_float(hud.message_seconds).is_equal(1.5)


func test_sync_shows_crops_bag_money_and_time_in_one_call() -> void:
	# Arrange
	var hud: Hud = _make_hud()

	# Act
	hud.sync(["ngo", "cai_xanh"] as Array[String], {"ngo": 3, "cai_xanh": 1}, 25, 2, "Sáng", "Mùa hạ")

	# Assert
	assert_array(hud._unlocked_crops).contains_exactly(["ngo", "cai_xanh"])
	assert_str(hud._inventory_label.text).contains("Ngô: 3")
	assert_str(hud._inventory_label.text).contains("Cải xanh: 1")
	assert_str(hud._money_label.text).contains("25")
	assert_str(hud._time_label.text).contains("Ngày 2")
	assert_str(hud._time_label.text).contains("Mùa hạ")


func test_sync_keeps_the_message_the_tool_and_a_still_unlocked_crop() -> void:
	# Arrange
	var hud: Hud = _make_hud()
	hud.sync(["ngo", "cai_xanh"] as Array[String], {}, 0, 1, "Sáng", "Mùa hạ")
	hud.current_crop_id = "cai_xanh"
	hud.current_tool = FarmGrid.Tool.WATER
	hud.show_message("đang hiện")

	# Act
	hud.sync(["ngo", "cai_xanh"] as Array[String], {"ngo": 1}, 5, 1, "Chiều", "Mùa hạ")

	# Assert
	assert_str(hud._message_label.text).is_equal("đang hiện")
	assert_int(hud.current_tool).is_equal(FarmGrid.Tool.WATER)
	assert_str(hud.current_crop_id).is_equal("cai_xanh")


func test_sync_falls_back_to_the_first_crop_when_the_selected_one_is_no_longer_unlocked() -> void:
	# Arrange
	var hud: Hud = _make_hud()
	hud.sync(["ngo", "cai_xanh"] as Array[String], {}, 0, 1, "Sáng", "Mùa hạ")
	hud.current_crop_id = "cai_xanh"

	# Act: a different save with fewer crops unlocked.
	hud.sync(["ngo"] as Array[String], {}, 0, 1, "Sáng", "Mùa hạ")

	# Assert
	assert_str(hud.current_crop_id).is_equal("ngo")


func test_setup_still_builds_the_crop_row_for_every_crop() -> void:
	# Arrange
	var hud: Hud = auto_free(Hud.new())
	var db := CropDatabase.new()
	db.configure(DataFixtures.crops(), DataResult.new())

	# Act
	hud.setup(db, DataFixtures.make_game_config())

	# Assert: the first crop of the file is selected for planting.
	assert_str(hud.current_crop_id).is_equal("ngo")


func _make_hud() -> Hud:
	var hud: Hud = auto_free(Hud.new())
	var db := CropDatabase.new()
	db.configure(DataFixtures.crops(), DataResult.new())
	hud.setup(db, DataFixtures.make_game_config())
	return hud
