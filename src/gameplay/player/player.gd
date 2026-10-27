class_name Player
extends Node2D
## Placeholder farmer that walks in a straight line to a tapped point. Speed and size come from
## GameConfig through [method setup]; before it is called the speed is 0, so a forgotten setup
## shows up as a player who does not move instead of hiding behind a default.
##
## Usage:
##   player.setup(config)
##   player.arrived.connect(_on_player_arrived)
##   player.move_to(Vector2(400, 300))

## Emitted once the player reaches the point passed to move_to().
signal arrived

## Walking speed in pixels per second.
var speed: float = 0.0
## Radius of the drawn figure in pixels.
var radius: float = 0.0

var _target: Vector2
var _moving: bool = false


## Takes the walking speed and the figure size from [param config].
func setup(config: GameConfig) -> void:
	speed = config.player_speed()
	radius = config.player_radius()
	queue_redraw()


## Starts walking toward [param canvas_position]. Always emits arrived afterwards.
func move_to(canvas_position: Vector2) -> void:
	_target = canvas_position
	_moving = true


func _process(delta: float) -> void:
	if not _moving:
		return
	position = position.move_toward(_target, speed * delta)
	if position.is_equal_approx(_target):
		_moving = false
		arrived.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.6, 0.2))
	draw_circle(Vector2(-6, -4), 3.0, Color.BLACK)
	draw_circle(Vector2(6, -4), 3.0, Color.BLACK)
