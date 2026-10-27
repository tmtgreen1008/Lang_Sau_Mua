class_name DataLoader
extends RefCounted
## The one place that reads JSON data files (ADR-0003, rule 2). Reports problems with
## the file name, line and reason instead of returning an empty Dictionary, so a broken
## data file stops startup with a usable message. Nothing else may call
## JSON.parse_string on game data: it gives no line or reason.
##
## Usage:
##   var result: DataResult = DataLoader.read_json("res://assets/data/crops.json")
##   if result.ok(): crops.configure(result.data, result)

const _BOM: int = 0xFEFF


## Reads and parses [param path]. On success [member DataResult.data] is the root object.
static func read_json(path: String) -> DataResult:
	if not FileAccess.file_exists(path):
		var missing := DataResult.new()
		missing.add_error(path, "file not found")
		return missing
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var unreadable := DataResult.new()
		unreadable.add_error(path, "cannot open the file (error %d)" % FileAccess.get_open_error())
		return unreadable
	var text: String = file.get_as_text()
	file.close()
	return parse_text(text, path)


## Parses [param text]; [param source] names it in messages (usually the file path).
## Pure: touches no file, so tests can pass hand-written strings.
static func parse_text(text: String, source: String) -> DataResult:
	var result := DataResult.new()
	var body: String = text
	if not body.is_empty() and body.unicode_at(0) == _BOM:
		body = body.substr(1)
		result.add_warning(source, "file starts with a UTF-8 BOM; ignored (save it without one)")
	var json := JSON.new()
	if json.parse(body) != OK:
		# get_error_line() counts from 0 (verified on 4.7.2); editors count from 1.
		result.add_error(source, "invalid JSON at line %d: %s" % [
				json.get_error_line() + 1, json.get_error_message()])
		return result
	if not json.data is Dictionary:
		result.add_error(source, "root must be an object")
		return result
	result.data = json.data as Dictionary
	return result
