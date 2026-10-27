class_name CropDatabase
extends RefCounted
## Read-only crop definitions loaded from an external JSON file (assets/data/crops.json).
## [method configure] checks the content and records every problem in a [DataResult];
## nothing is skipped silently (ADR-0003).
##
## Usage:
##   var db := CropDatabase.new()
##   var result := DataLoader.read_json("res://assets/data/crops.json")
##   db.configure(result.data, result)
##   if result.ok():
##       print(db.get_crop_name("ngo"), " grows in ", db.get_growth_days("ngo"), " days")

const _SOURCE: String = "crops.json"
const _TOP_KEYS: Array[String] = ["crops"]
const _CROP_KEYS: Array[String] = ["id", "name", "growth_days", "sell_price", "seasons", "color"]

## Crop id -> definition Dictionary (id, name, growth_days, sell_price, seasons, color).
var _crops: Dictionary = {}
var _ids: Array[String] = []


## Reads [param path] through [DataLoader] and applies it with [method configure]. Logs every
## problem and returns false when the content is unusable. A thin wrapper: Main gathers the
## results of all files itself and calls [method configure] directly.
func load_from_file(path: String) -> bool:
	var result: DataResult = DataLoader.read_json(path)
	if result.ok():
		configure(result.data, result)
	for message: String in result.errors:
		push_error("CropDatabase: %s" % message)
	for message: String in result.warnings:
		push_warning("CropDatabase: %s" % message)
	return result.ok()


## Checks [param data] (the shape of crops.json), records every problem in [param result]
## and, only when this call added no error, replaces the content. On errors the previous
## content stays. Errors already in [param result] (from other files) do not block it.
## Warnings (not errors): negative price (clamped to 0), empty name (the id is shown),
## invalid or missing colour (white), keys that are not part of the format.
func configure(data: Dictionary, result: DataResult) -> void:
	var errors_before: int = DataChecks.error_count(result)
	DataChecks.warn_unknown_keys(data, _TOP_KEYS, _SOURCE, result)
	var crops: Dictionary = {}
	var ids: Array[String] = []
	var raw: Variant = data.get("crops")
	if not raw is Array or (raw as Array).is_empty():
		result.add_error(_SOURCE, "crops must be a non-empty list")
	else:
		var entries: Array = raw as Array
		for i: int in entries.size():
			_read_crop(entries[i], "%s: crops[%d]" % [_SOURCE, i], result, crops, ids)
	if DataChecks.error_count(result) > errors_before:
		return
	_crops = crops
	_ids = ids


## Crop ids in file order.
func get_crop_ids() -> Array[String]:
	return _ids


func has_crop(crop_id: String) -> bool:
	return _crops.has(crop_id)


## Full definition Dictionary, or an empty one if unknown.
func get_crop(crop_id: String) -> Dictionary:
	return _crops.get(crop_id, {})


## Display name (Vietnamese). Falls back to the id.
func get_crop_name(crop_id: String) -> String:
	return str(get_crop(crop_id).get("name", crop_id))


## Days of watering needed before the crop is ripe.
func get_growth_days(crop_id: String) -> int:
	return int(get_crop(crop_id).get("growth_days", 1))


## Money for selling one unit of the crop (0 if unknown; never negative).
func get_sell_price(crop_id: String) -> int:
	return maxi(0, int(get_crop(crop_id).get("sell_price", 0)))


## Placeholder display colour.
func get_crop_color(crop_id: String) -> Color:
	return Color.from_string(str(get_crop(crop_id).get("color", "#ffffff")), Color.WHITE)


## Checks one crop entry and, when it is a usable object, adds a normalised copy.
func _read_crop(raw: Variant, where: String, result: DataResult, crops: Dictionary,
		ids: Array[String]) -> void:
	if not raw is Dictionary:
		result.add_error(where, "must be an object")
		return
	var entry: Dictionary = (raw as Dictionary).duplicate(true)
	DataChecks.warn_unknown_keys(entry, _CROP_KEYS, where, result)
	var id: Variant = entry.get("id")
	if not id is String or (id as String).is_empty():
		result.add_error(where, "id must be a non-empty string")
	elif crops.has(id):
		result.add_error(where, "duplicate id '%s'" % id)
	var growth_days: Variant = entry.get("growth_days")
	if not DataChecks.is_whole(growth_days) or int(growth_days) <= 0:
		result.add_error(where, "growth_days must be a whole number greater than 0")
	else:
		entry["growth_days"] = int(growth_days)
	var price: Variant = entry.get("sell_price")
	if not DataChecks.is_number(price):
		result.add_error(where, "sell_price must be a number")
	elif float(price) < 0.0:
		result.add_warning(where, "sell_price is negative; using 0")
		entry["sell_price"] = 0
	if not _is_list_of_ids(entry.get("seasons")):
		result.add_error(where, "seasons must be a non-empty list of season ids")
	if not entry.get("name") is String or (entry["name"] as String).is_empty():
		result.add_warning(where, "name is empty; showing the id")
		entry["name"] = id if id is String else ""
	if not DataChecks.is_valid_colour(entry.get("color")):
		result.add_warning(where, "color is not #rrggbb or #rrggbbaa; using white")
		entry["color"] = "#ffffff"
	if id is String and not (id as String).is_empty() and not crops.has(id):
		crops[id] = entry
		ids.append(id as String)


func _is_list_of_ids(value: Variant) -> bool:
	if not value is Array or (value as Array).is_empty():
		return false
	for item: Variant in value as Array:
		if not item is String or (item as String).is_empty():
			return false
	return true
