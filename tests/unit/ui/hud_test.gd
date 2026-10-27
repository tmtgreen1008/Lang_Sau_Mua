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


func test_setup_still_builds_the_crop_row_for_every_crop() -> void:
	# Arrange
	var hud: Hud = auto_free(Hud.new())
	var db := CropDatabase.new()
	db.configure(DataFixtures.crops(), DataResult.new())

	# Act
	hud.setup(db, DataFixtures.make_game_config())

	# Assert: the first crop of the file is selected for planting.
	assert_str(hud.current_crop_id).is_equal("ngo")
