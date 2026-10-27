extends GdUnitTestSuite
## Unit tests for SaveGame.save, backup_loaded_file and archive_for_new_game
## (src/core/save/save_game.gd, ADR-0005 rules 5, 6, 12, 14 to 18).
## Not covered here: a read-back that differs from the string written, and a rename that
## fails mid-swap. gdUnit cannot make FileAccess or DirAccess fail on demand; ADR-0005
## lists both under Verification Required.

const TEST_DIR: String = "user://test_save_game_write/"

var _store: SaveGame


func before_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_store = SaveGame.new(TEST_DIR)


func after_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)


# --- save ----------------------------------------------------------------------------

func test_save_then_load_returns_the_same_state() -> void:
	# Arrange
	var state: Dictionary = SaveTestSupport.valid_state()

	# Act
	var saved: bool = _store.save(state)
	var result: LoadResult = SaveGame.new(TEST_DIR).load_state()

	# Assert
	assert_bool(saved).is_true()
	assert_int(result.status).is_equal(LoadResult.Status.OK)
	assert_dict(result.data).is_equal(state)


func test_save_twice_keeps_the_previous_save_as_backup_and_leaves_no_temp_file() -> void:
	# Arrange
	var first: Dictionary = SaveTestSupport.valid_state("first")
	var second: Dictionary = SaveTestSupport.valid_state("second")
	_store.save(first)

	# Act
	var saved: bool = _store.save(second)

	# Assert
	assert_bool(saved).is_true()
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.TEMP_FILE)).is_false()
	var main: LoadResult = SaveGame.new(TEST_DIR).load_state()
	assert_dict(main.data).is_equal(second)
	var backup: Dictionary = JSON.parse_string(SaveTestSupport.read_file(TEST_DIR, SaveGame.BACKUP_FILE))
	assert_dict(backup["data"] as Dictionary).is_equal(first)


func test_save_empty_state_succeeds() -> void:
	# Arrange / Act
	var saved: bool = _store.save({})

	# Assert: SaveGame does not know the game's sections, so an empty state is still a save.
	assert_bool(saved).is_true()
	assert_int(_store.load_state().status).is_equal(LoadResult.Status.OK)


func test_save_refuses_when_the_main_file_is_from_a_newer_version() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE,
			SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION + 1))
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act: a fresh SaveGame that never loaded, so only the on-disk guard can stop it.
	var saved: bool = SaveGame.new(TEST_DIR).save(SaveTestSupport.valid_state())

	# Assert
	assert_bool(saved).is_false()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_save_refuses_when_the_main_file_cannot_be_read() -> void:
	# Arrange: a folder named like the save file.
	DirAccess.make_dir_recursive_absolute(TEST_DIR + SaveGame.SAVE_FILE)
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var saved: bool = SaveGame.new(TEST_DIR).save(SaveTestSupport.valid_state())

	# Assert
	assert_bool(saved).is_false()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_save_is_blocked_after_a_load_found_a_newer_version() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE,
			SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION + 1))
	_store.load_state()
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var saved: bool = _store.save(SaveTestSupport.valid_state())

	# Assert
	assert_bool(_store.is_write_blocked()).is_true()
	assert_bool(saved).is_false()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_save_is_blocked_after_a_load_found_only_corrupt_files() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "{ broken")
	_store.load_state()
	var before: Dictionary = SaveTestSupport.snapshot(TEST_DIR)

	# Act
	var saved: bool = _store.save(SaveTestSupport.valid_state())

	# Assert
	assert_bool(saved).is_false()
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_equal(before)


func test_save_works_again_after_archive_for_new_game() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "{ broken")
	_store.load_state()
	_store.archive_for_new_game()

	# Act
	var saved: bool = _store.save(SaveTestSupport.valid_state())

	# Assert
	assert_bool(_store.is_write_blocked()).is_false()
	assert_bool(saved).is_true()


func test_save_works_again_after_a_later_load_succeeds() -> void:
	# Arrange: blocked by a corrupt file, then the file is repaired by hand.
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "{ broken")
	_store.load_state()
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, SaveTestSupport.envelope_text())
	_store.load_state()

	# Act
	var saved: bool = _store.save(SaveTestSupport.valid_state("later"))

	# Assert
	assert_bool(saved).is_true()


func test_save_over_a_corrupt_main_file_keeps_the_good_backup() -> void:
	# Arrange: a corrupt main file must not be rotated over the good backup.
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "{ broken")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.BACKUP_FILE,
			SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "good backup"))

	# Act
	var saved: bool = _store.save(SaveTestSupport.valid_state("new"))

	# Assert
	assert_bool(saved).is_true()
	var backup: Dictionary = JSON.parse_string(SaveTestSupport.read_file(TEST_DIR, SaveGame.BACKUP_FILE))
	assert_dict(backup["data"] as Dictionary).is_equal(SaveTestSupport.valid_state("good backup"))
	assert_dict(SaveGame.new(TEST_DIR).load_state().data).is_equal(SaveTestSupport.valid_state("new"))


func test_save_with_custom_dir_does_not_touch_the_default_save_file() -> void:
	# Arrange
	var default_save: String = SaveGame.DEFAULT_DIR + SaveGame.SAVE_FILE
	var existed_before: bool = FileAccess.file_exists(default_save)
	var modified_before: int = FileAccess.get_modified_time(default_save) if existed_before else 0

	# Act
	_store.save(SaveTestSupport.valid_state())

	# Assert
	var existed_after: bool = FileAccess.file_exists(default_save)
	var modified_after: int = FileAccess.get_modified_time(default_save) if existed_after else 0
	assert_bool(existed_after).is_equal(existed_before)
	assert_int(modified_after).is_equal(modified_before)


# --- backup_loaded_file --------------------------------------------------------------

func test_backup_loaded_file_copies_the_loaded_file_to_a_versioned_backup() -> void:
	# Arrange
	var text: String = SaveTestSupport.envelope_text()
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, text)
	_store.load_state()

	# Act
	var copied: bool = _store.backup_loaded_file(1)

	# Assert
	assert_bool(copied).is_true()
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v1.bak")).is_equal(text)
	assert_str(SaveTestSupport.read_file(TEST_DIR, SaveGame.SAVE_FILE)).is_equal(text)


func test_backup_loaded_file_does_not_overwrite_an_existing_versioned_backup() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, SaveTestSupport.envelope_text())
	SaveTestSupport.write_file(TEST_DIR, "savegame.v1.bak", "keep me")
	_store.load_state()

	# Act
	var result: bool = _store.backup_loaded_file(1)

	# Assert
	assert_bool(result).is_true()
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v1.bak")).is_equal("keep me")


func test_backup_loaded_file_without_a_loaded_file_returns_false() -> void:
	# Arrange / Act / Assert
	assert_bool(_store.backup_loaded_file(1)).is_false()


func test_backup_loaded_file_copies_the_file_a_recovery_actually_used() -> void:
	# Arrange
	var backup_text: String = SaveTestSupport.envelope_text(SaveGame.FORMAT_VERSION, "backup")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "{ broken")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.BACKUP_FILE, backup_text)
	_store.load_state()

	# Act
	var copied: bool = _store.backup_loaded_file(1)

	# Assert
	assert_bool(copied).is_true()
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v1.bak")).is_equal(backup_text)


# --- archive_for_new_game ------------------------------------------------------------

func test_archive_renames_existing_files_into_a_numbered_set() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "main broken")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.TEMP_FILE, "temp broken")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.BACKUP_FILE, "backup broken")
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.corrupt.1.json")).is_equal("main broken")
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.corrupt.1.tmp.json")).is_equal("temp broken")
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.corrupt.1.bak.json")).is_equal("backup broken")
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)).is_false()
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.TEMP_FILE)).is_false()
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.BACKUP_FILE)).is_false()


func test_archive_numbers_continue_after_the_highest_existing_set() -> void:
	# Arrange
	SaveTestSupport.write_file(TEST_DIR, "savegame.corrupt.4.json", "old set")
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "main broken")
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.5.json")).is_true()


func test_archive_keeps_only_the_three_newest_sets() -> void:
	# Arrange
	for n: int in [1, 2, 3]:
		SaveTestSupport.write_file(TEST_DIR, "savegame.corrupt.%d.json" % n, "set %d" % n)
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "main broken")
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.1.json")).is_false()
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.2.json")).is_true()
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.3.json")).is_true()
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.4.json")).is_true()


func test_archive_of_a_newer_version_file_keeps_it_as_a_versioned_backup() -> void:
	# Arrange
	var newer: int = SaveGame.FORMAT_VERSION + 6
	var text: String = SaveTestSupport.envelope_text(newer)
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, text)
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v%d.bak" % newer)).is_equal(text)
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)).is_false()
	assert_bool(SaveTestSupport.exists(TEST_DIR, "savegame.corrupt.1.json")).is_false()


func test_archive_adds_a_suffix_when_the_versioned_backup_already_exists() -> void:
	# Arrange
	var newer: int = SaveGame.FORMAT_VERSION + 6
	SaveTestSupport.write_file(TEST_DIR, "savegame.v%d.bak" % newer, "old")
	var text: String = SaveTestSupport.envelope_text(newer)
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, text)
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v%d.bak" % newer)).is_equal("old")
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v%d.2.bak" % newer)).is_equal(text)


func test_archive_never_prunes_versioned_backups() -> void:
	# Arrange
	var newer: int = SaveGame.FORMAT_VERSION + 6
	SaveTestSupport.write_file(TEST_DIR, "savegame.v%d.bak" % newer, "precious")
	for n: int in [1, 2, 3]:
		SaveTestSupport.write_file(TEST_DIR, "savegame.corrupt.%d.json" % n, "set %d" % n)
	SaveTestSupport.write_file(TEST_DIR, SaveGame.SAVE_FILE, "main broken")
	_store.load_state()

	# Act
	_store.archive_for_new_game()

	# Assert
	assert_str(SaveTestSupport.read_file(TEST_DIR, "savegame.v%d.bak" % newer)).is_equal("precious")


func test_archive_with_no_files_changes_nothing_and_reenables_saving() -> void:
	# Arrange / Act
	_store.archive_for_new_game()

	# Assert
	assert_dict(SaveTestSupport.snapshot(TEST_DIR)).is_empty()
	assert_bool(_store.is_write_blocked()).is_false()
