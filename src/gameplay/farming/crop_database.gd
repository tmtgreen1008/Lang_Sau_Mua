class_name CropDatabase
extends RefCounted
## Read-only crop definitions loaded from an external JSON file.
##
## Usage:
##   var db := CropDatabase.new()
##   if db.load_from_file("res://assets/data/crops.json"):
##       print(db.get_crop_name("ngo"), " grows in ", db.get_growth_days("ngo"), " days")

## Crop id -> definition Dictionary (id, name, growth_days, sell_price, seasons, color).
var _crops: Dictionary = {}
var _ids: Array[String] = []


## Loads crop definitions from [param path]. Returns false (and logs) on any error.
func load_from_file(path: String) -> bool:
	_crops.clear()
	_ids.clear()
	if not FileAccess.file_exists(path):
		push_error("CropDatabase: file not found: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("CropDatabase: invalid JSON root in %s" % path)
		return false
	var list: Variant = (parsed as Dictionary).get("crops")
	if not list is Array:
		push_error("CropDatabase: missing 'crops' array in %s" % path)
		return false
	for entry: Variant in list as Array:
		if not entry is Dictionary:
			continue
		var crop: Dictionary = entry
		var id: String = str(crop.get("id", ""))
		if id.is_empty() or int(crop.get("growth_days", 0)) <= 0:
			push_error("CropDatabase: skipping invalid crop entry: %s" % str(crop))
			continue
		_crops[id] = crop
		_ids.append(id)
	return not _ids.is_empty()


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
