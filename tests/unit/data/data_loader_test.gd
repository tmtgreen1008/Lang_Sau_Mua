extends GdUnitTestSuite
## Unit tests for DataLoader (src/core/data/data_loader.gd, ADR-0003 rule 2).
## parse_text tests use hand-written strings; the read_json tests use a throwaway
## folder so nothing under assets/data/ or the player's save is touched.

const TEST_DIR: String = "user://test_data_loader/"
const BOM: String = "﻿"


func before_test() -> void:
	_remove_test_dir()
	DirAccess.make_dir_recursive_absolute(TEST_DIR)


func after_test() -> void:
	_remove_test_dir()


func test_parse_text_valid_object_returns_data() -> void:
	# Arrange
	var text: String = '{"crops": [{"id": "carrot"}], "_schema": "doc"}'

	# Act
	var result: DataResult = DataLoader.parse_text(text, "crops.json")

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).is_empty()
	assert_array(result.data["crops"]).has_size(1)
	assert_str(result.data["_schema"]).is_equal("doc")


func test_parse_text_invalid_json_reports_source_line_and_reason() -> void:
	# Arrange: the stray "}" after the colon is on line 3.
	var text: String = '{\n"a": 1,\n"b": }'

	# Act
	var result: DataResult = DataLoader.parse_text(text, "crops.json")

	# Assert
	assert_bool(result.ok()).is_false()
	assert_array(result.errors).has_size(1)
	assert_str(result.errors[0]).contains("crops.json")
	assert_str(result.errors[0]).contains("line 3")
	assert_dict(result.data).is_empty()


func test_parse_text_array_root_reports_root_must_be_object() -> void:
	# Arrange
	var text: String = '[1, 2, 3]'

	# Act
	var result: DataResult = DataLoader.parse_text(text, "crops.json")

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("crops.json")
	assert_str(result.errors[0]).contains("root must be an object")


func test_parse_text_empty_text_reports_error_without_crashing() -> void:
	# Arrange / Act
	var result: DataResult = DataLoader.parse_text("", "crops.json")

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("crops.json")


func test_parse_text_leading_bom_is_stripped_with_one_warning() -> void:
	# Arrange
	var text: String = BOM + '{"a": 1}'

	# Act
	var result: DataResult = DataLoader.parse_text(text, "crops.json")

	# Assert
	assert_bool(result.ok()).is_true()
	assert_array(result.warnings).has_size(1)
	assert_str(result.warnings[0]).contains("BOM")
	assert_int(int(result.data["a"])).is_equal(1)


func test_read_json_missing_file_reports_error_naming_the_path() -> void:
	# Arrange
	var path: String = TEST_DIR + "missing.json"

	# Act
	var result: DataResult = DataLoader.read_json(path)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains(path)


func test_read_json_valid_file_returns_data() -> void:
	# Arrange
	var path: String = TEST_DIR + "good.json"
	_write_file(path, '{"seconds": 30}')

	# Act
	var result: DataResult = DataLoader.read_json(path)

	# Assert
	assert_bool(result.ok()).is_true()
	assert_int(int(result.data["seconds"])).is_equal(30)


func test_read_json_broken_file_names_path_and_line() -> void:
	# Arrange
	var path: String = TEST_DIR + "broken.json"
	_write_file(path, '{\n"a": 1,\n"b": }')

	# Act
	var result: DataResult = DataLoader.read_json(path)

	# Assert
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains(path)
	assert_str(result.errors[0]).contains("line 3")


func _write_file(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove_test_dir() -> void:
	var dir: DirAccess = DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)
