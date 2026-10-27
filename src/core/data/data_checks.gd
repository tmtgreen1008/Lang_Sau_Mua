class_name DataChecks
extends RefCounted
## Type checks shared by every data module (ADR-0003, rule 7). JSON turns every number
## into a float, and GDScript's int() would silently turn 2.7 into 2 and "abc" into 0, so
## modules check with these instead of converting first.
##
## Usage:
##   if not DataChecks.is_whole(entry.get("growth_days")): result.add_error(...)
##   var errors_before: int = DataChecks.error_count(result)   # ... then compare after checking
##   DataChecks.warn_unknown_keys(entry, ["id", "name"], "crops.json: crops[0]", result)


## True for an int, or a finite float. False for bool, String, null, NAN and INF.
static func is_number(value: Variant) -> bool:
	match typeof(value):
		TYPE_INT:
			return true
		TYPE_FLOAT:
			return is_finite(value as float)
	return false


## True for an int, or a finite float with no fractional part (3.0 counts, 2.5 does not).
static func is_whole(value: Variant) -> bool:
	match typeof(value):
		TYPE_INT:
			return true
		TYPE_FLOAT:
			var number: float = value as float
			return is_finite(number) and number == floorf(number)
	return false


## True for a String in the data-file colour format: a leading '#' then hex digits
## (#rrggbb or #rrggbbaa; the engine also takes the short forms). Names such as "red" are
## not accepted: Color.from_string would read them, but the files must stay explicit, and
## Color.html_is_valid alone would also accept a string with no '#' (verified on 4.7.2).
static func is_valid_colour(value: Variant) -> bool:
	if not value is String:
		return false
	var text: String = value as String
	return text.begins_with("#") and Color.html_is_valid(text)


## Adds a warning to [param result] for every key of [param data] that is not in
## [param known_keys] and does not start with '_' (those are documentation, always ignored).
## Catches typos in key names that would otherwise be silently dropped (ADR-0003 rule 5).
static func warn_unknown_keys(data: Dictionary, known_keys: Array, where: String,
		result: DataResult) -> void:
	for key: Variant in data:
		var name: String = str(key)
		if not name.begins_with("_") and not known_keys.has(name):
			result.add_warning(where, "unknown key '%s' (typo?)" % name)


## Number of errors recorded in [param result], including those dropped beyond the cap.
## A module compares it before and after its own checks to know whether this call added any.
static func error_count(result: DataResult) -> int:
	return result.errors.size() + result.dropped_errors
