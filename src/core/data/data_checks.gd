class_name DataChecks
extends RefCounted
## Type checks shared by every data module (ADR-0003, rule 7). JSON turns every number
## into a float, and GDScript's int() would silently turn 2.7 into 2 and "abc" into 0, so
## modules check with these instead of converting first.
##
## Usage:
##   if not DataChecks.is_whole(entry.get("growth_days")): result.add_error(...)


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
