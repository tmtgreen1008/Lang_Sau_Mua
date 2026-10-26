class_name DishPanel
extends CanvasLayer
## Read-only list of unlocked dishes ("Món ăn"). No cooking. Story 004.
##
## Usage:
##   panel.setup(book)
##   panel.open()

const MIN_BUTTON_SIZE: Vector2 = Vector2(72.0, 72.0)
const FONT_SIZE: int = 24
const PANEL_MIN_WIDTH: float = 520.0

var _book: NeighborBook
var _dim: ColorRect
var _rows: VBoxContainer


## Builds the static frame. The panel starts closed.
func setup(book: NeighborBook) -> void:
	_book = book
	layer = 2
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.6)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0.0)
	center.add_child(box)
	var column := VBoxContainer.new()
	box.add_child(column)
	var title := Label.new()
	title.text = "Món ăn đã biết"
	title.add_theme_font_size_override("font_size", FONT_SIZE + 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_rows = VBoxContainer.new()
	column.add_child(_rows)
	var close_button := Button.new()
	close_button.text = "Đóng"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = MIN_BUTTON_SIZE
	close_button.add_theme_font_size_override("font_size", FONT_SIZE)
	close_button.pressed.connect(close)
	column.add_child(close_button)
	visible = false


## True while the panel is showing.
func is_open() -> bool:
	return visible


## Shows the panel with the currently unlocked dishes.
func open() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var dishes: Array[String] = _book.get_unlocked_dishes()
	if dishes.is_empty():
		_rows.add_child(_make_label("Chưa biết món nào. Giúp hàng xóm để học thêm."))
	for dish_id: String in dishes:
		_rows.add_child(_make_label("- " + _book.get_dish_name(dish_id)))
	visible = true


## Hides the panel.
func close() -> void:
	visible = false


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label
