class_name LoadResult
extends RefCounted
## Outcome of [method SaveGame.load_state] (ADR-0005, rule 9). Loading never renames or
## deletes a file: the status tells the caller what happened and what is allowed next.

enum Status {
	OK, ## The main file was read and accepted.
	NO_SAVE, ## No usable save file exists (a lone half-written temp file counts as none).
	NEWER_VERSION, ## A file is from a newer game version: not read, not touched, no saving.
	UNREADABLE, ## A file could not be opened or read (maybe temporary): not touched, no saving.
	CORRUPT, ## Files were read but none is usable: untouched, no saving.
	RECOVERED, ## A temp or backup file was used because the main file was not.
}

var status: Status = Status.NO_SAVE
## Format version found in the file (0 when no file was used or understood).
var version: int = 0
## The raw "data" object of the accepted file, not yet upgraded.
var data: Dictionary = {}
## Which file was used: "main", "tmp" or "bak" (empty when none).
var source: String = ""
## The reason, for the log and the player-visible message.
var message: String = ""
