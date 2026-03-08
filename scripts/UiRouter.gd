extends Node

signal modal_requested(payload: Dictionary)
signal guide_updated(steps: Array, current_index: int)

var last_event_id := ""
var walkthrough_steps: Array = [
	"在贫民街看价格、看耳语、看账本 HUD。",
	"完成一次打工或货物交易，拿到第一笔周转钱。",
	"花钱打听一条风声，注意新闻和街区状态。",
	"去交易所完成一次股票买卖，观察家族动作。",
	"结束一天，看事件、新闻、街区反馈和资产变化。"
]


func push_modal(title: String, body: String, tone: String = "news") -> void:
	modal_requested.emit({
		"title": title,
		"body": body,
		"tone": tone
	})


func update_guide(world_state: Dictionary) -> void:
	var player: Dictionary = world_state.get("player", {})
	var metrics: Dictionary = world_state.get("demo_metrics", {})
	var guide_index := 0
	if int(metrics.get("work_actions", 0)) + int(metrics.get("goods_trades", 0)) > 0 or int(player.get("cash", 0)) >= 35:
		guide_index = 1
	if int(metrics.get("intel_actions", 0)) > 0 or int(metrics.get("npc_talks", 0)) > 0 or player.get("rumors", []).size() > 0:
		guide_index = 2
	if int(metrics.get("stock_trades", 0)) > 0:
		guide_index = 3
	if int(metrics.get("days_ended", 0)) > 0 or int(world_state.get("day", 1)) > 1:
		guide_index = 4
	guide_updated.emit(walkthrough_steps, guide_index)


func maybe_present_event(world_state: Dictionary) -> void:
	var events: Array = world_state.get("pending_events", [])
	if events.is_empty():
		return
	var first: Dictionary = events[0]
	var event_id := str(first.get("id", ""))
	if event_id.is_empty() or event_id == last_event_id:
		return
	last_event_id = event_id
	push_modal(str(first.get("name", "新事件")), str(first.get("description", "")), "event")
