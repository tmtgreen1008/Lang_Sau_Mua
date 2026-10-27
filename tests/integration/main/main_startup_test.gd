extends GdUnitTestSuite
## Integration tests for Main's startup (ADR-0002 rules 6, 9, 11, 12 and ADR-0003 rules 5 to 8;
## src/main.gd). A real Main is added to the tree with two test seams set before add_child:
## _save_game points at a throwaway save folder and _data_dir at a throwaway copy of the data
## files, so the shipped files and the player's save are never touched. Each test breaks the
## copy in one way and looks at what the player would see.
##
## Not covered: the retry and new-game buttons for an unusable save (they wait for the UI ADR).

const DATA_DIR: String = "user://test_main_startup_data/"
const SAVE_DIR: String = "user://test_main_startup_save/"


func before_test() -> void:
	SaveTestSupport.remove_dir(DATA_DIR)
	SaveTestSupport.remove_dir(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	for file_name: String in DataPaths.all_files():
		SaveTestSupport.write_file(DATA_DIR, file_name,
				FileAccess.get_file_as_string(DataPaths.path(file_name)))


func after_test() -> void:
	SaveTestSupport.remove_dir(DATA_DIR)
	SaveTestSupport.remove_dir(SAVE_DIR)


# --- a good start ---------------------------------------------------------------------

func test_valid_data_starts_the_game_without_an_error_screen() -> void:
	# Arrange / Act
	var main: Main = _start_main()

	# Assert
	assert_object(_error_screen(main)).is_null()
	assert_bool(main.save_game()).is_true()


func test_game_config_values_reach_the_modules_that_used_them_as_constants() -> void:
	# Arrange
	_modify(DataPaths.GAME_CONFIG, func(data: Dictionary) -> void:
			data["player"] = {"speed": 300.0, "radius": 12.5}
			data["field"] = {"columns": 6, "rows": 3, "tile_size": 64.0}
			data["hud"] = {"message_seconds": 1.5})

	# Act
	var main: Main = _start_main()

	# Assert
	assert_object(_error_screen(main)).is_null()
	assert_float(main._player.speed).is_equal(300.0)
	assert_float(main._player.radius).is_equal(12.5)
	assert_float(main._farm_view.tile_size).is_equal(64.0)
	assert_float(main._hud.message_seconds).is_equal(1.5)
	assert_int(main._grid.columns).is_equal(6)
	assert_int(main._grid.rows).is_equal(3)


func test_warnings_do_not_stop_the_game() -> void:
	# Arrange: a typo in a key name is a warning, not an error.
	_modify(DataPaths.CROPS, func(data: Dictionary) -> void: data["crop"] = [])

	# Act
	var main: Main = _start_main()

	# Assert
	assert_object(_error_screen(main)).is_null()
	assert_bool(main.save_game()).is_true()


# --- a start that cannot work shows why -----------------------------------------------

func test_a_crop_with_zero_growth_days_shows_the_file_and_the_key() -> void:
	# Arrange
	_modify(DataPaths.CROPS, func(data: Dictionary) -> void:
			((data["crops"] as Array)[0] as Dictionary)["growth_days"] = 0)

	# Act
	var main: Main = _start_main()

	# Assert
	var text: String = _error_text(main)
	assert_str(text).contains("crops.json")
	assert_str(text).contains("growth_days")
	assert_bool(main.save_game()).is_false()


func test_a_missing_data_file_shows_its_name() -> void:
	# Arrange
	DirAccess.remove_absolute(DATA_DIR + DataPaths.NEIGHBORS)

	# Act
	var main: Main = _start_main()

	# Assert
	assert_str(_error_text(main)).contains("neighbors.json")


func test_a_data_file_that_is_not_valid_json_shows_its_name_and_the_line() -> void:
	# Arrange
	SaveTestSupport.write_file(DATA_DIR, DataPaths.TIME_CONFIG, '{\n"phases": [\n')

	# Act
	var main: Main = _start_main()

	# Assert
	var text: String = _error_text(main)
	assert_str(text).contains("time_config.json")
	assert_str(text).contains("line")


func test_errors_from_several_files_are_all_listed() -> void:
	# Arrange
	_modify(DataPaths.CROPS, func(data: Dictionary) -> void:
			((data["crops"] as Array)[0] as Dictionary)["growth_days"] = 0)
	_modify(DataPaths.GAME_CONFIG, func(data: Dictionary) -> void:
			(data["player"] as Dictionary)["speed"] = 0)

	# Act
	var main: Main = _start_main()

	# Assert
	var text: String = _error_text(main)
	assert_str(text).contains("crops.json")
	assert_str(text).contains("game_config.json")


func test_more_than_ten_errors_are_cut_with_a_count_of_the_rest() -> void:
	# Arrange: twelve crops that each have a broken growth_days.
	_modify(DataPaths.CROPS, func(data: Dictionary) -> void:
			var crops: Array = []
			for i: int in 12:
				crops.append({"id": "crop_%d" % i, "name": "Cây", "growth_days": 0, "sell_price": 1,
						"seasons": ["ha"], "color": "#ffffff"})
			data["crops"] = crops)

	# Act
	var main: Main = _start_main()

	# Assert
	assert_str(_error_text(main)).contains("lỗi khác")


func test_a_broken_relation_between_files_shows_the_request_and_the_crop() -> void:
	# Arrange: every file is valid on its own, but a request wants a crop that does not exist.
	_modify(DataPaths.NEIGHBORS, func(data: Dictionary) -> void:
			var neighbor: Dictionary = (data["neighbors"] as Array)[0] as Dictionary
			((neighbor["requests"] as Array)[1] as Dictionary)["require"] = {"khoai": 3})

	# Act
	var main: Main = _start_main()

	# Assert
	var text: String = _error_text(main)
	assert_str(text).contains("ba_tu_2")
	assert_str(text).contains("khoai")


func test_the_cross_check_says_it_was_skipped_when_a_file_failed() -> void:
	# Arrange
	_modify(DataPaths.CROPS, func(data: Dictionary) -> void:
			((data["crops"] as Array)[0] as Dictionary)["growth_days"] = 0)

	# Act
	var main: Main = _start_main()

	# Assert: silence here would read as "the cross-check found nothing".
	assert_str(_error_text(main)).contains("kiểm chéo bị bỏ qua")


func test_the_error_screen_blocks_taps_to_the_map() -> void:
	# Arrange
	DirAccess.remove_absolute(DATA_DIR + DataPaths.CROPS)

	# Act
	var main: Main = _start_main()

	# Assert
	var backgrounds: Array[Node] = _error_screen(main).find_children("*", "ColorRect", true, false)
	assert_int(backgrounds.size()).is_equal(1)
	assert_int((backgrounds[0] as ColorRect).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)


func test_a_failed_start_never_saves_ticks_or_touches_an_existing_save() -> void:
	# Arrange
	SaveTestSupport.write_file(SAVE_DIR, SaveGame.SAVE_FILE, SaveTestSupport.envelope_text())
	DirAccess.remove_absolute(DATA_DIR + DataPaths.CROPS)
	var before: Dictionary = SaveTestSupport.snapshot(SAVE_DIR)
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	main._process(1.0)

	# Assert
	assert_bool(main.save_game()).is_false()
	assert_dict(SaveTestSupport.snapshot(SAVE_DIR)).is_equal(before)


# --- wiring happens once --------------------------------------------------------------

func test_main_connects_every_cross_module_signal_exactly_once() -> void:
	# Arrange / Act
	var main: Main = _start_main()

	# Assert: a view may also watch its own module (VillageView follows the village), so the
	# check counts Main's connections, not all of them.
	var signals: Array[Signal] = [main._clock.day_advanced, main._clock.phase_changed,
			main._clock.season_changed, main._book.request_completed, main._book.crop_unlocked,
			main._book.season_requests_completed, main._grid.crop_harvested,
			main._village.piece_restored]
	for connected: Signal in signals:
		assert_int(_connections_to(connected, main)).is_equal(1)


func test_loading_a_save_again_does_not_connect_anything_twice() -> void:
	# Arrange
	var main: Main = _start_main()
	var before: int = _connection_total(main)

	# Act
	main._load_saved_game()
	main._load_saved_game()

	# Assert
	assert_int(_connection_total(main)).is_equal(before)


func test_completing_a_request_counts_it_in_the_village() -> void:
	# Arrange
	var main: Main = _start_main()
	main._grid.inventory["ngo"] = 5

	# Act
	var request: Dictionary = main._book.complete_request("ba_tu", main._grid.inventory)

	# Assert
	assert_dict(request).is_not_empty()
	assert_int(main._village.get_completed_count()).is_equal(1)


# --- helpers -------------------------------------------------------------------------

## A real Main in the tree. Both seams must be set before add_child: Main loads its data and
## its save in _ready().
func _start_main() -> Main:
	var main := Main.new()
	main._save_game = SaveGame.new(SAVE_DIR)
	main._data_dir = DATA_DIR
	auto_free(main)
	add_child(main)
	return main


func _error_screen(main: Main) -> StartupErrorScreen:
	for child: Node in main.get_children():
		if child is StartupErrorScreen:
			return child as StartupErrorScreen
	return null


func _error_text(main: Main) -> String:
	var screen: StartupErrorScreen = _error_screen(main)
	assert_object(screen).is_not_null()
	return screen.get_text() if screen != null else ""


## Reads a copied data file, lets [param change] edit its parsed content, writes it back.
func _modify(file_name: String, change: Callable) -> void:
	var data: Dictionary = JSON.parse_string(SaveTestSupport.read_file(DATA_DIR, file_name)) as Dictionary
	change.call(data)
	SaveTestSupport.write_file(DATA_DIR, file_name, JSON.stringify(data))


## How many connections of [param connected] call a method of [param owner].
func _connections_to(connected: Signal, owner: Object) -> int:
	var count: int = 0
	for connection: Dictionary in connected.get_connections():
		if (connection["callable"] as Callable).get_object() == owner:
			count += 1
	return count


func _connection_total(main: Main) -> int:
	var total: int = 0
	for connected: Signal in [main._clock.day_advanced, main._clock.phase_changed,
			main._clock.season_changed, main._book.request_completed, main._book.crop_unlocked,
			main._grid.crop_harvested, main._village.piece_restored, main._hud.sleep_requested]:
		total += connected.get_connections().size()
	return total
