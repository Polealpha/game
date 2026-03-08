extends RefCounted
class_name WorldLayout

const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(3072, 2048))
const PLAYER_START := Vector2(420, 1080)

const DISTRICT_RECTS := {
	"贫民街": Rect2(60, 320, 940, 1500),
	"港口": Rect2(980, 520, 1040, 1320),
	"工厂区": Rect2(1980, 700, 1030, 1180),
	"交易所": Rect2(1320, 40, 1700, 860),
}

const DISTRICT_LABELS := {
	"贫民街": Vector2(230, 760),
	"港口": Vector2(1230, 820),
	"工厂区": Vector2(2290, 1040),
	"交易所": Vector2(2200, 250),
}

const SUBREGIONS := [
	{
		"id": "forest_farm",
		"name": "左岸台地",
		"district": "贫民街",
		"rect": Rect2(90, 360, 420, 420),
		"center": Vector2(300, 570),
	},
	{
		"id": "courtyard_garden",
		"name": "鱼市前街",
		"district": "贫民街",
		"rect": Rect2(220, 860, 560, 430),
		"center": Vector2(500, 1075),
	},
	{
		"id": "wild_path",
		"name": "坡巷旧屋",
		"district": "贫民街",
		"rect": Rect2(80, 1280, 720, 430),
		"center": Vector2(440, 1495),
	},
	{
		"id": "shipyard_workshop",
		"name": "船坞工坊",
		"district": "港口",
		"rect": Rect2(950, 1180, 620, 560),
		"center": Vector2(1260, 1460),
	},
	{
		"id": "canal_harbor",
		"name": "运河小港",
		"district": "港口",
		"rect": Rect2(1120, 760, 680, 360),
		"center": Vector2(1460, 940),
	},
	{
		"id": "stonebridge_quarter",
		"name": "石桥住区",
		"district": "港口",
		"rect": Rect2(940, 520, 520, 320),
		"center": Vector2(1200, 680),
	},
	{
		"id": "watermill_yard",
		"name": "水车磨坊",
		"district": "工厂区",
		"rect": Rect2(2020, 840, 540, 420),
		"center": Vector2(2290, 1050),
	},
	{
		"id": "stoneyard_workcamp",
		"name": "石院工棚",
		"district": "工厂区",
		"rect": Rect2(2280, 1260, 700, 420),
		"center": Vector2(2630, 1470),
	},
	{
		"id": "clocktower_market",
		"name": "钟楼市场",
		"district": "交易所",
		"rect": Rect2(1830, 120, 760, 420),
		"center": Vector2(2210, 330),
	},
	{
		"id": "rune_tower",
		"name": "符文塔楼",
		"district": "交易所",
		"rect": Rect2(1500, 160, 420, 380),
		"center": Vector2(1710, 350),
	},
	{
		"id": "church_graveyard",
		"name": "教堂墓园",
		"district": "交易所",
		"rect": Rect2(2480, 360, 520, 420),
		"center": Vector2(2740, 570),
	},
]

const INTERACTABLES := [
	{"id": "slum_house", "kind": "house", "title": "壳背小屋", "district": "贫民街", "subtitle": "进屋歇脚、做饭和翻储物箱", "subregion_id": "courtyard_garden", "x": 390, "y": 1010},
	{"id": "slum_market", "kind": "goods", "title": "鱼市小摊", "district": "贫民街", "subtitle": "便宜杂货、旧货和边角消息", "subregion_id": "courtyard_garden", "x": 350, "y": 1210},
	{"id": "rag_broker", "kind": "goods", "title": "旧货经手", "district": "贫民街", "subtitle": "低价杂货与碎布边料流转", "subregion_id": "courtyard_garden", "x": 610, "y": 1010},
	{"id": "charity_board", "kind": "tasks", "title": "坡巷告示板", "district": "贫民街", "subtitle": "委托、差事和急活都贴在这里", "subregion_id": "forest_farm", "x": 250, "y": 820},
	{"id": "forest_stall", "kind": "info", "title": "街口风声", "district": "贫民街", "subtitle": "这里能听到租金和粮价的闲话", "subregion_id": "wild_path", "x": 500, "y": 1320},
	{"id": "dock_labor", "kind": "work", "title": "船坞工牌", "district": "港口", "subtitle": "搬箱、修船和卸缆都在这里领工", "subregion_id": "shipyard_workshop", "x": 1260, "y": 1480},
	{"id": "harbor_broker", "kind": "info", "title": "运河耳报", "district": "港口", "subtitle": "花点钱打听航运和热货", "subregion_id": "canal_harbor", "x": 1470, "y": 960},
	{"id": "dock_house", "kind": "house", "title": "潮木宿屋", "district": "港口", "subtitle": "潮气、绳索和炉火混在一间屋里", "subregion_id": "stonebridge_quarter", "x": 1180, "y": 760},
	{"id": "canal_market", "kind": "goods", "title": "桥头货摊", "district": "港口", "subtitle": "鲜货、盐包和沿河短线消息", "subregion_id": "canal_harbor", "x": 1550, "y": 860},
	{"id": "bridge_notice", "kind": "tasks", "title": "石桥留牌", "district": "港口", "subtitle": "跑腿、接货和找人都从桥头开始", "subregion_id": "canal_harbor", "x": 1360, "y": 900},
	{"id": "factory_house", "kind": "house", "title": "磨坊宿舍", "district": "工厂区", "subtitle": "进屋能歇脚、做饭和看账", "subregion_id": "watermill_yard", "x": 2340, "y": 1040},
	{"id": "foreman_desk", "kind": "work", "title": "工棚值台", "district": "工厂区", "subtitle": "散工、短工和压价差事都在这里接", "subregion_id": "watermill_yard", "x": 2510, "y": 1080},
	{"id": "canteen_supply", "kind": "goods", "title": "磨坊配给", "district": "工厂区", "subtitle": "便宜面包、热汤和工区常备货", "subregion_id": "watermill_yard", "x": 2210, "y": 1260},
	{"id": "rumor_post", "kind": "info", "title": "石院小报", "district": "工厂区", "subtitle": "矿价、工钱和谁要闹事都写在这", "subregion_id": "stoneyard_workcamp", "x": 2620, "y": 1410},
	{"id": "mill_notice", "kind": "tasks", "title": "磨坊白板", "district": "工厂区", "subtitle": "修机、运料和守夜的活在这里接", "subregion_id": "stoneyard_workcamp", "x": 2430, "y": 1240},
	{"id": "exchange_board", "kind": "stocks", "title": "钟楼牌价", "district": "交易所", "subtitle": "买卖三支股票，看资本风向", "subregion_id": "clocktower_market", "x": 2240, "y": 360},
	{"id": "market_whisper", "kind": "info", "title": "市场风报", "district": "交易所", "subtitle": "付费获取宏观传言和盘口消息", "subregion_id": "clocktower_market", "x": 2080, "y": 570},
	{"id": "family_registry", "kind": "tasks", "title": "家族会客簿", "district": "交易所", "subtitle": "查看关系、接差事、领委托", "subregion_id": "rune_tower", "x": 1710, "y": 350},
	{"id": "exchange_house", "kind": "house", "title": "账房公寓", "district": "交易所", "subtitle": "烛台、账桌和锁柜都在屋里", "subregion_id": "church_graveyard", "x": 2740, "y": 470},
	{"id": "day_bell", "kind": "end_day", "title": "钟楼日钟", "district": "交易所", "subtitle": "推进到下一天，结算世界变化", "subregion_id": "clocktower_market", "x": 2300, "y": 250},
	{"id": "chapel_notice", "kind": "info", "title": "墓园耳语", "district": "交易所", "subtitle": "夜里这里会听到更冷的消息", "subregion_id": "church_graveyard", "x": 2770, "y": 700},
]


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
