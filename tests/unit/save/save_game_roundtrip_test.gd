extends GdUnitTestSuite
## Unit tests for SaveGame (src/core/save/save_game.gd, ADR-0001, story 006).
## Every test runs against a throwaway folder passed to SaveGame.new(), so the
## player's user://savegame.json is never read, written or renamed.

const TEST_DIR: String = "user://test_save_game/"

var _store: SaveGame


func before_test() -> void:
	_remove_test_dir()
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_store = SaveGame.new(TEST_DIR)


func after_test() -> void:
	_remove_test_dir()


func test_load_state_without_file_returns_empty_and_not_failed() -> void:
	# Arrange: the throwaway folder holds no save.

	# Act
	var state: Dictionary = _store.load_state()

	# Assert
	assert_dict(state).is_empty()
	assert_bool(_store.last_load_failed).is_false()
	assert_bool(_store.has_save()).is_false()


func test_save_then_load_returns_same_state() -> void:
	# Arrange
	var state: Dictionary = _valid_state()

	# Act
	var saved: bool = _store.save(state)
	var loaded: Dictionary = SaveGame.new(TEST_DIR).load_state()

	# Assert
	assert_bool(saved).is_true()
	assert_bool(_store.has_save()).is_true()
	assert_dict(loaded).is_equal(state)


func test_save_twice_keeps_latest_and_leaves_no_temp_file() -> void:
	# Arrange
	var first: Dictionary = _valid_state()
	var second: Dictionary = _valid_state()
	second["market"] = {"note": "second"}
	_store.save(first)

	# Act
	var saved: bool = _store.save(second)
	var loaded: Dictionary = _store.load_state()

	# Assert
	assert_bool(saved).is_true()
	assert_dict(loaded).is_equal(second)
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.TEMP_FILE)).is_false()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.BACKUP_FILE)).is_false()


func test_load_state_with_invalid_json_returns_empty_and_keeps_corrupt_copy() -> void:
	# Arrange
	_write_file(SaveGame.SAVE_FILE, "{ this is not json")

	# Act
	var state: Dictionary = _store.load_state()

	# Assert
	assert_dict(state).is_empty()
	assert_bool(_store.last_load_failed).is_true()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.SAVE_FILE)).is_false()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.CORRUPT_FILE)).is_true()


func test_load_state_with_missing_section_is_rejected() -> void:
	# Arrange: a well-formed save that lacks the "village" section.
	var data: Dictionary = _valid_state()
	data.erase("village")
	_write_file(SaveGame.SAVE_FILE, JSON.stringify({"version": SaveGame.FORMAT_VERSION, "data": data}))

	# Act
	var state: Dictionary = _store.load_state()

	# Assert
	assert_dict(state).is_empty()
	assert_bool(_store.last_load_failed).is_true()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.CORRUPT_FILE)).is_true()


func test_load_state_with_unknown_version_is_rejected() -> void:
	# Arrange
	var unknown_version: int = SaveGame.FORMAT_VERSION + 1
	_write_file(SaveGame.SAVE_FILE, JSON.stringify({"version": unknown_version, "data": _valid_state()}))

	# Act
	var state: Dictionary = _store.load_state()

	# Assert
	assert_dict(state).is_empty()
	assert_bool(_store.last_load_failed).is_true()


func test_has_save_with_only_backup_restores_it() -> void:
	# Arrange: an interrupted swap left only the backup file.
	_write_file(SaveGame.BACKUP_FILE, JSON.stringify({"version": SaveGame.FORMAT_VERSION, "data": _valid_state()}))

	# Act
	var found: bool = _store.has_save()

	# Assert
	assert_bool(found).is_true()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.SAVE_FILE)).is_true()
	assert_bool(FileAccess.file_exists(TEST_DIR + SaveGame.BACKUP_FILE)).is_false()


func test_save_with_custom_dir_does_not_touch_default_save_file() -> void:
	# Arrange
	var default_save: String = SaveGame.DEFAULT_DIR + SaveGame.SAVE_FILE
	var existed_before: bool = FileAccess.file_exists(default_save)
	var modified_before: int = FileAccess.get_modified_time(default_save) if existed_before else 0

	# Act
	_store.save(_valid_state())

	# Assert
	var existed_after: bool = FileAccess.file_exists(default_save)
	var modified_after: int = FileAccess.get_modified_time(default_save) if existed_after else 0
	assert_bool(existed_after).is_equal(existed_before)
	assert_int(modified_after).is_equal(modified_before)


## Factory for a minimal valid save: every REQUIRED_SECTIONS key holds a Dictionary.
## Values are strings so the JSON round trip (numbers come back as floats) compares equal.
func _valid_state() -> Dictionary:
	var state: Dictionary = {}
	for section: String in SaveGame.REQUIRED_SECTIONS:
		state[section] = {"note": "fixture " + section}
	return state


func _write_file(file_name: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_DIR + file_name, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(text)
	file.close()


func _remove_test_dir() -> void:
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + file_name)
	DirAccess.remove_absolute(TEST_DIR)
