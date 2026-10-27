class_name DataValidator
extends RefCounted
## Checks that the data files agree with each other (ADR-0003, rule 7). Each file is checked
## on its own by its module's configure(); this class only checks the relations that need two
## files at once, so Main runs it after every file passed its own check. Every rule here is
## fatal: a broken relation means a request, crop or village piece that cannot work.
##
## The rules:
##  - every crop and request season is a season of time_config.json;
##  - every crop named by a requirement, an unlock or the starting crops exists in crops.json,
##    and every unlocked dish exists in neighbors.json;
##  - every request can be completed by following the unlocks (no request waits for a crop
##    that nothing unlocks, or for a request behind it);
##  - village pieces and levels fit the number of requests that exist;
##  - when requests use min_level: every village level can still be reached (the count of
##    requests open at one level must reach the next level's threshold).
##
## Usage:
##   var result: DataResult = DataValidator.new().validate(crops, clock, book, village)
##   if not result.ok(): show(result.errors)

const _CROPS: String = "crops.json"
const _NEIGHBORS: String = "neighbors.json"
const _VILLAGE: String = "village_restoration.json"


## Returns a result holding every broken relation as an error. The modules are only read.
func validate(crops: CropDatabase, clock: DayClock, book: NeighborBook,
		village: VillageProgress) -> DataResult:
	var result := DataResult.new()
	var seasons: Array[String] = clock.get_season_ids()
	_check_crop_seasons(crops, seasons, result)
	_check_request_references(crops, book, seasons, result)
	_check_requests_can_be_completed(crops, book, result)
	var total: int = _request_count(book)
	_check_village_pieces(village, total, result)
	_check_village_levels(village, total, result)
	_check_min_levels(book, village, result)
	return result


func _check_crop_seasons(crops: CropDatabase, seasons: Array[String], result: DataResult) -> void:
	for crop_id: String in crops.get_crop_ids():
		for season: Variant in crops.get_crop(crop_id)["seasons"] as Array:
			if not seasons.has(season):
				result.add_error("%s: crop '%s'" % [_CROPS, crop_id],
						"season '%s' is not in time_config.json (%s)" % [season, ", ".join(seasons)])


func _check_request_references(crops: CropDatabase, book: NeighborBook, seasons: Array[String],
		result: DataResult) -> void:
	for crop_id: String in book.get_start_crops():
		if not crops.has_crop(crop_id):
			result.add_error("%s: start_unlocked_crops" % _NEIGHBORS,
					"crop '%s' is not in crops.json" % crop_id)
	var dishes: Array[String] = book.get_dish_ids()
	for neighbor_id: String in book.get_neighbor_ids():
		for request: Variant in book.get_requests(neighbor_id):
			var def: Dictionary = request as Dictionary
			var where: String = "%s: request '%s'" % [_NEIGHBORS, def["id"]]
			if not seasons.has(def["season"]):
				result.add_error(where, "season '%s' is not in time_config.json (%s)" % [
						def["season"], ", ".join(seasons)])
			for crop_id: Variant in def["require"] as Dictionary:
				if not crops.has_crop(str(crop_id)):
					result.add_error(where, "requires crop '%s', which is not in crops.json" % crop_id)
			var reward: Dictionary = def["reward"] as Dictionary
			var unlock_crop: String = reward["unlock_crop"] as String
			if not unlock_crop.is_empty() and not crops.has_crop(unlock_crop):
				result.add_error(where, "unlocks crop '%s', which is not in crops.json" % unlock_crop)
			var unlock_dish: String = reward["unlock_dish"] as String
			if not unlock_dish.is_empty() and not dishes.has(unlock_dish):
				result.add_error(where, "unlocks dish '%s', which is not in the dishes list" % unlock_dish)


## Plays the game forward on paper: a neighbor's next request can be done once every crop it
## needs is unlocked, and completing it unlocks its reward crop. Whatever is left when nothing
## more can be done is stuck; only the first stuck request of each neighbor is reported (the
## ones behind it wait for it anyway). Crops missing from crops.json are reported elsewhere.
func _check_requests_can_be_completed(crops: CropDatabase, book: NeighborBook,
		result: DataResult) -> void:
	var unlocked: Array[String] = book.get_start_crops()
	var next_index: Dictionary[String, int] = {}
	for neighbor_id: String in book.get_neighbor_ids():
		next_index[neighbor_id] = 0
	var progressed: bool = true
	while progressed:
		progressed = false
		for neighbor_id: String in book.get_neighbor_ids():
			var requests: Array = book.get_requests(neighbor_id)
			while next_index[neighbor_id] < requests.size():
				var def: Dictionary = requests[next_index[neighbor_id]] as Dictionary
				if not _missing_crops(def, unlocked, crops).is_empty():
					break
				var unlock_crop: String = (def["reward"] as Dictionary)["unlock_crop"] as String
				if not unlock_crop.is_empty() and not unlocked.has(unlock_crop):
					unlocked.append(unlock_crop)
				next_index[neighbor_id] += 1
				progressed = true
	for neighbor_id: String in book.get_neighbor_ids():
		var requests: Array = book.get_requests(neighbor_id)
		if next_index[neighbor_id] < requests.size():
			var stuck: Dictionary = requests[next_index[neighbor_id]] as Dictionary
			result.add_error("%s: request '%s'" % [_NEIGHBORS, stuck["id"]],
					"can never be completed: needs %s, which no reachable reward unlocks" % ", ".join(
					_missing_crops(stuck, unlocked, crops)))


## Crops the request needs that exist but are not unlocked yet.
func _missing_crops(def: Dictionary, unlocked: Array[String], crops: CropDatabase) -> Array[String]:
	var missing: Array[String] = []
	for crop_id: Variant in def["require"] as Dictionary:
		if crops.has_crop(str(crop_id)) and not unlocked.has(str(crop_id)):
			missing.append("'%s'" % crop_id)
	return missing


func _request_count(book: NeighborBook) -> int:
	var total: int = 0
	for neighbor_id: String in book.get_neighbor_ids():
		total += book.get_requests(neighbor_id).size()
	return total


func _check_village_pieces(village: VillageProgress, total: int, result: DataResult) -> void:
	for piece: Dictionary in village.get_piece_defs():
		if int(piece["unlock_at"]) > total:
			result.add_error("%s: piece '%s'" % [_VILLAGE, piece["id"]],
					"unlock_at %d is above the number of requests (%d), so it could never be restored" % [
					int(piece["unlock_at"]), total])


func _check_village_levels(village: VillageProgress, total: int, result: DataResult) -> void:
	var levels: Array[Dictionary] = village.get_level_defs()
	if int(levels[0]["min_requests"]) != 0:
		result.add_error(_VILLAGE, "the lowest level must start at 0 requests (min_requests is %d)" % int(
				levels[0]["min_requests"]))
	for i: int in levels.size():
		var where: String = "%s: level %d" % [_VILLAGE, int(levels[i]["level"])]
		if int(levels[i]["min_requests"]) > total:
			result.add_error(where, "min_requests %d is above the number of requests (%d)" % [
					int(levels[i]["min_requests"]), total])
		if i == 0:
			continue
		if int(levels[i]["min_requests"]) == int(levels[i - 1]["min_requests"]):
			result.add_error(where, "min_requests %d is the same as level %d; levels must differ" % [
					int(levels[i]["min_requests"]), int(levels[i - 1]["level"])])
		if int(levels[i]["level"]) <= int(levels[i - 1]["level"]):
			result.add_error(where, "needs more requests than level %d, so its number must be higher" %
					int(levels[i - 1]["level"]))


## Only runs when some request has min_level. A request is open once the village is at its
## level AND the earlier requests of the same neighbor are done, so its effective level is the
## highest min_level up to and including it. For each level L the number of requests open at
## L must reach the next level's threshold, or the village could never grow past L.
func _check_min_levels(book: NeighborBook, village: VillageProgress, result: DataResult) -> void:
	var levels: Array[Dictionary] = village.get_level_defs()
	var lowest: int = int(levels[0]["level"])
	var highest: int = int(levels[levels.size() - 1]["level"])
	var any_min_level: bool = false
	var effective: Array[int] = []
	for neighbor_id: String in book.get_neighbor_ids():
		var running: int = lowest
		for request: Variant in book.get_requests(neighbor_id):
			var def: Dictionary = request as Dictionary
			if def.has("min_level"):
				any_min_level = true
				var min_level: int = int(def["min_level"])
				if min_level > highest:
					result.add_error("%s: request '%s'" % [_NEIGHBORS, def["id"]],
							"min_level %d is above the highest village level (%d)" % [min_level, highest])
				running = maxi(running, min_level)
			effective.append(running)
	if not any_min_level:
		return
	for i: int in levels.size() - 1:
		var open_count: int = 0
		for level: int in effective:
			if level <= int(levels[i]["level"]):
				open_count += 1
		var needed: int = int(levels[i + 1]["min_requests"])
		if open_count < needed:
			result.add_error("%s: level %d" % [_VILLAGE, int(levels[i + 1]["level"])],
					"can never be reached: only %d requests are open at level %d but it needs %d" % [
					open_count, int(levels[i]["level"]), needed])
