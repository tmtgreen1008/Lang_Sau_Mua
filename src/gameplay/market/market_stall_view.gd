class_name MarketStallView
extends Node2D
## Placeholder market stall on the village map: a coloured block with a "Chợ" label.
## Display only; Main decides what a tap on it does. Story 003.

const SIZE: Vector2 = Vector2(180.0, 120.0)
const BODY_COLOR: Color = Color(0.72, 0.42, 0.2)
const ROOF_COLOR: Color = Color(0.85, 0.25, 0.2)
const ROOF_HEIGHT: float = 36.0
const FONT_SIZE: int = 32


## Centre of the stall in canvas coordinates.
func get_center() -> Vector2:
	return to_global(SIZE * 0.5)


## True when [param canvas_position] lies on the stall.
func contains_point(canvas_position: Vector2) -> bool:
	return Rect2(Vector2.ZERO, SIZE).has_point(to_local(canvas_position))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BODY_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, ROOF_HEIGHT)), ROOF_COLOR)
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size("Chợ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	draw_string(font, Vector2((SIZE.x - text_size.x) * 0.5, ROOF_HEIGHT + 56.0), "Chợ",
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
