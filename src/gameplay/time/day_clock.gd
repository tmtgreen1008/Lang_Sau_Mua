class_name DayClock
extends RefCounted
## Pure day/phase/season counter. Time is injected through tick(delta); it never
## reads the wall clock, so it is deterministic and unit testable. Implements story
## 002 (design/game-brief.md, MVP feature 2). Lengths come from time_config.json.
##
## Usage:
##   var clock := DayClock.new()
##   clock.load_from_file("res://assets/data/time_config.json")
##   clock.day_advanced.connect(grid.advance_day.unbind(1))
##   clock.tick(delta)   # every frame
##   clock.sleep()       # end the day early

## Emitted when the phase changes (including the first phase of a new day).
signal phase_changed(phase_id: String)
## Emitted when a new day begins, after season_changed (if any). Carries the new day number.
signal day_advanced(day_number: int)
## Emitted when a new season begins.
signal season_changed(season_id: String)

## Current day, starting at 1.
var day_number: int = 1

var _phase_ids: Array[String] = []
var _phase_names: Array[String] = []
var _phase_seconds: Array[float] = []
var _season_ids: Array[String] = []
var _season_names: Array[String] = []
var _days_per_season: int = 1
var _phase_index: int = 0
var _phase_elapsed: float = 0.0


## Loads phase/season lengths from [param path]. Returns false (and logs) on any error.
func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("DayClock: file not found: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("DayClock: invalid JSON root in %s" % path)
		return false
	return configure(parsed as Dictionary)


## Applies a config Dictionary (same shape as time_config.json) and restarts at day 1,
## first phase, first season. Returns false (and logs) when the config is unusable.
func configure(config: Dictionary) -> bool:
	var phases: Variant = config.get("phases")
	var seasons: Variant = config.get("seasons")
	if not phases is Array or (phases as Array).is_empty() \
			or not seasons is Array or (seasons as Array).is_empty():
		push_error("DayClock: config needs non-empty 'phases' and 'seasons'")
		return false
	_phase_ids.clear()
	_phase_names.clear()
	_phase_seconds.clear()
	_season_ids.clear()
	_season_names.clear()
	for entry: Variant in phases as Array:
		var phase: Dictionary = entry if entry is Dictionary else {}
		var id: String = str(phase.get("id", ""))
		var seconds: float = float(phase.get("seconds", 0.0))
		if id.is_empty() or seconds <= 0.0:
			push_error("DayClock: invalid phase entry: %s" % str(entry))
			return false
		_phase_ids.append(id)
		_phase_names.append(str(phase.get("name", id)))
		_phase_seconds.append(seconds)
	for entry: Variant in seasons as Array:
		var season: Dictionary = entry if entry is Dictionary else {}
		var id: String = str(season.get("id", ""))
		if id.is_empty():
			push_error("DayClock: invalid season entry: %s" % str(entry))
			return false
		_season_ids.append(id)
		_season_names.append(str(season.get("name", id)))
	_days_per_season = maxi(1, int(config.get("days_per_season", 1)))
	day_number = 1
	_phase_index = 0
	_phase_elapsed = 0.0
	return true


## Advances the clock by [param delta] seconds, emitting signals for every phase,
## day and season boundary crossed.
func tick(delta: float) -> void:
	if _phase_ids.is_empty() or delta <= 0.0:
		return
	_phase_elapsed += delta
	while _phase_elapsed >= _phase_seconds[_phase_index]:
		_phase_elapsed -= _phase_seconds[_phase_index]
		if _phase_index + 1 < _phase_ids.size():
			_phase_index += 1
			phase_changed.emit(_phase_ids[_phase_index])
		else:
			_start_next_day()


## Ends the current day early: jumps straight to the next day's first phase.
## Nothing else is reset, so no progress is lost.
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
