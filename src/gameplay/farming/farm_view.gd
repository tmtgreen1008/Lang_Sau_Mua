class_name FarmView
extends Node2D
## Draws a FarmGrid as coloured placeholder tiles and converts positions to cells.
## Holds no farm rules; it only reads the grid.
##
## Usage:
##   var view := FarmView.new()
##   view.setup(grid, db)
##   var cell: Vector2i = view.cell_at(tap_position)

const TILE_GAP: float = 4.0
const INVALID_CELL: Vector2i = Vector2i(-1, -1)

const COLOR_EMPTY: Color = Color(0.62, 0.56, 0.38)
const COLOR_TILLED: Color = Color(0.40, 0.27, 0.16)
const COLOR_WATERED: Color = Color(0.24, 0.17, 0.13)
const COLOR_WITHERED: Color = Color(0.45, 0.40, 0.30)
const COLOR_WATER_EDGE: Color = Color(0.35, 0.6, 0.95)
const COLOR_RIPE_EDGE: Color = Color(1.0, 0.85, 0.2)

## Side of one tile in pixels. Comes from GameConfig through [method setup]; 0 until then.
var tile_size: float = 0.0

var _grid: FarmGrid
var _db: CropDatabase


## Binds the view to [param grid], takes the tile size from [param config] and redraws when
## the grid changes.
func setup(grid: FarmGrid, db: CropDatabase, config: GameConfig) -> void:
	_grid = grid
	_db = db
	tile_size = config.tile_size()
	_grid.plot_changed.connect(_on_plot_changed)
	queue_redraw()


## Cell under a canvas-space position, or INVALID_CELL when outside the field.
func cell_at(canvas_position: Vector2) -> Vector2i:
	var local: Vector2 = to_local(canvas_position) / tile_size
	var cell := Vector2i(floori(local.x), floori(local.y))
	return cell if _grid.is_valid_cell(cell) else INVALID_CELL


## Canvas-space centre of [param cell].
func cell_center(cell: Vector2i) -> Vector2:
	return to_global((Vector2(cell) + Vector2(0.5, 0.5)) * tile_size)


func _on_plot_changed(_cell: Vector2i) -> void:
	queue_redraw()


func _draw() -> void:
	for y: int in _grid.rows:
		for x: int in _grid.columns:
			_draw_plot(Vector2i(x, y))


func _draw_plot(cell: Vector2i) -> void:
	var rect := Rect2(Vector2(cell) * tile_size + Vector2(TILE_GAP, TILE_GAP) * 0.5,
			Vector2(tile_size - TILE_GAP, tile_size - TILE_GAP))
	var center: Vector2 = rect.get_center()
	var state: FarmGrid.PlotState = _grid.get_state(cell)
	var base: Color = COLOR_EMPTY
	match state:
		FarmGrid.PlotState.TILLED, FarmGrid.PlotState.PLANTED:
			base = COLOR_WATERED if _grid.is_watered(cell) else COLOR_TILLED
		FarmGrid.PlotState.WITHERED:
			base = COLOR_WITHERED
	draw_rect(rect, base)
	if _grid.is_watered(cell):
		draw_rect(rect, COLOR_WATER_EDGE, false, 3.0)
	if state == FarmGrid.PlotState.PLANTED:
		var crop_color: Color = _db.get_crop_color(_grid.get_crop_id(cell))
		var radius: float = 8.0 + 22.0 * _grid.get_growth_progress(cell)
		draw_circle(center, radius, crop_color)
		if _grid.is_ripe(cell):
			draw_arc(center, radius + 5.0, 0.0, TAU, 32, COLOR_RIPE_EDGE, 4.0)
	elif state == FarmGrid.PlotState.WITHERED:
		draw_circle(center, 10.0, Color(0.3, 0.25, 0.2))
