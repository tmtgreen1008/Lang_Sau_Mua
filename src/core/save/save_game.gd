class_name SaveGame
extends RefCounted
## Reads and writes the save file set. Knows nothing about the game systems: it stores the
## Dictionary it is given and checks only the envelope. Implements story 006 and ADR-0005
## (which amends ADR-0001). Not thread-safe; call it from the main thread only.
##
## Files (JSON, root {"version": int, "data": {...}}), all in one folder:
##   savegame.json  the current save
##   savegame.bak   the save before the current one (kept; the way back after a bad write)
##   savegame.tmp   a write in progress; a valid one is a complete newer save
##
## A save is written to .tmp, read back and compared, the current file is rotated to .bak and
## .tmp is renamed into place. Loading tries .tmp, the main file, then .bak and NEVER renames
## or deletes anything; files only move when the player starts a new game
## ([method archive_for_new_game]). A save from a newer game version, an unreadable file or
## a set of corrupt files blocks every later [method save] until then, so a bad load can
## never lead to the player's save being overwritten.
##
## Usage:
##   var store := SaveGame.new()            # or SaveGame.new("user://some_folder/") in tests
##   store.save({"farm": grid.to_dict(), "clock": clock.to_dict(), ...})
##   var result: LoadResult = store.load_state(accept_callable)   # accept(root) -> "" or reason
##   match result.status: ...

const DEFAULT_DIR: String = "user://"
const SAVE_FILE: String = "savegame.json"
const TEMP_FILE: String = "savegame.tmp"
const BACKUP_FILE: String = "savegame.bak"
## Version written to new saves. Raising it needs a SaveMigrations step and a frozen fixture.
const FORMAT_VERSION: int = 1
## How many corrupt-file sets [method archive_for_new_game] keeps.
const ARCHIVE_KEEP: int = 3

const _ROLE_MAIN: String = "main"
const _ROLE_TEMP: String = "tmp"
const _ROLE_BACKUP: String = "bak"

var _dir: String
var _save_path: String
var _temp_path: String
var _backup_path: String
var _write_blocked: bool = false
## Path of the file the last successful load used (for [method backup_loaded_file]).
var _loaded_path: String = ""
## Which file the last load found newer than this game, and its version (0 when none).
var _newer_role: String = ""
var _newer_version: int = 0


## [param base_dir] is the folder that holds the files (default [constant DEFAULT_DIR]);
## tests pass a throwaway folder so they never touch the player's save.
func _init(base_dir: String = DEFAULT_DIR) -> void:
	_dir = base_dir if base_dir.ends_with("/") else base_dir + "/"
	_save_path = _dir + SAVE_FILE
	_temp_path = _dir + TEMP_FILE
	_backup_path = _dir + BACKUP_FILE


## True when any of the save files exists. No side effects.
func has_save() -> bool:
	return FileAccess.file_exists(_save_path) or FileAccess.file_exists(_temp_path) \
			or FileAccess.file_exists(_backup_path)


## True while [method save] refuses to write (after a load that found a newer version, an
## unreadable file or only corrupt files), until [method archive_for_new_game] or a later
## load that succeeds.
func is_write_blocked() -> bool:
	return _write_blocked


## Tries .tmp, the main file, then .bak and returns the first usable one. Never renames or
## deletes a file. [param accept] is called as accept(root: Dictionary) -> String for every
## candidate that is well-formed at envelope level: "" means usable, anything else is the
## reason it is not (SaveGame does not know the game's sections; Main injects the check).
##
## A newer-version or unreadable file ends the search instead of falling through to an older
## candidate. A corrupt .tmp is an interrupted write and is skipped silently.
func load_state(accept: Callable = Callable()) -> LoadResult:
	_loaded_path = ""
	_newer_role = ""
	_newer_version = 0
	var corrupt_message: String = ""
	var candidates: Array[Array] = [
		[_ROLE_TEMP, _temp_path], [_ROLE_MAIN, _save_path], [_ROLE_BACKUP, _backup_path]]
	for candidate: Array in candidates:
		var role: String = candidate[0]
		var attempt: LoadResult = _read_candidate(role, candidate[1], accept)
		match attempt.status:
			LoadResult.Status.NO_SAVE:
				continue
			LoadResult.Status.CORRUPT:
				if role != _ROLE_TEMP and corrupt_message.is_empty():
					corrupt_message = attempt.message
				continue
			LoadResult.Status.NEWER_VERSION:
				_newer_role = role
				_newer_version = attempt.version
				_write_blocked = true
				return attempt
			LoadResult.Status.UNREADABLE:
				_write_blocked = true
				return attempt
		# A usable file.
		attempt.status = LoadResult.Status.OK if role == _ROLE_MAIN else LoadResult.Status.RECOVERED
		_loaded_path = candidate[1]
		_write_blocked = false
		return attempt
	var none := LoadResult.new()
	if corrupt_message.is_empty():
		_write_blocked = false
		return none
	none.status = LoadResult.Status.CORRUPT
	none.message = corrupt_message
	_write_blocked = true
	return none


## Writes [param state] (JSON-friendly values only). Returns false (and logs) when nothing
## was saved; the previous save is then intact. Refuses while [method is_write_blocked] and
## when the main file on disk is from a newer version or cannot be read.
##
## Steps (ADR-0005 rule 14): write .tmp and read it back; rotate a valid main file to .bak
## (a corrupt one is left so it cannot replace a good backup); rename .tmp over the main
## file, putting .bak back when that fails.
func save(state: Dictionary) -> bool:
	if _write_blocked:
		push_warning("SaveGame: saving is blocked until the player starts a new game.")
		return false
	var existing: String = _peek_main()
	if existing == "newer" or existing == "unreadable":
		push_warning("SaveGame: the main save file is %s; not overwriting it." % existing)
		return false
	var text: String = JSON.stringify({"version": FORMAT_VERSION, "data": state})
	if not _write_temp(text):
		return false
	var rotated: bool = false
	if existing == "valid":
		rotated = _rotate_main_to_backup()
		if not rotated:
			push_warning("SaveGame: cannot keep the old save as a backup; left the new one in %s." % TEMP_FILE)
			return false
	elif existing == "corrupt":
		DirAccess.remove_absolute(_save_path)
	if DirAccess.rename_absolute(_temp_path, _save_path) != OK:
		push_warning("SaveGame: cannot move the new save into place.")
		if rotated:
			DirAccess.rename_absolute(_backup_path, _save_path)
		return false
	return true


## Copies the file the last load used to savegame.v<version>.bak, unless that file already
## exists (it is never overwritten). Returns true when the copy exists afterwards, false when
## nothing was loaded or the copy failed. Call before saving an upgraded save.
func backup_loaded_file(version: int) -> bool:
	if _loaded_path.is_empty() or not FileAccess.file_exists(_loaded_path):
		return false
	var target: String = _dir + "savegame.v%d.bak" % version
	if FileAccess.file_exists(target):
		return true
	var text: String = FileAccess.get_file_as_string(_loaded_path)
	var file: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot create %s (error %d)." % [target, FileAccess.get_open_error()])
		return false
	var stored: bool = file.store_string(text)
	file.close()
	if not stored or FileAccess.get_file_as_string(target) != text:
		DirAccess.remove_absolute(target)
		return false
	return true


## The player chose "new game" after an unusable load: moves the existing save files aside
## (nothing is deleted except the oldest corrupt set beyond [constant ARCHIVE_KEEP]) and
## allows saving again. A file the last load found newer than this game is kept as
## savegame.v<N>.bak (a counter is added when that name is taken) and is never pruned.
func archive_for_new_game() -> void:
	var set_number: int = _highest_set_number() + 1
	var roles: Array[Array] = [
		[_ROLE_MAIN, _save_path, "savegame.corrupt.%d.json" % set_number],
		[_ROLE_TEMP, _temp_path, "savegame.corrupt.%d.tmp.json" % set_number],
		[_ROLE_BACKUP, _backup_path, "savegame.corrupt.%d.bak.json" % set_number]]
	for entry: Array in roles:
		var source: String = entry[1]
		if not FileAccess.file_exists(source):
			continue
		var target: String = _dir + (entry[2] as String)
		if entry[0] == _newer_role and _newer_version > 0:
			target = _free_versioned_backup_path(_newer_version)
		if DirAccess.rename_absolute(source, target) != OK:
			push_warning("SaveGame: cannot move %s aside." % source)
	_prune_archive_sets()
	_write_blocked = false
	_loaded_path = ""
	_newer_role = ""
	_newer_version = 0


## Reads one candidate file. NO_SAVE means "no such file", CORRUPT "read but not usable".
func _read_candidate(role: String, path: String, accept: Callable) -> LoadResult:
	var result := LoadResult.new()
	result.source = role
	if DirAccess.dir_exists_absolute(path):
		result.status = LoadResult.Status.UNREADABLE
		result.message = "%s is a folder, not a file" % path
		return result
	if not FileAccess.file_exists(path):
		return result
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		file = FileAccess.open(path, FileAccess.READ)  # once more: the failure may be temporary
	if file == null:
		result.status = LoadResult.Status.UNREADABLE
		result.message = "cannot open %s (error %d)" % [path, FileAccess.get_open_error()]
		return result
	var text: String = file.get_as_text()
	file.close()
	var parsed: DataResult = DataLoader.parse_text(text, path)
	if not parsed.ok():
		result.status = LoadResult.Status.CORRUPT
		result.message = parsed.errors[0]
		return result
	var raw_version: Variant = parsed.data.get("version")
	if not DataChecks.is_whole(raw_version) or int(raw_version) < 0:
		result.status = LoadResult.Status.CORRUPT
		result.message = "%s: version must be a non-negative whole number" % path
		return result
	result.version = int(raw_version)
	if result.version > FORMAT_VERSION:
		result.status = LoadResult.Status.NEWER_VERSION
		result.message = "%s is from a newer game version (%d, this game reads up to %d)" % [
				path, result.version, FORMAT_VERSION]
		return result
	if not parsed.data.get("data") is Dictionary:
		result.status = LoadResult.Status.CORRUPT
		result.message = "%s: 'data' must be an object" % path
		return result
	if accept.is_valid():
		var reason: String = str(accept.call(parsed.data))
		if not reason.is_empty():
			result.status = LoadResult.Status.CORRUPT
			result.message = "%s: %s" % [path, reason]
			return result
	result.status = LoadResult.Status.OK
	result.data = parsed.data["data"] as Dictionary
	return result


## What the main file on disk is: "none", "valid", "corrupt", "newer" or "unreadable".
func _peek_main() -> String:
	if DirAccess.dir_exists_absolute(_save_path):
		return "unreadable"
	if not FileAccess.file_exists(_save_path):
		return "none"
	var attempt: LoadResult = _read_candidate(_ROLE_MAIN, _save_path, Callable())
	match attempt.status:
		LoadResult.Status.OK:
			return "valid"
		LoadResult.Status.NEWER_VERSION:
			return "newer"
		LoadResult.Status.UNREADABLE:
			return "unreadable"
	return "corrupt"


## Steps (a) and (b): writes .tmp, then reads it back and compares it with [param text].
func _write_temp(text: String) -> bool:
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
	if FileAccess.get_file_as_string(_temp_path) != text:
		push_warning("SaveGame: %s does not match what was written (disk full?)." % _temp_path)
		DirAccess.remove_absolute(_temp_path)
		return false
	return true


## Step (c): the valid main file becomes the backup. A rename that cannot replace an
## existing backup is retried once after removing the old backup.
func _rotate_main_to_backup() -> bool:
	if DirAccess.rename_absolute(_save_path, _backup_path) == OK:
		return true
	DirAccess.remove_absolute(_backup_path)
	return DirAccess.rename_absolute(_save_path, _backup_path) == OK


func _free_versioned_backup_path(version: int) -> String:
	var path: String = _dir + "savegame.v%d.bak" % version
	var counter: int = 2
	while FileAccess.file_exists(path):
		path = _dir + "savegame.v%d.%d.bak" % [version, counter]
		counter += 1
	return path


## Numbers of the corrupt sets present, from savegame.corrupt.<n>[.tmp|.bak].json.
func _set_numbers() -> Array[int]:
	var numbers: Array[int] = []
	var pattern := RegEx.new()
	pattern.compile("^savegame\\.corrupt\\.(\\d+)\\.(?:tmp\\.|bak\\.)?json$")
	for file_name: String in DirAccess.get_files_at(_dir):
		var found: RegExMatch = pattern.search(file_name)
		if found != null and not numbers.has(found.get_string(1).to_int()):
			numbers.append(found.get_string(1).to_int())
	numbers.sort()
	return numbers


func _highest_set_number() -> int:
	var numbers: Array[int] = _set_numbers()
	return 0 if numbers.is_empty() else numbers[numbers.size() - 1]


## Deletes the oldest corrupt sets beyond [constant ARCHIVE_KEEP]. Versioned backups
## (savegame.v<N>.bak) are not corrupt sets and are never touched.
func _prune_archive_sets() -> void:
	var numbers: Array[int] = _set_numbers()
	while numbers.size() > ARCHIVE_KEEP:
		var oldest: int = numbers.pop_front()
		for suffix: String in [".json", ".tmp.json", ".bak.json"]:
			DirAccess.remove_absolute(_dir + "savegame.corrupt.%d%s" % [oldest, suffix])
