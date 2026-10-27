class_name SaveMigrations
extends RefCounted
## Upgrades old save files to the current format (ADR-0005, rules 3 and 7). Pure: no files,
## no signals. Every step works on a copy, so a failing step leaves the original untouched.
##
## A step is a function migrate_vN_to_vN+1(data: Dictionary) -> Variant that returns the new
## "data" Dictionary, or a String giving the reason it failed. The steps for versions
## 1 .. FORMAT_VERSION-1 are listed in order by [method migration_table]. Whoever raises
## SaveGame.FORMAT_VERSION must add the step, freeze a tests/fixtures/saves/v<N>.json and
## extend the tests; the table-size test and the fixture suite fail otherwise.
##
## Usage:
##   var upgraded: UpgradeResult = SaveMigrations.upgrade(root)   # root = {version, data}
##   if upgraded.ok: apply(upgraded.root["data"])

## Sections the current format must contain in "data", each an object.
const REQUIRED_SECTIONS: Array[String] = ["farm", "clock", "market", "neighbors", "village"]


## The migration steps, step i upgrading version i+1 to i+2. Empty while FORMAT_VERSION is 1.
static func migration_table() -> Array[Callable]:
	return []


## Upgrades [param root] ({"version", "data"}) to [constant SaveGame.FORMAT_VERSION].
static func upgrade(root: Dictionary) -> UpgradeResult:
	return upgrade_with(root, SaveGame.FORMAT_VERSION, migration_table())


## Same as [method upgrade] with an explicit target and step table (used by tests).
static func upgrade_with(root: Dictionary, target_version: int, table: Array[Callable]) -> UpgradeResult:
	var raw_version: Variant = root.get("version")
	if not DataChecks.is_whole(raw_version):
		return _fail("version is not a whole number")
	var version: int = int(raw_version)
	if version < 1:
		return _fail("version %d is not a known format" % version)
	if version > target_version:
		return _fail("version %d is newer than the supported version %d" % [version, target_version])
	if not root.get("data") is Dictionary:
		return _fail("'data' is not an object")
	var data: Dictionary = (root["data"] as Dictionary).duplicate(true)
	while version < target_version:
		if version > table.size():
			return _fail("no migration from version %d to %d" % [version, version + 1])
		var step: Variant = table[version - 1].call(data)
		if step is String:
			return _fail("migration from version %d to %d failed: %s" % [version, version + 1, step])
		if not step is Dictionary:
			return _fail("migration from version %d to %d returned neither data nor a reason" % [
					version, version + 1])
		data = step as Dictionary
		version += 1
	var result := UpgradeResult.new()
	result.ok = true
	result.root = {"version": target_version, "data": data}
	return result


## Problems with the sections of [param data] for the current format; empty when it is complete.
static func validate_sections(data: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for section: String in REQUIRED_SECTIONS:
		if not data.has(section):
			problems.append("missing section '%s'" % section)
		elif not data[section] is Dictionary:
			problems.append("section '%s' is not an object" % section)
	return problems


static func _fail(message: String) -> UpgradeResult:
	var result := UpgradeResult.new()
	result.message = message
	return result
