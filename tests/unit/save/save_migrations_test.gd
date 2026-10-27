extends GdUnitTestSuite
## Unit tests for SaveMigrations and UpgradeResult (src/core/save/save_migrations.gd,
## ADR-0005 rules 3 and 7). upgrade_with() takes the step table as a parameter, so the
## multi-step behaviour is tested with synthetic steps and no change to FORMAT_VERSION.


func test_upgrade_with_current_version_returns_an_unchanged_copy() -> void:
	# Arrange
	var root: Dictionary = {"version": 1, "data": SaveTestSupport.valid_state()}

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 1, [])

	# Assert
	assert_bool(result.ok).is_true()
	assert_int(int(result.root["version"])).is_equal(1)
	assert_dict(result.root["data"] as Dictionary).is_equal(SaveTestSupport.valid_state())


func test_upgrade_with_two_steps_applies_them_in_order_and_sets_the_version() -> void:
	# Arrange
	var root: Dictionary = {"version": 1, "data": {"order": ""}}
	var table: Array[Callable] = [_append_a, _append_b]

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 3, table)

	# Assert
	assert_bool(result.ok).is_true()
	assert_int(int(result.root["version"])).is_equal(3)
	assert_str((result.root["data"] as Dictionary)["order"]).is_equal("ab")


func test_upgrade_does_not_modify_the_input() -> void:
	# Arrange
	var root: Dictionary = {"version": 1, "data": {"order": ""}}
	var table: Array[Callable] = [_append_a, _append_b]

	# Act
	SaveMigrations.upgrade_with(root, 3, table)

	# Assert
	assert_int(int(root["version"])).is_equal(1)
	assert_str((root["data"] as Dictionary)["order"]).is_equal("")


func test_upgrade_with_a_failing_step_fails_and_applies_nothing() -> void:
	# Arrange
	var root: Dictionary = {"version": 1, "data": {"order": ""}}
	var table: Array[Callable] = [_append_a, _fail_with_boom]

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 3, table)

	# Assert
	assert_bool(result.ok).is_false()
	assert_str(result.message).contains("boom")
	assert_dict(result.root).is_empty()
	assert_str((root["data"] as Dictionary)["order"]).is_equal("")


func test_upgrade_with_a_missing_step_fails() -> void:
	# Arrange: version 1 to 3 needs two steps, the table has one.
	var root: Dictionary = {"version": 1, "data": {}}
	var table: Array[Callable] = [_append_a]

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 3, table)

	# Assert
	assert_bool(result.ok).is_false()
	assert_str(result.message).contains("2")


func test_upgrade_of_a_version_newer_than_the_target_fails() -> void:
	# Arrange
	var root: Dictionary = {"version": 5, "data": {}}

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 3, [])

	# Assert
	assert_bool(result.ok).is_false()


func test_upgrade_of_a_version_below_one_fails() -> void:
	# Arrange
	var root: Dictionary = {"version": 0, "data": {}}

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade_with(root, 3, [])

	# Assert
	assert_bool(result.ok).is_false()


func test_upgrade_uses_the_shipped_table_to_reach_the_current_version() -> void:
	# Arrange
	var root: Dictionary = {"version": 1, "data": SaveTestSupport.valid_state()}

	# Act
	var result: UpgradeResult = SaveMigrations.upgrade(root)

	# Assert
	assert_bool(result.ok).is_true()
	assert_int(int(result.root["version"])).is_equal(SaveGame.FORMAT_VERSION)


func test_validate_sections_with_every_section_returns_no_problems() -> void:
	# Arrange / Act / Assert
	assert_array(SaveMigrations.validate_sections(SaveTestSupport.valid_state())).is_empty()


func test_validate_sections_names_missing_and_non_object_sections() -> void:
	# Arrange
	var data: Dictionary = SaveTestSupport.valid_state()
	data.erase("village")
	data["farm"] = 5

	# Act
	var problems: Array[String] = SaveMigrations.validate_sections(data)

	# Assert
	assert_int(problems.size()).is_equal(2)
	assert_bool(" ".join(problems).contains("village")).is_true()
	assert_bool(" ".join(problems).contains("farm")).is_true()


func test_required_sections_are_the_five_game_sections() -> void:
	# Arrange / Act / Assert: renaming one is a format change and needs a migration.
	assert_array(SaveMigrations.REQUIRED_SECTIONS).contains_exactly(
			["farm", "clock", "market", "neighbors", "village"])


func test_shipped_table_has_one_step_for_every_version_below_the_current_one() -> void:
	# Arrange / Act / Assert: raising FORMAT_VERSION without a migrate function turns this red.
	assert_int(SaveMigrations.migration_table().size()).is_equal(SaveGame.FORMAT_VERSION - 1)


# --- synthetic migration steps (each returns the new data, or a String reason on failure) ---

func _append_a(data: Dictionary) -> Variant:
	data["order"] = str(data.get("order", "")) + "a"
	return data


func _append_b(data: Dictionary) -> Variant:
	data["order"] = str(data.get("order", "")) + "b"
	return data


func _fail_with_boom(_data: Dictionary) -> Variant:
	return "boom"
