extends GdUnitTestSuite
## Integration test: every frozen save fixture under tests/fixtures/saves/ must upgrade to the
## current format and pass the section check (ADR-0005 rule 7). A fixture is never edited
## after it is created. Raising FORMAT_VERSION without a migrate function and a new fixture
## makes this suite red.

const FIXTURE_DIR: String = "res://tests/fixtures/saves/"


func test_a_fixture_exists_for_every_format_version_ever_used() -> void:
	# Arrange / Act / Assert: guards against the loop below passing on an empty folder.
	for version: int in range(1, SaveGame.FORMAT_VERSION + 1):
		assert_bool(FileAccess.file_exists(FIXTURE_DIR + "v%d.json" % version)).is_true()


func test_every_fixture_upgrades_to_the_current_version_with_all_sections() -> void:
	# Arrange
	var checked: int = 0

	for file_name: String in DirAccess.get_files_at(FIXTURE_DIR):
		if not (file_name.begins_with("v") and file_name.ends_with(".json")):
			continue

		# Act
		var parsed: DataResult = DataLoader.read_json(FIXTURE_DIR + file_name)
		var upgraded: UpgradeResult = SaveMigrations.upgrade(parsed.data)

		# Assert
		assert_array(parsed.errors).is_empty()
		assert_bool(upgraded.ok).is_true()
		assert_int(int(upgraded.root["version"])).is_equal(SaveGame.FORMAT_VERSION)
		assert_array(SaveMigrations.validate_sections(upgraded.root["data"] as Dictionary)).is_empty()
		checked += 1

	assert_int(checked).is_greater_equal(SaveGame.FORMAT_VERSION)
