class_name FarmGrid
extends RefCounted
## Pure farm logic: a grid of plots, tools, crop growth and the harvest inventory.
## No scene or node dependencies, so it can be unit tested directly.
##
## Usage:
##   var grid := FarmGrid.new(db, 5, 4)
##   grid.apply_tool(FarmGrid.Tool.HOE, Vector2i(0, 0))
##   grid.apply_tool(FarmGrid.Tool.SEED, Vector2i(0, 0), "ngo")
##   grid.apply_tool(FarmGrid.Tool.WATER, Vector2i(0, 0))
##   grid.advance_day()  # watered crops grow one stage, unwatered growing crops wither

## Emitted when a plot's state, growth or watering changed.
signal plot_changed(cell: Vector2i)
## Emitted after a ripe crop was added to the inventory.
signal crop_harvested(crop_id: String)

enum Tool { HOE, SEED, WATER, HARVEST }
enum PlotState { EMPTY, TILLED, PLANTED, WITHERED }

## Mutable per-plot data.
class Plot:
	var state: FarmGrid.PlotState = FarmGrid.PlotState.EMPTY
	var crop_id: String = ""
	var days_grown: int = 0
	var watered: bool = false

var columns: int
var rows: int
## Harvested produce: crop_id -> count.
var inventory: Dictionary = {}

## Current season id (set by story 002's clock). Empty means no season restriction.
var current_season: String = ""

var _db: CropDatabase
var _plots: Array[Plot] = []


func _init(db: CropDatabase, grid_columns: int, grid_rows: int) -> void:
	_db = db
	columns = grid_columns
	rows = grid_rows
	for i: int in columns * rows:
		_plots.append(Plot.new())
	for crop_id: String in _db.get_crop_ids():
		inventory[crop_id] = 0


func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows


func get_state(cell: Vector2i) -> PlotState:
	return _plot(cell).state


func get_crop_id(cell: Vector2i) -> String:
	return _plot(cell).crop_id


func is_watered(cell: Vector2i) -> bool:
	return _plot(cell).watered


## True when a planted crop has grown for its full growth_days.
func is_ripe(cell: Vector2i) -> bool:
	var plot: Plot = _plot(cell)
	return plot.state == PlotState.PLANTED and plot.days_grown >= _db.get_growth_days(plot.crop_id)


## Growth progress in 0.0 .. 1.0 (0 when nothing is planted).
func get_growth_progress(cell: Vector2i) -> float:
	var plot: Plot = _plot(cell)
	if plot.crop_id.is_empty():
		return 0.0
	return clampf(float(plot.days_grown) / float(_db.get_growth_days(plot.crop_id)), 0.0, 1.0)


## Applies [param tool] to [param cell]. [param crop_id] is only used by Tool.SEED.
## Returns true when the action changed something.
func apply_tool(tool: Tool, cell: Vector2i, crop_id: String = "") -> bool:
	if not is_valid_cell(cell):
		return false
	match tool:
		Tool.HOE:
			return _till(cell)
		Tool.SEED:
			return _plant(cell, crop_id)
		Tool.WATER:
			return _water(cell)
		Tool.HARVEST:
			return _harvest(cell)
	return false


## Advances the farm by one day. A planted, unripe crop that was watered grows one
## stage; one that was not watered withers (the harvest is lost, nothing else
## happens). Ripe crops wait to be harvested. Watering is reset for the next day.
## Story 002 calls this automatically at the start of each day.
func advance_day() -> void:
	for y: int in rows:
		for x: int in columns:
			var cell := Vector2i(x, y)
			var plot: Plot = _plot(cell)
			var changed: bool = plot.watered
			if plot.state == PlotState.PLANTED and not is_ripe(cell):
				if plot.watered:
					plot.days_grown += 1
				else:
					plot.state = PlotState.WITHERED
				changed = true
			plot.watered = false
			if changed:
				plot_changed.emit(cell)


func _plot(cell: Vector2i) -> Plot:
	return _plots[cell.y * columns + cell.x]


## Empty land becomes tilled; a withered crop is cleared back to tilled soil.
func _till(cell: Vector2i) -> bool:
	var plot: Plot = _plot(cell)
	if plot.state != PlotState.EMPTY and plot.state != PlotState.WITHERED:
		return false
	plot.state = PlotState.TILLED
	plot.crop_id = ""
	plot.days_grown = 0
	plot.watered = false
	plot_changed.emit(cell)
	return true


## True when [param crop_id] may be planted in [member current_season] (always true
## while no season is set). Unknown crops are never plantable.
func can_plant_in_season(crop_id: String) -> bool:
	if not _db.has_crop(crop_id):
		return false
	if current_season.is_empty():
		return true
	var seasons: Variant = _db.get_crop(crop_id).get("seasons", [])
	return seasons is Array and (seasons as Array).has(current_season)


func _plant(cell: Vector2i, crop_id: String) -> bool:
	var plot: Plot = _plot(cell)
	if plot.state != PlotState.TILLED or not can_plant_in_season(crop_id):
		return false
	plot.state = PlotState.PLANTED
	plot.crop_id = crop_id
	plot.days_grown = 0
	plot.watered = false
	plot_changed.emit(cell)
	return true


func _water(cell: Vector2i) -> bool:
	var plot: Plot = _plot(cell)
	if plot.state != PlotState.PLANTED or plot.watered or is_ripe(cell):
		return false
	plot.watered = true
	plot_changed.emit(cell)
	return true


func _harvest(cell: Vector2i) -> bool:
	if not is_ripe(cell):
		return false
	var plot: Plot = _plot(cell)
	var harvested_id: String = plot.crop_id
	inventory[harvested_id] = int(inventory.get(harvested_id, 0)) + 1
	plot.state = PlotState.TILLED
	plot.crop_id = ""
	plot.days_grown = 0
	plot.watered = false
	plot_changed.emit(cell)
	crop_harvested.emit(harvested_id)
	return true
