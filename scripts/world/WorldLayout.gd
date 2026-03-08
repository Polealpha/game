extends RefCounted
class_name WorldLayout

const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(2360, 1480))
const PLAYER_START := Vector2(268, 286)

const DISTRICT_RECTS := {
	"贫民街": Rect2(80, 120, 980, 590),
	"港口": Rect2(1280, 90, 960, 590),
	"工厂区": Rect2(100, 820, 980, 580),
	"交易所": Rect2(1300, 780, 940, 620),
}

const DISTRICT_LABELS := {
	"贫民街": Vector2(132, 150),
	"港口": Vector2(1340, 138),
	"工厂区": Vector2(150, 864),
	"交易所": Vector2(1358, 828),
}

const SUBREGIONS := [
	{
		"id": "forest_farm",
		"name": "森林农庄",
		"district": "贫民街",
		"rect": Rect2(120, 150, 350, 230),
		"center": Vector2(296, 266),
	},
	{
		"id": "courtyard_garden",
		"name": "菜圃庭院",
		"district": "贫民街",
		"rect": Rect2(510, 156, 300, 220),
		"center": Vector2(660, 266),
	},
	{
		"id": "wild_path",
		"name": "林间秘径",
		"district": "贫民街",
		"rect": Rect2(150, 408, 470, 220),
		"center": Vector2(385, 518),
	},
	{
		"id": "shipyard_workshop",
		"name": "船坞工坊",
		"district": "港口",
		"rect": Rect2(1320, 120, 340, 248),
		"center": Vector2(1490, 244),
	},
	{
		"id": "canal_harbor",
		"name": "运河小港",
		"district": "港口",
		"rect": Rect2(1700, 160, 430, 214),
		"center": Vector2(1915, 268),
	},
	{
		"id": "stonebridge_quarter",
		"name": "石桥住区",
		"district": "港口",
		"rect": Rect2(1480, 404, 470, 220),
		"center": Vector2(1715, 514),
	},
	{
		"id": "watermill_yard",
		"name": "水车磨坊",
		"district": "工厂区",
		"rect": Rect2(140, 860, 380, 258),
		"center": Vector2(330, 988),
	},
	{
		"id": "stoneyard_workcamp",
		"name": "石院工棚",
		"district": "工厂区",
		"rect": Rect2(556, 904, 440, 244),
		"center": Vector2(776, 1026),
	},
	{
		"id": "clocktower_market",
		"name": "钟楼市场",
		"district": "交易所",
		"rect": Rect2(1360, 842, 440, 284),
		"center": Vector2(1580, 984),
	},
	{
		"id": "rune_tower",
		"name": "符文塔楼",
		"district": "交易所",
		"rect": Rect2(1850, 826, 270, 270),
		"center": Vector2(1985, 961),
	},
	{
		"id": "church_graveyard",
		"name": "教堂墓园",
		"district": "交易所",
		"rect": Rect2(1700, 1124, 440, 220),
		"center": Vector2(1920, 1234),
	},
]

const INTERACTABLES := [
	{"id": "slum_house", "kind": "house", "title": "壳背小屋", "district": "贫民街", "subtitle": "进屋歇脚、做饭和翻储物箱", "subregion_id": "forest_farm", "x": 268, "y": 262},
	{"id": "slum_market", "kind": "goods", "title": "菜圃小摊", "district": "贫民街", "subtitle": "便宜粮食、旧货和临时倒卖消息", "subregion_id": "courtyard_garden", "x": 664, "y": 286},
	{"id": "rag_broker", "kind": "goods", "title": "补丁货郎", "district": "贫民街", "subtitle": "低价杂货与边角料流转", "subregion_id": "wild_path", "x": 430, "y": 484},
	{"id": "charity_board", "kind": "tasks", "title": "街头告示栏", "district": "贫民街", "subtitle": "家族委托和街坊差事都贴在这里", "subregion_id": "wild_path", "x": 546, "y": 560},
	{"id": "forest_stall", "kind": "info", "title": "林边风声", "district": "贫民街", "subtitle": "这里能打听到谁在涨租谁在挨饿", "subregion_id": "forest_farm", "x": 340, "y": 350},
	{"id": "dock_labor", "kind": "work", "title": "船坞工牌", "district": "港口", "subtitle": "搬箱、修船和扛缆都在这里领工", "subregion_id": "shipyard_workshop", "x": 1488, "y": 258},
	{"id": "harbor_broker", "kind": "info", "title": "运河耳报", "district": "港口", "subtitle": "花点钱打听航运和热货", "subregion_id": "canal_harbor", "x": 1912, "y": 280},
	{"id": "dock_house", "kind": "house", "title": "潮木宿屋", "district": "港口", "subtitle": "潮气、绳索和炉火混在一间屋里", "subregion_id": "stonebridge_quarter", "x": 1774, "y": 500},
	{"id": "canal_market", "kind": "goods", "title": "鱼货码头", "district": "港口", "subtitle": "鲜货、盐包和沿河短线消息", "subregion_id": "canal_harbor", "x": 1804, "y": 334},
	{"id": "bridge_notice", "kind": "tasks", "title": "石桥留言牌", "district": "港口", "subtitle": "跑腿、接货和找人都从这里起", "subregion_id": "stonebridge_quarter", "x": 1608, "y": 548},
	{"id": "factory_house", "kind": "house", "title": "磨坊宿舍", "district": "工厂区", "subtitle": "进屋能歇脚、做饭、翻旧柜和看账", "subregion_id": "watermill_yard", "x": 254, "y": 988},
	{"id": "foreman_desk", "kind": "work", "title": "石院值台", "district": "工厂区", "subtitle": "散工、短工和压价任务都在这接", "subregion_id": "stoneyard_workcamp", "x": 706, "y": 1012},
	{"id": "canteen_supply", "kind": "goods", "title": "磨坊配给", "district": "工厂区", "subtitle": "便宜面包、热汤和工区常备货", "subregion_id": "watermill_yard", "x": 404, "y": 1042},
	{"id": "rumor_post", "kind": "info", "title": "工棚小报", "district": "工厂区", "subtitle": "矿价、工钱和谁要闹事都写在这", "subregion_id": "stoneyard_workcamp", "x": 914, "y": 1004},
	{"id": "mill_notice", "kind": "tasks", "title": "磨坊白板", "district": "工厂区", "subtitle": "修机、运粮和守夜的活在这里接", "subregion_id": "watermill_yard", "x": 314, "y": 1094},
	{"id": "exchange_board", "kind": "stocks", "title": "钟楼席位", "district": "交易所", "subtitle": "买卖三支股票，看资本风向", "subregion_id": "clocktower_market", "x": 1576, "y": 962},
	{"id": "market_whisper", "kind": "info", "title": "市场风报", "district": "交易所", "subtitle": "付费获取宏观传言和盘口消息", "subregion_id": "clocktower_market", "x": 1452, "y": 1090},
	{"id": "family_registry", "kind": "tasks", "title": "家族会客簿", "district": "交易所", "subtitle": "查看关系、接差事、领委托", "subregion_id": "rune_tower", "x": 1986, "y": 906},
	{"id": "exchange_house", "kind": "house", "title": "账房公寓", "district": "交易所", "subtitle": "烛台、账桌和锁柜都在屋里", "subregion_id": "church_graveyard", "x": 2042, "y": 1180},
	{"id": "day_bell", "kind": "end_day", "title": "钟楼日钟", "district": "交易所", "subtitle": "推进到下一天，结算世界变化", "subregion_id": "clocktower_market", "x": 1708, "y": 922},
	{"id": "chapel_notice", "kind": "info", "title": "墓园耳语", "district": "交易所", "subtitle": "夜里这里会听到更冷的消息", "subregion_id": "church_graveyard", "x": 1866, "y": 1232},
]

static func district_names() -> Array[String]:
	var names: Array[String] = []
	for district_name in DISTRICT_RECTS.keys():
		names.append(String(district_name))
	return names


static func interactable_rows() -> Array:
	return INTERACTABLES.duplicate(true)


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
