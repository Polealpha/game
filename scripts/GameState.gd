extends Node

signal snapshot_updated(snapshot: Dictionary)
signal toast_added(message: String)

var snapshot: Dictionary = {}


func apply_snapshot(data: Dictionary) -> void:
	snapshot = data
	snapshot_updated.emit(snapshot)


func add_toast(message: String) -> void:
	toast_added.emit(message)


func get_player() -> Dictionary:
	return snapshot.get("player", {})


func get_npcs() -> Array:
	return snapshot.get("npcs", [])


func get_headlines() -> Array:
	return snapshot.get("headline_news", [])


func get_npc_highlights() -> Array:
	return snapshot.get("npc_highlights", [])


func get_macro_summary() -> Dictionary:
	return snapshot.get("macro_summary", {})


func get_task_summary() -> Dictionary:
	return snapshot.get("task_summary", {})


func get_task_board() -> Array:
	return snapshot.get("task_board", [])
