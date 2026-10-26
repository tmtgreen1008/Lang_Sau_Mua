class_name NeighborBook
extends RefCounted
## Neighbor requests, unlocked crops and unlocked dishes. Pure logic, no nodes, no UI.
## Content comes from assets/data/neighbors.json (schema in its "_schema" key).
## Implements story 004 (design/game-brief.md, MVP feature 4).
##
## Each neighbor has an ordered, linear list of requests; a request is available only
## after the previous one is done. All progress lives in plain data (see [method to_dict])
## so story 006 can save and load it.
##
## Usage:
##   var book := NeighborBook.new()
##   if book.load_from_file("res://assets/data/neighbors.json"):
##       if book.can_complete("ba_tu", grid.inventory):
##           var request: Dictionary = book.complete_request("ba_tu", grid.inventory)

## Emitted after a request was completed and its produce removed from the inventory.
## [param money] is the money reward; the caller adds it to the player.
signal request_completed(neighbor_id: String, request_id: String, money: int)
## Emitted once when a crop becomes plantable.
signal crop_unlocked(crop_id: String)
## Emitted once when a dish becomes listed.
signal dish_unlocked(dish_id: String)
## Emitted exactly once per season, when every request tagged with [param season_id]
## is done. Story 005 consumes it.
signal season_requests_completed(season_id: String)

const STATE_NOT_STARTED: String = "not_started"
const STATE_ACTIVE: String = "active"
const STATE_DONE: String = "done"

## neighbor_id -> neighbor definition Dictionary.
var _neighbors: Dictionary[String, Dictionary] = {}
var _neighbor_ids: Array[String] = []
## request_id -> request definition Dictionary.
var _requests: Dictionary[String, Dictionary] = {}
## request_id -> season id.
var _request_seasons: Dictionary[String, String] = {}
## dish_id -> display name.
var _dish_names: Dictionary[String, String] = {}
## request_id -> STATE_*.
var _states: Dictionary[String, String] = {}
var _unlocked_crops: Array[String] = []
var _unlocked_dishes: Array[String] = []
var _start_crops: Array[String] = []
## Seasons whose completion signal was already emitted.
var _completed_seasons: Dictionary[String, bool] = {}


## Loads request content from [param path] and resets all progress to a new game.
## Returns false (and logs) on any error.
func load_from_file(path: String) -> bool:
	_clear()
	if not FileAccess.file_exists(path):
		push_error("NeighborBook: file not found: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("NeighborBook: invalid JSON root in %s" % path)
		return false
	var root: Dictionary = parsed
	for dish: Variant in root.get("dishes", []) as Array:
		if dish is Dictionary and not str((dish as Dictionary).get("id", "")).is_empty():
			_dish_names[str((dish as Dictionary)["id"])] = str((dish as Dictionary).get("name", ""))
	for crop_id: Variant in root.get("start_unlocked_crops", []) as Array:
		_start_crops.append(str(crop_id))
	var list: Variant = root.get("neighbors")
	if not list is Array:
		push_error("NeighborBook: missing 'neighbors' array in %s" % path)
		return false
	for entry: Variant in list as Array:
		if entry is Dictionary:
			_add_neighbor(entry as Dictionary)
	if _neighbor_ids.is_empty():
		push_error("NeighborBook: no valid neighbors in %s" % path)
		return false
	_reset_progress()
	return true


## Neighbor ids in file order.
func get_neighbor_ids() -> Array[String]:
	return _neighbor_ids


## Display name, or the id if unknown.
func get_neighbor_name(neighbor_id: String) -> String:
	return str(_neighbors.get(neighbor_id, {}).get("name", neighbor_id))


## Placeholder figure colour.
func get_neighbor_color(neighbor_id: String) -> Color:
	return Color.from_string(str(_neighbors.get(neighbor_id, {}).get("color", "#ffffff")), Color.WHITE)


## Line shown once all of the neighbor's requests are done ("" if the data has none).
func get_thanks_text(neighbor_id: String) -> String:
	return str(_neighbors.get(neighbor_id, {}).get("thanks_text", ""))


## The neighbor's requests, in order (empty if unknown).
func get_requests(neighbor_id: String) -> Array:
	return _neighbors.get(neighbor_id, {}).get("requests", [])


## State of a request: STATE_NOT_STARTED (chưa nhận), STATE_ACTIVE (đang làm) or
## STATE_DONE (xong). Unknown ids report STATE_NOT_STARTED.
func get_status(request_id: String) -> String:
	return _states.get(request_id, STATE_NOT_STARTED)


## The request the neighbor currently asks for, or an empty Dictionary when all are done.
func get_current_request(neighbor_id: String) -> Dictionary:
	for request: Variant in get_requests(neighbor_id):
		if get_status(str((request as Dictionary)["id"])) != STATE_DONE:
			return request as Dictionary
	return {}


## True when every request of the neighbor is done.
func is_all_done(neighbor_id: String) -> bool:
	return get_current_request(neighbor_id).is_empty() and _neighbors.has(neighbor_id)


## Required produce of the current request: crop_id -> quantity (empty when none).
func get_required(neighbor_id: String) -> Dictionary[String, int]:
	var required: Dictionary[String, int] = {}
	var request: Dictionary = get_current_request(neighbor_id)
	var require: Dictionary = request.get("require", {})
	for crop_id: Variant in require:
		required[str(crop_id)] = int(require[crop_id])
	return required


## Produce still missing for the current request given [param inventory]
## (crop_id -> quantity short; empty when the request can be completed).
func get_missing(neighbor_id: String, inventory: Dictionary) -> Dictionary[String, int]:
	var missing: Dictionary[String, int] = {}
	var required: Dictionary[String, int] = get_required(neighbor_id)
	for crop_id: String in required:
		var short: int = required[crop_id] - int(inventory.get(crop_id, 0))
		if short > 0:
			missing[crop_id] = short
	return missing


## True when the neighbor has a current request and [param inventory] covers it.
func can_complete(neighbor_id: String, inventory: Dictionary) -> bool:
	return not get_current_request(neighbor_id).is_empty() and get_missing(neighbor_id, inventory).is_empty()


## Hands in the current request: removes the produce from [param inventory], applies
## the unlock, marks it done (it can never be repeated) and activates the next request.
## Returns the completed request Dictionary, or an empty one (nothing changes) when
## it cannot be completed.
func complete_request(neighbor_id: String, inventory: Dictionary) -> Dictionary:
	if not can_complete(neighbor_id, inventory):
		return {}
	var request: Dictionary = get_current_request(neighbor_id)
	var request_id: String = str(request["id"])
	var required: Dictionary[String, int] = get_required(neighbor_id)
	for crop_id: String in required:
		inventory[crop_id] = int(inventory.get(crop_id, 0)) - required[crop_id]
	_states[request_id] = STATE_DONE
	_activate_first_open(neighbor_id)
	var reward: Dictionary = request.get("reward", {})
	_unlock_crop(str(reward.get("unlock_crop", "")))
	_unlock_dish(str(reward.get("unlock_dish", "")))
	request_completed.emit(neighbor_id, request_id, maxi(0, int(reward.get("money", 0))))
	_check_season_done(str(request.get("season", "")))
	return request


## True when [param crop_id] may be planted.
func is_crop_unlocked(crop_id: String) -> bool:
	return _unlocked_crops.has(crop_id)


## Unlocked crop ids, in unlock order.
func get_unlocked_crops() -> Array[String]:
	return _unlocked_crops


## Unlocked dish ids, in unlock order.
func get_unlocked_dishes() -> Array[String]:
	return _unlocked_dishes


## Dish display name, or the id if unknown.
func get_dish_name(dish_id: String) -> String:
	return _dish_names.get(dish_id, dish_id)


## Progress as plain data: {request_states: {request_id: state}, unlocked_crops: [ids],
## unlocked_dishes: [ids]}. Contains only JSON-friendly types.
func to_dict() -> Dictionary:
	return {
		"request_states": _states.duplicate(),
		"unlocked_crops": _unlocked_crops.duplicate(),
		"unlocked_dishes": _unlocked_dishes.duplicate(),
	}


## Restores progress written by [method to_dict] (content must already be loaded).
## Unknown ids and invalid states are ignored. Emits no signals.
func from_dict(data: Dictionary) -> void:
	_reset_progress()
	var saved_states: Variant = data.get("request_states", {})
	if saved_states is Dictionary:
		for request_id: Variant in saved_states as Dictionary:
			var state: String = str((saved_states as Dictionary)[request_id])
			if _requests.has(str(request_id)) \
					and [STATE_NOT_STARTED, STATE_ACTIVE, STATE_DONE].has(state):
				_states[str(request_id)] = state
	for neighbor_id: String in _neighbor_ids:
		_activate_first_open(neighbor_id)
	_unlocked_crops.clear()
	_unlocked_dishes.clear()
	for crop_id: Variant in data.get("unlocked_crops", []) as Array:
		if not _unlocked_crops.has(str(crop_id)):
			_unlocked_crops.append(str(crop_id))
	for dish_id: Variant in data.get("unlocked_dishes", []) as Array:
		if _dish_names.has(str(dish_id)) and not _unlocked_dishes.has(str(dish_id)):
			_unlocked_dishes.append(str(dish_id))
	# Seasons already finished must not fire the signal again.
	_completed_seasons.clear()
	for season_id: String in _all_seasons():
		if _is_season_done(season_id):
			_completed_seasons[season_id] = true


func _clear() -> void:
	_neighbors.clear()
	_neighbor_ids.clear()
	_requests.clear()
	_request_seasons.clear()
	_dish_names.clear()
	_states.clear()
	_unlocked_crops.clear()
	_unlocked_dishes.clear()
	_start_crops.clear()
	_completed_seasons.clear()


func _add_neighbor(entry: Dictionary) -> void:
	var neighbor_id: String = str(entry.get("id", ""))
	var raw_requests: Variant = entry.get("requests")
	if neighbor_id.is_empty() or _neighbors.has(neighbor_id) or not raw_requests is Array:
		push_error("NeighborBook: skipping invalid neighbor entry: %s" % str(entry.get("id", "?")))
		return
	var valid_requests: Array = []
	for raw: Variant in raw_requests as Array:
		if not raw is Dictionary:
			continue
		var request: Dictionary = raw
		var request_id: String = str(request.get("id", ""))
		if request_id.is_empty() or _requests.has(request_id) or not request.get("require") is Dictionary:
			push_error("NeighborBook: skipping invalid request entry: %s" % request_id)
			continue
		_requests[request_id] = request
		_request_seasons[request_id] = str(request.get("season", ""))
		valid_requests.append(request)
	var neighbor: Dictionary = entry.duplicate()
	neighbor["requests"] = valid_requests
	_neighbors[neighbor_id] = neighbor
	_neighbor_ids.append(neighbor_id)


## New-game progress: the first request of each neighbor is active, the rest wait.
func _reset_progress() -> void:
	_states.clear()
	for request_id: String in _requests:
		_states[request_id] = STATE_NOT_STARTED
	for neighbor_id: String in _neighbor_ids:
		_activate_first_open(neighbor_id)
	_unlocked_crops.clear()
	_unlocked_crops.append_array(_start_crops)
	_unlocked_dishes.clear()
	_completed_seasons.clear()


## Marks the first not-done request of the neighbor active (earlier ones stay done).
func _activate_first_open(neighbor_id: String) -> void:
	var found: bool = false
	for request: Variant in get_requests(neighbor_id):
		var request_id: String = str((request as Dictionary)["id"])
		if _states.get(request_id, STATE_NOT_STARTED) == STATE_DONE:
			continue
		_states[request_id] = STATE_NOT_STARTED if found else STATE_ACTIVE
		found = true


func _unlock_crop(crop_id: String) -> void:
	if crop_id.is_empty() or _unlocked_crops.has(crop_id):
		return
	_unlocked_crops.append(crop_id)
	crop_unlocked.emit(crop_id)


func _unlock_dish(dish_id: String) -> void:
	if dish_id.is_empty() or _unlocked_dishes.has(dish_id):
		return
	_unlocked_dishes.append(dish_id)
	dish_unlocked.emit(dish_id)


func _all_seasons() -> Array[String]:
	var seasons: Array[String] = []
	for request_id: String in _request_seasons:
		var season_id: String = _request_seasons[request_id]
		if not season_id.is_empty() and not seasons.has(season_id):
			seasons.append(season_id)
	return seasons


func _is_season_done(season_id: String) -> bool:
	for request_id: String in _request_seasons:
		if _request_seasons[request_id] == season_id and get_status(request_id) != STATE_DONE:
			return false
	return true


func _check_season_done(season_id: String) -> void:
	if season_id.is_empty() or _completed_seasons.has(season_id) or not _is_season_done(season_id):
		return
	_completed_seasons[season_id] = true
	season_requests_completed.emit(season_id)
