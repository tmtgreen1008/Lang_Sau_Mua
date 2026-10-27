class_name VillageView
extends Node2D
## Draws the village (houses, road segments, ground tint) as flat-colour placeholder
## shapes behind everything else. Display only: it reads a [VillageProgress] and never
## changes it. All shapes, colours and positions come from the progress' data file.
## Implements story 005 (design/game-brief.md, MVP feature 5).
##
## Place this node at the top-left of the field and add it BEFORE the field, stall and
## neighbors so it is drawn behind them: piece origins are relative to that position.
##
## Usage:
##   var view := VillageView.new()
##   view.position = farm_view.position
##   add_child(view)            # before the farm view
##   view.setup(village_progress)
##   view.reduce_motion = true  # accessibility: changes become instant

## When true, restorations and level changes are applied instantly (no tween, no flash).
var reduce_motion: bool = false
## While true, new restorations wait (the village keeps its old look); setting it back
## to false plays them. Used so the effect is not hidden behind a modal panel.
var effects_held: bool = false:
	set(value):
		effects_held = value
		if not value:
			_flush()

var _progress: VillageProgress
## Per piece: {id, origin: Vector2, size: Vector2, shapes: Array[Dictionary]} with colours parsed.
var _pieces: Array[Dictionary] = []
## piece_id -> 0.0 (ruined) .. 1.0 (restored).
var _blend: Dictionary[String, float] = {}
var _tweens: Dictionary[String, Tween] = {}
var _pending_pieces: Array[String] = []
var _pending_level: int = -1
var _tint_from: Color = Color.TRANSPARENT
var _tint_to: Color = Color.TRANSPARENT
var _tint_mix: float = 1.0
var _tint_tween: Tween
var _duration: float = 1.0
var _flash: float = 0.0
var _pulse_scale: float = 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


## Reads the pieces and levels from [param progress] and shows its current state at once.
func setup(progress: VillageProgress) -> void:
	_progress = progress
	var effect: Dictionary = progress.get_effect()
	_duration = float(effect.get("duration", 1.0))
	_flash = float(effect.get("flash", 0.0))
	_pulse_scale = float(effect.get("pulse_scale", 0.0))
	_pieces.clear()
	for def: Dictionary in progress.get_piece_defs():
		var origin: Array = def.get("origin", [0, 0]) as Array
		var size: Array = def.get("size", [0, 0]) as Array
		var shapes: Array[Dictionary] = []
		for raw: Variant in def.get("shapes", []) as Array:
			var shape: Dictionary = raw as Dictionary
			shapes.append({
				"kind": str(shape.get("kind", "rect")),
				"ruined": _parse_side(shape.get("ruined")),
				"restored": _parse_side(shape.get("restored")),
			})
		_pieces.append({
			"id": str(def["id"]),
			"origin": Vector2(float(origin[0]), float(origin[1])),
			"size": Vector2(float(size[0]), float(size[1])),
			"shapes": shapes,
		})
	sync()
	if not progress.piece_restored.is_connected(_on_piece_restored):
		progress.piece_restored.connect(_on_piece_restored)
		progress.level_changed.connect(_on_level_changed)


## Drops any running effect and shows the progress' current state immediately (the contract
## every view has, ADR-0002 rule 7; use after [method VillageProgress.from_dict]).
func sync() -> void:
	for tween: Tween in _tweens.values():
		tween.kill()
	_tweens.clear()
	if _tint_tween != null:
		_tint_tween.kill()
	_pending_pieces.clear()
	_pending_level = -1
	for piece: Dictionary in _pieces:
		var piece_id: String = piece["id"]
		_blend[piece_id] = 1.0 if _progress.is_piece_restored(piece_id) else 0.0
	_tint_to = _level_tint(_progress.get_level())
	_tint_from = _tint_to
	_tint_mix = 1.0
	queue_redraw()


func _on_piece_restored(piece_id: String) -> void:
	_pending_pieces.append(piece_id)
	_flush()


func _on_level_changed(level: int) -> void:
	_pending_level = level
	_flush()


func _flush() -> void:
	if effects_held or _progress == null:
		return
	for piece_id: String in _pending_pieces:
		_start_piece(piece_id)
	_pending_pieces.clear()
	if _pending_level >= 0:
		_start_tint(_level_tint(_pending_level))
		_pending_level = -1


func _start_piece(piece_id: String) -> void:
	if _tweens.has(piece_id):
		_tweens[piece_id].kill()
	if reduce_motion or _duration <= 0.0:
		_blend[piece_id] = 1.0
		queue_redraw()
		return
	_blend[piece_id] = 0.0
	var tween: Tween = create_tween()
	tween.tween_method(_set_blend.bind(piece_id), 0.0, 1.0, _duration)
	_tweens[piece_id] = tween
	tween.finished.connect(func() -> void: _tweens.erase(piece_id))


func _start_tint(target: Color) -> void:
	if _tint_tween != null:
		_tint_tween.kill()
	_tint_from = _tint_from.lerp(_tint_to, _tint_mix)
	_tint_to = target
	if reduce_motion or _duration <= 0.0:
		_tint_from = target
		_tint_mix = 1.0
		queue_redraw()
		return
	_tint_mix = 0.0
	_tint_tween = create_tween()
	_tint_tween.tween_method(_set_tint_mix, 0.0, 1.0, _duration)


func _set_blend(value: float, piece_id: String) -> void:
	_blend[piece_id] = value
	queue_redraw()


func _set_tint_mix(value: float) -> void:
	_tint_mix = value
	queue_redraw()


func _level_tint(level: int) -> Color:
	return Color.from_string(str(_progress.get_level_def(level).get("ground_tint", "#00000000")),
			Color.TRANSPARENT)


## {g: PackedFloat32Array, color: Color}, or {} when the side is null/absent.
func _parse_side(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var side: Dictionary = raw
	return {
		"g": PackedFloat32Array(side.get("g", []) as Array),
		"color": Color.from_string(str(side.get("color", "#ff00ff")), Color.MAGENTA),
	}


func _draw() -> void:
	if _progress == null:
		return
	var tint: Color = _tint_from.lerp(_tint_to, _tint_mix)
	draw_rect(Rect2(to_local(Vector2.ZERO), get_viewport_rect().size), tint)
	for piece: Dictionary in _pieces:
		var t: float = _blend.get(str(piece["id"]), 0.0)
		# 0 at both ends of the blend, 1 in the middle: the glow and pulse of the effect.
		var glow: float = sin(PI * t)
		var scale_factor: float = 1.0 + _pulse_scale * glow
		var size: Vector2 = piece["size"]
		draw_set_transform(
				(piece["origin"] as Vector2) + size * 0.5 * (1.0 - scale_factor), 0.0,
				Vector2(scale_factor, scale_factor))
		for shape: Dictionary in piece["shapes"]:
			_draw_shape(shape, t, _flash * glow)
	draw_set_transform(Vector2.ZERO)


func _draw_shape(shape: Dictionary, t: float, brighten: float) -> void:
	var ruined: Dictionary = shape["ruined"]
	var restored: Dictionary = shape["restored"]
	var geometry: PackedFloat32Array
	var color: Color
	if ruined.is_empty():
		geometry = restored["g"]
		color = restored["color"]
		color.a *= t
	elif restored.is_empty():
		geometry = ruined["g"]
		color = ruined["color"]
		color.a *= 1.0 - t
	else:
		var from_g: PackedFloat32Array = ruined["g"]
		var to_g: PackedFloat32Array = restored["g"]
		if from_g.size() == to_g.size():
			geometry = PackedFloat32Array()
			geometry.resize(from_g.size())
			for i: int in from_g.size():
				geometry[i] = lerpf(from_g[i], to_g[i], t)
		else:
			geometry = to_g if t >= 0.5 else from_g
		color = (ruined["color"] as Color).lerp(restored["color"] as Color, t)
	if color.a <= 0.01 or geometry.is_empty():
		return
	var alpha: float = color.a
	color = color.lerp(Color(1.0, 0.95, 0.75), brighten)
	color.a = alpha
	match str(shape["kind"]):
		"rect":
			draw_rect(Rect2(geometry[0], geometry[1], geometry[2], geometry[3]), color)
		"ellipse":
			var points := PackedVector2Array()
			for i: int in 20:
				var angle: float = TAU * float(i) / 20.0
				points.append(Vector2(geometry[0] + cos(angle) * geometry[2],
						geometry[1] + sin(angle) * geometry[3]))
			draw_colored_polygon(points, color)
		"poly":
			var points := PackedVector2Array()
			for i: int in geometry.size() / 2:
				points.append(Vector2(geometry[i * 2], geometry[i * 2 + 1]))
			draw_colored_polygon(points, color)
