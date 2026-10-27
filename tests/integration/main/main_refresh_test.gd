extends GdUnitTestSuite
## Integration tests for Main's refresh and its save-failure message (ADR-0002 rule 7 and
## ADR-0005 rule 17; src/main.gd). After a save is loaded, every view must show the loaded
## state, with no effect; the list of views Main refreshes must not miss one. A real Main runs
## with its SaveGame pointed at a throwaway folder (the _save_game seam), against the shipped data.

const SAVE_DIR: String = "user://test_main_refresh_save/"
const MISSING_DIR: String = "user://test_main_refresh_missing/"
const FIXTURE: String = "res://tests/fixtures/saves/v1.json"
## Save failures that stay silent; the message starts from the second one in a row.
const FIRST_LOUD_FAILURE: int = 2


## Stands in for a view: counts how often Main asks it to sync.
class SyncSpy:
	extends RefCounted
	var calls: int = 0

	func sync() -> void:
		calls += 1


func before_test() -> void:
	SaveTestSupport.remove_dir(SAVE_DIR)
	SaveTestSupport.remove_dir(MISSING_DIR)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func after_test() -> void:
	SaveTestSupport.remove_dir(SAVE_DIR)
	SaveTestSupport.remove_dir(MISSING_DIR)


# --- a loaded save is shown ----------------------------------------------------------

func test_loading_a_save_shows_its_money_day_and_bag_on_the_hud() -> void:
	# Arrange: the frozen v1 fixture holds 25 money, day 2 and 3 corn.
	_write_save(FileAccess.get_file_as_string(FIXTURE))

	# Act
	var main: Main = _start_main()

	# Assert
	assert_str(main._hud._money_label.text).contains("25")
	assert_str(main._hud._time_label.text).contains("Ngày 2")
	assert_str(main._hud._inventory_label.text).contains("Ngô: 3")


func test_loading_a_save_with_restored_village_pieces_shows_them_at_once_without_effects() -> void:
	# Arrange
	_write_save(_fixture_text(func(data: Dictionary) -> void:
			(data["village"] as Dictionary)["completed_requests"] = 3))

	# Act
	var main: Main = _start_main()

	# Assert
	var checked: int = 0
	for piece: Dictionary in main._village.get_piece_defs():
		var expected: float = 1.0 if int(piece["unlock_at"]) <= 3 else 0.0
		assert_float(main._village_view._blend[piece["id"]]).is_equal(expected)
		checked += 1
	assert_int(checked).is_greater(0)
	assert_bool(main._village_view._tweens.is_empty()).is_true()


func test_loading_a_save_unlocks_the_saved_crops_in_the_selector() -> void:
	# Arrange
	_write_save(_fixture_text(func(data: Dictionary) -> void:
			(data["neighbors"] as Dictionary)["unlocked_crops"] = ["ngo", "ca_chua"]))

	# Act
	var main: Main = _start_main()

	# Assert
	assert_array(main._hud._unlocked_crops).contains_exactly(["ngo", "ca_chua"])


func test_starting_without_a_save_still_fills_the_hud() -> void:
	# Arrange / Act
	var main: Main = _start_main()

	# Assert
	assert_str(main._hud._time_label.text).contains("Ngày 1")
	assert_str(main._hud._money_label.text).contains("0")
	assert_array(main._hud._unlocked_crops).contains_exactly(["ngo"])


# --- the refresh itself ---------------------------------------------------------------

func test_refresh_all_asks_every_listed_view_to_sync() -> void:
	# Arrange
	var main: Main = _start_main()
	var spy := SyncSpy.new()
	main._sync_views.append(spy)

	# Act
	main._refresh_all()

	# Assert
	assert_int(spy.calls).is_equal(1)


func test_refresh_all_keeps_the_message_the_tool_and_the_crop() -> void:
	# Arrange
	var main: Main = _start_main()
	main._hud.show_message("xin chào")
	main._hud.current_tool = FarmGrid.Tool.WATER
	var crop_before: String = main._hud.current_crop_id

	# Act
	main._refresh_all()

	# Assert
	assert_str(main._hud._message_label.text).is_equal("xin chào")
	assert_int(main._hud.current_tool).is_equal(FarmGrid.Tool.WATER)
	assert_str(main._hud.current_crop_id).is_equal(crop_before)


func test_every_view_file_has_sync_and_is_listed_in_main() -> void:
	# Arrange: derived from the folder, so a new *_view.gd cannot ship outside the refresh.
	var main: Main = _start_main()
	var paths: Array[String] = []
	_collect_view_scripts("res://src/", paths)

	for path: String in paths:
		var script: GDScript = load(path) as GDScript
		var method_names: Array = script.get_script_method_list().map(
				func(method: Dictionary) -> String: return method["name"])
		var listed: Array = main._sync_views.filter(
				func(view: Object) -> bool: return view.get_script() == script)

		# Act / Assert
		assert_bool(method_names.has("sync")).override_failure_message("%s has no sync()" % path).is_true()
		assert_bool(not listed.is_empty()).override_failure_message(
				"%s is not in Main._sync_views" % path).is_true()

	# Assert: guards against the loop passing because the scan found nothing.
	assert_int(paths.size()).is_greater_equal(4)


func test_every_neighbor_figure_is_listed_for_refresh() -> void:
	# Arrange / Act
	var main: Main = _start_main()
	var listed: Array = main._sync_views.filter(func(view: Object) -> bool: return view is NeighborView)

	# Assert
	assert_int(listed.size()).is_equal(main._book.get_neighbor_ids().size())


# --- save failures are not silent -----------------------------------------------------

func test_a_single_failed_save_stays_quiet() -> void:
	# Arrange
	var main: Main = _start_main_saving_to(MISSING_DIR)

	# Act
	var saved: bool = main.save_game()

	# Assert
	assert_bool(saved).is_false()
	assert_str(main._hud._message_label.text).not_contains("Không lưu được")


func test_the_second_failed_save_in_a_row_tells_the_player() -> void:
	# Arrange
	var main: Main = _start_main_saving_to(MISSING_DIR)

	# Act
	for i: int in FIRST_LOUD_FAILURE:
		main.save_game()

	# Assert
	assert_str(main._hud._message_label.text).contains("Không lưu được")


func test_a_successful_save_starts_the_count_again() -> void:
	# Arrange: two failures, then the folder appears and a save works.
	var main: Main = _start_main_saving_to(MISSING_DIR)
	for i: int in FIRST_LOUD_FAILURE:
		main.save_game()
	var was_loud: bool = main._hud._message_label.text.contains("Không lưu được")
	DirAccess.make_dir_recursive_absolute(MISSING_DIR)
	assert_bool(main.save_game()).is_true()

	# Act: the folder disappears again, so the next save fails once more.
	main._hud._message_label.text = ""
	main._market.add_money(1)
	SaveTestSupport.remove_dir(MISSING_DIR)
	main.save_game()

	# Assert: it was loud before, and one failure after a success is quiet again.
	assert_bool(was_loud).is_true()
	assert_str(main._hud._message_label.text).not_contains("Không lưu được")


func test_saving_that_is_blocked_on_purpose_is_not_counted_as_a_failure() -> void:
	# Arrange: a corrupt save blocks writing and Main already said so when it loaded.
	_write_save("{ broken")
	var main: Main = _start_main()
	var told_at_load: bool = main._hud._message_label.text.contains("bị hỏng")
	main._hud._message_label.text = ""

	# Act
	var any_saved: bool = false
	for i: int in FIRST_LOUD_FAILURE + 1:
		any_saved = main.save_game() or any_saved

	# Assert: saving really was refused (so the test exercises the blocked path), yet quiet.
	assert_bool(told_at_load).is_true()
	assert_bool(any_saved).is_false()
	assert_str(main._hud._message_label.text).not_contains("Không lưu được")


# --- helpers -------------------------------------------------------------------------

func _start_main() -> Main:
	return _start_main_saving_to(SAVE_DIR)


## A real Main in the tree; [param save_dir] is set before add_child because Main loads its save
## in _ready().
func _start_main_saving_to(save_dir: String) -> Main:
	var main := Main.new()
	main._save_game = SaveGame.new(save_dir)
	auto_free(main)
	add_child(main)
	return main


func _write_save(text: String) -> void:
	SaveTestSupport.write_file(SAVE_DIR, SaveGame.SAVE_FILE, text)


## The v1 fixture text with its "data" object edited by [param change].
func _fixture_text(change: Callable) -> String:
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	change.call(root["data"] as Dictionary)
	return JSON.stringify(root)


func _collect_view_scripts(dir: String, found: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(dir):
		if file_name.ends_with("_view.gd"):
			found.append(dir + file_name)
	for folder: String in DirAccess.get_directories_at(dir):
		_collect_view_scripts(dir + folder + "/", found)
