class_name SaveTestSupport
extends RefCounted
## Shared helpers for the SaveGame test suites: a valid state factory and throwaway-folder
## file helpers. Every suite points SaveGame at its own folder under user://, so the
## player's user://savegame.json is never read, written or renamed.


## Factory for a minimal valid save: every required section holds a Dictionary. Values are
## strings so the JSON round trip (numbers come back as floats) compares equal.
static func valid_state(tag: String = "fixture") -> Dictionary:
	var state: Dictionary = {}
	for section: String in SaveMigrations.REQUIRED_SECTIONS:
		state[section] = {"note": tag + " " + section}
	return state


## JSON text of a well-formed save envelope.
static func envelope_text(version: int = SaveGame.FORMAT_VERSION, tag: String = "fixture") -> String:
	return JSON.stringify({"version": version, "data": valid_state(tag)})


static func write_file(dir: String, file_name: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(dir + file_name, FileAccess.WRITE)
	assert(file != null, "cannot write test file " + file_name)
	file.store_string(text)
	file.close()


static func read_file(dir: String, file_name: String) -> String:
	return FileAccess.get_file_as_string(dir + file_name)


static func exists(dir: String, file_name: String) -> bool:
	return FileAccess.file_exists(dir + file_name)


## Every file (name to text) and folder (name to true) in [param dir], to compare before and
## after an operation that must leave the folder alone.
static func snapshot(dir: String) -> Dictionary:
	var snap: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(dir):
		snap[file_name] = FileAccess.get_file_as_string(dir + file_name)
	for folder_name: String in DirAccess.get_directories_at(dir):
		snap["dir:" + folder_name] = true
	return snap


## Deletes [param dir] and everything in it (files and one level of folders).
static func remove_dir(dir: String) -> void:
	for file_name: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + file_name)
	for folder_name: String in DirAccess.get_directories_at(dir):
		DirAccess.remove_absolute(dir + folder_name)
	DirAccess.remove_absolute(dir)


## accept callback for SaveGame.load_state, the way Main will inject it: "" when the
## sections of the current format are all present, else the reason.
static func accept_current_sections(root: Dictionary) -> String:
	var problems: Array[String] = SaveMigrations.validate_sections(root.get("data", {}))
	return "" if problems.is_empty() else "bad sections: " + ", ".join(problems)
