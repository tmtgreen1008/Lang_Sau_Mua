class_name Main
extends Node2D
## Entry scene: wires the farm logic (FarmGrid) to its display (FarmView), the
## touch-controlled Player and the Hud. Implements story 001 (design/game-brief.md,
## MVP feature 1).
##
## Tapping a field tile walks the player there and applies the selected tool on
## arrival; tapping elsewhere just walks.

const FIELD_TOP: float = 128.0
## The market stall sits this far right of the field, at this height.
const STALL_GAP_X: float = 60.0
const STALL_TOP: float = 190.0
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

## Folder the data files are read from. Test seam: tests point it at a copy they can break;
## it must be set before the node enters the tree, because _ready() loads the data.
var _data_dir: String = DataPaths.DEFAULT_DIR
var _config: GameConfig = GameConfig.new()
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
var _village: VillageProgress = VillageProgress.new()
var _village_view: VillageView
## HUD line about a restored village piece, waiting for the neighbor panel to close.
var _village_text: String = ""
## Story 006: reads and writes user://savegame.json.
var _save_game: SaveGame = SaveGame.new()
## "data" of the save accepted by _accept_save, already upgraded to the current format.
var _upgraded_data: Dictionary = {}
## JSON of the state last written successfully; an identical state is not written again.
var _last_saved_state: String = ""
## False when a data file failed to load; input and clock are then skipped.
var _initialised: bool = false
## True while the player walks to the stall to open the market.
var _pending_stall: bool = false
## Field cell to act on when the player arrives, or FarmView.INVALID_CELL.
var _pending_cell: Vector2i = FarmView.INVALID_CELL


## Startup (ADR-0002 rule 9 and 12): build once, wire once, then load the save. A data problem
## stops here with a message on screen; nothing is built, ticked or saved.
func _ready() -> void:
	if not _build():
		return
	_wire()
	_load_saved_game()
	_initialised = true


## Reads and checks every data file, then builds the modules and nodes. Returns false (after
## showing the startup error screen) when the data is wrong. Runs once.
func _build() -> bool:
	var problems: DataResult = _load_data()
	for line: String in problems.warnings:
		push_warning("Main: %s" % line)
	if not problems.ok():
		_show_startup_error(problems)
		return false
	_build_world()
	return true


## Reads the five data files into their modules. Every file is checked on its own and every
## problem is gathered; the cross-file check only runs when all of them passed, and says so
## when it was skipped (a silent skip would read as "nothing found").
func _load_data() -> DataResult:
	var problems := DataResult.new()
	var targets: Array[Array] = [[DataPaths.CROPS, _db], [DataPaths.TIME_CONFIG, _clock],
			[DataPaths.NEIGHBORS, _book], [DataPaths.VILLAGE, _village],
			[DataPaths.GAME_CONFIG, _config]]
	var failed: Array[String] = []
	for target: Array in targets:
		var file_name: String = target[0]
		var read: DataResult = DataLoader.read_json(DataPaths.path(file_name, _data_dir))
		if read.ok():
			(target[1] as Object).call("configure", read.data, read)
		if not read.ok():
			failed.append(file_name)
		problems.absorb(read)
	if failed.is_empty():
		problems.absorb(DataValidator.new().validate(_db, _clock, _book, _village))
	else:
		problems.errors.push_front("Lưu ý: kiểm chéo bị bỏ qua vì %s lỗi, nên chưa kiểm được quan hệ giữa các file." % ", ".join(failed))
	return problems


func _show_startup_error(problems: DataResult) -> void:
	var screen := StartupErrorScreen.new()
	add_child(screen)
	screen.show_errors(problems.errors, problems.dropped_errors)


## Creates the field, the people and the interface from the checked data. No signal is
## connected here; that is _wire().
func _build_world() -> void:
	_grid = FarmGrid.new(_db, _config.field_columns(), _config.field_rows())
	var viewport_size: Vector2 = get_viewport_rect().size
	var tile_size: float = _config.tile_size()
	var field_width: float = _config.field_columns() * tile_size

	var field_position := Vector2((viewport_size.x - field_width) * 0.5, FIELD_TOP)

	# The village is added first so it is drawn behind the field, stall and neighbors.
	_village_view = VillageView.new()
	_village_view.position = field_position
	add_child(_village_view)
	_village_view.setup(_village)

	_farm_view = FarmView.new()
	_farm_view.position = field_position
	add_child(_farm_view)
	_farm_view.setup(_grid, _db, _config)

	_player = Player.new()
	_player.position = Vector2(viewport_size.x * 0.5,
			FIELD_TOP + _config.field_rows() * tile_size + 24.0)
	add_child(_player)
	_player.setup(_config)

	_market = Market.new(_grid, _db)
	_stall = MarketStallView.new()
	_stall.position = Vector2(_farm_view.position.x + field_width + STALL_GAP_X, STALL_TOP)
	add_child(_stall)

	var field_right: float = _farm_view.position.x + field_width
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
	_hud.setup(_db, _config)
	_hud.set_unlocked_crops(_book.get_unlocked_crops())
	_hud.set_inventory(_grid.inventory)
	_hud.set_money(_market.money)

	_market_panel = MarketPanel.new()
	add_child(_market_panel)
	_market_panel.setup(_db)
	_neighbor_panel = NeighborPanel.new()
	add_child(_neighbor_panel)
	_neighbor_panel.setup(_db, _book)
	_dish_panel = DishPanel.new()
	add_child(_dish_panel)
	_dish_panel.setup(_book)


## Every connection between modules, injected query and starting display. Runs once: "new game"
## and reloading a save reset the modules with from_dict instead, so nothing is connected
## twice. The order of the clock handlers is the order of the signals' emission by DayClock
## (season, phase, day), so the connect order here is not significant between signals.
func _wire() -> void:
	_grid.crop_unlock_check = _book.is_crop_unlocked
	_player.arrived.connect(_on_player_arrived)
	_market.money_changed.connect(_hud.set_money)
	_market.inventory_changed.connect(_on_market_inventory_changed)
	_market_panel.sell_requested.connect(_on_sell_requested)
	_neighbor_panel.hand_over_requested.connect(_on_hand_over_requested)
	_neighbor_panel.visibility_changed.connect(_on_neighbor_panel_visibility_changed)
	_hud.dishes_requested.connect(_dish_panel.open)
	_hud.sleep_requested.connect(_on_sleep_requested)
	_book.crop_unlocked.connect(_on_crop_unlocked)
	_book.request_completed.connect(_on_book_request_completed)
	_book.season_requests_completed.connect(_on_season_requests_completed)
	_village.piece_restored.connect(_on_village_piece_restored)
	_grid.crop_harvested.connect(_on_crop_harvested)
	_clock.phase_changed.connect(_on_phase_changed)
	_clock.season_changed.connect(_on_season_changed)
	_clock.day_advanced.connect(_on_day_advanced)
	_grid.current_season = _clock.get_season_id()
	_refresh_time_hud()


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
	if _any_panel_open() or _hud.blocks_point(canvas_position):
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


## App lifecycle (ADR-0004 rule 5). Leaving the foreground stops the clock and saves; coming
## back restarts it. Each notification family has its own pause source because the order they
## arrive in on a phone is not known; RESUMED means "in the foreground" and clears the app
## sources as a safety net. The panel source is not touched here (see _process).
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_clock.set_paused(DayClock.PAUSE_APP, true)
			save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			_clock.set_paused(DayClock.PAUSE_APP, false)
			_clock.set_paused(DayClock.PAUSE_FOCUS, false)
			_clock.set_paused(DayClock.PAUSE_WINDOW, false)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_clock.set_paused(DayClock.PAUSE_FOCUS, true)
			save_game()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_clock.set_paused(DayClock.PAUSE_FOCUS, false)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_clock.set_paused(DayClock.PAUSE_WINDOW, true)
			save_game()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_clock.set_paused(DayClock.PAUSE_WINDOW, false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back_requested()


## The Back button never quits the app (ADR-0004 rule 7; the project setting
## application/config/quit_on_go_back is off): it closes the open panel. Opening the pause
## panel when nothing is open waits for the UI ADR.
func _on_back_requested() -> void:
	if not _initialised:
		return
	for panel: Variant in [_dish_panel, _neighbor_panel, _market_panel]:
		if panel.is_open():
			panel.close()
			return


## Writes the whole game state to the save file. Returns false when nothing was written
## (also before the game finished starting, so a failed start never overwrites a save, and
## while SaveGame blocks writing). Returns true without writing when the state is identical
## to the last successful write, so back-to-back lifecycle saves do not rotate the backup.
func save_game() -> bool:
	if not _initialised:
		return false
	var state: Dictionary = {
		"farm": _grid.to_dict(),
		"clock": _clock.to_dict(),
		"market": _market.to_dict(),
		"neighbors": _book.to_dict(),
		"village": _village.to_dict(),
	}
	var fingerprint: String = JSON.stringify(state)
	if fingerprint == _last_saved_state:
		return true
	if not _save_game.save(state):
		return false
	_last_saved_state = fingerprint
	return true


## True while any panel that covers the map is open (market, neighbors, dishes).
func _any_panel_open() -> bool:
	return _market_panel.is_open() or _neighbor_panel.is_open() or _dish_panel.is_open()


## Startup: applies the last save if there is one. A save the game cannot use is left exactly
## as it is and SaveGame blocks saving, so the player's file is never overwritten (ADR-0005);
## the choice between retrying and a new game comes with the startup error screen (ADR-0002).
func _load_saved_game() -> void:
	var result: LoadResult = _save_game.load_state(_accept_save)
	match result.status:
		LoadResult.Status.NO_SAVE:
			return
		LoadResult.Status.NEWER_VERSION:
			push_warning("Main: %s" % result.message)
			_hud.show_message("Bản lưu từ phiên bản game mới hơn; game sẽ không ghi đè lên nó.")
			return
		LoadResult.Status.UNREADABLE:
			push_warning("Main: %s" % result.message)
			_hud.show_message("Không đọc được file lưu; game sẽ không ghi đè lên nó. Hãy mở lại game.")
			return
		LoadResult.Status.CORRUPT:
			push_warning("Main: %s" % result.message)
			_hud.show_message("File lưu bị hỏng; game sẽ không ghi đè lên nó.")
			return
	if result.version < SaveGame.FORMAT_VERSION:
		_save_game.backup_loaded_file(result.version)
	if result.status == LoadResult.Status.RECOVERED:
		_hud.show_message("Đã khôi phục từ bản lưu trước.")
	var state: Dictionary = _upgraded_data
	_grid.from_dict(state["farm"] as Dictionary)
	_clock.from_dict(state["clock"] as Dictionary)
	_market.from_dict(state["market"] as Dictionary)
	_book.from_dict(state["neighbors"] as Dictionary)
	_village.from_dict(state["village"] as Dictionary)
	# The loaders emit nothing: refresh every display by hand, without effects.
	_grid.current_season = _clock.get_season_id()
	_hud.set_unlocked_crops(_book.get_unlocked_crops())
	_hud.set_inventory(_grid.inventory)
	_hud.set_money(_market.money)
	_refresh_time_hud()
	_farm_view.queue_redraw()
	_village_view.sync_instant()


## SaveGame calls this for every well-formed save file it considers: upgrades it to the
## current format and checks its sections. Returns "" when usable, else the reason.
func _accept_save(root: Dictionary) -> String:
	var upgraded: UpgradeResult = SaveMigrations.upgrade(root)
	if not upgraded.ok:
		return upgraded.message
	var data: Dictionary = upgraded.root["data"] as Dictionary
	var problems: Array[String] = SaveMigrations.validate_sections(data)
	if not problems.is_empty():
		return ", ".join(problems)
	_upgraded_data = data
	return ""


## The panel pause source is recomputed every frame from the panels themselves, so there is
## no state to forget to clear (ADR-0004 rule 9).
func _process(delta: float) -> void:
	if not _initialised:
		return
	_clock.set_paused(DayClock.PAUSE_PANEL, _any_panel_open())
	_clock.tick(delta)


func _refresh_time_hud() -> void:
	_hud.set_time_info(_clock.day_number, _clock.get_phase_name(), _clock.get_season_name())


## DayClock.sleep() ignores pause, so a panel being open has to be checked here.
func _on_sleep_requested() -> void:
	if _any_panel_open():
		return
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
	save_game()


func _on_crop_harvested(crop_id: String) -> void:
	_hud.set_inventory(_grid.inventory)
	_hud.show_message("Thu hoạch được 1 %s!" % _db.get_crop_name(crop_id))


func _on_sell_requested(crop_id: String, quantity: int) -> void:
	var sold: int = _market.sell(crop_id, quantity)
	if sold > 0:
		_hud.show_message("Bán %d %s, được %d tiền." % [
				sold, _db.get_crop_name(crop_id), sold * _market.get_unit_price(crop_id)])
		save_game()
	else:
		# Nothing sold (stale picker or empty stock): resync the panel and say so.
		_market_panel.refresh(_grid.inventory)
		_hud.show_message("Không bán được %s." % _db.get_crop_name(crop_id))


func _on_market_inventory_changed() -> void:
	_hud.set_inventory(_grid.inventory)
	_market_panel.refresh(_grid.inventory)


func _on_hand_over_requested(neighbor_id: String) -> void:
	_just_completed_season = ""
	# The panel dims the map: let the village effect play once it is closed.
	_village_view.effects_held = _neighbor_panel.is_open()
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
	save_game()


## The village counts requests through Main; it does not know the neighbor book.
func _on_book_request_completed(_neighbor_id: String, _request_id: String, _money: int) -> void:
	_village.on_request_completed(_book.get_completed_count())


func _on_crop_unlocked(_crop_id: String) -> void:
	_hud.set_unlocked_crops(_book.get_unlocked_crops())


func _on_village_piece_restored(piece_id: String) -> void:
	_village_text = "Làng đã dựng lại thêm %s!" % _village.get_piece_name(piece_id)
	if not _neighbor_panel.is_open():
		_hud.show_message(_village_text)
		_village_text = ""


## Once the neighbor panel closes: play the held village effect and announce it.
func _on_neighbor_panel_visibility_changed() -> void:
	if _neighbor_panel.is_open():
		return
	_village_view.effects_held = false
	if not _village_text.is_empty():
		_hud.show_message(_village_text)
		_village_text = ""


func _on_season_requests_completed(season_id: String) -> void:
	_just_completed_season = season_id
	print("Main: all neighbor requests of season '%s' are done." % season_id)
	season_requests_completed.emit(season_id)
