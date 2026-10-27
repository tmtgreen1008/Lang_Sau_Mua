class_name UpgradeResult
extends RefCounted
## Outcome of [method SaveMigrations.upgrade]: the upgraded save, or why it could not be
## upgraded. A failed upgrade changes nothing (ADR-0005, rule 3).

## True when the save now has the target version.
var ok: bool = false
## The upgraded envelope {"version": int, "data": Dictionary}; empty when [member ok] is false.
var root: Dictionary = {}
## Why the upgrade failed (empty when it worked).
var message: String = ""
