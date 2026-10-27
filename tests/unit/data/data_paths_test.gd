extends GdUnitTestSuite
## Unit tests for DataPaths (src/core/data/data_paths.gd, ADR-0003 rule 1): the one place that
## names the data files. The folder check reads assets/data, so a renamed or forgotten file
## turns this red.


func test_all_files_lists_every_data_file_once() -> void:
	# Arrange / Act
	var files: Array[String] = DataPaths.all_files()

	# Assert
	assert_array(files).contains_exactly_in_any_order([
			DataPaths.CROPS, DataPaths.TIME_CONFIG, DataPaths.NEIGHBORS,
			DataPaths.VILLAGE, DataPaths.GAME_CONFIG])


func test_every_listed_file_exists_in_the_default_folder() -> void:
	# Arrange / Act / Assert
	for file_name: String in DataPaths.all_files():
		assert_bool(FileAccess.file_exists(DataPaths.path(file_name))).is_true()


func test_every_json_file_in_the_data_folder_is_listed() -> void:
	# Arrange: derived from the folder, so a new data file cannot ship outside the list.
	var on_disk: Array[String] = []
	for file_name: String in DirAccess.get_files_at(DataPaths.DEFAULT_DIR):
		if file_name.ends_with(".json"):
			on_disk.append(file_name)

	# Act / Assert
	assert_array(on_disk).contains_exactly_in_any_order(DataPaths.all_files())


func test_path_joins_folder_and_file_with_or_without_a_trailing_slash() -> void:
	# Arrange / Act / Assert
	assert_str(DataPaths.path(DataPaths.CROPS, "user://other")).is_equal("user://other/crops.json")
	assert_str(DataPaths.path(DataPaths.CROPS, "user://other/")).is_equal("user://other/crops.json")
	assert_str(DataPaths.path(DataPaths.CROPS)).is_equal("res://assets/data/crops.json")
