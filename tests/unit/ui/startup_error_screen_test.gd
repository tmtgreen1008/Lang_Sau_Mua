extends GdUnitTestSuite
## Unit tests for StartupErrorScreen (src/ui/startup_error_screen.gd, ADR-0002 rules 9 and 11):
## the full-screen message shown when the data cannot be loaded, instead of a blank screen.


func test_format_lists_every_error_on_its_own_line_under_a_title() -> void:
	# Arrange
	var errors: Array[String] = ["crops.json: crops[0]: growth_days is wrong", "neighbors.json: file not found"]

	# Act
	var text: String = StartupErrorScreen.format(errors, 0)

	# Assert
	assert_str(text).contains("Game không khởi động được")
	assert_str(text).contains("crops.json: crops[0]: growth_days is wrong\n")
	assert_str(text).contains("neighbors.json: file not found")
	assert_str(text).not_contains("lỗi khác")


func test_format_with_exactly_the_maximum_shows_every_error_without_a_count() -> void:
	# Arrange
	var errors: Array[String] = _errors(StartupErrorScreen.MAX_LINES)

	# Act
	var text: String = StartupErrorScreen.format(errors, 0)

	# Assert
	assert_str(text).contains("error 9")
	assert_str(text).not_contains("lỗi khác")


func test_format_cuts_after_the_maximum_and_counts_the_rest() -> void:
	# Arrange
	var errors: Array[String] = _errors(StartupErrorScreen.MAX_LINES + 1)

	# Act
	var text: String = StartupErrorScreen.format(errors, 0)

	# Assert
	assert_str(text).contains("error 9")
	assert_str(text).not_contains("error 10")
	assert_str(text).contains("và 1 lỗi khác")


func test_format_counts_errors_the_result_dropped_beyond_its_own_cap() -> void:
	# Arrange: 12 stored plus 5 the DataResult only counted.
	var errors: Array[String] = _errors(12)

	# Act
	var text: String = StartupErrorScreen.format(errors, 5)

	# Assert
	assert_str(text).contains("và 7 lỗi khác")


func test_format_puts_the_errors_on_consecutive_lines_with_no_blank_line_between() -> void:
	# Arrange: a blank line after every error doubled the height and pushed the list off screen.
	var errors: Array[String] = _errors(StartupErrorScreen.MAX_LINES)

	# Act
	var text: String = StartupErrorScreen.format(errors, 0)

	# Assert: the only blank line is the one under the title.
	assert_int(text.count("\n\n")).is_equal(1)
	assert_str(text).contains("error 0\nerror 1\nerror 2")


func test_the_longest_list_with_realistic_errors_fits_the_screen_without_scrolling() -> void:
	# Arrange: ten errors of about 70 characters plus the "and N more" line, as in the 12-error capture.
	var screen: StartupErrorScreen = auto_free(StartupErrorScreen.new())
	add_child(screen)
	var errors: Array[String] = []
	for i: int in StartupErrorScreen.MAX_LINES + 2:
		errors.append("crops.json: crops[%d]: growth_days must be a whole number greater than 0" % i)

	# Act
	screen.show_errors(errors, 0)
	await await_idle_frame()
	await await_idle_frame()

	# Assert
	var label: Label = _label_of(screen)
	var available: float = _screen_height() - 2.0 * StartupErrorScreen.MARGIN
	assert_float(label.get_minimum_size().y).is_less(available)
	assert_str(screen.get_text()).contains("và 2 lỗi khác")


func test_the_text_sits_in_a_vertical_scroll_area_as_a_safety_net() -> void:
	# Arrange: one very long message can still be taller than the screen; it must stay reachable.
	var screen: StartupErrorScreen = auto_free(StartupErrorScreen.new())
	add_child(screen)
	var errors: Array[String] = ["x".repeat(6000)]

	# Act
	screen.show_errors(errors, 0)
	await await_idle_frame()
	await await_idle_frame()

	# Assert
	var scrolls: Array[Node] = screen.find_children("*", "ScrollContainer", true, false)
	assert_int(scrolls.size()).is_equal(1)
	var scroll: ScrollContainer = scrolls[0] as ScrollContainer
	assert_int(scroll.vertical_scroll_mode).is_not_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	assert_int(scroll.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	assert_object(_label_of(screen).get_parent()).is_same(scroll)
	assert_float(_label_of(screen).get_minimum_size().y).is_greater(
			_screen_height())


func test_the_list_font_is_small_enough_for_ten_errors() -> void:
	# Arrange / Act / Assert: 24 px was too big for the capture; the list uses 20 px at most.
	assert_int(StartupErrorScreen.FONT_SIZE).is_less_equal(20)


func test_show_errors_builds_a_blocking_full_screen_background_and_the_text() -> void:
	# Arrange
	var screen: StartupErrorScreen = auto_free(StartupErrorScreen.new())
	var errors: Array[String] = _errors(2)

	# Act
	screen.show_errors(errors, 0)

	# Assert
	var backgrounds: Array[Node] = screen.find_children("*", "ColorRect", true, false)
	assert_int(backgrounds.size()).is_equal(1)
	var background: ColorRect = backgrounds[0] as ColorRect
	assert_int(background.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_float(background.anchor_right).is_equal(1.0)
	assert_float(background.anchor_bottom).is_equal(1.0)
	assert_str(screen.get_text()).is_equal(StartupErrorScreen.format(errors, 0))


func test_the_screen_sits_above_the_hud_and_panels() -> void:
	# Arrange / Act
	var screen: StartupErrorScreen = auto_free(StartupErrorScreen.new())

	# Assert
	assert_int(screen.layer).is_greater_equal(100)


func _errors(count: int) -> Array[String]:
	var errors: Array[String] = []
	for i: int in count:
		errors.append("error %d" % i)
	return errors


func _label_of(screen: StartupErrorScreen) -> Label:
	return screen.find_children("*", "Label", true, false)[0] as Label


## Height of the game window as the project defines it. The headless test viewport is taller
## (1152 x 1152), so measuring it would let an overflowing list pass.
func _screen_height() -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_height"))
