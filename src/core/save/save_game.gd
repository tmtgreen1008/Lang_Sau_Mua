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
##   var store := SaveGame.new()
##   store.save({"farm": grid.to_dict(), "clock": clock.to_dict(), ...})
##   if store.has_save():
##       var state: Dictionary = store.load_state()   # {} when nothing usable
##       if state.is_empty() and store.last_load_failed: ...

const SAVE_PATH: String = "user://savegame.json"
const TEMP_PATH: String = "user://savegame.tmp"
const BACKUP_PATH: String = "user://savegame.bak"
const CORRUPT_PATH: String = "user://savegame.corrupt.json"
## Version written to new saves; only this version is read back.
const FORMAT_VERSION: int = 1
## Sections that must exist (as Dictionaries) in "data" for a save to be usable.
const REQUIRED_SECTIONS: Array[String] = ["farm", "clock", "market", "neighbors", "village"]

## True when the last [method load_state] found a file but could not use it.
var last_load_failed: bool = false


## True when a save file exists (a leftover interrupted-swap backup counts).
func has_save() -> bool:
	_recover_backup()
	return FileAccess.file_exists(SAVE_PATH)


## Writes [param state] (JSON-friendly values only). Returns false (and logs) on failure;
## the previous save is then still intact.
func save(state: Dictionary) -> bool:
	var text: String = JSON.stringify({"version": FORMAT_VERSION, "data": state})
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot open %s for writing (error %d)." % [
				TEMP_PATH, FileAccess.get_open_error()])
		return false
	var stored: bool = file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		push_warning("SaveGame: writing %s failed (error %d)." % [TEMP_PATH, write_error])
		DirAccess.remove_absolute(TEMP_PATH)
		return false
	return _swap_in_temp()


## Reads the save. Returns the "data" Dictionary, or an empty Dictionary when there is no
## file or it is unusable (then [member last_load_failed] tells which; a bad file is
## renamed to user://savegame.corrupt.json and a warning is logged).
func load_state() -> Dictionary:
	last_load_failed = false
	_recover_backup()
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
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
	if not FileAccess.file_exists(SAVE_PATH):
		return _rename_or_warn(TEMP_PATH, SAVE_PATH)
	if DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH) == OK:
		return true
	DirAccess.remove_absolute(BACKUP_PATH)
	if DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH) != OK:
		push_warning("SaveGame: cannot move the old save aside; keeping it.")
		DirAccess.remove_absolute(TEMP_PATH)
		return false
	if DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH) != OK:
		push_warning("SaveGame: cannot move the new save into place; restoring the old one.")
		DirAccess.rename_absolute(BACKUP_PATH, SAVE_PATH)
		DirAccess.remove_absolute(TEMP_PATH)
		return false
	DirAccess.remove_absolute(BACKUP_PATH)
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
	if not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(BACKUP_PATH):
		DirAccess.rename_absolute(BACKUP_PATH, SAVE_PATH)


## Logs the reason, keeps the bad file as the corrupt copy and reports "nothing usable".
func _reject(reason: String) -> Dictionary:
	push_warning("SaveGame: unusable save (%s); starting a new game." % reason)
	last_load_failed = true
	DirAccess.remove_absolute(CORRUPT_PATH)
	if DirAccess.rename_absolute(SAVE_PATH, CORRUPT_PATH) != OK:
		push_warning("SaveGame: could not keep the bad file as %s." % CORRUPT_PATH)
		DirAccess.remove_absolute(SAVE_PATH)
	return {}
