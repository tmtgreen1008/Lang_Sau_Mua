class_name NeighborPanel
extends CanvasLayer
## Neighbor talk screen: name, request statuses, current request text, required vs owned
## produce, a "Nộp" button and "Đóng". Display only: it reads the NeighborBook but never
## changes it; it emits [signal hand_over_requested]. Story 004.
##
## Usage:
##   panel.setup(db, book)
##   panel.hand_over_requested.connect(func(neighbor_id): ...)
##   panel.open("ba_tu", grid.inventory)

## Emitted when the player taps "Nộp" for the neighbor's current request.
signal hand_over_requested(neighbor_id: String)

const MIN_BUTTON_SIZE: Vector2 = Vector2(72.0, 72.0)
const FONT_SIZE: int = 24
const PANEL_MIN_WIDTH: float = 760.0
const TEXT_WIDTH: float = 720.0
const STATUS_NAMES: Dictionary = {
	NeighborBook.STATE_NOT_STARTED: "chưa nhận",
	NeighborBook.STATE_ACTIVE: "đang làm",
	NeighborBook.STATE_DONE: "xong",
}

var _db: CropDatabase
var _book: NeighborBook
var _dim: ColorRect
var _content: VBoxContainer
var _neighbor_id: String = ""
var _inventory: Dictionary = {}
## Text shown after a successful hand-over (done line and reward), until the panel reopens.
var _result_text: String = ""


## Builds the static frame. The panel starts closed.
func setup(db: CropDatabase, book: NeighborBook) -> void:
	_db = db
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
	_content = VBoxContainer.new()
	box.add_child(_content)
	visible = false


## True while the panel is showing.
func is_open() -> bool:
	return visible


## Shows the panel for [param neighbor_id] with the given crop_id -> count inventory.
func open(neighbor_id: String, inventory: Dictionary) -> void:
	_neighbor_id = neighbor_id
	_result_text = ""
	visible = true
	refresh(inventory)


## Hides the panel.
func close() -> void:
	visible = false


## Shows [param text] (done line and reward) above the next request after a hand-over.
func show_result(text: String) -> void:
	_result_text = text
	refresh(_inventory)


## Rebuilds the content from the book and [param inventory].
func refresh(inventory: Dictionary) -> void:
	_inventory = inventory
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	var title: Label = _make_label(_book.get_neighbor_name(_neighbor_id), FONT_SIZE + 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var index: int = 0
	for request: Variant in _book.get_requests(_neighbor_id):
		index += 1
		var status: String = _book.get_status(str((request as Dictionary)["id"]))
		_content.add_child(_make_label("Nhờ vả %d: %s" % [index, STATUS_NAMES.get(status, status)], FONT_SIZE))

	if not _result_text.is_empty():
		_content.add_child(_make_label(_result_text, FONT_SIZE))

	var can_hand_over: bool = false
	var current: Dictionary = _book.get_current_request(_neighbor_id)
	if current.is_empty():
		_content.add_child(_make_label(_book.get_thanks_text(_neighbor_id), FONT_SIZE))
	else:
		if _result_text.is_empty():
			_content.add_child(_make_label(str(current.get("offer_text", "")), FONT_SIZE))
		var required: Dictionary[String, int] = _book.get_required(_neighbor_id)
		for crop_id: String in required:
			_content.add_child(_make_label("%s %d/%d" % [
					_db.get_crop_name(crop_id), int(_inventory.get(crop_id, 0)), required[crop_id]], FONT_SIZE))
		can_hand_over = _book.can_complete(_neighbor_id, _inventory)
		if not can_hand_over:
			var parts: PackedStringArray = []
			var missing: Dictionary[String, int] = _book.get_missing(_neighbor_id, _inventory)
			for crop_id: String in missing:
				parts.append("%s x%d" % [_db.get_crop_name(crop_id), missing[crop_id]])
			_content.add_child(_make_label(
					"%s\nCòn thiếu: %s" % [str(current.get("missing_text", "")), ", ".join(parts)], FONT_SIZE))

	var buttons := HBoxContainer.new()
	var hand_over := _make_button("Nộp")
	hand_over.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_over.disabled = not can_hand_over
	hand_over.pressed.connect(func() -> void: hand_over_requested.emit(_neighbor_id))
	buttons.add_child(hand_over)
	var close_button := _make_button("Đóng")
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(close)
	buttons.add_child(close_button)
	_content.add_child(buttons)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_WIDTH, 0.0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = MIN_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button
