class_name Player
extends Node2D
## Placeholder farmer that walks in a straight line to a tapped point.
##
## Usage:
##   player.arrived.connect(_on_player_arrived)
##   player.move_to(Vector2(400, 300))

## Emitted once the player reaches the point passed to move_to().
signal arrived

const SPEED: float = 360.0
const RADIUS: float = 18.0

var _target: Vector2
var _moving: bool = false


## Starts walking toward [param canvas_position]. Always emits arrived afterwards.
func move_to(canvas_position: Vector2) -> void:
	_target = canvas_position
	_moving = true


func _process(delta: float) -> void:
	if not _moving:
		return
	position = position.move_toward(_target, SPEED * delta)
	if position.is_equal_approx(_target):
		_moving = false
		arrived.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.6, 0.2))
	draw_circle(Vector2(-6, -4), 3.0, Color.BLACK)
	draw_circle(Vector2(6, -4), 3.0, Color.BLACK)
