extends GdUnitTestSuite
## Integration test: the data files under assets/data/ must pass every check (ADR-0003 rule 10),
## each on its own and against each other, with no errors and no warnings. A typo in a content
## file turns CI red here instead of showing up as a broken game. Reads the real files.


func test_shipped_data_files_pass_their_own_checks_without_warnings() -> void:
	# Arrange
	var result := DataResult.new()

	# Act
	_load_all(result)

	# Assert
	assert_array(result.errors).is_empty()
	assert_array(result.warnings).is_empty()


func test_shipped_data_files_agree_with_each_other() -> void:
	# Arrange
	var result := DataResult.new()
	var modules: Dictionary = _load_all(result)

	# Act
	var cross: DataResult = DataValidator.new().validate(modules["crops"], modules["clock"],
			modules["book"], modules["village"])

	# Assert
	assert_array(cross.errors).is_empty()
	assert_array(cross.warnings).is_empty()


func test_shipped_data_is_not_empty() -> void:
	# Arrange / Act
	var modules: Dictionary = _load_all(DataResult.new())

	# Assert: guards against the checks above passing because nothing was loaded.
	assert_int((modules["crops"] as CropDatabase).get_crop_ids().size()).is_greater(0)
	assert_int((modules["book"] as NeighborBook).get_neighbor_ids().size()).is_greater(0)
	assert_int((modules["village"] as VillageProgress).get_piece_defs().size()).is_greater(0)
	assert_int((modules["clock"] as DayClock).get_season_ids().size()).is_greater(0)


func test_shipped_game_config_keeps_the_values_that_were_written_in_the_code() -> void:
	# Arrange: ADR-0003 rule 8 moved these numbers out of the code without changing them. They
	# are written here as the values the game shipped with; changing one in game_config.json is a
	# deliberate balance change and updates this test with it.
	var config: GameConfig = _load_all(DataResult.new())["config"] as GameConfig

	# Act / Assert
	assert_bool(config.is_configured()).is_true()
	assert_float(config.player_speed()).is_equal(360.0)
	assert_float(config.player_radius()).is_equal(18.0)
	assert_int(config.field_columns()).is_equal(5)
	assert_int(config.field_rows()).is_equal(4)
	assert_float(config.tile_size()).is_equal(80.0)
	assert_float(config.message_seconds()).is_equal(2.5)


func test_load_from_file_wrappers_accept_the_shipped_files() -> void:
	# Arrange / Act / Assert: Main still loads through these until it gathers results itself.
	assert_bool(CropDatabase.new().load_from_file(DataPaths.path(DataPaths.CROPS))).is_true()
	assert_bool(DayClock.new().load_from_file(DataPaths.path(DataPaths.TIME_CONFIG))).is_true()
	assert_bool(NeighborBook.new().load_from_file(DataPaths.path(DataPaths.NEIGHBORS))).is_true()
	assert_bool(VillageProgress.new().load_from_file(DataPaths.path(DataPaths.VILLAGE))).is_true()


## Reads and configures every data file, collecting each error and warning in [param result].
func _load_all(result: DataResult) -> Dictionary:
	var crops := CropDatabase.new()
	var clock := DayClock.new()
	var book := NeighborBook.new()
	var village := VillageProgress.new()
	var config := GameConfig.new()
	var targets: Array[Array] = [[DataPaths.CROPS, crops], [DataPaths.TIME_CONFIG, clock],
			[DataPaths.NEIGHBORS, book], [DataPaths.VILLAGE, village], [DataPaths.GAME_CONFIG, config]]
	assert_int(targets.size()).is_equal(DataPaths.all_files().size())
	for target: Array in targets:
		var read: DataResult = DataLoader.read_json(DataPaths.path(target[0] as String))
		(target[1] as Object).call("configure", read.data, read)
		result.errors.append_array(read.errors)
		result.warnings.append_array(read.warnings)
	return {"crops": crops, "clock": clock, "book": book, "village": village, "config": config}
