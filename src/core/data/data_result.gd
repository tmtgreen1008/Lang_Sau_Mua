class_name DataResult
extends RefCounted
## Outcome of reading or validating game data (ADR-0003, rule 3): the parsed content
## plus every error and warning found, each tagged with where it was found. Modules
## write into one shared result instead of stopping at the first problem, so the
## player-visible startup error lists everything that is wrong at once.
##
## Errors block startup; warnings do not (ADR-0003, rule 5). Each list keeps at most
## [constant MAX_ENTRIES] entries; further ones only raise the matching counter, so a
## wrong schema cannot produce thousands of lines.
##
## Usage:
##   var result := DataResult.new()
##   result.add_error("crops.json: crops[2]", "growth_days must be greater than 0")
##   if not result.ok(): ...   # result.errors, result.dropped_errors

const MAX_ENTRIES: int = 200

## Parsed content (the JSON root object); empty when reading failed.
var data: Dictionary = {}
## Blocking problems, each "where: message".
var errors: Array[String] = []
## Non-blocking problems, each "where: message".
var warnings: Array[String] = []
## Errors beyond [constant MAX_ENTRIES] that were counted but not stored.
var dropped_errors: int = 0
## Warnings beyond [constant MAX_ENTRIES] that were counted but not stored.
var dropped_warnings: int = 0


## True when no error was recorded (stored or dropped).
func ok() -> bool:
	return errors.is_empty() and dropped_errors == 0


## Records a blocking problem. [param where] is the file and the path inside it.
func add_error(where: String, message: String) -> void:
	if errors.size() >= MAX_ENTRIES:
		dropped_errors += 1
		return
	errors.append("%s: %s" % [where, message])


## Records a non-blocking problem. [param where] is the file and the path inside it.
func add_warning(where: String, message: String) -> void:
	if warnings.size() >= MAX_ENTRIES:
		dropped_warnings += 1
		return
	warnings.append("%s: %s" % [where, message])


## Appends every error and warning of [param other] (already formatted) after this result's
## own, keeping the [constant MAX_ENTRIES] cap: what does not fit, and what [param other] had
## already dropped, is only counted. [member data] is not copied. Main uses this to gather the
## results of every data file into one.
func absorb(other: DataResult) -> void:
	for line: String in other.errors:
		if errors.size() >= MAX_ENTRIES:
			dropped_errors += 1
		else:
			errors.append(line)
	dropped_errors += other.dropped_errors
	for line: String in other.warnings:
		if warnings.size() >= MAX_ENTRIES:
			dropped_warnings += 1
		else:
			warnings.append(line)
	dropped_warnings += other.dropped_warnings
