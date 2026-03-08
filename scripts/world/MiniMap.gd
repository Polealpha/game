extends Control
class_name MiniMapView

var world_rect := Rect2(0, 0, 1600, 980)
var district_rects: Dictionary = {}
var district_states: Dictionary = {}
var player_position := Vector2.ZERO
var npc_points: Array = []
var interactable_points: Array = []
var current_district := ""


func configure(layout_world_rect: Rect2, layout_district_rects: Dictionary) -> void:
	world_rect = layout_world_rect
	district_rects = layout_district_rects.duplicate(true)
	queue_redraw()


func update_snapshot(snapshot: Dictionary, actor_position: Vector2, interactables: Array, district_name: String) -> void:
	player_position = actor_position
	current_district = district_name
	npc_points.clear()
	interactable_points.clear()
	for row in snapshot.get("districts", []):
		district_states[str(row.get("name", ""))] = str(row.get("state", "normal"))
	for npc in snapshot.get("npcs", []):
		npc_points.append({
			"position": Vector2(float(npc.get("x", 0.0)), float(npc.get("y", 0.0))),
			"district": str(npc.get("district", "")),
			"mood": str(npc.get("mood", ""))
		})
	for node in interactables:
		interactable_points.append({
			"position": node.position,
			"kind": node.kind
		})
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("19120d"), true)
	draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), Color("ead8b1"), false, 3.0)
	for district_name in district_rects.keys():
		var rect: Rect2 = district_rects[district_name]
		var mini_rect := _world_to_map_rect(rect)
		draw_rect(mini_rect, _district_color(district_name), true)
		draw_rect(mini_rect, Color(1, 0.93, 0.78, 0.35), false, 1.0)
		if district_name == current_district:
			draw_rect(mini_rect.grow(2), Color("f3dfac"), false, 2.0)
	draw_line(_world_to_map(Vector2(800, 40)), _world_to_map(Vector2(800, 920)), Color("c49a63"), 2.0)
	draw_line(_world_to_map(Vector2(40, 490)), _world_to_map(Vector2(1560, 490)), Color("c49a63"), 2.0)
	for point in interactable_points:
		draw_circle(_world_to_map(point.get("position", Vector2.ZERO)), 3.5, _interactable_color(str(point.get("kind", ""))))
	for point in npc_points:
		draw_circle(_world_to_map(point.get("position", Vector2.ZERO)), 2.2, _npc_color(str(point.get("mood", ""))))
	draw_circle(_world_to_map(player_position), 4.5, Color("8bd36c"))
	draw_circle(_world_to_map(player_position), 7.5, Color(0.55, 0.85, 0.42, 0.2))


func _world_to_map(point: Vector2) -> Vector2:
	var padding := Vector2(12, 12)
	var scale := Vector2(
		(size.x - padding.x * 2.0) / world_rect.size.x,
		(size.y - padding.y * 2.0) / world_rect.size.y
	)
	return padding + Vector2(point.x * scale.x, point.y * scale.y)


func _world_to_map_rect(rect: Rect2) -> Rect2:
	var pos := _world_to_map(rect.position)
	var end := _world_to_map(rect.position + rect.size)
	return Rect2(pos, end - pos)


func _district_color(district_name: String) -> Color:
	var state := str(district_states.get(district_name, "normal"))
	var base := Color("58402c")
	match district_name:
		"贫民街":
			base = Color("5b4431")
		"港口":
			base = Color("35576a")
		"工厂区":
			base = Color("4b3b31")
		"交易所":
			base = Color("65513d")
	match state:
		"prosperous":
			return base.lightened(0.12)
		"tense":
			return base.darkened(0.08)
		"unrest":
			return base.darkened(0.18)
		"declining":
			return base.darkened(0.24)
	return base


func _interactable_color(kind: String) -> Color:
	match kind:
		"work":
			return Color("c07f31")
		"goods":
			return Color("d4b35e")
		"stocks":
			return Color("8aa96b")
		"info":
			return Color("9e6db8")
		"tasks":
			return Color("d4715d")
		"end_day":
			return Color("f1df9d")
	return Color("d8c8a1")


func _npc_color(mood: String) -> Color:
	match mood:
		"anxious":
			return Color("c26a54")
		"excited":
			return Color("d1a04e")
		"hopeful":
			return Color("85a15a")
		"defiant":
			return Color("b55147")
		"tired":
			return Color("7f6d58")
	return Color("d6c7a4")
