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
##   var result := DataLoader.read_json("res://assets/data/neighbors.json")
##   book.configure(result.data, result)      # every problem goes into result
##   if book.can_complete("ba_tu", grid.inventory):
##       var request: Dictionary = book.complete_request("ba_tu", grid.inventory)

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

const _SOURCE: String = "neighbors.json"
const _TOP_KEYS: Array[String] = ["start_unlocked_crops", "dishes", "neighbors"]
const _DISH_KEYS: Array[String] = ["id", "name"]
const _NEIGHBOR_KEYS: Array[String] = ["id", "name", "color", "thanks_text", "requests"]
const _REQUEST_KEYS: Array[String] = ["id", "season", "offer_text", "missing_text", "done_text",
		"require", "reward", "min_level"]
const _REQUEST_TEXT_KEYS: Array[String] = ["offer_text", "missing_text", "done_text"]
const _REWARD_KEYS: Array[String] = ["money", "unlock_crop", "unlock_dish"]

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


## Reads [param path] through [DataLoader] and applies it with [method configure]. Logs every
## problem and returns false when the content is unusable. A thin wrapper: Main gathers the
## results of all files itself and calls [method configure] directly.
func load_from_file(path: String) -> bool:
	var result: DataResult = DataLoader.read_json(path)
	if result.ok():
		configure(result.data, result)
	for message: String in result.errors:
		push_error("NeighborBook: %s" % message)
	for message: String in result.warnings:
		push_warning("NeighborBook: %s" % message)
	return result.ok()


## Checks [param data] (the shape of neighbors.json), records every problem in [param result]
## and, only when this call added no error, replaces the content and resets all progress to a
## new game. On errors the previous content stays. Errors already in [param result] (from
## other files) do not block it. This checks the file on its own; whether the crops, seasons
## and dishes it names exist is the DataValidator's job.
## Warnings (not errors): empty names or texts, invalid colour, negative money (clamped to 0),
## keys that are not part of the format.
func configure(data: Dictionary, result: DataResult) -> void:
	var errors_before: int = DataChecks.error_count(result)
	DataChecks.warn_unknown_keys(data, _TOP_KEYS, _SOURCE, result)
	var start_crops: Array[String] = _read_start_crops(data.get("start_unlocked_crops"), result)
	var dish_names: Dictionary[String, String] = _read_dishes(data.get("dishes"), result)
	var neighbors: Dictionary[String, Dictionary] = {}
	var neighbor_ids: Array[String] = []
	var requests: Dictionary[String, Dictionary] = {}
	var request_seasons: Dictionary[String, String] = {}
	var raw: Variant = data.get("neighbors")
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "neighbors must be a non-empty list")
	else:
		var entries: Array = raw as Array
		for i: int in entries.size():
			_read_neighbor(entries[i], "%s: neighbors[%d]" % [_SOURCE, i], result, neighbors,
					neighbor_ids, requests, request_seasons)
	if DataChecks.error_count(result) > errors_before:
		return
	_clear()
	_neighbors = neighbors
	_neighbor_ids = neighbor_ids
	_requests = requests
	_request_seasons = request_seasons
	_dish_names = dish_names
	_start_crops = start_crops
	_reset_progress()


## Crops plantable from the start of the game (ids), in file order.
func get_start_crops() -> Array[String]:
	return _start_crops.duplicate()


## Ids of every dish a reward may unlock, in file order.
func get_dish_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(_dish_names.keys())
	return ids


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
	# The starting crops are always unlocked, whatever the save says.
	_unlocked_crops.append_array(_start_crops)
	var saved_crops: Variant = data.get("unlocked_crops", [])
	if saved_crops is Array:
		for crop_id: Variant in saved_crops as Array:
			if not _unlocked_crops.has(str(crop_id)):
				_unlocked_crops.append(str(crop_id))
	var saved_dishes: Variant = data.get("unlocked_dishes", [])
	if saved_dishes is Array:
		for dish_id: Variant in saved_dishes as Array:
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


func _read_start_crops(raw: Variant, result: DataResult) -> Array[String]:
	var crops: Array[String] = []
	var where: String = "%s: start_unlocked_crops" % _SOURCE
	if not raw is Array:
		result.add_error(where, "must be a list of crop ids")
		return crops
	for item: Variant in raw as Array:
		if not item is String or (item as String).is_empty():
			result.add_error(where, "every entry must be a non-empty crop id")
		else:
			crops.append(item as String)
	return crops


func _read_dishes(raw: Variant, result: DataResult) -> Dictionary[String, String]:
	var names: Dictionary[String, String] = {}
	if not raw is Array:
		result.add_error(_SOURCE, "dishes must be a list (it may be empty)")
		return names
	var entries: Array = raw as Array
	for i: int in entries.size():
		var where: String = "%s: dishes[%d]" % [_SOURCE, i]
		if not entries[i] is Dictionary:
			result.add_error(where, "must be an object")
			continue
		var entry: Dictionary = entries[i] as Dictionary
		DataChecks.warn_unknown_keys(entry, _DISH_KEYS, where, result)
		var id: Variant = entry.get("id")
		if not id is String or (id as String).is_empty():
			result.add_error(where, "id must be a non-empty string")
			continue
		if names.has(id):
			result.add_error(where, "duplicate id '%s'" % id)
			continue
		var dish_name: Variant = entry.get("name")
		if not dish_name is String or (dish_name as String).is_empty():
			result.add_warning(where, "name is empty; showing the id")
			dish_name = id
		names[id as String] = dish_name as String
	return names


## Checks one neighbor and its requests; when the neighbor has a usable id it is added
## (with only its usable requests), so later errors can still be found.
func _read_neighbor(raw: Variant, where: String, result: DataResult,
		neighbors: Dictionary[String, Dictionary], neighbor_ids: Array[String],
		requests: Dictionary[String, Dictionary], request_seasons: Dictionary[String, String]) -> void:
	if not raw is Dictionary:
		result.add_error(where, "must be an object")
		return
	var entry: Dictionary = (raw as Dictionary).duplicate(true)
	DataChecks.warn_unknown_keys(entry, _NEIGHBOR_KEYS, where, result)
	var id: Variant = entry.get("id")
	var id_ok: bool = id is String and not (id as String).is_empty()
	if not id_ok:
		result.add_error(where, "id must be a non-empty string")
	elif neighbors.has(id):
		result.add_error(where, "duplicate id '%s'" % id)
		id_ok = false
	if not entry.get("name") is String or (entry["name"] as String).is_empty():
		result.add_warning(where, "name is empty; showing the id")
		entry["name"] = id if id is String else ""
	if not DataChecks.is_valid_colour(entry.get("color")):
		result.add_warning(where, "color is not #rrggbb or #rrggbbaa; using white")
		entry["color"] = "#ffffff"
	var valid_requests: Array = []
	var raw_requests: Variant = entry.get("requests")
	if not raw_requests is Array or (raw_requests as Array).is_empty():
		result.add_error(where, "requests must be a non-empty list")
	else:
		var list: Array = raw_requests as Array
		for j: int in list.size():
			_read_request(list[j], "%s.requests[%d]" % [where, j], result, valid_requests,
					requests, request_seasons)
	if id_ok:
		entry["requests"] = valid_requests
		neighbors[id as String] = entry
		neighbor_ids.append(id as String)


func _read_request(raw: Variant, where: String, result: DataResult, valid_requests: Array,
		requests: Dictionary[String, Dictionary], request_seasons: Dictionary[String, String]) -> void:
	if not raw is Dictionary:
		result.add_error(where, "must be an object")
		return
	var entry: Dictionary = (raw as Dictionary).duplicate(true)
	DataChecks.warn_unknown_keys(entry, _REQUEST_KEYS, where, result)
	var id: Variant = entry.get("id")
	var id_ok: bool = id is String and not (id as String).is_empty()
	if not id_ok:
		result.add_error(where, "id must be a non-empty string")
	elif requests.has(id):
		result.add_error(where, "duplicate id '%s' (request ids are unique over the whole file)" % id)
		id_ok = false
	var season: Variant = entry.get("season")
	if not season is String or (season as String).is_empty():
		result.add_error(where, "season must be a non-empty season id")
	for key: String in _REQUEST_TEXT_KEYS:
		if not entry.get(key) is String or (entry[key] as String).is_empty():
			result.add_warning(where, "%s is empty" % key)
	_read_require(entry, where, result)
	_read_reward(entry, where, result)
	if entry.has("min_level"):
		var min_level: Variant = entry["min_level"]
		if not DataChecks.is_whole(min_level) or int(min_level) < 0:
			result.add_error(where, "min_level must be a whole number of at least 0")
	if id_ok:
		requests[id as String] = entry
		request_seasons[id as String] = season as String if season is String else ""
		valid_requests.append(entry)


## Checks the require object and turns its quantities into ints.
func _read_require(entry: Dictionary, where: String, result: DataResult) -> void:
	var require: Variant = entry.get("require")
	if not require is Dictionary or (require as Dictionary).is_empty():
		result.add_error(where, "require must be an object with at least one crop")
		return
	var table: Dictionary = require as Dictionary
	for crop_id: Variant in table:
		var quantity: Variant = table[crop_id]
		if not DataChecks.is_whole(quantity) or int(quantity) <= 0:
			result.add_error(where, "require.%s must be a whole number greater than 0" % str(crop_id))
		else:
			table[crop_id] = int(quantity)


## Checks the reward object; money becomes an int (negative values are clamped to 0).
func _read_reward(entry: Dictionary, where: String, result: DataResult) -> void:
	var reward: Variant = entry.get("reward")
	if not reward is Dictionary:
		result.add_error(where, "reward must be an object")
		return
	var table: Dictionary = reward as Dictionary
	DataChecks.warn_unknown_keys(table, _REWARD_KEYS, where + ".reward", result)
	var money: Variant = table.get("money")
	if not DataChecks.is_number(money):
		result.add_error(where, "reward.money must be a number")
	elif float(money) < 0.0:
		result.add_warning(where, "reward.money is negative; using 0")
		table["money"] = 0
	else:
		table["money"] = int(money)
	for key: String in ["unlock_crop", "unlock_dish"]:
		if not table.has(key):
			table[key] = ""
		elif not table[key] is String:
			result.add_error(where, "reward.%s must be an id or an empty string" % key)


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
