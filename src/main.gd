class_name Main
extends Node2D
## Entry scene: wires the farm logic (FarmGrid) to its display (FarmView), the
## touch-controlled Player and the Hud. Implements story 001 (design/game-brief.md,
## MVP feature 1).
##
## Tapping a field tile walks the player there and applies the selected tool on
## arrival; tapping elsewhere just walks.

const CROPS_PATH: String = "res://assets/data/crops.json"
const FIELD_COLUMNS: int = 5
const FIELD_ROWS: int = 4
const FIELD_TOP: float = 100.0
const GROUND_COLOR: Color = Color(0.45, 0.68, 0.38)

## Vietnamese feedback when a tool cannot be used on the tapped plot.
const FAIL_MESSAGES: Dictionary = {
	FarmGrid.Tool.HOE: "Chỉ cuốc được ô đất trống hoặc cây héo.",
	FarmGrid.Tool.SEED: "Cần ô đã cuốc và còn trống để gieo.",
	FarmGrid.Tool.WATER: "Ô này không có cây cần tưới.",
	FarmGrid.Tool.HARVEST: "Chưa có cây chín để thu hoạch.",
}

var _db: CropDatabase = CropDatabase.new()
var _grid: FarmGrid
var _farm_view: FarmView
var _player: Player
var _hud: Hud
## Field cell to act on when the player arrives, or FarmView.INVALID_CELL.
var _pending_cell: Vector2i = FarmView.INVALID_CELL


func _ready() -> void:
	_db.load_from_file(CROPS_PATH)
	_grid = FarmGrid.new(_db, FIELD_COLUMNS, FIELD_ROWS)
	var viewport_size: Vector2 = get_viewport_rect().size

	_farm_view = FarmView.new()
	_farm_view.position = Vector2(
			(viewport_size.x - FIELD_COLUMNS * FarmView.TILE_SIZE) * 0.5, FIELD_TOP)
	add_child(_farm_view)
	_farm_view.setup(_grid, _db)

	_player = Player.new()
	_player.position = Vector2(viewport_size.x * 0.5, FIELD_TOP + FIELD_ROWS * FarmView.TILE_SIZE + 24.0)
	add_child(_player)
	_player.arrived.connect(_on_player_arrived)

	_hud = Hud.new()
	add_child(_hud)
	_hud.setup(_db)
	_hud.set_inventory(_grid.inventory)
	_hud.next_day_requested.connect(_on_next_day_requested)
	_grid.crop_harvested.connect(_on_crop_harvested)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), GROUND_COLOR)


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		_on_tap(touch.position)
		return
	var mouse := event as InputEventMouseButton
	# Touches also arrive as emulated mouse clicks; skip those to avoid a double tap.
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and mouse.device != InputEvent.DEVICE_ID_EMULATION:
		_on_tap(mouse.position)


func _on_tap(canvas_position: Vector2) -> void:
	if _hud.blocks_point(canvas_position):
		return
	var cell: Vector2i = _farm_view.cell_at(canvas_position)
	_pending_cell = cell
	if cell == FarmView.INVALID_CELL:
		_player.move_to(canvas_position)
	else:
		_player.move_to(_farm_view.cell_center(cell))


func _on_player_arrived() -> void:
	if _pending_cell == FarmView.INVALID_CELL:
		return
	var cell: Vector2i = _pending_cell
	_pending_cell = FarmView.INVALID_CELL
	var tool: FarmGrid.Tool = _hud.current_tool
	if not _grid.apply_tool(tool, cell, _hud.current_crop_id):
		_hud.show_message(str(FAIL_MESSAGES[tool]))


func _on_next_day_requested() -> void:
	_grid.advance_day()
	_hud.show_message("Ngày mới! Cây đã tưới lớn thêm, cây khô héo mất vụ.")


func _on_crop_harvested(crop_id: String) -> void:
	_hud.set_inventory(_grid.inventory)
	_hud.show_message("Thu hoạch được 1 %s!" % _db.get_crop_name(crop_id))
