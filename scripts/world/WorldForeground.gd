extends Node2D
class_name WorldForeground

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.2

const LEDGER_ICON_PATH := "res://assets/vendor/opengameart/496_RPG_icons/I_Book.png"
const TOOL_ICON_PATH := "res://assets/vendor/opengameart/496_RPG_icons/S_Axe01.png"
const COIN_ICON_PATH := "res://assets/vendor/opengameart/496_RPG_icons/I_GoldCoin.png"
const WORLD_RECT := WorldLayout.WORLD_RECT

var pulse_time := 0.0
var time_period := "day"
var light_level := 1.0
var house_states: Dictionary = {}
var canopy_layer := Node2D.new()
var ledger_icon: Texture2D
var tool_icon: Texture2D
var coin_icon: Texture2D
var redraw_accumulator := 0.0


func _ready() -> void:
	add_child(canopy_layer)
	ledger_icon = _load_runtime_texture(LEDGER_ICON_PATH)
	tool_icon = _load_runtime_texture(TOOL_ICON_PATH)
	coin_icon = _load_runtime_texture(COIN_ICON_PATH)
	_build_reference_canopies()


func _process(delta: float) -> void:
	pulse_time += delta
	redraw_accumulator += delta
	if redraw_accumulator >= REDRAW_INTERVAL:
		redraw_accumulator = 0.0
		queue_redraw()


func set_time_of_day(period: String, level: float) -> void:
	time_period = period
	light_level = clampf(level, 0.2, 1.0)
	redraw_accumulator = 0.0
	queue_redraw()


func set_house_states(states: Dictionary) -> void:
	house_states = states.duplicate(true)
	redraw_accumulator = 0.0
	queue_redraw()


func _load_runtime_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _build_reference_canopies() -> void:
	for spec in [
		{"folder": "tietu1_layers", "stem": "moonlit_grove", "rect": Rect2(84, 120, 534, 292)},
		{"folder": "tietu1_layers", "stem": "garden_homestead", "rect": Rect2(524, 126, 384, 272)},
		{"folder": "tietu1_layers", "stem": "outpost_keep", "rect": Rect2(502, 394, 346, 252)},
		{"folder": "tietu_layers", "stem": "shipyard", "rect": Rect2(1292, 96, 498, 306)},
		{"folder": "tietu_layers", "stem": "canal_harbor", "rect": Rect2(1610, 126, 548, 326)},
		{"folder": "tietu1_layers", "stem": "riverside_watermill", "rect": Rect2(112, 842, 502, 334)},
		{"folder": "tietu_layers", "stem": "market", "rect": Rect2(1306, 806, 540, 350)},
		{"folder": "tietu1_layers", "stem": "arcane_keep", "rect": Rect2(1806, 790, 386, 330)},
		{"folder": "tietu_layers", "stem": "church", "rect": Rect2(1688, 1088, 456, 330)},
		{"folder": "tietu1_layers", "stem": "watchtower_post", "rect": Rect2(536, 1128, 360, 210)}
	]:
		var folder: String = str(spec.get("folder", "tietu_layers"))
		var stem: String = str(spec.get("stem", ""))
		var rect: Rect2 = spec.get("rect", Rect2())
		var texture := _load_runtime_texture("res://assets/generated/%s/%s_canopy.png" % [folder, stem])
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = rect.position
		sprite.scale = Vector2(
			rect.size.x / maxf(float(texture.get_width()), 1.0),
			rect.size.y / maxf(float(texture.get_height()), 1.0)
		)
		sprite.modulate = Color(1, 1, 1, 0.98)
		canopy_layer.add_child(sprite)


func _draw() -> void:
	_draw_factory_foreground()
	_draw_exchange_foreground()
	_draw_house_doorstep_foreground()
	_draw_vignette()


func _draw_slum_foreground() -> void:
	_draw_canopy(Vector2(188, 362), Vector2(112, 34), Color("7a4a2c"), Color("8f2f33"))
	_draw_canopy(Vector2(476, 344), Vector2(100, 30), Color("6e4b30"), Color("8d6a2f"))
	_draw_signpost(Vector2(646, 388), "收债巷")
	_draw_alley_arch(Vector2(348, 354), Vector2(70, 34))
	_draw_market_entry_foreground(Rect2(214, 344, 156, 60), false)
	_draw_slum_lane_foreground(Rect2(168, 374, 414, 66))
	_draw_night_bazaar_foreground(Rect2(188, 352, 350, 56))
	_draw_laundry_alley_foreground(Rect2(454, 350, 126, 68))
	_draw_corner_hearth_foreground(Rect2(96, 372, 96, 54))
	_draw_grass_blade_row(Vector2(78, 434), 8, Color("4d5e36"))
	_draw_hanging_lamp(Vector2(286, 344))
	_draw_hanging_lamp(Vector2(554, 332))
	_draw_roof_beam(Vector2(92, 124), Vector2(628, 124))
	_draw_hanging_cloth_bundle(Vector2(214, 340), 3)
	_draw_reed_clump(Vector2(118, 440), 5)
	_draw_reed_clump(Vector2(642, 430), 4)
	_draw_roof_rag_strip(Vector2(108, 146), 5)
	_draw_slat_fence(Vector2(88, 394), 4, 28.0)
	_draw_foreground_shrub_row(Vector2(76, 452), 4, Color("4d5f38"), Color("687a49"))
	_draw_sack_cluster(Vector2(612, 388), 2, Color("8f7b57"))
	_draw_light_pool(Vector2(286, 384), Vector2(58, 22), Color(0.96, 0.78, 0.42, 1.0), 0.15)
	_draw_light_pool(Vector2(554, 372), Vector2(50, 20), Color(0.96, 0.75, 0.39, 1.0), 0.13)


func _draw_port_foreground() -> void:
	_draw_rope_fence(Vector2(900, 356), 5)
	_draw_crate_stack(Vector2(1440, 344), 2)
	_draw_canopy(Vector2(1276, 336), Vector2(96, 26), Color("5c4330"), Color("355f82"))
	_draw_mooring_planks(Vector2(922, 372), 6)
	_draw_bridgehead_foreground(Rect2(640, 536, 136, 88))
	_draw_harbor_spine_foreground(Rect2(946, 330, 344, 84))
	_draw_dock_loading_foreground(Rect2(1072, 348, 222, 58))
	_draw_fish_market_foreground(Rect2(1362, 344, 140, 58))
	_draw_ship_repair_foreground(Rect2(1452, 316, 112, 86))
	_draw_rope_wet_alley_foreground(Rect2(1202, 338, 92, 68))
	_draw_stake_net_beach_foreground(Rect2(1378, 356, 158, 56))
	draw_circle(Vector2(1028, 206), 22.0 + 2.0 * sin(pulse_time * 2.4), Color(0.76, 0.91, 0.96, 0.08))
	_draw_sail_cloth(Vector2(996, 116), Vector2(120, 48), Color("e7e1cf"))
	_draw_roof_beam(Vector2(856, 118), Vector2(1546, 118))
	_draw_hanging_net(Vector2(1188, 286), Vector2(54, 72))
	_draw_hanging_net(Vector2(1328, 280), Vector2(48, 68))
	_draw_anchor_prop(Vector2(1506, 350))
	_draw_slat_fence(Vector2(878, 370), 4, 30.0)
	_draw_sack_cluster(Vector2(1398, 376), 2, Color("897152"))
	_draw_foreground_shrub_row(Vector2(1490, 404), 4, Color("5c6d44"), Color("788a56"))
	_draw_reed_bank(Rect2(878, 392, 214, 24), 9, Color("728858"))
	_draw_wet_sheen(Rect2(882, 344, 590, 28))
	_draw_light_pool(Vector2(1276, 368), Vector2(70, 18), Color(0.84, 0.9, 0.95, 1.0), 0.08)


func _draw_factory_foreground() -> void:
	_draw_pipe(Vector2(166, 786), 94)
	_draw_pipe(Vector2(520, 812), 70)
	_draw_warning_stripe(Rect2(560, 782, 148, 24))
	_draw_signpost(Vector2(696, 782), "灰炉戒严")
	_draw_gantry_frame(Vector2(250, 640), 3)
	_draw_grass_blade_row(Vector2(84, 832), 6, Color("5e5934"))
	_draw_roof_beam(Vector2(76, 520), Vector2(720, 520))
	_draw_chain_hook(Vector2(614, 642))
	_draw_sparks_bucket(Vector2(298, 816))
	_draw_sparks_bucket(Vector2(462, 792))
	_draw_steam_vent(Vector2(214, 774), 52.0)
	_draw_steam_vent(Vector2(446, 798), 42.0)
	_draw_slat_fence(Vector2(82, 824), 4, 28.0)
	_draw_cinder_bank(Rect2(88, 836, 238, 28))
	_draw_cinder_cracks(Rect2(120, 844, 184, 18))
	_draw_light_pool(Vector2(298, 832), Vector2(42, 16), Color(0.96, 0.52, 0.2, 1.0), 0.12)
	_draw_light_pool(Vector2(462, 808), Vector2(38, 14), Color(0.94, 0.48, 0.18, 1.0), 0.1)
	_draw_factory_outbound_foreground(Rect2(446, 772, 242, 86))
	_draw_smokestack_corridor_foreground(Rect2(126, 724, 204, 80))
	_draw_factory_ash_drain_foreground(Rect2(88, 838, 252, 42))
	_draw_coal_loading_foreground(Rect2(398, 782, 148, 52))


func _draw_exchange_foreground() -> void:
	_draw_banner_arch(Vector2(1080, 824), Vector2(256, 44), "金钟广场")
	_draw_hedge_curve(Vector2(950, 812), 5)
	_draw_coin_marker(Vector2(1306, 820))
	_draw_market_entry_foreground(Rect2(1060, 792, 226, 60), true)
	_draw_exchange_stall_foreground(Rect2(1018, 818, 300, 52))
	_draw_exchange_steps_foreground(Rect2(1084, 748, 196, 82))
	_draw_hanging_lamp(Vector2(1164, 544))
	_draw_hanging_lamp(Vector2(1270, 544))
	_draw_roof_beam(Vector2(866, 520), Vector2(1524, 520))
	_draw_trimmed_bush(Vector2(914, 846))
	_draw_trimmed_bush(Vector2(1478, 846))
	_draw_banner_pendants(Vector2(1008, 560), 5)
	_draw_paving_border(Vector2(952, 836), 9)
	_draw_foreground_shrub_row(Vector2(930, 858), 3, Color("526740"), Color("6b8252"))
	_draw_foreground_shrub_row(Vector2(1368, 856), 3, Color("556a42"), Color("708955"))
	_draw_flower_knots(Vector2(1046, 848), 4)
	_draw_flower_knots(Vector2(1236, 848), 4)
	_draw_light_pool(Vector2(1164, 572), Vector2(48, 18), Color(0.98, 0.82, 0.48, 1.0), 0.14)
	_draw_light_pool(Vector2(1270, 572), Vector2(48, 18), Color(0.98, 0.82, 0.48, 1.0), 0.14)
	_draw_exchange_arcade_foreground(Rect2(1022, 808, 260, 48))
	_draw_exchange_service_foreground(Rect2(1374, 734, 104, 60))
	_draw_stone_courtyard_foreground(Rect2(1360, 752, 118, 48))
	_draw_arcade_notice_foreground(Rect2(1016, 728, 108, 42))


func _draw_vignette() -> void:
	draw_rect(Rect2(0, 0, WORLD_RECT.size.x, 28), Color(0, 0, 0, 0.035), true)
	draw_rect(Rect2(0, WORLD_RECT.size.y - 24, WORLD_RECT.size.x, 24), Color(0, 0, 0, 0.03), true)
	draw_rect(Rect2(0, 0, 18, WORLD_RECT.size.y), Color(0, 0, 0, 0.025), true)
	draw_rect(Rect2(WORLD_RECT.size.x - 18, 0, 18, WORLD_RECT.size.y), Color(0, 0, 0, 0.025), true)


func _draw_subregion_expansion_foreground() -> void:
	_draw_light_pool(Vector2(326, 294), Vector2(52, 18), Color(0.96, 0.84, 0.48, 1.0), 0.06)
	_draw_foreground_shrub_row(Vector2(112, 548), 5, Color("4f673d"), Color("688451"))
	_draw_foreground_shrub_row(Vector2(530, 344), 2, Color("4d663b"), Color("6f8a52"))
	_draw_rope_fence(Vector2(1498, 350), 3)
	_draw_light_pool(Vector2(1768, 534), Vector2(62, 18), Color(0.86, 0.9, 0.96, 1.0), 0.07)
	_draw_signpost(Vector2(1610, 566), "石桥小单")
	_draw_sack_cluster(Vector2(804, 1078), 2, Color("867255"))
	_draw_warning_stripe(Rect2(646, 1118, 132, 16))
	_draw_light_pool(Vector2(432, 1044), Vector2(48, 16), Color(0.96, 0.6, 0.28, 1.0), 0.1)
	_draw_banner_arch(Vector2(1578, 1122), Vector2(280, 42), "钟楼外环")
	_draw_flower_knots(Vector2(1904, 1298), 3)
	_draw_foreground_shrub_row(Vector2(1786, 1328), 2, Color("557041"), Color("71905a"))


func _draw_scene_framers() -> void:
	_draw_overhang_branch(Vector2(176, 26), 2, Color("607647"))
	_draw_overhang_branch(Vector2(1366, 26), 2, Color("607647"))
	for index in range(4):
		var center := Vector2(182 + index * 332.0, 16 + sin(float(index) * 0.7) * 2.0)
		draw_circle(center, 22.0, Color(0.2, 0.26, 0.18, 0.055))
		draw_circle(center + Vector2(16, 4), 14.0, Color(0.28, 0.36, 0.24, 0.05))


func _draw_canopy(origin: Vector2, size: Vector2, frame_color: Color, cloth_color: Color) -> void:
	draw_rect(Rect2(origin, size), cloth_color, true)
	draw_line(origin, origin + Vector2(size.x, 0), frame_color.darkened(0.2), 3.0)
	draw_line(origin + Vector2(0, size.y), origin + Vector2(size.x, size.y), frame_color.darkened(0.25), 3.0)
	for index in range(3):
		var x := origin.x + 18 + index * (size.x - 36) / 2.0
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + size.y), Color(1, 1, 1, 0.14), 2.0)
	draw_line(origin + Vector2(8, size.y), origin + Vector2(8, size.y + 32), frame_color, 3.0)
	draw_line(origin + Vector2(size.x - 8, size.y), origin + Vector2(size.x - 8, size.y + 32), frame_color, 3.0)


func _draw_signpost(origin: Vector2, text_value: String) -> void:
	draw_line(origin, origin + Vector2(0, 44), Color("553621"), 4.0)
	draw_rect(Rect2(origin + Vector2(-28, -6), Vector2(80, 20)), Color("6f4a2e"), true)
	draw_rect(Rect2(origin + Vector2(-28, -6), Vector2(80, 20)), Color("d1b17a"), false, 2.0)
	for index in range(min(5, text_value.length())):
		draw_rect(Rect2(origin + Vector2(-20 + index * 12, 0), Vector2(6, 2)), Color("f7e4bb"), true)


func _draw_grass_blade_row(origin: Vector2, count: int, color_value: Color) -> void:
	for index in range(count):
		var x := origin.x + index * 26
		draw_line(Vector2(x, origin.y + 12), Vector2(x - 3, origin.y), color_value, 2.0)
		draw_line(Vector2(x, origin.y + 12), Vector2(x + 4, origin.y + 2), color_value, 2.0)


func _draw_rope_fence(origin: Vector2, posts: int) -> void:
	for index in range(posts):
		var x := origin.x + index * 52
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 28), Color("5a3c27"), 4.0)
	if posts > 1:
		draw_line(origin + Vector2(0, 8), origin + Vector2((posts - 1) * 52, 12), Color("c7a164"), 2.0)
		draw_line(origin + Vector2(0, 18), origin + Vector2((posts - 1) * 52, 22), Color("c7a164"), 2.0)


func _draw_crate_stack(origin: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2(index * 18, -index * 10)
		draw_rect(Rect2(origin + offset, Vector2(30, 24)), Color("725033"), true)
		draw_rect(Rect2(origin + offset, Vector2(30, 24)), Color("402718"), false, 2.0)
		draw_line(origin + offset, origin + offset + Vector2(30, 24), Color("4d331f"), 1.5)
		draw_line(origin + offset + Vector2(30, 0), origin + offset + Vector2(0, 24), Color("4d331f"), 1.5)


func _draw_alley_arch(origin: Vector2, size: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, size.y), Color("4e311f"), 4.0)
	draw_line(origin + Vector2(size.x, 0), origin + Vector2(size.x, size.y), Color("4e311f"), 4.0)
	draw_line(origin, origin + Vector2(size.x, 0), Color("6a4730"), 4.0)
	draw_rect(Rect2(origin + Vector2(10, 8), Vector2(size.x - 20, 10)), Color("8d6c46"), true)


func _draw_mooring_planks(origin: Vector2, count: int) -> void:
	for index in range(count):
		var x: float = origin.x + index * 30.0
		draw_rect(Rect2(x, origin.y, 20, 8), Color("7a5939"), true)
		draw_line(Vector2(x + 2, origin.y), Vector2(x + 2, origin.y + 8), Color("4d331f"), 1.2)


func _draw_reed_bank(rect: Rect2, count: int, color_value: Color) -> void:
	for index in range(count):
		var x: float = rect.position.x + 10.0 + index * rect.size.x / float(max(count - 1, 1))
		var height := 10.0 + float(index % 3) * 4.0
		draw_line(Vector2(x, rect.position.y + rect.size.y), Vector2(x - 2, rect.position.y + rect.size.y - height), color_value.darkened(0.14), 1.6)
		draw_line(Vector2(x + 2, rect.position.y + rect.size.y), Vector2(x + 3, rect.position.y + rect.size.y - height + 2.0), color_value, 1.4)


func _draw_gantry_frame(origin: Vector2, bays: int) -> void:
	for index in range(bays + 1):
		var x: float = origin.x + index * 42.0
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 56), Color("4b392c"), 3.0)
	for index in range(bays):
		var x: float = origin.x + index * 42.0
		draw_line(Vector2(x, origin.y), Vector2(x + 42, origin.y + 8), Color("66503c"), 3.0)
		draw_line(Vector2(x + 8, origin.y + 24), Vector2(x + 34, origin.y + 24), Color("7f6547"), 2.0)


func _draw_cinder_cracks(rect: Rect2) -> void:
	for index in range(5):
		var start := rect.position + Vector2(index * 34, 6 + float(index % 2) * 3.0)
		draw_line(start, start + Vector2(12, 4), Color(0.14, 0.1, 0.08, 0.34), 1.2)
		draw_line(start + Vector2(7, 2), start + Vector2(10, 8), Color(0.14, 0.1, 0.08, 0.24), 1.0)


func _draw_flower_knots(origin: Vector2, count: int) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 18, sin(float(index) * 0.8) * 2.0)
		draw_circle(center, 3.0, Color("d8be63"))
		draw_circle(center + Vector2(4, 1), 2.0, Color("e8d8a3"))


func _draw_bridgehead_foreground(rect: Rect2) -> void:
	_draw_rope_fence(rect.position + Vector2(8, 18), 3)
	_draw_rope_fence(rect.position + Vector2(rect.size.x - 112.0, 24), 3)
	_draw_sack_cluster(rect.position + Vector2(18, rect.size.y - 8.0), 2, Color("8b7656"))
	_draw_sack_cluster(rect.position + Vector2(rect.size.x - 54.0, rect.size.y - 6.0), 2, Color("8b7656"))
	for index in range(4):
		var x: float = rect.position.x + 22.0 + index * 24.0
		draw_line(Vector2(x, rect.position.y + 40), Vector2(x + 12, rect.position.y + rect.size.y - 10.0), Color("4d3928"), 1.2)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 12.0), Vector2(54, 14), Color(0.94, 0.78, 0.46, 1.0), 0.08)


func _draw_market_entry_foreground(rect: Rect2, formal: bool) -> void:
	var lamp_color := Color(0.98, 0.82, 0.46, 1.0) if formal else Color(0.96, 0.74, 0.4, 1.0)
	for index in range(2):
		var x: float = rect.position.x + 18.0 + index * (rect.size.x - 36.0)
		draw_line(Vector2(x, rect.position.y + 8), Vector2(x, rect.position.y + 50), Color("523624"), 3.0)
		draw_circle(Vector2(x, rect.position.y + 56), 6.0, Color("b98b3f"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 8.0), Vector2(rect.size.x * 0.34, 16), lamp_color, 0.11 if formal else 0.09)
	if formal:
		_draw_paving_border(rect.position + Vector2(10, rect.size.y - 6.0), 8)
		_draw_flower_knots(rect.position + Vector2(24, rect.size.y - 2.0), 5)
		_draw_flower_knots(rect.position + Vector2(rect.size.x - 116.0, rect.size.y - 2.0), 5)
	else:
		_draw_sack_cluster(rect.position + Vector2(18, rect.size.y - 2.0), 3, Color("937c58"))
		_draw_hanging_cloth_bundle(rect.position + Vector2(rect.size.x - 70.0, rect.position.y + 18.0), 3)
	for index in range(5):
		var x: float = rect.position.x + 18.0 + index * 34.0
		draw_rect(Rect2(x, rect.position.y + rect.size.y - 18.0 + float(index % 2) * 3.0, 16, 6), Color("806143"), true)


func _draw_harbor_spine_foreground(rect: Rect2) -> void:
	_draw_rope_fence(rect.position + Vector2(10, 12), 5)
	_draw_rope_fence(rect.position + Vector2(10, rect.size.y - 6.0), 5)
	for index in range(4):
		var x: float = rect.position.x + 24.0 + index * 78.0
		_draw_crate_stack(Vector2(x, rect.position.y + 22), 2)
		_draw_sack_cluster(Vector2(x + 18.0, rect.position.y + rect.size.y - 12.0), 2, Color("8f7757"))
	_draw_hanging_net(rect.position + Vector2(rect.size.x - 56.0, 4), Vector2(42, 54))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.46, rect.size.y - 6.0), Vector2(106, 14), Color(0.84, 0.9, 0.95, 1.0), 0.07)


func _draw_exchange_stall_foreground(rect: Rect2) -> void:
	for index in range(5):
		var x: float = rect.position.x + 12.0 + index * 80.0
		draw_rect(Rect2(x, rect.position.y + 8, 60, 14), Color("6d5238"), true)
		draw_rect(Rect2(x, rect.position.y + 22, 60, 24), Color("cfb985"), true)
		draw_rect(Rect2(x + 6, rect.position.y + 28, 16, 10), Color("8f2f33"), true)
		draw_rect(Rect2(x + 24, rect.position.y + 30, 12, 8), Color("75884e"), true)
		draw_rect(Rect2(x + 40, rect.position.y + 27, 14, 11), Color("b7965c"), true)
	_draw_paving_border(rect.position + Vector2(8, rect.size.y - 4.0), 10)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(132, 12), Color(0.98, 0.82, 0.48, 1.0), 0.12)


func _draw_slum_lane_foreground(rect: Rect2) -> void:
	for index in range(4):
		var x: float = rect.position.x + 18.0 + index * 84.0
		draw_rect(Rect2(x, rect.position.y + 8 + float(index % 2) * 4.0, 20, rect.size.y - 16.0), Color("7f6648"), true)
		draw_line(Vector2(x + 10, rect.position.y + 8), Vector2(x + 10, rect.position.y + rect.size.y - 8.0), Color("4c3626"), 1.0)
	_draw_sack_cluster(rect.position + Vector2(12, rect.size.y - 6.0), 2, Color("8e7656"))
	_draw_sack_cluster(rect.position + Vector2(rect.size.x - 44.0, rect.size.y - 8.0), 1, Color("8e7656"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.45, rect.size.y - 4.0), Vector2(112, 12), Color(0.96, 0.72, 0.38, 1.0), 0.08)


func _draw_night_bazaar_foreground(rect: Rect2) -> void:
	for index in range(3):
		var x: float = rect.position.x + 18.0 + index * 104.0
		_draw_hanging_lamp(Vector2(x + 28.0, rect.position.y + 6))
		_draw_sack_cluster(Vector2(x + 6.0, rect.position.y + rect.size.y - 6.0), 1, Color("8d7657"))
		draw_rect(Rect2(x + 16.0, rect.position.y + rect.size.y - 22.0, 18, 8), Color("b98a54"), true)
		draw_rect(Rect2(x + 38.0, rect.position.y + rect.size.y - 20.0, 14, 10), Color("6e8150"), true)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(112, 12), Color(0.98, 0.72, 0.42, 1.0), 0.1)


func _draw_exchange_steps_foreground(rect: Rect2) -> void:
	for step in range(4):
		draw_rect(Rect2(rect.position.x + 18.0 + step * 10.0, rect.position.y + 18.0 + step * 14.0, rect.size.x - 36.0 - step * 20.0, 8), Color("d4bd8e"), true)
	for index in range(3):
		var x: float = rect.position.x + 36.0 + index * 74.0
		draw_line(Vector2(x, rect.position.y + 6), Vector2(x, rect.position.y + rect.size.y - 8.0), Color("6a5037"), 3.0)
		draw_circle(Vector2(x, rect.position.y + 6), 5.0, Color("b98b3f"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(104, 12), Color(0.98, 0.84, 0.5, 1.0), 0.14)


func _draw_dock_loading_foreground(rect: Rect2) -> void:
	for index in range(3):
		var x: float = rect.position.x + 16.0 + index * 70.0
		_draw_crate_stack(Vector2(x, rect.position.y + 16), 2)
		_draw_sack_cluster(Vector2(x + 18.0, rect.position.y + rect.size.y - 4.0), 1, Color("887154"))
	_draw_hanging_net(rect.position + Vector2(rect.size.x - 50.0, 2), Vector2(38, 46))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(92, 10), Color(0.86, 0.94, 0.98, 1.0), 0.06)


func _draw_factory_outbound_foreground(rect: Rect2) -> void:
	for index in range(3):
		var x: float = rect.position.x + 12.0 + index * 74.0
		_draw_crate_stack(Vector2(x, rect.position.y + 12.0), 2)
		_draw_sack_cluster(Vector2(x + 22.0, rect.position.y + rect.size.y - 4.0), 2, Color("816a4f"))
	_draw_chain_hook(rect.position + Vector2(176.0, 6.0))
	draw_rect(Rect2(rect.position.x + 186.0, rect.position.y + 20.0, 24, 12), Color("8f723f"), true)
	draw_rect(Rect2(rect.position.x + 214.0, rect.position.y + 22.0, 16, 10), Color("5f6b4b"), true)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(108, 12), Color(0.96, 0.56, 0.24, 1.0), 0.11)


func _draw_exchange_arcade_foreground(rect: Rect2) -> void:
	for bay in range(3):
		var x: float = rect.position.x + 16.0 + bay * 82.0
		_draw_hanging_lamp(Vector2(x + 26.0, rect.position.y + 6.0))
		draw_rect(Rect2(x + 6.0, rect.position.y + rect.size.y - 18.0, 18, 8), Color("c39a5b"), true)
		draw_rect(Rect2(x + 30.0, rect.position.y + rect.size.y - 20.0, 14, 10), Color("6d8151"), true)
		_draw_sack_cluster(Vector2(x + 44.0, rect.position.y + rect.size.y - 4.0), 1, Color("8f7758"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(96, 10), Color(0.98, 0.82, 0.48, 1.0), 0.08)


func _draw_fish_market_foreground(rect: Rect2) -> void:
	for bay in range(2):
		var x: float = rect.position.x + 12.0 + bay * 62.0
		_draw_sack_cluster(Vector2(x + 10.0, rect.position.y + rect.size.y - 4.0), 1, Color("8c7658"))
		draw_rect(Rect2(x + 18.0, rect.position.y + rect.size.y - 18.0, 18, 8), Color("b6a36b"), true)
		draw_rect(Rect2(x + 24.0, rect.position.y + rect.size.y - 28.0, 10, 6), Color("7f98a6"), true)
	_draw_reed_bank(Rect2(rect.position.x - 6.0, rect.position.y + rect.size.y - 8.0, rect.size.x + 10.0, 16), 5, Color("728858"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(70, 10), Color(0.84, 0.92, 0.96, 1.0), 0.06)


func _draw_smokestack_corridor_foreground(rect: Rect2) -> void:
	for lane in range(3):
		var x: float = rect.position.x + 12.0 + lane * 56.0
		_draw_sack_cluster(Vector2(x + 10.0, rect.position.y + rect.size.y - 4.0), 1, Color("7f6a50"))
		draw_rect(Rect2(x + 18.0, rect.position.y + rect.size.y - 18.0, 16, 8), Color("a98246"), true)
	_draw_chain_hook(rect.position + Vector2(158.0, 6.0))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(96, 12), Color(0.96, 0.58, 0.24, 1.0), 0.11)


func _draw_ship_repair_foreground(rect: Rect2) -> void:
	_draw_hanging_net(rect.position + Vector2(10.0, 8.0), Vector2(28, 38))
	_draw_sack_cluster(Vector2(rect.position.x + 26.0, rect.position.y + rect.size.y - 4.0), 1, Color("8a7457"))
	_draw_sack_cluster(Vector2(rect.position.x + 74.0, rect.position.y + rect.size.y - 4.0), 1, Color("7d694f"))
	draw_rect(Rect2(rect.position.x + 44.0, rect.position.y + rect.size.y - 20.0, 20, 8), Color("b79e66"), true)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(74, 12), Color(0.84, 0.92, 0.96, 1.0), 0.08)


func _draw_exchange_service_foreground(rect: Rect2) -> void:
	_draw_hanging_lamp(Vector2(rect.position.x + 26.0, rect.position.y + 6.0))
	for stack in range(2):
		var x: float = rect.position.x + 18.0 + stack * 30.0
		draw_rect(Rect2(x, rect.position.y + rect.size.y - 18.0, 16, 8), Color("b99762"), true)
		_draw_sack_cluster(Vector2(x + 8.0, rect.position.y + rect.size.y - 4.0), 1, Color("8b7657"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(60, 10), Color(0.98, 0.82, 0.48, 1.0), 0.08)


func _draw_laundry_alley_foreground(rect: Rect2) -> void:
	for bundle in range(3):
		var x: float = rect.position.x + 12.0 + bundle * 38.0
		_draw_hanging_cloth_bundle(Vector2(x, rect.position.y + 6.0), 2)
		_draw_sack_cluster(Vector2(x + 10.0, rect.position.y + rect.size.y - 4.0), 1, Color("89745a"))
	draw_rect(Rect2(rect.position.x + 96.0, rect.position.y + rect.size.y - 18.0, 16, 8), Color("8f9da4"), true)
	draw_rect(Rect2(rect.position.x + 118.0, rect.position.y + rect.size.y - 20.0, 18, 10), Color("b69a65"), true)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(74, 10), Color(0.94, 0.74, 0.42, 1.0), 0.08)


func _draw_factory_ash_drain_foreground(rect: Rect2) -> void:
	for grate in range(4):
		var x: float = rect.position.x + 18.0 + grate * 54.0
		draw_rect(Rect2(x, rect.position.y + 8.0, 18, 14), Color("4b433a"), true)
		draw_line(Vector2(x + 6.0, rect.position.y + 10.0), Vector2(x + 6.0, rect.position.y + 20.0), Color("23201c"), 1.0)
		draw_line(Vector2(x + 12.0, rect.position.y + 10.0), Vector2(x + 12.0, rect.position.y + 20.0), Color("23201c"), 1.0)
	_draw_cinder_cracks(Rect2(rect.position.x + 10.0, rect.position.y + 24.0, rect.size.x - 20.0, 12.0))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(94, 10), Color(0.7, 0.5, 0.34, 1.0), 0.05)


func _draw_rope_wet_alley_foreground(rect: Rect2) -> void:
	for coil in range(3):
		var x: float = rect.position.x + 12.0 + coil * 24.0
		draw_circle(Vector2(x, rect.position.y + rect.size.y - 10.0), 6.0, Color("7e6246"))
		draw_circle(Vector2(x, rect.position.y + rect.size.y - 10.0), 2.0, Color("4d382b"))
	_draw_hanging_net(rect.position + Vector2(54.0, 2.0), Vector2(24, 42))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(64, 10), Color(0.84, 0.92, 0.96, 1.0), 0.07)


func _draw_stone_courtyard_foreground(rect: Rect2) -> void:
	for planter in range(2):
		var x: float = rect.position.x + 18.0 + planter * 46.0
		draw_rect(Rect2(x, rect.position.y + rect.size.y - 16.0, 22, 10), Color("856544"), true)
		draw_rect(Rect2(x + 4.0, rect.position.y + rect.size.y - 26.0, 14, 10), Color("6d8652"), true)
	_draw_hanging_lamp(Vector2(rect.position.x + 118.0, rect.position.y + 8.0))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(56, 10), Color(0.98, 0.82, 0.48, 1.0), 0.07)


func _draw_corner_hearth_foreground(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position.x + 10.0, rect.position.y + 8.0, 26, 14), Color("6b5039"), true)
	draw_circle(Vector2(rect.position.x + 58.0, rect.position.y + 18.0), 11.0, Color("32241b"))
	draw_circle(Vector2(rect.position.x + 58.0, rect.position.y + 18.0), 5.0, Color("e58a3a"))
	draw_line(Vector2(rect.position.x + 58.0, rect.position.y + 4.0), Vector2(rect.position.x + 58.0, rect.position.y + 14.0), Color("4a382b"), 2.0)
	_draw_sack_cluster(Vector2(rect.position.x + 22.0, rect.position.y + rect.size.y - 4.0), 1, Color("8f7757"))
	draw_rect(Rect2(rect.position.x + 68.0, rect.position.y + rect.size.y - 18.0, 16, 8), Color("9d7a51"), true)
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.45, rect.size.y - 2.0), Vector2(56, 10), Color(0.98, 0.64, 0.3, 1.0), 0.12)


func _draw_stake_net_beach_foreground(rect: Rect2) -> void:
	for post in range(4):
		var x: float = rect.position.x + 14.0 + post * 34.0
		draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.position.y + rect.size.y - 10.0), Color("5b4430"), 2.4)
		_draw_hanging_net(Vector2(x - 8.0, rect.position.y + 10.0), Vector2(22, 26))
	draw_rect(Rect2(rect.position.x + 118.0, rect.position.y + rect.size.y - 18.0, 18, 8), Color("b69a62"), true)
	_draw_sack_cluster(Vector2(rect.position.x + 142.0, rect.position.y + rect.size.y - 4.0), 1, Color("866f52"))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(70, 10), Color(0.84, 0.92, 0.96, 1.0), 0.08)


func _draw_coal_loading_foreground(rect: Rect2) -> void:
	for pile in range(3):
		var x: float = rect.position.x + 16.0 + pile * 36.0
		draw_circle(Vector2(x, rect.position.y + rect.size.y - 10.0), 10.0, Color("25211f"))
		draw_circle(Vector2(x + 12.0, rect.position.y + rect.size.y - 12.0), 9.0, Color("302927"))
		draw_rect(Rect2(x - 4.0, rect.position.y + rect.size.y - 22.0, 22, 6), Color("8b755b"), true)
	_draw_chain_hook(rect.position + Vector2(108.0, 6.0))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(64, 10), Color(0.88, 0.56, 0.28, 1.0), 0.08)


func _draw_arcade_notice_foreground(rect: Rect2) -> void:
	for sheet in range(3):
		var x: float = rect.position.x + 16.0 + sheet * 26.0
		draw_rect(Rect2(x, rect.position.y + 10.0, 18, 14), Color("d8c595"), true)
		draw_line(Vector2(x + 3.0, rect.position.y + 15.0), Vector2(x + 15.0, rect.position.y + 15.0), Color("8a6b49"), 1.0)
		draw_line(Vector2(x + 3.0, rect.position.y + 19.0), Vector2(x + 13.0, rect.position.y + 19.0), Color("8a6b49"), 1.0)
	_draw_hanging_lamp(Vector2(rect.position.x + 118.0, rect.position.y + 6.0))
	_draw_light_pool(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 2.0), Vector2(52, 10), Color(0.98, 0.82, 0.48, 1.0), 0.08)


func _draw_pipe(origin: Vector2, width: float) -> void:
	draw_rect(Rect2(origin, Vector2(width, 18)), Color("4c382d"), true)
	draw_rect(Rect2(origin + Vector2(0, 18), Vector2(width, 10)), Color("2b211c"), true)
	draw_circle(origin + Vector2(width, 9), 9.0, Color("655044"))


func _draw_warning_stripe(rect: Rect2) -> void:
	draw_rect(rect, Color("2b2118"), true)
	for index in range(6):
		var x := rect.position.x + index * 28
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x, rect.position.y + rect.size.y),
				Vector2(x + 18, rect.position.y),
				Vector2(x + 28, rect.position.y),
				Vector2(x + 10, rect.position.y + rect.size.y)
			]),
			Color("d7a23c")
		)


func _draw_banner_arch(origin: Vector2, size: Vector2, title: String) -> void:
	draw_line(origin + Vector2(0, size.y), origin, Color("5b3a24"), 5.0)
	draw_line(origin + Vector2(size.x, size.y), origin + Vector2(size.x, 0), Color("5b3a24"), 5.0)
	draw_rect(Rect2(origin, Vector2(size.x, 20)), Color("8f2f33"), true)
	draw_rect(Rect2(origin, Vector2(size.x, 20)), Color("e5c98f"), false, 2.0)
	for index in range(min(7, title.length())):
		draw_rect(Rect2(origin + Vector2(26 + index * 24, 6), Vector2(10, 3)), Color("f9e6c1"), true)


func _draw_hedge_curve(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 36, sin(float(index) * 0.7) * 6.0)
		draw_circle(pos, 16.0, Color("54683f"))
		draw_circle(pos + Vector2(4, 3), 10.0, Color("61784a"))


func _draw_coin_marker(center: Vector2) -> void:
	draw_circle(center, 11.0, Color("c8a14b"))
	draw_circle(center, 7.0, Color("ecc97a"))
	draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), Color("6c4a24"), 1.6)


func _draw_hanging_lamp(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 24), Color("4b2f1e"), 2.0)
	draw_circle(origin + Vector2(0, 30), 7.0, Color("b98b3f"))
	var glow_alpha := lerpf(0.04, 0.18, 1.0 - light_level)
	draw_circle(origin + Vector2(0, 30), 14.0 + 1.5 * sin(pulse_time * 2.1 + origin.x * 0.02), Color(0.97, 0.83, 0.44, glow_alpha))


func _draw_roof_beam(start: Vector2, ending: Vector2) -> void:
	draw_line(start, ending, Color("3b2518"), 8.0)
	for index in range(8):
		var ratio := float(index) / 7.0
		var pivot := start.lerp(ending, ratio)
		draw_line(pivot, pivot + Vector2(0, 16), Color("5b3a24"), 4.0)


func _draw_sail_cloth(origin: Vector2, size: Vector2, color_value: Color) -> void:
	var sway := sin(pulse_time * 1.5) * 10.0
	draw_colored_polygon(
		PackedVector2Array([
			origin,
			origin + Vector2(size.x, 8 + sway * 0.15),
			origin + Vector2(size.x - 28, size.y),
			origin + Vector2(8, size.y - 8)
		]),
		color_value
	)
	draw_line(origin, origin + Vector2(size.x, 8 + sway * 0.15), Color("b8ab87"), 2.0)


func _draw_chain_hook(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 44), Color("574335"), 3.0)
	draw_arc(origin + Vector2(0, 50), 8.0, 0.2, PI + 0.8, 16, Color("7b614f"), 3.0)


func _draw_hanging_cloth_bundle(origin: Vector2, count: int) -> void:
	for index in range(count):
		var x := origin.x + index * 18.0
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 12), Color("5a3b25"), 1.4)
		draw_rect(Rect2(Vector2(x - 7, origin.y + 12), Vector2(14, 12)), [Color("8f2f33"), Color("8c6a2f"), Color("6d7d42")][index], true)


func _draw_reed_clump(origin: Vector2, count: int) -> void:
	for index in range(count):
		var x := origin.x + index * 8.0
		draw_line(Vector2(x, origin.y + 18), Vector2(x - 2, origin.y), Color("6c7a43"), 1.8)
		draw_line(Vector2(x + 2, origin.y + 18), Vector2(x + 4, origin.y + 4), Color("859b55"), 1.4)


func _draw_hanging_net(origin: Vector2, size: Vector2) -> void:
	for row in range(5):
		var y := origin.y + row * size.y / 4.0
		draw_line(Vector2(origin.x, y), Vector2(origin.x + size.x, y), Color(0.9, 0.82, 0.66, 0.28), 1.0)
	for column in range(5):
		var x := origin.x + column * size.x / 4.0
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + size.y), Color(0.9, 0.82, 0.66, 0.28), 1.0)


func _draw_anchor_prop(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 28), Color("56463a"), 3.0)
	draw_arc(origin + Vector2(-8, 12), 11.0, -0.2, PI + 0.2, 16, Color("56463a"), 3.0)
	draw_arc(origin + Vector2(8, 12), 11.0, PI - 0.2, TAU + 0.2, 16, Color("56463a"), 3.0)
	draw_line(origin + Vector2(-16, 0), origin + Vector2(16, 0), Color("56463a"), 3.0)


func _draw_sparks_bucket(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(16, 14)), Color("6b5647"), true)
	draw_arc(origin + Vector2(8, 4), 6.0, PI, TAU, 12, Color("d2bd94"), 1.0)
	draw_circle(origin + Vector2(8, -2 + sin(pulse_time * 3.2) * 2.0), 2.0, Color(0.96, 0.66, 0.24, 0.32))


func _draw_trimmed_bush(origin: Vector2) -> void:
	draw_circle(origin, 18.0, Color("536943"))
	draw_circle(origin + Vector2(0, -10), 12.0, Color("5e764c"))


func _draw_banner_pendants(origin: Vector2, count: int) -> void:
	draw_line(origin, origin + Vector2(count * 34.0, 0), Color("68482d"), 2.0)
	for index in range(count):
		var start := origin + Vector2(8 + index * 34.0, 0)
		var color_value := Color("8f2f33") if index % 2 == 0 else Color("728748")
		draw_colored_polygon(PackedVector2Array([
			start,
			start + Vector2(14, 4),
			start + Vector2(2, 16)
		]), color_value)


func _draw_light_pool(center: Vector2, radii: Vector2, color_value: Color, strength: float) -> void:
	var alpha := strength * clampf(1.1 - light_level, 0.0, 1.0)
	if alpha <= 0.01:
		return
	_draw_ellipse(center, radii, Color(color_value.r, color_value.g, color_value.b, alpha))
	_draw_ellipse(center + Vector2(0, -2), radii * 0.56, Color(1, 1, 1, alpha * 0.22))


func _draw_house_doorstep_foreground() -> void:
	for house_id in ["slum_house", "dock_house", "factory_house", "exchange_house"]:
		if not house_states.has(house_id):
			continue
		var state: Dictionary = house_states[house_id]
		var doorstep_alpha: float = float(state.get("doorstep_alpha", 0.0))
		var warmth: float = float(state.get("residual_warmth", 0.0))
		var leftovers: float = float(state.get("breakfast_leftovers", 0.0))
		if maxf(maxf(doorstep_alpha, warmth), leftovers) <= 0.03:
			continue
		_draw_house_threshold_trace(house_id, state)


func _draw_house_threshold_trace(house_id: String, state: Dictionary) -> void:
	var specs: Dictionary = _house_entry_spec(house_id)
	var center: Vector2 = specs.get("door", Vector2.ZERO)
	var trail: Vector2 = specs.get("trail", Vector2(0.0, 1.0))
	var base_color: Color = specs.get("color", Color(0.94, 0.78, 0.46, 1.0))
	var doorstep_alpha: float = float(state.get("doorstep_alpha", 0.0))
	var warmth: float = float(state.get("residual_warmth", 0.0))
	var leftovers: float = float(state.get("breakfast_leftovers", 0.0))
	var prop_name: String = str(state.get("doorstep_prop", ""))
	var pulse: float = 0.9 + 0.1 * sin(pulse_time * 2.4 + center.x * 0.03)
	if warmth > 0.04:
		_draw_light_pool(center + trail * 16.0, Vector2(36.0, 12.0), base_color, 0.06 + warmth * 0.11 * pulse)
	if doorstep_alpha > 0.04:
		_draw_threshold_footprints(center, trail, base_color, doorstep_alpha)
		_draw_threshold_prop(prop_name, center + trail * 8.0 + Vector2(18.0, -10.0), doorstep_alpha, house_id)
	if leftovers > 0.05:
		_draw_breakfast_trace(center + Vector2(-18.0, 10.0), leftovers, house_id)


func _draw_threshold_footprints(center: Vector2, trail: Vector2, color_value: Color, alpha: float) -> void:
	var side: Vector2 = Vector2(-trail.y, trail.x)
	for index in range(3):
		var step_center: Vector2 = center + trail * float(index * 10) + side * (4.0 if index % 2 == 0 else -4.0)
		draw_circle(step_center, 4.5 - float(index) * 0.5, Color(color_value.r * 0.48, color_value.g * 0.4, color_value.b * 0.32, alpha * 0.22))
		draw_circle(step_center + Vector2(4.0, 1.0), 2.4, Color(color_value.r, color_value.g, color_value.b, alpha * 0.12))


func _draw_threshold_prop(prop_name: String, center: Vector2, alpha: float, house_id: String) -> void:
	var tint: Color = Color(1.0, 1.0, 1.0, clampf(alpha * 0.92, 0.0, 1.0))
	match prop_name:
		"ledger":
			if ledger_icon != null:
				draw_texture_rect(ledger_icon, Rect2(center + Vector2(-8.0, -8.0), Vector2(18.0, 18.0)), false, tint)
			if house_id == "exchange_house" and coin_icon != null:
				draw_texture_rect(coin_icon, Rect2(center + Vector2(10.0, -4.0), Vector2(12.0, 12.0)), false, Color(1.0, 1.0, 1.0, alpha * 0.76))
		"tool":
			if tool_icon != null:
				draw_texture_rect(tool_icon, Rect2(center + Vector2(-10.0, -10.0), Vector2(20.0, 20.0)), false, tint)
			draw_rect(Rect2(center + Vector2(12.0, -2.0), Vector2(8.0, 6.0)), Color(0.56, 0.46, 0.36, alpha * 0.72), true)
		"satchel":
			draw_line(center + Vector2(-4.0, -8.0), center + Vector2(8.0, 6.0), Color(0.8, 0.7, 0.54, alpha * 0.74), 1.2)
			draw_rect(Rect2(center + Vector2(-6.0, 0.0), Vector2(16.0, 12.0)), Color(0.46, 0.32, 0.22, alpha * 0.78), true)
			draw_rect(Rect2(center + Vector2(-6.0, 0.0), Vector2(16.0, 12.0)), Color(0.18, 0.12, 0.08, alpha * 0.7), false, 1.0)
		"breakfast":
			_draw_breakfast_trace(center, alpha, house_id)


func _draw_breakfast_trace(center: Vector2, alpha: float, house_id: String) -> void:
	var plate_color: Color = Color(0.82, 0.76, 0.62, alpha * 0.74)
	var food_color: Color = Color(0.78, 0.62, 0.38, alpha * 0.72)
	if house_id == "dock_house":
		food_color = Color(0.52, 0.64, 0.72, alpha * 0.7)
	elif house_id == "factory_house":
		food_color = Color(0.64, 0.44, 0.26, alpha * 0.72)
	elif house_id == "exchange_house":
		food_color = Color(0.92, 0.82, 0.56, alpha * 0.78)
	draw_circle(center, 6.0, plate_color)
	draw_circle(center + Vector2(1.0, -1.0), 3.4, food_color)
	draw_rect(Rect2(center + Vector2(10.0, -2.0), Vector2(10.0, 4.0)), food_color.lightened(0.08), true)
	draw_line(center + Vector2(8.0, -4.0), center + Vector2(18.0, 6.0), Color(0.92, 0.86, 0.72, alpha * 0.54), 1.0)


func _house_entry_spec(house_id: String) -> Dictionary:
	match house_id:
		"dock_house":
			return {"door": Vector2(1134, 266), "trail": Vector2(0.48, 0.88), "color": Color(0.74, 0.88, 0.96, 1.0)}
		"factory_house":
			return {"door": Vector2(174, 656), "trail": Vector2(0.58, 0.82), "color": Color(0.96, 0.52, 0.22, 1.0)}
		"exchange_house":
			return {"door": Vector2(1314, 792), "trail": Vector2(0.32, 0.94), "color": Color(0.98, 0.84, 0.48, 1.0)}
		_:
			return {"door": Vector2(178, 262), "trail": Vector2(0.42, 0.9), "color": Color(0.94, 0.72, 0.38, 1.0)}


func _draw_foreground_shrub_row(origin: Vector2, count: int, base_color: Color, accent_color: Color) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 24.0, sin(float(index) * 0.85) * 4.0)
		draw_circle(center, 12.0 + float(index % 2), base_color)
		draw_circle(center + Vector2(5, -1), 7.0, accent_color)
		draw_circle(center + Vector2(-4, 3), 5.0, base_color.darkened(0.08))


func _draw_slat_fence(origin: Vector2, count: int, height: float) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 20.0, sin(float(index) * 0.7) * 3.0)
		draw_line(pos, pos + Vector2(0, height), Color("5a3d28"), 3.0)
	if count > 1:
		draw_line(origin + Vector2(0, 8), origin + Vector2((count - 1) * 20.0, 12), Color("8c6a42"), 2.0)
		draw_line(origin + Vector2(0, height * 0.6), origin + Vector2((count - 1) * 20.0, height * 0.6 + 4.0), Color("8c6a42"), 2.0)


func _draw_sack_cluster(origin: Vector2, count: int, sack_color: Color) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 16.0, -float(index % 2) * 3.0)
		_draw_ellipse(center, Vector2(10, 12), sack_color)
		draw_line(center + Vector2(0, -9), center + Vector2(0, 8), Color("5a422c"), 1.2)


func _draw_roof_rag_strip(origin: Vector2, count: int) -> void:
	draw_line(origin, origin + Vector2(count * 30.0, 0), Color("5b3d28"), 2.0)
	for index in range(count):
		var x := origin.x + 10.0 + index * 30.0
		var sway := sin(pulse_time * 1.7 + index) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, origin.y),
			Vector2(x + 14 + sway, origin.y + 4),
			Vector2(x + 2, origin.y + 18)
		]), Color("b58b52") if index % 2 == 0 else Color("7b6943"))


func _draw_wet_sheen(rect: Rect2) -> void:
	for index in range(10):
		var x := rect.position.x + 10.0 + index * rect.size.x / 10.0
		var y := rect.position.y + rect.size.y * 0.55 + sin(pulse_time * 2.0 + index) * 2.0
		draw_line(Vector2(x, y), Vector2(x + 24, y + 2), Color(0.8, 0.92, 0.96, 0.18), 1.2)


func _draw_steam_vent(origin: Vector2, height: float) -> void:
	draw_line(origin, origin + Vector2(0, 16), Color("533c30"), 3.0)
	for index in range(3):
		var phase := pulse_time * (1.5 + float(index) * 0.2) + float(index)
		var center := origin + Vector2(sin(phase) * 6.0, -10.0 - abs(cos(phase * 0.8)) * height * (0.35 + float(index) * 0.18))
		_draw_ellipse(center, Vector2(10.0 + float(index) * 4.0, 6.0 + float(index) * 2.0), Color(0.72, 0.72, 0.72, 0.1))


func _draw_cinder_bank(rect: Rect2) -> void:
	draw_rect(rect, Color(0.16, 0.12, 0.1, 0.32), true)
	for index in range(8):
		var center := rect.position + Vector2(18 + index * 26, 10 + fmod(float(index) * 5.0, rect.size.y - 8.0))
		draw_circle(center, 4.0 + float(index % 2), Color(0.25, 0.18, 0.14, 0.24))


func _draw_paving_border(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 28.0, fmod(float(index) * 5.0, 10.0))
		draw_rect(Rect2(pos, Vector2(16, 8)), Color("a88a61"), true)
		draw_rect(Rect2(pos + Vector2(1, 1), Vector2(14, 6)), Color("8e734c"), false, 1.0)


func _draw_ellipse(center: Vector2, radii: Vector2, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(18):
		var angle := TAU * float(step) / 18.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)


func _draw_framing_tree(origin: Vector2, trunk_height: float, trunk_color: Color, leaf_color: Color, lean: float) -> void:
	draw_rect(Rect2(origin.x - 12, origin.y, 24, trunk_height), trunk_color, true)
	draw_rect(Rect2(origin.x - 8 + lean * 8.0, origin.y + 18, 16, trunk_height - 10.0), trunk_color.lightened(0.06), true)
	_draw_ellipse(origin + Vector2(lean * 18.0, -8), Vector2(54, 32), leaf_color)
	_draw_ellipse(origin + Vector2(lean * 48.0, 14), Vector2(46, 26), leaf_color.darkened(0.06))
	_draw_ellipse(origin + Vector2(-lean * 26.0, 18), Vector2(40, 24), leaf_color.lightened(0.05))


func _draw_overhang_branch(origin: Vector2, clusters: int, leaf_color: Color) -> void:
	draw_line(origin, origin + Vector2(clusters * 68.0, 8.0), Color("4f3624"), 5.0)
	for index in range(clusters):
		var center := origin + Vector2(30.0 + index * 68.0, 8.0 + sin(float(index) * 0.8) * 5.0)
		draw_line(center + Vector2(-8, -2), center + Vector2(-2, 22), Color("4f3624"), 3.0)
		_draw_ellipse(center + Vector2(0, 20), Vector2(30, 18), leaf_color)
		_draw_ellipse(center + Vector2(16, 28), Vector2(24, 14), leaf_color.lightened(0.04))
		_draw_ellipse(center + Vector2(-18, 26), Vector2(22, 13), leaf_color.darkened(0.05))


func _draw_wildflower_strip(rect: Rect2, count: int, flower_color: Color, grass_color: Color) -> void:
	for index in range(count):
		var x := rect.position.x + 14.0 + fmod(float(index) * 27.0, rect.size.x - 20.0)
		var y := rect.position.y + rect.size.y - 8.0 + sin(float(index) * 1.2) * 2.0
		draw_line(Vector2(x, y), Vector2(x - 2, y - 12), grass_color, 1.6)
		draw_line(Vector2(x, y), Vector2(x + 3, y - 10), grass_color.lightened(0.06), 1.4)
		draw_circle(Vector2(x - 1, y - 14), 2.2, flower_color)
		if index % 3 == 0:
			draw_circle(Vector2(x + 3, y - 11), 1.6, Color("d58c76"))


func _draw_bottom_scrub_band(rect: Rect2, count: int, base_color: Color, accent_color: Color) -> void:
	for index in range(count):
		var x := rect.position.x + 10.0 + fmod(float(index) * 29.0, rect.size.x - 14.0)
		var y := rect.position.y + rect.size.y - 4.0 + sin(float(index) * 0.8) * 2.0
		draw_line(Vector2(x, y), Vector2(x - 3, y - 10), base_color, 1.5)
		draw_line(Vector2(x, y), Vector2(x + 2, y - 12), accent_color, 1.4)
		if index % 4 == 0:
			draw_circle(Vector2(x + 1, y - 13), 1.8, Color("d9c46a"))
