class_name Main
extends Node2D
## Entry scene: wires the farm logic (FarmGrid) to its display (FarmView), the
## touch-controlled Player and the Hud. Implements story 001 (design/game-brief.md,
## MVP feature 1).
##
## Tapping a field tile walks the player there and applies the selected tool on
## arrival; tapping elsewhere just walks.

const CROPS_PATH: String = "res://assets/data/crops.json"
const TIME_CONFIG_PATH: String = "res://assets/data/time_config.json"
const FIELD_COLUMNS: int = 5
const FIELD_ROWS: int = 4
const FIELD_TOP: float = 128.0
## The market stall sits this far right of the field, at this height.
const STALL_GAP_X: float = 60.0
const STALL_TOP: float = 190.0
const NEIGHBORS_PATH: String = "res://assets/data/neighbors.json"
## Neighbors stand in a row below the stall, right of the field: clear of the field,
## the stall and the bottom HUD rows on the 1152x648 base (and any wider viewport).
const NEIGHBOR_FIRST_GAP_X: float = 60.0
const NEIGHBOR_SPACING_X: float = 100.0
const NEIGHBOR_TOP: float = 370.0
const GROUND_COLOR: Color = Color(0.45, 0.68, 0.38)

## Emitted when every request of a season is done (forwarded from NeighborBook; story 005).
signal season_requests_completed(season_id: String)

## Vietnamese feedback when a tool cannot be used on the tapped plot.
const FAIL_MESSAGES: Dictionary = {
	FarmGrid.Tool.HOE: "Chỉ cuốc được ô đất trống hoặc cây héo.",
	FarmGrid.Tool.SEED: "Cần ô đã cuốc và còn trống để gieo.",
	FarmGrid.Tool.WATER: "Ô này không có cây cần tưới.",
	FarmGrid.Tool.HARVEST: "Chưa có cây chín để thu hoạch.",
}

var _db: CropDatabase = CropDatabase.new()
var _clock: DayClock = DayClock.new()
var _grid: FarmGrid
var _farm_view: FarmView
var _player: Player
var _hud: Hud
var _market: Market
var _stall: MarketStallView
var _market_panel: MarketPanel
var _book: NeighborBook = NeighborBook.new()
## neighbor_id -> map figure.
var _neighbor_views: Dictionary[String, NeighborView] = {}
var _neighbor_panel: NeighborPanel
var _dish_panel: DishPanel
## Neighbor to talk to once the player arrives, or "".
var _pending_neighbor: String = ""
## Season completed by the hand-over being processed, or "".
var _just_completed_season: String = ""
## False when a data file failed to load; input and clock are then skipped.
var _initialised: bool = false
## True while the player walks to the stall to open the market.
var _pending_stall: bool = false
## Field cell to act on when the player arrives, or FarmView.INVALID_CELL.
var _pending_cell: Vector2i = FarmView.INVALID_CELL


func _ready() -> void:
	if not _db.load_from_file(CROPS_PATH):
		push_error("Main: cannot load crop data from %s; the game will not start." % CROPS_PATH)
		return
	if not _clock.load_from_file(TIME_CONFIG_PATH):
		push_error("Main: cannot load time config from %s; the game will not start." % TIME_CONFIG_PATH)
		return
	if not _book.load_from_file(NEIGHBORS_PATH):
		push_error("Main: cannot load neighbor data from %s; the game will not start." % NEIGHBORS_PATH)
		return
	_grid = FarmGrid.new(_db, FIELD_COLUMNS, FIELD_ROWS)
	_grid.crop_unlock_check = _book.is_crop_unlocked
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

	_market = Market.new(_grid, _db)
	_stall = MarketStallView.new()
	_stall.position = Vector2(
			_farm_view.position.x + FIELD_COLUMNS * FarmView.TILE_SIZE + STALL_GAP_X, STALL_TOP)
	add_child(_stall)

	var field_right: float = _farm_view.position.x + FIELD_COLUMNS * FarmView.TILE_SIZE
	var slot: int = 0
	for neighbor_id: String in _book.get_neighbor_ids():
		var view := NeighborView.new()
		view.setup(_book.get_neighbor_name(neighbor_id), _book.get_neighbor_color(neighbor_id))
		view.position = Vector2(
				field_right + NEIGHBOR_FIRST_GAP_X + slot * NEIGHBOR_SPACING_X, NEIGHBOR_TOP)
		add_child(view)
		_neighbor_views[neighbor_id] = view
		slot += 1

	_hud = Hud.new()
	add_child(_hud)
	_hud.setup(_db)
	_hud.set_unlocked_crops(_book.get_unlocked_crops())
	_hud.set_inventory(_grid.inventory)
	_hud.set_money(_market.money)
	_market.money_changed.connect(_hud.set_money)
	_market.inventory_changed.connect(_on_market_inventory_changed)

	_market_panel = MarketPanel.new()
	add_child(_market_panel)
	_market_panel.setup(_db)
	_market_panel.sell_requested.connect(_on_sell_requested)
	_neighbor_panel = NeighborPanel.new()
	add_child(_neighbor_panel)
	_neighbor_panel.setup(_db, _book)
	_neighbor_panel.hand_over_requested.connect(_on_hand_over_requested)
	_dish_panel = DishPanel.new()
	add_child(_dish_panel)
	_dish_panel.setup(_book)
	_hud.dishes_requested.connect(_dish_panel.open)
	_book.crop_unlocked.connect(_on_crop_unlocked)
	_book.season_requests_completed.connect(_on_season_requests_completed)
	_hud.sleep_requested.connect(_on_sleep_requested)
	_grid.crop_harvested.connect(_on_crop_harvested)
	_clock.phase_changed.connect(_on_phase_changed)
	_clock.season_changed.connect(_on_season_changed)
	_clock.day_advanced.connect(_on_day_advanced)
	_grid.current_season = _clock.get_season_id()
	_refresh_time_hud()
	_initialised = true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), GROUND_COLOR)


func _unhandled_input(event: InputEvent) -> void:
	if not _initialised:
		return
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
	if _market_panel.is_open() or _neighbor_panel.is_open() or _dish_panel.is_open() \
			or _hud.blocks_point(canvas_position):
		return
	_pending_neighbor = ""
	for neighbor_id: String in _neighbor_views:
		if _neighbor_views[neighbor_id].contains_point(canvas_position):
			_pending_neighbor = neighbor_id
			break
	if not _pending_neighbor.is_empty():
		_pending_stall = false
		_pending_cell = FarmView.INVALID_CELL
		_player.move_to(_neighbor_views[_pending_neighbor].get_center())
		return
	_pending_stall = _stall.contains_point(canvas_position)
	if _pending_stall:
		_pending_cell = FarmView.INVALID_CELL
		_player.move_to(_stall.get_center())
		return
	var cell: Vector2i = _farm_view.cell_at(canvas_position)
	_pending_cell = cell
	if cell == FarmView.INVALID_CELL:
		_player.move_to(canvas_position)
	else:
		_player.move_to(_farm_view.cell_center(cell))


func _on_player_arrived() -> void:
	if not _pending_neighbor.is_empty():
		var neighbor_id: String = _pending_neighbor
		_pending_neighbor = ""
		_neighbor_panel.open(neighbor_id, _grid.inventory)
		return
	if _pending_stall:
		_pending_stall = false
		# TODO: the story allows opening the market at any phase; gate by phase later if wanted.
		_market_panel.open(_grid.inventory)
		return
	if _pending_cell == FarmView.INVALID_CELL:
		return
	var cell: Vector2i = _pending_cell
	_pending_cell = FarmView.INVALID_CELL
	var tool: FarmGrid.Tool = _hud.current_tool
	if not _grid.apply_tool(tool, cell, _hud.current_crop_id):
		if tool == FarmGrid.Tool.SEED and not _grid.is_crop_unlocked(_hud.current_crop_id):
			_hud.show_message("Chưa có hạt giống này. Giúp hàng xóm để mở khoá.")
		elif tool == FarmGrid.Tool.SEED and not _grid.can_plant_in_season(_hud.current_crop_id):
			_hud.show_message("%s không gieo được vào %s." % [
					_db.get_crop_name(_hud.current_crop_id), _clock.get_season_name()])
		else:
			_hud.show_message(str(FAIL_MESSAGES[tool]))


func _process(delta: float) -> void:
	if not _initialised:
		return
	_clock.tick(delta)


func _refresh_time_hud() -> void:
	_hud.set_time_info(_clock.day_number, _clock.get_phase_name(), _clock.get_season_name())


func _on_sleep_requested() -> void:
	_clock.sleep()


func _on_phase_changed(_phase_id: String) -> void:
	_refresh_time_hud()


func _on_season_changed(season_id: String) -> void:
	_grid.current_season = season_id
	_hud.show_message("Sang %s! Chỉ gieo được cây hợp mùa." % _clock.get_season_name())


func _on_day_advanced(day_number: int) -> void:
	_grid.advance_day()
	_refresh_time_hud()
	_hud.show_message("Ngày %d! Cây đã tưới lớn thêm, cây khô héo mất vụ." % day_number)


func _on_crop_harvested(crop_id: String) -> void:
	_hud.set_inventory(_grid.inventory)
	_hud.show_message("Thu hoạch được 1 %s!" % _db.get_crop_name(crop_id))


func _on_sell_requested(crop_id: String, quantity: int) -> void:
	var sold: int = _market.sell(crop_id, quantity)
	if sold > 0:
		_hud.show_message("Bán %d %s, được %d tiền." % [
				sold, _db.get_crop_name(crop_id), sold * _market.get_unit_price(crop_id)])
	else:
		# Nothing sold (stale picker or empty stock): resync the panel and say so.
		_market_panel.refresh(_grid.inventory)
		_hud.show_message("Không bán được %s." % _db.get_crop_name(crop_id))


func _on_market_inventory_changed() -> void:
	_hud.set_inventory(_grid.inventory)
	_market_panel.refresh(_grid.inventory)


func _on_hand_over_requested(neighbor_id: String) -> void:
	_just_completed_season = ""
	var request: Dictionary = _book.complete_request(neighbor_id, _grid.inventory)
	if request.is_empty():
		# Stale panel (nothing to hand over): resync it.
		_neighbor_panel.refresh(_grid.inventory)
		return
	_hud.set_inventory(_grid.inventory)
	var reward: Dictionary = request.get("reward", {})
	var parts: PackedStringArray = []
	var money: int = int(reward.get("money", 0))
	_market.add_money(money)
	if money > 0:
		parts.append("Nhận %d tiền." % money)
	var crop_id: String = str(reward.get("unlock_crop", ""))
	if not crop_id.is_empty():
		parts.append("Mở khoá hạt %s." % _db.get_crop_name(crop_id))
	var dish_id: String = str(reward.get("unlock_dish", ""))
	if not dish_id.is_empty():
		parts.append("Học món %s." % _book.get_dish_name(dish_id))
	if not _just_completed_season.is_empty():
		parts.append("Xong hết nhờ vả của mùa này!")
	var reward_text: String = " ".join(parts)
	_hud.show_message(reward_text)
	_neighbor_panel.show_result("%s\n%s" % [str(request.get("done_text", "")), reward_text])


func _on_crop_unlocked(_crop_id: String) -> void:
	_hud.set_unlocked_crops(_book.get_unlocked_crops())


func _on_season_requests_completed(season_id: String) -> void:
	_just_completed_season = season_id
	print("Main: all neighbor requests of season '%s' are done." % season_id)
	season_requests_completed.emit(season_id)
