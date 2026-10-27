class_name StartupErrorScreen
extends CanvasLayer
## Full-screen message shown when the game cannot start because its data is wrong (ADR-0002
## rules 9 and 11), instead of a blank screen. It lists up to [constant MAX_LINES] errors, each
## with the file and place that is wrong, then how many more there are. The background covers
## the whole screen and swallows taps, so nothing underneath can be touched. Text only: the
## retry and new-game choices belong to the UI ADR.
##
## The Vietnamese text is written here directly; there is no localization system yet.
##
## Usage:
##   var screen := StartupErrorScreen.new()
##   add_child(screen)
##   screen.show_errors(result.errors, result.dropped_errors)

## Errors listed before the rest are only counted.
const MAX_LINES: int = 10
const TITLE: String = "Game không khởi động được. Hãy sửa các lỗi dữ liệu sau:"
const FONT_SIZE: int = 24
const MARGIN: float = 32.0
const BACKGROUND_COLOR: Color = Color(0.12, 0.08, 0.08)

var _label: Label


func _init() -> void:
	# Above the HUD and every panel (they use the default layer 1 and a little above it).
	layer = 100


## The text shown for [param errors] ([param dropped] more errors were counted but not kept).
static func format(errors: Array[String], dropped: int = 0) -> String:
	var lines: PackedStringArray = [TITLE, ""]
	for i: int in mini(errors.size(), MAX_LINES):
		lines.append(errors[i] + "\n")
	var rest: int = maxi(0, errors.size() - MAX_LINES) + dropped
	if rest > 0:
		lines.append("và %d lỗi khác" % rest)
	return "\n".join(lines).strip_edges(false, true)


## Builds the blocking background and the message.
func show_errors(errors: Array[String], dropped: int = 0) -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_label = Label.new()
	_label.text = format(errors, dropped)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = MARGIN
	_label.offset_top = MARGIN
	_label.offset_right = -MARGIN
	_label.offset_bottom = -MARGIN
	add_child(_label)


## The message currently shown ("" before [method show_errors]).
func get_text() -> String:
	return _label.text if _label != null else ""
