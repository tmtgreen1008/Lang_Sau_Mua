class_name VillageProgress
extends RefCounted
## Village restoration progress. Pure logic, no nodes, no drawing.
## Counts completed neighbor requests and derives which pieces are restored and which
## appearance level applies. Content comes from assets/data/village_restoration.json
## (schema in its "_schema" key). Implements story 005 (design/game-brief.md, MVP feature 5).
##
## Usage:
##   var village := VillageProgress.new()
##   if village.load_from_file("res://assets/data/village_restoration.json"):
##       village.bind_book(neighbor_book)   # counts requests from now on
##       village.piece_restored.connect(func(piece_id: String) -> void: ...)

## Emitted once for every piece restored by a newly completed request.
signal piece_restored(piece_id: String)
## Emitted when the appearance level changes (after the piece_restored signals).
signal level_changed(level: int)

## Dictionaries as read from the data file, in file order.
var _pieces: Array[Dictionary] = []
var _levels: Array[Dictionary] = []
var _effect: Dictionary = {}
var _completed: int = 0
var _level: int = 0


## Loads the content from [param path] and resets progress to zero completed requests.
## Returns false (and logs) on any error.
func load_from_file(path: String) -> bool:
	_pieces.clear()
	_levels.clear()
	_completed = 0
	if not FileAccess.file_exists(path):
		push_error("VillageProgress: file not found: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("VillageProgress: invalid JSON root in %s" % path)
		return false
	var root: Dictionary = parsed
	_effect = root.get("effect", {}) as Dictionary
	var ids: Dictionary[String, bool] = {}
	for raw: Variant in root.get("pieces", []) as Array:
		if not raw is Dictionary:
			continue
		var piece: Dictionary = raw
		var piece_id: String = str(piece.get("id", ""))
		if piece_id.is_empty() or ids.has(piece_id) or not piece.has("unlock_at"):
			push_error("VillageProgress: skipping invalid piece entry: %s" % piece_id)
			continue
		ids[piece_id] = true
		_pieces.append(piece)
	for raw: Variant in root.get("levels", []) as Array:
		if raw is Dictionary and (raw as Dictionary).has("level") and (raw as Dictionary).has("min_requests"):
			_levels.append(raw as Dictionary)
	if _pieces.is_empty() or _levels.is_empty():
		push_error("VillageProgress: need at least one piece and one level in %s" % path)
		return false
	_levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["min_requests"]) < int(b["min_requests"]))
	_level = _compute_level()
	return true


## Starts counting requests completed in [param book]: syncs from its current done
## states (no signals), then follows [signal NeighborBook.request_completed].
func bind_book(book: NeighborBook) -> void:
	var done: int = 0
	for neighbor_id: String in book.get_neighbor_ids():
		for request: Variant in book.get_requests(neighbor_id):
			if book.get_status(str((request as Dictionary)["id"])) == NeighborBook.STATE_DONE:
				done += 1
	_completed = done
	_level = _compute_level()
	book.request_completed.connect(_on_request_completed)


## Number of completed neighbor requests counted so far.
func get_completed_count() -> int:
	return _completed


## Current appearance level (the number from the data file; 1 is the ruined village).
func get_level() -> int:
	return _level


## Display name of the current level.
func get_level_name() -> String:
	return str(_level_def(_level).get("name", ""))


## True when the piece's unlock_at has been reached.
func is_piece_restored(piece_id: String) -> bool:
	for piece: Dictionary in _pieces:
		if str(piece["id"]) == piece_id:
			return int(piece["unlock_at"]) <= _completed
	return false


## Display name of a piece ("" if unknown).
func get_piece_name(piece_id: String) -> String:
	for piece: Dictionary in _pieces:
		if str(piece["id"]) == piece_id:
			return str(piece.get("name", ""))
	return ""


## Piece definitions as in the data file, in restoration order (read only).
func get_piece_defs() -> Array[Dictionary]:
	return _pieces


## Level definition for [param level] ({} if unknown).
func get_level_def(level: int) -> Dictionary:
	return _level_def(level)


## The "effect" block of the data file (duration, flash, pulse_scale).
func get_effect() -> Dictionary:
	return _effect


## Progress as plain data: {completed_requests: int}. JSON-friendly.
func to_dict() -> Dictionary:
	return {"completed_requests": _completed}


## Restores progress written by [method to_dict] (content must already be loaded).
## Emits no signals; a view should be resynced afterwards.
func from_dict(data: Dictionary) -> void:
	_completed = maxi(0, int(data.get("completed_requests", 0)))
	_level = _compute_level()


func _on_request_completed(_neighbor_id: String, _request_id: String, _money: int) -> void:
	var before: int = _completed
	_completed += 1
	for piece: Dictionary in _pieces:
		var unlock_at: int = int(piece["unlock_at"])
		if unlock_at > before and unlock_at <= _completed:
			piece_restored.emit(str(piece["id"]))
	var level: int = _compute_level()
	if level != _level:
		_level = level
		level_changed.emit(_level)


func _compute_level() -> int:
	var result: int = int(_levels[0]["level"])
	for level_def: Dictionary in _levels:
		if int(level_def["min_requests"]) <= _completed:
			result = int(level_def["level"])
	return result


func _level_def(level: int) -> Dictionary:
	for level_def: Dictionary in _levels:
		if int(level_def["level"]) == level:
			return level_def
	return {}
