class_name GameConfig
extends RefCounted
## Gameplay numbers that used to be written into the code (ADR-0003 rule 8), read from
## assets/data/game_config.json. Every key is required: there is no default in the code, so a
## missing key stops the game at startup instead of quietly changing how it plays. Before a
## successful [method configure] the getters return 0, which breaks the game visibly rather
## than hiding a missing configure behind a believable value.
##
## Pixel layout constants (stall and neighbor positions, font sizes) are not here; the phone
## display and UI decisions own those.
##
## Usage:
##   var config := GameConfig.new()
##   var result := DataLoader.read_json(DataPaths.path(DataPaths.GAME_CONFIG))
##   config.configure(result.data, result)
##   player.speed = config.player_speed()

const _SOURCE: String = "game_config.json"
const _SECTIONS: Dictionary[String, Array] = {
	"player": ["speed", "radius"],
	"field": ["columns", "rows", "tile_size"],
	"hud": ["message_seconds"],
}
## Keys that must be whole numbers of at least 1; every other key is a number above 0.
const _WHOLE_KEYS: Array[String] = ["field.columns", "field.rows"]

var _values: Dictionary[String, float] = {}
var _configured: bool = false


## Checks [param data] (the shape of game_config.json), records every problem in
## [param result] and, only when this call added no error, replaces the values. On errors the
## previous values stay. Errors already in [param result] (from other files) do not block it.
## A key that is not part of the format only adds a warning (typo catcher).
func configure(data: Dictionary, result: DataResult) -> void:
	var errors_before: int = DataChecks.error_count(result)
	DataChecks.warn_unknown_keys(data, _SECTIONS.keys(), _SOURCE, result)
	var values: Dictionary[String, float] = {}
	for section: String in _SECTIONS:
		var raw: Variant = data.get(section)
		if not raw is Dictionary:
			result.add_error(_SOURCE, "%s must be an object" % section)
			continue
		var table: Dictionary = raw as Dictionary
		DataChecks.warn_unknown_keys(table, _SECTIONS[section], "%s: %s" % [_SOURCE, section], result)
		for key: String in _SECTIONS[section]:
			_read_value(table.get(key), "%s.%s" % [section, key], result, values)
	if DataChecks.error_count(result) > errors_before:
		return
	_values = values
	_configured = true


## True after a configure that found no error.
func is_configured() -> bool:
	return _configured


## How fast the player walks, in pixels per second.
func player_speed() -> float:
	return _value("player.speed")


## Radius of the player figure, in pixels.
func player_radius() -> float:
	return _value("player.radius")


## Number of columns of the field.
func field_columns() -> int:
	return int(_value("field.columns"))


## Number of rows of the field.
func field_rows() -> int:
	return int(_value("field.rows"))


## Side of one field tile, in pixels.
func tile_size() -> float:
	return _value("field.tile_size")


## How long a HUD message stays visible, in seconds.
func message_seconds() -> float:
	return _value("hud.message_seconds")


func _read_value(raw: Variant, name: String, result: DataResult, values: Dictionary[String, float]) -> void:
	if _WHOLE_KEYS.has(name):
		if not DataChecks.is_whole(raw) or int(raw) < 1:
			result.add_error(_SOURCE, "%s must be a whole number of at least 1" % name)
			return
	elif not DataChecks.is_number(raw) or float(raw) <= 0.0:
		result.add_error(_SOURCE, "%s must be a number greater than 0" % name)
		return
	values[name] = float(raw)


func _value(name: String) -> float:
	return _values.get(name, 0.0)
