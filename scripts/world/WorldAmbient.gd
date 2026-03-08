extends Node2D
class_name WorldAmbient

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.16

const LEAF_TEXTURE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/fx/7.png"
const EMBER_TEXTURE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/fx/8.png"
const WORLD_RECT := WorldLayout.WORLD_RECT

var time_passed := 0.0
var time_period := "day"
var light_level := 1.0
var house_states: Dictionary = {}
var dust_particles: Array = []
var spark_particles: Array = []
var fireflies: Array = []
var leaf_particles: Array = []
var leaf_texture: Texture2D
var ember_texture: Texture2D
var redraw_accumulator := 0.0


func _ready() -> void:
	leaf_texture = load(LEAF_TEXTURE_PATH) as Texture2D
	ember_texture = load(EMBER_TEXTURE_PATH) as Texture2D
	for index in range(12):
		dust_particles.append(
			{
				"origin": Vector2(randf_range(40.0, 1560.0), randf_range(120.0, 850.0)),
				"phase": randf_range(0.0, TAU),
				"speed": randf_range(0.18, 0.42),
				"radius": randf_range(1.8, 3.8),
				"alpha": randf_range(0.04, 0.11),
			}
		)
	for index in range(8):
		spark_particles.append(
			{
				"origin": Vector2(randf_range(90.0, 700.0), randf_range(520.0, 830.0)),
				"phase": randf_range(0.0, TAU),
				"speed": randf_range(0.9, 1.6),
				"rise": randf_range(8.0, 20.0),
			}
		)
	for index in range(10):
		fireflies.append(
			{
				"origin": Vector2(randf_range(40.0, 1560.0), randf_range(120.0, 900.0)),
				"phase": randf_range(0.0, TAU),
				"speed": randf_range(0.6, 1.1),
			}
		)
	for index in range(8):
		leaf_particles.append(
			{
				"origin": Vector2(randf_range(40.0, 1560.0), randf_range(80.0, 860.0)),
				"phase": randf_range(0.0, TAU),
				"speed": randf_range(0.18, 0.42),
				"size": randf_range(0.65, 1.15),
				"drift": randf_range(20.0, 42.0),
			}
		)


func _process(delta: float) -> void:
	time_passed += delta
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


func _draw() -> void:
	_draw_sky_wash()
	_draw_horizon_belt()
	_draw_cloud_shadows()
	_draw_district_haze()
	_draw_breeze_lines()
	_draw_dust()
	_draw_port_gulls()
	if light_level < 0.74:
		_draw_factory_sparks()
		_draw_exchange_glow()
		_draw_market_bloom()
		_draw_harbor_spine_bloom()
		_draw_slum_lane_bloom()
		_draw_factory_outbound_bloom()
		_draw_subregion_expansion_bloom()
		_draw_window_glow_ribbons()
	_draw_house_transition_ambient()
	if light_level < 0.66:
		_draw_far_city_lights()
		_draw_ground_warmth()
		_draw_fireflies()
	_draw_leaves()
	if light_level < 0.8:
		_draw_embers()


func _draw_sky_wash() -> void:
	if light_level >= 0.62:
		_draw_glow_ellipse(Vector2(284, 118), Vector2(220, 86), Color(0.95, 0.88, 0.7, 0.06))
		_draw_glow_ellipse(Vector2(1298, 146), Vector2(260, 92), Color(0.86, 0.92, 0.98, 0.06))
		return
	draw_rect(WORLD_RECT, Color(0.04, 0.07, 0.12, (1.0 - light_level) * 0.08), true)
	_draw_glow_ellipse(Vector2(1228, 198), Vector2(340, 180), Color(0.16, 0.22, 0.34, 0.08 + (1.0 - light_level) * 0.08))


func _draw_horizon_belt() -> void:
	var dusk_alpha := clampf(0.55 - abs(light_level - 0.46) * 1.4, 0.0, 0.12)
	if dusk_alpha > 0.0:
		draw_rect(Rect2(0, 158, 1600, 88), Color(0.88, 0.62, 0.46, dusk_alpha), true)
	var cool_alpha := clampf((1.0 - light_level) * 0.08, 0.0, 0.08)
	if cool_alpha > 0.0:
		draw_rect(Rect2(0, 182, 1600, 70), Color(0.2, 0.26, 0.34, cool_alpha), true)


func _draw_cloud_shadows() -> void:
	for index in range(4):
		var x := 180.0 + fmod(time_passed * 18.0 + index * 380.0, 1840.0) - 120.0
		var y := 136.0 + index * 172.0 + 12.0 * sin(time_passed * 0.3 + index)
		var center := Vector2(x + 130.0, y + 27.0)
		var points := PackedVector2Array()
		for step in range(20):
			var angle := TAU * float(step) / 20.0
			points.append(center + Vector2(cos(angle) * 130.0, sin(angle) * 27.0))
		draw_colored_polygon(points, Color(0, 0, 0, 0.035))


func _draw_district_haze() -> void:
	_draw_slum_haze()
	_draw_port_mist()
	_draw_factory_plume()
	_draw_exchange_bloom()


func _draw_subregion_expansion_bloom() -> void:
	_draw_glow_ellipse(Vector2(320, 288), Vector2(186, 72), Color(0.96, 0.88, 0.62, 0.05))
	_draw_glow_ellipse(Vector2(1888, 272), Vector2(160, 54), Color(0.78, 0.9, 0.98, 0.05))
	_draw_glow_ellipse(Vector2(438, 1038), Vector2(82, 28), Color(0.98, 0.56, 0.22, 0.08))
	_draw_glow_ellipse(Vector2(1972, 836), Vector2(88, 32), Color(0.38, 0.56, 0.94, 0.16))
	_draw_glow_ellipse(Vector2(1912, 1242), Vector2(164, 46), Color(0.72, 0.84, 0.98, 0.05))


func _draw_breeze_lines() -> void:
	for index in range(10):
		var start := Vector2(40 + index * 154.0 + fmod(time_passed * 14.0, 120.0), 244 + fmod(float(index) * 57.0, 520.0))
		draw_line(start, start + Vector2(42, sin(float(index) + time_passed) * 3.0), Color(1, 1, 1, 0.035), 1.0)


func _draw_slum_haze() -> void:
	var warm_alpha := 0.03 + (1.0 - light_level) * 0.06
	_draw_glow_ellipse(Vector2(234, 322), Vector2(152, 54), Color(0.6, 0.45, 0.28, warm_alpha))
	_draw_glow_ellipse(Vector2(522, 348), Vector2(126, 44), Color(0.58, 0.43, 0.27, warm_alpha * 0.85))
	if light_level < 0.72:
		_draw_glow_ellipse(Vector2(286, 374), Vector2(70, 26), Color(0.96, 0.72, 0.38, 0.06 + (1.0 - light_level) * 0.12))
		_draw_glow_ellipse(Vector2(552, 360), Vector2(62, 22), Color(0.96, 0.72, 0.38, 0.05 + (1.0 - light_level) * 0.1))


func _draw_port_mist() -> void:
	for index in range(5):
		var center := Vector2(930 + index * 126.0 + sin(time_passed * 0.35 + index) * 12.0, 176 + cos(time_passed * 0.25 + index) * 8.0)
		_draw_glow_ellipse(center, Vector2(126, 24), Color(0.78, 0.9, 0.96, 0.045))
		_draw_glow_ellipse(center + Vector2(22, 84), Vector2(138, 20), Color(0.68, 0.84, 0.9, 0.03))
	if light_level < 0.75:
		_draw_glow_ellipse(Vector2(1278, 350), Vector2(90, 24), Color(0.84, 0.9, 0.95, 0.04 + (1.0 - light_level) * 0.08))


func _draw_factory_plume() -> void:
	for index in range(4):
		var phase := time_passed * 0.38 + float(index) * 0.8
		var center := Vector2(182 + float(index) * 42.0 + sin(phase) * 9.0, 564 - abs(cos(phase * 0.7)) * 132.0)
		_draw_glow_ellipse(center, Vector2(34 + float(index) * 8.0, 18 + float(index) * 5.0), Color(0.16, 0.14, 0.12, 0.08))
	_draw_glow_ellipse(Vector2(142, 666), Vector2(84, 34), Color(0.94, 0.48, 0.18, 0.05 + (1.0 - light_level) * 0.08))
	_draw_glow_ellipse(Vector2(302, 808), Vector2(68, 24), Color(0.94, 0.44, 0.16, 0.04 + (1.0 - light_level) * 0.08))


func _draw_exchange_bloom() -> void:
	var gold_alpha := 0.03 + (1.0 - light_level) * 0.09
	_draw_glow_ellipse(Vector2(1180, 670), Vector2(214, 92), Color(0.86, 0.76, 0.46, gold_alpha))
	_draw_glow_ellipse(Vector2(1180, 576), Vector2(176, 54), Color(0.92, 0.82, 0.58, gold_alpha * 0.72))
	if light_level < 0.76:
		_draw_glow_ellipse(Vector2(1164, 572), Vector2(44, 18), Color(0.98, 0.84, 0.48, 0.04 + (1.0 - light_level) * 0.12))
		_draw_glow_ellipse(Vector2(1270, 572), Vector2(44, 18), Color(0.98, 0.84, 0.48, 0.04 + (1.0 - light_level) * 0.12))


func _draw_dust() -> void:
	for particle in dust_particles:
		var origin: Vector2 = particle.get("origin", Vector2.ZERO)
		var phase: float = float(particle.get("phase", 0.0))
		var speed: float = float(particle.get("speed", 0.2))
		var radius: float = float(particle.get("radius", 2.0))
		var alpha: float = float(particle.get("alpha", 0.05))
		var pos := origin + Vector2(
			sin(time_passed * speed + phase) * 16.0,
			cos(time_passed * speed * 0.7 + phase) * 10.0
		)
		draw_circle(pos, radius, Color(0.95, 0.88, 0.72, alpha))


func _draw_factory_sparks() -> void:
	for particle in spark_particles:
		var origin: Vector2 = particle.get("origin", Vector2.ZERO)
		var phase: float = float(particle.get("phase", 0.0))
		var speed: float = float(particle.get("speed", 1.0))
		var rise: float = float(particle.get("rise", 10.0))
		var progress := fmod(time_passed * speed + phase, TAU)
		var pos := origin + Vector2(sin(progress) * 8.0, -abs(sin(progress * 0.5)) * rise)
		draw_circle(pos, 1.8, Color(0.93, 0.63, 0.22, 0.24))


func _draw_port_gulls() -> void:
	for index in range(3):
		var x := 860.0 + fmod(time_passed * 32.0 + index * 160.0, 620.0)
		var y := 116.0 + 24.0 * sin(time_passed * 0.7 + index * 1.7)
		draw_arc(Vector2(x, y), 10.0, PI * 1.1, PI * 1.9, 10, Color(0.92, 0.94, 0.96, 0.42), 1.6)
		draw_arc(Vector2(x + 10, y), 10.0, PI * 1.1, PI * 1.9, 10, Color(0.92, 0.94, 0.96, 0.42), 1.6)


func _draw_exchange_glow() -> void:
	var pulse := lerpf(0.05, 0.22, 1.0 - light_level) + 0.03 * sin(time_passed * 2.2)
	draw_rect(Rect2(950, 540, 390, 230), Color(1.0, 0.86, 0.58, pulse), false, 2.0)


func _draw_bridgehead_bloom() -> void:
	var bridge_alpha := 0.018 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(704, 588), Vector2(116, 26), Color(0.96, 0.8, 0.48, bridge_alpha))
	_draw_glow_ellipse(Vector2(684, 228), Vector2(84, 20), Color(0.86, 0.9, 0.98, 0.012 + (1.0 - light_level) * 0.05))
	if light_level < 0.7:
		for lamp in [Vector2(654, 578), Vector2(748, 584)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.12 + sin(time_passed * 2.1 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 10.0, Color(0.98, 0.84, 0.5, pulse * 0.25))


func _draw_market_bloom() -> void:
	var warm_alpha := 0.02 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(292, 394), Vector2(126, 28), Color(0.96, 0.7, 0.34, warm_alpha))
	_draw_glow_ellipse(Vector2(1178, 840), Vector2(170, 26), Color(0.98, 0.82, 0.46, warm_alpha * 0.9))
	if light_level < 0.72:
		for lamp in [Vector2(214, 398), Vector2(366, 394), Vector2(1054, 832), Vector2(1292, 832)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.12 + sin(time_passed * 2.4 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.82, 0.46, pulse))
			draw_circle(lamp, 9.0, Color(0.98, 0.82, 0.46, pulse * 0.22))


func _draw_harbor_spine_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.06
	_draw_glow_ellipse(Vector2(1118, 374), Vector2(188, 18), Color(0.78, 0.9, 0.96, cool_alpha))
	_draw_glow_ellipse(Vector2(1128, 330), Vector2(164, 22), Color(0.68, 0.84, 0.9, cool_alpha * 0.7))
	if light_level < 0.72:
		for lamp in [Vector2(990, 388), Vector2(1138, 388), Vector2(1280, 390)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.0 + lamp.x * 0.03) * 0.01
			draw_circle(lamp, 3.0, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 8.0, Color(0.86, 0.94, 0.98, pulse * 0.22))


func _draw_exchange_stall_bloom() -> void:
	var warm_alpha := 0.014 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1174, 844), Vector2(202, 16), Color(0.98, 0.84, 0.48, warm_alpha))
	if light_level < 0.72:
		for lamp in [Vector2(996, 836), Vector2(1078, 836), Vector2(1160, 836), Vector2(1242, 836), Vector2(1324, 836)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.12 + sin(time_passed * 2.2 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 9.0, Color(0.98, 0.84, 0.5, pulse * 0.2))


func _draw_slum_lane_bloom() -> void:
	var warm_alpha := 0.014 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(376, 428), Vector2(188, 18), Color(0.94, 0.68, 0.34, warm_alpha))
	if light_level < 0.72:
		for lamp in [Vector2(202, 418), Vector2(354, 420), Vector2(520, 420)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.0 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.96, 0.76, 0.42, pulse))
			draw_circle(lamp, 9.0, Color(0.96, 0.76, 0.42, pulse * 0.22))


func _draw_exchange_steps_bloom() -> void:
	var warm_alpha := 0.016 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1180, 818), Vector2(142, 14), Color(0.98, 0.84, 0.5, warm_alpha))
	_draw_glow_ellipse(Vector2(1180, 764), Vector2(126, 20), Color(0.92, 0.82, 0.58, warm_alpha * 0.7))
	if light_level < 0.72:
		for lamp in [Vector2(1094, 748), Vector2(1180, 744), Vector2(1266, 748)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.12 + sin(time_passed * 2.1 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.84, 0.48, pulse))
			draw_circle(lamp, 10.0, Color(0.98, 0.84, 0.48, pulse * 0.2))


func _draw_dock_loading_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(1186, 404), Vector2(156, 16), Color(0.82, 0.92, 0.98, cool_alpha))
	_draw_glow_ellipse(Vector2(1186, 358), Vector2(124, 20), Color(0.72, 0.86, 0.92, cool_alpha * 0.72))
	if light_level < 0.72:
		for lamp in [Vector2(1074, 394), Vector2(1188, 392), Vector2(1306, 396)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.0 + lamp.x * 0.03) * 0.01
			draw_circle(lamp, 3.0, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 9.0, Color(0.86, 0.94, 0.98, pulse * 0.22))


func _draw_night_bazaar_bloom() -> void:
	var warm_alpha := 0.018 + (1.0 - light_level) * 0.09
	_draw_glow_ellipse(Vector2(374, 410), Vector2(182, 18), Color(0.98, 0.74, 0.4, warm_alpha))
	_draw_glow_ellipse(Vector2(374, 378), Vector2(156, 20), Color(0.94, 0.64, 0.34, warm_alpha * 0.68))
	if light_level < 0.72:
		for lamp in [Vector2(194, 392), Vector2(278, 392), Vector2(362, 392), Vector2(446, 392), Vector2(530, 392)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.12 + sin(time_passed * 2.2 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.78, 0.44, pulse))
			draw_circle(lamp, 10.0, Color(0.98, 0.78, 0.44, pulse * 0.2))


func _draw_factory_outbound_bloom() -> void:
	var ember_alpha := 0.014 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(566, 842), Vector2(132, 16), Color(0.96, 0.54, 0.24, ember_alpha))
	_draw_glow_ellipse(Vector2(534, 804), Vector2(106, 20), Color(0.78, 0.38, 0.16, ember_alpha * 0.68))
	if light_level < 0.74:
		for lamp in [Vector2(470, 828), Vector2(552, 824), Vector2(636, 826)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.11 + sin(time_passed * 2.1 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.62, 0.28, pulse))
			draw_circle(lamp, 9.0, Color(0.98, 0.62, 0.28, pulse * 0.2))


func _draw_exchange_arcade_bloom() -> void:
	var warm_alpha := 0.015 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1154, 848), Vector2(168, 14), Color(0.98, 0.84, 0.5, warm_alpha))
	_draw_glow_ellipse(Vector2(1154, 810), Vector2(152, 20), Color(0.88, 0.74, 0.44, warm_alpha * 0.72))
	if light_level < 0.72:
		for lamp in [Vector2(1018, 810), Vector2(1098, 810), Vector2(1178, 810), Vector2(1258, 810)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.11 + sin(time_passed * 2.2 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 9.0, Color(0.98, 0.84, 0.5, pulse * 0.2))


func _draw_smokestack_corridor_bloom() -> void:
	var ember_alpha := 0.014 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(226, 798), Vector2(118, 14), Color(0.96, 0.56, 0.24, ember_alpha))
	_draw_glow_ellipse(Vector2(214, 754), Vector2(98, 18), Color(0.74, 0.34, 0.16, ember_alpha * 0.66))
	if light_level < 0.74:
		for lamp in [Vector2(154, 788), Vector2(226, 786), Vector2(298, 790)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.11 + sin(time_passed * 2.0 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.62, 0.28, pulse))
			draw_circle(lamp, 8.0, Color(0.98, 0.62, 0.28, pulse * 0.2))


func _draw_fish_market_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(1426, 404), Vector2(108, 14), Color(0.82, 0.92, 0.98, cool_alpha))
	_draw_glow_ellipse(Vector2(1436, 370), Vector2(96, 18), Color(0.7, 0.86, 0.92, cool_alpha * 0.7))
	if light_level < 0.72:
		for lamp in [Vector2(1368, 392), Vector2(1426, 390), Vector2(1484, 394)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.1 + lamp.x * 0.03) * 0.01
			draw_circle(lamp, 3.0, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 8.0, Color(0.86, 0.94, 0.98, pulse * 0.22))


func _draw_exchange_service_bloom() -> void:
	var warm_alpha := 0.014 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1426, 796), Vector2(88, 14), Color(0.98, 0.82, 0.48, warm_alpha))
	_draw_glow_ellipse(Vector2(1416, 750), Vector2(74, 20), Color(0.82, 0.66, 0.38, warm_alpha * 0.7))
	if light_level < 0.72:
		for lamp in [Vector2(1386, 744), Vector2(1426, 742), Vector2(1462, 748)]:
			var pulse := 0.05 + (1.0 - light_level) * 0.11 + sin(time_passed * 2.1 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 8.0, Color(0.98, 0.84, 0.5, pulse * 0.2))


func _draw_ship_repair_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(1506, 404), Vector2(74, 12), Color(0.82, 0.92, 0.98, cool_alpha))
	_draw_glow_ellipse(Vector2(1504, 350), Vector2(62, 18), Color(0.68, 0.84, 0.92, cool_alpha * 0.72))
	if light_level < 0.72:
		for lamp in [Vector2(1478, 394), Vector2(1510, 390), Vector2(1540, 394)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.0 + lamp.x * 0.03) * 0.01
			draw_circle(lamp, 3.0, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 8.0, Color(0.86, 0.94, 0.98, pulse * 0.22))


func _draw_laundry_alley_bloom() -> void:
	var warm_alpha := 0.012 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(514, 420), Vector2(86, 12), Color(0.94, 0.72, 0.42, warm_alpha))
	_draw_glow_ellipse(Vector2(514, 372), Vector2(76, 18), Color(0.72, 0.66, 0.56, warm_alpha * 0.56))
	if light_level < 0.72:
		for lamp in [Vector2(460, 358), Vector2(516, 360), Vector2(570, 362)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.2 + lamp.x * 0.02) * 0.01
			draw_circle(lamp, 3.0, Color(0.96, 0.76, 0.44, pulse))
			draw_circle(lamp, 8.0, Color(0.96, 0.76, 0.44, pulse * 0.18))


func _draw_factory_ash_drain_bloom() -> void:
	var cool_alpha := 0.01 + (1.0 - light_level) * 0.06
	_draw_glow_ellipse(Vector2(206, 878), Vector2(124, 10), Color(0.38, 0.34, 0.3, cool_alpha))
	_draw_glow_ellipse(Vector2(206, 846), Vector2(102, 12), Color(0.56, 0.44, 0.32, cool_alpha * 0.5))
	if light_level < 0.74:
		for lamp in [Vector2(114, 850), Vector2(208, 846), Vector2(298, 850)]:
			var pulse := 0.03 + (1.0 - light_level) * 0.08 + sin(time_passed * 1.9 + lamp.x * 0.02) * 0.008
			draw_circle(lamp, 2.5, Color(0.76, 0.54, 0.34, pulse))
			draw_circle(lamp, 7.0, Color(0.76, 0.54, 0.34, pulse * 0.16))


func _draw_rope_wet_alley_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(1244, 404), Vector2(70, 10), Color(0.82, 0.92, 0.98, cool_alpha))
	_draw_glow_ellipse(Vector2(1240, 366), Vector2(62, 14), Color(0.64, 0.82, 0.88, cool_alpha * 0.68))
	if light_level < 0.72:
		for lamp in [Vector2(1216, 394), Vector2(1242, 392), Vector2(1268, 394)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.09 + sin(time_passed * 2.0 + lamp.x * 0.03) * 0.008
			draw_circle(lamp, 2.5, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 7.0, Color(0.86, 0.94, 0.98, pulse * 0.18))


func _draw_stone_courtyard_bloom() -> void:
	var warm_alpha := 0.012 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1418, 804), Vector2(78, 10), Color(0.98, 0.82, 0.48, warm_alpha))
	_draw_glow_ellipse(Vector2(1438, 758), Vector2(68, 14), Color(0.82, 0.68, 0.42, warm_alpha * 0.7))
	if light_level < 0.72:
		for lamp in [Vector2(1388, 792), Vector2(1422, 790), Vector2(1456, 794)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.1 + lamp.x * 0.02) * 0.008
			draw_circle(lamp, 2.5, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 7.0, Color(0.98, 0.84, 0.5, pulse * 0.18))


func _draw_corner_hearth_bloom() -> void:
	var warm_alpha := 0.016 + (1.0 - light_level) * 0.09
	_draw_glow_ellipse(Vector2(138, 430), Vector2(62, 10), Color(0.96, 0.62, 0.3, warm_alpha))
	_draw_glow_ellipse(Vector2(146, 386), Vector2(42, 14), Color(0.48, 0.42, 0.38, warm_alpha * 0.52))
	if light_level < 0.74:
		for lamp in [Vector2(120, 392), Vector2(150, 388), Vector2(172, 396)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.11 + sin(time_passed * 2.2 + lamp.x * 0.03) * 0.01
			draw_circle(lamp, 2.5, Color(0.98, 0.68, 0.34, pulse))
			draw_circle(lamp, 8.0, Color(0.98, 0.68, 0.34, pulse * 0.18))


func _draw_stake_net_beach_bloom() -> void:
	var cool_alpha := 0.012 + (1.0 - light_level) * 0.07
	_draw_glow_ellipse(Vector2(1450, 416), Vector2(84, 10), Color(0.82, 0.92, 0.98, cool_alpha))
	_draw_glow_ellipse(Vector2(1456, 378), Vector2(74, 14), Color(0.68, 0.84, 0.92, cool_alpha * 0.68))
	if light_level < 0.72:
		for lamp in [Vector2(1408, 402), Vector2(1450, 398), Vector2(1492, 404)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.09 + sin(time_passed * 2.0 + lamp.x * 0.03) * 0.008
			draw_circle(lamp, 2.5, Color(0.86, 0.94, 0.98, pulse))
			draw_circle(lamp, 7.0, Color(0.86, 0.94, 0.98, pulse * 0.18))


func _draw_coal_loading_bloom() -> void:
	var ember_alpha := 0.012 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(470, 836), Vector2(76, 10), Color(0.92, 0.58, 0.3, ember_alpha))
	_draw_glow_ellipse(Vector2(472, 796), Vector2(68, 12), Color(0.52, 0.34, 0.24, ember_alpha * 0.62))
	if light_level < 0.74:
		for lamp in [Vector2(424, 822), Vector2(470, 818), Vector2(516, 824)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.1 + lamp.x * 0.03) * 0.008
			draw_circle(lamp, 2.5, Color(0.94, 0.64, 0.32, pulse))
			draw_circle(lamp, 7.0, Color(0.94, 0.64, 0.32, pulse * 0.18))


func _draw_arcade_notice_bloom() -> void:
	var warm_alpha := 0.012 + (1.0 - light_level) * 0.08
	_draw_glow_ellipse(Vector2(1068, 776), Vector2(74, 10), Color(0.98, 0.82, 0.48, warm_alpha))
	_draw_glow_ellipse(Vector2(1074, 736), Vector2(64, 12), Color(0.82, 0.68, 0.42, warm_alpha * 0.68))
	if light_level < 0.72:
		for lamp in [Vector2(1028, 742), Vector2(1070, 738), Vector2(1110, 744)]:
			var pulse := 0.04 + (1.0 - light_level) * 0.1 + sin(time_passed * 2.0 + lamp.x * 0.02) * 0.008
			draw_circle(lamp, 2.5, Color(0.98, 0.84, 0.5, pulse))
			draw_circle(lamp, 7.0, Color(0.98, 0.84, 0.5, pulse * 0.18))


func _draw_window_glow_ribbons() -> void:
	if light_level > 0.84:
		return
	for window in [
		{"center": Vector2(126, 272), "radii": Vector2(18, 8), "color": Color(0.96, 0.78, 0.46, 0.12)},
		{"center": Vector2(274, 268), "radii": Vector2(18, 8), "color": Color(0.96, 0.78, 0.46, 0.12)},
		{"center": Vector2(956, 270), "radii": Vector2(22, 9), "color": Color(0.84, 0.9, 0.96, 0.1)},
		{"center": Vector2(1136, 266), "radii": Vector2(22, 9), "color": Color(0.84, 0.9, 0.96, 0.1)},
		{"center": Vector2(120, 634), "radii": Vector2(22, 10), "color": Color(0.94, 0.56, 0.22, 0.11)},
		{"center": Vector2(284, 640), "radii": Vector2(26, 10), "color": Color(0.94, 0.56, 0.22, 0.11)},
		{"center": Vector2(950, 678), "radii": Vector2(22, 10), "color": Color(0.98, 0.84, 0.52, 0.1)},
		{"center": Vector2(1390, 674), "radii": Vector2(22, 10), "color": Color(0.98, 0.84, 0.52, 0.1)}
	]:
		var color_value: Color = window.get("color", Color.WHITE)
		var alpha_scale := 0.45 + (1.0 - light_level) * 0.8
		color_value.a *= alpha_scale
		_draw_glow_ellipse(window.get("center", Vector2.ZERO), window.get("radii", Vector2(20, 8)), color_value)


func _draw_house_transition_ambient() -> void:
	for house_id in ["slum_house", "dock_house", "factory_house", "exchange_house"]:
		if not house_states.has(house_id):
			continue
		var state: Dictionary = house_states[house_id]
		var glow_boost: float = float(state.get("window_glow_boost", 0.0))
		var warmth: float = float(state.get("residual_warmth", 0.0))
		var doorstep_alpha: float = float(state.get("doorstep_alpha", 0.0))
		if maxf(maxf(glow_boost, warmth), doorstep_alpha) <= 0.03:
			continue
		_draw_house_transition_bloom(house_id, state)


func _draw_house_transition_bloom(house_id: String, state: Dictionary) -> void:
	var spec: Dictionary = _house_transition_spec(house_id)
	var glow_boost: float = float(state.get("window_glow_boost", 0.0))
	var warmth: float = float(state.get("residual_warmth", 0.0))
	var doorstep_alpha: float = float(state.get("doorstep_alpha", 0.0))
	var curve_name: String = str(state.get("window_curve", "plain"))
	var pulse_speed: float = 1.4
	var pulse_span: float = 0.01
	match curve_name:
		"warm_fast":
			pulse_speed = 2.8
			pulse_span = 0.02
		"mist_long":
			pulse_speed = 1.6
			pulse_span = 0.012
		"ember_pulse":
			pulse_speed = 3.2
			pulse_span = 0.028
		"gold_linger":
			pulse_speed = 1.2
			pulse_span = 0.014
	var pulse: float = 0.92 + sin(time_passed * pulse_speed + float(spec.get("pulse_phase", 0.0))) * pulse_span
	var window_color: Color = spec.get("window_color", Color(0.98, 0.84, 0.5, 0.1))
	for center in spec.get("windows", []):
		var window_center: Vector2 = center
		var alpha: float = (0.02 + glow_boost * 0.22) * pulse
		_draw_glow_ellipse(window_center, spec.get("window_radii", Vector2(28, 10)), Color(window_color.r, window_color.g, window_color.b, alpha))
		_draw_glow_ellipse(window_center + Vector2(0, 12), spec.get("trail_radii", Vector2(40, 12)), Color(window_color.r, window_color.g, window_color.b, alpha * 0.42))
	var door_center: Vector2 = spec.get("door", Vector2.ZERO)
	if warmth > 0.04:
		var warmth_color: Color = spec.get("warmth_color", window_color)
		_draw_glow_ellipse(door_center + Vector2(0, 16), spec.get("door_radii", Vector2(54, 16)), Color(warmth_color.r, warmth_color.g, warmth_color.b, 0.02 + warmth * 0.12 * pulse))
	if doorstep_alpha > 0.04:
		var step_color: Color = spec.get("step_color", window_color)
		_draw_glow_ellipse(door_center + Vector2(18, 20), spec.get("step_radii", Vector2(38, 12)), Color(step_color.r, step_color.g, step_color.b, doorstep_alpha * 0.09))
		_draw_glow_ellipse(door_center + Vector2(-14, 26), spec.get("step_radii", Vector2(26, 8)), Color(step_color.r, step_color.g, step_color.b, doorstep_alpha * 0.05))


func _house_transition_spec(house_id: String) -> Dictionary:
	match house_id:
		"dock_house":
			return {
				"windows": [Vector2(1088, 206), Vector2(1182, 206)],
				"window_radii": Vector2(30, 10),
				"trail_radii": Vector2(44, 12),
				"door": Vector2(1134, 266),
				"door_radii": Vector2(60, 18),
				"step_radii": Vector2(34, 10),
				"window_color": Color(0.76, 0.9, 0.96, 0.1),
				"warmth_color": Color(0.66, 0.82, 0.9, 0.08),
				"step_color": Color(0.82, 0.9, 0.96, 0.08),
				"pulse_phase": 0.8,
			}
		"factory_house":
			return {
				"windows": [Vector2(132, 622), Vector2(286, 632)],
				"window_radii": Vector2(28, 10),
				"trail_radii": Vector2(40, 12),
				"door": Vector2(174, 656),
				"door_radii": Vector2(54, 16),
				"step_radii": Vector2(32, 10),
				"window_color": Color(0.96, 0.58, 0.28, 0.11),
				"warmth_color": Color(0.84, 0.34, 0.16, 0.1),
				"step_color": Color(0.94, 0.5, 0.24, 0.08),
				"pulse_phase": 1.9,
			}
		"exchange_house":
			return {
				"windows": [Vector2(1266, 742), Vector2(1380, 738)],
				"window_radii": Vector2(28, 10),
				"trail_radii": Vector2(42, 12),
				"door": Vector2(1314, 792),
				"door_radii": Vector2(56, 16),
				"step_radii": Vector2(34, 10),
				"window_color": Color(0.98, 0.84, 0.52, 0.1),
				"warmth_color": Color(0.92, 0.8, 0.5, 0.08),
				"step_color": Color(0.98, 0.86, 0.58, 0.08),
				"pulse_phase": 2.4,
			}
		_:
			return {
				"windows": [Vector2(126, 272), Vector2(274, 268)],
				"window_radii": Vector2(24, 9),
				"trail_radii": Vector2(34, 10),
				"door": Vector2(178, 262),
				"door_radii": Vector2(48, 14),
				"step_radii": Vector2(28, 8),
				"window_color": Color(0.96, 0.76, 0.44, 0.1),
				"warmth_color": Color(0.86, 0.58, 0.28, 0.08),
				"step_color": Color(0.94, 0.72, 0.42, 0.08),
				"pulse_phase": 0.2,
			}


func _draw_far_city_lights() -> void:
	if light_level > 0.7:
		return
	for light_spec in [
		Vector2(152, 220), Vector2(246, 206), Vector2(418, 212), Vector2(560, 216),
		Vector2(934, 228), Vector2(1088, 222), Vector2(1242, 226), Vector2(1416, 236)
	]:
		var pulse := 0.04 + (1.0 - light_level) * 0.08 + sin(time_passed * 2.0 + light_spec.x * 0.02) * 0.01
		draw_circle(light_spec, 2.0, Color(0.98, 0.84, 0.52, pulse))
		draw_circle(light_spec, 5.0, Color(0.98, 0.84, 0.52, pulse * 0.25))


func _draw_ground_warmth() -> void:
	if light_level > 0.8:
		return
	_draw_glow_ellipse(Vector2(246, 390), Vector2(102, 24), Color(0.94, 0.62, 0.28, 0.025 + (1.0 - light_level) * 0.05))
	_draw_glow_ellipse(Vector2(300, 812), Vector2(74, 18), Color(0.94, 0.44, 0.18, 0.02 + (1.0 - light_level) * 0.04))
	_draw_glow_ellipse(Vector2(1184, 706), Vector2(136, 20), Color(0.96, 0.84, 0.46, 0.018 + (1.0 - light_level) * 0.04))


func _draw_fireflies() -> void:
	if light_level > 0.72:
		return
	for particle in fireflies:
		var origin: Vector2 = particle.get("origin", Vector2.ZERO)
		var phase: float = float(particle.get("phase", 0.0))
		var speed: float = float(particle.get("speed", 0.8))
		var pos := origin + Vector2(
			sin(time_passed * speed + phase) * 18.0,
			cos(time_passed * speed * 0.8 + phase) * 12.0
		)
		var alpha := 0.08 + 0.08 * (1.0 - light_level) + 0.04 * sin(time_passed * 2.0 + phase)
		draw_circle(pos, 2.0, Color(0.98, 0.9, 0.5, alpha))


func _draw_leaves() -> void:
	if leaf_texture == null or light_level < 0.5:
		return
	for particle in leaf_particles:
		var origin: Vector2 = particle.get("origin", Vector2.ZERO)
		var phase: float = float(particle.get("phase", 0.0))
		var speed: float = float(particle.get("speed", 0.2))
		var scale_value: float = float(particle.get("size", 1.0))
		var drift: float = float(particle.get("drift", 24.0))
		var pos := origin + Vector2(
			fmod(time_passed * (16.0 + drift) + phase * 42.0, 1660.0) - 60.0,
			sin(time_passed * speed + phase) * 14.0
		)
		var rect := Rect2(pos, Vector2(leaf_texture.get_width(), leaf_texture.get_height()) * scale_value)
		draw_texture_rect(leaf_texture, rect, false, Color(1, 1, 1, 0.11))


func _draw_embers() -> void:
	if ember_texture == null or light_level > 0.82:
		return
	for index in range(7):
		var phase := time_passed * 0.9 + float(index) * 0.7
		var pos := Vector2(86 + index * 88.0 + sin(phase) * 10.0, 640 - abs(cos(phase * 0.8)) * 74.0)
		var rect := Rect2(pos, Vector2(ember_texture.get_width(), ember_texture.get_height()) * 0.72)
		draw_texture_rect(ember_texture, rect, false, Color(1, 1, 1, 0.12 + 0.05 * (1.0 - light_level)))


func _draw_glow_ellipse(center: Vector2, radii: Vector2, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(24):
		var angle := TAU * float(step) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)
