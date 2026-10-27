class_name DataFixtures
extends RefCounted
## Small hand-written data sets that are valid on their own and agree with each other, for the
## tests that check how the data files relate (DataValidator). Each factory returns a fresh
## Dictionary so a test can break one detail without touching the others.
##
## The set: three crops, two seasons (ha, thu), four requests (ba_tu_1, ba_tu_2, chu_ba_1,
## chu_ba_2), three village levels (0, 2 and 4 requests) and two pieces (1 and 3 requests).
## ngo is plantable from the start; ba_tu_1 unlocks ca_chua and chu_ba_1 unlocks cai_xanh.

const TOTAL_REQUESTS: int = 4


static func crops() -> Dictionary:
	return {
		"crops": [
			{"id": "ngo", "name": "Ngô", "growth_days": 4, "sell_price": 50,
					"seasons": ["ha", "thu"], "color": "#f0c93c"},
			{"id": "ca_chua", "name": "Cà chua", "growth_days": 3, "sell_price": 30,
					"seasons": ["ha"], "color": "#e0463a"},
			{"id": "cai_xanh", "name": "Cải xanh", "growth_days": 2, "sell_price": 15,
					"seasons": ["thu"], "color": "#5fbf4a"},
		],
	}


static func clock() -> Dictionary:
	return {
		"phases": [
			{"id": "morning", "name": "Sáng", "seconds": 10.0},
			{"id": "evening", "name": "Tối", "seconds": 10.0},
		],
		"days_per_season": 2,
		"seasons": [{"id": "ha", "name": "Mùa hạ"}, {"id": "thu", "name": "Mùa thu"}],
		"max_step_seconds": 1.0,
		"day_speed": {"normal": 1.0, "slow": 0.5, "stop": 0.0},
	}


static func neighbors() -> Dictionary:
	return {
		"start_unlocked_crops": ["ngo"],
		"dishes": [{"id": "canh_ca_chua", "name": "Canh cà chua"}],
		"neighbors": [
			{"id": "ba_tu", "name": "Bà Tư", "color": "#c0653b", "requests": [
				_request("ba_tu_1", "ha", {"ngo": 2}, "ca_chua", ""),
				_request("ba_tu_2", "thu", {"ca_chua": 3}, "", "canh_ca_chua"),
			]},
			{"id": "chu_ba", "name": "Chú Ba", "color": "#3b7ec0", "requests": [
				_request("chu_ba_1", "ha", {"ngo": 3}, "cai_xanh", ""),
				_request("chu_ba_2", "thu", {"cai_xanh": 4}, "", ""),
			]},
		],
	}


static func village() -> Dictionary:
	return {
		"effect": {"duration": 1.0, "flash": 0.45, "pulse_scale": 0.08},
		"levels": [
			{"level": 1, "min_requests": 0, "name": "Hoang tàn", "ground_tint": "#5a4630b0"},
			{"level": 2, "min_requests": 2, "name": "Đang hồi sinh", "ground_tint": "#d8b86020"},
			{"level": 3, "min_requests": 4, "name": "Sung túc", "ground_tint": "#ffc85a48"},
		],
		"pieces": [
			_piece("house_1", 1),
			_piece("house_2", 3),
		],
	}


## The request Dictionary at [param request_index] of the neighbor at [param neighbor_index].
static func request(data: Dictionary, neighbor_index: int, request_index: int) -> Dictionary:
	var neighbor: Dictionary = (data["neighbors"] as Array)[neighbor_index] as Dictionary
	return (neighbor["requests"] as Array)[request_index] as Dictionary


static func _request(id: String, season: String, require: Dictionary, unlock_crop: String,
		unlock_dish: String) -> Dictionary:
	return {
		"id": id, "season": season,
		"offer_text": "Con giúp nhé.", "missing_text": "Chưa đủ.", "done_text": "Cảm ơn.",
		"require": require,
		"reward": {"money": 10, "unlock_crop": unlock_crop, "unlock_dish": unlock_dish},
	}


static func _piece(id: String, unlock_at: int) -> Dictionary:
	return {
		"id": id, "name": "một ngôi nhà", "unlock_at": unlock_at, "origin": [0, 0], "size": [10, 10],
		"shapes": [{"kind": "rect", "ruined": {"g": [0, 0, 5, 5], "color": "#4a3524"}, "restored": null}],
	}
