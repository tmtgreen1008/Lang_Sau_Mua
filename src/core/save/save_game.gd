class_name SaveGame
extends RefCounted
## Reads and writes the single save file. Knows nothing about the game systems: it only
## stores the Dictionary it is given. Implements story 006 (design/game-brief.md,
## MVP feature 6). Not thread-safe; call it from the main thread only.
##
## File: JSON text in user://savegame.json, root {"version": 1, "data": {...}}.
## A save is written to a temp file first and then renamed over the real file, so an
## interrupted write never destroys the previous good save. An unusable file is kept
## as user://savegame.corrupt.json and load_state() returns an empty Dictionary.
##
## Usage:
##   var store := SaveGame.new()            # or SaveGame.new("user://some_folder/") in tests
##   store.save({"farm": grid.to_dict(), "clock": clock.to_dict(), ...})
##   if store.has_save():
##       var state: Dictionary = store.load_state()   # {} when nothing usable
##       if state.is_empty() and store.last_load_failed: ...

const DEFAULT_DIR: String = "user://"
const SAVE_FILE: String = "savegame.json"
const TEMP_FILE: String = "savegame.tmp"
const BACKUP_FILE: String = "savegame.bak"
const CORRUPT_FILE: String = "savegame.corrupt.json"
## Version written to new saves; only this version is read back.
const FORMAT_VERSION: int = 1
## Sections that must exist (as Dictionaries) in "data" for a save to be usable.
const REQUIRED_SECTIONS: Array[String] = ["farm", "clock", "market", "neighbors", "village"]

## True when the last [method load_state] found a file but could not use it.
var last_load_failed: bool = false

var _save_path: String
var _temp_path: String
var _backup_path: String
var _corrupt_path: String


## [param base_dir] is the folder that holds the four files (default [constant DEFAULT_DIR]);
## tests pass a throwaway folder so they never touch the player's save.
func _init(base_dir: String = DEFAULT_DIR) -> void:
	var dir: String = base_dir if base_dir.ends_with("/") else base_dir + "/"
	_save_path = dir + SAVE_FILE
	_temp_path = dir + TEMP_FILE
	_backup_path = dir + BACKUP_FILE
	_corrupt_path = dir + CORRUPT_FILE


## True when a save file exists (a leftover interrupted-swap backup counts).
func has_save() -> bool:
	_recover_backup()
	return FileAccess.file_exists(_save_path)


## Writes [param state] (JSON-friendly values only). Returns false (and logs) on failure;
## the previous save is then still intact.
func save(state: Dictionary) -> bool:
	var text: String = JSON.stringify({"version": FORMAT_VERSION, "data": state})
	var file: FileAccess = FileAccess.open(_temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot open %s for writing (error %d)." % [
				_temp_path, FileAccess.get_open_error()])
		return false
	var stored: bool = file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		push_warning("SaveGame: writing %s failed (error %d)." % [_temp_path, write_error])
		DirAccess.remove_absolute(_temp_path)
		return false
	return _swap_in_temp()


## Reads the save. Returns the "data" Dictionary, or an empty Dictionary when there is no
## file or it is unusable (then [member last_load_failed] tells which; a bad file is
## renamed to user://savegame.corrupt.json and a warning is logged).
func load_state() -> Dictionary:
	last_load_failed = false
	_recover_backup()
	if not FileAccess.file_exists(_save_path):
		return {}
	var text: String = FileAccess.get_file_as_string(_save_path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return _reject("invalid JSON (line %d: %s)" % [json.get_error_line(), json.get_error_message()])
	if not json.data is Dictionary:
		return _reject("root is not an object")
	var root: Dictionary = json.data
	var version: Variant = root.get("version")
	if not (version is float or version is int) or int(version) != FORMAT_VERSION:
		return _reject("unknown version %s" % str(version))
	var data: Variant = root.get("data")
	if not data is Dictionary:
		return _reject("missing 'data' object")
	for section: String in REQUIRED_SECTIONS:
		if not (data as Dictionary).get(section) is Dictionary:
			return _reject("missing section '%s'" % section)
	return data as Dictionary


## Renames the temp file over the save. If the rename cannot overwrite, the old save is
## moved aside first and put back when the swap fails.
func _swap_in_temp() -> bool:
	if not FileAccess.file_exists(_save_path):
		return _rename_or_warn(_temp_path, _save_path)
	if DirAccess.rename_absolute(_temp_path, _save_path) == OK:
		return true
	DirAccess.remove_absolute(_backup_path)
	if DirAccess.rename_absolute(_save_path, _backup_path) != OK:
		push_warning("SaveGame: cannot move the old save aside; keeping it.")
		DirAccess.remove_absolute(_temp_path)
		return false
	if DirAccess.rename_absolute(_temp_path, _save_path) != OK:
		push_warning("SaveGame: cannot move the new save into place; restoring the old one.")
		DirAccess.rename_absolute(_backup_path, _save_path)
		DirAccess.remove_absolute(_temp_path)
		return false
	DirAccess.remove_absolute(_backup_path)
	return true


func _rename_or_warn(from_path: String, to_path: String) -> bool:
	var error: Error = DirAccess.rename_absolute(from_path, to_path)
	if error != OK:
		push_warning("SaveGame: rename %s -> %s failed (error %d)." % [from_path, to_path, error])
		DirAccess.remove_absolute(from_path)
		return false
	return true


## An interrupted swap can leave only the backup: put it back.
func _recover_backup() -> void:
	if not FileAccess.file_exists(_save_path) and FileAccess.file_exists(_backup_path):
		DirAccess.rename_absolute(_backup_path, _save_path)


## Logs the reason, keeps the bad file as the corrupt copy and reports "nothing usable".
func _reject(reason: String) -> Dictionary:
	push_warning("SaveGame: unusable save (%s); starting a new game." % reason)
	last_load_failed = true
	DirAccess.remove_absolute(_corrupt_path)
	if DirAccess.rename_absolute(_save_path, _corrupt_path) != OK:
		push_warning("SaveGame: could not keep the bad file as %s." % _corrupt_path)
		DirAccess.remove_absolute(_save_path)
	return {}
