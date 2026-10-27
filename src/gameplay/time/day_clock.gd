class_name DayClock
extends RefCounted
## Pure day/phase/season counter. Time is injected through tick(delta); it never
## reads the wall clock, so it is deterministic and unit testable. Implements story
## 002 (design/game-brief.md, MVP feature 2). Lengths come from time_config.json.
##
## Each tick adds at most max_step_seconds (ADR-0004 rule 1), so one tick crosses at most
## one phase boundary and a long stall or a return from the background never skips a day.
## The clock stands still while any pause source is set, and day speed scales each step.
## Only Main sets pause sources (ADR-0004); this class knows nothing about panels or the app.
##
## Usage:
##   var clock := DayClock.new()
##   var result := DataLoader.read_json("res://assets/data/time_config.json")
##   clock.configure(result.data, result)   # errors and warnings go into result
##   clock.day_advanced.connect(grid.advance_day.unbind(1))
##   clock.tick(delta)                       # every frame
##   clock.set_paused(DayClock.PAUSE_PANEL, true)
##   clock.sleep()                           # end the day early (ignores pause and speed)

## Emitted when the phase changes (including the first phase of a new day).
signal phase_changed(phase_id: String)
## Emitted when a new day begins, after season_changed (if any). Carries the new day number.
signal day_advanced(day_number: int)
## Emitted when a new season begins.
signal season_changed(season_id: String)

## Pause sources (ADR-0004 rule 2). Each is set and cleared by Main only; they are separate
## because the order lifecycle notifications arrive in on a phone is not known.
const PAUSE_PANEL := &"panel"
const PAUSE_APP := &"app_paused"
const PAUSE_FOCUS := &"app_focus"
const PAUSE_WINDOW := &"window_focus"
const PAUSE_PLAYER := &"player"

const _SOURCE: String = "time_config.json"
const _KNOWN_KEYS: Array[String] = ["phases", "days_per_season", "seasons",
		"max_step_seconds", "day_speed"]
const _SPEED_MODES: Array[StringName] = [&"normal", &"slow", &"stop"]

## Current day, starting at 1.
var day_number: int = 1

var _phase_ids: Array[String] = []
var _phase_names: Array[String] = []
var _phase_seconds: Array[float] = []
var _season_ids: Array[String] = []
var _season_names: Array[String] = []
var _days_per_season: int = 1
var _max_step: float = 0.0
var _speed_factors: Dictionary = {}
var _day_speed: StringName = &"normal"
var _pause_sources: Dictionary = {}
var _phase_index: int = 0
var _phase_elapsed: float = 0.0


## Reads [param path] through [DataLoader] and applies it with [method configure]. Logs
## every problem and returns false when the file is unusable. A thin wrapper: Main (ADR-0002)
## gathers results itself and calls [method configure] directly.
func load_from_file(path: String) -> bool:
	var result: DataResult = DataLoader.read_json(path)
	if result.ok():
		configure(result.data, result)
	for message: String in result.errors:
		push_error("DayClock: %s" % message)
	for message: String in result.warnings:
		push_warning("DayClock: %s" % message)
	return result.ok()


## Checks [param data] (same shape as time_config.json), records every problem in
## [param result] and, only when this call added no error, applies it and restarts at day 1,
## first phase, first season, normal speed. Errors already in [param result] (from other
## files) do not block it. On errors the clock keeps its previous state.
func configure(data: Dictionary, result: DataResult) -> void:
	var errors_before: int = result.errors.size() + result.dropped_errors
	for key: Variant in data:
		if not str(key).begins_with("_") and not _KNOWN_KEYS.has(str(key)):
			result.add_warning(_SOURCE, "unknown key '%s' (typo?)" % str(key))
	var phase_ids: Array[String] = []
	var phase_names: Array[String] = []
	var phase_seconds: Array[float] = []
	_read_phases(data.get("phases"), result, phase_ids, phase_names, phase_seconds)
	var season_ids: Array[String] = []
	var season_names: Array[String] = []
	_read_seasons(data.get("seasons"), result, season_ids, season_names)
	var days_per_season: Variant = data.get("days_per_season")
	if not DataChecks.is_whole(days_per_season) or int(days_per_season) < 1:
		result.add_error(_SOURCE, "days_per_season must be a whole number of at least 1")
	var max_step: Variant = data.get("max_step_seconds")
	if not DataChecks.is_number(max_step) or float(max_step) <= 0.0:
		result.add_error(_SOURCE, "max_step_seconds must be a number greater than 0")
	elif not phase_seconds.is_empty() and float(max_step) > phase_seconds.min():
		result.add_error(_SOURCE, "max_step_seconds (%s) must be at most the shortest phase (%s s)"
				% [str(max_step), str(phase_seconds.min())])
	var speed_factors: Dictionary = _read_day_speed(data.get("day_speed"), result)
	if result.errors.size() + result.dropped_errors > errors_before:
		return
	_phase_ids = phase_ids
	_phase_names = phase_names
	_phase_seconds = phase_seconds
	_season_ids = season_ids
	_season_names = season_names
	_days_per_season = int(days_per_season)
	_max_step = float(max_step)
	_speed_factors = speed_factors
	_day_speed = &"normal"
	day_number = 1
	_phase_index = 0
	_phase_elapsed = 0.0


## Advances the clock by [param delta] real seconds: the step is cut to max_step_seconds,
## scaled by the day speed, and nothing happens while paused. Emits signals for the phase,
## day and season boundaries crossed (at most one phase boundary per call).
func tick(delta: float) -> void:
	if _phase_ids.is_empty() or not (delta > 0.0) or is_paused():
		return
	var step: float = minf(delta, _max_step) * float(_speed_factors[_day_speed])
	if step <= 0.0:
		return
	_phase_elapsed += step
	while _phase_elapsed >= _phase_seconds[_phase_index]:
		_phase_elapsed -= _phase_seconds[_phase_index]
		if _phase_index + 1 < _phase_ids.size():
			_phase_index += 1
			phase_changed.emit(_phase_ids[_phase_index])
		else:
			_start_next_day()


## Sets or clears one pause source. The clock stands still while any source is set; setting
## a source twice still needs only one clear. [param source] must be one of the PAUSE_*
## constants: another name is logged and ignored.
func set_paused(source: StringName, paused: bool) -> void:
	if not [PAUSE_PANEL, PAUSE_APP, PAUSE_FOCUS, PAUSE_WINDOW, PAUSE_PLAYER].has(source):
		push_error("DayClock: unknown pause source '%s'" % source)
		return
	if paused:
		_pause_sources[source] = true
	else:
		_pause_sources.erase(source)


## True while any pause source is set.
func is_paused() -> bool:
	return not _pause_sources.is_empty()


## Picks the day speed: &"normal", &"slow" or &"stop" (factors come from time_config.json).
## Another mode is logged and ignored, keeping the current one.
func set_day_speed(mode: StringName) -> void:
	if not _speed_factors.has(mode):
		push_error("DayClock: unknown day speed '%s'" % mode)
		return
	_day_speed = mode


## The current day speed mode.
func get_day_speed() -> StringName:
	return _day_speed


## Ends the current day early: jumps straight to the next day's first phase. Ignores pause
## and day speed, so it is still the way through a day at speed stop (Main blocks the
## button while a panel is open). Nothing else is reset, so no progress is lost.
func sleep() -> void:
	if _phase_ids.is_empty():
		return
	_phase_elapsed = 0.0
	_start_next_day()


## Id of the current phase (e.g. "morning").
func get_phase_id() -> String:
	return _phase_ids[_phase_index]


## Vietnamese display name of the current phase.
func get_phase_name() -> String:
	return _phase_names[_phase_index]


## Id of the current season (matches ids used in crops.json).
func get_season_id() -> String:
	return _season_ids[_season_index()]


## Vietnamese display name of the current season.
func get_season_name() -> String:
	return _season_names[_season_index()]


## Clock state as plain data: {day_number, phase_index, phase_elapsed}. The season is
## derived from the day number, so it is not stored (story 006).
func to_dict() -> Dictionary:
	return {"day_number": day_number, "phase_index": _phase_index, "phase_elapsed": _phase_elapsed}


## Restores state written by [method to_dict] (config must already be loaded). Values are
## clamped into range. Emits no signals.
func from_dict(data: Dictionary) -> void:
	if _phase_ids.is_empty():
		return
	day_number = maxi(1, int(data.get("day_number", 1)))
	_phase_index = clampi(int(data.get("phase_index", 0)), 0, _phase_ids.size() - 1)
	var elapsed: float = float(data.get("phase_elapsed", 0.0))
	if is_nan(elapsed) or elapsed < 0.0 or elapsed >= _phase_seconds[_phase_index]:
		elapsed = 0.0
	_phase_elapsed = elapsed


func _read_phases(raw: Variant, result: DataResult, ids: Array[String],
		names: Array[String], seconds: Array[float]) -> void:
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "phases must be a non-empty list")
		return
	var entries: Array = raw as Array
	for i: int in entries.size():
		var where: String = "%s: phases[%d]" % [_SOURCE, i]
		if not entries[i] is Dictionary:
			result.add_error(where, "must be an object")
			continue
		var entry: Dictionary = entries[i] as Dictionary
		var id: Variant = entry.get("id")
		if not id is String or (id as String).is_empty():
			result.add_error(where, "id must be a non-empty string")
		elif ids.has(id):
			result.add_error(where, "duplicate id '%s'" % id)
		var length: Variant = entry.get("seconds")
		if not DataChecks.is_number(length) or float(length) <= 0.0:
			result.add_error(where, "seconds must be a number greater than 0")
		if id is String and DataChecks.is_number(length):
			ids.append(id as String)
			names.append(entry.get("name") as String if entry.get("name") is String else id as String)
			seconds.append(float(length))


func _read_seasons(raw: Variant, result: DataResult, ids: Array[String],
		names: Array[String]) -> void:
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "seasons must be a non-empty list")
		return
	var entries: Array = raw as Array
	for i: int in entries.size():
		var where: String = "%s: seasons[%d]" % [_SOURCE, i]
		if not entries[i] is Dictionary:
			result.add_error(where, "must be an object")
			continue
		var entry: Dictionary = entries[i] as Dictionary
		var id: Variant = entry.get("id")
		if not id is String or (id as String).is_empty():
			result.add_error(where, "id must be a non-empty string")
			continue
		if ids.has(id):
			result.add_error(where, "duplicate id '%s'" % id)
		ids.append(id as String)
		names.append(entry.get("name") as String if entry.get("name") is String else id as String)


## Returns {mode: factor} for every mode in [constant _SPEED_MODES]; records an error for
## each missing or invalid one.
func _read_day_speed(raw: Variant, result: DataResult) -> Dictionary:
	var factors: Dictionary = {}
	if not raw is Dictionary:
		result.add_error(_SOURCE, "day_speed must be an object with normal, slow and stop")
		return factors
	var table: Dictionary = raw as Dictionary
	for mode: StringName in _SPEED_MODES:
		var where: String = "%s: day_speed.%s" % [_SOURCE, mode]
		var factor: Variant = table.get(String(mode))
		if not DataChecks.is_number(factor):
			result.add_error(where, "missing or not a number")
		elif float(factor) < 0.0 or (mode == &"normal" and float(factor) <= 0.0):
			result.add_error(where, "must be %s" % ("greater than 0" if mode == &"normal" else "0 or more"))
		else:
			factors[mode] = float(factor)
	return factors


func _season_index() -> int:
	return ((day_number - 1) / _days_per_season) % _season_ids.size()


func _start_next_day() -> void:
	var old_season: int = _season_index()
	day_number += 1
	_phase_index = 0
	if _season_index() != old_season:
		season_changed.emit(get_season_id())
	phase_changed.emit(_phase_ids[0])
	day_advanced.emit(day_number)
