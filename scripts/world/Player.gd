extends Node2D
class_name PlayerView

const TURN_DURATION := 0.18
const INTERACT_DURATION := 0.34
const CHARACTER_SCALE := Vector2(0.82, 0.82)
const CHARACTER_BASE_PATH := "res://assets/generated/portrait_people"
const SHEET_PATHS := {
	"idle": {
		"down": CHARACTER_BASE_PATH + "/player_idle.png",
		"up": CHARACTER_BASE_PATH + "/player_idle.png",
		"left": CHARACTER_BASE_PATH + "/player_idle.png",
		"right": CHARACTER_BASE_PATH + "/player_idle.png",
	},
	"walk": {
		"down": CHARACTER_BASE_PATH + "/player_move.png",
		"up": CHARACTER_BASE_PATH + "/player_move.png",
		"left": CHARACTER_BASE_PATH + "/player_move.png",
		"right": CHARACTER_BASE_PATH + "/player_move.png",
	},
	"interact": {
		"down": CHARACTER_BASE_PATH + "/player_move.png",
		"up": CHARACTER_BASE_PATH + "/player_move.png",
		"left": CHARACTER_BASE_PATH + "/player_move.png",
		"right": CHARACTER_BASE_PATH + "/player_move.png",
	},
}
const FRAME_COUNTS := {
	"idle": 4,
	"walk": 8,
	"interact": 8,
}
const FRAME_RATES := {
	"idle": 4.6,
	"walk": 10.6,
	"interact": 12.8,
}
const INTERACTION_ICON_PATHS := {
	"use": "res://assets/vendor/opengameart/496_RPG_icons/I_Key01.png",
	"talk": "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_dots3.png",
	"point": "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_idea.png",
	"search": "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_question.png",
	"carry": "res://assets/vendor/opengameart/496_RPG_icons/E_Wood01.png",
	"write": "res://assets/vendor/opengameart/496_RPG_icons/I_Book.png",
	"cook": "res://assets/vendor/opengameart/496_RPG_icons/I_C_Bread.png",
	"rest": "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_sleep.png",
}

var movement := Vector2.ZERO
var facing := Vector2(0.0, 1.0)
var facing_visual := Vector2(0.0, 1.0)
var last_direction_name := "down"
var anim_time := 0.0
var idle_time := 0.0
var turn_timer := 0.0
var interact_timer := 0.0
var interaction_mode := "use"
var sprite := Sprite2D.new()
var sheet_cache: Dictionary = {}
var prop_texture_cache: Dictionary = {}


func _ready() -> void:
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = CHARACTER_SCALE
	sprite.position = Vector2(0, -34)
	add_child(sprite)
	_update_sprite()
	queue_redraw()


func set_movement_direction(direction: Vector2) -> void:
	movement = direction
	if direction.length() > 0.08:
		_face_towards(direction.normalized())


func trigger_interaction(direction: Vector2 = Vector2.ZERO, mode: String = "use") -> void:
	if direction.length() > 0.08:
		_face_towards(direction.normalized())
	interaction_mode = mode
	interact_timer = INTERACT_DURATION


func face_towards(direction: Vector2) -> void:
	if direction.length() > 0.08:
		_face_towards(direction.normalized())


func _face_towards(direction: Vector2) -> void:
	var next_dir := _direction_name_from_vector(direction)
	if next_dir != last_direction_name:
		turn_timer = TURN_DURATION
		last_direction_name = next_dir
	facing = direction


func _process(delta: float) -> void:
	var moving := movement.length() > 0.1
	anim_time += delta
	idle_time += delta
	turn_timer = max(turn_timer - delta, 0.0)
	interact_timer = max(interact_timer - delta, 0.0)
	facing_visual = facing_visual.lerp(facing.normalized(), minf(delta * (10.0 if moving else 6.5), 1.0))
	_update_sprite()
	queue_redraw()


func _update_sprite() -> void:
	var dir := _direction_name_from_vector(facing_visual)
	var anim_name := "idle"
	if interact_timer > 0.01:
		anim_name = "interact"
	elif movement.length() > 0.08:
		anim_name = "walk"
	var texture := _load_sheet(anim_name, dir)
	if texture == null and anim_name == "interact":
		texture = _load_sheet("walk", dir)
		anim_name = "walk"
	if texture == null:
		texture = _load_sheet("idle", dir)
		anim_name = "idle"
	if texture == null:
		return
	var frame_count := int(FRAME_COUNTS.get(anim_name, 1))
	sprite.texture = texture
	sprite.hframes = max(frame_count, 1)
	sprite.vframes = 4
	sprite.frame_coords = Vector2i(
		int(fposmod(anim_time * float(FRAME_RATES.get(anim_name, 4.0)), frame_count)),
		_row_for_direction(dir)
	)
	var bob := 0.0
	if movement.length() > 0.08:
		bob = -abs(sin(anim_time * 10.6)) * 4.4
	elif interact_timer > 0.01:
		bob = -sin((1.0 - interact_timer / INTERACT_DURATION) * PI) * 5.6
	else:
		bob = -sin(idle_time * 2.1) * 1.9
	sprite.position = Vector2(0, -34 + bob)
	sprite.rotation = sin((1.0 - turn_timer / TURN_DURATION) * PI) * 0.02 if turn_timer > 0.0 else 0.0
	var stride := 0.0
	if movement.length() > 0.08:
		stride = sin(anim_time * 10.6) * 0.035
	elif interact_timer > 0.01:
		stride = sin((1.0 - interact_timer / INTERACT_DURATION) * PI) * 0.025
	else:
		stride = sin(idle_time * 1.7) * 0.012
	sprite.scale = Vector2(CHARACTER_SCALE.x * (1.0 + stride * 0.28), CHARACTER_SCALE.y * (1.0 - abs(stride) * 0.08))


func _draw() -> void:
	var moving := movement.length() > 0.08
	var shadow_size := Vector2(16.0 + (2.6 if moving else 0.0), 8.5 + (1.0 if interact_timer > 0.01 else 0.0))
	_draw_shadow(Vector2(0, 25), shadow_size, 0.22)
	if interact_timer > 0.01:
		_draw_interaction_prop()


func _draw_shadow(center: Vector2, radii: Vector2, alpha: float) -> void:
	var points := PackedVector2Array()
	for step in range(20):
		var angle := TAU * float(step) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, Color(0, 0, 0, alpha))


func _draw_interaction_prop() -> void:
	var texture := _load_prop_texture(str(INTERACTION_ICON_PATHS.get(interaction_mode, "")))
	if texture == null:
		return
	var pop := sin((1.0 - interact_timer / INTERACT_DURATION) * PI)
	var center := Vector2(0, -66 - pop * 8.0)
	draw_circle(center, 16.0 + pop * 2.0, Color(0.08, 0.05, 0.02, 0.34))
	draw_circle(center, 13.0 + pop * 1.6, Color(0.98, 0.9, 0.72, 0.16))
	draw_texture_rect(texture, Rect2(center - Vector2(11, 11), Vector2(22, 22)), false, Color(1, 1, 1, 0.95))


func _load_sheet(anim_name: String, dir: String) -> Texture2D:
	var sheet_group: Dictionary = SHEET_PATHS.get(anim_name, {})
	var path := str(sheet_group.get(dir, ""))
	if path.is_empty():
		return null
	if sheet_cache.has(path):
		return sheet_cache[path]
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	if texture != null:
		sheet_cache[path] = texture
	return texture


func _load_prop_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if prop_texture_cache.has(path):
		return prop_texture_cache[path]
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	if texture != null:
		prop_texture_cache[path] = texture
	return texture


func _direction_name_from_vector(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x >= 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _row_for_direction(dir: String) -> int:
	match dir:
		"up":
			return 0
		"left":
			return 1
		"right":
			return 3
		_:
			return 2
