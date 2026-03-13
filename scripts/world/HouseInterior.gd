extends Node2D
class_name HouseInteriorView

const PlayerView = preload("res://scripts/world/Player.gd")
const InteractableView = preload("res://scripts/world/Interactable.gd")

const ROOM_RECT := Rect2(Vector2(0, 0), Vector2(1320, 880))
const WALK_RECT := Rect2(Vector2(96, 132), Vector2(1128, 640))
const PLAYER_SPEED := 275.0
const WOOD_CHEST_OPEN := preload("res://assets/vendor/superpowers/medieval-fantasy/items/wood-chest-open.png")
const WOOD_CHEST_CLOSED := preload("res://assets/vendor/superpowers/medieval-fantasy/items/wood-chest-close.png")
const BARREL_TEXTURE := preload("res://assets/vendor/superpowers/medieval-fantasy/items/barrel.png")
const CRATE_TEXTURE := preload("res://assets/vendor/superpowers/medieval-fantasy/items/crate.png")
const FOOD_SHEET := preload("res://assets/vendor/superpowers/medieval-fantasy/items/food-&-potion/food.png")
const OTHER_ITEMS_SHEET := preload("res://assets/vendor/superpowers/medieval-fantasy/items/other.png")
const GOLD_CUP_TEXTURE := preload("res://assets/vendor/superpowers/medieval-fantasy/items/gold-&-gem/gold-cup.png")
const GOLD_TEXTURE := preload("res://assets/vendor/superpowers/medieval-fantasy/items/gold-&-gem/gold.png")
const GEM_TEXTURE := preload("res://assets/vendor/superpowers/medieval-fantasy/items/gold-&-gem/gem-1.png")
const WEAPON_SHEET := preload("res://assets/vendor/superpowers/medieval-fantasy/items/weapon/weapon.png")
const CHARACTER_SHEET := preload("res://assets/vendor/superpowers/medieval-fantasy/characters/0-characters.png")
const CALCIUM_INTERIOR_PATH := "res://assets/vendor/calciumtrice/medieval_tileset_interior.png"
const LPC_WOODSHOP_PATH := "res://assets/vendor/lpc_woodshop/lpc-woodshop/woodshop.png"
const LPC_LIGHTS_PATH := "res://assets/vendor/lpc_castle_lights.png"
const STOCK_EXCHANGE_INTERIOR_PATH := "res://证券交易所_4k_realesrgan.png"
const CUSTOM_ROOM_TEXTURES := {
	"news_center_1": "res://assets/interiors/news_center.png",
	"factory_2": "res://assets/interiors/factory.png",
	"factory_house": "res://assets/interiors/factory.png",
	"food_market_3": "res://assets/interiors/food_market.png",
	"food_market_4": "res://assets/interiors/food_market.png",
	"bookstore_5": "res://assets/interiors/bookstore.png",
	"stock_exchange_6": "res://assets/interiors/stock_exchange.png",
	"capitalist_mansion_7": "res://assets/interiors/capitalist_mansion.png",
	"bar_8": "res://assets/interiors/bar.png",
	"slum_9": "res://assets/interiors/slum.png",
	"slum_10": "res://assets/interiors/slum.png",
	"slum_house": "res://assets/interiors/slum.png",
}
const CUSTOM_ROOM_WALK_MASK_TEXTURES := {
	"news_center_1": "res://assets/interiors/walk_masks/news_center.png",
	"factory_2": "res://assets/interiors/walk_masks/factory.png",
	"factory_house": "res://assets/interiors/walk_masks/factory.png",
	"food_market_3": "res://assets/interiors/walk_masks/food_market.png",
	"food_market_4": "res://assets/interiors/walk_masks/food_market.png",
	"bookstore_5": "res://assets/interiors/walk_masks/bookstore.png",
	"stock_exchange_6": "res://assets/interiors/walk_masks/stock_exchange.png",
	"stock_exchange": "res://assets/interiors/walk_masks/stock_exchange.png",
	"capitalist_mansion_7": "res://assets/interiors/walk_masks/capitalist_mansion.png",
	"bar_8": "res://assets/interiors/walk_masks/bar.png",
	"slum_9": "res://assets/interiors/walk_masks/slum.png",
	"slum_10": "res://assets/interiors/walk_masks/slum.png",
	"slum_house": "res://assets/interiors/walk_masks/slum.png",
}
const CUSTOM_ROOM_WALK_MASK_SOURCE_RECTS := {
	"news_center_1": Rect2(1272, 1978, 2004, 562),
	"factory_2": Rect2(36, 1642, 1920, 1015),
	"factory_house": Rect2(36, 1642, 1920, 1015),
	"food_market_3": Rect2(1334, 1538, 1921, 1144),
	"food_market_4": Rect2(1334, 1538, 1921, 1144),
	"bookstore_5": Rect2(1398, 1420, 1921, 1278),
	"stock_exchange_6": Rect2(622, 1478, 1922, 1152),
	"stock_exchange": Rect2(622, 1478, 1922, 1152),
	"capitalist_mansion_7": Rect2(1228, 1800, 1920, 664),
	"bar_8": Rect2(1462, 2118, 1921, 586),
	"slum_9": Rect2(672, 1884, 1918, 814),
	"slum_10": Rect2(672, 1884, 1918, 814),
	"slum_house": Rect2(672, 1884, 1918, 814),
}
const CUSTOM_ROOM_FRAME_RECT := Rect2(56, 56, 1208, 768)
const STOCK_EXCHANGE_FRAME_RECT := Rect2(54, 84, 1212, 720)
const ROOM_WALK_MASK_ALPHA_THRESHOLD := 0.08
const ROOM_TEXTURE := preload("res://assets/vendor/tiny_wizard/art/room.png")
const TW_NORMAL_CHEST := preload("res://assets/vendor/tiny_wizard/props/chests/normal_chest_closed.png")
const TW_GOLD_CHEST := preload("res://assets/vendor/tiny_wizard/props/chests/gold_chest_closed.png")
const TW_UP_DOOR := preload("res://assets/vendor/tiny_wizard/props/doors/up_door.png")
const TW_DOWN_DOOR := preload("res://assets/vendor/tiny_wizard/props/doors/down_door.png")
const TW_COIN := preload("res://assets/vendor/tiny_wizard/props/items/coin.png")
const TW_KEY := preload("res://assets/vendor/tiny_wizard/props/items/key.png")
const EMOTE_SLEEP_PATH := "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_sleep.png"
const EMOTE_SLEEPS_PATH := "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_sleeps.png"
const CALCIUM_DINING_REGION := Rect2(96, 160, 96, 48)
const CALCIUM_SHELF_REGION := Rect2(176, 144, 64, 64)
const CALCIUM_COUNTER_REGION := Rect2(208, 144, 96, 64)
const CALCIUM_FORGE_REGION := Rect2(0, 224, 112, 96)
const CALCIUM_DISH_REGION := Rect2(160, 208, 80, 48)
const CALCIUM_TOOL_REGION := Rect2(224, 256, 64, 48)
const CALCIUM_CRATE_REGION := Rect2(208, 272, 112, 48)
const CALCIUM_BARREL_REGION := Rect2(224, 160, 96, 64)
const WOODSHOP_BENCH_REGION := Rect2(0, 0, 256, 64)
const WOODSHOP_SAW_REGION := Rect2(176, 64, 128, 96)
const WOODSHOP_TOOL_WALL_REGION := Rect2(0, 176, 256, 48)
const WOODSHOP_TOOLS_REGION := Rect2(0, 224, 256, 80)
const WOODSHOP_WOOD_REGION := Rect2(0, 320, 256, 112)
const WOODSHOP_CRATE_REGION := Rect2(176, 224, 160, 96)
const LPC_TORCH_REGION := Rect2(0, 0, 16, 48)
const LPC_SMALL_TORCH_REGION := Rect2(16, 0, 16, 48)

var room_player := PlayerView.new()
var room_camera := Camera2D.new()
var interactable_layer := Node2D.new()
var world_tint := CanvasModulate.new()
var title_label := Label.new()
var subtitle_label := Label.new()
var calcium_interior: Texture2D
var woodshop_texture: Texture2D
var lights_texture: Texture2D
var stock_exchange_interior: Texture2D
var custom_room_texture: Texture2D
var custom_room_walk_mask_image: Image
var emote_sleep_texture: Texture2D
var emote_sleeps_texture: Texture2D

var interactables: Array[InteractableView] = []
var current_interactable: InteractableView = null
var house_data: Dictionary = {}
var house_layout: Dictionary = {}
var house_theme: Dictionary = {}
var house_state: Dictionary = {}
var active := false
var pulse_time := 0.0
var current_period := "day"
var current_light_level := 1.0
var current_clock_minutes := 8 * 60
var current_clock_label := "08:00"
var exchange_hud_state: Dictionary = {}
var room_caption := "屋里还有温度。"


func _ready() -> void:
	calcium_interior = _load_runtime_texture(CALCIUM_INTERIOR_PATH)
	woodshop_texture = _load_runtime_texture(LPC_WOODSHOP_PATH)
	lights_texture = _load_runtime_texture(LPC_LIGHTS_PATH)
	stock_exchange_interior = _load_runtime_texture(STOCK_EXCHANGE_INTERIOR_PATH)
	emote_sleep_texture = _load_runtime_texture(EMOTE_SLEEP_PATH)
	emote_sleeps_texture = _load_runtime_texture(EMOTE_SLEEPS_PATH)
	add_child(world_tint)
	add_child(interactable_layer)
	add_child(room_player)
	room_player.add_child(room_camera)
	room_camera.enabled = false
	room_camera.position_smoothing_enabled = true
	room_camera.position_smoothing_speed = 5.8
	room_camera.zoom = Vector2.ONE
	room_camera.limit_left = int(ROOM_RECT.position.x)
	room_camera.limit_top = int(ROOM_RECT.position.y)
	room_camera.limit_right = int(ROOM_RECT.end.x)
	room_camera.limit_bottom = int(ROOM_RECT.end.y)

	title_label.position = Vector2(28, 24)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("f1e0b8"))
	add_child(title_label)

	subtitle_label.position = Vector2(28, 56)
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color("d4c29d"))
	add_child(subtitle_label)

	visible = false
	set_process(false)
	queue_redraw()


func _load_runtime_image(path: String, warn_on_fail: bool = true) -> Image:
	if path.is_empty():
		return null
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		if warn_on_fail:
			push_warning("Failed to load runtime texture: %s" % path)
		return null
	return image


func _load_runtime_texture(path: String, warn_on_fail: bool = true) -> Texture2D:
	var image := _load_runtime_image(path, warn_on_fail)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _exit_tree() -> void:
	for node in interactables:
		if is_instance_valid(node):
			node.queue_free()
	interactables.clear()
	current_interactable = null
	calcium_interior = null
	woodshop_texture = null
	lights_texture = null
	stock_exchange_interior = null
	custom_room_texture = null
	custom_room_walk_mask_image = null
	emote_sleep_texture = null
	emote_sleeps_texture = null


func set_active(enabled: bool) -> void:
	active = enabled
	visible = enabled
	set_process(enabled)
	room_camera.enabled = enabled
	if not enabled:
		room_player.set_movement_direction(Vector2.ZERO)
		current_interactable = null
		for node in interactables:
			if is_instance_valid(node):
				node.set_highlighted(false)


func enter_house(data: Dictionary) -> void:
	house_data = data.duplicate(true)
	house_state = data.get("house_state", {}).duplicate(true)
	if not _is_exchange_scene():
		exchange_hud_state.clear()
	house_theme = _theme_for_house(house_data)
	house_layout = _layout_for_house(house_data)
	custom_room_texture = _load_runtime_texture(_custom_room_texture_path_for_house(_scene_house_id()), false)
	custom_room_walk_mask_image = _load_runtime_image(_custom_room_walk_mask_path_for_house(_scene_house_id()), false)
	if _is_exchange_scene():
		house_layout["entry_x"] = 1078.0
		house_layout["entry_y"] = 724.0
		house_layout["desk_x"] = 314.0
		house_layout["desk_y"] = 586.0
		house_layout["storage_x"] = 180.0
		house_layout["storage_y"] = 708.0
		house_layout["kitchen_x"] = 1036.0
		house_layout["kitchen_y"] = 238.0
		house_layout["bed_x"] = 456.0
		house_layout["bed_y"] = 544.0
		house_layout["route_nodes"] = {
			"entry": Vector2(1078.0, 706.0),
			"storage": Vector2(180.0, 708.0),
			"cabinet": Vector2(180.0, 708.0),
			"desk": Vector2(314.0, 586.0),
			"table": Vector2(760.0, 646.0),
			"kitchen": Vector2(1036.0, 238.0),
			"bedside": Vector2(456.0, 544.0),
			"mending": Vector2(456.0, 544.0),
			"warming": Vector2(456.0, 544.0)
		}
	title_label.text = str(house_data.get("title", "屋内"))
	room_player.position = _spawn_position_for_room(Vector2(
		float(house_layout.get("entry_x", 664.0)),
		float(house_layout.get("entry_y", 674.0))
	))
	_rebuild_interactables()
	_refresh_caption()
	queue_redraw()


func update_house_state(state: Dictionary) -> void:
	house_state = state.duplicate(true)
	_refresh_caption()
	queue_redraw()


func set_exchange_hud_state(state: Dictionary) -> void:
	exchange_hud_state = state.duplicate(true)
	if _is_exchange_scene():
		queue_redraw()


func set_time_of_day(period: String, light_level: float) -> void:
	current_period = period
	current_light_level = light_level
	world_tint.color = Color(
		lerpf(0.34, 1.0, light_level),
		lerpf(0.31, 1.0, light_level),
		lerpf(0.4, 1.0, light_level),
		1.0
	)
	_refresh_caption()
	queue_redraw()


func set_clock_context(clock_minutes: int, clock_label: String = "") -> void:
	if clock_minutes >= 0:
		current_clock_minutes = clock_minutes
	if not clock_label.is_empty():
		current_clock_label = clock_label
	queue_redraw()


func tick(delta: float) -> void:
	pulse_time += delta
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	room_player.set_movement_direction(input_vector)
	var desired_position := room_player.position + input_vector * PLAYER_SPEED * delta
	room_player.position = _resolve_room_motion(room_player.position, desired_position)
	_update_current_interactable()
	queue_redraw()


func get_current_interactable() -> InteractableView:
	return current_interactable


func get_current_district() -> String:
	return str(house_data.get("district", "贫民街"))


func _scene_house_id() -> String:
	return str(house_data.get("id", ""))


func _is_exchange_scene() -> bool:
	return _scene_house_id() in ["stock_exchange", "stock_exchange_6", "exchange_house"]


func get_current_house_payload() -> Dictionary:
	return {
		"house_id": str(house_data.get("action_house_id", house_data.get("id", ""))),
		"house_title": str(house_data.get("title", "")),
	}


func get_player_position() -> Vector2:
	return room_player.position


func get_scene_note() -> String:
	return room_caption


func get_nearby_interactables(limit: int) -> Array:
	var ranked: Array = []
	for node in interactables:
		var distance := room_player.position.distance_to(node.position)
		if distance <= maxf(210.0, _interaction_radius_for_node(node) + 72.0):
			ranked.append({
				"id": node.interaction_id,
				"title": node.title,
				"kind": node.kind,
				"distance": snappedf(distance, 0.1)
			})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	return ranked.slice(0, min(limit, ranked.size()))


func get_hint_text() -> String:
	if current_interactable == null:
		if _is_exchange_scene():
			return "%s 靠近交易席、终端、账桌或正门后按 E；站在门边时按 E 直接退出。" % room_caption
		return "%s 靠近床铺、灶台、储物箱、账桌或门口后按 E。" % room_caption
	return "靠近 %s。按 E 操作。%s" % [current_interactable.title, current_interactable.subtitle]


func _refresh_caption() -> void:
	var base_subtitle := str(house_data.get("subtitle", "木头、油烟和账页味还留在屋里。"))
	subtitle_label.text = "%s · %s" % [base_subtitle, _period_text(current_period)]
	var summary := str(house_state.get("summary_line", ""))
	var schedule_note := str(house_state.get("schedule_note", ""))
	var doorstep_note := str(house_state.get("doorstep_note", ""))
	if summary.is_empty():
		summary = _default_life_note()
	if not schedule_note.is_empty() and schedule_note != summary:
		room_caption = "%s %s" % [summary, schedule_note]
	else:
		room_caption = summary
	if not doorstep_note.is_empty() and room_caption.find(doorstep_note) == -1:
		room_caption = "%s %s" % [room_caption, doorstep_note]


func _default_life_note() -> String:
	match _scene_house_id():
		"news_center_1":
			return "墙上的头版和热线电话都还亮着，城里的风声随时会被写成新闻。"
		"factory_2", "factory_house":
			return "机械臂和控制台都还带着余温，钢铁味和机油味压满了整间屋子。"
		"food_market_3", "food_market_4":
			return "柜台上的货单和价签还没收，今天卖剩下的食材都藏在后头。"
		"bookstore_5":
			return "纸张、灰尘和旧消息混在一起，最值钱的往往不是书而是传闻。"
		"stock_exchange_6", "stock_exchange":
			return "落地窗外压着全城天际线，盘口灯墙和保密金库都在等下一轮敲钟。"
		"capitalist_mansion_7":
			return "证书、藏酒和城市夜景摆在一起，这里每样东西都在宣告权力。"
		"bar_8":
			return "酒瓶、吧台和暖灯把人留在这里，最值钱的话通常都在杯子放下以后。"
		"slum_9", "slum_10", "slum_house":
			return "床铺、旧报纸和裂开的墙皮全挤在一起，日子还得靠这间屋子顶着。"
		"dock_house":
			return "潮气贴在木梁上，绳结和锅具都还留着盐味。"
		"exchange_house":
			return "桌上的账本翻到半页，蜡油沿着铜台慢慢往下流。"
		_:
			return "补丁布帘挡着风，木板缝里还带着晚饭后的热气。"


func _custom_room_texture_path_for_house(house_id: String) -> String:
	return str(CUSTOM_ROOM_TEXTURES.get(house_id, ""))


func _custom_room_walk_mask_path_for_house(house_id: String) -> String:
	return str(CUSTOM_ROOM_WALK_MASK_TEXTURES.get(house_id, ""))


func _custom_room_walk_mask_source_rect_for_house(house_id: String) -> Rect2:
	return CUSTOM_ROOM_WALK_MASK_SOURCE_RECTS.get(house_id, Rect2())


func _has_custom_room_scene() -> bool:
	return custom_room_texture != null


func _has_room_walk_mask() -> bool:
	return custom_room_walk_mask_image != null


func _current_room_base_texture() -> Texture2D:
	if custom_room_texture != null:
		return custom_room_texture
	if _is_exchange_scene():
		return stock_exchange_interior
	return null


func _room_frame_rect() -> Rect2:
	if _is_exchange_scene():
		return STOCK_EXCHANGE_FRAME_RECT
	return CUSTOM_ROOM_FRAME_RECT


func _room_walk_mask_dest_rect() -> Rect2:
	var base_texture := _current_room_base_texture()
	var source_rect := _custom_room_walk_mask_source_rect_for_house(_scene_house_id())
	if base_texture == null or source_rect.size.x <= 0.0 or source_rect.size.y <= 0.0:
		return _room_frame_rect()
	var frame_rect := _room_frame_rect()
	var scale_x := frame_rect.size.x / float(base_texture.get_width())
	var scale_y := frame_rect.size.y / float(base_texture.get_height())
	return Rect2(
		frame_rect.position + Vector2(source_rect.position.x * scale_x, source_rect.position.y * scale_y),
		Vector2(source_rect.size.x * scale_x, source_rect.size.y * scale_y)
	)


func _clamp_to_room_bounds(pos: Vector2) -> Vector2:
	if _has_room_walk_mask():
		var frame_rect := _room_walk_mask_dest_rect().grow(-2.0)
		return Vector2(
			clampf(pos.x, frame_rect.position.x, frame_rect.end.x),
			clampf(pos.y, frame_rect.position.y, frame_rect.end.y)
		)
	return Vector2(
		clampf(pos.x, WALK_RECT.position.x, WALK_RECT.end.x),
		clampf(pos.y, WALK_RECT.position.y, WALK_RECT.end.y)
	)


func _spawn_position_for_room(pos: Vector2) -> Vector2:
	var clamped := _clamp_to_room_bounds(pos)
	if not _has_room_walk_mask():
		return clamped
	return _snap_to_room_walk_mask(clamped)


func _resolve_room_motion(current: Vector2, desired: Vector2) -> Vector2:
	var clamped_desired := _clamp_to_room_bounds(desired)
	if not _has_room_walk_mask():
		return clamped_desired
	for candidate in [
		clamped_desired,
		_clamp_to_room_bounds(Vector2(clamped_desired.x, current.y)),
		_clamp_to_room_bounds(Vector2(current.x, clamped_desired.y))
	]:
		if _is_point_on_room_walk_mask(candidate):
			return candidate
	if _is_point_on_room_walk_mask(current):
		return current
	return _snap_to_room_walk_mask(current)


func _is_point_on_room_walk_mask(pos: Vector2) -> bool:
	if custom_room_walk_mask_image == null:
		return false
	var frame_rect := _room_walk_mask_dest_rect()
	if not frame_rect.has_point(pos):
		return false
	var uv := Vector2(
		(pos.x - frame_rect.position.x) / frame_rect.size.x,
		(pos.y - frame_rect.position.y) / frame_rect.size.y
	)
	var px := int(clampf(roundf(uv.x * float(custom_room_walk_mask_image.get_width() - 1)), 0.0, float(custom_room_walk_mask_image.get_width() - 1)))
	var py := int(clampf(roundf(uv.y * float(custom_room_walk_mask_image.get_height() - 1)), 0.0, float(custom_room_walk_mask_image.get_height() - 1)))
	return custom_room_walk_mask_image.get_pixel(px, py).a >= ROOM_WALK_MASK_ALPHA_THRESHOLD


func _snap_to_room_walk_mask(pos: Vector2) -> Vector2:
	var clamped := _clamp_to_room_bounds(pos)
	if not _has_room_walk_mask():
		return clamped
	if _is_point_on_room_walk_mask(clamped):
		return clamped
	var best_point := clamped
	var best_distance := INF
	var frame_rect := _room_walk_mask_dest_rect().grow(-2.0)
	var max_radius := int(maxf(frame_rect.size.x, frame_rect.size.y))
	for radius in range(12, max_radius + 1, 12):
		var sample_count := 16 if radius <= 96 else 28
		for index in range(sample_count):
			var angle := TAU * float(index) / float(sample_count)
			var sample := clamped + Vector2(cos(angle), sin(angle)) * float(radius)
			sample = _clamp_to_room_bounds(sample)
			if not _is_point_on_room_walk_mask(sample):
				continue
			var distance := pos.distance_squared_to(sample)
			if distance < best_distance:
				best_distance = distance
				best_point = sample
		if best_distance < INF:
			return best_point
	var fallback_best := clamped
	var fallback_distance := INF
	for step_y in range(0, 96):
		var y := frame_rect.position.y + frame_rect.size.y * float(step_y) / 95.0
		for step_x in range(0, 140):
			var x := frame_rect.position.x + frame_rect.size.x * float(step_x) / 139.0
			var sample := Vector2(x, y)
			if not _is_point_on_room_walk_mask(sample):
				continue
			var distance := pos.distance_squared_to(sample)
			if distance < fallback_distance:
				fallback_distance = distance
				fallback_best = sample
	return fallback_best


func _spawn_interactable_rows(items: Array) -> void:
	for item in items:
		var node := InteractableView.new()
		node.configure(item)
		var position := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
		if _has_room_walk_mask() and not _is_point_on_room_walk_mask(position):
			var snapped_position := _snap_to_room_walk_mask(position)
			if position.distance_to(snapped_position) <= 180.0:
				position = snapped_position
		node.position = position
		interactable_layer.add_child(node)
		interactables.append(node)


func _custom_room_interactables() -> Array:
	var district := get_current_district()
	match _scene_house_id():
		"news_center_1":
			return [
				{"id":"news_desk","kind":"desk","title":"新闻工位","district":district,"subtitle":"查看稿件、热线和今日头条。","x":870.0,"y":356.0},
				{"id":"news_board","kind":"info","title":"线报墙","district":district,"subtitle":"翻看城里最新的风声和舆论热点。","x":1022.0,"y":520.0},
				{"id":"archive_shelf","kind":"storage","title":"档案柜","district":district,"subtitle":"旧报纸、照片和剪报都压在这里。","x":316.0,"y":360.0},
				{"id":"exit_house","kind":"exit_house","title":"前门","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
		"factory_2", "factory_house":
			return [
				{"id":"assembly_line","kind":"work","title":"装配线","district":district,"subtitle":"盯住机械臂和传送带，继续干活。","x":846.0,"y":584.0},
				{"id":"control_console","kind":"desk","title":"控制台","district":district,"subtitle":"翻看工位记录、故障表和排班。","x":1054.0,"y":350.0},
				{"id":"parts_rack","kind":"storage","title":"备件架","district":district,"subtitle":"零件、工具和半成品都堆在这儿。","x":286.0,"y":620.0},
				{"id":"exit_house","kind":"exit_house","title":"厂门","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
		"food_market_3", "food_market_4":
			return [
				{"id":"market_counter","kind":"goods","title":"货摊柜台","district":district,"subtitle":"看货、问价，顺手做一笔买卖。","x":840.0,"y":468.0},
				{"id":"cold_storage","kind":"storage","title":"后仓货架","district":district,"subtitle":"翻看今天剩下的存货和补货单。","x":320.0,"y":584.0},
				{"id":"market_ledger","kind":"desk","title":"记账台","district":district,"subtitle":"价签、欠条和流水都在这张台面上。","x":1056.0,"y":320.0},
				{"id":"exit_house","kind":"exit_house","title":"铺门","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
		"bookstore_5":
			return [
				{"id":"bookshelf","kind":"info","title":"书架","district":district,"subtitle":"翻翻旧书、传闻和夹在页里的纸条。","x":316.0,"y":360.0},
				{"id":"front_counter","kind":"desk","title":"柜台","district":district,"subtitle":"问书、问路，也能顺手打听人。","x":920.0,"y":540.0},
				{"id":"notice_shelf","kind":"tasks","title":"店内告示","district":district,"subtitle":"看看订书委托和临时活。","x":1086.0,"y":322.0},
				{"id":"exit_house","kind":"exit_house","title":"店门","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
		"stock_exchange_6":
			return [
				{"id":"trading_floor","kind":"stocks","title":"交易席","district":district,"subtitle":"盯住股票报价和盘口变化。","x":700.0,"y":452.0},
				{"id":"intel_terminal","kind":"info","title":"信息终端","district":district,"subtitle":"打听政策风向、席位耳语和市场消息。","x":1064.0,"y":186.0},
				{"id":"broker_desk","kind":"desk","title":"经纪人办公桌","district":district,"subtitle":"翻看委托、成交和你的资金记录。","x":546.0,"y":476.0},
				{"id":"vault","kind":"storage","title":"保密金库","district":district,"subtitle":"封存文件、筹码和贵重物都在这里。","x":424.0,"y":704.0},
				{"id":"exit_house","kind":"exit_house","title":"正门","district":district,"subtitle":"回到街上。","x":678.0,"y":744.0},
			]
		"capitalist_mansion_7":
			return [
				{"id":"drawing_room","kind":"tasks","title":"会客桌","district":district,"subtitle":"看看请帖、邀约和家族安排。","x":770.0,"y":510.0},
				{"id":"study_desk","kind":"desk","title":"书房桌","district":district,"subtitle":"账册、信件和投资计划都摊在这里。","x":988.0,"y":322.0},
				{"id":"safe_room","kind":"storage","title":"保险柜","district":district,"subtitle":"贵重文件和现金都锁在里面。","x":318.0,"y":356.0},
				{"id":"exit_house","kind":"exit_house","title":"侧门","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
		"bar_8":
			return [
				{"id":"bar_counter","kind":"goods","title":"吧台","district":district,"subtitle":"点酒、问价，顺便听点风声。","x":840.0,"y":468.0},
				{"id":"bar_gossip","kind":"info","title":"酒客耳语","district":district,"subtitle":"角落里总有人愿意低声交换消息。","x":320.0,"y":360.0},
				{"id":"bar_backroom","kind":"desk","title":"角落账桌","district":district,"subtitle":"老板把流水、赊账和名单都记在这里。","x":1082.0,"y":650.0},
				{"id":"exit_house","kind":"exit_house","title":"酒吧门口","district":district,"subtitle":"回到街上。","x":664.0,"y":742.0},
			]
	return []


func _rebuild_interactables() -> void:
	for node in interactables:
		if is_instance_valid(node):
			node.queue_free()
	interactables.clear()

	if _is_exchange_scene():
		_spawn_interactable_rows([
			{"id":"trading_floor","kind":"stocks","title":"交易席","district":get_current_district(),"subtitle":"盯住三支股票的盘口、涨跌与个人持仓。","x":456.0,"y":544.0},
			{"id":"intel_terminal","kind":"info","title":"信息终端","district":get_current_district(),"subtitle":"查看市场风向、政策耳语和交易室里的流言。","x":1036.0,"y":238.0},
			{"id":"broker_desk","kind":"desk","title":"经纪人办公桌","district":get_current_district(),"subtitle":"翻看委托、回执和你的资金记录。","x":314.0,"y":586.0},
			{"id":"vault","kind":"storage","title":"保密金库","district":get_current_district(),"subtitle":"封存凭证、密码函和不能见光的材料。","x":180.0,"y":708.0},
			{"id":"briefing_table","kind":"tasks","title":"晨会长桌","district":get_current_district(),"subtitle":"经纪行的临时委托、悬赏和会议纪要。","x":760.0,"y":646.0},
			{"id":"exit_house","kind":"exit_house","title":"正门","district":get_current_district(),"subtitle":"回到交易所大楼门前。","x":1078.0,"y":724.0},
		])
		return

	var custom_items := _custom_room_interactables()
	if _has_custom_room_scene() and not custom_items.is_empty():
		_spawn_interactable_rows(custom_items)
		return

	var items := [
		{"id":"bed","kind":"bed","title":str(house_layout.get("bed_title", "木床")),"district":get_current_district(),"subtitle":str(house_layout.get("bed_subtitle", "躺一会，顺着屋里的热气缓缓神。")),"x":float(house_layout.get("bed_x", 282.0)),"y":float(house_layout.get("bed_y", 256.0))},
		{"id":"kitchen","kind":"kitchen","title":str(house_layout.get("kitchen_title", "灶台")),"district":get_current_district(),"subtitle":str(house_layout.get("kitchen_subtitle", "锅还温着，正好再热一顿饭。")),"x":float(house_layout.get("kitchen_x", 1000.0)),"y":float(house_layout.get("kitchen_y", 256.0))},
		{"id":"storage","kind":"storage","title":str(house_layout.get("storage_title", "储物箱")),"district":get_current_district(),"subtitle":str(house_layout.get("storage_subtitle", "翻找留给明天的旧货和备粮。")),"x":float(house_layout.get("storage_x", 954.0)),"y":float(house_layout.get("storage_y", 608.0))},
		{"id":"desk","kind":"desk","title":str(house_layout.get("desk_title", "账桌")),"district":get_current_district(),"subtitle":str(house_layout.get("desk_subtitle", "把价格、账目和风声重新理顺。")),"x":float(house_layout.get("desk_x", 628.0)),"y":float(house_layout.get("desk_y", 360.0))},
		{"id":"exit_house","kind":"exit_house","title":"门口","district":get_current_district(),"subtitle":"把门带上，回到街上继续讨生活。","x":float(house_layout.get("entry_x", 664.0)),"y":float(house_layout.get("entry_y", 746.0))}
	]
	_spawn_interactable_rows(items)


func _update_current_interactable() -> void:
	var nearest: InteractableView = null
	var best_distance := 99999.0
	for node in interactables:
		var distance := room_player.position.distance_to(node.position)
		var interaction_radius := _interaction_radius_for_node(node)
		if distance < interaction_radius and distance < best_distance:
			best_distance = distance
			nearest = node
	for node in interactables:
		node.set_highlighted(node == nearest)
	current_interactable = nearest


func _interaction_radius_for_node(node: InteractableView) -> float:
	if node == null:
		return 88.0
	if node.kind == "exit_house":
		if _is_exchange_scene():
			return 160.0
		return 112.0
	if _is_exchange_scene():
		match node.kind:
			"stocks":
				return 118.0
			"tasks":
				return 102.0
			_:
				return 94.0
	return 88.0


func _draw() -> void:
	if _is_exchange_scene():
		_draw_stock_exchange_scene()
		return
	if _has_custom_room_scene():
		_draw_custom_room_scene()
		return
	draw_rect(ROOM_RECT, house_theme.get("void", Color("1c130d")), true)
	_draw_floor()
	_draw_walls()
	_draw_windows()
	_draw_structural_shell()
	_draw_rug()
	_draw_bed()
	_draw_hearth()
	_draw_desk()
	_draw_storage()
	_draw_wall_shelves()
	_draw_partition()
	_draw_lived_in_props()
	_draw_calcium_room_set()
	_draw_woodshop_set()
	_draw_activity_scene()
	_draw_settle_props()
	_draw_morning_traces()
	_draw_morning_activity_hints()
	_draw_wall_lights()
	_draw_doorway()
	_draw_light_pools()
	_draw_resident_presence()


func _draw_custom_room_scene() -> void:
	draw_rect(ROOM_RECT, Color("0f1014"), true)
	var frame_rect := CUSTOM_ROOM_FRAME_RECT
	draw_rect(frame_rect.grow(8.0), Color(0, 0, 0, 0.28), true)
	draw_rect(frame_rect, Color("181a20"), true)
	if custom_room_texture != null:
		_draw_scaled_texture(custom_room_texture, frame_rect, Color(1, 1, 1, 0.98))
	else:
		draw_rect(frame_rect, Color("2d2f36"), true)
	draw_rect(frame_rect, Color(1, 1, 1, 0.04), false, 3.0)
	draw_rect(Rect2(56, 810, 1208, 30), Color(0, 0, 0, 0.26), true)


func _draw_stock_exchange_scene() -> void:
	draw_rect(ROOM_RECT, Color("0f1218"), true)
	var frame_rect := STOCK_EXCHANGE_FRAME_RECT
	draw_rect(frame_rect, Color("10151d"), true)
	var base_texture := custom_room_texture if custom_room_texture != null else stock_exchange_interior
	if base_texture != null:
		_draw_scaled_texture(base_texture, frame_rect, Color(1, 1, 1, 0.98))
	else:
		draw_rect(frame_rect, Color("2b3442"), true)
		draw_rect(Rect2(120, 118, 1080, 220), Color("415269"), true)
		draw_rect(Rect2(120, 350, 1080, 392), Color("273240"), true)
	draw_rect(frame_rect, Color(0, 0, 0, 0.18), false, 6.0)
	draw_rect(Rect2(54, 84, 1212, 76), Color(0.03, 0.04, 0.06, 0.44), true)
	draw_rect(Rect2(54, 740, 1212, 64), Color(0.03, 0.04, 0.06, 0.48), true)
	draw_rect(Rect2(0, 0, ROOM_RECT.size.x, 86), Color("0b0e13"), true)
	draw_rect(Rect2(138, 776, 912, 40), Color("1f232b"), true)
	draw_rect(Rect2(156, 786, 876, 18), Color(1, 1, 1, 0.08), true)
	draw_rect(Rect2(572, 732, 212, 58), Color("233041"), true)
	draw_rect(Rect2(594, 744, 168, 10), Color(0.66, 0.8, 0.95, 0.55), true)
	draw_rect(Rect2(594, 760, 168, 12), Color(0, 0, 0, 0.2), true)
	draw_line(Vector2(678, 728), Vector2(678, 812), Color(1, 1, 1, 0.15), 2.0)
	draw_rect(Rect2(112, 96, 320, 34), Color("11161d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(132, 121), "证券交易所内厅", HORIZONTAL_ALIGNMENT_LEFT, 260, 26, Color("f4e3bd"))
	draw_string(ThemeDB.fallback_font, Vector2(772, 121), "走势图 / 主力席位 / 影子盘", HORIZONTAL_ALIGNMENT_LEFT, 420, 20, Color("d7cdb6"))

	var chart_rect := Rect2(110, 156, 676, 368)
	draw_rect(chart_rect, Color(0.05, 0.08, 0.1, 0.78), true)
	draw_rect(chart_rect, Color(0.8, 0.72, 0.48, 0.24), false, 2.0)
	for step in range(1, 5):
		var y := chart_rect.position.y + chart_rect.size.y * step / 5.0
		draw_line(Vector2(chart_rect.position.x + 18, y), Vector2(chart_rect.end.x - 18, y), Color(1, 1, 1, 0.06), 1.0)
	for step in range(1, 6):
		var x := chart_rect.position.x + chart_rect.size.x * step / 6.0
		draw_line(Vector2(x, chart_rect.position.y + 18), Vector2(x, chart_rect.end.y - 18), Color(1, 1, 1, 0.04), 1.0)
	draw_string(ThemeDB.fallback_font, chart_rect.position + Vector2(18, 20), "REAL MARKET TAPE", HORIZONTAL_ALIGNMENT_LEFT, 220, 18, Color("f0dfbe"))
	_draw_exchange_price_charts(chart_rect)

	var board_rect := Rect2(812, 156, 324, 182)
	draw_rect(board_rect, Color(0.05, 0.08, 0.1, 0.76), true)
	draw_rect(board_rect, Color(0.75, 0.66, 0.42, 0.38), false, 2.0)
	draw_string(ThemeDB.fallback_font, board_rect.position + Vector2(12, 18), "LIVE BOARD", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("f0dfbe"))
	var board_rows: Array = exchange_hud_state.get("stocks", [])
	for index in range(min(3, board_rows.size())):
		var stock: Dictionary = board_rows[index]
		var change_pct := float(stock.get("change_pct", 0.0)) * 100.0
		var row_color := _stock_color(change_pct)
		var row_text := "%s  %s  %+0.2f%%" % [str(stock.get("ticker", stock.get("name", ""))), int(stock.get("current_price", 0)), change_pct]
		draw_string(ThemeDB.fallback_font, board_rect.position + Vector2(12, 42 + index * 28), row_text, HORIZONTAL_ALIGNMENT_LEFT, 296, 16, row_color)
		var holder_name := "暂无大户"
		var holders: Array = stock.get("major_holders", [])
		if not holders.is_empty():
			holder_name = str(holders[0].get("holder_name", "暂无大户"))
		draw_string(ThemeDB.fallback_font, board_rect.position + Vector2(12, 58 + index * 28), holder_name, HORIZONTAL_ALIGNMENT_LEFT, 296, 13, Color("c7bca0"))
	var board_status := "MARKET OPEN" if bool(exchange_hud_state.get("market_open", true)) else "MARKET CLOSED"
	draw_string(ThemeDB.fallback_font, board_rect.position + Vector2(12, 154), board_status, HORIZONTAL_ALIGNMENT_LEFT, 170, 15, Color("d7cdb6"))
	draw_string(ThemeDB.fallback_font, board_rect.position + Vector2(184, 154), str(exchange_hud_state.get("clock_label", current_clock_label)), HORIZONTAL_ALIGNMENT_LEFT, 120, 15, Color("d7cdb6"))

	var account_rect := Rect2(812, 352, 324, 170)
	draw_rect(account_rect, Color(0.06, 0.07, 0.1, 0.76), true)
	draw_rect(account_rect, Color(0.34, 0.65, 0.92, 0.32), false, 2.0)
	_draw_exchange_metrics_block(account_rect)

	var tape_rect := Rect2(110, 548, 1026, 154)
	draw_rect(tape_rect, Color(0.04, 0.05, 0.08, 0.8), true)
	draw_rect(tape_rect, Color(0.75, 0.66, 0.42, 0.2), false, 2.0)
	draw_string(ThemeDB.fallback_font, tape_rect.position + Vector2(16, 20), "最近成交与风险预警", HORIZONTAL_ALIGNMENT_LEFT, 220, 18, Color("f0dfbe"))
	_draw_exchange_tape_block(tape_rect)


func _stock_color(change_pct: float) -> Color:
	if change_pct > 0.01:
		return Color("d96d52")
	if change_pct < -0.01:
		return Color("74b58a")
	return Color("d8b982")


func _draw_exchange_price_charts(chart_rect: Rect2) -> void:
	var stocks: Array = exchange_hud_state.get("stocks", [])
	if stocks.is_empty():
		draw_string(ThemeDB.fallback_font, chart_rect.position + Vector2(24, 56), "暂无真实盘口数据", HORIZONTAL_ALIGNMENT_LEFT, 220, 18, Color("d7cdb6"))
		return
	var legend_y := chart_rect.position.y + 36.0
	var palette: Array[Color] = [Color("d96d52"), Color("6fb4e8"), Color("8fd08f")]
	for index in range(min(3, stocks.size())):
		var stock: Dictionary = stocks[index]
		var series: Array = stock.get("history", [])
		var color: Color = palette[index]
		var label := "%s %s" % [str(stock.get("ticker", "")), str(stock.get("display_name", stock.get("name", "")))]
		draw_rect(Rect2(chart_rect.position.x + 22 + index * 214, legend_y - 10, 12, 12), color, true)
		draw_string(ThemeDB.fallback_font, Vector2(chart_rect.position.x + 40 + index * 214, legend_y), label, HORIZONTAL_ALIGNMENT_LEFT, 190, 14, Color("e8dfc8"))
		if series.size() < 2:
			continue
		var plot_rect: Rect2 = chart_rect.grow(-26)
		plot_rect.position.y += 34
		plot_rect.size.y -= 48
		var min_price: float = float(series[0])
		var max_price: float = float(series[0])
		for value in series:
			min_price = min(min_price, float(value))
			max_price = max(max_price, float(value))
		var spread: float = max(1.0, max_price - min_price)
		var points: PackedVector2Array = PackedVector2Array()
		for point_index in range(series.size()):
			var x_ratio: float = float(point_index) / max(1.0, float(series.size() - 1))
			var y_ratio: float = (float(series[point_index]) - min_price) / spread
			points.append(Vector2(
				plot_rect.position.x + x_ratio * plot_rect.size.x,
				plot_rect.end.y - y_ratio * plot_rect.size.y
			))
		if points.size() >= 2:
			draw_polyline(points, color, 3.0, true)
			draw_circle(points[points.size() - 1], 4.0, color)
		var change_pct := float(stock.get("change_pct", 0.0)) * 100.0
		var stat := "%s  %+0.2f%%" % [int(stock.get("current_price", 0)), change_pct]
		draw_string(ThemeDB.fallback_font, Vector2(chart_rect.end.x - 182, chart_rect.position.y + 28 + index * 18), stat, HORIZONTAL_ALIGNMENT_LEFT, 160, 14, color)


func _draw_exchange_metrics_block(block_rect: Rect2) -> void:
	var account_tier: Dictionary = exchange_hud_state.get("account_tier", {})
	var reputation: Dictionary = exchange_hud_state.get("reputation", {})
	var shadow: Dictionary = exchange_hud_state.get("shadow_reputation", {})
	var lines := [
		"账户等级 %s / %s" % [str(account_tier.get("label", "青铜级")), str(account_tier.get("leverage", "1x-10x"))],
		"现金 %s  持仓 %s" % [int(exchange_hud_state.get("player_cash", 0)), int(exchange_hud_state.get("player_holdings_value", 0))],
		"总资产 %s" % int(exchange_hud_state.get("player_total_wealth", 0)),
		"革命税 %s / 总抽成 %s" % [int(exchange_hud_state.get("player_trading_fees", 0)), int(exchange_hud_state.get("sam_tax_total", 0))],
		"FC %s  FB %s  SN %s" % [int(reputation.get("FC", 10)), int(reputation.get("FB", 5)), int(reputation.get("SN", 20))],
		"SUI %s  ST %s  WL %s" % [shadow.get("SUI", 15), shadow.get("ST", 1.0), int(shadow.get("WL", 1))],
		"警局 %s" % str(shadow.get("police_side", "摇摆观望")),
		"风险 %s" % str(exchange_hud_state.get("market_risk", "缄默期")),
	]
	for index in range(lines.size()):
		draw_string(ThemeDB.fallback_font, block_rect.position + Vector2(14, 22 + index * 18), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 298, 15, Color("ddd4bf"))


func _draw_exchange_tape_block(tape_rect: Rect2) -> void:
	var tape: Array = exchange_hud_state.get("tape", [])
	var warnings: Array = exchange_hud_state.get("warnings", [])
	var line_y := tape_rect.position.y + 46.0
	for row in tape.slice(0, min(4, tape.size())):
		var text := str(row.get("anonymous_label", "刚才还没有新的成交。"))
		draw_string(ThemeDB.fallback_font, Vector2(tape_rect.position.x + 18, line_y), text, HORIZONTAL_ALIGNMENT_LEFT, 620, 15, Color("d7cdb6"))
		line_y += 18.0
	if tape.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(tape_rect.position.x + 18, line_y), "刚才还没有新的成交。", HORIZONTAL_ALIGNMENT_LEFT, 420, 15, Color("d7cdb6"))
	var warning_y := tape_rect.position.y + 46.0
	for warning in warnings.slice(0, min(3, warnings.size())):
		draw_string(ThemeDB.fallback_font, Vector2(tape_rect.position.x + 650, warning_y), str(warning), HORIZONTAL_ALIGNMENT_LEFT, 350, 15, Color("dfb96d"))
		warning_y += 18.0

func _draw_floor() -> void:
	draw_rect(Rect2(76, 120, 1168, 696), house_theme.get("floor", Color("5c432d")), true)
	_draw_scaled_texture(ROOM_TEXTURE, Rect2(84, 122, 1152, 692), Color(1, 1, 1, 0.18))
	for x in range(76, 1244, 40):
		draw_line(Vector2(x, 120), Vector2(x, 816), Color(0, 0, 0, 0.08), 1.0)
	for y in range(120, 816, 30):
		draw_line(Vector2(76, y), Vector2(1244, y), Color(1, 1, 1, 0.03), 1.0)
	for offset in range(0, 18):
		var x0 := 92 + offset * 64
		var plank := PackedVector2Array([
			Vector2(x0, 132),
			Vector2(x0 + 46, 126),
			Vector2(x0 + 56, 790),
			Vector2(x0 + 6, 804)
		])
		draw_colored_polygon(plank, house_theme.get("plank_overlay", Color(0.43, 0.3, 0.2, 0.09)))


func _draw_walls() -> void:
	draw_rect(Rect2(56, 76, 1208, 56), house_theme.get("wall_top", Color("725238")), true)
	draw_rect(Rect2(56, 132, 26, 684), house_theme.get("wall_side", Color("6a4a32")), true)
	draw_rect(Rect2(1238, 132, 26, 684), house_theme.get("wall_side", Color("6a4a32")), true)
	draw_rect(Rect2(56, 816, 1208, 32), house_theme.get("wall_bottom", Color("473121")), true)
	for x in [90, 338, 586, 834, 1082]:
		draw_rect(Rect2(x, 110, 20, 706), house_theme.get("post", Color("825f43")), true)
		draw_rect(Rect2(x + 4, 110, 4, 706), Color(1, 1, 1, 0.08), true)
	for x in range(118, 1210, 96):
		draw_rect(Rect2(x, 90, 48, 22), house_theme.get("trim", Color("8f6a48")), true)
	for y in [176.0, 442.0]:
		draw_rect(Rect2(104, y, 1120, 10), house_theme.get("beam", Color("442d1d")), true)
		for x in range(120, 1188, 112):
			draw_rect(Rect2(x, y - 6, 12, 24), house_theme.get("beam", Color("442d1d")).lightened(0.08), true)
	if bool(house_layout.get("patched_walls", false)):
		draw_rect(Rect2(210, 232, 96, 54), house_theme.get("cloth", Color("8d5f4a")), true)
		draw_rect(Rect2(214, 236, 88, 46), Color(0, 0, 0, 0.08), false, 2.0)
		draw_rect(Rect2(1018, 212, 82, 42), Color("6c4b35"), true)
		draw_line(Vector2(1020, 212), Vector2(1098, 252), Color("b58a61"), 2.0)


func _draw_windows() -> void:
	var glow := _window_glow()
	var departure_glow: float = _doorstep_transition_strength()
	for rect in house_layout.get("windows", [Rect2(132, 128, 108, 86), Rect2(1080, 128, 108, 86)]):
		draw_rect(rect, Color("7b5738"), true)
		draw_rect(rect.grow(-8), house_theme.get("window_frame", Color("20303a")), true)
		draw_rect(rect.grow(-18), Color(0.18, 0.22, 0.26, 0.85), true)
		draw_rect(rect.grow(-18), Color(1.0, 0.84, 0.54, glow), true)
		if departure_glow > 0.04:
			draw_rect(Rect2(rect.position + Vector2(18, 18), Vector2(rect.size.x - 36.0, 8.0)), Color(1.0, 0.92, 0.68, departure_glow * 0.24), true)
			draw_colored_polygon(PackedVector2Array([
				rect.position + Vector2(rect.size.x * 0.26, rect.size.y - 6.0),
				rect.position + Vector2(rect.size.x * 0.5, rect.size.y + 30.0),
				rect.position + Vector2(rect.size.x * 0.74, rect.size.y - 6.0),
			]), Color(1.0, 0.9, 0.62, departure_glow * 0.12))
		draw_line(rect.position + Vector2(rect.size.x * 0.5, 8), rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 8), Color("7b5738"), 3.0)
		draw_line(rect.position + Vector2(8, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 8, rect.size.y * 0.5), Color("7b5738"), 3.0)
		if bool(house_layout.get("curtains", false)):
			draw_rect(Rect2(rect.position + Vector2(12, 12), Vector2(22, rect.size.y - 24)), house_theme.get("accent", Color("8f2f33")).darkened(0.1), true)
			draw_rect(Rect2(rect.position + Vector2(rect.size.x - 34, 12), Vector2(22, rect.size.y - 24)), house_theme.get("accent", Color("8f2f33")).darkened(0.1), true)


func _draw_structural_shell() -> void:
	match str(house_data.get("id", "")):
		"dock_house":
			_draw_dock_shell()
		"factory_house":
			_draw_factory_shell()
		"exchange_house":
			_draw_exchange_shell()
		_:
			_draw_slum_shell()


func _draw_slum_shell() -> void:
	var divider := PackedVector2Array([
		Vector2(304, 226),
		Vector2(438, 204),
		Vector2(536, 318),
		Vector2(418, 360),
		Vector2(286, 326)
	])
	draw_colored_polygon(divider, Color(0.34, 0.22, 0.16, 0.46))
	draw_polyline(PackedVector2Array([divider[0], divider[1], divider[2], divider[3], divider[4], divider[0]]), Color(0.78, 0.63, 0.44, 0.42), 2.0)
	for patch in [
		Rect2(314, 238, 56, 18),
		Rect2(404, 226, 68, 20),
		Rect2(360, 292, 82, 18)
	]:
		draw_rect(patch, house_theme.get("cloth", Color("8c604a")).lightened(0.08), true)
		draw_rect(patch.grow(-4), Color(0, 0, 0, 0.08), false, 1.0)
	var lean_to := PackedVector2Array([
		Vector2(120, 178),
		Vector2(284, 154),
		Vector2(318, 256),
		Vector2(136, 278)
	])
	draw_colored_polygon(lean_to, Color(0.22, 0.16, 0.12, 0.24))
	for plank in [
		Rect2(122, 646, 182, 18),
		Rect2(152, 678, 214, 20),
		Rect2(212, 714, 146, 18)
	]:
		draw_rect(plank, Color("715338"), true)
		draw_line(plank.position + Vector2(8, 0), plank.position + Vector2(plank.size.x - 8, 0), Color(1, 1, 1, 0.05), 1.0)
	draw_rect(Rect2(742, 172, 24, 488), Color("4a2f1c"), true)
	draw_rect(Rect2(764, 198, 120, 28), Color("7f6452"), true)
	draw_rect(Rect2(764, 228, 120, 120), Color(0.3, 0.19, 0.14, 0.32), true)


func _draw_dock_shell() -> void:
	for stain in [
		Rect2(120, 138, 84, 220),
		Rect2(1018, 150, 96, 244),
		Rect2(1104, 188, 62, 182)
	]:
		draw_rect(stain, Color(0.16, 0.3, 0.38, 0.16), true)
	for rail_y in [196.0, 286.0]:
		draw_rect(Rect2(176, rail_y, 220, 12), Color("4d3a2a"), true)
		for x in [198.0, 252.0, 308.0, 364.0]:
			draw_rect(Rect2(x, rail_y + 10, 16, 68), Color("6c533b"), true)
	for rack in [
		Rect2(182, 214, 196, 20),
		Rect2(182, 306, 196, 20),
		Rect2(878, 210, 226, 22),
		Rect2(878, 304, 226, 22)
	]:
		draw_rect(rack, Color("6d5238"), true)
		draw_rect(Rect2(rack.position + Vector2(8, 6), Vector2(rack.size.x - 16, 8)), Color(1, 1, 1, 0.05), true)
	for x in [892.0, 956.0, 1020.0, 1084.0]:
		draw_rect(Rect2(x, 326, 18, 164), Color("533b29"), true)
	draw_rect(Rect2(470, 192, 286, 434), Color(0.12, 0.09, 0.07, 0.12), false, 3.0)
	for y in [224.0, 610.0]:
		draw_line(Vector2(504, y), Vector2(722, y), Color(1, 1, 1, 0.06), 2.0)


func _draw_factory_shell() -> void:
	var frame_color := Color("5f5f66")
	for rect in [
		Rect2(146, 186, 266, 18),
		Rect2(146, 474, 266, 18),
		Rect2(846, 182, 266, 18),
		Rect2(846, 480, 266, 18)
	]:
		draw_rect(rect, frame_color, true)
	for x in [158.0, 214.0, 270.0, 326.0, 382.0, 858.0, 918.0, 978.0, 1038.0, 1098.0]:
		draw_rect(Rect2(x, 198, 12, 286), frame_color.darkened(0.08), true)
	for plate in [
		Rect2(136, 650, 314, 96),
		Rect2(812, 648, 332, 102)
	]:
		draw_rect(plate, Color("49433f"), true)
		for y in [18.0, 46.0, 74.0]:
			draw_line(plate.position + Vector2(14, y), plate.position + Vector2(plate.size.x - 14, y), Color(1, 1, 1, 0.05), 1.0)
	draw_line(Vector2(182, 168), Vector2(1096, 168), Color("3e3430"), 6.0)
	for chain_x in [330.0, 632.0, 948.0]:
		draw_line(Vector2(chain_x, 168), Vector2(chain_x, 222), Color("6a645e"), 2.0)
		draw_rect(Rect2(chain_x - 8, 222, 16, 18), Color("7d756b"), true)


func _draw_exchange_shell() -> void:
	for panel in [
		Rect2(220, 202, 124, 182),
		Rect2(346, 184, 120, 202),
		Rect2(826, 210, 110, 186)
	]:
		draw_rect(panel, house_theme.get("accent", Color("6a4f88")).darkened(0.16), true)
		draw_rect(panel.grow(-8), Color(0.92, 0.86, 0.7, 0.08), false, 2.0)
		for stripe in [24.0, 52.0, 80.0, 108.0, 136.0]:
			draw_line(panel.position + Vector2(12, stripe), panel.position + Vector2(panel.size.x - 12, stripe), Color(1, 1, 1, 0.06), 1.0)
	draw_rect(Rect2(530, 168, 188, 74), Color("694d34"), true)
	draw_rect(Rect2(542, 180, 164, 48), Color("806042"), true)
	for y in [188.0, 202.0, 216.0]:
		draw_rect(Rect2(560, y, 132, 6), Color("eadcb8"), true)
	draw_rect(Rect2(960, 202, 120, 254), Color("60422b"), true)
	draw_rect(Rect2(976, 220, 88, 220), Color("6e5137"), true)
	for y in [252.0, 314.0, 376.0]:
		draw_rect(Rect2(986, y, 68, 8), Color("d3c29d"), true)


func _draw_rug() -> void:
	var style := str(house_layout.get("rug_style", "patch"))
	match style:
		"runner":
			draw_rect(Rect2(446, 448, 374, 200), house_theme.get("rug", Color("8f3b2e")), true)
			draw_rect(Rect2(454, 456, 358, 184), Color(1, 1, 1, 0.05), false, 3.0)
			for y in [470, 506, 542, 578, 614]:
				draw_line(Vector2(470, y), Vector2(796, y), house_theme.get("rug_trim", Color("f1d79f")), 1.2)
		"merchant":
			var points := PackedVector2Array([
				Vector2(402, 458),
				Vector2(866, 446),
				Vector2(896, 632),
				Vector2(386, 650)
			])
			draw_colored_polygon(points, house_theme.get("rug", Color("5b3f7e")))
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), house_theme.get("rug_trim", Color("f1ddb0")), 3.0)
			draw_rect(Rect2(534, 500, 234, 96), Color(1, 1, 1, 0.05), false, 2.0)
		_:
			var main_rug := PackedVector2Array([
				Vector2(420, 458),
				Vector2(864, 446),
				Vector2(882, 640),
				Vector2(402, 652)
			])
			draw_colored_polygon(main_rug, house_theme.get("rug", Color("8f3b2e")))
			draw_polyline(PackedVector2Array([main_rug[0], main_rug[1], main_rug[2], main_rug[3], main_rug[0]]), house_theme.get("rug_trim", Color("f1d79f")), 3.0)
			for offset in range(6):
				draw_line(Vector2(438, 480 + offset * 26), Vector2(846, 470 + offset * 26), Color(1, 1, 1, 0.08), 1.0)


func _draw_bed() -> void:
	var bed_pos := Vector2(float(house_layout.get("bed_x", 282.0)) - 110.0, float(house_layout.get("bed_y", 256.0)) - 72.0)
	var wood: Color = house_theme.get("wood", Color("6b472b"))
	var bed_style := str(house_layout.get("bed_style", "plain"))
	draw_rect(Rect2(bed_pos, Vector2(220, 120)), wood, true)
	draw_rect(Rect2(bed_pos + Vector2(12, 12), Vector2(196, 92)), Color("d6c6a1"), true)
	draw_rect(Rect2(bed_pos + Vector2(12, 12), Vector2(196, 24)), Color("efe7d2"), true)
	draw_rect(Rect2(bed_pos + Vector2(24, 42), Vector2(96, 56)), house_theme.get("blanket", Color("8f3f35")), true)
	draw_rect(Rect2(bed_pos + Vector2(122, 42), Vector2(72, 56)), house_theme.get("sheet", Color("8d8a74")), true)
	draw_rect(Rect2(bed_pos + Vector2(-10, -8), Vector2(20, 142)), wood.darkened(0.26), true)
	draw_rect(Rect2(bed_pos + Vector2(210, -8), Vector2(20, 142)), wood.darkened(0.26), true)
	draw_rect(Rect2(bed_pos + Vector2(32, -30), Vector2(152, 18)), wood.darkened(0.18), true)
	_draw_pillow_stack(bed_pos + Vector2(34, 22))
	_draw_bedside_stool(bed_pos + Vector2(190, 92))
	if bed_style == "bunk":
		draw_rect(Rect2(bed_pos + Vector2(8, -44), Vector2(204, 16)), wood.darkened(0.15), true)
		draw_rect(Rect2(bed_pos + Vector2(18, -30), Vector2(180, 36)), Color("8e8a78"), true)
		draw_rect(Rect2(bed_pos + Vector2(22, -26), Vector2(92, 16)), house_theme.get("blanket", Color("8f5b45")), true)
		draw_line(bed_pos + Vector2(10, 100), bed_pos + Vector2(10, -28), Color("2c1b12"), 3.0)
		draw_line(bed_pos + Vector2(210, 100), bed_pos + Vector2(210, -28), Color("2c1b12"), 3.0)
	elif bed_style == "merchant":
		draw_rect(Rect2(bed_pos + Vector2(-16, -18), Vector2(252, 18)), house_theme.get("trim", Color("9f7d5a")), true)
		draw_rect(Rect2(bed_pos + Vector2(68, -72), Vector2(84, 42)), house_theme.get("accent", Color("6a4f88")), true)
		draw_line(bed_pos + Vector2(74, -72), bed_pos + Vector2(74, 110), Color("4e3423"), 3.0)
		draw_line(bed_pos + Vector2(146, -72), bed_pos + Vector2(146, 110), Color("4e3423"), 3.0)
	_draw_laundry_basket(Vector2(bed_pos.x + 210, bed_pos.y + 122))


func _draw_hearth() -> void:
	var kitchen_center := Vector2(float(house_layout.get("kitchen_x", 1000.0)), float(house_layout.get("kitchen_y", 256.0)))
	var body_pos := kitchen_center + Vector2(-108, -92)
	draw_rect(Rect2(body_pos, Vector2(216, 136)), house_theme.get("stone", Color("655141")), true)
	draw_rect(Rect2(body_pos + Vector2(20, 16), Vector2(176, 108)), Color("3a2a1d"), true)
	draw_rect(Rect2(body_pos + Vector2(44, 44), Vector2(128, 68)), Color("1d130d"), true)
	var flame_pulse := 0.7 + 0.3 * sin(pulse_time * 4.0)
	var fire_strength := _fire_strength()
	if fire_strength > 0.05:
		draw_circle(kitchen_center + Vector2(0, -4), 24, Color(0.78 + 0.16 * flame_pulse, 0.46, 0.16, 0.9 * fire_strength))
		draw_circle(kitchen_center + Vector2(0, -10), 14, Color(0.98, 0.82, 0.45, 0.86 * fire_strength))
		draw_circle(kitchen_center + Vector2(0, -14), 8, Color(1.0, 0.94, 0.72, 0.82 * fire_strength))
	draw_rect(Rect2(kitchen_center + Vector2(-44, 48), Vector2(90, 42)), house_theme.get("wood", Color("7b5835")), true)
	draw_rect(Rect2(kitchen_center + Vector2(48, 60), Vector2(28, 24)), Color("c7ab7c"), true)
	draw_line(kitchen_center + Vector2(-70, -84), kitchen_center + Vector2(-70, -148), Color("443326"), 10.0)
	draw_line(kitchen_center + Vector2(68, -84), kitchen_center + Vector2(68, -150), Color("443326"), 10.0)
	_draw_cooking_props(kitchen_center + Vector2(-54, 52))
	_draw_breakfast_leftovers(kitchen_center)
	_draw_hanging_herbs(kitchen_center + Vector2(-66, -126))
	_draw_kettle_hook(kitchen_center + Vector2(18, -96))
	_draw_cooking_steam(kitchen_center + Vector2(18, -122), fire_strength)
	if bool(house_layout.get("fish_rack", false)):
		draw_line(kitchen_center + Vector2(120, -34), kitchen_center + Vector2(172, -74), Color("5b4431"), 3.0)
		draw_line(kitchen_center + Vector2(120, -34), kitchen_center + Vector2(184, -22), Color("5b4431"), 3.0)
		for fish_y in [-68.0, -48.0, -28.0]:
			draw_line(kitchen_center + Vector2(146, fish_y), kitchen_center + Vector2(154, fish_y + 16), Color("c3b28a"), 2.0)
	draw_rect(Rect2(kitchen_center + Vector2(-88, 88), Vector2(176, 10)), Color(0, 0, 0, 0.12), true)


func _draw_desk() -> void:
	var desk_center := Vector2(float(house_layout.get("desk_x", 628.0)), float(house_layout.get("desk_y", 360.0)))
	var desk_pos := desk_center + Vector2(-86, -58)
	draw_rect(Rect2(desk_pos + Vector2(0, 18), Vector2(172, 86)), house_theme.get("wood", Color("6f4a2f")), true)
	draw_rect(Rect2(desk_pos + Vector2(14, 4), Vector2(144, 24)), house_theme.get("trim", Color("8d6440")), true)
	draw_rect(Rect2(desk_pos + Vector2(22, -18), Vector2(74, 18)), Color("4c3220"), true)
	draw_rect(Rect2(desk_pos + Vector2(112, -18), Vector2(30, 18)), Color("d8c69d"), true)
	draw_rect(Rect2(desk_pos + Vector2(34, 104), Vector2(16, 108)), Color("4e3423"), true)
	draw_rect(Rect2(desk_pos + Vector2(122, 104), Vector2(16, 108)), Color("4e3423"), true)
	draw_rect(Rect2(desk_pos + Vector2(-44, 58), Vector2(32, 78)), house_theme.get("chair", Color("7b5738")), true)
	draw_rect(Rect2(desk_pos + Vector2(184, 58), Vector2(32, 78)), house_theme.get("chair", Color("7b5738")), true)
	_draw_ledger_set(desk_center + Vector2(22, -34))
	_draw_candle_cluster(desk_center + Vector2(-34, -22))
	if bool(house_layout.get("book_stack", false)):
		_draw_book_stack(desk_center + Vector2(90, -20))
	if bool(house_layout.get("tools_on_desk", false)):
		draw_line(desk_center + Vector2(82, -18), desk_center + Vector2(114, -38), Color("a88b63"), 2.0)
		draw_rect(Rect2(desk_center + Vector2(100, -34), Vector2(16, 8)), Color("6d5c52"), true)
	draw_rect(Rect2(desk_pos + Vector2(26, 30), Vector2(112, 8)), Color(1, 1, 1, 0.06), true)


func _draw_storage() -> void:
	var storage_center := Vector2(float(house_layout.get("storage_x", 954.0)), float(house_layout.get("storage_y", 608.0)))
	var box_pos := storage_center + Vector2(-84, -54)
	draw_rect(Rect2(box_pos, Vector2(164, 108)), house_theme.get("wood_dark", Color("654529")), true)
	draw_rect(Rect2(box_pos + Vector2(18, 18), Vector2(128, 72)), Color("7c5732"), true)
	draw_line(storage_center + Vector2(-64, -8), storage_center + Vector2(64, -8), Color("d9bc86"), 3.0)
	draw_circle(storage_center + Vector2(0, -8), 8, Color("d1aa52"))
	_draw_item_texture(TW_NORMAL_CHEST if str(house_data.get("id", "")) != "exchange_house" else TW_GOLD_CHEST, storage_center + Vector2(-42, -6), 3.0)
	_draw_item_texture(WOOD_CHEST_OPEN, storage_center + Vector2(-4, 44), 3.8)
	_draw_item_texture(WOOD_CHEST_CLOSED, storage_center + Vector2(56, 30), 3.2)
	draw_rect(Rect2(storage_center + Vector2(-98, -88), Vector2(58, 32)), house_theme.get("trim", Color("8e6640")), true)
	draw_rect(Rect2(storage_center + Vector2(78, -48), Vector2(56, 68)), Color("765133"), true)
	draw_rect(Rect2(storage_center + Vector2(146, -48), Vector2(48, 88)), Color("6a482d"), true)
	_draw_cabinet(storage_center + Vector2(176, 28))
	_draw_sack_stack(storage_center + Vector2(-124, 50))
	if bool(house_layout.get("crate_stack", false)):
		draw_rect(Rect2(storage_center + Vector2(-174, -28), Vector2(44, 44)), Color("6f4e31"), true)
		draw_rect(Rect2(storage_center + Vector2(-164, -38), Vector2(34, 18)), Color("85613c"), true)
		_draw_item_texture(CRATE_TEXTURE, storage_center + Vector2(-182, -40), 2.6)
	if bool(house_layout.get("locker", false)):
		draw_rect(Rect2(storage_center + Vector2(208, -82), Vector2(54, 102)), Color("5b5c61"), true)
		draw_rect(Rect2(storage_center + Vector2(214, -74), Vector2(42, 86)), Color("7a7c81"), true)
		draw_circle(storage_center + Vector2(248, -28), 3.0, Color("d2b16d"))
	if str(house_data.get("id", "")) == "exchange_house":
		_draw_item_texture(GOLD_CUP_TEXTURE, storage_center + Vector2(92, -76), 2.6)
		_draw_item_texture(GEM_TEXTURE, storage_center + Vector2(126, -66), 2.2)


func _draw_wall_shelves() -> void:
	for shelf in house_layout.get("shelves", []):
		var shelf_rect: Rect2 = shelf
		draw_rect(shelf_rect, house_theme.get("wood_dark", Color("5d4028")), true)
		_draw_shelf_items(shelf_rect.position + Vector2(8, -18), int((shelf_rect.size.x - 16.0) / 28.0))
	if bool(house_layout.get("bookcase", false)):
		var origin := Vector2(218, 594)
		draw_rect(Rect2(origin + Vector2(-36, -118), Vector2(72, 118)), house_theme.get("wood_dark", Color("5d4028")), true)
		for y in [-92.0, -58.0, -24.0]:
			draw_rect(Rect2(origin + Vector2(-28, y), Vector2(56, 8)), house_theme.get("trim", Color("8e6640")), true)
		_draw_book_stack(origin + Vector2(-18, -98))
		_draw_book_stack(origin + Vector2(-4, -64))
		_draw_book_stack(origin + Vector2(8, -30))


func _draw_partition() -> void:
	if not bool(house_layout.get("partition", false)):
		return
	var origin := Vector2(float(house_layout.get("partition_x", 812.0)), 166.0)
	var style := str(house_layout.get("partition_style", "cloth"))
	match style:
		"screen":
			draw_line(origin, origin + Vector2(0, 244), Color("4d331f"), 4.0)
			draw_line(origin + Vector2(0, 4), origin + Vector2(0, 246), Color(1, 1, 1, 0.08), 1.0)
			draw_rect(Rect2(origin + Vector2(-92, 8), Vector2(184, 144)), house_theme.get("accent", Color("8f2f33")).darkened(0.1), true)
			draw_rect(Rect2(origin + Vector2(-92, 152), Vector2(184, 74)), house_theme.get("accent", Color("8f2f33")).lightened(0.05), true)
			for y in [24.0, 56.0, 88.0, 120.0, 170.0]:
				draw_line(origin + Vector2(-84, y), origin + Vector2(84, y), Color(1, 1, 1, 0.05), 1.0)
		"shack":
			draw_line(origin + Vector2(-34, 6), origin + Vector2(8, 216), Color("4d331f"), 4.0)
			draw_line(origin + Vector2(18, 0), origin + Vector2(58, 206), Color("4d331f"), 4.0)
			draw_colored_polygon(
				PackedVector2Array([
					origin + Vector2(-94, 18),
					origin + Vector2(4, 2),
					origin + Vector2(62, 102),
					origin + Vector2(-78, 156)
				]),
				house_theme.get("cloth", Color("8c604a")).darkened(0.1)
			)
			draw_rect(Rect2(origin + Vector2(-62, 158), Vector2(122, 56)), Color("6b4a2c"), true)
		"iron":
			draw_rect(Rect2(origin + Vector2(-86, 4), Vector2(172, 16)), Color("5f5f66"), true)
			draw_rect(Rect2(origin + Vector2(-86, 198), Vector2(172, 16)), Color("5f5f66"), true)
			for x in [-70.0, -42.0, -14.0, 14.0, 42.0, 70.0]:
				draw_rect(Rect2(origin + Vector2(x, 20), Vector2(8, 178)), Color("73727b"), true)
		"rack":
			for y in [14.0, 86.0, 158.0]:
				draw_rect(Rect2(origin + Vector2(-98, y), Vector2(196, 14)), Color("5f4832"), true)
			for x in [-80.0, -18.0, 44.0, 86.0]:
				draw_rect(Rect2(origin + Vector2(x, 20), Vector2(12, 186)), Color("4b3526"), true)
		_:
			draw_line(origin, origin + Vector2(0, 226), Color("4d331f"), 4.0)
			draw_line(origin + Vector2(0, 4), origin + Vector2(0, 228), Color(1, 1, 1, 0.08), 1.0)
			draw_rect(Rect2(origin + Vector2(-80, 10), Vector2(160, 138)), house_theme.get("accent", Color("8f2f33")).darkened(0.1), true)
			draw_rect(Rect2(origin + Vector2(-80, 148), Vector2(160, 66)), house_theme.get("accent", Color("8f2f33")).lightened(0.05), true)
			for y in [24.0, 56.0, 88.0, 120.0, 170.0]:
				draw_line(origin + Vector2(-72, y), origin + Vector2(72, y), Color(1, 1, 1, 0.05), 1.0)


func _draw_lived_in_props() -> void:
	draw_rect(Rect2(214, 334, 72, 28), Color("9b815d"), true)
	draw_rect(Rect2(214, 362, 72, 18), Color("4f3521"), true)
	draw_circle(Vector2(1102, 660), 26, Color("7a5a37"))
	draw_circle(Vector2(1102, 660), 14, Color("5d4128"))
	draw_circle(Vector2(196, 638), 18, Color("7a5a37"))
	draw_rect(Rect2(234, 624, 44, 28), Color("7d5634"), true)
	draw_rect(Rect2(1132, 646, 42, 48), Color("7a5636"), true)
	for x in [420, 470, 520]:
		draw_rect(Rect2(x, 702, 36, 18), Color("9a7a55"), true)
	_draw_broom(Vector2(1186, 632))
	_draw_wall_crock(Vector2(264, 250))
	_draw_wall_crock(Vector2(314, 266))
	_draw_wall_hangings()
	_draw_hanging_coats(Vector2(918, 214), max(1, int(house_state.get("resident_count", 1))))
	match str(house_data.get("id", "")):
		"dock_house":
			_draw_rope_bundle(Vector2(226, 578))
			_draw_rope_bundle(Vector2(266, 594))
			draw_rect(Rect2(948, 514, 82, 18), Color("4e6d7b"), true)
			draw_rect(Rect2(956, 530, 64, 8), Color("c9d7de"), true)
			_draw_item_texture(BARREL_TEXTURE, Vector2(180, 560), 2.8)
			_draw_item_texture(TW_KEY, Vector2(586, 318), 2.4)
		"factory_house":
			_draw_tool_rack(Vector2(938, 506))
			_draw_tool_rack(Vector2(214, 520))
			draw_rect(Rect2(984, 522, 64, 18), Color("4c382b"), true)
			draw_rect(Rect2(992, 540, 48, 8), Color("aa7335"), true)
			_draw_other_item(Vector2(236, 482), Rect2(96, 0, 12, 12), 2.6)
			_draw_weapon_item(Vector2(1018, 496), Rect2(84, 0, 16, 16), 2.4)
		"exchange_house":
			draw_rect(Rect2(214, 534, 112, 58), Color("5a402c"), true)
			for y in [546.0, 560.0, 574.0]:
				draw_rect(Rect2(228, y, 84, 6), Color("e8d9b5"), true)
			_draw_other_item(Vector2(1038, 512), Rect2(120, 0, 12, 12), 2.2)
			_draw_book_stack(Vector2(1088, 496))
			_draw_scaled_texture(TW_UP_DOOR, Rect2(216, 482, 40, 52), Color(1, 1, 1, 0.72))
			_draw_item_texture(TW_COIN, Vector2(694, 300), 2.6)
			_draw_item_texture(GOLD_TEXTURE, Vector2(726, 302), 2.2)
		_:
			draw_rect(Rect2(214, 542, 92, 64), Color("66402a"), true)
			draw_rect(Rect2(228, 556, 64, 36), Color("8f6b4a"), true)
			_draw_food_item(Vector2(258, 544), Rect2(72, 0, 18, 17), 1.6)
			_draw_item_texture(TW_COIN, Vector2(592, 332), 2.2)
	if bool(house_layout.get("laundry", false)):
		_draw_laundry_basket(Vector2(1036, 704))
	if bool(house_layout.get("wash_basin", false)):
		draw_circle(Vector2(1088, 716), 18.0, Color("7b8d93"))
		draw_circle(Vector2(1088, 716), 10.0, Color("bcd5db"))


func _draw_doorway() -> void:
	var door_center := Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 746.0)))
	var frame := Rect2(door_center + Vector2(-70, -4), Vector2(140, 92))
	var doorstep_alpha: float = _doorstep_transition_strength()
	draw_rect(frame, Color("3a2518"), true)
	draw_rect(Rect2(frame.position + Vector2(16, 0), Vector2(108, 82)), Color("5f3f27"), true)
	_draw_scaled_texture(TW_DOWN_DOOR, Rect2(frame.position + Vector2(18, 0), Vector2(104, 84)), Color(1, 1, 1, 0.72))
	draw_circle(frame.position + Vector2(104, 44), 6, Color("caa562"))
	draw_rect(Rect2(frame.position + Vector2(-18, 82), Vector2(176, 14)), Color("1a120d"), true)
	if bool(house_state.get("lights_on", false)):
		draw_rect(Rect2(frame.position + Vector2(10, 8), Vector2(120, 10)), Color(1.0, 0.82, 0.46, 0.08), true)
	if doorstep_alpha > 0.04:
		draw_rect(Rect2(frame.position + Vector2(48, 8), Vector2(18, 72)), Color(1.0, 0.92, 0.68, doorstep_alpha * 0.18), true)
		draw_colored_polygon(PackedVector2Array([
			frame.position + Vector2(56, 84),
			frame.position + Vector2(102, 106),
			frame.position + Vector2(26, 106),
		]), Color(1.0, 0.88, 0.58, doorstep_alpha * 0.14))
		draw_circle(frame.position + Vector2(34, 98), 4.0, Color(0.38, 0.28, 0.18, doorstep_alpha * 0.5))
		draw_circle(frame.position + Vector2(94, 102), 4.0, Color(0.38, 0.28, 0.18, doorstep_alpha * 0.36))


func _draw_light_pools() -> void:
	var warm_strength := _lamp_strength()
	var warm: Color = house_theme.get("light", Color(1.0, 0.83, 0.45, 0.1))
	draw_circle(Vector2(float(house_layout.get("kitchen_x", 1000.0)), float(house_layout.get("kitchen_y", 256.0)) + 44), 94.0, warm * Color(1, 1, 1, 0.55 + warm_strength * 0.45))
	for pool in house_layout.get("lamp_pools", [Vector2(186, 170), Vector2(1128, 170)]):
		draw_circle(pool, 62.0, Color(1.0, 0.86, 0.58, 0.04 + warm_strength * 0.1))
	if bool(house_state.get("lights_on", false)):
		draw_circle(Vector2(float(house_layout.get("desk_x", 628.0)), float(house_layout.get("desk_y", 360.0)) - 56), 72.0, Color(1.0, 0.84, 0.56, 0.06 + warm_strength * 0.08))
	var doorway_heat: float = _doorstep_transition_strength()
	if doorway_heat > 0.04:
		var entry := Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 744.0))) + Vector2(0.0, 40.0)
		draw_circle(entry, 76.0, Color(1.0, 0.9, 0.62, doorway_heat * 0.08))


func _draw_calcium_room_set() -> void:
	if calcium_interior == null:
		return
	match str(house_data.get("id", "")):
		"dock_house":
			_draw_region_texture(calcium_interior, CALCIUM_DINING_REGION, Rect2(420, 514, 190, 94), Color(1, 1, 1, 0.9))
			_draw_region_texture(calcium_interior, CALCIUM_SHELF_REGION, Rect2(210, 212, 128, 128), Color(1, 1, 1, 0.88))
			_draw_region_texture(calcium_interior, CALCIUM_BARREL_REGION, Rect2(864, 520, 160, 106), Color(1, 1, 1, 0.88))
		"factory_house":
			_draw_region_texture(calcium_interior, CALCIUM_FORGE_REGION, Rect2(858, 158, 224, 192), Color(1, 1, 1, 0.9))
			_draw_region_texture(calcium_interior, CALCIUM_CRATE_REGION, Rect2(820, 548, 196, 84), Color(1, 1, 1, 0.9))
			_draw_region_texture(calcium_interior, CALCIUM_TOOL_REGION, Rect2(214, 536, 128, 96), Color(1, 1, 1, 0.88))
		"exchange_house":
			_draw_region_texture(calcium_interior, CALCIUM_DINING_REGION, Rect2(468, 500, 210, 98), Color(1, 1, 1, 0.92))
			_draw_region_texture(calcium_interior, CALCIUM_COUNTER_REGION, Rect2(188, 504, 192, 128), Color(1, 1, 1, 0.92))
			_draw_region_texture(calcium_interior, CALCIUM_SHELF_REGION, Rect2(930, 210, 136, 136), Color(1, 1, 1, 0.88))
		_:
			_draw_region_texture(calcium_interior, CALCIUM_FORGE_REGION, Rect2(888, 170, 188, 156), Color(1, 1, 1, 0.72))
			_draw_region_texture(calcium_interior, CALCIUM_BARREL_REGION, Rect2(198, 542, 140, 96), Color(1, 1, 1, 0.84))
			_draw_region_texture(calcium_interior, CALCIUM_CRATE_REGION, Rect2(862, 554, 176, 78), Color(1, 1, 1, 0.84))


func _draw_woodshop_set() -> void:
	if woodshop_texture == null:
		return
	match str(house_data.get("id", "")):
		"dock_house":
			_draw_region_texture(woodshop_texture, WOODSHOP_BENCH_REGION, Rect2(154, 578, 256, 64), Color(1, 1, 1, 0.9))
			_draw_region_texture(woodshop_texture, WOODSHOP_TOOL_WALL_REGION, Rect2(918, 206, 220, 42), Color(1, 1, 1, 0.92))
			_draw_region_texture(woodshop_texture, WOODSHOP_WOOD_REGION, Rect2(104, 706, 230, 100), Color(1, 1, 1, 0.82))
		"factory_house":
			_draw_region_texture(woodshop_texture, WOODSHOP_BENCH_REGION, Rect2(136, 566, 274, 70), Color(1, 1, 1, 0.94))
			_draw_region_texture(woodshop_texture, WOODSHOP_SAW_REGION, Rect2(874, 566, 172, 126), Color(1, 1, 1, 0.92))
			_draw_region_texture(woodshop_texture, WOODSHOP_TOOL_WALL_REGION, Rect2(176, 206, 254, 48), Color(1, 1, 1, 0.96))
			_draw_region_texture(woodshop_texture, WOODSHOP_TOOLS_REGION, Rect2(436, 706, 176, 54), Color(1, 1, 1, 0.86))
			_draw_region_texture(woodshop_texture, WOODSHOP_WOOD_REGION, Rect2(874, 704, 240, 104), Color(1, 1, 1, 0.84))
		"exchange_house":
			_draw_region_texture(woodshop_texture, WOODSHOP_CRATE_REGION, Rect2(868, 690, 164, 88), Color(1, 1, 1, 0.62))
		_:
			_draw_region_texture(woodshop_texture, WOODSHOP_BENCH_REGION, Rect2(126, 596, 222, 56), Color(1, 1, 1, 0.74))
			_draw_region_texture(woodshop_texture, WOODSHOP_WOOD_REGION, Rect2(842, 712, 184, 82), Color(1, 1, 1, 0.68))


func _draw_activity_scene() -> void:
	var primary_activity := str(house_state.get("primary_activity", "away"))
	_draw_activity_props(primary_activity, 0)
	if int(house_state.get("residents_home", 0)) > 1:
		_draw_activity_props(str(house_state.get("secondary_activity", "away")), 1)


func _draw_settle_props() -> void:
	var residents_home := int(house_state.get("residents_home", 0))
	if residents_home <= 0:
		return
	var primary_pose := _resident_pose_for_slot(0, str(house_state.get("primary_activity", "away")), str(house_state.get("primary_state", "away")))
	_draw_stage_prop(primary_pose)
	if residents_home > 1:
		var secondary_home_state := "evening_home" if str(house_state.get("primary_state", "away")) == "evening_home" else "resting"
		var secondary_pose := _resident_pose_for_slot(1, str(house_state.get("secondary_activity", "away")), secondary_home_state)
		_draw_stage_prop(secondary_pose)


func _draw_stage_prop(pose: Dictionary) -> void:
	var stage := str(pose.get("stage", ""))
	var anchor: Vector2 = pose.get("anchor", Vector2.ZERO)
	match stage:
		"drop", "cabinet":
			_draw_satchel(anchor + Vector2(18, 22))
		"dress_badge":
			draw_line(anchor + Vector2(12, -10), anchor + Vector2(12, 16), Color("5e4632"), 2.0)
			draw_rect(Rect2(anchor + Vector2(4, 8), Vector2(16, 12)), Color("b58a4d"), true)
			draw_rect(Rect2(anchor + Vector2(8, 10), Vector2(8, 8)), Color("e8d8ad"), true)
		"take_ledger":
			_draw_ledger_set(anchor + Vector2(-12, -18))
			draw_rect(Rect2(anchor + Vector2(24, 8), Vector2(14, 10)), Color("7a583d"), true)
		"lift_bag":
			_draw_satchel(anchor + Vector2(10, 12))
			draw_rect(Rect2(anchor + Vector2(24, 10), Vector2(18, 14)), Color("7d5f40"), true)
			draw_line(anchor + Vector2(26, 14), anchor + Vector2(38, 22), Color("cdb388"), 1.2)
		"ledger":
			_draw_ledger_set(anchor + Vector2(-6, -22))
		"meal":
			_draw_region_texture(calcium_interior, CALCIUM_DISH_REGION, Rect2(anchor + Vector2(-50, -18), Vector2(84, 52)), Color(1, 1, 1, 0.86))
		"sorting":
			_draw_region_texture(calcium_interior, CALCIUM_CRATE_REGION, Rect2(anchor + Vector2(-44, -24), Vector2(108, 48)), Color(1, 1, 1, 0.84))
		"stoke":
			_draw_cooking_steam(anchor + Vector2(6, -34), 0.78)
		"wash":
			draw_rect(Rect2(anchor + Vector2(18, 10), Vector2(22, 10)), Color("d9cfb6"), true)
		"tool":
			draw_rect(Rect2(anchor + Vector2(16, 6), Vector2(24, 8)), Color("74655c"), true)
		"mending":
			draw_rect(Rect2(anchor + Vector2(14, 10), Vector2(26, 12)), Color("d7c9aa"), true)
			draw_line(anchor + Vector2(14, 16), anchor + Vector2(38, 18), Color("8f2f33"), 1.4)
		"clear_table":
			_draw_region_texture(calcium_interior, CALCIUM_DISH_REGION, Rect2(anchor + Vector2(-42, -20), Vector2(72, 48)), Color(1, 1, 1, 0.82))
			draw_rect(Rect2(anchor + Vector2(20, 2), Vector2(18, 12)), Color("d4c3a0"), true)
		"uncoat":
			draw_rect(Rect2(anchor + Vector2(12, -6), Vector2(10, 30)), house_theme.get("resident_cloak", Color("70533d")), true)
			draw_line(anchor + Vector2(18, -12), anchor + Vector2(18, 2), Color("5f432e"), 2.0)
			draw_circle(anchor + Vector2(18, -14), 3.0, Color("d8c188"))
		"set_bag":
			_draw_satchel(anchor + Vector2(14, 14))
			draw_rect(Rect2(anchor + Vector2(26, 14), Vector2(14, 10)), Color("70533d"), true)
		"extinguish":
			draw_circle(anchor + Vector2(0, -16), 8.0, Color(0.76, 0.72, 0.68, 0.14))
			draw_circle(anchor + Vector2(8, -28), 12.0, Color(0.62, 0.6, 0.56, 0.1))
			draw_line(anchor + Vector2(12, 14), anchor + Vector2(32, -6), Color("6f5842"), 1.8)
		"lockup":
			draw_rect(Rect2(anchor + Vector2(12, 8), Vector2(26, 16)), Color("77583e"), true)
			draw_circle(anchor + Vector2(6, 16), 4.0, Color("d4b661"))
			draw_line(anchor + Vector2(6, 20), anchor + Vector2(16, 24), Color("d4b661"), 1.2)
		"turn_down":
			draw_rect(Rect2(anchor + Vector2(6, 10), Vector2(34, 16)), Color("b39d72"), true)
			draw_line(anchor + Vector2(10, 14), anchor + Vector2(34, 22), Color("e7d7b5"), 1.0)
		"night_lamp":
			draw_rect(Rect2(anchor + Vector2(18, 10), Vector2(14, 10)), Color("6e4e34"), true)
			draw_rect(Rect2(anchor + Vector2(22, 2), Vector2(6, 10)), Color("dbcba4"), true)
			draw_circle(anchor + Vector2(25, 0), 4.0, Color(1.0, 0.86, 0.52, 0.44))
			if emote_sleeps_texture != null:
				draw_texture_rect(emote_sleeps_texture, Rect2(anchor + Vector2(-6, -54), Vector2(20, 20)), false, Color(1, 1, 1, 0.72))
		"farewell":
			draw_rect(Rect2(anchor + Vector2(-18, 18), Vector2(46, 10)), Color("6c4d34"), true)
			draw_line(anchor + Vector2(-14, 14), anchor + Vector2(20, 14), Color("d5c39a"), 1.2)
			draw_circle(anchor + Vector2(32, 20), 4.0, Color("4a3426"))
		"threshold":
			draw_colored_polygon(PackedVector2Array([
				anchor + Vector2(-12, 22),
				anchor + Vector2(30, 12),
				anchor + Vector2(42, 22),
				anchor + Vector2(0, 34),
			]), Color(1.0, 0.9, 0.68, 0.14))
			draw_rect(Rect2(anchor + Vector2(-10, 24), Vector2(22, 8)), Color("503728"), true)
			draw_rect(Rect2(anchor + Vector2(18, 22), Vector2(14, 10)), Color("d2c39c"), true)
		"bedside":
			draw_rect(Rect2(anchor + Vector2(16, 14), Vector2(22, 10)), Color("70533d"), true)
			draw_rect(Rect2(anchor + Vector2(20, 10), Vector2(14, 8)), Color("d9cfb6"), true)
			draw_circle(anchor + Vector2(10, 18), 4.0, Color("3f2f23"))
			draw_circle(anchor + Vector2(22, 18), 4.0, Color("3f2f23"))
			if emote_sleep_texture != null and current_clock_minutes >= int(house_layout.get("route_bed_minutes", 21 * 60 + 30)) - 10:
				draw_texture_rect(emote_sleep_texture, Rect2(anchor + Vector2(-2, -44), Vector2(16, 16)), false, Color(1, 1, 1, 0.62))
	_draw_sleep_trace(stage, anchor)


func _draw_sleep_trace(stage: String, anchor: Vector2) -> void:
	match str(house_data.get("id", "")):
		"factory_house":
			_draw_factory_sleep_trace(stage, anchor)
		"exchange_house":
			_draw_exchange_sleep_trace(stage, anchor)
		"dock_house":
			_draw_dock_sleep_trace(stage, anchor)
		_:
			_draw_slum_sleep_trace(stage, anchor)


func _draw_slum_sleep_trace(stage: String, anchor: Vector2) -> void:
	match stage:
		"set_bag":
			draw_rect(Rect2(anchor + Vector2(2, 18), Vector2(22, 14)), Color("624631"), true)
			draw_line(anchor + Vector2(2, 24), anchor + Vector2(24, 28), Color("9a6d47"), 1.0)
			draw_line(anchor + Vector2(10, 17), anchor + Vector2(22, 30), Color("3a271c"), 1.2)
		"turn_down", "bedside":
			draw_rect(Rect2(anchor + Vector2(-18, 8), Vector2(30, 16)), Color("8d6a57"), true)
			draw_line(anchor + Vector2(-14, 12), anchor + Vector2(8, 24), Color("cdbb93"), 1.0)
			draw_line(anchor + Vector2(-6, 8), anchor + Vector2(-2, 24), Color("6b3b33"), 1.0)
		"night_lamp":
			draw_rect(Rect2(anchor + Vector2(10, 14), Vector2(12, 6)), Color("5a4231"), true)
			draw_circle(anchor + Vector2(16, 10), 2.5, Color(1.0, 0.76, 0.32, 0.4))


func _draw_factory_sleep_trace(stage: String, anchor: Vector2) -> void:
	match stage:
		"uncoat", "set_bag":
			draw_rect(Rect2(anchor + Vector2(0, 18), Vector2(18, 12)), Color("7f8488"), true)
			draw_rect(Rect2(anchor + Vector2(18, 18), Vector2(14, 10)), Color("a19a8b"), true)
			draw_rect(Rect2(anchor + Vector2(4, 14), Vector2(8, 5)), Color("b8834d"), true)
		"lockup":
			draw_rect(Rect2(anchor + Vector2(-6, 18), Vector2(12, 8)), Color("6d6f73"), true)
			draw_rect(Rect2(anchor + Vector2(12, 14), Vector2(10, 12)), Color("9a9ea1"), true)
			draw_circle(anchor + Vector2(28, 20), 5.0, Color("8f9699"))
		"bedside", "night_lamp":
			draw_circle(anchor + Vector2(-8, 18), 6.0, Color("73797d"))
			draw_rect(Rect2(anchor + Vector2(4, 14), Vector2(18, 8)), Color("9ea4a7"), true)
			draw_rect(Rect2(anchor + Vector2(8, 10), Vector2(10, 4)), Color("c6b08c"), true)


func _draw_exchange_sleep_trace(stage: String, anchor: Vector2) -> void:
	match stage:
		"lockup":
			if WOOD_CHEST_CLOSED != null:
				draw_texture_rect(WOOD_CHEST_CLOSED, Rect2(anchor + Vector2(-6, 4), Vector2(28, 28)), false, Color(1, 1, 1, 0.9))
			if TW_KEY != null:
				draw_texture_rect(TW_KEY, Rect2(anchor + Vector2(24, 10), Vector2(12, 12)), false, Color(1, 1, 1, 0.92))
		"turn_down", "bedside":
			draw_rect(Rect2(anchor + Vector2(-18, 6), Vector2(28, 14)), Color("d4c29f"), true)
			draw_line(anchor + Vector2(-14, 9), anchor + Vector2(4, 18), Color("f0e1bc"), 1.0)
			draw_line(anchor + Vector2(-4, 6), anchor + Vector2(0, 20), Color("8d6c55"), 1.0)
		"night_lamp":
			if GOLD_CUP_TEXTURE != null:
				draw_texture_rect(GOLD_CUP_TEXTURE, Rect2(anchor + Vector2(8, 2), Vector2(18, 18)), false, Color(1, 1, 1, 0.92))
			draw_circle(anchor + Vector2(18, 0), 3.6, Color(1.0, 0.86, 0.52, 0.52))
			draw_circle(anchor + Vector2(18, -6), 6.0, Color(1.0, 0.82, 0.44, 0.12))


func _draw_dock_sleep_trace(stage: String, anchor: Vector2) -> void:
	match stage:
		"set_bag":
			draw_line(anchor + Vector2(-6, 18), anchor + Vector2(16, 28), Color("b99a68"), 2.0)
			draw_line(anchor + Vector2(0, 14), anchor + Vector2(20, 24), Color("7f6647"), 1.4)
			draw_rect(Rect2(anchor + Vector2(18, 18), Vector2(16, 10)), Color("5e7181"), true)
		"clear_table", "turn_down":
			draw_rect(Rect2(anchor + Vector2(-16, 12), Vector2(24, 10)), Color("6d7f8a"), true)
			draw_line(anchor + Vector2(-14, 14), anchor + Vector2(6, 20), Color("d8d1be"), 1.0)
		"night_lamp", "bedside":
			draw_rect(Rect2(anchor + Vector2(6, 14), Vector2(16, 8)), Color("5d452f"), true)
			draw_circle(anchor + Vector2(24, 18), 4.0, Color("30424f"))
			draw_circle(anchor + Vector2(10, 18), 4.0, Color("30424f"))


func _draw_morning_traces() -> void:
	var alpha: float = _morning_trace_alpha()
	if alpha <= 0.02:
		return
	var bed_anchor := Vector2(float(house_layout.get("bed_x", 282.0)), float(house_layout.get("bed_y", 256.0))) + Vector2(26.0, 52.0)
	var kitchen_anchor := Vector2(float(house_layout.get("kitchen_x", 1000.0)), float(house_layout.get("kitchen_y", 256.0))) + Vector2(-18.0, 86.0)
	var door_anchor := Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 744.0))) + Vector2(-18.0, 30.0)
	match str(house_data.get("id", "")):
		"factory_house":
			_draw_factory_morning_trace(bed_anchor, kitchen_anchor, door_anchor, alpha)
		"exchange_house":
			_draw_exchange_morning_trace(bed_anchor, kitchen_anchor, door_anchor, alpha)
		"dock_house":
			_draw_dock_morning_trace(bed_anchor, kitchen_anchor, door_anchor, alpha)
		_:
			_draw_slum_morning_trace(bed_anchor, kitchen_anchor, door_anchor, alpha)


func _morning_trace_alpha() -> float:
	if current_period == "dawn":
		return 0.96
	if current_period != "day":
		return 0.0
	var fade_start: float = 8.0 * 60.0 + 25.0
	var fade_end: float = 10.0 * 60.0 + 20.0
	if current_clock_minutes <= fade_start:
		return 0.9
	if current_clock_minutes >= fade_end:
		return 0.0
	return clampf(1.0 - (float(current_clock_minutes) - fade_start) / (fade_end - fade_start), 0.0, 0.9)


func _draw_slum_morning_trace(bed_anchor: Vector2, kitchen_anchor: Vector2, door_anchor: Vector2, alpha: float) -> void:
	draw_rect(Rect2(bed_anchor + Vector2(-26, 2), Vector2(38, 16)), Color(0.62, 0.47, 0.39, 0.76 * alpha), true)
	draw_line(bed_anchor + Vector2(-22, 6), bed_anchor + Vector2(6, 18), Color(0.86, 0.78, 0.62, 0.84 * alpha), 1.0)
	draw_line(bed_anchor + Vector2(-10, 2), bed_anchor + Vector2(-4, 18), Color(0.48, 0.23, 0.2, 0.9 * alpha), 1.0)
	draw_circle(kitchen_anchor + Vector2(-6, 2), 10.0, Color(0.36, 0.33, 0.29, 0.72 * alpha))
	draw_circle(kitchen_anchor + Vector2(12, -2), 6.0, Color(0.78, 0.72, 0.58, 0.72 * alpha))
	draw_rect(Rect2(kitchen_anchor + Vector2(14, 4), Vector2(14, 6)), Color(0.62, 0.49, 0.34, 0.82 * alpha), true)
	_draw_satchel(door_anchor + Vector2(-8, -2))
	draw_line(door_anchor + Vector2(-2, 4), door_anchor + Vector2(10, 10), Color(0.84, 0.76, 0.58, 0.84 * alpha), 1.0)


func _draw_factory_morning_trace(bed_anchor: Vector2, kitchen_anchor: Vector2, door_anchor: Vector2, alpha: float) -> void:
	draw_rect(Rect2(bed_anchor + Vector2(-20, 2), Vector2(22, 10)), Color(0.64, 0.67, 0.69, 0.8 * alpha), true)
	draw_rect(Rect2(bed_anchor + Vector2(6, 0), Vector2(12, 8)), Color(0.78, 0.48, 0.26, 0.84 * alpha), true)
	draw_circle(kitchen_anchor + Vector2(-4, 2), 8.0, Color(0.56, 0.58, 0.6, 0.82 * alpha))
	draw_rect(Rect2(kitchen_anchor + Vector2(8, -2), Vector2(16, 6)), Color(0.78, 0.68, 0.54, 0.72 * alpha), true)
	draw_rect(Rect2(door_anchor + Vector2(-10, 0), Vector2(12, 8)), Color(0.7, 0.72, 0.74, 0.82 * alpha), true)
	draw_rect(Rect2(door_anchor + Vector2(4, -2), Vector2(8, 10)), Color(0.86, 0.56, 0.32, 0.88 * alpha), true)
	draw_rect(Rect2(door_anchor + Vector2(14, 0), Vector2(14, 8)), Color(0.55, 0.57, 0.59, 0.76 * alpha), true)


func _draw_exchange_morning_trace(bed_anchor: Vector2, kitchen_anchor: Vector2, door_anchor: Vector2, alpha: float) -> void:
	draw_rect(Rect2(bed_anchor + Vector2(-24, 0), Vector2(34, 14)), Color(0.84, 0.78, 0.67, 0.82 * alpha), true)
	draw_line(bed_anchor + Vector2(-18, 3), bed_anchor + Vector2(6, 12), Color(0.96, 0.91, 0.79, 0.92 * alpha), 1.0)
	draw_circle(bed_anchor + Vector2(18, 4), 4.0, Color(0.98, 0.84, 0.46, 0.72 * alpha))
	draw_rect(Rect2(kitchen_anchor + Vector2(-2, -4), Vector2(18, 10)), Color(0.84, 0.76, 0.6, 0.76 * alpha), true)
	draw_circle(kitchen_anchor + Vector2(20, -6), 4.5, Color(0.98, 0.84, 0.5, 0.8 * alpha))
	if TW_KEY != null:
		draw_texture_rect(TW_KEY, Rect2(door_anchor + Vector2(0, -8), Vector2(12, 12)), false, Color(1, 1, 1, 0.88 * alpha))
	if WOOD_CHEST_CLOSED != null:
		draw_texture_rect(WOOD_CHEST_CLOSED, Rect2(door_anchor + Vector2(10, -2), Vector2(26, 26)), false, Color(1, 1, 1, 0.72 * alpha))


func _draw_dock_morning_trace(bed_anchor: Vector2, kitchen_anchor: Vector2, door_anchor: Vector2, alpha: float) -> void:
	draw_line(bed_anchor + Vector2(-18, 8), bed_anchor + Vector2(4, 18), Color(0.74, 0.64, 0.48, 0.86 * alpha), 2.0)
	draw_line(bed_anchor + Vector2(-10, 2), bed_anchor + Vector2(14, 14), Color(0.46, 0.38, 0.28, 0.8 * alpha), 1.2)
	draw_rect(Rect2(kitchen_anchor + Vector2(-8, 0), Vector2(20, 8)), Color(0.78, 0.72, 0.56, 0.78 * alpha), true)
	draw_rect(Rect2(kitchen_anchor + Vector2(12, 2), Vector2(12, 6)), Color(0.38, 0.5, 0.58, 0.82 * alpha), true)
	draw_circle(door_anchor + Vector2(-2, 10), 5.0, Color(0.22, 0.3, 0.36, 0.76 * alpha))
	draw_circle(door_anchor + Vector2(10, 10), 5.0, Color(0.22, 0.3, 0.36, 0.76 * alpha))
	draw_line(door_anchor + Vector2(18, 0), door_anchor + Vector2(34, 10), Color(0.78, 0.66, 0.46, 0.84 * alpha), 1.8)


func _draw_morning_activity_hints() -> void:
	var alpha: float = _morning_trace_alpha()
	if alpha <= 0.02:
		return
	var primary_activity: String = str(house_state.get("primary_activity", "away"))
	_draw_morning_activity_hint(primary_activity, 0, alpha)
	if int(house_state.get("residents_home", 0)) > 1:
		_draw_morning_activity_hint(str(house_state.get("secondary_activity", "away")), 1, alpha * 0.92)


func _draw_morning_activity_hint(activity_name: String, slot: int, alpha: float) -> void:
	if activity_name in ["", "away", "sleeping"]:
		return
	var anchor: Vector2 = _activity_anchor_for_slot(activity_name, slot)
	match str(house_data.get("id", "")):
		"factory_house":
			_draw_factory_morning_activity_hint(activity_name, anchor, alpha)
		"exchange_house":
			_draw_exchange_morning_activity_hint(activity_name, anchor, alpha)
		"dock_house":
			_draw_dock_morning_activity_hint(activity_name, anchor, alpha)
		_:
			_draw_slum_morning_activity_hint(activity_name, anchor, alpha)


func _draw_slum_morning_activity_hint(activity_name: String, anchor: Vector2, alpha: float) -> void:
	match activity_name:
		"cooking":
			draw_rect(Rect2(anchor + Vector2(-18, 18), Vector2(18, 8)), Color(0.66, 0.53, 0.33, 0.84 * alpha), true)
			draw_circle(anchor + Vector2(14, 12), 6.0, Color(0.34, 0.31, 0.28, 0.68 * alpha))
		"washing":
			draw_rect(Rect2(anchor + Vector2(18, -6), Vector2(16, 8)), Color(0.8, 0.71, 0.56, 0.82 * alpha), true)
			draw_line(anchor + Vector2(22, -8), anchor + Vector2(34, 0), Color(0.76, 0.7, 0.56, 0.84 * alpha), 1.0)
		"sorting_goods", "mending":
			_draw_satchel(anchor + Vector2(10, 10))
			draw_line(anchor + Vector2(8, 12), anchor + Vector2(22, 20), Color(0.86, 0.78, 0.62, 0.76 * alpha), 1.0)
		"eating":
			draw_rect(Rect2(anchor + Vector2(-12, 16), Vector2(16, 8)), Color(0.74, 0.62, 0.44, 0.84 * alpha), true)
			draw_circle(anchor + Vector2(12, 18), 4.0, Color(0.86, 0.8, 0.62, 0.72 * alpha))


func _draw_factory_morning_activity_hint(activity_name: String, anchor: Vector2, alpha: float) -> void:
	match activity_name:
		"cooking", "warming":
			draw_circle(anchor + Vector2(-6, 18), 7.0, Color(0.58, 0.6, 0.62, 0.84 * alpha))
			draw_rect(Rect2(anchor + Vector2(10, 16), Vector2(14, 6)), Color(0.84, 0.72, 0.56, 0.76 * alpha), true)
		"washing":
			draw_rect(Rect2(anchor + Vector2(18, -8), Vector2(10, 10)), Color(0.78, 0.8, 0.82, 0.84 * alpha), true)
			draw_rect(Rect2(anchor + Vector2(30, -6), Vector2(8, 8)), Color(0.66, 0.68, 0.7, 0.84 * alpha), true)
		"ledger", "reading":
			draw_rect(Rect2(anchor + Vector2(-16, 16), Vector2(12, 8)), Color(0.7, 0.72, 0.74, 0.86 * alpha), true)
			draw_rect(Rect2(anchor + Vector2(4, 14), Vector2(8, 10)), Color(0.86, 0.56, 0.32, 0.9 * alpha), true)
		"mending", "sorting_goods":
			draw_rect(Rect2(anchor + Vector2(12, 14), Vector2(14, 8)), Color(0.56, 0.58, 0.6, 0.84 * alpha), true)
			draw_circle(anchor + Vector2(6, 18), 3.6, Color(0.84, 0.66, 0.38, 0.82 * alpha))


func _draw_exchange_morning_activity_hint(activity_name: String, anchor: Vector2, alpha: float) -> void:
	match activity_name:
		"ledger", "reading":
			draw_rect(Rect2(anchor + Vector2(-20, 14), Vector2(18, 10)), Color(0.86, 0.8, 0.68, 0.88 * alpha), true)
			if TW_KEY != null:
				draw_texture_rect(TW_KEY, Rect2(anchor + Vector2(8, 10), Vector2(10, 10)), false, Color(1, 1, 1, 0.82 * alpha))
		"eating", "cooking":
			if GOLD_CUP_TEXTURE != null:
				draw_texture_rect(GOLD_CUP_TEXTURE, Rect2(anchor + Vector2(-8, 10), Vector2(16, 16)), false, Color(1, 1, 1, 0.84 * alpha))
			draw_circle(anchor + Vector2(16, 18), 4.0, Color(0.96, 0.84, 0.52, 0.76 * alpha))
		"sorting_goods":
			draw_rect(Rect2(anchor + Vector2(8, 14), Vector2(16, 10)), Color(0.78, 0.62, 0.42, 0.84 * alpha), true)
			draw_circle(anchor + Vector2(28, 18), 3.0, Color(0.96, 0.84, 0.52, 0.72 * alpha))
		"mending":
			draw_rect(Rect2(anchor + Vector2(10, 14), Vector2(18, 8)), Color(0.82, 0.72, 0.62, 0.84 * alpha), true)
			draw_line(anchor + Vector2(8, 12), anchor + Vector2(26, 22), Color(0.94, 0.88, 0.76, 0.9 * alpha), 1.0)


func _draw_dock_morning_activity_hint(activity_name: String, anchor: Vector2, alpha: float) -> void:
	match activity_name:
		"cooking", "eating":
			draw_rect(Rect2(anchor + Vector2(-18, 16), Vector2(18, 8)), Color(0.76, 0.7, 0.54, 0.84 * alpha), true)
			draw_rect(Rect2(anchor + Vector2(8, 14), Vector2(14, 6)), Color(0.42, 0.56, 0.64, 0.84 * alpha), true)
		"sorting_goods":
			draw_line(anchor + Vector2(-10, 14), anchor + Vector2(14, 24), Color(0.8, 0.68, 0.48, 0.88 * alpha), 1.8)
			draw_rect(Rect2(anchor + Vector2(18, 16), Vector2(14, 8)), Color(0.32, 0.46, 0.54, 0.82 * alpha), true)
		"ledger", "reading":
			draw_rect(Rect2(anchor + Vector2(-12, 16), Vector2(14, 8)), Color(0.72, 0.68, 0.58, 0.78 * alpha), true)
			draw_circle(anchor + Vector2(16, 18), 3.6, Color(0.32, 0.46, 0.54, 0.84 * alpha))


func _draw_activity_props(activity_name: String, slot: int) -> void:
	if activity_name in ["", "away", "sleeping"]:
		return
	var anchor := _activity_anchor_for_slot(activity_name, slot)
	match activity_name:
		"cooking":
			_draw_region_texture(calcium_interior, CALCIUM_DISH_REGION, Rect2(anchor + Vector2(-62, -10), Vector2(108, 66)), Color(1, 1, 1, 0.92))
			_draw_cooking_steam(anchor + Vector2(10, -42), 0.9)
		"ledger", "reading":
			_draw_region_texture(calcium_interior, CALCIUM_COUNTER_REGION, Rect2(anchor + Vector2(-48, -82), Vector2(120, 80)), Color(1, 1, 1, 0.88))
		"sorting_goods":
			_draw_region_texture(calcium_interior, CALCIUM_CRATE_REGION, Rect2(anchor + Vector2(-54, -32), Vector2(134, 58)), Color(1, 1, 1, 0.9))
			if woodshop_texture != null:
				_draw_region_texture(woodshop_texture, WOODSHOP_CRATE_REGION, Rect2(anchor + Vector2(-68, 12), Vector2(144, 82)), Color(1, 1, 1, 0.86))
		"washing":
			draw_circle(anchor + Vector2(0, 12), 22.0, Color("7b8d93"))
			draw_circle(anchor + Vector2(0, 12), 12.0 + sin(pulse_time * 2.8) * 1.6, Color("bfd6df"))
			draw_rect(Rect2(anchor + Vector2(30, -6), Vector2(18, 34)), Color("d8cdb0"), true)
		"mending":
			_draw_region_texture(calcium_interior, CALCIUM_TOOL_REGION, Rect2(anchor + Vector2(-42, -36), Vector2(96, 72)), Color(1, 1, 1, 0.9))
			if woodshop_texture != null:
				_draw_region_texture(woodshop_texture, WOODSHOP_TOOLS_REGION, Rect2(anchor + Vector2(-60, 10), Vector2(132, 44)), Color(1, 1, 1, 0.88))
		"eating":
			_draw_region_texture(calcium_interior, CALCIUM_DISH_REGION, Rect2(anchor + Vector2(-56, -20), Vector2(94, 58)), Color(1, 1, 1, 0.88))
		"warming":
			draw_circle(anchor + Vector2(0, 8), 44.0, Color(1.0, 0.75, 0.34, 0.08 + sin(pulse_time * 2.0) * 0.01))


func _activity_anchor(activity_name: String, secondary: bool) -> Vector2:
	var offset := Vector2(0.0, 0.0)
	if secondary:
		offset = Vector2(74.0, 16.0)
	match activity_name:
		"cooking", "warming":
			return Vector2(float(house_layout.get("kitchen_x", 1000.0)) - 56.0, float(house_layout.get("kitchen_y", 256.0)) + 72.0) + offset
		"sorting_goods":
			return Vector2(float(house_layout.get("storage_x", 954.0)) - 18.0, float(house_layout.get("storage_y", 608.0)) + 18.0) + offset
		"washing":
			if bool(house_layout.get("wash_basin", false)):
				return Vector2(1088.0, 704.0) + offset
			return Vector2(float(house_layout.get("storage_x", 954.0)) + 106.0, float(house_layout.get("storage_y", 608.0)) + 86.0) + offset
		"mending":
			return Vector2(float(house_layout.get("bed_x", 282.0)) + 96.0, float(house_layout.get("bed_y", 256.0)) + 64.0) + offset
		"eating":
			return Vector2(float(house_layout.get("desk_x", 628.0)) - 104.0, float(house_layout.get("desk_y", 360.0)) + 124.0) + offset
		_:
			return Vector2(float(house_layout.get("desk_x", 628.0)) - 10.0, float(house_layout.get("desk_y", 360.0)) + 34.0) + offset


func _activity_anchor_for_slot(activity_name: String, slot: int) -> Vector2:
	var stage := _stage_for_activity(activity_name)
	return _stage_anchor(stage, slot)


func _activity_prefers_seat(activity_name: String) -> bool:
	return activity_name in ["ledger", "reading", "eating", "mending"]


func _resident_frame_index(slot: int) -> int:
	var options := [0, 1]
	match str(house_data.get("id", "")):
		"dock_house":
			options = [7, 8]
		"factory_house":
			options = [4, 6]
		"exchange_house":
			options = [9, 10]
		_:
			options = [0, 2]
	return options[min(slot, options.size() - 1)]


func _draw_wall_lights() -> void:
	if lights_texture == null:
		return
	var alpha := 0.38 + _lamp_strength() * 0.62
	var fixtures: Array[Dictionary] = []
	match str(house_data.get("id", "")):
		"dock_house":
			fixtures = [
				{"rect": Rect2(108, 168, 42, 126), "source": LPC_SMALL_TORCH_REGION},
				{"rect": Rect2(1144, 168, 42, 126), "source": LPC_SMALL_TORCH_REGION},
			]
		"factory_house":
			fixtures = [
				{"rect": Rect2(126, 164, 48, 132), "source": LPC_TORCH_REGION},
				{"rect": Rect2(1128, 164, 48, 132), "source": LPC_TORCH_REGION},
			]
		"exchange_house":
			fixtures = [
				{"rect": Rect2(138, 164, 42, 126), "source": LPC_SMALL_TORCH_REGION},
				{"rect": Rect2(1108, 164, 42, 126), "source": LPC_SMALL_TORCH_REGION},
			]
		_:
			fixtures = [
				{"rect": Rect2(120, 170, 40, 120), "source": LPC_SMALL_TORCH_REGION},
				{"rect": Rect2(1128, 170, 40, 120), "source": LPC_SMALL_TORCH_REGION},
			]
	for fixture in fixtures:
		var rect: Rect2 = fixture.get("rect", Rect2())
		var source: Rect2 = fixture.get("source", LPC_SMALL_TORCH_REGION)
		_draw_region_texture(lights_texture, source, rect, Color(1, 1, 1, alpha))
		var center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.34)
		draw_circle(center, 42.0, Color(1.0, 0.82, 0.4, 0.04 + _lamp_strength() * 0.06))


func _draw_resident_presence() -> void:
	var residents_home := int(house_state.get("residents_home", 0))
	if residents_home <= 0:
		return
	var home_state_name := str(house_state.get("primary_state", "resting"))
	var primary_activity := str(house_state.get("primary_activity", "resting"))
	var sleeping_count := int(house_state.get("sleeping_count", 0))
	if home_state_name == "sleeping":
		_draw_sleeping_shape(Vector2(float(house_layout.get("bed_x", 282.0)) - 18.0, float(house_layout.get("bed_y", 256.0)) - 16.0))
		if residents_home <= sleeping_count:
			return
	var primary_pose := _resident_pose_for_slot(0, primary_activity, home_state_name)
	if str(primary_pose.get("mode", "")) != "sleeping":
		_draw_resident_sprite(
			primary_pose.get("anchor", _activity_anchor(primary_activity, false)),
			bool(primary_pose.get("seated", false)),
			float(primary_pose.get("facing", -1.0)),
			0,
			str(primary_pose.get("stage", primary_activity))
		)
	if residents_home > 1:
		var secondary_activity := str(house_state.get("secondary_activity", "resting"))
		var secondary_home_state := "evening_home" if home_state_name == "evening_home" else "resting"
		var secondary_pose := _resident_pose_for_slot(1, secondary_activity, secondary_home_state)
		if str(secondary_pose.get("mode", "")) != "sleeping":
			_draw_resident_sprite(
				secondary_pose.get("anchor", _activity_anchor(secondary_activity, true)),
				bool(secondary_pose.get("seated", false)),
				float(secondary_pose.get("facing", 1.0)),
				1,
				str(secondary_pose.get("stage", secondary_activity))
			)


func _resident_pose_for_slot(slot: int, activity_name: String, home_state_name: String) -> Dictionary:
	var secondary := slot > 0
	var fallback_anchor := _activity_anchor_for_slot(activity_name, slot)
	var fallback := {
		"mode": "activity",
		"anchor": fallback_anchor,
		"seated": _activity_prefers_seat(activity_name),
		"facing": -1.0 if secondary else 1.0,
		"stage": _stage_for_activity(activity_name),
	}
	if home_state_name == "sleeping":
		return {
			"mode": "sleeping",
			"anchor": Vector2(float(house_layout.get("bed_x", 282.0)), float(house_layout.get("bed_y", 256.0))),
			"seated": false,
			"facing": -1.0,
			"stage": "sleeping",
	}
	if current_period in ["dawn", "day"]:
		var morning_route: Array = _morning_departure_route_points(slot, activity_name)
		if morning_route.size() >= 2:
			var route_wake: int = int(house_layout.get("route_wake_minutes", 6 * 60 + 2))
			var route_leave: int = int(house_layout.get("route_leave_minutes", 8 * 60 + 6))
			if current_clock_minutes >= route_wake and current_clock_minutes <= route_leave + 16:
				var wake_phase: float = _morning_phase_shift(slot, activity_name)
				var animated_wake_minutes: float = clampf(
					float(current_clock_minutes) + pulse_time * 3.4 + wake_phase,
					float(route_wake),
					float(max(route_leave, route_wake + 1))
				)
				if current_clock_minutes >= route_leave:
					var threshold_stage: String = "threshold"
					var threshold_anchor: Vector2 = _stage_anchor(threshold_stage, slot)
					return {
						"mode": "departure",
						"anchor": threshold_anchor + _stage_motion_offset(threshold_stage, slot, 1.0),
						"seated": false,
						"facing": 1.0,
						"stage": threshold_stage,
					}
				var wake_pose: Dictionary = _weighted_route_pose(morning_route, animated_wake_minutes, route_wake, route_leave, fallback_anchor)
				var wake_from_anchor: Vector2 = wake_pose.get("from_anchor", fallback_anchor)
				var wake_to_anchor: Vector2 = wake_pose.get("to_anchor", fallback_anchor)
				var wake_facing_delta: float = wake_to_anchor.x - wake_from_anchor.x
				var wake_facing: float = 1.0
				if absf(wake_facing_delta) >= 1.0:
					wake_facing = sign(wake_facing_delta)
				var wake_stage: String = str(wake_pose.get("stage", fallback.get("stage", "desk")))
				var wake_local: float = float(wake_pose.get("local", 0.0))
				var wake_anchor: Vector2 = wake_pose.get("anchor", fallback_anchor)
				return {
					"mode": "departure",
					"anchor": wake_anchor + _stage_motion_offset(wake_stage, slot, wake_local),
					"seated": bool(wake_pose.get("seated", false)),
					"facing": wake_facing,
					"stage": wake_stage,
				}
	if home_state_name != "evening_home" and current_period not in ["dusk", "night"]:
		return fallback
	var route := _night_route_points(slot, activity_name, home_state_name)
	if route.size() < 2:
		return fallback
	var route_start := int(house_layout.get("route_start_minutes", 18 * 60 + 10))
	var route_bed := int(house_layout.get("route_bed_minutes", 21 * 60 + 30))
	var slot_phase := _resident_phase_shift(slot, activity_name)
	var animated_minutes := clampf(
		float(current_clock_minutes) + pulse_time * 3.0 + slot_phase,
		float(route_start),
		float(max(route_bed, route_start + 1))
	)
	if current_clock_minutes >= route_bed and home_state_name != "evening_home":
		var settled_stage := "bedside"
		var settled_anchor := _stage_anchor(settled_stage, slot)
		return {
			"mode": "settled",
			"anchor": settled_anchor + _stage_motion_offset(settled_stage, slot, 1.0),
			"seated": settled_stage in ["bedside", "ledger", "meal", "mending"],
			"facing": -1.0 if secondary else 1.0,
			"stage": settled_stage,
		}
	var weighted_pose := _weighted_route_pose(route, animated_minutes, route_start, route_bed, fallback_anchor)
	var from_anchor: Vector2 = weighted_pose.get("from_anchor", fallback_anchor)
	var to_anchor: Vector2 = weighted_pose.get("to_anchor", fallback_anchor)
	var facing_delta := to_anchor.x - from_anchor.x
	var facing := -1.0 if secondary else 1.0
	if absf(facing_delta) >= 1.0:
		facing = sign(facing_delta)
	var stage := str(weighted_pose.get("stage", fallback.get("stage", "desk")))
	var local := float(weighted_pose.get("local", 0.0))
	var anchor: Vector2 = weighted_pose.get("anchor", fallback_anchor)
	return {
		"mode": "route",
		"anchor": anchor + _stage_motion_offset(stage, slot, local),
		"seated": bool(weighted_pose.get("seated", false)),
		"facing": facing,
		"stage": stage,
	}


func _morning_departure_route_points(slot: int, activity_name: String) -> Array:
	var route: Array = []
	match str(house_data.get("id", "")):
		"dock_house":
			route = [
				_route_step("bedside", slot, 0.62, true),
				_route_step("lift_bag", slot, 0.94),
				_route_step("sorting" if slot == 0 else "meal", slot, 0.86, slot == 1),
				_route_step("farewell", slot, 1.08),
				_route_step("threshold", slot, 0.92),
			]
		"factory_house":
			route = [
				_route_step("bedside", slot, 0.6, true),
				_route_step("dress_badge" if slot == 0 else "lift_bag", slot, 0.92),
				_route_step("tool" if slot == 0 else "wash", slot, 0.82),
				_route_step("farewell", slot, 1.06),
				_route_step("threshold", slot, 0.9),
			]
		"exchange_house":
			route = [
				_route_step("bedside", slot, 0.6, true),
				_route_step("take_ledger" if slot == 0 else "lift_bag", slot, 0.94),
				_route_step("ledger" if slot == 0 else "cabinet", slot, 0.88, slot == 0),
				_route_step("farewell", slot, 1.08),
				_route_step("threshold", slot, 0.88),
			]
		_:
			route = [
				_route_step("bedside", slot, 0.64, true),
				_route_step("lift_bag", slot, 0.9),
				_route_step("meal" if slot == 0 else "wash", slot, 0.82, slot == 0),
				_route_step("farewell", slot, 1.02),
				_route_step("threshold", slot, 0.9),
			]
	return _apply_morning_activity_focus(route, slot, activity_name)


func _morning_phase_shift(slot: int, activity_name: String) -> float:
	var shift: float = 8.0 if slot == 0 else 26.0
	match activity_name:
		"washing":
			return shift - 8.0
		"ledger", "reading":
			return shift + 14.0
		"sorting_goods":
			return shift + 10.0
		"cooking", "eating":
			return shift - 4.0
		_:
			return shift


func _apply_morning_activity_focus(route: Array, slot: int, activity_name: String) -> Array:
	var focused: Array = route.duplicate(true)
	var focus_stage: String = _stage_for_activity(activity_name)
	if focus_stage in ["entry", "bedside", "threshold", "farewell"]:
		return focused
	var exit_index: int = _route_stage_index(focused, "farewell")
	if exit_index == -1:
		exit_index = max(1, focused.size() - 1)
	var stage_index: int = _route_stage_index(focused, focus_stage)
	if stage_index == -1:
		focused.insert(exit_index, _route_step(focus_stage, slot, 1.18, _stage_prefers_seat(focus_stage)))
	else:
		var row: Dictionary = focused[stage_index]
		row["anchor"] = _stage_anchor(focus_stage, slot)
		row["seated"] = _stage_prefers_seat(focus_stage)
		row["weight"] = max(float(row.get("weight", 1.0)), 1.12)
		focused[stage_index] = row
	return focused


func _night_route_points(slot: int, activity_name: String, home_state_name: String) -> Array:
	var route: Array = []
	match str(house_data.get("id", "")):
		"dock_house":
			route = [
				_route_step("entry", slot, 0.9),
				_route_step("drop" if slot == 0 else "sorting", slot, 0.95),
				_route_step("kitchen" if slot == 0 else "storage", slot, 1.2),
				_route_step("meal" if slot == 0 else "table", slot, 1.35, true),
			]
		"factory_house":
			route = [
				_route_step("entry", slot, 0.85),
				_route_step("wash" if slot == 0 else "storage", slot, 1.1),
				_route_step("tool" if slot == 0 else "stoke", slot, 1.2),
				_route_step("ledger" if slot == 0 else "mending", slot, 1.25, true),
			]
		"exchange_house":
			route = [
				_route_step("entry", slot, 0.75),
				_route_step("cabinet" if slot == 0 else "kitchen", slot, 1.0),
				_route_step("ledger" if slot == 0 else "meal", slot, 1.3, true),
				_route_step("table" if slot == 0 else "desk", slot, 1.1, true),
			]
		_:
			route = [
				_route_step("entry", slot, 0.8),
				_route_step("drop" if slot == 0 else "wash", slot, 0.95),
				_route_step("kitchen" if slot == 0 else "storage", slot, 1.2),
				_route_step("ledger" if slot == 0 else "mending", slot, 1.25, true),
			]
	route.append_array(_sleep_prep_steps(slot))
	route = _apply_activity_focus(route, slot, activity_name, home_state_name)
	return route


func _route_step(stage: String, slot: int, weight: float, seated: bool = false) -> Dictionary:
	return {
		"anchor": _stage_anchor(stage, slot),
		"stage": stage,
		"seated": seated,
		"weight": weight,
	}


func _sleep_prep_steps(slot: int) -> Array:
	var steps: Array = []
	match str(house_data.get("id", "")):
		"dock_house":
			if slot == 0:
				steps = [
					_route_step("clear_table", slot, 0.8),
					_route_step("uncoat", slot, 0.58),
					_route_step("extinguish", slot, 0.75),
					_route_step("set_bag", slot, 0.64),
					_route_step("turn_down", slot, 0.66),
					_route_step("night_lamp", slot, 0.52),
					_route_step("bedside", slot, 0.84, true),
				]
			else:
				steps = [
					_route_step("lockup", slot, 0.82),
					_route_step("set_bag", slot, 0.66),
					_route_step("clear_table", slot, 0.72),
					_route_step("uncoat", slot, 0.6),
					_route_step("turn_down", slot, 0.7),
					_route_step("night_lamp", slot, 0.5),
					_route_step("bedside", slot, 0.8, true),
				]
		"factory_house":
			if slot == 0:
				steps = [
					_route_step("clear_table", slot, 0.78),
					_route_step("uncoat", slot, 0.62),
					_route_step("extinguish", slot, 0.76),
					_route_step("lockup", slot, 0.7),
					_route_step("set_bag", slot, 0.62),
					_route_step("turn_down", slot, 0.68),
					_route_step("night_lamp", slot, 0.5),
					_route_step("bedside", slot, 0.84, true),
				]
			else:
				steps = [
					_route_step("lockup", slot, 0.8),
					_route_step("set_bag", slot, 0.62),
					_route_step("clear_table", slot, 0.74),
					_route_step("uncoat", slot, 0.58),
					_route_step("turn_down", slot, 0.72),
					_route_step("night_lamp", slot, 0.48),
					_route_step("bedside", slot, 0.82, true),
				]
		"exchange_house":
			if slot == 0:
				steps = [
					_route_step("clear_table", slot, 0.74),
					_route_step("uncoat", slot, 0.56),
					_route_step("lockup", slot, 0.82),
					_route_step("set_bag", slot, 0.58),
					_route_step("turn_down", slot, 0.72),
					_route_step("night_lamp", slot, 0.54),
					_route_step("bedside", slot, 0.86, true),
				]
			else:
				steps = [
					_route_step("extinguish", slot, 0.7),
					_route_step("clear_table", slot, 0.78),
					_route_step("uncoat", slot, 0.56),
					_route_step("lockup", slot, 0.74),
					_route_step("set_bag", slot, 0.56),
					_route_step("turn_down", slot, 0.72),
					_route_step("night_lamp", slot, 0.5),
					_route_step("bedside", slot, 0.82, true),
				]
		_:
			if slot == 0:
				steps = [
					_route_step("clear_table", slot, 0.76),
					_route_step("uncoat", slot, 0.58),
					_route_step("extinguish", slot, 0.72),
					_route_step("set_bag", slot, 0.66),
					_route_step("turn_down", slot, 0.7),
					_route_step("night_lamp", slot, 0.52),
					_route_step("bedside", slot, 0.84, true),
				]
			else:
				steps = [
					_route_step("lockup", slot, 0.8),
					_route_step("set_bag", slot, 0.62),
					_route_step("clear_table", slot, 0.7),
					_route_step("uncoat", slot, 0.58),
					_route_step("turn_down", slot, 0.74),
					_route_step("night_lamp", slot, 0.48),
					_route_step("bedside", slot, 0.82, true),
				]
	return steps


func _apply_activity_focus(route: Array, slot: int, activity_name: String, home_state_name: String) -> Array:
	var focused: Array = route.duplicate(true)
	var focus_stage: String = _stage_for_activity(activity_name)
	if focus_stage in ["entry", "bedside"]:
		return focused
	var insert_index: int = max(1, focused.size() - 2)
	if home_state_name == "evening_home":
		insert_index = min(insert_index, 2)
	var stage_index: int = _route_stage_index(focused, focus_stage)
	if stage_index == -1:
		focused.insert(insert_index, _route_step(focus_stage, slot, 1.55, _stage_prefers_seat(focus_stage)))
	elif stage_index < focused.size():
		var row: Dictionary = focused[stage_index]
		row["anchor"] = _stage_anchor(focus_stage, slot)
		row["seated"] = _stage_prefers_seat(focus_stage)
		row["weight"] = max(float(row.get("weight", 1.0)), 1.45)
		focused[stage_index] = row
	var settle_index: int = _route_stage_index(focused, "bedside")
	if settle_index > 1 and focus_stage in ["ledger", "meal", "mending"]:
		var settle_row: Dictionary = focused[settle_index]
		settle_row["weight"] = 0.62
		focused[settle_index] = settle_row
	return focused


func _route_stage_index(route: Array, stage: String) -> int:
	for index in range(route.size()):
		if str(route[index].get("stage", "")) == stage:
			return index
	return -1


func _weighted_route_pose(route: Array, animated_minutes: float, route_start: int, route_bed: int, fallback_anchor: Vector2) -> Dictionary:
	if route.size() < 2:
		return {
			"anchor": fallback_anchor,
			"from_anchor": fallback_anchor,
			"to_anchor": fallback_anchor,
			"local": 0.0,
			"stage": "idle",
			"seated": false,
		}
	var total_weight: float = 0.0
	for row in route:
		total_weight += max(float(row.get("weight", 1.0)), 0.1)
	var total_span: float = max(float(route_bed - route_start), 1.0)
	var elapsed: float = clampf(animated_minutes - float(route_start), 0.0, total_span)
	var consumed: float = 0.0
	for index in range(route.size() - 1):
		var from_pose: Dictionary = route[index]
		var to_pose: Dictionary = route[index + 1]
		var stage_weight: float = max(float(to_pose.get("weight", 1.0)), 0.1)
		var segment_span: float = total_span * stage_weight / total_weight
		if elapsed <= consumed + segment_span or index == route.size() - 2:
			var local: float = 0.0 if segment_span <= 0.001 else clampf((elapsed - consumed) / segment_span, 0.0, 1.0)
			var from_anchor: Vector2 = from_pose.get("anchor", fallback_anchor)
			var to_anchor: Vector2 = to_pose.get("anchor", fallback_anchor)
			return {
				"anchor": from_anchor.lerp(to_anchor, local),
				"from_anchor": from_anchor,
				"to_anchor": to_anchor,
				"local": local,
				"stage": str(to_pose.get("stage", "idle")),
				"seated": bool(to_pose.get("seated", false)) and local >= 0.35,
			}
		consumed += segment_span
	var last_pose: Dictionary = route[route.size() - 1]
	var last_anchor: Vector2 = last_pose.get("anchor", fallback_anchor)
	return {
		"anchor": last_anchor,
		"from_anchor": last_anchor,
		"to_anchor": last_anchor,
		"local": 1.0,
		"stage": str(last_pose.get("stage", "bedside")),
		"seated": bool(last_pose.get("seated", false)),
	}


func _resident_phase_shift(slot: int, activity_name: String) -> float:
	var shift := 0.0
	if slot == 1:
		shift = -26.0
	match activity_name:
		"cooking", "warming":
			return shift - 6.0
		"ledger", "reading":
			return shift + 10.0
		"sorting_goods":
			return shift - 2.0
		"mending":
			return shift + 16.0
		"washing":
			return shift - 10.0
		_:
			return shift


func _stage_for_activity(activity_name: String) -> String:
	match activity_name:
		"cooking":
			return "kitchen"
		"warming":
			return "stoke"
		"ledger", "reading":
			return "ledger"
		"sorting_goods":
			return "sorting"
		"washing":
			return "wash"
		"mending":
			return "mending"
		"eating":
			return "meal"
		_:
			return "desk"


func _stage_prefers_seat(stage: String) -> bool:
	return stage in ["ledger", "meal", "mending", "desk", "table", "bedside"]


func _stage_anchor(stage: String, slot: int) -> Vector2:
	var offset := _slot_stage_offset(stage, slot)
	match stage:
		"entry":
			return _route_node("entry", false) + offset
		"threshold":
			return _route_node("threshold", false) + offset
		"farewell":
			return _route_node("farewell", false) + offset
		"drop":
			return _route_node("drop", false) + offset
		"cabinet":
			return _route_node("cabinet", false) + offset
		"dress_badge":
			return _route_node("farewell", false) + offset
		"take_ledger":
			return _route_node("desk", false) + offset
		"lift_bag":
			return _route_node(_bag_drop_node(), false) + offset
		"kitchen", "stoke":
			return _route_node("kitchen", false) + offset
		"ledger", "desk":
			return _route_node("desk", false) + offset
		"meal", "table":
			return _route_node("table", false) + offset
		"clear_table":
			return _route_node(_clear_table_node(), false) + offset
		"uncoat":
			return _route_node(_uncoat_node(), false) + offset
		"storage", "sorting":
			return _route_node("storage", false) + offset
		"set_bag":
			return _route_node(_bag_drop_node(), false) + offset
		"lockup":
			return _route_node(_lockup_node(), false) + offset
		"wash":
			return _route_node("wash", false) + offset
		"tool":
			return _route_node("tool", false) + offset
		"mending":
			return _route_node("mending", false) + offset
		"warming", "extinguish":
			return _route_node("warming", false) + offset
		"turn_down", "night_lamp":
			return _route_node("bedside", false) + offset
		"bedside":
			return _route_node("bedside", false) + offset
		_:
			return _route_node("desk", false) + offset


func _clear_table_node() -> String:
	return "table" if str(house_data.get("id", "")) in ["dock_house", "exchange_house"] else "desk"


func _lockup_node() -> String:
	return "cabinet" if str(house_data.get("id", "")) == "exchange_house" else "storage"


func _uncoat_node() -> String:
	return "cabinet" if str(house_data.get("id", "")) == "exchange_house" else "entry"


func _bag_drop_node() -> String:
	match str(house_data.get("id", "")):
		"dock_house":
			return "drop"
		"exchange_house":
			return "cabinet"
		_:
			return "storage"


func _slot_stage_offset(stage: String, slot: int) -> Vector2:
	if slot <= 0:
		match stage:
			"meal", "table", "clear_table":
				return Vector2(-20.0, 4.0)
			"farewell":
				return Vector2(-26.0, -14.0)
			"threshold":
				return Vector2(-6.0, -6.0)
			"dress_badge":
				return Vector2(-14.0, -8.0)
			"take_ledger":
				return Vector2(-18.0, 6.0)
			"lift_bag":
				return Vector2(-8.0, 10.0)
			"kitchen", "stoke", "extinguish":
				return Vector2(-10.0, 0.0)
			"uncoat":
				return Vector2(-6.0, -2.0)
			"set_bag", "lockup":
				return Vector2(-4.0, 2.0)
			"turn_down", "night_lamp", "bedside":
				return Vector2(-8.0, 0.0)
			_:
				return Vector2.ZERO
	match str(house_data.get("id", "")):
		"dock_house":
			match stage:
				"entry":
					return Vector2(24.0, -14.0)
				"farewell":
					return Vector2(14.0, -20.0)
				"threshold":
					return Vector2(8.0, -4.0)
				"lift_bag":
					return Vector2(104.0, -2.0)
				"sorting", "storage", "set_bag", "lockup":
					return Vector2(112.0, -12.0)
				"uncoat":
					return Vector2(18.0, -10.0)
				"kitchen", "stoke", "extinguish":
					return Vector2(28.0, 20.0)
				"meal", "table", "clear_table":
					return Vector2(36.0, -10.0)
				"turn_down", "night_lamp", "bedside":
					return Vector2(18.0, 4.0)
		"factory_house":
			match stage:
				"entry":
					return Vector2(28.0, -10.0)
				"farewell":
					return Vector2(16.0, -16.0)
				"threshold":
					return Vector2(10.0, -2.0)
				"dress_badge":
					return Vector2(14.0, -14.0)
				"lift_bag":
					return Vector2(86.0, -6.0)
				"uncoat":
					return Vector2(20.0, -10.0)
				"storage", "set_bag", "lockup":
					return Vector2(96.0, -20.0)
				"stoke", "kitchen", "extinguish":
					return Vector2(22.0, 26.0)
				"desk", "ledger", "clear_table":
					return Vector2(24.0, 10.0)
				"mending":
					return Vector2(32.0, 8.0)
				"turn_down", "night_lamp", "bedside":
					return Vector2(18.0, -2.0)
		"exchange_house":
			match stage:
				"entry":
					return Vector2(18.0, -10.0)
				"farewell":
					return Vector2(8.0, -18.0)
				"threshold":
					return Vector2(4.0, -4.0)
				"take_ledger":
					return Vector2(14.0, 6.0)
				"lift_bag":
					return Vector2(20.0, 10.0)
				"uncoat":
					return Vector2(18.0, -6.0)
				"kitchen", "extinguish":
					return Vector2(24.0, 18.0)
				"meal", "table", "clear_table":
					return Vector2(30.0, -10.0)
				"desk", "ledger":
					return Vector2(20.0, 12.0)
				"set_bag", "lockup":
					return Vector2(24.0, 2.0)
				"turn_down", "night_lamp", "bedside":
					return Vector2(18.0, 0.0)
		_:
			match stage:
				"entry":
					return Vector2(24.0, -8.0)
				"farewell":
					return Vector2(10.0, -16.0)
				"threshold":
					return Vector2(4.0, -4.0)
				"lift_bag":
					return Vector2(74.0, 6.0)
				"uncoat":
					return Vector2(18.0, -8.0)
				"wash":
					return Vector2(34.0, 2.0)
				"storage", "sorting", "set_bag", "lockup":
					return Vector2(78.0, -8.0)
				"kitchen", "stoke", "extinguish":
					return Vector2(22.0, 16.0)
				"desk", "ledger", "clear_table":
					return Vector2(20.0, 12.0)
				"mending":
					return Vector2(18.0, 8.0)
				"turn_down", "night_lamp", "bedside":
					return Vector2(14.0, 2.0)
	return house_layout.get("secondary_route_offset", Vector2(56.0, 12.0))


func _stage_motion_offset(stage: String, slot: int, progress: float) -> Vector2:
	var phase := pulse_time * (1.8 + slot * 0.2) + progress * PI
	match stage:
		"farewell":
			return Vector2(sin(phase * 1.1) * 1.0, -abs(cos(phase * 1.4)) * 2.2)
		"threshold":
			return Vector2(cos(phase * 0.7) * 0.8, sin(phase * 0.55) * 0.6)
		"dress_badge":
			return Vector2(cos(phase * 1.25) * 1.2, -abs(sin(phase * 0.9)) * 1.8)
		"take_ledger":
			return Vector2(sin(phase * 0.9) * 1.4, cos(phase * 0.8) * 0.9)
		"lift_bag":
			return Vector2(cos(phase * 0.85) * 1.0, abs(sin(phase * 0.75)) * 2.4)
		"kitchen", "stoke", "extinguish":
			return Vector2(sin(phase * 1.4) * 4.0, -abs(cos(phase)) * 2.0)
		"uncoat":
			return Vector2(cos(phase * 0.9) * 1.6, sin(phase * 0.7) * 1.2)
		"ledger", "desk":
			return Vector2(sin(phase) * 1.5, cos(phase * 0.8) * 1.2)
		"meal", "table", "clear_table":
			return Vector2(cos(phase) * 1.8, sin(phase * 0.7) * 1.0)
		"sorting", "storage", "cabinet", "set_bag", "lockup":
			return Vector2(sin(phase * 1.2) * 2.2, abs(cos(phase)) * 2.0)
		"wash":
			return Vector2(sin(phase) * 1.4, abs(cos(phase * 1.1)) * 2.6)
		"mending", "tool":
			return Vector2(cos(phase * 1.3) * 1.4, sin(phase * 1.6) * 1.0)
		"turn_down":
			return Vector2(sin(phase * 0.8) * 1.2, -abs(cos(phase * 0.65)) * 1.2)
		"night_lamp":
			return Vector2(cos(phase * 0.6) * 0.8, sin(phase * 0.55) * 0.6)
		"bedside":
			return Vector2(sin(phase * 0.5) * 0.8, cos(phase * 0.45) * 0.6)
		_:
			return Vector2.ZERO


func _route_node(node_name: String, secondary: bool) -> Vector2:
	var nodes: Dictionary = house_layout.get("route_nodes", {})
	var offset := Vector2.ZERO
	if secondary:
		offset = house_layout.get("secondary_route_offset", Vector2(72.0, 18.0))
	var fallback := _activity_anchor("ledger", false)
	match node_name:
		"entry":
			fallback = Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 744.0))) + Vector2(-32.0, -28.0)
		"threshold":
			fallback = Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 744.0))) + Vector2(-6.0, -8.0)
		"farewell":
			fallback = Vector2(float(house_layout.get("entry_x", 664.0)), float(house_layout.get("entry_y", 744.0))) + Vector2(-46.0, -42.0)
		"kitchen":
			fallback = _activity_anchor("cooking", false)
		"desk", "table":
			fallback = _activity_anchor("ledger", false)
		"storage", "drop", "cabinet":
			fallback = _activity_anchor("sorting_goods", false)
		"wash":
			fallback = _activity_anchor("washing", false)
		"tool", "mending":
			fallback = _activity_anchor("mending", false)
		"warming":
			fallback = _activity_anchor("warming", false)
		"bedside":
			fallback = Vector2(float(house_layout.get("bed_x", 282.0)) + 58.0, float(house_layout.get("bed_y", 256.0)) + 56.0)
	var node: Vector2 = nodes.get(node_name, fallback)
	return node + offset


func _draw_sleeping_shape(anchor: Vector2) -> void:
	draw_rect(Rect2(anchor + Vector2(-38, -8), Vector2(102, 26)), house_theme.get("blanket", Color("8f3f35")).lightened(0.08), true)
	draw_rect(Rect2(anchor + Vector2(-16, -14), Vector2(28, 18)), Color("dbc79f"), true)
	draw_rect(Rect2(anchor + Vector2(14, -2), Vector2(24, 16)), Color(0, 0, 0, 0.08), true)
	draw_circle(anchor + Vector2(50, 6), 10.0, Color(0, 0, 0, 0.12))


func _draw_resident_sprite(anchor: Vector2, seated: bool, facing_sign: float, slot: int = 0, stage: String = "") -> void:
	var bob := sin(pulse_time * 2.1) * 1.4
	draw_circle(anchor + Vector2(0, 18), 16.0, Color(0, 0, 0, 0.16))
	if CHARACTER_SHEET != null:
		var frame_index := _resident_frame_index(slot)
		var source := Rect2(frame_index * 16.0, 0.0, 16.0, 16.0)
		var sprite_height := 42.0 if seated else 48.0
		var y_offset := -34.0 + bob if seated else -46.0 + bob
		var size := Vector2(42.0, sprite_height)
		var draw_pos := anchor + Vector2(-size.x * 0.5, y_offset)
		draw_texture_rect_region(CHARACTER_SHEET, Rect2(draw_pos, size), source, Color(1, 1, 1, 0.98), false)
		if seated:
			draw_rect(Rect2(anchor + Vector2(-18, 28), Vector2(36, 8)), Color("4c3220"), true)
		else:
			draw_line(anchor + Vector2(-8, 14), anchor + Vector2(-14 * facing_sign, 28), Color("4e3423"), 2.4)
			draw_line(anchor + Vector2(8, 14), anchor + Vector2(14 * facing_sign, 26), Color("4e3423"), 2.4)
		_draw_resident_hand_prop(anchor, stage, facing_sign, seated, bob)
		return
	var cloak: Color = house_theme.get("resident_cloak", Color("6d4a33"))
	var shell: Color = house_theme.get("resident_shell", Color("4e5e2f"))
	var body_height := 42.0 if seated else 52.0
	var leg_y := 24.0 if seated else 32.0
	draw_circle(anchor + Vector2(0, -26 + bob), 12.0, Color("dbc79f"))
	draw_circle(anchor + Vector2(4 * facing_sign, -28 + bob), 1.6, Color("2b1c12"))
	draw_rect(Rect2(anchor + Vector2(-14, -14 + bob), Vector2(28, body_height)), cloak, true)
	draw_rect(Rect2(anchor + Vector2(-8, -6 + bob), Vector2(22, 26)), shell, true)
	draw_rect(Rect2(anchor + Vector2(-12, leg_y), Vector2(8, 18)), Color("4e3423"), true)
	draw_rect(Rect2(anchor + Vector2(4, leg_y), Vector2(8, 18)), Color("4e3423"), true)
	if seated:
		draw_rect(Rect2(anchor + Vector2(-22, 28), Vector2(44, 8)), Color("4c3220"), true)
	else:
		draw_line(anchor + Vector2(-10, 6), anchor + Vector2(-18 * facing_sign, 20), Color("4e3423"), 3.0)
		draw_line(anchor + Vector2(10, 6), anchor + Vector2(18 * facing_sign, 18), Color("4e3423"), 3.0)
	_draw_resident_hand_prop(anchor, stage, facing_sign, seated, bob)


func _draw_resident_hand_prop(anchor: Vector2, stage: String, facing_sign: float, seated: bool, bob: float) -> void:
	var hand_anchor: Vector2 = anchor + Vector2(12.0 * facing_sign, -4.0 + bob * 0.45)
	if seated:
		hand_anchor += Vector2(4.0 * facing_sign, 6.0)
	var house_id: String = str(house_data.get("id", ""))
	match stage:
		"dress_badge":
			draw_line(hand_anchor + Vector2(-2.0, -8.0), hand_anchor + Vector2(6.0, 6.0), Color("604736"), 1.4)
			draw_rect(Rect2(hand_anchor + Vector2(2.0, 2.0), Vector2(10.0, 8.0)), Color("c28f45"), true)
			draw_rect(Rect2(hand_anchor + Vector2(4.0, 4.0), Vector2(6.0, 4.0)), Color("ebddb2"), true)
		"take_ledger":
			draw_rect(Rect2(hand_anchor + Vector2(-12.0, -7.0), Vector2(18.0, 14.0)), Color("ceb78d"), true)
			draw_line(hand_anchor + Vector2(-8.0, -2.0), hand_anchor + Vector2(4.0, -2.0), Color("7c5532"), 1.0)
			draw_rect(Rect2(hand_anchor + Vector2(8.0, -4.0), Vector2(6.0, 10.0)), Color("8b643f"), true)
		"lift_bag":
			_draw_satchel(hand_anchor + Vector2(-14.0, -8.0))
			draw_line(hand_anchor + Vector2(-2.0, -4.0), hand_anchor + Vector2(10.0, 10.0), Color("cdb288"), 1.2)
		"farewell":
			if house_id == "exchange_house":
				draw_rect(Rect2(hand_anchor + Vector2(-10.0, -4.0), Vector2(14.0, 8.0)), Color("e2d5b2"), true)
				draw_circle(hand_anchor + Vector2(10.0, 0.0), 3.0, Color("d4b661"))
			elif house_id == "factory_house":
				draw_rect(Rect2(hand_anchor + Vector2(-8.0, -4.0), Vector2(12.0, 8.0)), Color("8e9498"), true)
				draw_line(hand_anchor + Vector2(6.0, -2.0), hand_anchor + Vector2(12.0, 6.0), Color("e2d0a1"), 1.0)
			else:
				draw_line(hand_anchor + Vector2(-6.0, -6.0), hand_anchor + Vector2(10.0, 6.0), Color("efe2c1"), 1.4)
				draw_rect(Rect2(hand_anchor + Vector2(2.0, 2.0), Vector2(8.0, 6.0)), Color("856240"), true)
		"threshold":
			if house_id == "dock_house":
				_draw_satchel(hand_anchor + Vector2(-12.0, -8.0))
				draw_line(hand_anchor + Vector2(10.0, 4.0), hand_anchor + Vector2(18.0, 10.0), Color("d0b384"), 1.4)
			elif house_id == "exchange_house":
				draw_rect(Rect2(hand_anchor + Vector2(-12.0, -6.0), Vector2(18.0, 12.0)), Color("d9c9a4"), true)
				draw_circle(hand_anchor + Vector2(12.0, -2.0), 3.0, Color("d5b765"))
			elif house_id == "factory_house":
				draw_rect(Rect2(hand_anchor + Vector2(-10.0, -6.0), Vector2(14.0, 10.0)), Color("8a8f92"), true)
				draw_rect(Rect2(hand_anchor + Vector2(6.0, -2.0), Vector2(8.0, 8.0)), Color("c48a46"), true)
			else:
				draw_rect(Rect2(hand_anchor + Vector2(-10.0, -6.0), Vector2(14.0, 10.0)), Color("8b6237"), true)
				draw_circle(hand_anchor + Vector2(10.0, 0.0), 4.0, Color("e5d7b1"))
		"uncoat":
			if house_id == "exchange_house":
				draw_rect(Rect2(hand_anchor + Vector2(-11.0, -8.0), Vector2(16.0, 16.0)), Color("7c5aa4"), true)
				draw_line(hand_anchor + Vector2(-6.0, -6.0), hand_anchor + Vector2(6.0, 6.0), Color("f0ddb1"), 1.2)
			elif house_id == "factory_house":
				draw_rect(Rect2(hand_anchor + Vector2(-10.0, -8.0), Vector2(15.0, 16.0)), Color("7b5a45"), true)
				draw_rect(Rect2(hand_anchor + Vector2(5.0, -2.0), Vector2(6.0, 8.0)), Color("9b9ea2"), true)
			else:
				draw_rect(Rect2(hand_anchor + Vector2(-10.0, -8.0), Vector2(15.0, 16.0)), house_theme.get("resident_cloak", Color("72523a")), true)
				draw_line(hand_anchor + Vector2(-4.0, -6.0), hand_anchor + Vector2(6.0, 6.0), Color("5d412b"), 1.4)
		"set_bag":
			_draw_satchel(hand_anchor + Vector2(-12.0, -6.0))
			if house_id not in ["dock_house", "factory_house", "exchange_house"]:
				draw_line(hand_anchor + Vector2(-8.0, 4.0), hand_anchor + Vector2(4.0, 10.0), Color("c3b08a"), 1.0)
			elif house_id == "factory_house":
				draw_rect(Rect2(hand_anchor + Vector2(6.0, -2.0), Vector2(6.0, 8.0)), Color("b8844e"), true)
		"ledger", "desk":
			draw_rect(Rect2(hand_anchor + Vector2(-12.0, -6.0), Vector2(18.0, 12.0)), Color("ccb78a"), true)
			draw_line(hand_anchor + Vector2(-8.0, -2.0), hand_anchor + Vector2(4.0, -2.0), Color("7c5532"), 1.2)
		"table", "meal":
			draw_circle(hand_anchor, 7.0, Color("c18a46"))
			draw_circle(hand_anchor + Vector2(0.0, -1.0), 4.0, Color("ead8b1"))
		"clear_table":
			draw_rect(Rect2(hand_anchor + Vector2(-11.0, -5.0), Vector2(16.0, 10.0)), Color("d7c6a2"), true)
			draw_line(hand_anchor + Vector2(-6.0, 4.0), hand_anchor + Vector2(6.0, -4.0), Color("8d6a44"), 1.4)
		"kitchen", "stoke":
			draw_rect(Rect2(hand_anchor + Vector2(-10.0, -5.0), Vector2(16.0, 10.0)), Color("5f5b57"), true)
			draw_line(hand_anchor + Vector2(6.0, 0.0), hand_anchor + Vector2(16.0 * facing_sign, -2.0), Color("8e6d45"), 1.6)
		"extinguish":
			draw_circle(hand_anchor + Vector2(-4.0, 2.0), 5.0, Color("7e705b"))
			draw_line(hand_anchor + Vector2(0.0, 2.0), hand_anchor + Vector2(16.0 * facing_sign, -6.0), Color("71563e"), 1.8)
		"sorting", "storage", "drop", "cabinet":
			draw_rect(Rect2(hand_anchor + Vector2(-10.0, -8.0), Vector2(16.0, 16.0)), Color("8b6237"), true)
			draw_rect(Rect2(hand_anchor + Vector2(-6.0, -4.0), Vector2(8.0, 8.0)), Color("b68852"), true)
		"lockup":
			draw_circle(hand_anchor + Vector2(-2.0, 0.0), 4.0, Color("d2b05a"))
			draw_line(hand_anchor + Vector2(2.0, 2.0), hand_anchor + Vector2(11.0, 10.0), Color("d2b05a"), 1.6)
			draw_rect(Rect2(hand_anchor + Vector2(6.0, -5.0), Vector2(9.0, 10.0)), Color("7f603e"), true)
			if house_id == "exchange_house":
				draw_circle(hand_anchor + Vector2(16.0, -2.0), 3.0, Color("f0ddb1"))
			elif house_id == "factory_house":
				draw_rect(Rect2(hand_anchor + Vector2(12.0, -4.0), Vector2(8.0, 8.0)), Color("8a8f93"), true)
		"wash":
			draw_rect(Rect2(hand_anchor + Vector2(-12.0, -5.0), Vector2(18.0, 10.0)), Color("d6d0bf"), true)
			draw_circle(hand_anchor + Vector2(8.0, 6.0), 2.2, Color("9bc4d8"))
		"tool", "mending":
			draw_line(hand_anchor + Vector2(-8.0, 4.0), hand_anchor + Vector2(8.0, -4.0), Color("8d8e90"), 2.0)
			draw_circle(hand_anchor + Vector2(-10.0, 6.0), 3.2, Color("6a4b38"))
		"turn_down":
			if house_id not in ["dock_house", "factory_house", "exchange_house"]:
				draw_rect(Rect2(hand_anchor + Vector2(-11.0, -6.0), Vector2(18.0, 12.0)), Color("9f7d68"), true)
				draw_line(hand_anchor + Vector2(-8.0, -2.0), hand_anchor + Vector2(4.0, 4.0), Color("d8c39c"), 1.2)
			elif house_id == "exchange_house":
				draw_rect(Rect2(hand_anchor + Vector2(-11.0, -6.0), Vector2(18.0, 12.0)), Color("d8c8a8"), true)
				draw_line(hand_anchor + Vector2(-8.0, -2.0), hand_anchor + Vector2(4.0, 4.0), Color("f6ead0"), 1.2)
			else:
				draw_rect(Rect2(hand_anchor + Vector2(-11.0, -6.0), Vector2(18.0, 12.0)), Color("c0aa7d"), true)
				draw_line(hand_anchor + Vector2(-8.0, -2.0), hand_anchor + Vector2(4.0, 4.0), Color("e7d6b2"), 1.2)
		"night_lamp":
			draw_rect(Rect2(hand_anchor + Vector2(-7.0, -6.0), Vector2(8.0, 12.0)), Color("dfcfaa"), true)
			draw_circle(hand_anchor + Vector2(0.0, -8.0), 3.0, Color(1.0, 0.84, 0.44, 0.7))
		"bedside":
			draw_rect(Rect2(hand_anchor + Vector2(-9.0, -6.0), Vector2(14.0, 12.0)), Color("d4c3a0"), true)
			draw_circle(hand_anchor + Vector2(6.0, -4.0), 3.0, Color(1.0, 0.84, 0.46, 0.72))


func _lamp_strength() -> float:
	var base := clampf(1.0 - current_light_level, 0.0, 1.0)
	if bool(house_state.get("lights_on", false)):
		base = max(base, 0.82)
	if current_period == "night":
		base = max(base, 0.9)
	elif current_period == "dusk":
		base = max(base, 0.62)
	var prep_dim: float = _sleep_prep_dim_strength()
	if prep_dim > 0.0:
		base = lerpf(base, 0.18 if current_period == "night" else 0.26, prep_dim)
	return base


func _window_glow() -> float:
	return 0.02 + _lamp_strength() * 0.28 + float(house_state.get("window_glow_boost", 0.0)) * 0.36


func _fire_strength() -> float:
	var fire := 1.0 if bool(house_state.get("lights_on", false)) else 0.72 if current_period in ["night", "dusk", "dawn"] else 0.4
	fire = max(fire, 0.16 + _residual_warmth_strength() * 0.62)
	var prep_dim: float = _sleep_prep_dim_strength()
	if prep_dim > 0.0:
		fire = lerpf(fire, 0.12, min(prep_dim + 0.18, 0.92))
	return fire


func _doorstep_transition_strength() -> float:
	return clampf(float(house_state.get("doorstep_alpha", 0.0)), 0.0, 1.0)


func _residual_warmth_strength() -> float:
	return clampf(float(house_state.get("residual_warmth", 0.0)), 0.0, 1.0)


func _breakfast_leftovers_strength() -> float:
	return clampf(float(house_state.get("breakfast_leftovers", 0.0)), 0.0, 1.0)


func _sleep_prep_dim_strength() -> float:
	var residents_home: int = int(house_state.get("residents_home", 0))
	if residents_home <= 0 or current_period not in ["dusk", "night"]:
		return 0.0
	var fade: float = 0.0
	var primary_pose: Dictionary = _resident_pose_for_slot(0, str(house_state.get("primary_activity", "resting")), str(house_state.get("primary_state", "resting")))
	fade = max(fade, _sleep_stage_dim(str(primary_pose.get("stage", ""))))
	if residents_home > 1:
		var secondary_home_state: String = "evening_home" if str(house_state.get("primary_state", "resting")) == "evening_home" else "resting"
		var secondary_pose: Dictionary = _resident_pose_for_slot(1, str(house_state.get("secondary_activity", "resting")), secondary_home_state)
		fade = max(fade, _sleep_stage_dim(str(secondary_pose.get("stage", ""))))
	return fade


func _sleep_stage_dim(stage: String) -> float:
	match stage:
		"night_lamp":
			return 0.82
		"extinguish":
			return 0.78
		"lockup":
			return 0.34
		"turn_down":
			return 0.56
		"bedside":
			return 0.42 if current_clock_minutes >= int(house_layout.get("route_bed_minutes", 21 * 60 + 30)) - 12 else 0.0
		_:
			return 0.0


func _draw_pillow_stack(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(36, 18)), Color("efe7d2"), true)
	draw_rect(Rect2(origin + Vector2(40, 2), Vector2(42, 16)), Color("e6ddc9"), true)
	draw_line(origin + Vector2(12, 0), origin + Vector2(12, 18), Color(0, 0, 0, 0.08), 1.0)


func _draw_cooking_props(origin: Vector2) -> void:
	_draw_food_item(origin + Vector2(-10, -12), Rect2(0, 0, 16, 17), 2.0)
	_draw_food_item(origin + Vector2(18, -8), Rect2(18, 0, 16, 17), 1.8)
	_draw_food_item(origin + Vector2(44, -10), Rect2(54, 0, 18, 17), 1.8)


func _draw_cooking_steam(origin: Vector2, strength: float) -> void:
	if strength <= 0.05:
		return
	for index in range(3):
		var phase := pulse_time * (1.5 + index * 0.2) + index * 0.9
		var drift := sin(phase) * 10.0
		var lift := cos(phase * 0.8) * 6.0
		draw_circle(
			origin + Vector2(index * 10.0 - 8.0 + drift, -index * 18.0 + lift),
			8.0 + index * 2.0,
			Color(0.92, 0.9, 0.84, 0.1 + strength * 0.12)
		)


func _draw_breakfast_leftovers(kitchen_center: Vector2) -> void:
	var leftovers: float = _breakfast_leftovers_strength()
	if leftovers <= 0.04:
		return
	var tray_anchor: Vector2 = kitchen_center + Vector2(-66.0, 78.0)
	draw_rect(Rect2(tray_anchor, Vector2(62.0, 18.0)), Color(0.42, 0.3, 0.2, 0.52 + leftovers * 0.18), true)
	draw_circle(tray_anchor + Vector2(16.0, -2.0), 8.0, Color(0.76, 0.72, 0.58, 0.56 + leftovers * 0.18))
	draw_circle(tray_anchor + Vector2(40.0, 0.0), 6.0, Color(0.34, 0.36, 0.38, 0.52 + leftovers * 0.22))
	draw_rect(Rect2(tray_anchor + Vector2(34.0, -6.0), Vector2(16.0, 4.0)), Color(0.8, 0.72, 0.54, 0.54 + leftovers * 0.18), true)
	draw_line(tray_anchor + Vector2(6.0, 22.0), tray_anchor + Vector2(26.0, 30.0), Color(0.28, 0.2, 0.14, leftovers * 0.42), 1.2)
	draw_line(tray_anchor + Vector2(30.0, 24.0), tray_anchor + Vector2(44.0, 32.0), Color(0.28, 0.2, 0.14, leftovers * 0.32), 1.0)
	_draw_cooking_steam(kitchen_center + Vector2(-18.0, -112.0), leftovers * 0.42 + _residual_warmth_strength() * 0.32)


func _draw_ledger_set(origin: Vector2) -> void:
	draw_rect(Rect2(origin + Vector2(-48, -16), Vector2(44, 28)), Color("5a3d29"), true)
	draw_rect(Rect2(origin + Vector2(-44, -12), Vector2(36, 20)), Color("e7d8b3"), true)
	draw_line(origin + Vector2(-38, -4), origin + Vector2(-16, -4), Color("8f2f33"), 1.6)
	draw_line(origin + Vector2(-38, 2), origin + Vector2(-10, 2), Color("8f2f33"), 1.4)
	_draw_other_item(origin + Vector2(0, -18), Rect2(84, 0, 12, 12), 2.2)
	_draw_other_item(origin + Vector2(26, -18), Rect2(36, 0, 12, 12), 2.0)


func _draw_shelf_items(origin: Vector2, count: int) -> void:
	for index in range(count):
		var base := origin + Vector2(index * 28.0, 0.0)
		match index % 4:
			0:
				_draw_other_item(base, Rect2(36, 0, 12, 12), 1.8)
			1:
				_draw_other_item(base, Rect2(60, 0, 12, 12), 1.8)
			2:
				_draw_food_item(base + Vector2(0, 1), Rect2(18, 0, 16, 17), 1.4)
			_:
				draw_rect(Rect2(base, Vector2(14, 18)), Color("8f6a42"), true)
				draw_rect(Rect2(base + Vector2(4, 4), Vector2(6, 10)), Color("f0deaf"), true)


func _draw_wall_hangings() -> void:
	var colors := [house_theme.get("accent", Color("8f2f33")), Color("7b6c2f"), Color("36586c")]
	for index in range(3):
		var origin := Vector2(442 + index * 132.0, 188)
		draw_line(origin, origin + Vector2(0, 56), Color("4b2f1e"), 2.0)
		draw_colored_polygon(PackedVector2Array([origin + Vector2(-18, 8), origin + Vector2(18, 8), origin + Vector2(0, 56)]), colors[index % colors.size()])


func _draw_hanging_coats(origin: Vector2, count: int) -> void:
	var coat_total: int = min(count, 3)
	for index in range(coat_total):
		var hook := origin + Vector2(index * 28.0, 0.0)
		draw_line(hook, hook + Vector2(0, 14), Color("4b2f1e"), 2.0)
		draw_rect(
			Rect2(hook + Vector2(-8, 14), Vector2(16, 28)),
			house_theme.get("resident_cloak", Color("7b5337")).darkened(index * 0.08),
			true
		)
		draw_rect(Rect2(hook + Vector2(-4, 16), Vector2(8, 8)), Color(0.86, 0.78, 0.62, 0.22), true)


func _draw_bedside_stool(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(28, 18)), Color("825b39"), true)
	draw_rect(Rect2(pos + Vector2(4, 18), Vector2(4, 18)), Color("4e3423"), true)
	draw_rect(Rect2(pos + Vector2(20, 18), Vector2(4, 18)), Color("4e3423"), true)


func _draw_hanging_herbs(origin: Vector2) -> void:
	for index in range(3):
		var x := origin.x + index * 22.0
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 24), Color("5b3a24"), 1.8)
		draw_circle(Vector2(x - 3, origin.y + 28), 6.0, Color("70854d"))
		draw_circle(Vector2(x + 4, origin.y + 30), 5.0, Color("87a05a"))


func _draw_kettle_hook(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 28), Color("4d392b"), 2.0)
	draw_arc(origin + Vector2(0, 34), 7.0, 0.2, PI + 0.9, 12, Color("615044"), 2.0)
	draw_circle(origin + Vector2(0, 42), 10.0, Color("4b423a"))
	draw_circle(origin + Vector2(0, 42), 6.0, Color("6f655c"))


func _draw_candle_cluster(origin: Vector2) -> void:
	for offset in [0.0, 14.0, 28.0]:
		draw_rect(Rect2(origin + Vector2(offset, 0), Vector2(5, 16)), Color("efe2b8"), true)
		draw_rect(Rect2(origin + Vector2(offset + 1, -3 + sin(pulse_time * 3.0 + offset) * 1.2), Vector2(3, 4)), Color("f6b54b"), true)


func _draw_cabinet(origin: Vector2) -> void:
	draw_rect(Rect2(origin + Vector2(-32, -84), Vector2(64, 84)), Color("6b482b"), true)
	draw_rect(Rect2(origin + Vector2(-26, -76), Vector2(24, 64)), Color("7d5a36"), true)
	draw_rect(Rect2(origin + Vector2(2, -76), Vector2(24, 64)), Color("7d5a36"), true)
	draw_circle(origin + Vector2(-10, -42), 3.0, Color("caa562"))
	draw_circle(origin + Vector2(10, -42), 3.0, Color("caa562"))


func _draw_sack_stack(origin: Vector2) -> void:
	draw_circle(origin + Vector2(-18, 0), 16.0, Color("9f8760"))
	draw_circle(origin + Vector2(4, -6), 14.0, Color("b19a73"))
	draw_circle(origin + Vector2(20, 6), 12.0, Color("927750"))
	draw_line(origin + Vector2(-18, -10), origin + Vector2(-18, 8), Color("6d5638"), 1.0)


func _draw_satchel(origin: Vector2) -> void:
	draw_rect(Rect2(origin + Vector2(-12, -8), Vector2(24, 18)), Color("7a5538"), true)
	draw_rect(Rect2(origin + Vector2(-8, -4), Vector2(16, 10)), Color("8b6544"), true)
	draw_arc(origin + Vector2(0, -6), 8.0, PI, TAU, 10, Color("d1b27a"), 2.0)


func _draw_broom(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(22, -84), Color("7b5b37"), 3.0)
	for index in range(5):
		draw_line(origin + Vector2(-8 + index * 4, 0), origin + Vector2(0, 18), Color("aa8e55"), 1.3)


func _draw_wall_crock(origin: Vector2) -> void:
	draw_circle(origin, 12.0, Color("6c5040"))
	draw_circle(origin, 8.0, Color("816553"))
	draw_line(origin + Vector2(-6, 0), origin + Vector2(6, 0), Color(1, 1, 1, 0.08), 1.0)


func _draw_rope_bundle(origin: Vector2) -> void:
	draw_arc(origin, 18.0, 0.0, TAU, 24, Color("c8b27b"), 2.2)
	draw_arc(origin + Vector2(2, 0), 10.0, 0.0, TAU, 18, Color("9b8256"), 2.0)


func _draw_tool_rack(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(72, 8)), Color("4a3423"), true)
	for x in [12.0, 34.0, 56.0]:
		draw_line(Vector2(origin.x + x, origin.y + 8), Vector2(origin.x + x, origin.y + 32), Color("4a3423"), 2.0)
	draw_line(origin + Vector2(12, 26), origin + Vector2(6, 40), Color("8a755d"), 2.0)
	draw_line(origin + Vector2(34, 26), origin + Vector2(40, 40), Color("8a755d"), 2.0)
	draw_rect(Rect2(origin + Vector2(52, 28), Vector2(10, 12)), Color("6d5c52"), true)


func _draw_book_stack(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(30, 8)), Color("8f2f33"), true)
	draw_rect(Rect2(origin + Vector2(2, -8), Vector2(26, 8)), Color("45627c"), true)
	draw_rect(Rect2(origin + Vector2(5, -16), Vector2(22, 8)), Color("7b6c2f"), true)


func _draw_laundry_basket(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(34, 22)), Color("8d6944"), true)
	draw_arc(origin + Vector2(17, 0), 12.0, PI, TAU, 12, Color("d2bc8a"), 2.0)


func _draw_food_item(pos: Vector2, region: Rect2, scale_value: float) -> void:
	if FOOD_SHEET == null:
		return
	draw_texture_rect_region(FOOD_SHEET, Rect2(pos, region.size * scale_value), region, Color.WHITE, false)


func _draw_other_item(pos: Vector2, region: Rect2, scale_value: float) -> void:
	if OTHER_ITEMS_SHEET == null:
		return
	draw_texture_rect_region(OTHER_ITEMS_SHEET, Rect2(pos, region.size * scale_value), region, Color.WHITE, false)


func _draw_item_texture(texture: Texture2D, pos: Vector2, scale_value: float) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(pos, Vector2(texture.get_width(), texture.get_height()) * scale_value), false)


func _draw_scaled_texture(texture: Texture2D, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, modulate)


func _draw_region_texture(texture: Texture2D, source_rect: Rect2, target_rect: Rect2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	draw_texture_rect_region(texture, target_rect, source_rect, modulate, false)


func _draw_weapon_item(pos: Vector2, region: Rect2, scale_value: float) -> void:
	if WEAPON_SHEET == null:
		return
	draw_texture_rect_region(WEAPON_SHEET, Rect2(pos, region.size * scale_value), region, Color.WHITE, false)


func _theme_for_house(data: Dictionary) -> Dictionary:
	match str(data.get("id", "")):
		"dock_house":
			return {"void":Color("17140f"),"floor":Color("564230"),"plank_overlay":Color(0.36,0.28,0.22,0.11),"wall_top":Color("5b4537"),"wall_side":Color("513d31"),"wall_bottom":Color("37281f"),"post":Color("725746"),"trim":Color("7b6756"),"wood":Color("6b4f34"),"wood_dark":Color("563d28"),"stone":Color("4f565b"),"accent":Color("35576a"),"rug":Color("375869"),"rug_trim":Color("d9c59a"),"blanket":Color("477189"),"sheet":Color("d2d4d7"),"chair":Color("65503f"),"beam":Color("473527"),"light":Color(0.92,0.78,0.54,0.11),"window_frame":Color("20333f"),"cloth":Color("617b8c"),"resident_cloak":Color("59748a"),"resident_shell":Color("506033")}
		"factory_house":
			return {"void":Color("16120f"),"floor":Color("514033"),"plank_overlay":Color(0.33,0.25,0.18,0.11),"wall_top":Color("60493d"),"wall_side":Color("58443a"),"wall_bottom":Color("30231b"),"post":Color("70584d"),"trim":Color("85664d"),"wood":Color("674b35"),"wood_dark":Color("503824"),"stone":Color("625b59"),"accent":Color("90513a"),"rug":Color("6b382e"),"rug_trim":Color("d9c08b"),"blanket":Color("8f5b45"),"sheet":Color("8e8a78"),"chair":Color("735640"),"beam":Color("3d2d23"),"light":Color(0.96,0.72,0.34,0.12),"window_frame":Color("2a2f35"),"cloth":Color("8f5d43"),"resident_cloak":Color("80543c"),"resident_shell":Color("555c34")}
		"exchange_house":
			return {"void":Color("18130d"),"floor":Color("614a35"),"plank_overlay":Color(0.46,0.32,0.21,0.08),"wall_top":Color("7b6044"),"wall_side":Color("654f3c"),"wall_bottom":Color("403022"),"post":Color("8e6b4f"),"trim":Color("9f7d5a"),"wood":Color("7f5a3a"),"wood_dark":Color("64472d"),"stone":Color("5a4f49"),"accent":Color("6a4f88"),"rug":Color("5b3f7e"),"rug_trim":Color("f1ddb0"),"blanket":Color("7c5aa4"),"sheet":Color("d5cfbe"),"chair":Color("886749"),"beam":Color("513a2a"),"light":Color(1.0,0.86,0.48,0.1),"window_frame":Color("233144"),"cloth":Color("7f60a0"),"resident_cloak":Color("7758a0"),"resident_shell":Color("4d5d34")}
		"stock_exchange":
			return {"void":Color("0f131a"),"floor":Color("1f252c"),"plank_overlay":Color(0.25,0.36,0.45,0.08),"wall_top":Color("1a2028"),"wall_side":Color("141920"),"wall_bottom":Color("0d1015"),"post":Color("2c333d"),"trim":Color("d8b982"),"wood":Color("443324"),"wood_dark":Color("2a1f16"),"stone":Color("20262d"),"accent":Color("6bb6d9"),"rug":Color("27445e"),"rug_trim":Color("f1ddb0"),"blanket":Color("4d687d"),"sheet":Color("d3d7dc"),"chair":Color("4c3a30"),"beam":Color("1c232a"),"light":Color(0.72,0.86,1.0,0.14),"window_frame":Color("1f2935"),"cloth":Color("41586b"),"resident_cloak":Color("43596c"),"resident_shell":Color("37402d")}
		_:
			return {"void":Color("1c130d"),"floor":Color("5c432d"),"plank_overlay":Color(0.43,0.3,0.2,0.09),"wall_top":Color("725238"),"wall_side":Color("6a4a32"),"wall_bottom":Color("473121"),"post":Color("825f43"),"trim":Color("8f6a48"),"wood":Color("6b472b"),"wood_dark":Color("654529"),"stone":Color("655141"),"accent":Color("8f2f33"),"rug":Color("8f3b2e"),"rug_trim":Color("f1d79f"),"blanket":Color("8f3f35"),"sheet":Color("8d8a74"),"chair":Color("7b5738"),"beam":Color("442d1d"),"light":Color(1.0,0.83,0.45,0.1),"window_frame":Color("2e352b"),"cloth":Color("8c604a"),"resident_cloak":Color("7b5337"),"resident_shell":Color("50612e")}


func _layout_for_house(data: Dictionary) -> Dictionary:
	match str(data.get("id", "")):
		"dock_house":
			return {
				"entry_x": 636.0,
				"entry_y": 744.0,
				"bed_x": 286.0,
				"bed_y": 248.0,
				"kitchen_x": 1046.0,
				"kitchen_y": 254.0,
				"storage_x": 1018.0,
				"storage_y": 628.0,
				"desk_x": 520.0,
				"desk_y": 360.0,
				"bed_style": "plain",
				"rug_style": "runner",
				"fish_rack": true,
				"crate_stack": true,
				"laundry": true,
				"partition": true,
				"partition_x": 814.0,
				"partition_style": "rack",
				"curtains": false,
				"bookcase": false,
				"book_stack": false,
				"wash_basin": false,
				"shelves": [Rect2(180, 138, 144, 10), Rect2(520, 138, 150, 10), Rect2(902, 138, 214, 10), Rect2(1020, 474, 150, 10)],
				"windows": [Rect2(132, 128, 108, 86), Rect2(1076, 128, 112, 86)],
				"lamp_pools": [Vector2(194, 170), Vector2(1128, 170), Vector2(1034, 250)],
				"route_start_minutes": 18 * 60 + 15,
				"route_bed_minutes": 21 * 60 + 35,
				"secondary_route_offset": Vector2(54.0, 10.0),
				"route_nodes": {
					"entry": Vector2(624.0, 690.0),
					"drop": Vector2(912.0, 654.0),
					"kitchen": Vector2(972.0, 330.0),
					"table": Vector2(470.0, 486.0),
					"desk": Vector2(520.0, 396.0),
					"storage": Vector2(980.0, 650.0),
					"bedside": Vector2(364.0, 332.0),
					"warming": Vector2(976.0, 330.0)
				},
				"bed_title": "舷边窄床",
				"bed_subtitle": "木床贴着湿木板，翻身时还能听见船绳轻响。",
				"kitchen_title": "海风炉台",
				"kitchen_subtitle": "鱼汤、盐面包和潮气都在这里重新热起来。",
				"storage_title": "双层货架",
				"storage_subtitle": "绳箱、盐桶、旧帆布和零散货样塞满了后墙。",
				"desk_title": "航账桌",
				"desk_subtitle": "工钱、船讯和下一批卸货单都摊在窄桌上。"
			}
		"factory_house":
			return {
				"entry_x": 688.0,
				"entry_y": 744.0,
				"bed_x": 248.0,
				"bed_y": 246.0,
				"kitchen_x": 986.0,
				"kitchen_y": 250.0,
				"storage_x": 1008.0,
				"storage_y": 626.0,
				"desk_x": 628.0,
				"desk_y": 404.0,
				"bed_style": "bunk",
				"rug_style": "runner",
				"locker": true,
				"book_stack": false,
				"bookcase": false,
				"laundry": true,
				"wash_basin": true,
				"tools_on_desk": true,
				"partition": true,
				"partition_x": 780.0,
				"partition_style": "iron",
				"curtains": false,
				"shelves": [Rect2(174, 138, 118, 10), Rect2(500, 138, 142, 10), Rect2(906, 138, 152, 10), Rect2(1022, 472, 142, 10)],
				"windows": [Rect2(138, 128, 104, 82), Rect2(1082, 128, 104, 82)],
				"lamp_pools": [Vector2(190, 170), Vector2(1126, 170), Vector2(624, 372)],
				"route_start_minutes": 18 * 60 + 5,
				"route_bed_minutes": 21 * 60 + 10,
				"secondary_route_offset": Vector2(62.0, 14.0),
				"route_nodes": {
					"entry": Vector2(676.0, 690.0),
					"wash": Vector2(1056.0, 700.0),
					"tool": Vector2(286.0, 612.0),
					"desk": Vector2(620.0, 436.0),
					"kitchen": Vector2(930.0, 330.0),
					"storage": Vector2(968.0, 646.0),
					"mending": Vector2(370.0, 360.0),
					"bedside": Vector2(320.0, 334.0),
					"warming": Vector2(928.0, 330.0)
				},
				"bed_title": "铁架工棚床",
				"bed_subtitle": "床栏冰冷发硬，枕边却堆着换班后来不及收的衣服。",
				"kitchen_title": "压火铁炉",
				"kitchen_subtitle": "煤灰、热水和晚班人的疲惫都围着这团火转。",
				"storage_title": "工位柜与配给箱",
				"storage_subtitle": "工具、工牌、手套和剩下的配给面都压在一起。",
				"desk_title": "工账台",
				"desk_subtitle": "欠条、排班和流言都在铁屑味里被记下来。"
			}
		"exchange_house":
			return {
				"entry_x": 678.0,
				"entry_y": 744.0,
				"bed_x": 302.0,
				"bed_y": 244.0,
				"kitchen_x": 1030.0,
				"kitchen_y": 248.0,
				"storage_x": 958.0,
				"storage_y": 620.0,
				"desk_x": 610.0,
				"desk_y": 388.0,
				"bed_style": "merchant",
				"rug_style": "merchant",
				"partition": true,
				"partition_x": 786.0,
				"partition_style": "screen",
				"bookcase": true,
				"book_stack": true,
				"laundry": false,
				"wash_basin": false,
				"tools_on_desk": false,
				"curtains": true,
				"shelves": [Rect2(196, 138, 136, 10), Rect2(506, 138, 170, 10), Rect2(914, 138, 176, 10), Rect2(1026, 474, 146, 10)],
				"windows": [Rect2(136, 128, 110, 86), Rect2(1072, 128, 114, 86)],
				"lamp_pools": [Vector2(194, 170), Vector2(1126, 170), Vector2(610, 318)],
				"route_start_minutes": 18 * 60 + 30,
				"route_bed_minutes": 21 * 60 + 55,
				"secondary_route_offset": Vector2(48.0, 12.0),
				"route_nodes": {
					"entry": Vector2(666.0, 690.0),
					"cabinet": Vector2(948.0, 646.0),
					"kitchen": Vector2(972.0, 320.0),
					"desk": Vector2(596.0, 420.0),
					"table": Vector2(500.0, 500.0),
					"storage": Vector2(952.0, 642.0),
					"bedside": Vector2(400.0, 330.0),
					"mending": Vector2(442.0, 364.0)
				},
				"bed_title": "屏风高床",
				"bed_subtitle": "帘布和厚毯把街上的喧声挡成一层很薄的回响。",
				"kitchen_title": "铜炉小灶",
				"kitchen_subtitle": "热酒、浓汤和夜里翻账时的小火都靠这只铜炉。",
				"storage_title": "账柜",
				"storage_subtitle": "礼盒、酒瓶、备用银烛和契纸全锁在柜门后面。",
				"desk_title": "账房桌",
				"desk_subtitle": "账本、消息纸片和利差都在这张桌上被算成一夜。"
			}
		"stock_exchange":
			return {
				"entry_x": 678.0,
				"entry_y": 744.0,
				"bed_x": 320.0,
				"bed_y": 702.0,
				"kitchen_x": 180.0,
				"kitchen_y": 520.0,
				"storage_x": 424.0,
				"storage_y": 704.0,
				"desk_x": 546.0,
				"desk_y": 476.0,
				"route_nodes": {
					"entry": Vector2(678.0, 716.0),
					"storage": Vector2(424.0, 704.0),
					"cabinet": Vector2(424.0, 704.0),
					"desk": Vector2(546.0, 476.0),
					"table": Vector2(1012.0, 672.0),
					"kitchen": Vector2(1064.0, 186.0),
					"bedside": Vector2(320.0, 702.0),
					"mending": Vector2(700.0, 452.0),
					"warming": Vector2(700.0, 452.0)
				},
				"bed_title": "会客沙发",
				"bed_subtitle": "靠着玻璃幕墙喘口气，盯着城市灯火和你的账面波动。",
				"kitchen_title": "酒水吧台",
				"kitchen_subtitle": "咖啡、酒和临时会客都在角落里周转。",
				"storage_title": "保密金库",
				"storage_subtitle": "沉底的仓位凭证、金条和封存文件都压在这里。",
				"desk_title": "经纪人办公桌",
				"desk_subtitle": "把委托、仓位和资金流水重新理清。"
			}
		_:
			return {
				"entry_x": 664.0,
				"entry_y": 744.0,
				"bed_x": 224.0,
				"bed_y": 248.0,
				"kitchen_x": 1040.0,
				"kitchen_y": 254.0,
				"storage_x": 910.0,
				"storage_y": 642.0,
				"desk_x": 494.0,
				"desk_y": 488.0,
				"bed_style": "plain",
				"rug_style": "patch",
				"patched_walls": true,
				"laundry": true,
				"wash_basin": true,
				"partition": true,
				"partition_x": 726.0,
				"partition_style": "shack",
				"bookcase": false,
				"book_stack": false,
				"curtains": false,
				"shelves": [Rect2(168, 138, 118, 10), Rect2(462, 138, 132, 10), Rect2(902, 138, 148, 10), Rect2(1038, 478, 136, 10)],
				"windows": [Rect2(132, 128, 108, 86), Rect2(1080, 128, 108, 86)],
				"lamp_pools": [Vector2(186, 170), Vector2(1128, 170), Vector2(494, 446)],
				"route_start_minutes": 18 * 60 + 10,
				"route_bed_minutes": 21 * 60 + 20,
				"secondary_route_offset": Vector2(44.0, 12.0),
				"route_nodes": {
					"entry": Vector2(654.0, 690.0),
					"drop": Vector2(836.0, 668.0),
					"kitchen": Vector2(988.0, 330.0),
					"desk": Vector2(492.0, 518.0),
					"storage": Vector2(880.0, 664.0),
					"wash": Vector2(1044.0, 704.0),
					"mending": Vector2(330.0, 382.0),
					"bedside": Vector2(330.0, 336.0),
					"warming": Vector2(982.0, 334.0)
				},
				"bed_title": "拼补木床",
				"bed_subtitle": "床板旧得发亮，补丁布把风口和夜气都挡住了一半。",
				"kitchen_title": "泥炉灶",
				"kitchen_subtitle": "锅底黑得发亮，靠近就知道这里真的有人过活。",
				"storage_title": "破箱与木柜",
				"storage_subtitle": "补丁布、剩面包和舍不得丢的旧货全挤在一角。",
				"desk_title": "窄账桌",
				"desk_subtitle": "工钱、欠账和明早想法都得在这张矮桌上算清。"
			}


func _period_text(period: String) -> String:
	match period:
		"dawn":
			return "黎明"
		"day":
			return "白昼"
		"dusk":
			return "黄昏"
		"night":
			return "夜里"
	return "当下"
