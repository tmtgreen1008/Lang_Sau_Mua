class_name MarketPanel
extends CanvasLayer
## Market screen: lists owned produce with unit price, a quantity picker and a sell
## button per crop. Display only: it emits requests and holds no game state.
## Story 003.
##
## Usage:
##   panel.setup(db)
##   panel.sell_requested.connect(func(id, qty): market.sell(id, qty))
##   panel.open(grid.inventory)

## Emitted when the player taps "Bán" for [param quantity] units of [param crop_id].
signal sell_requested(crop_id: String, quantity: int)

const MIN_BUTTON_SIZE: Vector2 = Vector2(72.0, 72.0)
const FONT_SIZE: int = 24
const PANEL_MIN_WIDTH: float = 760.0

var _db: CropDatabase
var _dim: ColorRect
var _rows: VBoxContainer
## crop_id -> quantity chosen in the picker.
var _chosen: Dictionary[String, int] = {}
var _inventory: Dictionary = {}


## Builds the static frame for the crops in [param db]. The panel starts closed.
func setup(db: CropDatabase) -> void:
	_db = db
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
	title.text = "Chợ quê - bán nông sản"
	title.add_theme_font_size_override("font_size", FONT_SIZE + 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_rows = VBoxContainer.new()
	column.add_child(_rows)

	var close_button := _make_button("Đóng")
	close_button.pressed.connect(close)
	column.add_child(close_button)
	visible = false


## True while the market screen is showing.
func is_open() -> bool:
	return visible


## Shows the panel for the given crop_id -> count inventory.
func open(inventory: Dictionary) -> void:
	_chosen.clear()
	visible = true
	refresh(inventory)


## Hides the panel.
func close() -> void:
	visible = false


## Rebuilds the rows from [param inventory]; picked quantities are clamped to what is owned.
func refresh(inventory: Dictionary) -> void:
	_inventory = inventory
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var any_owned: bool = false
	for crop_id: String in _db.get_crop_ids():
		if int(_inventory.get(crop_id, 0)) > 0:
			any_owned = true
			_rows.add_child(_make_row(crop_id))
	if not any_owned:
		var empty := Label.new()
		empty.text = "Chưa có nông sản để bán."
		empty.add_theme_font_size_override("font_size", FONT_SIZE)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rows.add_child(empty)


func _make_row(crop_id: String) -> HBoxContainer:
	var owned: int = int(_inventory.get(crop_id, 0))
	var chosen: int = clampi(int(_chosen.get(crop_id, 0)), 0, owned)
	_chosen[crop_id] = chosen

	var row := HBoxContainer.new()
	var info := Label.new()
	info.text = "%s - giá %d - có %d" % [_db.get_crop_name(crop_id), _db.get_sell_price(crop_id), owned]
	info.add_theme_font_size_override("font_size", FONT_SIZE)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var minus := _make_button("-")
	minus.disabled = chosen <= 0
	minus.pressed.connect(_on_quantity_changed.bind(crop_id, -1))
	row.add_child(minus)

	var amount := Label.new()
	amount.text = str(chosen)
	amount.custom_minimum_size = Vector2(56.0, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(amount)

	var plus := _make_button("+")
	plus.disabled = chosen >= owned
	plus.pressed.connect(_on_quantity_changed.bind(crop_id, 1))
	row.add_child(plus)

	var sell := _make_button("Bán")
	sell.custom_minimum_size = Vector2(120.0, MIN_BUTTON_SIZE.y)
	sell.disabled = chosen <= 0
	sell.pressed.connect(_on_sell_pressed.bind(crop_id))
	row.add_child(sell)
	return row


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = MIN_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _on_quantity_changed(crop_id: String, delta: int) -> void:
	_chosen[crop_id] = clampi(int(_chosen.get(crop_id, 0)) + delta, 0, int(_inventory.get(crop_id, 0)))
	refresh(_inventory)


func _on_sell_pressed(crop_id: String) -> void:
	var quantity: int = int(_chosen.get(crop_id, 0))
	_chosen[crop_id] = 0
	sell_requested.emit(crop_id, quantity)
