extends GdUnitTestSuite
## Integration tests for Main's app-lifecycle and panel-pause wiring (ADR-0004 rules 2, 3, 5,
## 6, 7, 8, 9; src/main.gd). A real Main is added to the tree with its SaveGame pointed at a
## throwaway folder (the _save_game test seam), so the player's user://savegame.json is
## never read or written. Tests are synchronous: no engine frame runs between two lines, so
## time only moves when a test calls _process() itself.
##
## Not covered: the pause panel the Back button should open when nothing else is open (its
## screen belongs to the UI ADR, not written yet), and what Android really sends (ADR-0004
## Verification Required, needs a device build).

const TEST_DIR: String = "user://test_main_lifecycle/"
const BIG_DELTA: float = 300.0


func before_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)
	DirAccess.make_dir_recursive_absolute(TEST_DIR)


func after_test() -> void:
	SaveTestSupport.remove_dir(TEST_DIR)


# --- lifecycle notifications ---------------------------------------------------------

func test_paused_notification_stops_the_clock_and_saves() -> void:
	# Arrange
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	# Assert
	assert_bool(main._clock.is_paused()).is_true()
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)).is_true()


func test_resumed_notification_restarts_the_clock() -> void:
	# Arrange
	var main: Main = _start_main()
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var paused_before: bool = main._clock.is_paused()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	# Assert: it must have been stopped first, or "running" proves nothing.
	assert_bool(paused_before).is_true()
	assert_bool(main._clock.is_paused()).is_false()


func test_app_focus_out_then_in_pauses_then_resumes_and_saves_on_the_way_out() -> void:
	# Arrange
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var paused_after_out: bool = main._clock.is_paused()
	var saved_on_out: bool = SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)

	# Assert
	assert_bool(paused_after_out).is_true()
	assert_bool(saved_on_out).is_true()
	assert_bool(main._clock.is_paused()).is_false()


func test_window_focus_out_then_in_pauses_then_resumes_and_saves_on_the_way_out() -> void:
	# Arrange
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	var paused_after_out: bool = main._clock.is_paused()
	var saved_on_out: bool = SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)
	main.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)

	# Assert
	assert_bool(paused_after_out).is_true()
	assert_bool(saved_on_out).is_true()
	assert_bool(main._clock.is_paused()).is_false()


func test_every_order_of_complete_pairs_ends_with_the_clock_running() -> void:
	# Arrange: the order these arrive in on a phone is unknown (ADR-0004 rule 2), so the
	# clock must come back whichever way the in/out pairs interleave.
	var out_app: int = Node.NOTIFICATION_APPLICATION_PAUSED
	var in_app: int = Node.NOTIFICATION_APPLICATION_RESUMED
	var out_focus: int = Node.NOTIFICATION_APPLICATION_FOCUS_OUT
	var in_focus: int = Node.NOTIFICATION_APPLICATION_FOCUS_IN
	var out_window: int = Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT
	var in_window: int = Node.NOTIFICATION_WM_WINDOW_FOCUS_IN
	var orders: Array[Array] = [
		[out_app, out_focus, in_app, in_focus],
		[out_focus, out_app, in_focus, in_app],
		[out_app, in_app, out_focus, in_focus],
		[out_focus, in_focus, out_app, in_app],
		[out_window, out_app, in_window, in_app],
		[out_app, out_focus, out_window, in_window, in_focus, in_app],
		[out_window, out_focus, out_app, in_app, in_focus, in_window],
	]

	for order: Array in orders:
		var main: Main = _start_main()
		var was_paused: bool = false

		# Act
		for what: int in order:
			main.notification(what)
			was_paused = was_paused or main._clock.is_paused()

		# Assert: it stopped at some point (else "running" proves nothing) and ended running.
		assert_bool(was_paused).is_true()
		assert_bool(main._clock.is_paused()).is_false()


func test_resumed_clears_a_focus_out_whose_focus_in_never_came() -> void:
	# Arrange: RESUMED means the app is in the foreground again, so it is the safety net.
	var main: Main = _start_main()
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var paused_before: bool = main._clock.is_paused()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	# Assert
	assert_bool(paused_before).is_true()
	assert_bool(main._clock.is_paused()).is_false()


func test_resumed_does_not_clear_the_pause_of_an_open_panel() -> void:
	# Arrange
	var main: Main = _start_main()
	main._market_panel.open(main._grid.inventory)
	main._process(0.0)

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	# Assert
	assert_bool(main._clock.is_paused()).is_true()


func test_close_request_saves_the_game() -> void:
	# Arrange
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)).is_true()


func test_pause_then_focus_out_with_no_change_writes_only_one_save() -> void:
	# Arrange: both notifications arrive back to back; the second state is identical.
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	# Assert: a second write would have rotated the first save into .bak.
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.SAVE_FILE)).is_true()
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.BACKUP_FILE)).is_false()


func test_a_changed_state_is_saved_again() -> void:
	# Arrange
	var main: Main = _start_main()
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main._market.add_money(5)

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	# Assert
	assert_bool(SaveTestSupport.exists(TEST_DIR, SaveGame.BACKUP_FILE)).is_true()


func test_pause_and_resume_in_mid_day_keep_the_clock_state() -> void:
	# Arrange
	var main: Main = _start_main()
	main._process(0.1)
	var before: Dictionary = main._clock.to_dict()

	# Act
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	# Assert
	assert_dict(main._clock.to_dict()).is_equal(before)


func test_first_frame_after_a_long_absence_does_not_skip_a_day() -> void:
	# Arrange
	var main: Main = _start_main()
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var day_before: int = main._clock.day_number

	# Act: the engine may hand the first frame back the whole time spent in the background.
	main._process(BIG_DELTA)

	# Assert
	assert_int(main._clock.day_number).is_equal(day_before)


# --- panels pause the clock ----------------------------------------------------------

func test_an_open_panel_stops_the_clock_on_the_next_frame() -> void:
	# Arrange
	var main: Main = _start_main()
	main._market_panel.open(main._grid.inventory)
	var before: Dictionary = main._clock.to_dict()

	# Act
	main._process(1.0)

	# Assert
	assert_bool(main._clock.is_paused()).is_true()
	assert_dict(main._clock.to_dict()).is_equal(before)


func test_closing_the_panel_lets_the_clock_run_again() -> void:
	# Arrange
	var main: Main = _start_main()
	main._market_panel.open(main._grid.inventory)
	main._process(0.0)
	var paused_while_open: bool = main._clock.is_paused()
	main._market_panel.close()

	# Act
	main._process(1.0)

	# Assert
	assert_bool(paused_while_open).is_true()
	assert_bool(main._clock.is_paused()).is_false()
	assert_float(main._clock.to_dict()["phase_elapsed"]).is_greater(0.0)


func test_panels_opened_one_after_another_leave_no_stuck_pause() -> void:
	# Arrange
	var main: Main = _start_main()
	var neighbor_id: String = main._book.get_neighbor_ids()[0]

	# Act
	main._market_panel.open(main._grid.inventory)
	main._process(0.0)
	main._market_panel.close()
	main._neighbor_panel.open(neighbor_id, main._grid.inventory)
	main._process(0.0)
	var paused_while_second_is_open: bool = main._clock.is_paused()
	main._neighbor_panel.close()
	main._process(0.0)

	# Assert
	assert_bool(paused_while_second_is_open).is_true()
	assert_bool(main._clock.is_paused()).is_false()


func test_the_dish_panel_pauses_the_clock_too() -> void:
	# Arrange: it is opened straight from the HUD, not through Main.
	var main: Main = _start_main()
	main._dish_panel.open()

	# Act
	main._process(0.0)

	# Assert
	assert_bool(main._clock.is_paused()).is_true()


func test_sleep_is_blocked_while_a_panel_is_open() -> void:
	# Arrange: DayClock.sleep() ignores pause, so Main must refuse the request itself.
	var main: Main = _start_main()
	main._market_panel.open(main._grid.inventory)
	var day_before: int = main._clock.day_number

	# Act
	main._hud.sleep_requested.emit()

	# Assert
	assert_int(main._clock.day_number).is_equal(day_before)


func test_sleep_works_when_no_panel_is_open() -> void:
	# Arrange
	var main: Main = _start_main()
	var day_before: int = main._clock.day_number

	# Act
	main._hud.sleep_requested.emit()

	# Assert
	assert_int(main._clock.day_number).is_equal(day_before + 1)


# --- the Back button -----------------------------------------------------------------

func test_back_request_closes_an_open_panel() -> void:
	# Arrange
	var main: Main = _start_main()
	main._market_panel.open(main._grid.inventory)

	# Act
	main.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)

	# Assert
	assert_bool(main._market_panel.is_open()).is_false()


func test_back_request_with_nothing_open_leaves_the_game_running() -> void:
	# Arrange
	var main: Main = _start_main()

	# Act
	main.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)

	# Assert: nothing opened and the game is still usable (it did not quit or break).
	assert_bool(main._market_panel.is_open()).is_false()
	assert_bool(main.save_game()).is_true()


func test_the_engine_is_told_not_to_quit_on_back() -> void:
	# Arrange / Act / Assert: ADR-0004 rule 7. The setting name was verified on Godot 4.7.2.
	assert_bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)).is_false()
	assert_bool(get_tree().is_quit_on_go_back()).is_false()


# --- helpers -------------------------------------------------------------------------

## A real Main in the tree, saving into TEST_DIR. The _save_game seam must be set before
## add_child, because Main loads the save in _ready().
func _start_main() -> Main:
	var main := Main.new()
	main._save_game = SaveGame.new(TEST_DIR)
	auto_free(main)
	add_child(main)
	return main
