extends RefCounted
class_name WorldLayout

const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(3072, 2048))
const PLAYER_START := Vector2(2020, 620)
const ROAD_MASK_TEXTURE_PATH := "res://road_layer_2.png"
const ROAD_MASK_WORLD_RECT := Rect2(0.0, 261.89134045077105, 3064.3116672694396, 1559.6682997458058)
const ROAD_MASK_ALPHA_THRESHOLD := 0.3

const DISTRICT_RECTS := {
	"贫民街": Rect2(40, 40, 980, 1120),
	"港口": Rect2(80, 880, 1760, 1080),
	"工厂区": Rect2(1660, 760, 1240, 980),
	"交易所": Rect2(980, 40, 2050, 760),
}

const DISTRICT_LABELS := {
	"贫民街": Vector2(250, 430),
	"港口": Vector2(780, 1500),
	"工厂区": Vector2(2220, 1070),
	"交易所": Vector2(2050, 170),
}

const WALKABLE_RECTS := [
	Rect2(120, 120, 920, 760),
	Rect2(200, 860, 900, 380),
	Rect2(120, 1280, 1260, 590),
	Rect2(940, 220, 760, 560),
	Rect2(980, 840, 720, 720),
	Rect2(1620, 120, 1380, 700),
	Rect2(1660, 860, 1240, 720),
	Rect2(2360, 1360, 460, 320),
]

const WATER_RECTS := [
	Rect2(720, 700, 280, 120),
	Rect2(1130, 910, 320, 430),
	Rect2(760, 1380, 970, 360),
	Rect2(2130, 1490, 520, 120),
]

const BLOCKED_RECTS := [
	Rect2(40, 40, 470, 420),
	Rect2(420, 220, 520, 300),
	Rect2(170, 540, 500, 270),
	Rect2(180, 930, 420, 260),
	Rect2(70, 1310, 430, 360),
	Rect2(510, 900, 420, 280),
	Rect2(980, 490, 620, 330),
	Rect2(1040, 150, 760, 210),
	Rect2(1860, 120, 720, 220),
	Rect2(2590, 80, 430, 290),
	Rect2(1760, 980, 820, 260),
	Rect2(2580, 1080, 420, 290),
	Rect2(2570, 1510, 500, 390),
]

const WATER_AREAS := [
	{"id": "upper_canal", "rect": Rect2(720, 700, 280, 120), "flow": Vector2(1.0, 0.08), "strength": 0.9},
	{"id": "market_basin", "rect": Rect2(1130, 910, 320, 430), "flow": Vector2(0.5, 0.18), "strength": 0.78},
	{"id": "harbor_bay", "rect": Rect2(760, 1380, 970, 360), "flow": Vector2(1.0, 0.02), "strength": 1.0},
	{"id": "east_dock", "rect": Rect2(2130, 1490, 520, 120), "flow": Vector2(0.9, 0.04), "strength": 0.64},
]

const FOUNTAIN_POINTS := [
	{"pos": Vector2(2050, 470), "radius": 64.0},
]

const STREET_LAMPS := [
	Vector2(1960, 430),
	Vector2(2140, 430),
	Vector2(1940, 655),
	Vector2(2160, 655),
	Vector2(980, 1010),
	Vector2(1260, 1080),
	Vector2(1500, 1380),
	Vector2(1830, 1400),
	Vector2(2240, 1370),
	Vector2(2480, 1390),
	Vector2(2750, 1460),
]

const HOUSE_DOORS := {
	"slum_house": Vector2(548, 452),
	"dock_house": Vector2(860, 720),
	"factory_house": Vector2(2240, 1120),
	"exchange_house": Vector2(1370, 804),
	"news_center_1": Vector2(2012, 448),
	"factory_2": Vector2(2240, 1120),
	"food_market_3": Vector2(428, 1688),
	"food_market_4": Vector2(240, 1810),
	"bookstore_5": Vector2(2620, 778),
	"stock_exchange_6": Vector2(1370, 804),
	"capitalist_mansion_7": Vector2(2516, 412),
	"bar_8": Vector2(583, 1183),
	"slum_9": Vector2(760, 420),
	"slum_10": Vector2(220, 520),
}

const SUBREGIONS := [
	{
		"id": "forest_farm",
		"name": "山坡旧屋",
		"district": "贫民街",
		"rect": Rect2(120, 120, 820, 420),
		"center": Vector2(530, 320),
	},
	{
		"id": "courtyard_garden",
		"name": "石阶前场",
		"district": "贫民街",
		"rect": Rect2(180, 520, 760, 520),
		"center": Vector2(520, 760),
	},
	{
		"id": "wild_path",
		"name": "鱼市码头",
		"district": "贫民街",
		"rect": Rect2(80, 1260, 820, 540),
		"center": Vector2(430, 1530),
	},
	{
		"id": "shipyard_workshop",
		"name": "船坞工坊",
		"district": "港口",
		"rect": Rect2(760, 1320, 980, 560),
		"center": Vector2(1240, 1600),
	},
	{
		"id": "canal_harbor",
		"name": "运河小港",
		"district": "港口",
		"rect": Rect2(930, 820, 700, 640),
		"center": Vector2(1270, 1120),
	},
	{
		"id": "stonebridge_quarter",
		"name": "石桥住区",
		"district": "港口",
		"rect": Rect2(520, 620, 580, 520),
		"center": Vector2(800, 860),
	},
	{
		"id": "watermill_yard",
		"name": "机房街段",
		"district": "工厂区",
		"rect": Rect2(1680, 900, 980, 480),
		"center": Vector2(2160, 1140),
	},
	{
		"id": "stoneyard_workcamp",
		"name": "东侧货场",
		"district": "工厂区",
		"rect": Rect2(2040, 1320, 840, 420),
		"center": Vector2(2450, 1530),
	},
	{
		"id": "clocktower_market",
		"name": "钟楼市场",
		"district": "交易所",
		"rect": Rect2(1760, 80, 1240, 640),
		"center": Vector2(2380, 290),
	},
	{
		"id": "rune_tower",
		"name": "券商前厅",
		"district": "交易所",
		"rect": Rect2(1000, 170, 760, 520),
		"center": Vector2(1380, 430),
	},
	{
		"id": "church_graveyard",
		"name": "喷泉广场",
		"district": "交易所",
		"rect": Rect2(1800, 320, 660, 420),
		"center": Vector2(2130, 520),
	},
]

const INTERACTABLES := [
	{"id": "slum_10", "kind": "house", "title": "贫民窟", "district": "贫民街", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "forest_farm", "x": 220, "y": 520},
	{"id": "slum_9", "kind": "house", "title": "贫民窟", "district": "贫民街", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "forest_farm", "x": 760, "y": 420},
	{"id": "slum_house", "kind": "house", "title": "山坡租屋", "district": "贫民街", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "forest_farm", "x": 548, "y": 420},
	{"id": "slum_market", "kind": "goods", "title": "鱼市小摊", "district": "贫民街", "subtitle": "便宜杂货和旧货消息都在这儿", "subregion_id": "wild_path", "x": 260, "y": 1570},
	{"id": "rag_broker", "kind": "goods", "title": "巷口杂铺", "district": "贫民街", "subtitle": "低价散货、旧箱子和临时货单", "subregion_id": "courtyard_garden", "x": 430, "y": 760},
	{"id": "charity_board", "kind": "tasks", "title": "山坡告示牌", "district": "贫民街", "subtitle": "委托、苦活和代办都贴在这里", "subregion_id": "forest_farm", "x": 240, "y": 360},
	{"id": "forest_stall", "kind": "info", "title": "街口风声", "district": "贫民街", "subtitle": "这里能听到租金、粮价和欠账消息", "subregion_id": "courtyard_garden", "x": 720, "y": 900},
	{"id": "bar_8", "kind": "house", "title": "酒吧", "district": "港口", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "stonebridge_quarter", "x": 583, "y": 1100},
	{"id": "food_market_4", "kind": "house", "title": "食品市场", "district": "港口", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "shipyard_workshop", "x": 240, "y": 1730},
	{"id": "food_market_3", "kind": "house", "title": "食品市场", "district": "港口", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "shipyard_workshop", "x": 428, "y": 1600},
	{"id": "dock_labor", "kind": "work", "title": "船坞工牌", "district": "港口", "subtitle": "搬箱、修船和装卸都在这里领工", "subregion_id": "shipyard_workshop", "x": 1430, "y": 1540},
	{"id": "harbor_broker", "kind": "info", "title": "运河耳报", "district": "港口", "subtitle": "花点钱打听航运、热货和谁在抢仓位", "subregion_id": "canal_harbor", "x": 1260, "y": 1080},
	{"id": "dock_house", "kind": "house", "title": "石桥住屋", "district": "港口", "subtitle": "潮木、鱼腥和炉火都留在屋里", "subregion_id": "stonebridge_quarter", "x": 860, "y": 720},
	{"id": "canal_market", "kind": "goods", "title": "桥头货摊", "district": "港口", "subtitle": "沿河短线消息和新鲜货单都在这儿", "subregion_id": "shipyard_workshop", "x": 970, "y": 1510},
	{"id": "bridge_notice", "kind": "tasks", "title": "石桥留言牌", "district": "港口", "subtitle": "跑腿、接货和找人从桥头开始", "subregion_id": "canal_harbor", "x": 980, "y": 1000},
	{"id": "factory_house", "kind": "house", "title": "厂房宿舍", "district": "工厂区", "subtitle": "推门进屋，洗灰、热饭和记账", "subregion_id": "watermill_yard", "x": 2240, "y": 1120},
	{"id": "foreman_desk", "kind": "work", "title": "工头值台", "district": "工厂区", "subtitle": "散工、短工和压价差事都在这里接", "subregion_id": "watermill_yard", "x": 1940, "y": 1200},
	{"id": "canteen_supply", "kind": "goods", "title": "厂区配给", "district": "工厂区", "subtitle": "便宜面包、热汤和工区常备货", "subregion_id": "watermill_yard", "x": 1850, "y": 1440},
	{"id": "rumor_post", "kind": "info", "title": "货场小报", "district": "工厂区", "subtitle": "矿价、工钱和谁要闹事都写在这", "subregion_id": "stoneyard_workcamp", "x": 2520, "y": 1450},
	{"id": "mill_notice", "kind": "tasks", "title": "机房白板", "district": "工厂区", "subtitle": "修机、搬料和守夜的活在这里接", "subregion_id": "watermill_yard", "x": 2070, "y": 980},
	{"id": "news_center_1", "kind": "house", "title": "新闻中心", "district": "交易所", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "church_graveyard", "x": 2012, "y": 360},
	{"id": "capitalist_mansion_7", "kind": "house", "title": "资本家豪宅", "district": "交易所", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "clocktower_market", "x": 2516, "y": 300},
	{"id": "bookstore_5", "kind": "house", "title": "书店", "district": "交易所", "subtitle": "靠近门口后按交互键进入房间。", "subregion_id": "clocktower_market", "x": 2620, "y": 730},
	{"id": "exchange_board", "kind": "stocks", "title": "交易牌价", "district": "交易所", "subtitle": "买卖股票，盯住资本风向", "subregion_id": "clocktower_market", "x": 2190, "y": 220},
	{"id": "market_whisper", "kind": "info", "title": "市场风报", "district": "交易所", "subtitle": "付费获得宏观传言和盘口消息", "subregion_id": "church_graveyard", "x": 2060, "y": 640},
	{"id": "family_registry", "kind": "tasks", "title": "会客前厅", "district": "交易所", "subtitle": "查关系、接差事、领委托", "subregion_id": "rune_tower", "x": 1120, "y": 620},
	{"id": "exchange_house", "kind": "house", "title": "证券交易所", "district": "交易所", "subtitle": "从正门进入券商大厅、交易席和保密金库", "subregion_id": "rune_tower", "x": 1370, "y": 690},
	{"id": "day_bell", "kind": "end_day", "title": "钟楼日钟", "district": "交易所", "subtitle": "推动到下一天，结算世界变化", "subregion_id": "clocktower_market", "x": 2820, "y": 140},
	{"id": "chapel_notice", "kind": "info", "title": "广场耳语", "district": "交易所", "subtitle": "喷泉旁总有人低声交换风向", "subregion_id": "church_graveyard", "x": 2040, "y": 520},
]

static var _road_mask_image: Image = null
static var _road_mask_available := false


static func district_names() -> Array[String]:
	var names: Array[String] = []
	for district_name in DISTRICT_RECTS.keys():
		names.append(String(district_name))
	return names


static func interactable_rows() -> Array:
	return INTERACTABLES.duplicate(true)


static func interactable_by_id(interactable_id: String) -> Dictionary:
	for row in INTERACTABLES:
		if str(row.get("id", "")) == interactable_id:
			return row.duplicate(true)
	return {}


static func district_for_point(pos: Vector2) -> String:
	for district_name in DISTRICT_RECTS.keys():
		var rect: Rect2 = DISTRICT_RECTS[district_name]
		if rect.has_point(pos):
			return String(district_name)
	return "街巷"


static func subregion_for_point(pos: Vector2) -> Dictionary:
	for row in SUBREGIONS:
		var rect: Rect2 = row.get("rect", Rect2())
		if rect.has_point(pos):
			return row.duplicate(true)
	return {}


static func subregion_name_for_point(pos: Vector2) -> String:
	var row := subregion_for_point(pos)
	return String(row.get("name", ""))


static func label_position_for_district(district_name: String) -> Vector2:
	return DISTRICT_LABELS.get(district_name, Vector2.ZERO)


static func is_walkable_point(pos: Vector2) -> bool:
	if not WORLD_RECT.has_point(pos):
		return false
	if _has_road_mask():
		return _is_point_on_road_mask(pos)
	for rect in WATER_RECTS:
		if rect.has_point(pos):
			return false
	for rect in BLOCKED_RECTS:
		if rect.has_point(pos):
			return false
	for rect in WALKABLE_RECTS:
		if rect.has_point(pos):
			return true
	return false


static func snap_to_walkable(pos: Vector2) -> Vector2:
	var clamped := Vector2(
		clampf(pos.x, WORLD_RECT.position.x, WORLD_RECT.end.x),
		clampf(pos.y, WORLD_RECT.position.y, WORLD_RECT.end.y)
	)
	if is_walkable_point(clamped):
		return clamped
	if _has_road_mask():
		return _snap_to_road_mask(clamped)
	var best_point := PLAYER_START
	var best_distance := INF
	for rect in WALKABLE_RECTS:
		var candidate := Vector2(
			clampf(clamped.x, rect.position.x + 6.0, rect.end.x - 6.0),
			clampf(clamped.y, rect.position.y + 6.0, rect.end.y - 6.0)
		)
		if not is_walkable_point(candidate):
			continue
		var distance := clamped.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best_point = candidate
	return best_point


static func _has_road_mask() -> bool:
	if _road_mask_image != null:
		return true
	if _road_mask_available:
		return false
	_road_mask_available = true
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(ROAD_MASK_TEXTURE_PATH)) != OK:
		return false
	_road_mask_image = image
	return true


static func _is_point_on_road_mask(pos: Vector2) -> bool:
	if _road_mask_image == null:
		return false
	if not ROAD_MASK_WORLD_RECT.has_point(pos):
		return false
	var uv := Vector2(
		(pos.x - ROAD_MASK_WORLD_RECT.position.x) / ROAD_MASK_WORLD_RECT.size.x,
		(pos.y - ROAD_MASK_WORLD_RECT.position.y) / ROAD_MASK_WORLD_RECT.size.y
	)
	var px := int(clampf(roundf(uv.x * float(_road_mask_image.get_width() - 1)), 0.0, float(_road_mask_image.get_width() - 1)))
	var py := int(clampf(roundf(uv.y * float(_road_mask_image.get_height() - 1)), 0.0, float(_road_mask_image.get_height() - 1)))
	var color := _road_mask_image.get_pixel(px, py)
	return color.a >= ROAD_MASK_ALPHA_THRESHOLD


static func _snap_to_road_mask(pos: Vector2) -> Vector2:
	if _road_mask_image == null:
		return pos
	var search_center := Vector2(
		clampf(pos.x, ROAD_MASK_WORLD_RECT.position.x, ROAD_MASK_WORLD_RECT.end.x),
		clampf(pos.y, ROAD_MASK_WORLD_RECT.position.y, ROAD_MASK_WORLD_RECT.end.y)
	)
	var best_point := search_center
	var best_distance := INF
	var max_radius := int(maxf(ROAD_MASK_WORLD_RECT.size.x, ROAD_MASK_WORLD_RECT.size.y))
	for radius in range(0, max_radius + 1, 12):
		var sample_count := 16 if radius <= 96 else 28
		for index in range(sample_count):
			var angle := TAU * float(index) / float(sample_count)
			var sample := search_center + Vector2(cos(angle), sin(angle)) * float(radius)
			sample.x = clampf(sample.x, ROAD_MASK_WORLD_RECT.position.x, ROAD_MASK_WORLD_RECT.end.x)
			sample.y = clampf(sample.y, ROAD_MASK_WORLD_RECT.position.y, ROAD_MASK_WORLD_RECT.end.y)
			if not _is_point_on_road_mask(sample):
				continue
			var distance := pos.distance_squared_to(sample)
			if distance < best_distance:
				best_distance = distance
				best_point = sample
		if best_distance < INF:
			return best_point
	var fallback_best := ROAD_MASK_WORLD_RECT.get_center()
	var fallback_distance := INF
	for step_y in range(0, 160):
		var y := ROAD_MASK_WORLD_RECT.position.y + ROAD_MASK_WORLD_RECT.size.y * float(step_y) / 159.0
		for step_x in range(0, 240):
			var x := ROAD_MASK_WORLD_RECT.position.x + ROAD_MASK_WORLD_RECT.size.x * float(step_x) / 239.0
			var sample := Vector2(x, y)
			if not _is_point_on_road_mask(sample):
				continue
			var distance := pos.distance_squared_to(sample)
			if distance < fallback_distance:
				fallback_distance = distance
				fallback_best = sample
	return fallback_best


static func water_areas() -> Array:
	return WATER_AREAS.duplicate(true)


static func street_lamps() -> Array[Vector2]:
	var lamps: Array[Vector2] = []
	for point in STREET_LAMPS:
		lamps.append(point)
	return lamps


static func fountain_points() -> Array:
	return FOUNTAIN_POINTS.duplicate(true)


static func house_door_for_id(house_id: String) -> Vector2:
	return HOUSE_DOORS.get(house_id, PLAYER_START)


static func has_house_door(house_id: String) -> bool:
	return HOUSE_DOORS.has(house_id)
