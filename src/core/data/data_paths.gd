class_name DataPaths
extends RefCounted
## The one place that names the data files and the folder they live in (ADR-0003 rule 1), so
## paths are not scattered through Main. A new data file is added here and to the folder
## check in tests/unit/data/data_paths_test.gd.
##
## Usage:
##   var result := DataLoader.read_json(DataPaths.path(DataPaths.CROPS))
##   var in_tests := DataPaths.path(DataPaths.CROPS, "user://test_data/")

const DEFAULT_DIR: String = "res://assets/data/"
const CROPS: String = "crops.json"
const TIME_CONFIG: String = "time_config.json"
const NEIGHBORS: String = "neighbors.json"
const VILLAGE: String = "village_restoration.json"
const GAME_CONFIG: String = "game_config.json"


## Every data file name, in the order Main loads them.
static func all_files() -> Array[String]:
	return [CROPS, TIME_CONFIG, NEIGHBORS, VILLAGE, GAME_CONFIG]


## Full path of [param file_name] inside [param dir] (a trailing '/' is optional).
static func path(file_name: String, dir: String = DEFAULT_DIR) -> String:
	return (dir if dir.ends_with("/") else dir + "/") + file_name
