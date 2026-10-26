class_name Hud
extends CanvasLayer
## Touch HUD: tool toolbar, crop selector, inventory label, message line and the
## "Đi ngủ" button and the day/phase/season label. Holds the selected tool/crop;
## knows no farm or clock rules.
##
## Usage:
##   hud.setup(db)
##   hud.sleep_requested.connect(clock.sleep)
##   hud.set_time_info(1, "Sáng", "Mùa hạ")
##   hud.set_inventory(grid.inventory)

## Emitted when the player taps the "Đi ngủ" (end day early) button.
signal sleep_requested
## Emitted when the player taps the "Món ăn" (unlocked dishes) button.
signal dishes_requested

const MIN_BUTTON_SIZE: Vector2 = Vector2(120.0, 72.0)
const FONT_SIZE: int = 24
const TIME_FONT_SIZE: int = 36
const MESSAGE_SECONDS: float = 2.5
const MESSAGE_WIDTH: float = 320.0
const MESSAGE_POSITION: Vector2 = Vector2(16.0, 140.0)
const TOOL_NAMES: Dictionary = {
	FarmGrid.Tool.HOE: "Cuốc",
	FarmGrid.Tool.SEED: "Gieo hạt",
	FarmGrid.Tool.WATER: "Tưới",
	FarmGrid.Tool.HARVEST: "Thu hoạch",
}

## Tool currently selected in the toolbar.
var current_tool: FarmGrid.Tool = FarmGrid.Tool.HOE
## Crop currently selected in the crop selector ("" if none).
var current_crop_id: String = ""

var _db: CropDatabase
var _crop_row: HBoxContainer
## Crop ids shown in the selector and the inventory label (set by set_unlocked_crops).
var _unlocked_crops: Array[String] = []
var _last_inventory: Dictionary = {}
var _inventory_label: Label
var _money_label: Label
var _time_label: Label
var _message_label: Label
var _message_tween: Tween
## Controls that swallow taps (used to keep UI taps from moving the player).
var _interactive: Array[Control] = []


## Builds the UI for the crops in [param db].
func setup(db: CropDatabase) -> void:
	_db = db
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_row)
	_inventory_label = _make_label()
	_inventory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_inventory_label)
	_money_label = _make_label()
	_money_label.add_theme_constant_override("outline_size", 8)
	top_row.add_child(_money_label)
	set_money(0)
	var sleep_button: Button = _make_button("Đi ngủ", false)
	sleep_button.pressed.connect(func() -> void: sleep_requested.emit())
	top_row.add_child(sleep_button)
	var dishes_button: Button = _make_button("Món ăn", false)
	dishes_button.pressed.connect(func() -> void: dishes_requested.emit())
	top_row.add_child(dishes_button)

	_time_label = _make_label()
	_time_label.add_theme_font_size_override("font_size", TIME_FONT_SIZE)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_time_label)

	# Feedback line sits in the left margin beside the field, never over the tiles.
	_message_label = _make_label()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size = Vector2(MESSAGE_WIDTH, 0.0)
	_message_label.size = Vector2(MESSAGE_WIDTH, 0.0)
	_message_label.position = MESSAGE_POSITION
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message_label)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	_crop_row = HBoxContainer.new()
	_crop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_crop_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_crop_row)
	_unlocked_crops = db.get_crop_ids().duplicate()
	_rebuild_crop_row()

	var tool_row := HBoxContainer.new()
	tool_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tool_row)
	var tool_group := ButtonGroup.new()
	for tool: FarmGrid.Tool in TOOL_NAMES:
		var tool_button: Button = _make_button(str(TOOL_NAMES[tool]), true)
		tool_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tool_button.button_group = tool_group
		tool_button.pressed.connect(_on_tool_pressed.bind(tool))
		tool_row.add_child(tool_button)
		if tool == current_tool:
			tool_button.button_pressed = true


## Refreshes the inventory label from a crop_id -> count Dictionary.
func set_inventory(inventory: Dictionary) -> void:
	_last_inventory = inventory
	var parts: PackedStringArray = []
	for crop_id: String in _db.get_crop_ids():
		if _unlocked_crops.has(crop_id):
			parts.append("%s: %d" % [_db.get_crop_name(crop_id), int(inventory.get(crop_id, 0))])
	_inventory_label.text = "Túi đồ  " + "  |  ".join(parts)


## Limits the crop selector (and inventory label) to [param crop_ids], rebuilding the
## selector row. The selected crop stays if still listed, otherwise the first one is chosen.
func set_unlocked_crops(crop_ids: Array[String]) -> void:
	_unlocked_crops = crop_ids.duplicate()
	_rebuild_crop_row()
	set_inventory(_last_inventory)


func _rebuild_crop_row() -> void:
	for child: Node in _crop_row.get_children():
		_crop_row.remove_child(child)
		_interactive.erase(child)
		child.queue_free()
	if not _unlocked_crops.has(current_crop_id):
		current_crop_id = ""
	var crop_group := ButtonGroup.new()
	for crop_id: String in _db.get_crop_ids():
		if not _unlocked_crops.has(crop_id):
			continue
		var crop_button: Button = _make_button("Hạt %s" % _db.get_crop_name(crop_id), true)
		crop_button.button_group = crop_group
		crop_button.pressed.connect(_on_crop_pressed.bind(crop_id))
		_crop_row.add_child(crop_button)
		if current_crop_id.is_empty():
			current_crop_id = crop_id
		crop_button.button_pressed = crop_id == current_crop_id


## Shows the player's money, always visible.
func set_money(amount: int) -> void:
	_money_label.text = "  Tiền: %d  " % amount


## Shows the day number, phase name and season name (large text).
func set_time_info(day_number: int, phase_name: String, season_name: String) -> void:
	_time_label.text = "Ngày %d  -  %s  -  %s" % [day_number, phase_name, season_name]


## Shows a short feedback line that clears itself after a moment.
func show_message(text: String) -> void:
	_message_label.text = text
	if _message_tween != null:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_SECONDS)
	_message_tween.tween_callback(func() -> void: _message_label.text = "")


## True when [param canvas_position] lies on a button.
func blocks_point(canvas_position: Vector2) -> bool:
	for control: Control in _interactive:
		if control.get_global_rect().has_point(canvas_position):
			return true
	return false


func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label


func _make_button(text: String, toggle: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = toggle
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = MIN_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	_interactive.append(button)
	return button


func _on_tool_pressed(tool: FarmGrid.Tool) -> void:
	current_tool = tool


func _on_crop_pressed(crop_id: String) -> void:
	current_crop_id = crop_id
