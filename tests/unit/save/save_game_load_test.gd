extends GdUnitTestSuite
## Unit tests for SaveGame.load_state and has_save (src/core/save/save_game.gd, ADR-0005
## rules 9 to 13). Interrupted-write states are built by creating the files by hand. Nothing
## here may rename or delete a file while loading: each such test compares a snapshot of the
## folder before and after.

const TEST_DIR: String = "user://test_save_game_load/"

var _store: SaveGame


func before_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_store = SaveGame.new(TEST_DIR)


func after_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)


func test_load_state_without_files_returns_no_save() -> void:
	# Arrange: the throwaway folder is empty.

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.NO_SAVE)
	assert_dict(result.data).is_empty()


func test_load_state_valid_main_file_returns_ok_with_data() -> void:
	# Arrange
	_write(SaveGame.SAVE_FILE, SaveTestSupport.envelope_text())

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.OK)
	assert_dict(result.data).is_equal(SaveTestSupport.valid_state())
	assert_int(result.version).is_equal(SaveGame.FORMAT_VERSION)
	assert_str(result.source).is_equal("main")


func test_load_state_corrupt_main_and_valid_backup_returns_recovered_and_touches_nothing() -> void:
	# Arrange
	_write(SaveGame.SAVE_FILE, "{ this is not json")
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "backup"))
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.RECOVERED)
	assert_str(result.source).is_equal("bak")
	assert_dict(result.data).is_equal(SaveTestSupport.valid_state("backup"))
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_empty_main_and_valid_backup_returns_recovered() -> void:
	# Arrange: a power cut can leave the main file at zero bytes.
	_write(SaveGame.SAVE_FILE, "")
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.RECOVERED)
	assert_str(result.source).is_equal("bak")


func test_load_state_missing_main_and_valid_backup_recovers_without_creating_main() -> void:
	# Arrange: an interrupted swap left only the backup.
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.RECOVERED)
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_only_valid_temp_file_returns_recovered_from_temp() -> void:
	# Arrange
	_write(SaveGame.TEMP_FILE, SaveTestSupport.envelope_text())

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.RECOVERED)
	assert_str(result.source).is_equal("tmp")


func test_load_state_temp_file_is_tried_before_the_main_file() -> void:
	# Arrange: a valid temp file is a complete newer write interrupted before the rename.
	_write(SaveGame.SAVE_FILE, SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "main"))
	_write(SaveGame.TEMP_FILE, SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "temp"))

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_str(result.source).is_equal("tmp")
	assert_dict(result.data).is_equal(SaveTestSupport.valid_state("temp"))


func test_load_state_temp_and_backup_without_main_prefers_temp() -> void:
	# Arrange
	_write(SaveGame.TEMP_FILE, SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "temp"))
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "backup"))

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_str(result.source).is_equal("tmp")


func test_load_state_lone_corrupt_temp_file_returns_no_save_and_keeps_it() -> void:
	# Arrange: an interrupted write leaves a half-written temp file; that is not a corrupt save.
	_write(SaveGame.TEMP_FILE, '{"version": 1, "da')
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.NO_SAVE)
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_corrupt_temp_is_skipped_in_favour_of_a_valid_main_file() -> void:
	# Arrange
	_write(SaveGame.TEMP_FILE, "garbage")
	_write(SaveGame.SAVE_FILE, SaveTestSupport.envelope_text())

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.OK)
	assert_str(result.source).is_equal("main")


func test_load_state_every_candidate_corrupt_returns_corrupt_and_keeps_every_file() -> void:
	# Arrange
	_write(SaveGame.SAVE_FILE, "{ broken")
	_write(SaveGame.BACKUP_FILE, "also broken")
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.CORRUPT)
	assert_dict(result.data).is_empty()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_newer_main_file_stops_before_the_backup() -> void:
	# Arrange: falling back to an older backup would let the next save overwrite a good file.
	var newer: int = SaveGame.FORMAT_VERSION + 6
	_write(SaveGame.SAVE_FILE, SaveTestSupport.envelope_text(newer))
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.NEWER_VERSION)
	assert_int(result.version).is_equal(newer)
	assert_dict(result.data).is_empty()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_unreadable_main_file_stops_before_the_backup() -> void:
	# Arrange: a folder named like the save file cannot be opened as a file.
	DirAccess.make_dir_recursive_absolute(TEST_DIR + SaveGame.SAVE_FILE)
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.UNREADABLE)
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_load_state_invalid_version_values_are_corrupt() -> void:
	# Arrange: version must be a non-negative whole number.
	var invalid_versions: Array[String] = ['"1"', "true", "1.5", "-1", "null"]

	for version_text: String in invalid_versions:
		_write(SaveGame.SAVE_FILE, '{"version": %s, "data": {}}' % version_text)

		# Act
		var result: LoadResult = _store.load_state()

		# Assert
		assert_int(result.status).is_equal(LoadResult.Status.CORRUPT)


func test_load_state_whole_float_version_is_accepted() -> void:
	# Arrange: JSON hands every number back as a float, so 1.0 must count as version 1.
	_write(SaveGame.SAVE_FILE, '{"version": 1.0, "data": {"farm": {}}}')

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.OK)
	assert_int(result.version).is_equal(1)


func test_load_state_root_not_an_object_or_data_missing_is_corrupt() -> void:
	# Arrange / Act / Assert
	_write(SaveGame.SAVE_FILE, "[1, 2, 3]")
	assert_int(_store.load_state().status).is_equal(LoadResult.Status.CORRUPT)
	_write(SaveGame.SAVE_FILE, '{"version": 1}')
	assert_int(_store.load_state().status).is_equal(LoadResult.Status.CORRUPT)


func test_load_state_accept_rejecting_main_falls_back_to_backup() -> void:
	# Arrange: a well-formed envelope that lacks the "village" section.
	var incomplete: Dictionary = SaveTestSupport.valid_state()
	incomplete.erase("village")
	_write(SaveGame.SAVE_FILE, JSON.stringify({"version": SaveGame.FORMAT_VERSION, "data": incomplete}))
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())

	# Act
	var result: LoadResult = _store.load_state(SaveTestSupport.accept_current_sections)

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.RECOVERED)
	assert_str(result.source).is_equal("bak")


func test_load_state_accept_rejecting_everything_returns_corrupt_with_the_reason() -> void:
	# Arrange
	var incomplete: Dictionary = SaveTestSupport.valid_state()
	incomplete.erase("village")
	_write(SaveGame.SAVE_FILE, JSON.stringify({"version": SaveGame.FORMAT_VERSION, "data": incomplete}))

	# Act
	var result: LoadResult = _store.load_state(SaveTestSupport.accept_current_sections)

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.CORRUPT)
	assert_str(result.message).contains("village")


func test_load_state_without_accept_does_not_check_section_names() -> void:
	# Arrange: SaveGame does not know the game's sections; only the envelope is checked.
	_write(SaveGame.SAVE_FILE, '{"version": 1, "data": {}}')

	# Act
	var result: LoadResult = _store.load_state()

	# Assert
	assert_int(result.status).is_equal(LoadResult.Status.OK)


func test_has_save_without_files_is_false() -> void:
	# Arrange / Act / Assert
	assert_bool(_store.has_save()).is_false()


func test_has_save_with_only_a_backup_is_true_and_changes_nothing() -> void:
	# Arrange
	_write(SaveGame.BACKUP_FILE, SaveTestSupport.envelope_text())
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var found: bool = _store.has_save()

	# Assert
	assert_bool(found).is_true()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func _write(file_name: String, text: String) -> void:
	SaveTestSupport.write_file(TEST_DIR, file_name, text)
