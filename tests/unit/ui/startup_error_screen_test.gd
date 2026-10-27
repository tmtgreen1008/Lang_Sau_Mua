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
