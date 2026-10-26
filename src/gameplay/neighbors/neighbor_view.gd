class_name NeighborView
extends Node2D
## Placeholder neighbor figure on the village map: a coloured body and head with a name
## label. Display only; Main decides what a tap on it does. Story 004.
##
## Usage:
##   var view := NeighborView.new()
##   view.setup("Bà Tư", Color.ORANGE)
##   view.position = Vector2(836.0, 370.0)

const SIZE: Vector2 = Vector2(100.0, 100.0)
const FIGURE_WIDTH: float = 44.0
const HEAD_RADIUS: float = 14.0
const BODY_HEIGHT: float = 34.0
const FONT_SIZE: int = 22
const HEAD_COLOR: Color = Color(0.95, 0.8, 0.65)

var _display_name: String = ""
var _color: Color = Color.WHITE


## Sets the label and body colour.
func setup(display_name: String, color: Color) -> void:
	_display_name = display_name
	_color = color
	queue_redraw()


## Centre of the figure in canvas coordinates.
func get_center() -> Vector2:
	return to_global(SIZE * 0.5)


## True when [param canvas_position] lies on the figure (including its label).
func contains_point(canvas_position: Vector2) -> bool:
	return Rect2(Vector2.ZERO, SIZE).has_point(to_local(canvas_position))


func _draw() -> void:
	var centre_x: float = SIZE.x * 0.5
	draw_circle(Vector2(centre_x, HEAD_RADIUS + 2.0), HEAD_RADIUS, HEAD_COLOR)
	draw_rect(Rect2(Vector2(centre_x - FIGURE_WIDTH * 0.5, HEAD_RADIUS * 2.0 + 4.0),
			Vector2(FIGURE_WIDTH, BODY_HEIGHT)), _color)
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(_display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var baseline: float = HEAD_RADIUS * 2.0 + 4.0 + BODY_HEIGHT + 4.0 + FONT_SIZE
	draw_string_outline(font, Vector2((SIZE.x - text_size.x) * 0.5, baseline), _display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 6, Color.BLACK)
	draw_string(font, Vector2((SIZE.x - text_size.x) * 0.5, baseline), _display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
