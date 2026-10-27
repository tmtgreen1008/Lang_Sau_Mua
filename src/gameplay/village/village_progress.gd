class_name VillageProgress
extends RefCounted
## Village restoration progress. Pure logic, no nodes, no drawing.
## Counts completed neighbor requests and derives which pieces are restored and which
## appearance level applies. Content comes from assets/data/village_restoration.json
## (schema in its "_schema" key). Implements story 005 (design/game-brief.md, MVP feature 5).
##
## Usage:
##   var village := VillageProgress.new()
##   var result := DataLoader.read_json("res://assets/data/village_restoration.json")
##   village.configure(result.data, result)   # every problem goes into result
##   village.piece_restored.connect(func(piece_id: String) -> void: ...)
##   village.on_request_completed(book.get_completed_count())   # Main, after each hand-over

## Emitted once for every piece restored by a newly completed request.
signal piece_restored(piece_id: String)
## Emitted when the appearance level changes (after the piece_restored signals).
signal level_changed(level: int)

const _SOURCE: String = "village_restoration.json"
const _TOP_KEYS: Array[String] = ["effect", "levels", "pieces"]
const _EFFECT_KEYS: Array[String] = ["duration", "flash", "pulse_scale"]
const _LEVEL_KEYS: Array[String] = ["level", "min_requests", "name", "ground_tint"]
const _PIECE_KEYS: Array[String] = ["id", "name", "unlock_at", "origin", "size", "shapes"]
const _SHAPE_KEYS: Array[String] = ["kind", "ruined", "restored"]
const _SIDE_KEYS: Array[String] = ["g", "color"]
## Shape kind -> how many numbers its "g" list must hold (poly: an even count of at least 6).
const _SHAPE_NUMBERS: Dictionary[String, int] = {"rect": 4, "ellipse": 4, "poly": 0}

## Dictionaries as read from the data file, in file order.
var _pieces: Array[Dictionary] = []
var _levels: Array[Dictionary] = []
var _effect: Dictionary = {}
var _completed: int = 0
var _level: int = 0


## Reads [param path] through [DataLoader] and applies it with [method configure]. Logs every
## problem and returns false when the content is unusable. A thin wrapper: Main gathers the
## results of all files itself and calls [method configure] directly.
func load_from_file(path: String) -> bool:
	var result: DataResult = DataLoader.read_json(path)
	if result.ok():
		configure(result.data, result)
	for message: String in result.errors:
		push_error("VillageProgress: %s" % message)
	for message: String in result.warnings:
		push_warning("VillageProgress: %s" % message)
	return result.ok()


## Checks [param data] (the shape of village_restoration.json), records every problem in
## [param result] and, only when this call added no error, replaces the content and resets
## progress to zero completed requests. On errors the previous content stays. Errors already
## in [param result] (from other files) do not block it. How the unlock numbers relate to the
## number of requests is the DataValidator's job.
## Warnings (not errors): invalid colours, empty names, keys that are not part of the format.
func configure(data: Dictionary, result: DataResult) -> void:
	var errors_before: int = DataChecks.error_count(result)
	DataChecks.warn_unknown_keys(data, _TOP_KEYS, _SOURCE, result)
	var effect: Dictionary = _read_effect(data.get("effect"), result)
	var levels: Array[Dictionary] = _read_levels(data.get("levels"), result)
	var pieces: Array[Dictionary] = _read_pieces(data.get("pieces"), result)
	if DataChecks.error_count(result) > errors_before:
		return
	levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["min_requests"]) < int(b["min_requests"]))
	_effect = effect
	_levels = levels
	_pieces = pieces
	_completed = 0
	_level = _compute_level()


## Level definitions ({level, min_requests, name, ground_tint}), ascending by min_requests.
func get_level_defs() -> Array[Dictionary]:
	return _levels


## Main tells the village how many neighbor requests are done in total (ADR-0002 rule 6; the
## village does not know the neighbor book). A higher count restores every piece whose
## unlock_at it reaches, in data order, then emits level_changed if the level rose. The same
## count does nothing; a lower one (a new game) updates silently.
func on_request_completed(count: int) -> void:
	var before: int = _completed
	_completed = maxi(0, count)
	var level: int = _compute_level()
	if _completed > before:
		for piece: Dictionary in _pieces:
			var unlock_at: int = int(piece["unlock_at"])
			if unlock_at > before and unlock_at <= _completed:
				piece_restored.emit(str(piece["id"]))
	var changed: bool = level != _level
	_level = level
	if changed and _completed > before:
		level_changed.emit(_level)


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


func _read_effect(raw: Variant, result: DataResult) -> Dictionary:
	var where: String = "%s: effect" % _SOURCE
	if not raw is Dictionary:
		result.add_error(where, "must be an object with duration, flash and pulse_scale")
		return {}
	var effect: Dictionary = (raw as Dictionary).duplicate(true)
	DataChecks.warn_unknown_keys(effect, _EFFECT_KEYS, where, result)
	var duration: Variant = effect.get("duration")
	if not DataChecks.is_number(duration) or float(duration) <= 0.0:
		result.add_error(where, "duration must be a number greater than 0")
	var flash: Variant = effect.get("flash")
	if not DataChecks.is_number(flash) or float(flash) < 0.0 or float(flash) > 1.0:
		result.add_error(where, "flash must be a number from 0 to 1")
	var pulse: Variant = effect.get("pulse_scale")
	if not DataChecks.is_number(pulse) or float(pulse) < 0.0:
		result.add_error(where, "pulse_scale must be a number of at least 0")
	return effect


func _read_levels(raw: Variant, result: DataResult) -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "levels must be a non-empty list")
		return levels
	var seen: Array[int] = []
	var entries: Array = raw as Array
	for i: int in entries.size():
		var where: String = "%s: levels[%d]" % [_SOURCE, i]
		if not entries[i] is Dictionary:
			result.add_error(where, "must be an object")
			continue
		var entry: Dictionary = (entries[i] as Dictionary).duplicate(true)
		DataChecks.warn_unknown_keys(entry, _LEVEL_KEYS, where, result)
		var valid: bool = true
		if not DataChecks.is_whole(entry.get("level")):
			result.add_error(where, "level must be a whole number")
			valid = false
		elif seen.has(int(entry["level"])):
			result.add_error(where, "duplicate level %d" % int(entry["level"]))
			valid = false
		else:
			seen.append(int(entry["level"]))
			entry["level"] = int(entry["level"])
		var min_requests: Variant = entry.get("min_requests")
		if not DataChecks.is_whole(min_requests) or int(min_requests) < 0:
			result.add_error(where, "min_requests must be a whole number of at least 0")
			valid = false
		else:
			entry["min_requests"] = int(min_requests)
		if not entry.get("name") is String or (entry["name"] as String).is_empty():
			result.add_warning(where, "name is empty")
		if not DataChecks.is_valid_colour(entry.get("ground_tint")):
			result.add_warning(where, "ground_tint is not #rrggbb or #rrggbbaa")
		if valid:
			levels.append(entry)
	return levels


func _read_pieces(raw: Variant, result: DataResult) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "pieces must be a non-empty list")
		return pieces
	var ids: Array[String] = []
	var entries: Array = raw as Array
	for i: int in entries.size():
		var where: String = "%s: pieces[%d]" % [_SOURCE, i]
		if not entries[i] is Dictionary:
			result.add_error(where, "must be an object")
			continue
		var entry: Dictionary = (entries[i] as Dictionary).duplicate(true)
		DataChecks.warn_unknown_keys(entry, _PIECE_KEYS, where, result)
		var id: Variant = entry.get("id")
		var valid: bool = id is String and not (id as String).is_empty()
		if not valid:
			result.add_error(where, "id must be a non-empty string")
		elif ids.has(id):
			result.add_error(where, "duplicate id '%s'" % id)
			valid = false
		else:
			ids.append(id as String)
		var unlock_at: Variant = entry.get("unlock_at")
		if not DataChecks.is_whole(unlock_at) or int(unlock_at) < 1:
			result.add_error(where, "unlock_at must be a whole number of at least 1")
		else:
			entry["unlock_at"] = int(unlock_at)
		if not entry.get("name") is String or (entry["name"] as String).is_empty():
			result.add_warning(where, "name is empty")
		_check_pair(entry.get("origin"), "origin", where, false, result)
		_check_pair(entry.get("size"), "size", where, true, result)
		_read_shapes(entry.get("shapes"), where, result)
		if valid:
			pieces.append(entry)
	return pieces


## origin and size are [x, y] number pairs; size must also be positive.
func _check_pair(raw: Variant, key: String, where: String, positive: bool, result: DataResult) -> void:
	var ok: bool = raw is Array and (raw as Array).size() == 2
	if ok:
		for value: Variant in raw as Array:
			if not DataChecks.is_number(value) or (positive and float(value) <= 0.0):
				ok = false
	if not ok:
		result.add_error(where, "%s must be [%s]" % [key, "width, height, both above 0" if positive else "x, y"])


func _read_shapes(raw: Variant, where: String, result: DataResult) -> void:
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(where, "shapes must be a non-empty list")
		return
	var shapes: Array = raw as Array
	for i: int in shapes.size():
		var shape_where: String = "%s.shapes[%d]" % [where, i]
		if not shapes[i] is Dictionary:
			result.add_error(shape_where, "must be an object")
			continue
		var shape: Dictionary = shapes[i] as Dictionary
		DataChecks.warn_unknown_keys(shape, _SHAPE_KEYS, shape_where, result)
		var kind: Variant = shape.get("kind")
		if not kind is String or not _SHAPE_NUMBERS.has(kind):
			result.add_error(shape_where, "kind must be one of rect, ellipse, poly")
			continue
		if shape.get("ruined") == null and shape.get("restored") == null:
			result.add_error(shape_where, "needs a ruined or a restored side (both are empty)")
		for side: String in ["ruined", "restored"]:
			_read_side(shape.get(side), kind as String, "%s.%s" % [shape_where, side], result)


## One side of a shape: null (the shape fades in or out) or {g: [numbers], color}.
func _read_side(raw: Variant, kind: String, where: String, result: DataResult) -> void:
	if raw == null:
		return
	if not raw is Dictionary:
		result.add_error(where, "must be null or an object with g and color")
		return
	var side: Dictionary = raw as Dictionary
	DataChecks.warn_unknown_keys(side, _SIDE_KEYS, where, result)
	var geometry: Variant = side.get("g")
	var ok: bool = geometry is Array
	if ok:
		for value: Variant in geometry as Array:
			ok = ok and DataChecks.is_number(value)
		var count: int = (geometry as Array).size()
		if kind == "poly":
			ok = ok and count >= 6 and count % 2 == 0
		else:
			ok = ok and count == _SHAPE_NUMBERS[kind]
	if not ok:
		var need: String = "an even number of values, at least 6 (3 points)" if kind == "poly" \
				else "%d numbers" % _SHAPE_NUMBERS[kind]
		result.add_error(where, "g for a %s must be %s" % [kind, need])
	if not DataChecks.is_valid_colour(side.get("color")):
		result.add_warning(where, "color is not #rrggbb or #rrggbbaa")


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
