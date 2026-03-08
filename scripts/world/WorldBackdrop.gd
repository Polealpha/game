extends Node2D
class_name WorldBackdrop

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.18

const ROOM_TEXTURE_PATH := "res://assets/vendor/tiny_wizard/art/room.png"
const CHEST_TEXTURE_PATH := "res://assets/vendor/tiny_wizard/props/chests/normal_chest_closed.png"
const GOLD_CHEST_TEXTURE_PATH := "res://assets/vendor/tiny_wizard/props/chests/gold_chest_closed.png"
const COIN_TEXTURE_PATH := "res://assets/vendor/tiny_wizard/props/items/coin.png"
const KEY_TEXTURE_PATH := "res://assets/vendor/tiny_wizard/props/items/key.png"
const MEDIEVAL_TILESET_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/0-tileset.png"
const MEDIEVAL_STALL_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/1.png"
const MEDIEVAL_SIGN_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/8.png"
const MEDIEVAL_ROOF_HOUSE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/9.png"
const MEDIEVAL_ROOF_HUT_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/10.png"
const MEDIEVAL_WELL_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/11.png"
const MEDIEVAL_ARCH_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/13.png"
const MEDIEVAL_HUT_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/15.png"
const MEDIEVAL_HOUSE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/16.png"
const MEDIEVAL_CASTLE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/17.png"
const MEDIEVAL_TREE_BRIGHT_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/18.png"
const MEDIEVAL_DEAD_TREE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/19.png"
const MEDIEVAL_TREE_DARK_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/20.png"
const MEDIEVAL_FORGE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/background-elements/21.png"
const MEDIEVAL_BARREL_PATH := "res://assets/vendor/superpowers/medieval-fantasy/items/barrel.png"
const MEDIEVAL_CRATE_PATH := "res://assets/vendor/superpowers/medieval-fantasy/items/crate.png"
const MEDIEVAL_WOOD_CHEST_PATH := "res://assets/vendor/superpowers/medieval-fantasy/items/wood-chest-close.png"
const MEDIEVAL_COIN_PATH := "res://assets/vendor/superpowers/medieval-fantasy/items/gold-&-gem/coin.png"
const MEDIEVAL_FROG_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/1.png"
const MEDIEVAL_SHEEP_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/2.png"
const MEDIEVAL_BIRD_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/3.png"
const MEDIEVAL_GOAT_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/4.png"
const MEDIEVAL_DEER_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/5.png"
const MEDIEVAL_HEDGEHOG_PATH := "res://assets/vendor/superpowers/medieval-fantasy/animals/6.png"
const CALCIUM_FOREST_TILESET_PATH := "res://assets/vendor/calciumtrice/forest_tileset.png"
const CALCIUM_TREES_PATH := "res://assets/vendor/calciumtrice/trees.png"
const CALCIUM_MEDIEVAL_EXTERIOR_PATH := "res://assets/vendor/calciumtrice/medieval_tileset_exterior.png"
const SLATES_TILESET_PATH := "res://assets/vendor/ivan_voirol/slates_v2.png"
const TOWN_TILESET_PATH := "res://assets/vendor/downloads/2DRP CCArt RPG Town (32x32).png"
const TIETU_FOREST_STREAM_PATH := "res://tietu/064010546fd86c4f51e947191ae0d7d3.jpg"
const TIETU_FOREST_HOMESTEAD_PATH := "res://tietu/10ce556efb19f1dd428c7958d6093201.jpg"
const TIETU_RUNE_TOWER_PATH := "res://tietu/580efe727365cf086c35e22156c26829.jpg"
const TIETU_CANAL_HARBOR_PATH := "res://tietu/638d266eea7f28b01109aa0a840deaf0.jpg"
const TIETU_FARM_COTTAGE_PATH := "res://tietu/9dca3763313715e28d460a88636ec429.jpg"
const TIETU_CHURCH_PATH := "res://tietu/bff243f036bc6b7e2d7ad7db1cc87be1.jpg"
const TIETU_WATERMILL_PATH := "res://tietu/d3a3054be72c54b4e3abf183942a347a.jpg"
const TIETU_SHIPYARD_PATH := "res://tietu/d4dcfc3c8bd0b21e442a9e00249a11b8.jpg"
const TIETU_MARKET_PATH := "res://tietu/f23e1adc1e91818208d911740ed5e69c.jpg"

const WORLD_RECT := WorldLayout.WORLD_RECT
const DISTRICT_RECTS := WorldLayout.DISTRICT_RECTS
const LOT_LABELS := [
	{"text": "旧面包巷", "position": Vector2(118, 148)},
	{"text": "铁锚栈桥", "position": Vector2(1096, 146)},
	{"text": "灰炉厂门", "position": Vector2(120, 548)},
	{"text": "铜钟大厅", "position": Vector2(1094, 548)}
]

var district_states: Dictionary = {}
var _time := 0.0
var time_period := "day"
var light_level := 1.0
var reference_ground_layer := Node2D.new()
var reference_layer := Node2D.new()
var sprite_layer := Node2D.new()
var room_texture: Texture2D
var chest_texture: Texture2D
var gold_chest_texture: Texture2D
var coin_texture: Texture2D
var key_texture: Texture2D
var medieval_tileset: Texture2D
var medieval_stall_texture: Texture2D
var medieval_sign_texture: Texture2D
var medieval_roof_house_texture: Texture2D
var medieval_roof_hut_texture: Texture2D
var medieval_well_texture: Texture2D
var medieval_arch_texture: Texture2D
var medieval_hut_texture: Texture2D
var medieval_house_texture: Texture2D
var medieval_castle_texture: Texture2D
var medieval_tree_bright_texture: Texture2D
var medieval_dead_tree_texture: Texture2D
var medieval_tree_dark_texture: Texture2D
var medieval_forge_texture: Texture2D
var medieval_barrel_texture: Texture2D
var medieval_crate_texture: Texture2D
var medieval_wood_chest_texture: Texture2D
var medieval_coin_texture: Texture2D
var medieval_frog_texture: Texture2D
var medieval_sheep_texture: Texture2D
var medieval_bird_texture: Texture2D
var medieval_goat_texture: Texture2D
var medieval_deer_texture: Texture2D
var medieval_hedgehog_texture: Texture2D
var calcium_forest_tileset: Texture2D
var calcium_trees_texture: Texture2D
var calcium_medieval_exterior_texture: Texture2D
var slates_tileset: Texture2D
var town_tileset: Texture2D
var tietu_forest_stream_texture: Texture2D
var tietu_forest_homestead_texture: Texture2D
var tietu_rune_tower_texture: Texture2D
var tietu_canal_harbor_texture: Texture2D
var tietu_farm_cottage_texture: Texture2D
var tietu_church_texture: Texture2D
var tietu_watermill_texture: Texture2D
var tietu_shipyard_texture: Texture2D
var tietu_market_texture: Texture2D
var banner_specs: Array = []
var smoke_specs: Array = []
var lantern_specs: Array = []
var critter_specs: Array = []
var redraw_accumulator := 0.0


func _load_png_texture(path: String, chroma_key: Color = Color(-1, -1, -1, -1), tolerance: float = 0.01) -> Texture2D:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	if chroma_key.r >= 0.0:
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel := image.get_pixel(x, y)
				if abs(pixel.r - chroma_key.r) <= tolerance and abs(pixel.g - chroma_key.g) <= tolerance and abs(pixel.b - chroma_key.b) <= tolerance:
					image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
	return ImageTexture.create_from_image(image)


func _ready() -> void:
	room_texture = load(ROOM_TEXTURE_PATH) as Texture2D
	chest_texture = load(CHEST_TEXTURE_PATH) as Texture2D
	gold_chest_texture = load(GOLD_CHEST_TEXTURE_PATH) as Texture2D
	coin_texture = load(COIN_TEXTURE_PATH) as Texture2D
	key_texture = load(KEY_TEXTURE_PATH) as Texture2D
	medieval_tileset = load(MEDIEVAL_TILESET_PATH) as Texture2D
	medieval_stall_texture = load(MEDIEVAL_STALL_PATH) as Texture2D
	medieval_sign_texture = load(MEDIEVAL_SIGN_PATH) as Texture2D
	medieval_roof_house_texture = load(MEDIEVAL_ROOF_HOUSE_PATH) as Texture2D
	medieval_roof_hut_texture = load(MEDIEVAL_ROOF_HUT_PATH) as Texture2D
	medieval_well_texture = load(MEDIEVAL_WELL_PATH) as Texture2D
	medieval_arch_texture = load(MEDIEVAL_ARCH_PATH) as Texture2D
	medieval_hut_texture = load(MEDIEVAL_HUT_PATH) as Texture2D
	medieval_house_texture = load(MEDIEVAL_HOUSE_PATH) as Texture2D
	medieval_castle_texture = load(MEDIEVAL_CASTLE_PATH) as Texture2D
	medieval_tree_bright_texture = load(MEDIEVAL_TREE_BRIGHT_PATH) as Texture2D
	medieval_dead_tree_texture = load(MEDIEVAL_DEAD_TREE_PATH) as Texture2D
	medieval_tree_dark_texture = load(MEDIEVAL_TREE_DARK_PATH) as Texture2D
	medieval_forge_texture = load(MEDIEVAL_FORGE_PATH) as Texture2D
	medieval_barrel_texture = load(MEDIEVAL_BARREL_PATH) as Texture2D
	medieval_crate_texture = load(MEDIEVAL_CRATE_PATH) as Texture2D
	medieval_wood_chest_texture = load(MEDIEVAL_WOOD_CHEST_PATH) as Texture2D
	medieval_coin_texture = load(MEDIEVAL_COIN_PATH) as Texture2D
	medieval_frog_texture = load(MEDIEVAL_FROG_PATH) as Texture2D
	medieval_sheep_texture = load(MEDIEVAL_SHEEP_PATH) as Texture2D
	medieval_bird_texture = load(MEDIEVAL_BIRD_PATH) as Texture2D
	medieval_goat_texture = load(MEDIEVAL_GOAT_PATH) as Texture2D
	medieval_deer_texture = load(MEDIEVAL_DEER_PATH) as Texture2D
	medieval_hedgehog_texture = load(MEDIEVAL_HEDGEHOG_PATH) as Texture2D
	calcium_forest_tileset = _load_png_texture(CALCIUM_FOREST_TILESET_PATH)
	calcium_trees_texture = _load_png_texture(CALCIUM_TREES_PATH)
	calcium_medieval_exterior_texture = _load_png_texture(CALCIUM_MEDIEVAL_EXTERIOR_PATH)
	slates_tileset = _load_png_texture(SLATES_TILESET_PATH, Color(1, 1, 1, 1), 0.012)
	town_tileset = _load_png_texture(TOWN_TILESET_PATH, Color(0, 0, 0, 1), 0.01)
	add_child(reference_ground_layer)
	add_child(sprite_layer)
	add_child(reference_layer)
	sprite_layer.y_sort_enabled = true
	_build_textured_props()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for spec in smoke_specs:
		var bob := 10.0 * sin(_time * float(spec.get("speed", 0.6)) + float(spec.get("phase", 0.0)))
		var node: ColorRect = spec.get("node")
		var origin: Vector2 = spec.get("origin", Vector2.ZERO)
		node.position = origin + Vector2(0, -bob)
		node.modulate.a = 0.3 + 0.18 * sin(_time * float(spec.get("speed", 0.6)) + float(spec.get("phase", 0.0)))
	for spec in critter_specs:
		var sprite: Sprite2D = spec.get("sprite")
		var shadow: Polygon2D = spec.get("shadow")
		if sprite == null or shadow == null:
			continue
		var anchor: Vector2 = spec.get("anchor", Vector2.ZERO)
		var range_x := float(spec.get("range_x", 12.0))
		var range_y := float(spec.get("range_y", 6.0))
		var speed := float(spec.get("speed", 0.8))
		var phase := float(spec.get("phase", 0.0))
		var offset := Vector2(
			sin(_time * speed + phase) * range_x,
			cos(_time * speed * 0.72 + phase) * range_y
		)
		var ground := anchor + offset
		var texture_size := Vector2(sprite.texture.get_width(), sprite.texture.get_height()) * sprite.scale
		sprite.position = ground - Vector2(texture_size.x * 0.5, texture_size.y)
		shadow.position = ground + Vector2(0, 4)
		sprite.flip_h = sin(_time * speed + phase) < 0.0
	redraw_accumulator += delta
	if redraw_accumulator >= REDRAW_INTERVAL:
		redraw_accumulator = 0.0
		queue_redraw()


func set_district_states(rows: Array) -> void:
	for row in rows:
		district_states[str(row.get("name", ""))] = str(row.get("state", "normal"))
	redraw_accumulator = 0.0
	queue_redraw()


func set_time_of_day(period: String, level: float) -> void:
	time_period = period
	light_level = clampf(level, 0.2, 1.0)
	redraw_accumulator = 0.0
	queue_redraw()


func _build_textured_props() -> void:
	for prop in [
		{"texture": medieval_wood_chest_texture, "position": Vector2(208, 340), "scale": Vector2(2.0, 2.0)},
		{"texture": medieval_crate_texture, "position": Vector2(322, 714), "scale": Vector2(2.0, 2.0)},
		{"texture": gold_chest_texture, "position": Vector2(1228, 654), "scale": Vector2(1.28, 1.28)},
		{"texture": chest_texture, "position": Vector2(1450, 240), "scale": Vector2(1.12, 1.12)},
		{"texture": medieval_coin_texture, "position": Vector2(1242, 694), "scale": Vector2(1.7, 1.7)},
		{"texture": key_texture, "position": Vector2(1452, 712), "scale": Vector2(0.88, 0.88)}
	]:
		_add_prop(prop.get("texture"), prop.get("position", Vector2.ZERO), prop.get("scale", Vector2.ONE))

	for banner in [
		{"position": Vector2(136, 152), "color": Color("8f2f33")},
		{"position": Vector2(442, 156), "color": Color("8b6c2d")},
		{"position": Vector2(952, 154), "color": Color("355f82")},
		{"position": Vector2(1360, 154), "color": Color("577d52")},
		{"position": Vector2(146, 550), "color": Color("5e4331")},
		{"position": Vector2(474, 554), "color": Color("7c6036")},
		{"position": Vector2(936, 550), "color": Color("7c6036")},
		{"position": Vector2(1398, 550), "color": Color("8f2f33")}
	]:
		_add_banner(banner.get("position", Vector2.ZERO), banner.get("color", Color.WHITE))

	for puff in [
		{"position": Vector2(158, 560), "speed": 0.56, "phase": 0.0},
		{"position": Vector2(222, 548), "speed": 0.74, "phase": 1.2},
		{"position": Vector2(310, 556), "speed": 0.66, "phase": 0.45},
		{"position": Vector2(520, 600), "speed": 0.72, "phase": 1.8}
	]:
		_add_smoke(puff.get("position", Vector2.ZERO), Color(0.72, 0.72, 0.72, 0.38), float(puff.get("speed", 0.6)), float(puff.get("phase", 0.0)))

	for lantern in [
		Vector2(86, 470), Vector2(756, 470), Vector2(844, 470), Vector2(1518, 470),
		Vector2(800, 96), Vector2(800, 870)
	]:
		lantern_specs.append(lantern)

	for row in LOT_LABELS:
		_add_lot_label(str(row.get("text", "")), row.get("position", Vector2.ZERO))

	_build_medieval_sprite_props()
	_build_calciumtrice_sprite_props()
	_build_slates_sprite_props()
	_build_reference_props()


func _build_reference_props() -> void:
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
		_add_reference_scene_to_layer(reference_ground_layer, _load_reference_plate_texture(folder, stem), rect, 1.0)


func _load_reference_plate_texture(folder: String, stem: String) -> Texture2D:
	if folder.is_empty() or stem.is_empty():
		return null
	return _load_png_texture("res://assets/generated/%s/%s_plate.png" % [folder, stem])


func _add_reference_scene_to_layer(target_layer: Node2D, texture: Texture2D, rect: Rect2, alpha: float = 1.0, tint: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = rect.position
	sprite.scale = Vector2(
		rect.size.x / maxf(float(texture.get_width()), 1.0),
		rect.size.y / maxf(float(texture.get_height()), 1.0)
	)
	sprite.modulate = Color(tint.r, tint.g, tint.b, alpha)
	target_layer.add_child(sprite)


func _add_room_patch(texture: Texture2D, pos: Vector2, scale_value: Vector2, alpha: float) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = scale_value
	sprite.modulate = Color(1, 1, 1, alpha)
	sprite_layer.add_child(sprite)


func _add_prop(texture: Texture2D, pos: Vector2, scale_value: Vector2) -> void:
	if texture == null:
		return
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-20, -10), Vector2(18, -8), Vector2(26, 8), Vector2(-18, 10)
	])
	shadow.position = pos + Vector2(3, 16)
	shadow.color = Color(0, 0, 0, 0.22)
	sprite_layer.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_layer.add_child(sprite)


func _add_grounded_sprite(texture: Texture2D, ground_pos: Vector2, scale_value: Vector2, alpha: float = 1.0, shadow_size: Vector2 = Vector2(22, 10)) -> void:
	if texture == null:
		return
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-shadow_size.x, -shadow_size.y * 0.35),
		Vector2(shadow_size.x, -shadow_size.y * 0.28),
		Vector2(shadow_size.x * 1.18, shadow_size.y * 0.55),
		Vector2(-shadow_size.x * 1.1, shadow_size.y * 0.7)
	])
	shadow.position = ground_pos + Vector2(0, 4)
	shadow.color = Color(0, 0, 0, 0.18 * alpha)
	sprite_layer.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale_value
	sprite.modulate = Color(1, 1, 1, alpha)
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	sprite.position = ground_pos - Vector2(texture_size.x * scale_value.x * 0.5, texture_size.y * scale_value.y)
	sprite_layer.add_child(sprite)


func _add_wander_sprite(texture: Texture2D, ground_pos: Vector2, scale_value: Vector2, range_x: float, range_y: float, speed: float, shadow_size: Vector2) -> void:
	if texture == null:
		return
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-shadow_size.x, -shadow_size.y * 0.35),
		Vector2(shadow_size.x, -shadow_size.y * 0.28),
		Vector2(shadow_size.x * 1.18, shadow_size.y * 0.55),
		Vector2(-shadow_size.x * 1.1, shadow_size.y * 0.7)
	])
	shadow.color = Color(0, 0, 0, 0.13)
	sprite_layer.add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale_value
	sprite_layer.add_child(sprite)
	critter_specs.append({
		"sprite": sprite,
		"shadow": shadow,
		"anchor": ground_pos,
		"range_x": range_x,
		"range_y": range_y,
		"speed": speed,
		"phase": randf() * TAU
	})


func _atlas_region(column: int, row: int, width_tiles: int = 1, height_tiles: int = 1) -> Rect2:
	return Rect2(column * 32, row * 32, width_tiles * 32, height_tiles * 32)


func _atlas_region_size(column: int, row: int, tile_size: Vector2i, width_tiles: int = 1, height_tiles: int = 1) -> Rect2:
	return Rect2(column * tile_size.x, row * tile_size.y, width_tiles * tile_size.x, height_tiles * tile_size.y)


func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


func _add_grounded_region_sprite(texture: Texture2D, region: Rect2, ground_pos: Vector2, scale_value: Vector2, alpha: float = 1.0, shadow_size: Vector2 = Vector2(22, 10)) -> void:
	if texture == null:
		return
	_add_grounded_sprite(_make_atlas_texture(texture, region), ground_pos, scale_value, alpha, shadow_size)


func _add_flat_region_patch(texture: Texture2D, region: Rect2, pos: Vector2, scale_value: Vector2, alpha: float = 0.9) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _make_atlas_texture(texture, region)
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = scale_value
	sprite.modulate = Color(1, 1, 1, alpha)
	sprite_layer.add_child(sprite)


func _build_medieval_sprite_props() -> void:
	for patch in [
		{"origin": Vector2(76, 162), "cols": 18, "rows": 7, "tile": Vector2i(2, 0), "alpha": 0.35},
		{"origin": Vector2(856, 118), "cols": 18, "rows": 3, "tile": Vector2i(4, 0), "alpha": 0.55},
		{"origin": Vector2(866, 206), "cols": 17, "rows": 2, "tile": Vector2i(1, 0), "alpha": 0.4},
		{"origin": Vector2(84, 560), "cols": 16, "rows": 7, "tile": Vector2i(2, 0), "alpha": 0.28},
		{"origin": Vector2(928, 586), "cols": 15, "rows": 6, "tile": Vector2i(3, 0), "alpha": 0.4},
		{"origin": Vector2(1068, 840), "cols": 8, "rows": 3, "tile": Vector2i(0, 0), "alpha": 0.22},
		{"origin": Vector2(118, 846), "cols": 7, "rows": 3, "tile": Vector2i(0, 0), "alpha": 0.22},
		{"origin": Vector2(74, 436), "cols": 8, "rows": 2, "tile": Vector2i(1, 0), "alpha": 0.24},
		{"origin": Vector2(1248, 436), "cols": 9, "rows": 2, "tile": Vector2i(1, 0), "alpha": 0.24},
		{"origin": Vector2(724, 84), "cols": 3, "rows": 10, "tile": Vector2i(3, 0), "alpha": 0.2},
		{"origin": Vector2(418, 790), "cols": 5, "rows": 2, "tile": Vector2i(2, 0), "alpha": 0.26},
		{"origin": Vector2(516, 92), "cols": 6, "rows": 3, "tile": Vector2i(0, 0), "alpha": 0.22},
		{"origin": Vector2(1260, 82), "cols": 8, "rows": 3, "tile": Vector2i(0, 0), "alpha": 0.22},
		{"origin": Vector2(92, 874), "cols": 10, "rows": 2, "tile": Vector2i(0, 0), "alpha": 0.22},
		{"origin": Vector2(1044, 874), "cols": 11, "rows": 2, "tile": Vector2i(0, 0), "alpha": 0.22}
	]:
		_add_tile_patch(
			patch.get("origin", Vector2.ZERO),
			int(patch.get("cols", 1)),
			int(patch.get("rows", 1)),
			patch.get("tile", Vector2i.ZERO),
			float(patch.get("alpha", 0.25))
		)

	for spec in [
		{"texture": medieval_roof_hut_texture, "ground": Vector2(114, 226), "scale": Vector2(2.8, 2.8), "shadow": Vector2(26, 11)},
		{"texture": medieval_hut_texture, "ground": Vector2(212, 228), "scale": Vector2(2.8, 2.8), "shadow": Vector2(24, 11)},
		{"texture": medieval_roof_house_texture, "ground": Vector2(344, 228), "scale": Vector2(2.9, 2.9), "shadow": Vector2(25, 11)},
		{"texture": medieval_house_texture, "ground": Vector2(470, 246), "scale": Vector2(2.85, 2.85), "shadow": Vector2(26, 11)},
		{"texture": medieval_stall_texture, "ground": Vector2(178, 336), "scale": Vector2(2.7, 2.7), "shadow": Vector2(22, 9)},
		{"texture": medieval_stall_texture, "ground": Vector2(354, 328), "scale": Vector2(2.5, 2.5), "shadow": Vector2(22, 9)},
		{"texture": medieval_stall_texture, "ground": Vector2(554, 332), "scale": Vector2(2.35, 2.35), "shadow": Vector2(20, 9)},
		{"texture": medieval_sign_texture, "ground": Vector2(650, 348), "scale": Vector2(2.35, 2.35), "shadow": Vector2(14, 7)},
		{"texture": medieval_barrel_texture, "ground": Vector2(134, 352), "scale": Vector2(1.95, 1.95), "shadow": Vector2(14, 7)},
		{"texture": medieval_barrel_texture, "ground": Vector2(588, 320), "scale": Vector2(1.85, 1.85), "shadow": Vector2(14, 7)},
		{"texture": medieval_crate_texture, "ground": Vector2(622, 326), "scale": Vector2(1.85, 1.85), "shadow": Vector2(14, 7)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(72, 176), "scale": Vector2(3.05, 3.05), "shadow": Vector2(30, 12)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(184, 168), "scale": Vector2(2.82, 2.82), "shadow": Vector2(28, 11)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(288, 436), "scale": Vector2(2.8, 2.8), "shadow": Vector2(28, 11)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(622, 164), "scale": Vector2(2.92, 2.92), "shadow": Vector2(30, 12)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(712, 422), "scale": Vector2(3.1, 3.1), "shadow": Vector2(32, 13)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(782, 384), "scale": Vector2(2.84, 2.84), "shadow": Vector2(28, 11)},
		{"texture": medieval_arch_texture, "ground": Vector2(1218, 240), "scale": Vector2(3.0, 3.0), "shadow": Vector2(32, 13)},
		{"texture": medieval_roof_house_texture, "ground": Vector2(938, 308), "scale": Vector2(2.8, 2.8), "shadow": Vector2(26, 11)},
		{"texture": medieval_house_texture, "ground": Vector2(1108, 308), "scale": Vector2(2.95, 2.95), "shadow": Vector2(28, 12)},
		{"texture": medieval_roof_hut_texture, "ground": Vector2(1286, 306), "scale": Vector2(2.75, 2.75), "shadow": Vector2(24, 10)},
		{"texture": medieval_sign_texture, "ground": Vector2(1118, 342), "scale": Vector2(2.05, 2.05), "shadow": Vector2(13, 6)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(880, 154), "scale": Vector2(3.0, 3.0), "shadow": Vector2(30, 12)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1528, 194), "scale": Vector2(2.95, 2.95), "shadow": Vector2(28, 11)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1442, 160), "scale": Vector2(2.72, 2.72), "shadow": Vector2(26, 10)},
		{"texture": medieval_crate_texture, "ground": Vector2(1462, 330), "scale": Vector2(1.9, 1.9), "shadow": Vector2(14, 6)},
		{"texture": medieval_barrel_texture, "ground": Vector2(1492, 326), "scale": Vector2(1.9, 1.9), "shadow": Vector2(14, 6)},
		{"texture": medieval_crate_texture, "ground": Vector2(972, 338), "scale": Vector2(1.85, 1.85), "shadow": Vector2(14, 6)},
		{"texture": medieval_barrel_texture, "ground": Vector2(1010, 344), "scale": Vector2(1.85, 1.85), "shadow": Vector2(14, 6)},
		{"texture": medieval_forge_texture, "ground": Vector2(126, 664), "scale": Vector2(3.0, 3.0), "shadow": Vector2(30, 12)},
		{"texture": medieval_forge_texture, "ground": Vector2(294, 676), "scale": Vector2(2.8, 2.8), "shadow": Vector2(28, 11)},
		{"texture": medieval_house_texture, "ground": Vector2(504, 674), "scale": Vector2(2.85, 2.85), "shadow": Vector2(28, 12)},
		{"texture": medieval_house_texture, "ground": Vector2(666, 668), "scale": Vector2(2.65, 2.65), "shadow": Vector2(26, 11)},
		{"texture": medieval_dead_tree_texture, "ground": Vector2(72, 834), "scale": Vector2(2.75, 2.75), "shadow": Vector2(24, 10)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(310, 888), "scale": Vector2(2.88, 2.88), "shadow": Vector2(28, 11)},
		{"texture": medieval_barrel_texture, "ground": Vector2(592, 770), "scale": Vector2(2.0, 2.0), "shadow": Vector2(14, 7)},
		{"texture": medieval_crate_texture, "ground": Vector2(628, 754), "scale": Vector2(1.9, 1.9), "shadow": Vector2(14, 7)},
		{"texture": medieval_castle_texture, "ground": Vector2(1182, 692), "scale": Vector2(3.7, 3.7), "shadow": Vector2(38, 15)},
		{"texture": medieval_house_texture, "ground": Vector2(956, 822), "scale": Vector2(2.55, 2.55), "shadow": Vector2(24, 10)},
		{"texture": medieval_house_texture, "ground": Vector2(1326, 816), "scale": Vector2(2.55, 2.55), "shadow": Vector2(24, 10)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(938, 846), "scale": Vector2(2.95, 2.95), "shadow": Vector2(28, 12)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(1494, 844), "scale": Vector2(2.95, 2.95), "shadow": Vector2(28, 12)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1226, 926), "scale": Vector2(2.7, 2.7), "shadow": Vector2(26, 10)},
		{"texture": medieval_well_texture, "ground": Vector2(1392, 744), "scale": Vector2(2.4, 2.4), "shadow": Vector2(18, 8)},
		{"texture": medieval_well_texture, "ground": Vector2(1092, 816), "scale": Vector2(2.2, 2.2), "shadow": Vector2(17, 8)},
		{"texture": medieval_arch_texture, "ground": Vector2(1020, 822), "scale": Vector2(2.8, 2.8), "shadow": Vector2(28, 11)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(482, 126), "scale": Vector2(3.2, 3.2), "shadow": Vector2(32, 13)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1354, 112), "scale": Vector2(3.1, 3.1), "shadow": Vector2(31, 12)},
		{"texture": medieval_dead_tree_texture, "ground": Vector2(1478, 842), "scale": Vector2(3.0, 3.0), "shadow": Vector2(26, 11)},
		{"texture": medieval_hut_texture, "ground": Vector2(546, 122), "scale": Vector2(2.8, 2.8), "shadow": Vector2(24, 10)},
		{"texture": medieval_hut_texture, "ground": Vector2(1462, 878), "scale": Vector2(2.8, 2.8), "shadow": Vector2(24, 10)},
		{"texture": medieval_hut_texture, "ground": Vector2(188, 892), "scale": Vector2(2.6, 2.6), "shadow": Vector2(22, 10)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(412, 94), "scale": Vector2(2.6, 2.6), "shadow": Vector2(26, 10)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(642, 110), "scale": Vector2(2.7, 2.7), "shadow": Vector2(26, 10)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1184, 98), "scale": Vector2(2.7, 2.7), "shadow": Vector2(26, 10)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(1532, 126), "scale": Vector2(2.7, 2.7), "shadow": Vector2(26, 10)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(144, 930), "scale": Vector2(2.45, 2.45), "shadow": Vector2(24, 10)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(412, 934), "scale": Vector2(2.68, 2.68), "shadow": Vector2(26, 10)},
		{"texture": medieval_tree_bright_texture, "ground": Vector2(1088, 930), "scale": Vector2(2.55, 2.55), "shadow": Vector2(24, 10)},
		{"texture": medieval_tree_dark_texture, "ground": Vector2(1342, 940), "scale": Vector2(2.72, 2.72), "shadow": Vector2(26, 10)},
		{"texture": medieval_sheep_texture, "ground": Vector2(1246, 890), "scale": Vector2(2.0, 2.0), "shadow": Vector2(15, 7)},
		{"texture": medieval_goat_texture, "ground": Vector2(1160, 902), "scale": Vector2(2.0, 2.0), "shadow": Vector2(15, 7)},
		{"texture": medieval_deer_texture, "ground": Vector2(1418, 906), "scale": Vector2(2.22, 2.22), "shadow": Vector2(18, 8)},
		{"texture": medieval_frog_texture, "ground": Vector2(214, 402), "scale": Vector2(1.85, 1.85), "shadow": Vector2(12, 6)},
		{"texture": medieval_bird_texture, "ground": Vector2(1516, 336), "scale": Vector2(1.85, 1.85), "shadow": Vector2(12, 6)},
		{"texture": medieval_hedgehog_texture, "ground": Vector2(548, 906), "scale": Vector2(1.8, 1.8), "shadow": Vector2(11, 5)}
	]:
		_add_grounded_sprite(
			spec.get("texture"),
			spec.get("ground", Vector2.ZERO),
			spec.get("scale", Vector2.ONE),
			1.0,
			spec.get("shadow", Vector2(22, 10))
		)

	for critter in [
		{"texture": medieval_frog_texture, "ground": Vector2(182, 402), "scale": Vector2(1.75, 1.75), "range_x": 18.0, "range_y": 6.0, "speed": 1.0, "shadow": Vector2(10, 5)},
		{"texture": medieval_bird_texture, "ground": Vector2(1484, 340), "scale": Vector2(1.7, 1.7), "range_x": 22.0, "range_y": 7.0, "speed": 1.15, "shadow": Vector2(10, 5)},
		{"texture": medieval_sheep_texture, "ground": Vector2(1194, 894), "scale": Vector2(1.9, 1.9), "range_x": 24.0, "range_y": 8.0, "speed": 0.55, "shadow": Vector2(14, 6)},
		{"texture": medieval_bird_texture, "ground": Vector2(596, 106), "scale": Vector2(1.6, 1.6), "range_x": 16.0, "range_y": 5.0, "speed": 1.0, "shadow": Vector2(9, 4)},
		{"texture": medieval_deer_texture, "ground": Vector2(1328, 908), "scale": Vector2(2.2, 2.2), "range_x": 24.0, "range_y": 9.0, "speed": 0.42, "shadow": Vector2(18, 8)},
		{"texture": medieval_goat_texture, "ground": Vector2(284, 912), "scale": Vector2(2.0, 2.0), "range_x": 16.0, "range_y": 7.0, "speed": 0.6, "shadow": Vector2(14, 6)}
	]:
		_add_wander_sprite(
			critter.get("texture"),
			critter.get("ground", Vector2.ZERO),
			critter.get("scale", Vector2.ONE),
			float(critter.get("range_x", 12.0)),
			float(critter.get("range_y", 6.0)),
			float(critter.get("speed", 0.8)),
			critter.get("shadow", Vector2(10, 5))
		)


func _build_calciumtrice_sprite_props() -> void:
	var tree_tile_size := Vector2i(96, 112)
	var exterior_tile_size := Vector2i(32, 32)
	for tree in [
		{"variant": Vector2i(0, 0), "ground": Vector2(58, 188), "scale": Vector2(1.42, 1.42), "shadow": Vector2(34, 13)},
		{"variant": Vector2i(1, 0), "ground": Vector2(244, 178), "scale": Vector2(1.36, 1.36), "shadow": Vector2(32, 12)},
		{"variant": Vector2i(0, 1), "ground": Vector2(704, 198), "scale": Vector2(1.38, 1.38), "shadow": Vector2(33, 12)},
		{"variant": Vector2i(1, 1), "ground": Vector2(806, 402), "scale": Vector2(1.34, 1.34), "shadow": Vector2(31, 12)},
		{"variant": Vector2i(1, 0), "ground": Vector2(1486, 194), "scale": Vector2(1.34, 1.34), "shadow": Vector2(31, 12)},
		{"variant": Vector2i(0, 1), "ground": Vector2(1216, 132), "scale": Vector2(1.28, 1.28), "shadow": Vector2(30, 11)},
		{"variant": Vector2i(1, 2), "ground": Vector2(86, 850), "scale": Vector2(1.18, 1.18), "shadow": Vector2(22, 9)},
		{"variant": Vector2i(0, 2), "ground": Vector2(1468, 858), "scale": Vector2(1.24, 1.24), "shadow": Vector2(24, 9)},
		{"variant": Vector2i(0, 0), "ground": Vector2(342, 930), "scale": Vector2(1.3, 1.3), "shadow": Vector2(30, 11)},
		{"variant": Vector2i(1, 1), "ground": Vector2(1084, 944), "scale": Vector2(1.34, 1.34), "shadow": Vector2(32, 12)},
		{"variant": Vector2i(0, 1), "ground": Vector2(1438, 926), "scale": Vector2(1.36, 1.36), "shadow": Vector2(32, 12)},
		{"variant": Vector2i(1, 1), "ground": Vector2(22, 240), "scale": Vector2(1.52, 1.52), "shadow": Vector2(36, 13)},
		{"variant": Vector2i(0, 0), "ground": Vector2(1578, 236), "scale": Vector2(1.5, 1.5), "shadow": Vector2(36, 13)},
		{"variant": Vector2i(0, 1), "ground": Vector2(18, 936), "scale": Vector2(1.44, 1.44), "shadow": Vector2(34, 12)},
		{"variant": Vector2i(1, 0), "ground": Vector2(1582, 926), "scale": Vector2(1.46, 1.46), "shadow": Vector2(35, 12)}
	]:
		_add_grounded_region_sprite(
			calcium_trees_texture,
			_atlas_region_size(tree.get("variant", Vector2i.ZERO).x, tree.get("variant", Vector2i.ZERO).y, tree_tile_size),
			tree.get("ground", Vector2.ZERO),
			tree.get("scale", Vector2.ONE),
			1.0,
			tree.get("shadow", Vector2(30, 12))
		)

	for patch in [
		{"region": _atlas_region_size(0, 0, exterior_tile_size, 5, 3), "position": Vector2(96, 834), "scale": Vector2(0.94, 0.94), "alpha": 0.8},
		{"region": _atlas_region_size(0, 0, exterior_tile_size, 5, 3), "position": Vector2(1096, 838), "scale": Vector2(0.98, 0.98), "alpha": 0.82},
		{"region": _atlas_region_size(0, 4, exterior_tile_size, 3, 2), "position": Vector2(336, 848), "scale": Vector2(0.94, 0.94), "alpha": 0.78},
		{"region": _atlas_region_size(0, 4, exterior_tile_size, 3, 2), "position": Vector2(1380, 850), "scale": Vector2(0.9, 0.9), "alpha": 0.78},
		{"region": _atlas_region_size(0, 0, exterior_tile_size, 3, 2), "position": Vector2(1294, 78), "scale": Vector2(0.82, 0.82), "alpha": 0.66},
		{"region": _atlas_region_size(0, 4, exterior_tile_size, 3, 2), "position": Vector2(118, 82), "scale": Vector2(0.8, 0.8), "alpha": 0.62},
		{"region": _atlas_region_size(0, 6, exterior_tile_size, 3, 2), "position": Vector2(690, 120), "scale": Vector2(0.86, 0.86), "alpha": 0.68},
		{"region": _atlas_region_size(0, 6, exterior_tile_size, 3, 2), "position": Vector2(654, 860), "scale": Vector2(0.9, 0.9), "alpha": 0.72}
	]:
		_add_flat_region_patch(
			calcium_medieval_exterior_texture,
			patch.get("region", Rect2()),
			patch.get("position", Vector2.ZERO),
			patch.get("scale", Vector2.ONE),
			float(patch.get("alpha", 0.8))
		)

	for building in [
		{"region": _atlas_region_size(5, 1, exterior_tile_size, 4, 4), "ground": Vector2(210, 912), "scale": Vector2(1.02, 1.02), "shadow": Vector2(34, 12)},
		{"region": _atlas_region_size(5, 1, exterior_tile_size, 4, 4), "ground": Vector2(1422, 170), "scale": Vector2(0.96, 0.96), "shadow": Vector2(30, 11)},
		{"region": _atlas_region_size(5, 1, exterior_tile_size, 4, 4), "ground": Vector2(1484, 910), "scale": Vector2(1.0, 1.0), "shadow": Vector2(34, 12)}
	]:
		_add_grounded_region_sprite(
			calcium_medieval_exterior_texture,
			building.get("region", Rect2()),
			building.get("ground", Vector2.ZERO),
			building.get("scale", Vector2.ONE),
			0.96,
			building.get("shadow", Vector2(30, 11))
		)

	for patch in [
		{"region": _atlas_region(0, 0, 4, 4), "position": Vector2(120, 286), "scale": Vector2(0.64, 0.64), "alpha": 0.24},
		{"region": _atlas_region(0, 0, 4, 4), "position": Vector2(430, 290), "scale": Vector2(0.58, 0.58), "alpha": 0.18},
		{"region": _atlas_region(0, 0, 4, 4), "position": Vector2(964, 214), "scale": Vector2(0.52, 0.52), "alpha": 0.14},
		{"region": _atlas_region(0, 0, 4, 4), "position": Vector2(280, 742), "scale": Vector2(0.56, 0.56), "alpha": 0.18}
	]:
		_add_flat_region_patch(
			calcium_forest_tileset,
			patch.get("region", Rect2()),
			patch.get("position", Vector2.ZERO),
			patch.get("scale", Vector2.ONE),
			float(patch.get("alpha", 0.2))
		)


func _build_slates_sprite_props() -> void:
	if slates_tileset == null:
		return
	var pine_region := Rect2(252, 418, 133, 176)
	var round_tree_region := Rect2(385, 418, 63, 93)
	var bridge_water_region := Rect2(490, 471, 142, 73)
	for tree in [
		{"region": pine_region, "ground": Vector2(404, 154), "scale": Vector2(0.84, 0.84), "shadow": Vector2(26, 10)},
		{"region": pine_region, "ground": Vector2(1266, 146), "scale": Vector2(0.78, 0.78), "shadow": Vector2(24, 9)},
		{"region": pine_region, "ground": Vector2(104, 924), "scale": Vector2(0.76, 0.76), "shadow": Vector2(24, 9)},
		{"region": pine_region, "ground": Vector2(1044, 932), "scale": Vector2(0.82, 0.82), "shadow": Vector2(25, 10)},
		{"region": round_tree_region, "ground": Vector2(648, 394), "scale": Vector2(0.92, 0.92), "shadow": Vector2(18, 8)},
		{"region": round_tree_region, "ground": Vector2(1502, 398), "scale": Vector2(0.9, 0.9), "shadow": Vector2(18, 8)},
		{"region": round_tree_region, "ground": Vector2(900, 846), "scale": Vector2(0.86, 0.86), "shadow": Vector2(18, 8)},
		{"region": round_tree_region, "ground": Vector2(1324, 846), "scale": Vector2(0.86, 0.86), "shadow": Vector2(18, 8)}
	]:
		_add_grounded_region_sprite(
			slates_tileset,
			tree.get("region", Rect2()),
			tree.get("ground", Vector2.ZERO),
			tree.get("scale", Vector2.ONE),
			0.94,
			tree.get("shadow", Vector2(18, 8))
		)
	for strip in [
		{"position": Vector2(868, 146), "scale": Vector2(0.9, 0.9), "alpha": 0.92},
		{"position": Vector2(996, 160), "scale": Vector2(0.86, 0.86), "alpha": 0.88},
		{"position": Vector2(1128, 176), "scale": Vector2(0.82, 0.82), "alpha": 0.84}
	]:
		_add_flat_region_patch(
			slates_tileset,
			bridge_water_region,
			strip.get("position", Vector2.ZERO),
			strip.get("scale", Vector2.ONE),
			float(strip.get("alpha", 0.9))
		)


func _add_tile_patch(origin: Vector2, cols: int, rows: int, atlas_tile: Vector2i, alpha: float = 0.24) -> void:
	if medieval_tileset == null:
		return
	var region := _atlas_region(atlas_tile.x, atlas_tile.y)
	for row in range(rows):
		for column in range(cols):
			var jitter_x := 3.0 if row % 2 == 0 else -2.0
			var offset := origin + Vector2(column * 30.0 + jitter_x, row * 28.0)
			var atlas := AtlasTexture.new()
			atlas.atlas = medieval_tileset
			atlas.region = region
			var sprite := Sprite2D.new()
			sprite.texture = atlas
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.modulate = Color(1, 1, 1, alpha)
			sprite.position = offset
			sprite_layer.add_child(sprite)


func _add_banner(pos: Vector2, color_value: Color) -> void:
	var pole := Line2D.new()
	pole.width = 5
	pole.default_color = Color("3a2415")
	pole.points = PackedVector2Array([pos, pos + Vector2(0, 88)])
	sprite_layer.add_child(pole)
	banner_specs.append({"origin": pos + Vector2(0, 8), "color": color_value})


func _add_lot_label(text_value: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = pos + Vector2(8, 4)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("f0dfb6"))
	sprite_layer.add_child(label)


func _add_smoke(pos: Vector2, color_value: Color, speed: float, phase: float) -> void:
	var puff := ColorRect.new()
	puff.color = color_value
	puff.position = pos
	puff.size = Vector2(24, 24)
	puff.rotation = 0.34
	sprite_layer.add_child(puff)
	smoke_specs.append({"node": puff, "origin": pos, "speed": speed, "phase": phase})


func _draw() -> void:
	_draw_foundation()
	_draw_horizon_layers()
	_draw_district_grounds()
	_draw_transition_bands()
	_draw_crossroads()
	_draw_outskirts()
	_draw_slum()
	_draw_port()
	_draw_factory()
	_draw_exchange()
	_draw_subregion_expansions()
	_draw_lot_labels()
	_draw_banners()
	_draw_lanterns()
	_draw_border()


func _draw_foundation() -> void:
	draw_rect(WORLD_RECT, Color("3b3327"), true)
	_draw_meadow_patch(PackedVector2Array([
		Vector2(0, 0), Vector2(462, 0), Vector2(590, 180), Vector2(428, 356), Vector2(0, 294)
	]), Color("5a5d37"))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1030, 0), Vector2(1600, 0), Vector2(1600, 266), Vector2(1452, 338), Vector2(1184, 246)
	]), Color("505f3d"))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(0, 720), Vector2(286, 642), Vector2(442, 728), Vector2(402, 980), Vector2(0, 980)
	]), Color("58643d"))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1228, 690), Vector2(1600, 742), Vector2(1600, 980), Vector2(1128, 980), Vector2(1080, 816)
	]), Color("55613b"))
	for stripe in range(18):
		var y := 24 + stripe * 54
		draw_line(Vector2(0, y), Vector2(1600, y), Color(1, 1, 1, 0.012), 1.0)
	for column in range(18):
		var x := 20 + column * 88
		draw_line(Vector2(x, 0), Vector2(x, 980), Color(0, 0, 0, 0.03), 1.0)
	_draw_ground_tufts(Rect2(0, 0, 1600, 980), 86, Color("68764a"), Color("4f5d39"))
	_draw_root_arcs(Rect2(0, 0, 1600, 980), 42, Color(0.18, 0.12, 0.08, 0.12))
	_draw_scatter_stones()
	var darkness := 1.0 - light_level
	if darkness > 0.02:
		draw_rect(WORLD_RECT, Color(0.05, 0.09, 0.18, darkness * 0.28), true)


func _draw_horizon_layers() -> void:
	var sky_top := Color("9aa0bd").darkened((1.0 - light_level) * 0.38)
	var sky_mid := Color("c7b7c1").darkened((1.0 - light_level) * 0.24)
	var sky_low := Color("d2b49a").darkened((1.0 - light_level) * 0.14)
	for band in range(12):
		var ratio := float(band) / 11.0
		var color_value := sky_top.lerp(sky_mid, min(ratio * 1.5, 1.0)).lerp(sky_low, max(0.0, ratio - 0.35) / 0.65)
		draw_rect(Rect2(0, band * 28, 1600, 30), color_value, true)
	_draw_sun_disk(Vector2(1284, 112), 58.0)
	_draw_distant_canopy_band(Vector2(0, 122), 17, Color(0.35, 0.39, 0.42, 0.55), 88.0)
	_draw_distant_canopy_band(Vector2(36, 148), 15, Color(0.3, 0.35, 0.37, 0.72), 72.0)
	_draw_distant_roofline(Vector2(94, 204), 7, Color(0.26, 0.22, 0.19, 0.42))
	_draw_distant_roofline(Vector2(926, 218), 6, Color(0.24, 0.21, 0.18, 0.38))
	_draw_cloud_bank(Vector2(1108, 88), 4, Color(1, 1, 1, 0.16))
	_draw_cloud_bank(Vector2(1332, 146), 3, Color(1, 1, 1, 0.12))


func _draw_district_grounds() -> void:
	for district_name in DISTRICT_RECTS.keys():
		var rect: Rect2 = DISTRICT_RECTS[district_name]
		var fill := _district_color(district_name)
		var shape := _district_shape(district_name)
		var bounds := _polygon_bounds(shape)
		var zone := 0
		if rect.position.y < 400.0 and rect.position.x >= 800.0:
			zone = 1
		elif rect.position.y >= 400.0 and rect.position.x < 800.0:
			zone = 2
		elif rect.position.y >= 400.0:
			zone = 3
		_draw_ground_shape(shape, fill)
		_draw_district_shape_details(shape, bounds, zone, fill)
		_draw_shape_feather(shape, fill)


func _draw_transition_bands() -> void:
	_draw_meadow_patch(PackedVector2Array([
		Vector2(30, 102), Vector2(220, 88), Vector2(386, 124), Vector2(350, 184), Vector2(126, 196), Vector2(18, 150)
	]), Color(0.34, 0.39, 0.24, 0.82))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(698, 86), Vector2(924, 92), Vector2(918, 220), Vector2(796, 258), Vector2(700, 196)
	]), Color(0.31, 0.36, 0.25, 0.76))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(654, 466), Vector2(918, 454), Vector2(968, 604), Vector2(846, 664), Vector2(672, 618), Vector2(626, 532)
	]), Color(0.35, 0.29, 0.2, 0.72))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(40, 792), Vector2(196, 754), Vector2(322, 808), Vector2(278, 936), Vector2(96, 952), Vector2(22, 894)
	]), Color(0.33, 0.39, 0.24, 0.7))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1108, 812), Vector2(1378, 820), Vector2(1512, 878), Vector2(1464, 952), Vector2(1218, 968), Vector2(1090, 902)
	]), Color(0.35, 0.4, 0.25, 0.72))
	_draw_dirt_path(PackedVector2Array([
		Vector2(704, 138), Vector2(766, 186), Vector2(810, 246), Vector2(824, 340), Vector2(814, 448)
	]), 22.0)
	_draw_road_shoulder(PackedVector2Array([
		Vector2(704, 138), Vector2(766, 186), Vector2(810, 246), Vector2(824, 340), Vector2(814, 448)
	]), 34.0, Color(0.34, 0.37, 0.24, 0.34), Color(0.52, 0.45, 0.3, 0.22))
	_draw_dirt_path(PackedVector2Array([
		Vector2(748, 540), Vector2(682, 620), Vector2(600, 700), Vector2(522, 788)
	]), 18.0)
	_draw_road_shoulder(PackedVector2Array([
		Vector2(748, 540), Vector2(682, 620), Vector2(600, 700), Vector2(522, 788)
	]), 30.0, Color(0.34, 0.31, 0.22, 0.34), Color(0.5, 0.43, 0.28, 0.2))
	_draw_ground_tufts(Rect2(690, 104, 196, 784), 24, Color("6e7c51"), Color("4d5938"))
	_draw_ground_tufts(Rect2(54, 786, 298, 158), 18, Color("728051"), Color("4d5937"))
	_draw_shrub_cluster(Vector2(708, 206), 6, Color("56663f"), Color("6d8052"))
	_draw_shrub_cluster(Vector2(708, 676), 5, Color("4b5738"), Color("627447"))
	_draw_drainage_ditch(PackedVector2Array([
		Vector2(628, 118), Vector2(680, 186), Vector2(706, 264), Vector2(724, 384), Vector2(714, 512), Vector2(664, 690), Vector2(610, 824)
	]), 18.0)
	_draw_wetland_band(PackedVector2Array([
		Vector2(628, 118), Vector2(680, 186), Vector2(706, 264), Vector2(724, 384), Vector2(714, 512), Vector2(664, 690), Vector2(610, 824)
	]), 34.0, Color(0.28, 0.34, 0.27, 0.28), Color(0.22, 0.29, 0.31, 0.32))
	_draw_flat_bridge(Vector2(684, 220), 46.0)
	_draw_flat_bridge(Vector2(702, 548), 52.0)
	_draw_bridgehead_node(Vector2(684, 220), Vector2(122, 64), false)
	_draw_bridgehead_node(Vector2(702, 548), Vector2(144, 74), true)


func _district_shape(name: String) -> PackedVector2Array:
	match name:
		"港口":
			return PackedVector2Array([
				Vector2(836, 116), Vector2(1038, 98), Vector2(1276, 106), Vector2(1478, 142),
				Vector2(1554, 220), Vector2(1546, 332), Vector2(1456, 408), Vector2(1248, 438),
				Vector2(1010, 420), Vector2(858, 356), Vector2(826, 234)
			])
		"工厂区":
			return PackedVector2Array([
				Vector2(48, 510), Vector2(248, 494), Vector2(496, 510), Vector2(686, 554),
				Vector2(744, 636), Vector2(730, 786), Vector2(620, 850), Vector2(386, 872),
				Vector2(168, 848), Vector2(62, 772), Vector2(42, 620)
			])
		"交易所":
			return PackedVector2Array([
				Vector2(876, 528), Vector2(1054, 504), Vector2(1298, 512), Vector2(1490, 558),
				Vector2(1558, 648), Vector2(1554, 798), Vector2(1456, 856), Vector2(1232, 878),
				Vector2(1020, 862), Vector2(894, 796), Vector2(860, 642)
			])
		_:
			return PackedVector2Array([
				Vector2(38, 128), Vector2(238, 108), Vector2(514, 126), Vector2(688, 162),
				Vector2(748, 244), Vector2(736, 358), Vector2(648, 430), Vector2(410, 450),
				Vector2(186, 426), Vector2(54, 360), Vector2(34, 238)
			])


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_x := points[0].x
	var min_y := points[0].y
	var max_x := points[0].x
	var max_y := points[0].y
	for point in points:
		min_x = minf(min_x, point.x)
		min_y = minf(min_y, point.y)
		max_x = maxf(max_x, point.x)
		max_y = maxf(max_y, point.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _draw_ground_shape(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	for index in range(points.size()):
		var start := points[index]
		var ending := points[(index + 1) % points.size()]
		draw_line(start, ending, fill.darkened(0.14), 2.0)


func _draw_shape_feather(points: PackedVector2Array, fill: Color) -> void:
	for index in range(points.size()):
		var current := points[index]
		var prev := points[(index - 1 + points.size()) % points.size()]
		var nxt := points[(index + 1) % points.size()]
		var inward := (prev + nxt) * 0.5
		var center := current.lerp(inward, 0.18)
		draw_circle(center, 18.0 + float(index % 3) * 5.0, Color(fill.r, fill.g, fill.b, 0.12))
		draw_circle(center + Vector2(6.0, -4.0), 8.0 + float(index % 2) * 3.0, Color(fill.r, fill.g, fill.b, 0.08))


func _draw_district_shape_details(points: PackedVector2Array, bounds: Rect2, zone: int, fill: Color) -> void:
	var inset := bounds.grow(-26.0)
	for row in range(7):
		for column in range(12):
			var patch_pos := inset.position + Vector2(18.0 + column * 56.0, 14.0 + row * 42.0)
			var patch_center := patch_pos + Vector2(18.0, 12.0)
			if not Geometry2D.is_point_in_polygon(patch_center, points):
				continue
			var shade := 0.02 * sin(float(row * 17 + column * 11))
			draw_rect(Rect2(patch_pos, Vector2(36.0, 24.0)), fill.lightened(shade), true)
			if (row + column) % 3 == 0:
				draw_rect(Rect2(patch_pos + Vector2(8.0, 6.0), Vector2(14.0, 6.0)), fill.darkened(0.05), true)
	for index in range(18):
		var ratio := float(index) / 18.0
		var center := Vector2(
			inset.position.x + fmod(34.0 + ratio * inset.size.x * 1.27 + float(index * 21), maxf(inset.size.x, 28.0)),
			inset.position.y + fmod(22.0 + ratio * inset.size.y * 1.19 + float(index * 33), maxf(inset.size.y, 24.0))
		)
		if not Geometry2D.is_point_in_polygon(center, points):
			continue
		_draw_ground_detail_point(center, zone, fill, index)
	_draw_polygon_edge_breakup(points, fill)


func _draw_ground_detail_point(center: Vector2, zone: int, fill: Color, index: int) -> void:
	match zone:
		0:
			_draw_ellipse(center, Vector2(10.0 + float(index % 3) * 2.0, 4.0), Color(0.26, 0.18, 0.13, 0.18))
			draw_line(center + Vector2(-3, 7), center + Vector2(-5, -3), Color("687848"), 1.5)
			draw_line(center + Vector2(1, 7), center + Vector2(2, -5), Color("798c56"), 1.4)
		1:
			draw_rect(Rect2(center - Vector2(8.0, 3.0), Vector2(16.0, 6.0)), Color(0.77, 0.76, 0.67, 0.14), true)
			draw_line(center + Vector2(-4, 6), center + Vector2(-6, -4), Color("6c7c4a"), 1.3)
			draw_line(center + Vector2(2, 6), center + Vector2(5, -2), Color("8aa063"), 1.1)
		2:
			_draw_ellipse(center, Vector2(9.0, 4.0), Color(0.18, 0.13, 0.1, 0.22))
			draw_rect(Rect2(center + Vector2(-2.0, -2.0), Vector2(4.0, 4.0)), Color(0.56, 0.42, 0.22, 0.18), true)
		3:
			draw_rect(Rect2(center - Vector2(8.0, 4.0), Vector2(16.0, 8.0)), fill.lightened(0.16), true)
			draw_rect(Rect2(center - Vector2(6.0, 2.0), Vector2(12.0, 4.0)), fill.darkened(0.1), false, 1.0)
			draw_circle(center + Vector2(0.0, -8.0), 3.0, Color("73864f"))


func _draw_polygon_edge_breakup(points: PackedVector2Array, fill: Color) -> void:
	for index in range(points.size()):
		var start := points[index]
		var ending := points[(index + 1) % points.size()]
		for step in range(2):
			var ratio := float(step + 1) / 3.0
			var point := start.lerp(ending, ratio)
			var radius := 10.0 + float((index + step) % 3) * 3.0
			draw_circle(point, radius, Color(fill.r, fill.g, fill.b, 0.12))
			draw_circle(point + Vector2(4.0, -2.0), radius * 0.46, Color(fill.r, fill.g, fill.b, 0.07))


func _draw_harbor_water() -> void:
	var deep_water := PackedVector2Array([
		Vector2(842, 94), Vector2(1026, 90), Vector2(1246, 100), Vector2(1442, 120),
		Vector2(1558, 148), Vector2(1558, 216), Vector2(1458, 206), Vector2(1272, 204),
		Vector2(1060, 210), Vector2(888, 214), Vector2(842, 202)
	])
	var shore_water := PackedVector2Array([
		Vector2(848, 122), Vector2(1042, 116), Vector2(1236, 122), Vector2(1418, 138),
		Vector2(1552, 164), Vector2(1552, 204), Vector2(1462, 196), Vector2(1288, 192),
		Vector2(1100, 194), Vector2(930, 200), Vector2(848, 204)
	])
	draw_colored_polygon(deep_water, Color("274b62"))
	draw_colored_polygon(shore_water, Color("2f6077"))
	for index in range(shore_water.size() - 1):
		var start := shore_water[index]
		var ending := shore_water[index + 1]
		draw_line(start, ending, Color(0.78, 0.9, 0.96, 0.16), 2.0)
	for index in range(shore_water.size() - 1):
		var start := shore_water[index]
		var ending := shore_water[index + 1]
		var midpoint := start.lerp(ending, 0.5) + Vector2(0.0, 6.0 + sin(_time * 1.8 + float(index)) * 2.0)
		draw_arc(midpoint, 12.0 + float(index % 2) * 2.0, PI * 1.04, PI * 1.96, 10, Color(0.9, 0.96, 0.99, 0.24), 1.4)


func _draw_tile_noise(rect: Rect2, base_color: Color) -> void:
	for row in range(6):
		for column in range(11):
			var patch_pos := rect.position + Vector2(18 + column * 62, 18 + row * 46)
			var shade := 0.02 * sin(float(row * 17 + column * 11))
			draw_rect(Rect2(patch_pos, Vector2(42, 28)), base_color.lightened(shade), true)
	_draw_brush_strokes(rect, base_color.darkened(0.05), 18)
	_draw_ink_hatching(rect, 44.0, 0.03)
	_draw_root_arcs(rect.grow(-12), 7, Color(0.12, 0.08, 0.05, 0.08))


func _draw_ground_tufts(rect: Rect2, count: int, bright: Color, dark: Color) -> void:
	for index in range(count):
		var ratio: float = float(index) / maxf(float(count), 1.0)
		var x := rect.position.x + fmod(34.0 + ratio * rect.size.x * 1.37 + float(index * 19), rect.size.x)
		var y := rect.position.y + fmod(20.0 + ratio * rect.size.y * 1.11 + float(index * 31), rect.size.y)
		var base := Vector2(x, y)
		draw_line(base, base + Vector2(-4, -10), dark, 2.0)
		draw_line(base, base + Vector2(0, -12), bright, 2.0)
		draw_line(base, base + Vector2(5, -9), dark.lightened(0.08), 1.6)
		if index % 3 == 0:
			draw_circle(base + Vector2(0, -2), 1.8, Color(dark.r, dark.g, dark.b, 0.16))


func _draw_root_arcs(rect: Rect2, count: int, color_value: Color) -> void:
	for index in range(count):
		var ratio: float = float(index) / maxf(float(count), 1.0)
		var center := Vector2(
			rect.position.x + fmod(48.0 + ratio * rect.size.x * 1.21 + float(index * 23), rect.size.x),
			rect.position.y + fmod(28.0 + ratio * rect.size.y * 1.39 + float(index * 17), rect.size.y)
		)
		draw_arc(center, 7.0 + float(index % 4), PI * 0.15, PI * 0.95, 10, color_value, 1.2)
		if index % 2 == 0:
			draw_line(center + Vector2(-4, 0), center + Vector2(-10, 6), color_value, 1.0)
			draw_line(center + Vector2(4, 0), center + Vector2(10, 6), color_value, 1.0)


func _draw_crossroads() -> void:
	var east_west := PackedVector2Array([
		Vector2(0, 470), Vector2(200, 450), Vector2(530, 466), Vector2(820, 494),
		Vector2(1180, 470), Vector2(1600, 490), Vector2(1600, 560), Vector2(1200, 540),
		Vector2(820, 570), Vector2(470, 530), Vector2(180, 548), Vector2(0, 540)
	])
	var north_south := PackedVector2Array([
		Vector2(730, 0), Vector2(804, 0), Vector2(836, 162), Vector2(830, 356),
		Vector2(862, 610), Vector2(846, 980), Vector2(744, 980), Vector2(730, 642),
		Vector2(714, 378), Vector2(700, 164)
	])
	_draw_road_shoulder(east_west, 56.0, Color(0.28, 0.24, 0.18, 0.28), Color(0.52, 0.44, 0.3, 0.16))
	_draw_road_shoulder(north_south, 48.0, Color(0.26, 0.22, 0.17, 0.26), Color(0.48, 0.42, 0.28, 0.14))
	_draw_road_strip(east_west, Color("71583a"), Color("d8bf88"))
	_draw_road_strip(north_south, Color("6d5436"), Color("d8bf88"))
	_draw_dirt_path(PackedVector2Array([
		Vector2(86, 418), Vector2(216, 472), Vector2(338, 506), Vector2(482, 526), Vector2(640, 558)
	]), 18.0)
	_draw_dirt_path(PackedVector2Array([
		Vector2(980, 512), Vector2(1104, 538), Vector2(1268, 568), Vector2(1444, 610)
	]), 16.0)
	_draw_dirt_path(PackedVector2Array([
		Vector2(762, 286), Vector2(714, 214), Vector2(632, 166), Vector2(552, 130), Vector2(474, 102)
	]), 14.0)
	for column in range(13):
		_draw_lamp_post(Vector2(134 + column * 110, 504 + sin(float(column) * 0.6) * 4.0))
	_draw_stone_seams(Rect2(758, 44, 84, 836), true)
	_draw_stone_seams(Rect2(44, 456, 1512, 78), false)
	_draw_roadside_scrub(Rect2(52, 430, 1498, 142), 20, Color("617245"), Color("495738"))
	_draw_wagon_ruts(Rect2(120, 474, 1320, 48), 18)
	_draw_crossroad_blend(Vector2(800, 506), Vector2(208, 92), Color(0.58, 0.46, 0.3, 0.18))


func _draw_slum() -> void:
	_draw_shack(Vector2(98, 248), Color("5a4330"))
	_draw_shack(Vector2(248, 244), Color("744f34"))
	_draw_shack(Vector2(388, 258), Color("66472e"))
	_draw_lean_to(Vector2(566, 270), Vector2(76, 32), Color("6a4a2f"), Color("8a6b42"))
	_draw_market_stall(Vector2(164, 300), Color("5b412a"), Color("8f6236"))
	_draw_market_stall(Vector2(500, 296), Color("533b28"), Color("87653a"))
	_draw_clothesline(Vector2(120, 226), Vector2(300, 226))
	_draw_clothesline(Vector2(344, 218), Vector2(512, 218))
	_draw_clothesline(Vector2(494, 236), Vector2(672, 248))
	_draw_broken_cart(Vector2(610, 308))
	_draw_window_glow(Rect2(122, 266, 10, 10))
	_draw_window_glow(Rect2(274, 262, 10, 10))
	_draw_window_glow(Rect2(418, 276, 10, 10))
	for index in range(5):
		var bush_pos := Vector2(122 + index * 118, 392 + 6 * sin(_time * 0.7 + index))
		draw_circle(bush_pos, 18.0, Color("5b6840"))
		draw_circle(bush_pos + Vector2(6, 6), 9.0, Color("43311f"))
	_draw_fence_run(Vector2(120, 348), 4)
	draw_rect(Rect2(430, 252, 184, 16), Color("4b3523"), true)
	draw_rect(Rect2(430, 268, 184, 20), Color("896c45"), true)
	draw_rect(Rect2(124, 334, 290, 14), Color("8a6c3c"), true)
	draw_rect(Rect2(438, 256, 20, 90), Color("3e281a"), true)
	_draw_mud_patch(Rect2(86, 360, 222, 44), Color("4a3629"))
	_draw_mud_patch(Rect2(342, 366, 196, 36), Color("50382a"))
	_draw_barrel_group(Vector2(674, 330), 3)
	_draw_tree_cluster(Vector2(72, 152), 3, Color("5c7040"))
	_draw_tree_cluster(Vector2(712, 404), 4, Color("50623a"))
	_draw_patchwork_roof(Vector2(92, 166), Vector2(78, 14))
	_draw_patchwork_roof(Vector2(304, 166), Vector2(84, 14))
	_draw_patchwork_roof(Vector2(520, 234), Vector2(82, 14))
	_draw_clutter_bundle(Vector2(136, 344), 4)
	_draw_clutter_bundle(Vector2(564, 308), 3)
	_draw_puddle_cluster(Vector2(238, 392), 3)
	_draw_puddle_cluster(Vector2(484, 388), 2)
	_draw_bucket_row(Vector2(626, 358), 3)
	_draw_shrub_cluster(Vector2(78, 410), 6, Color("4f5e39"), Color("66784b"))
	_draw_barrel_group(Vector2(398, 326), 2)
	_draw_flat_yard(Rect2(110, 286, 128, 56), Color("5a432f"), Color("7d6544"))
	_draw_flat_yard(Rect2(280, 280, 118, 52), Color("5e4430"), Color("826848"))
	_draw_alley_posts(Vector2(150, 252), 4, 44.0)
	_draw_alley_posts(Vector2(444, 266), 4, 38.0)
	_draw_stall_counter(Vector2(178, 338), 4, Color("7f5c37"))
	_draw_stall_counter(Vector2(512, 334), 3, Color("775535"))
	_draw_dirt_path(PackedVector2Array([
		Vector2(88, 278), Vector2(194, 312), Vector2(316, 330), Vector2(440, 324), Vector2(612, 346)
	]), 14.0)
	_draw_crook_chimneys(Vector2(142, 212), 3, Color("4d3422"))
	_draw_courtyard_flags(Rect2(236, 286, 118, 48), Color("8f2f33"), Color("cfb06e"))
	_draw_market_threshold_node(Rect2(182, 286, 224, 92), Color("6a4a31"), Color("8e673b"), false)
	_draw_slum_main_lane(Rect2(132, 258, 522, 118), Color("5f452f"), Color("856544"))
	_draw_night_bazaar_row(Rect2(146, 304, 454, 82), Color("67472f"), Color("a77a43"))
	_draw_laundry_backyard_alley(Rect2(428, 244, 172, 138), Color("654731"), Color("8f2f33"))
	_draw_corner_hearth(Rect2(92, 320, 104, 92), Color("5e4330"), Color("9e6a32"))


func _draw_port() -> void:
	_draw_harbor_water()
	_draw_palisade_run(Vector2(856, 234), 11, 46.0, Color("6d5238"), Color("4c311f"))
	_draw_warehouse(Vector2(900, 242))
	_draw_warehouse(Vector2(1076, 238))
	_draw_shack(Vector2(1278, 252), Color("4f6576"))
	_draw_dry_fish_rack(Vector2(1188, 288), 4)
	for index in range(18):
		var wave_x := 858 + index * 38
		var wave_y := 154 + 7 * sin(_time * 2.0 + index)
		draw_line(Vector2(wave_x, wave_y), Vector2(wave_x + 24, wave_y + 3), Color(0.82, 0.92, 0.98, 0.34), 2.0)
	_draw_window_glow(Rect2(950, 262, 16, 14))
	_draw_window_glow(Rect2(1128, 258, 16, 14))
	_draw_window_glow(Rect2(1304, 274, 12, 12))
	for index in range(7):
		var pier_x := 902 + index * 78
		draw_rect(Rect2(pier_x, 198, 18, 86), Color("5a3c27"), true)
		draw_rect(Rect2(pier_x - 18, 240, 54, 18), Color("84603d"), true)
	_draw_crane(Vector2(1366, 244))
	_draw_boat(Vector2(936, 168), Color("5f3c2c"))
	_draw_boat(Vector2(1188, 182), Color("4f2d22"))
	_draw_rope_coil(Vector2(1000, 334))
	_draw_rope_coil(Vector2(1288, 338))
	_draw_net_rack(Vector2(944, 334))
	_draw_net_rack(Vector2(1162, 330))
	_draw_barrel_group(Vector2(1476, 318), 4)
	_draw_plank_walkway(Rect2(864, 208, 626, 28), 14)
	_draw_tree_cluster(Vector2(1540, 162), 2, Color("627a48"))
	_draw_mooring_posts(Vector2(894, 250), 7)
	_draw_fish_crates(Vector2(1378, 334), 3)
	_draw_buoy_pair(Vector2(1084, 192))
	_draw_buoy_pair(Vector2(1328, 178))
	_draw_shrub_cluster(Vector2(1490, 374), 4, Color("5b6a43"), Color("708451"))
	_draw_harbor_masts(Vector2(944, 214), 4)
	_draw_shore_reeds(Rect2(850, 198, 684, 26), 22, Color("88a167"), Color("6f8252"))
	_draw_jetty_rubble(Vector2(1422, 342), 6)
	_draw_ramp_run(Vector2(888, 286), 5)
	_draw_chain_moorings(Vector2(930, 254), 6)
	_draw_branch_jetty(Vector2(1206, 236), 3, Color("7b5637"))
	_draw_tide_steps(Vector2(1494, 244), 4, Color("7b6042"))
	_draw_harbor_spine_view(Rect2(904, 236, 418, 112), Color("7b583a"), Color("9b7752"))
	_draw_dock_loading_apron(Rect2(1034, 248, 318, 110), Color("715338"), Color("9b7752"))
	_draw_fish_market_wet_stalls(Rect2(1328, 252, 196, 118), Color("75553b"), Color("8ba273"))
	_draw_ship_repair_corner(Rect2(1458, 214, 108, 146), Color("6f5137"), Color("8d7350"))
	_draw_rope_wet_alley(Rect2(1188, 246, 112, 132), Color("654936"), Color("7c8f7b"))
	_draw_stake_net_beach(Rect2(1368, 318, 172, 92), Color("71553a"), Color("8ca06c"))


func _draw_factory() -> void:
	_draw_factory_building(Vector2(84, 596))
	_draw_foundry(Vector2(244, 586))
	_draw_factory_building(Vector2(514, 600))
	_draw_sawtooth_hall(Vector2(382, 590), Vector2(134, 78), 4)
	_draw_boiler_tanks(Vector2(88, 730), 2)
	for index in range(3):
		_draw_coal_heap(Vector2(110 + index * 84, 748))
	_draw_window_glow(Rect2(110, 626, 16, 16))
	_draw_window_glow(Rect2(282, 632, 18, 18))
	_draw_window_glow(Rect2(540, 630, 16, 16))
	_draw_track(Vector2(510, 742), 6)
	_draw_gatehouse(Vector2(632, 624))
	_draw_pipe_run(Vector2(84, 686), 5)
	_draw_slag_pool(Vector2(420, 784), Vector2(88, 26))
	_draw_slag_pool(Vector2(288, 822), Vector2(62, 18))
	_draw_catwalk(Vector2(254, 660), 3)
	_draw_tree_cluster(Vector2(62, 812), 2, Color("4e5b36"))
	_draw_gear_pile(Vector2(562, 758))
	_draw_gear_pile(Vector2(664, 724))
	_draw_smokestack_cluster(Vector2(154, 564), 3)
	_draw_warning_lantern(Vector2(688, 640))
	_draw_warning_lantern(Vector2(562, 786))
	_draw_mud_patch(Rect2(92, 760, 144, 28), Color("382821"))
	_draw_pipe_bridge(Vector2(302, 650), 4)
	_draw_scrap_scatter(Rect2(92, 704, 244, 104), 14)
	_draw_scrap_scatter(Rect2(430, 704, 250, 118), 12)
	_draw_rail_siding(Vector2(402, 748), 5)
	_draw_conveyor_frame(Vector2(572, 646), 4)
	_draw_loading_yard(Rect2(452, 704, 176, 62), Color("5e4a37"), Color("80664b"))
	_draw_factory_outbound_yard(Rect2(432, 714, 252, 104), Color("5b4735"), Color("836348"))
	_draw_smokestack_worker_corridor(Rect2(112, 606, 228, 152), Color("4a372a"), Color("71553e"))
	_draw_factory_ash_drain(Rect2(74, 804, 286, 72), Color("332822"), Color("615041"))
	_draw_coal_sack_loading_bay(Rect2(388, 724, 164, 84), Color("554333"), Color("2c2522"))


func _draw_exchange() -> void:
	_draw_exchange_hall(Rect2(992, 554, 360, 112))
	_draw_townhouse(Vector2(918, 652))
	_draw_townhouse(Vector2(1352, 648))
	_draw_clock_tower(Vector2(1410, 560))
	_draw_square_plaza(Rect2(928, 600, 486, 178))
	_draw_statue(Vector2(1230, 604))
	_draw_ticker_board(Vector2(954, 588))
	_draw_hedge_row(Vector2(914, 782), 7)
	_draw_arcade_columns(Rect2(988, 586, 330, 168))
	_draw_planter(Vector2(912, 744))
	_draw_planter(Vector2(1370, 742))
	_draw_bench(Vector2(1034, 772))
	_draw_bench(Vector2(1284, 772))
	_draw_tree_cluster(Vector2(1498, 790), 3, Color("627846"))
	_draw_fountain(Vector2(1184, 700))
	_draw_flag_row(Vector2(928, 570), 6, Color("8f2f33"), Color("6f8a43"))
	_draw_carriage(Vector2(1424, 736))
	_draw_window_glow(Rect2(948, 674, 16, 16))
	_draw_window_glow(Rect2(1382, 670, 16, 16))
	_draw_lamp_post(Vector2(972, 768))
	_draw_lamp_post(Vector2(1388, 768))
	_draw_planter(Vector2(1118, 772))
	_draw_planter(Vector2(1210, 772))
	_draw_parterre(Rect2(1008, 786, 122, 40), Color("566d43"), Color("7a9157"))
	_draw_parterre(Rect2(1240, 786, 126, 40), Color("566d43"), Color("7a9157"))
	_draw_arcade_shadow_band(Rect2(988, 738, 330, 18))
	_draw_plaza_mosaic(Vector2(1180, 690), 4)
	_draw_side_arcade(Vector2(914, 650), 3, Color("d7c192"), Color("705236"))
	_draw_side_arcade(Vector2(1352, 646), 3, Color("d7c192"), Color("705236"))
	_draw_market_threshold_node(Rect2(1020, 744, 306, 96), Color("756143"), Color("cfb985"), true)
	_draw_exchange_edge_stalls(Rect2(944, 782, 476, 72), Color("7a5f42"), Color("d3ba84"))
	_draw_exchange_steps_forecourt(Rect2(1036, 676, 286, 128), Color("a6885c"), Color("cfb985"))
	_draw_exchange_arcade_stall_band(Rect2(974, 744, 356, 96), Color("766145"), Color("cdb681"))
	_draw_exchange_service_alley(Rect2(1340, 610, 148, 154), Color("6d563e"), Color("b99862"))
	_draw_stone_courtyard_garden(Rect2(1332, 612, 168, 168), Color("8d826c"), Color("6d8a54"))
	_draw_arcade_notice_wall(Rect2(990, 640, 158, 116), Color("8a7c64"), Color("c8b17a"))


func _draw_outskirts() -> void:
	_draw_tree_cluster(Vector2(488, 88), 5, Color("617643"))
	_draw_tree_cluster(Vector2(1358, 84), 4, Color("556b3c"))
	_draw_tree_cluster(Vector2(1478, 600), 5, Color("5d7342"))
	_draw_tree_cluster(Vector2(514, 892), 4, Color("627846"))
	_draw_tree_cluster(Vector2(42, 212), 5, Color("4d6339"))
	_draw_tree_cluster(Vector2(1560, 238), 5, Color("4d6339"))
	_draw_tree_cluster(Vector2(40, 900), 6, Color("50663d"))
	_draw_tree_cluster(Vector2(1562, 892), 6, Color("51663d"))
	_draw_treeline_band(Vector2(72, 92), 10, Color("48603a"), Color("617844"))
	_draw_treeline_band(Vector2(1050, 88), 8, Color("435937"), Color("5f7546"))
	_draw_treeline_band(Vector2(56, 910), 7, Color("4b603d"), Color("6b7d4b"))
	_draw_treeline_band(Vector2(1048, 924), 8, Color("475d39"), Color("657c49"))
	_draw_treeline_band(Vector2(12, 176), 5, Color("445836"), Color("5c7245"))
	_draw_treeline_band(Vector2(1306, 178), 5, Color("425634"), Color("5a7144"))
	_draw_treeline_band(Vector2(10, 858), 5, Color("455937"), Color("607646"))
	_draw_treeline_band(Vector2(1312, 856), 5, Color("455937"), Color("607646"))
	_draw_meadow_hut(Vector2(524, 74), Color("6a4730"))
	_draw_meadow_hut(Vector2(1382, 74), Color("6c5036"))
	_draw_meadow_hut(Vector2(1462, 842), Color("65462e"))
	_draw_farm_patch(Rect2(116, 850, 210, 82))
	_draw_farm_patch(Rect2(356, 842, 132, 64))
	_draw_farm_patch(Rect2(1110, 852, 232, 74))
	_draw_farm_patch(Rect2(1384, 846, 124, 72))
	_draw_fence_run(Vector2(106, 848), 5)
	_draw_fence_run(Vector2(1116, 848), 5)
	_draw_orchard_row(Vector2(392, 876), 4, Color("617743"))
	_draw_orchard_row(Vector2(1368, 888), 3, Color("637945"))
	_draw_dirt_path(PackedVector2Array([
		Vector2(344, 822), Vector2(452, 792), Vector2(598, 812), Vector2(742, 866), Vector2(872, 918)
	]), 24.0)
	_draw_dirt_path(PackedVector2Array([
		Vector2(1324, 210), Vector2(1428, 246), Vector2(1518, 334)
	]), 18.0)
	_draw_shrub_cluster(Vector2(88, 892), 7, Color("5d6f44"), Color("728651"))
	_draw_shrub_cluster(Vector2(1114, 900), 8, Color("5b6d41"), Color("738751"))
	_draw_hedgerow_strip(Vector2(102, 842), 6, Color("55683f"))
	_draw_hedgerow_strip(Vector2(1108, 840), 7, Color("586b41"))
	_draw_field_gate(Vector2(304, 878), Color("806040"), Color("58412c"))
	_draw_field_gate(Vector2(1348, 882), Color("806040"), Color("58412c"))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(0, 156), Vector2(64, 132), Vector2(98, 236), Vector2(44, 338), Vector2(0, 316)
	]), Color(0.28, 0.35, 0.22, 0.58))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1532, 138), Vector2(1600, 146), Vector2(1600, 344), Vector2(1544, 328), Vector2(1496, 240)
	]), Color(0.28, 0.35, 0.22, 0.54))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(0, 840), Vector2(92, 826), Vector2(114, 940), Vector2(0, 980)
	]), Color(0.29, 0.36, 0.23, 0.56))
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1502, 832), Vector2(1600, 844), Vector2(1600, 980), Vector2(1486, 956)
	]), Color(0.29, 0.36, 0.23, 0.56))


func _draw_treeline_band(origin: Vector2, count: int, trunk: Color, leaf: Color) -> void:
	for index in range(count):
		var x := origin.x + index * 62.0 + sin(float(index) * 0.55) * 12.0
		var y := origin.y + cos(float(index) * 0.9) * 8.0
		draw_rect(Rect2(x - 5, y + 18, 10, 28), trunk, true)
		draw_circle(Vector2(x - 10, y + 12), 16.0, leaf.darkened(0.08))
		draw_circle(Vector2(x + 4, y + 4), 20.0, leaf)
		draw_circle(Vector2(x + 18, y + 14), 14.0, leaf.lightened(0.05))
		draw_circle(Vector2(x + 3, y + 7), 6.0, Color(1, 1, 1, 0.05))


func _draw_lot_labels() -> void:
	for row in LOT_LABELS:
		var pos: Vector2 = row.get("position", Vector2.ZERO)
		draw_rect(Rect2(pos, Vector2(126, 26)), Color(0.11, 0.08, 0.06, 0.26), true)
		draw_rect(Rect2(pos, Vector2(126, 26)), Color("c39b64"), false, 2.0)


func _draw_banners() -> void:
	for spec in banner_specs:
		var origin: Vector2 = spec.get("origin", Vector2.ZERO)
		var color_value: Color = spec.get("color", Color.WHITE)
		var sway := 12.0 * sin(_time * 2.0 + origin.x * 0.01)
		draw_polygon(
			PackedVector2Array([
				origin,
				origin + Vector2(42 + sway, 8),
				origin + Vector2(36 + sway, 46),
				origin + Vector2(0, 36)
			]),
			[color_value]
		)
		draw_line(origin, origin + Vector2(42 + sway, 8), Color("ead9aa"), 2.0)


func _draw_lanterns() -> void:
	for origin in lantern_specs:
		draw_line(origin + Vector2(0, -20), origin + Vector2(0, 12), Color("3c2617"), 3.0)
		draw_circle(origin, 7.0, Color("b98c3f"))
		var glow_alpha := lerpf(0.05, 0.24, 1.0 - light_level)
		draw_circle(origin, 12.0 + 1.5 * sin(_time * 2.5 + origin.x * 0.02), Color(0.97, 0.84, 0.45, glow_alpha))


func _draw_border() -> void:
	pass


func _draw_shack(pos: Vector2, roof_color: Color) -> void:
	_draw_building_plinth(Rect2(pos + Vector2(-14, 34), Vector2(94, 22)), Color("3c2a1d"), Color("6d5438"))
	draw_rect(Rect2(pos, Vector2(66, 44)), Color("714f35"), true)
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(50, 28)), Color("8e6a49"), true)
	draw_rect(Rect2(pos + Vector2(-6, -10), Vector2(78, 12)), roof_color, true)
	draw_rect(Rect2(pos + Vector2(20, 18), Vector2(12, 26)), Color("3a271b"), true)


func _draw_market_stall(pos: Vector2, frame_color: Color, cloth_color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(54, 12)), cloth_color, true)
	draw_rect(Rect2(pos + Vector2(0, 12), Vector2(54, 8)), Color(1, 1, 1, 0.08), true)
	draw_line(pos + Vector2(4, 12), pos + Vector2(4, 46), frame_color, 3.0)
	draw_line(pos + Vector2(50, 12), pos + Vector2(50, 46), frame_color, 3.0)
	draw_rect(Rect2(pos + Vector2(6, 36), Vector2(42, 10)), Color("7b5832"), true)
	for index in range(3):
		draw_rect(Rect2(pos + Vector2(10 + index * 12, 25), Vector2(8, 7)), cloth_color.lightened(0.2), true)


func _draw_clothesline(start: Vector2, ending: Vector2) -> void:
	draw_line(start, ending, Color("5a4334"), 2.0)
	for index in range(5):
		var ratio: float = float(index + 1) / 6.0
		var x: float = lerpf(start.x, ending.x, ratio)
		var y: float = lerpf(start.y, ending.y, ratio) + 4.0 * sin(_time * 1.6 + index)
		draw_rect(Rect2(x - 8, y, 16, 14), Color("c1a56a"), true)


func _draw_fence_run(origin: Vector2, segments: int) -> void:
	for index in range(segments):
		var x := origin.x + index * 58
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 42), Color("5b412c"), 4.0)
		draw_line(Vector2(x + 42, origin.y), Vector2(x + 42, origin.y + 42), Color("5b412c"), 4.0)
		draw_line(Vector2(x, origin.y + 10), Vector2(x + 42, origin.y + 16), Color("8b6a42"), 3.0)
		draw_line(Vector2(x, origin.y + 30), Vector2(x + 42, origin.y + 36), Color("8b6a42"), 3.0)


func _draw_warehouse(pos: Vector2) -> void:
	_draw_building_plinth(Rect2(pos + Vector2(-12, 46), Vector2(134, 28)), Color("34261b"), Color("65503b"))
	draw_rect(Rect2(pos, Vector2(112, 60)), Color("5c4330"), true)
	draw_rect(Rect2(pos + Vector2(-6, -14), Vector2(124, 16)), Color("3a2618"), true)
	draw_rect(Rect2(pos + Vector2(14, 20), Vector2(20, 40)), Color("2f1d14"), true)
	draw_rect(Rect2(pos + Vector2(46, 20), Vector2(18, 18)), Color("d2bb8f"), true)
	draw_rect(Rect2(pos + Vector2(72, 20), Vector2(18, 18)), Color("d2bb8f"), true)
	_draw_window_glow(Rect2(pos + Vector2(46, 20), Vector2(18, 18)))
	_draw_window_glow(Rect2(pos + Vector2(72, 20), Vector2(18, 18)))


func _draw_crane(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 98), Color("a88952"), 6.0)
	draw_line(origin + Vector2(-14, 8), origin + Vector2(46, 8), Color("a88952"), 4.0)
	draw_line(origin + Vector2(44, 8), origin + Vector2(60, 64), Color("a88952"), 3.0)
	draw_line(origin + Vector2(52, 64), origin + Vector2(52, 110), Color("d8bf88"), 2.0)
	draw_rect(Rect2(origin + Vector2(44, 108), Vector2(18, 14)), Color("7c5634"), true)


func _draw_boat(center: Vector2, hull_color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(-42, 6),
			center + Vector2(-18, -10),
			center + Vector2(22, -10),
			center + Vector2(46, 6),
			center + Vector2(16, 18),
			center + Vector2(-14, 18)
		]),
		hull_color
	)
	draw_line(center + Vector2(-2, -10), center + Vector2(-2, -42), Color("e3d6b5"), 2.0)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(0, -40),
			center + Vector2(20, -18),
			center + Vector2(0, -18)
		]),
		[Color(1, 1, 1, 0.8)]
	)


func _draw_rope_coil(center: Vector2) -> void:
	draw_arc(center, 16.0, 0.0, TAU, 32, Color("bf9f64"), 3.0)
	draw_arc(center, 10.0, 0.0, TAU, 24, Color("bf9f64"), 2.0)


func _draw_factory_building(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(98, 82)), Color("58453a"), true)
	draw_rect(Rect2(pos + Vector2(-6, -14), Vector2(110, 16)), Color("30211a"), true)
	draw_rect(Rect2(pos + Vector2(16, -52), Vector2(24, 52)), Color("48352a"), true)
	draw_rect(Rect2(pos + Vector2(56, -42), Vector2(20, 42)), Color("48352a"), true)
	draw_rect(Rect2(pos + Vector2(16, 26), Vector2(18, 26)), Color("d0b788"), true)
	draw_rect(Rect2(pos + Vector2(48, 26), Vector2(18, 26)), Color("d0b788"), true)
	_draw_window_glow(Rect2(pos + Vector2(16, 26), Vector2(18, 26)))
	_draw_window_glow(Rect2(pos + Vector2(48, 26), Vector2(18, 26)))


func _draw_foundry(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(184, 104)), Color("66513f"), true)
	draw_rect(Rect2(pos + Vector2(-8, -18), Vector2(200, 20)), Color("342419"), true)
	for index in range(4):
		draw_rect(Rect2(pos + Vector2(20 + index * 36, 32), Vector2(16, 54)), Color("d2ba8c"), true)
	draw_rect(Rect2(pos + Vector2(76, 58), Vector2(34, 46)), Color("2b1d14"), true)


func _draw_coal_heap(center: Vector2) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(-28, 12),
			center + Vector2(-12, -18),
			center + Vector2(0, -26),
			center + Vector2(22, -6),
			center + Vector2(34, 12)
		]),
		Color("231811")
	)


func _draw_track(origin: Vector2, segments: int) -> void:
	for index in range(segments):
		var x := origin.x + index * 28
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + 60), Color("3b291d"), 2.0)
	draw_line(origin + Vector2(-10, 6), origin + Vector2(segments * 28, 10), Color("8c6c40"), 3.0)
	draw_line(origin + Vector2(-10, 28), origin + Vector2(segments * 28, 32), Color("8c6c40"), 3.0)


func _draw_gatehouse(pos: Vector2) -> void:
	_draw_building_plinth(Rect2(pos + Vector2(-10, 44), Vector2(92, 22)), Color("38281d"), Color("6a5642"))
	draw_rect(Rect2(pos, Vector2(72, 58)), Color("6f5940"), true)
	draw_rect(Rect2(pos + Vector2(-8, -10), Vector2(88, 12)), Color("3a281b"), true)
	draw_rect(Rect2(pos + Vector2(24, 12), Vector2(20, 46)), Color("22170f"), true)


func _draw_exchange_hall(rect: Rect2) -> void:
	_draw_building_plinth(Rect2(rect.position + Vector2(-12, rect.size.y - 4), Vector2(rect.size.x + 24, 28)), Color("352518"), Color("745c3e"))
	draw_rect(rect, Color("655036"), true)
	draw_rect(Rect2(rect.position + Vector2(-22, -30), Vector2(rect.size.x + 44, 34)), Color("402a1b"), true)
	for index in range(6):
		draw_rect(Rect2(rect.position + Vector2(34 + index * 54, 34), Vector2(18, 112)), Color("d4bd8f"), true)
	draw_rect(Rect2(rect.position + Vector2(118, 78), Vector2(126, 106)), Color("2e1e14"), true)


func _draw_square_plaza(rect: Rect2) -> void:
	_draw_forecourt_bleed(rect, Color(0.46, 0.38, 0.26, 0.2), Color(0.62, 0.54, 0.38, 0.12))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(18.0, 0.0),
		rect.position + Vector2(rect.size.x - 16.0, 2.0),
		rect.position + Vector2(rect.size.x, 22.0),
		rect.position + Vector2(rect.size.x - 8.0, rect.size.y - 10.0),
		rect.position + Vector2(26.0, rect.size.y),
		rect.position + Vector2(0.0, rect.size.y - 18.0),
	]), Color("8e734b"))
	for row in range(4):
		for column in range(8):
			var pos := rect.position + Vector2(column * 58 + 8, row * 42 + 8)
			draw_rect(Rect2(pos, Vector2(44, 28)), Color("a8895d"), true)
	_draw_stone_seams(rect, false)
	for index in range(8):
		var edge := rect.position + Vector2(18.0 + index * 54.0, rect.size.y - 6.0 + sin(float(index) * 0.8) * 2.0)
		draw_circle(edge, 6.0 + float(index % 2) * 2.0, Color(0.68, 0.58, 0.4, 0.16))


func _draw_statue(center: Vector2) -> void:
	draw_circle(center, 28.0, Color("b98e45"))
	draw_line(center + Vector2(0, -22), center + Vector2(0, 20), Color("4b3019"), 4.0)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color("4b3019"), 4.0)


func _draw_district_blotches(rect: Rect2, fill: Color) -> void:
	var shapes := [
		[Vector2(16, 40), Vector2(120, 12), Vector2(222, 28), Vector2(180, 92), Vector2(62, 96)],
		[Vector2(rect.size.x - 182, 24), Vector2(rect.size.x - 52, 32), Vector2(rect.size.x - 18, 108), Vector2(rect.size.x - 148, 122)],
		[Vector2(34, rect.size.y - 96), Vector2(166, rect.size.y - 126), Vector2(202, rect.size.y - 42), Vector2(54, rect.size.y - 18)],
	]
	for local_points in shapes:
		var points := PackedVector2Array()
		for point in local_points:
			points.append(rect.position + point)
		draw_colored_polygon(points, fill.lightened(0.04))


func _draw_road_strip(points: PackedVector2Array, fill_color: Color, brick_color: Color) -> void:
	draw_colored_polygon(points, fill_color)
	for index in range(points.size() - 1):
		draw_line(points[index], points[index + 1], Color(0, 0, 0, 0.08), 2.0)
	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	var bounds := Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	for row in range(int(bounds.size.y / 36.0)):
		for column in range(int(bounds.size.x / 74.0)):
			var pos := bounds.position + Vector2(18 + column * 74.0, 12 + row * 36.0)
			draw_rect(Rect2(pos, Vector2(34, 12)), brick_color, true)
	for index in range(18):
		var x := bounds.position.x + 12.0 + fmod(float(index) * 58.0, max(bounds.size.x - 18.0, 22.0))
		var y := bounds.position.y + 10.0 + fmod(float(index) * 31.0, max(bounds.size.y - 16.0, 18.0))
		draw_rect(Rect2(x, y, 10, 4), fill_color.lightened(0.08), true)
		draw_rect(Rect2(x + 16, y + 6, 8, 3), fill_color.darkened(0.08), true)
	for index in range(points.size() - 1):
		var start := points[index]
		var ending := points[index + 1]
		var midpoint := start.lerp(ending, 0.5)
		var direction := (ending - start).normalized()
		var normal := Vector2(-direction.y, direction.x)
		draw_circle(midpoint + normal * 22.0, 10.0 + float(index % 2) * 3.0, Color(fill_color.r, fill_color.g, fill_color.b, 0.12))
		draw_circle(midpoint - normal * 18.0, 8.0 + float((index + 1) % 2) * 2.0, Color(fill_color.r, fill_color.g, fill_color.b, 0.08))


func _draw_road_shoulder(points: PackedVector2Array, width: float, grass_color: Color, dirt_color: Color) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var ending := points[index + 1]
		var direction := (ending - start).normalized()
		var normal := Vector2(-direction.y, direction.x) * width * 0.5
		draw_colored_polygon(PackedVector2Array([
			start + normal,
			ending + normal,
			ending - normal,
			start - normal
		]), grass_color)
		for sample in range(3):
			var ratio := float(sample + 1) / 4.0
			var center := start.lerp(ending, ratio)
			var wobble := normal.normalized() * ((-1.0 if sample % 2 == 0 else 1.0) * (width * 0.28))
			draw_circle(center + wobble, 10.0 + float((index + sample) % 3) * 3.0, dirt_color)
			draw_circle(center - wobble * 0.7, 7.0 + float(sample % 2) * 2.0, Color(grass_color.r, grass_color.g, grass_color.b, grass_color.a * 0.72))


func _draw_wetland_band(points: PackedVector2Array, width: float, moss_color: Color, water_color: Color) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var ending := points[index + 1]
		var direction := (ending - start).normalized()
		var normal := Vector2(-direction.y, direction.x) * width * 0.5
		draw_colored_polygon(PackedVector2Array([
			start + normal,
			ending + normal * 0.85,
			ending - normal * 0.6,
			start - normal * 0.9
		]), moss_color)
		var center := start.lerp(ending, 0.5)
		_draw_ellipse(center + normal * 0.18, Vector2(width * 0.36, 8.0 + float(index % 2) * 3.0), water_color)
		for reed in range(4):
			var reed_ratio := float(reed + 1) / 5.0
			var reed_origin := start.lerp(ending, reed_ratio) + normal.normalized() * (4.0 + float(reed % 2) * 6.0)
			draw_line(reed_origin, reed_origin + Vector2(-2.0, -10.0 - float(reed % 3) * 2.0), Color("6b7f4c"), 1.3)
			draw_line(reed_origin + Vector2(2.0, 0.0), reed_origin + Vector2(4.0, -8.0 - float(reed % 2) * 2.0), Color("7f9460"), 1.0)


func _draw_crossroad_blend(center: Vector2, radii: Vector2, color_value: Color) -> void:
	_draw_ellipse(center, radii, color_value)
	_draw_ellipse(center + Vector2(0.0, -8.0), radii * Vector2(0.64, 0.48), Color(color_value.r, color_value.g, color_value.b, color_value.a * 0.62))


func _draw_edge_breakup(rect: Rect2, base_color: Color) -> void:
	for index in range(7):
		var top_x := rect.position.x + 24.0 + index * (rect.size.x - 48.0) / 6.0
		draw_circle(Vector2(top_x, rect.position.y + 4.0), 12.0 + fmod(float(index) * 3.0, 8.0), base_color.lightened(0.05))
		var bottom_x := rect.position.x + 36.0 + index * (rect.size.x - 72.0) / 6.0
		draw_circle(Vector2(bottom_x, rect.position.y + rect.size.y - 4.0), 11.0 + fmod(float(index) * 2.0, 7.0), base_color.darkened(0.05))
	for index in range(4):
		var left_y := rect.position.y + 32.0 + index * (rect.size.y - 64.0) / 3.0
		draw_circle(Vector2(rect.position.x + 4.0, left_y), 10.0, base_color.lightened(0.04))
		var right_y := rect.position.y + 28.0 + index * (rect.size.y - 56.0) / 3.0
		draw_circle(Vector2(rect.position.x + rect.size.x - 4.0, right_y), 10.0, base_color.darkened(0.04))


func _draw_tree_cluster(origin: Vector2, count: int, leaf_color: Color) -> void:
	for index in range(count):
		var offset := Vector2(index * 28.0, fmod(float(index) * 11.0, 24.0))
		var trunk := origin + offset
		draw_rect(Rect2(trunk + Vector2(-4, 12), Vector2(8, 24)), Color("4f3420"), true)
		draw_circle(trunk + Vector2(0, 8), 18.0, leaf_color)
		draw_circle(trunk + Vector2(-10, 14), 12.0, leaf_color.darkened(0.06))
		draw_circle(trunk + Vector2(10, 14), 11.0, leaf_color.lightened(0.08))


func _draw_shrub_cluster(origin: Vector2, count: int, leaf_color: Color, accent_color: Color) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 18.0, sin(float(index) * 1.1) * 4.0)
		draw_circle(center, 10.0 + float(index % 2) * 2.0, leaf_color)
		draw_circle(center + Vector2(4, -2), 6.0, accent_color)
		draw_circle(center + Vector2(-4, 3), 4.0, leaf_color.darkened(0.08))


func _draw_sun_disk(center: Vector2, radius: float) -> void:
	var sun_color := Color("f6e4b6").darkened((1.0 - light_level) * 0.18)
	draw_circle(center, radius, sun_color)
	draw_circle(center, radius + 16.0, Color(sun_color.r, sun_color.g * 0.96, sun_color.b * 0.9, 0.12))
	if light_level < 0.62:
		draw_circle(center + Vector2(0, 2), radius + 28.0, Color(0.88, 0.58, 0.42, (1.0 - light_level) * 0.12))


func _draw_distant_canopy_band(origin: Vector2, count: int, color_value: Color, base_height: float) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 98.0 + sin(float(index) * 0.7) * 14.0, sin(float(index) * 0.9) * 10.0)
		var height := base_height + float(index % 3) * 18.0
		draw_rect(Rect2(center + Vector2(-8, 18), Vector2(16, height)), Color(color_value.r * 0.74, color_value.g * 0.74, color_value.b * 0.72, color_value.a), true)
		_draw_ellipse(center + Vector2(-18, 10), Vector2(42, 24), color_value)
		_draw_ellipse(center + Vector2(14, 2), Vector2(52, 30), color_value)
		_draw_ellipse(center + Vector2(34, 18), Vector2(38, 22), Color(color_value.r * 0.92, color_value.g * 0.92, color_value.b * 0.95, color_value.a))


func _draw_distant_roofline(origin: Vector2, count: int, color_value: Color) -> void:
	for index in range(count):
		var base := origin + Vector2(index * 86.0, sin(float(index) * 0.9) * 6.0)
		draw_rect(Rect2(base, Vector2(62, 32 + float(index % 2) * 10.0)), color_value, true)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-8, 0),
			base + Vector2(31, -20 - float(index % 3) * 6.0),
			base + Vector2(70, 0)
		]), Color(color_value.r * 0.82, color_value.g * 0.78, color_value.b * 0.76, color_value.a))


func _draw_cloud_bank(origin: Vector2, count: int, color_value: Color) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 76.0, sin(float(index) * 1.1) * 8.0)
		_draw_ellipse(center, Vector2(34, 12), color_value)
		_draw_ellipse(center + Vector2(18, -6), Vector2(24, 10), color_value)
		_draw_ellipse(center + Vector2(-18, -2), Vector2(20, 9), color_value)


func _draw_meadow_patch(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	for index in range(points.size() - 1):
		draw_line(points[index], points[index + 1], fill.darkened(0.14), 2.0)


func _draw_drainage_ditch(points: PackedVector2Array, width: float) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var ending := points[index + 1]
		var direction := (ending - start).normalized()
		var normal := Vector2(-direction.y, direction.x) * width * 0.5
		draw_colored_polygon(PackedVector2Array([
			start + normal,
			ending + normal,
			ending - normal,
			start - normal
		]), Color(0.24, 0.3, 0.34, 0.62))
		draw_line(start + normal, ending + normal, Color(0.64, 0.72, 0.68, 0.2), 1.2)
		draw_line(start - normal, ending - normal, Color(0.12, 0.1, 0.08, 0.18), 1.2)


func _draw_flat_bridge(center: Vector2, width: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - width * 0.5 - 6.0, center.y - 7.0),
		Vector2(center.x + width * 0.5 + 4.0, center.y - 10.0),
		Vector2(center.x + width * 0.5 + 8.0, center.y + 8.0),
		Vector2(center.x - width * 0.5 - 4.0, center.y + 10.0)
	]), Color("7a5939"))
	for board in range(5):
		var x := center.x - width * 0.5 + board * width / 5.0
		draw_line(Vector2(x, center.y - 8.0 + sin(float(board) * 0.8) * 1.5), Vector2(x + sin(float(board) * 0.5) * 1.2, center.y + 8.0), Color("4d331f"), 1.2)
	draw_line(Vector2(center.x - width * 0.5 - 2.0, center.y + 10.0), Vector2(center.x + width * 0.5 + 4.0, center.y + 8.0), Color(0, 0, 0, 0.18), 1.2)


func _draw_bridgehead_node(center: Vector2, size: Vector2, lower_crossing: bool) -> void:
	var rect := Rect2(center - size * 0.5, size)
	_draw_forecourt_bleed(rect, Color(0.44, 0.36, 0.25, 0.22), Color(0.52, 0.44, 0.3, 0.14))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-6.0, 4.0),
		rect.position + Vector2(rect.size.x + 4.0, 0.0),
		rect.position + rect.size + Vector2(6.0, -2.0),
		rect.position + Vector2(-8.0, rect.size.y + 4.0)
	]), Color("6a573d"))
	draw_rect(Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16)), Color("8c734d"), true)
	for index in range(4):
		var x := rect.position.x + 14.0 + index * 24.0
		draw_rect(Rect2(x, rect.position.y + 12, 12, rect.size.y - 24.0), Color("9a8058"), true)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5 - 18.0, 6), Vector2(36, rect.size.y - 12.0)), Color("71573b"), true)
	_draw_post_pair(rect.position + Vector2(12, 8), rect.position + Vector2(rect.size.x - 12.0, 8), Color("5b402a"))
	_draw_post_pair(rect.position + Vector2(12, rect.size.y - 8.0), rect.position + Vector2(rect.size.x - 12.0, rect.size.y - 8.0), Color("5b402a"))
	var marker_y := rect.position.y + 18.0 if lower_crossing else rect.position.y + rect.size.y - 18.0
	draw_rect(Rect2(center.x - 28.0, marker_y - 10.0, 56, 20), Color("5f432d"), true)
	draw_rect(Rect2(center.x - 28.0, marker_y - 10.0, 56, 20), Color("ccb07a"), false, 2.0)
	for index in range(3):
		var px := center.x - 18.0 + index * 18.0
		draw_circle(Vector2(px, marker_y), 2.0, Color("eadab2"))
	for index in range(3):
		var stone := rect.position + Vector2(12.0 + index * 32.0, rect.size.y - 10.0 + sin(float(index)) * 3.0)
		draw_rect(Rect2(stone, Vector2(16, 8)), Color("7a6a58"), true)
	if lower_crossing:
		_draw_rope_coil(center + Vector2(-40, 22))
		_draw_rope_coil(center + Vector2(44, 18))
	else:
		_draw_shrub_cluster(rect.position + Vector2(-12, rect.size.y + 8), 4, Color("58673f"), Color("728352"))
		_draw_shrub_cluster(rect.position + Vector2(rect.size.x - 60, -8), 4, Color("58673f"), Color("728352"))


func _draw_roadside_scrub(rect: Rect2, count: int, base_color: Color, accent_color: Color) -> void:
	for index in range(count):
		var x := rect.position.x + 16.0 + fmod(float(index) * 78.0, rect.size.x - 24.0)
		var y := rect.position.y + 12.0 + fmod(float(index) * 41.0, rect.size.y - 18.0)
		draw_circle(Vector2(x, y), 8.0 + float(index % 2) * 2.0, base_color)
		draw_circle(Vector2(x + 4, y + 1), 5.0, accent_color)


func _draw_wagon_ruts(rect: Rect2, segments: int) -> void:
	for row in [0.0, 18.0]:
		var previous := Vector2(rect.position.x, rect.position.y + row + 8.0)
		for index in range(segments):
			var x: float = rect.position.x + index * rect.size.x / float(segments)
			var y: float = rect.position.y + row + 8.0 + sin(float(index) * 0.6) * 2.0
			var current := Vector2(x, y)
			draw_line(previous, current, Color(0.29, 0.22, 0.15, 0.28), 1.8)
			previous = current


func _draw_flat_yard(rect: Rect2, dirt_color: Color, straw_color: Color) -> void:
	draw_rect(rect, dirt_color, true)
	for index in range(10):
		var x := rect.position.x + 10.0 + fmod(float(index) * 17.0, rect.size.x - 14.0)
		var y := rect.position.y + 8.0 + fmod(float(index) * 11.0, rect.size.y - 10.0)
		draw_line(Vector2(x, y), Vector2(x + 8, y + 2), straw_color, 1.0)
	draw_rect(rect, Color(0, 0, 0, 0.08), false, 1.0)


func _draw_shore_reeds(rect: Rect2, count: int, bright: Color, dark: Color) -> void:
	for index in range(count):
		var x := rect.position.x + 10.0 + index * rect.size.x / float(count)
		var y := rect.position.y + rect.size.y - 6.0 + sin(float(index) * 0.9 + _time * 1.1) * 2.0
		draw_line(Vector2(x, y), Vector2(x - 2, y - 16), dark, 1.8)
		draw_line(Vector2(x + 2, y), Vector2(x + 3, y - 14), bright, 1.4)


func _draw_jetty_rubble(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 12.0, fmod(float(index) * 5.0, 11.0))
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-4, 0),
			pos + Vector2(2, -3),
			pos + Vector2(6, 2),
			pos + Vector2(1, 6),
			pos + Vector2(-5, 3)
		]), Color("7c725f"))


func _draw_scrap_scatter(rect: Rect2, count: int) -> void:
	for index in range(count):
		var center := rect.position + Vector2(14.0 + fmod(float(index) * 29.0, rect.size.x - 16.0), 12.0 + fmod(float(index) * 19.0, rect.size.y - 16.0))
		draw_rect(Rect2(center - Vector2(4, 2), Vector2(8, 4)), Color("67584a"), true)
		draw_line(center + Vector2(-6, 0), center + Vector2(6, 0), Color("3b3027"), 1.0)
		if index % 3 == 0:
			draw_circle(center + Vector2(0, -5), 2.0, Color("896c3d"))


func _draw_parterre(rect: Rect2, hedge_color: Color, flower_color: Color) -> void:
	draw_rect(rect, hedge_color, true)
	draw_line(rect.position + Vector2(rect.size.x * 0.5, 4), rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 4), Color("3f5132"), 2.0)
	draw_line(rect.position + Vector2(4, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 4, rect.size.y * 0.5), Color("3f5132"), 2.0)
	for dot in [Vector2(20, 10), Vector2(44, 28), Vector2(76, 12), Vector2(94, 26)]:
		draw_circle(rect.position + dot, 3.0, flower_color)


func _draw_hedgerow_strip(origin: Vector2, count: int, hedge_color: Color) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 34.0, sin(float(index) * 0.7) * 3.0)
		draw_circle(center, 12.0, hedge_color)
		draw_circle(center + Vector2(4, 2), 7.0, hedge_color.lightened(0.06))


func _draw_lean_to(origin: Vector2, size: Vector2, roof_color: Color, wall_color: Color) -> void:
	draw_rect(Rect2(origin, size), wall_color, true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-6, 0),
		origin + Vector2(size.x + 8, 8),
		origin + Vector2(size.x + 2, 18),
		origin + Vector2(-10, 10)
	]), roof_color)
	draw_line(origin + Vector2(8, 2), origin + Vector2(8, size.y), Color("4b311f"), 2.0)
	draw_line(origin + Vector2(size.x - 8, 8), origin + Vector2(size.x - 8, size.y), Color("4b311f"), 2.0)


func _draw_alley_posts(origin: Vector2, count: int, height: float) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 22.0, sin(float(index) * 0.7) * 2.0)
		draw_line(pos, pos + Vector2(0, height), Color("583c28"), 3.0)
	if count > 1:
		draw_line(origin + Vector2(0, 10), origin + Vector2((count - 1) * 22.0, 14), Color("88653c"), 2.0)


func _draw_stall_counter(origin: Vector2, slots: int, wood_color: Color) -> void:
	draw_rect(Rect2(origin, Vector2(slots * 18.0 + 10.0, 12)), wood_color, true)
	for index in range(slots):
		var pos := origin + Vector2(6 + index * 18.0, -8 + fmod(float(index) * 3.0, 5.0))
		draw_rect(Rect2(pos, Vector2(10, 8)), wood_color.lightened(0.12), true)


func _draw_crook_chimneys(origin: Vector2, count: int, stack_color: Color) -> void:
	for index in range(count):
		var base := origin + Vector2(index * 84.0, float(index % 2) * 8.0)
		draw_rect(Rect2(base, Vector2(12, 34)), stack_color, true)
		draw_rect(Rect2(base + Vector2(-4, -6), Vector2(18, 8)), stack_color.lightened(0.08), true)
		draw_line(base + Vector2(6, -8), base + Vector2(16, -18), Color(0.82, 0.82, 0.78, 0.26), 2.0)


func _draw_courtyard_flags(rect: Rect2, cloth_a: Color, cloth_b: Color) -> void:
	draw_line(rect.position + Vector2(0, 6), rect.position + Vector2(rect.size.x, 0), Color("5b3f2b"), 2.0)
	for index in range(5):
		var x := rect.position.x + 12.0 + index * 20.0
		var y := rect.position.y + 6.0 + sin(float(index) * 0.8) * 2.0
		var cloth := cloth_a if index % 2 == 0 else cloth_b
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y),
			Vector2(x + 12, y + 2),
			Vector2(x + 2, y + 14)
		]), cloth)


func _draw_market_threshold_node(rect: Rect2, ground_color: Color, timber_color: Color, formal: bool) -> void:
	_draw_forecourt_bleed(rect, Color(ground_color.r, ground_color.g, ground_color.b, 0.22), Color(timber_color.r, timber_color.g, timber_color.b, 0.12))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-4.0, 2.0),
		rect.position + Vector2(rect.size.x + 2.0, 0.0),
		rect.position + rect.size + Vector2(8.0, -4.0),
		rect.position + Vector2(-10.0, rect.size.y + 6.0)
	]), ground_color)
	for index in range(6):
		var x := rect.position.x + 14.0 + index * (rect.size.x - 28.0) / 5.0
		draw_line(Vector2(x, rect.position.y + 6), Vector2(x, rect.position.y + rect.size.y - 6.0), Color(1, 1, 1, 0.04), 1.0)
	var arch_y := rect.position.y + 14.0
	draw_rect(Rect2(rect.position.x + 20, arch_y, rect.size.x - 40.0, 14), timber_color.darkened(0.12), true)
	for index in range(4):
		var x := rect.position.x + 30.0 + index * (rect.size.x - 60.0) / 3.0
		draw_rect(Rect2(x, arch_y + 4, 10, 40), timber_color, true)
		draw_rect(Rect2(x + 2, arch_y + 4, 2, 40), Color(1, 1, 1, 0.1), true)
	if formal:
		for index in range(5):
			var x := rect.position.x + 34.0 + index * 44.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, arch_y + 14),
				Vector2(x + 16, arch_y + 18),
				Vector2(x + 3, arch_y + 34)
			]), Color("8f2f33") if index % 2 == 0 else Color("cfb985"))
		draw_rect(Rect2(rect.position.x + 96, rect.position.y + rect.size.y - 28.0, rect.size.x - 192.0, 14), Color("b39a6c"), true)
		_draw_parterre(Rect2(rect.position.x + 30, rect.position.y + rect.size.y - 34.0, 72, 20), Color("5d7146"), Color("d2c274"))
		_draw_parterre(Rect2(rect.end.x - 102.0, rect.position.y + rect.size.y - 34.0, 72, 20), Color("5d7146"), Color("d2c274"))
	else:
		_draw_stall_counter(rect.position + Vector2(26, rect.size.y - 22.0), 4, timber_color)
		_draw_stall_counter(rect.position + Vector2(rect.size.x - 102.0, rect.size.y - 20.0), 3, timber_color.darkened(0.06))
		_draw_clutter_bundle(rect.position + Vector2(22, rect.size.y - 30.0), 3)
		_draw_bucket_row(rect.position + Vector2(rect.size.x - 82.0, rect.size.y - 18.0), 3)
	for index in range(4):
		var px := rect.position.x + 34.0 + index * 38.0
		var py := rect.position.y + rect.size.y * 0.56 + sin(float(index) * 0.8) * 3.0
		draw_rect(Rect2(px, py, 18, 8), ground_color.lightened(0.1), true)
		draw_rect(Rect2(px + 10, py + 10, 14, 6), ground_color.darkened(0.12), true)


func _draw_harbor_spine_view(rect: Rect2, plank_color: Color, highlight_color: Color) -> void:
	_draw_forecourt_bleed(rect, Color(0.32, 0.28, 0.2, 0.24), Color(0.46, 0.38, 0.2, 0.12))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-4.0, 0.0),
		rect.position + Vector2(rect.size.x + 10.0, 4.0),
		rect.position + rect.size + Vector2(6.0, -2.0),
		rect.position + Vector2(-6.0, rect.size.y + 2.0)
	]), plank_color)
	for index in range(7):
		var x := rect.position.x + 14.0 + index * 58.0
		draw_rect(Rect2(x, rect.position.y + 8, 24, rect.size.y - 16.0), highlight_color, true)
		draw_line(Vector2(x + 12, rect.position.y + 8), Vector2(x + 12, rect.position.y + rect.size.y - 8.0), plank_color.darkened(0.18), 1.0)
	for index in range(4):
		var y := rect.position.y + 18.0 + index * 22.0
		draw_line(Vector2(rect.position.x + 10, y), Vector2(rect.end.x - 10.0, y + 4.0), plank_color.darkened(0.22), 1.4)
	_draw_post_pair(rect.position + Vector2(16, 0), rect.position + Vector2(rect.size.x - 16.0, 0), Color("5a3d27"))
	_draw_post_pair(rect.position + Vector2(16, rect.size.y - 2.0), rect.position + Vector2(rect.size.x - 16.0, rect.size.y - 2.0), Color("5a3d27"))
	for index in range(5):
		var bollard := rect.position + Vector2(28.0 + index * 78.0, rect.size.y - 8.0 + float(index % 2) * 4.0)
		draw_rect(Rect2(bollard, Vector2(12, 14)), Color("6a4a32"), true)
		draw_line(bollard + Vector2(6, 0), bollard + Vector2(18, -10), Color("c2a06c"), 1.4)
		draw_line(bollard + Vector2(6, 4), bollard + Vector2(20, -2), Color("c2a06c"), 1.2)


func _draw_exchange_edge_stalls(rect: Rect2, base_color: Color, trim_color: Color) -> void:
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.82), true)
	for index in range(6):
		var x := rect.position.x + 14.0 + index * 76.0
		draw_rect(Rect2(x, rect.position.y + 10, 58, 18), base_color.darkened(0.1), true)
		draw_rect(Rect2(x, rect.position.y + 28, 58, 28), trim_color.darkened(0.24), true)
		draw_rect(Rect2(x + 4, rect.position.y + 16, 50, 6), trim_color, true)
		for slot in range(3):
			draw_rect(Rect2(x + 8 + slot * 14.0, rect.position.y + 34 + float(slot % 2) * 6.0, 10, 8), base_color.lightened(0.12), true)
	for index in range(5):
		var seam_x := rect.position.x + 22.0 + index * 92.0
		draw_line(Vector2(seam_x, rect.position.y + 8), Vector2(seam_x, rect.end.y - 6.0), Color(1, 1, 1, 0.05), 1.0)


func _draw_slum_main_lane(rect: Rect2, dirt_color: Color, plank_color: Color) -> void:
	draw_rect(rect, dirt_color, true)
	for index in range(6):
		var x := rect.position.x + 18.0 + index * 74.0
		draw_rect(Rect2(x, rect.position.y + 10, 22, rect.size.y - 20.0), plank_color, true)
		draw_line(Vector2(x + 10, rect.position.y + 10), Vector2(x + 10, rect.position.y + rect.size.y - 10.0), dirt_color.darkened(0.18), 1.0)
	for index in range(7):
		var y := rect.position.y + 18.0 + index * 14.0
		draw_line(Vector2(rect.position.x + 12, y), Vector2(rect.end.x - 12.0, y + sin(float(index) * 0.7) * 3.0), Color(0, 0, 0, 0.08), 1.2)
	_draw_post_pair(rect.position + Vector2(18, 0), rect.position + Vector2(rect.size.x - 18.0, 0), Color("5b402a"))
	for index in range(5):
		var clutter := rect.position + Vector2(22.0 + index * 96.0, rect.size.y - 20.0 + float(index % 2) * 4.0)
		draw_rect(Rect2(clutter, Vector2(18, 10)), dirt_color.lightened(0.1), true)
		draw_circle(clutter + Vector2(26, 4), 4.0, Color("6f5337"))


func _draw_night_bazaar_row(rect: Rect2, base_color: Color, awning_color: Color) -> void:
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.84), true)
	for index in range(5):
		var x := rect.position.x + 14.0 + index * 88.0
		draw_rect(Rect2(x, rect.position.y + 8, 64, 12), base_color.darkened(0.14), true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.position.y + 20),
			Vector2(x + 64, rect.position.y + 20),
			Vector2(x + 56, rect.position.y + 38),
			Vector2(x + 8, rect.position.y + 38)
		]), awning_color if index % 2 == 0 else awning_color.darkened(0.16))
		draw_rect(Rect2(x + 6, rect.position.y + 38, 52, 20), base_color.lightened(0.08), true)
		draw_rect(Rect2(x + 12, rect.position.y + 44, 12, 8), Color("b98a54"), true)
		draw_rect(Rect2(x + 28, rect.position.y + 46, 10, 6), Color("8f2f33"), true)
		draw_rect(Rect2(x + 42, rect.position.y + 43, 10, 9), Color("6b8250"), true)
	for index in range(6):
		var seam_x := rect.position.x + 10.0 + index * 74.0
		draw_line(Vector2(seam_x, rect.position.y + 10), Vector2(seam_x, rect.end.y - 8.0), Color(1, 1, 1, 0.04), 1.0)


func _draw_exchange_steps_forecourt(rect: Rect2, stone_color: Color, trim_color: Color) -> void:
	draw_rect(rect, stone_color, true)
	for step in range(5):
		draw_rect(Rect2(rect.position.x + 28.0 + step * 10.0, rect.position.y + 18.0 + step * 14.0, rect.size.x - 56.0 - step * 20.0, 10), trim_color, true)
	for index in range(4):
		var x := rect.position.x + 34.0 + index * 62.0
		draw_rect(Rect2(x, rect.position.y + 84, 24, 30), Color("7f6646"), true)
		draw_rect(Rect2(x + 4, rect.position.y + 84, 4, 30), Color(1, 1, 1, 0.08), true)
	draw_rect(Rect2(rect.position.x + 68, rect.position.y + 104, rect.size.x - 136.0, 16), Color("b79a6c"), true)
	for index in range(6):
		var medallion := rect.position + Vector2(44.0 + index * 34.0, rect.size.y - 18.0)
		draw_circle(medallion, 5.0, Color("8d734d"))
		draw_circle(medallion, 2.0, Color("d9c38e"))


func _draw_dock_loading_apron(rect: Rect2, plank_color: Color, timber_color: Color) -> void:
	_draw_forecourt_bleed(rect, Color(0.34, 0.3, 0.22, 0.24), Color(0.52, 0.44, 0.28, 0.12))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-4.0, 3.0),
		rect.position + Vector2(rect.size.x + 8.0, 0.0),
		rect.position + rect.size + Vector2(10.0, -2.0),
		rect.position + Vector2(-8.0, rect.size.y + 4.0)
	]), plank_color)
	for row in range(3):
		for column in range(5):
			var pos := rect.position + Vector2(18 + column * 58.0, 14 + row * 28.0)
			draw_rect(Rect2(pos, Vector2(32, 16)), timber_color, true)
			draw_line(pos + Vector2(16, 0), pos + Vector2(16, 16), plank_color.darkened(0.18), 1.0)
	for index in range(4):
		var rail_x := rect.position.x + 26.0 + index * 84.0
		draw_line(Vector2(rail_x, rect.position.y + 8), Vector2(rail_x, rect.end.y - 8.0), Color("4d3524"), 1.6)
		draw_line(Vector2(rail_x + 20, rect.position.y + 8), Vector2(rail_x + 20, rect.end.y - 8.0), Color("4d3524"), 1.2)
	for index in range(4):
		var bundle := rect.position + Vector2(24.0 + index * 72.0, rect.end.y - 20.0 + float(index % 2) * 4.0)
		draw_rect(Rect2(bundle, Vector2(24, 10)), Color("816143"), true)
		draw_circle(bundle + Vector2(30, 4), 4.0, Color("5f432d"))


func _draw_factory_outbound_yard(rect: Rect2, base_color: Color, trim_color: Color) -> void:
	_draw_forecourt_bleed(rect, Color(0.22, 0.18, 0.14, 0.26), Color(0.4, 0.3, 0.2, 0.14))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-8.0, 4.0),
		rect.position + Vector2(rect.size.x + 6.0, 0.0),
		rect.position + rect.size + Vector2(4.0, -4.0),
		rect.position + Vector2(-10.0, rect.size.y + 6.0)
	]), Color(base_color.r, base_color.g, base_color.b, 0.84))
	for lane in range(3):
		var y := rect.position.y + 18.0 + lane * 24.0
		draw_rect(Rect2(rect.position.x + 20.0, y, rect.size.x - 40.0, 10), base_color.darkened(0.14), true)
		draw_line(Vector2(rect.position.x + 24.0, y + 5.0), Vector2(rect.end.x - 24.0, y + 5.0), Color(1, 1, 1, 0.04), 1.0)
	for index in range(4):
		var stack := rect.position + Vector2(18.0 + index * 56.0, rect.end.y - 28.0 + float(index % 2) * 4.0)
		draw_rect(Rect2(stack, Vector2(28, 12)), trim_color, true)
		draw_rect(Rect2(stack + Vector2(4, -10), Vector2(20, 10)), trim_color.darkened(0.12), true)
	for index in range(3):
		var frame_x := rect.position.x + 46.0 + index * 78.0
		draw_line(Vector2(frame_x, rect.position.y + 10.0), Vector2(frame_x, rect.end.y - 8.0), Color("433123"), 2.2)
		draw_line(Vector2(frame_x, rect.position.y + 22.0), Vector2(frame_x + 36.0, rect.position.y + 8.0), Color("5f4733"), 1.6)
		draw_line(Vector2(frame_x, rect.position.y + 32.0), Vector2(frame_x + 40.0, rect.position.y + 18.0), Color("5f4733"), 1.2)
	draw_rect(Rect2(rect.position.x + 152.0, rect.position.y + 16.0, 54, 26), Color("674e39"), true)
	draw_rect(Rect2(rect.position.x + 160.0, rect.position.y + 24.0, 12, 10), Color("a58558"), true)
	draw_rect(Rect2(rect.position.x + 178.0, rect.position.y + 22.0, 18, 12), Color("86673f"), true)


func _draw_exchange_arcade_stall_band(rect: Rect2, base_color: Color, trim_color: Color) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y + 18.0, rect.size.x, rect.size.y - 18.0), Color(base_color.r, base_color.g, base_color.b, 0.8), true)
	for bay in range(4):
		var x := rect.position.x + 12.0 + bay * 86.0
		draw_rect(Rect2(x, rect.position.y + 8.0, 68, 12), trim_color.darkened(0.1), true)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x, rect.position.y + 20.0),
				Vector2(x + 68.0, rect.position.y + 20.0),
				Vector2(x + 58.0, rect.position.y + 40.0),
				Vector2(x + 10.0, rect.position.y + 40.0),
			]),
			base_color.darkened(0.06) if bay % 2 == 0 else base_color
		)
		draw_rect(Rect2(x + 8.0, rect.position.y + 40.0, 52, 18), trim_color, true)
		draw_rect(Rect2(x + 14.0, rect.position.y + 46.0, 10, 8), Color("c39a5b"), true)
		draw_rect(Rect2(x + 30.0, rect.position.y + 44.0, 12, 10), Color("6f8752"), true)
		draw_rect(Rect2(x + 46.0, rect.position.y + 47.0, 8, 7), Color("8a3340"), true)
	for index in range(5):
		var seam_x := rect.position.x + 6.0 + index * 70.0
		draw_line(Vector2(seam_x, rect.position.y + 10.0), Vector2(seam_x, rect.end.y - 8.0), Color(0, 0, 0, 0.06), 1.0)


func _draw_fish_market_wet_stalls(rect: Rect2, wood_color: Color, reed_color: Color) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y + 22.0, rect.size.x, rect.size.y - 18.0), Color(wood_color.r, wood_color.g, wood_color.b, 0.78), true)
	for bay in range(3):
		var x := rect.position.x + 16.0 + bay * 58.0
		draw_rect(Rect2(x, rect.position.y + 10.0, 42, 12), wood_color.darkened(0.12), true)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x, rect.position.y + 22.0),
				Vector2(x + 42.0, rect.position.y + 22.0),
				Vector2(x + 34.0, rect.position.y + 38.0),
				Vector2(x + 8.0, rect.position.y + 38.0),
			]),
			reed_color if bay % 2 == 0 else reed_color.darkened(0.12)
		)
		draw_rect(Rect2(x + 4.0, rect.position.y + 38.0, 34, 20), wood_color.lightened(0.06), true)
		draw_circle(Vector2(x + 14.0, rect.position.y + 48.0), 5.0, Color("c3b58c"))
		draw_rect(Rect2(x + 22.0, rect.position.y + 45.0, 10, 8), Color("8097a4"), true)
	for post in range(4):
		var post_x := rect.position.x + 12.0 + post * 56.0
		draw_line(Vector2(post_x, rect.position.y + 18.0), Vector2(post_x, rect.end.y - 8.0), Color("4c3526"), 2.0)
	for puddle in range(3):
		var center := rect.position + Vector2(34.0 + puddle * 58.0, rect.end.y - 10.0 + float(puddle % 2) * 2.0)
		var puddle_points := PackedVector2Array()
		for step in range(18):
			var angle := TAU * float(step) / 18.0
			puddle_points.append(center + Vector2(cos(angle) * 18.0, sin(angle) * 6.0))
		draw_colored_polygon(puddle_points, Color(0.52, 0.7, 0.76, 0.32))


func _draw_smokestack_worker_corridor(rect: Rect2, base_color: Color, plank_color: Color) -> void:
	draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.82), true)
	for lane in range(4):
		var y := rect.position.y + 16.0 + lane * 26.0
		draw_rect(Rect2(rect.position.x + 18.0, y, rect.size.x - 36.0, 10), plank_color, true)
		draw_line(Vector2(rect.position.x + 22.0, y + 5.0), Vector2(rect.end.x - 22.0, y + 5.0), Color(0, 0, 0, 0.08), 1.0)
	for rail in range(4):
		var x := rect.position.x + 24.0 + rail * 52.0
		draw_line(Vector2(x, rect.position.y + 10.0), Vector2(x, rect.end.y - 12.0), Color("2f231c"), 2.0)
		draw_line(Vector2(x + 18.0, rect.position.y + 10.0), Vector2(x + 18.0, rect.end.y - 12.0), Color("48352a"), 1.0)
	draw_rect(Rect2(rect.position.x + 132.0, rect.position.y + 18.0, 44, 22), Color("6d4b34"), true)
	draw_rect(Rect2(rect.position.x + 140.0, rect.position.y + 24.0, 12, 10), Color("bb8d46"), true)
	draw_rect(Rect2(rect.position.x + 158.0, rect.position.y + 24.0, 10, 10), Color("8c6d4f"), true)
	for grime in range(5):
		var grime_x := rect.position.x + 16.0 + grime * 42.0
		draw_line(Vector2(grime_x, rect.end.y - 18.0), Vector2(grime_x + 16.0, rect.end.y - 6.0), Color(0, 0, 0, 0.12), 1.2)


func _draw_ship_repair_corner(rect: Rect2, base_color: Color, trim_color: Color) -> void:
	draw_rect(Rect2(rect.position.x + 6.0, rect.position.y + 42.0, rect.size.x - 10.0, rect.size.y - 36.0), Color(base_color.r, base_color.g, base_color.b, 0.82), true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(rect.position.x + 10.0, rect.position.y + 118.0),
			Vector2(rect.position.x + 72.0, rect.position.y + 74.0),
			Vector2(rect.position.x + 92.0, rect.position.y + 84.0),
			Vector2(rect.position.x + 46.0, rect.position.y + 132.0),
		]),
		base_color.darkened(0.1)
	)
	for frame in range(3):
		var x := rect.position.x + 18.0 + frame * 26.0
		draw_line(Vector2(x, rect.position.y + 46.0), Vector2(x, rect.end.y - 12.0), Color("4b3527"), 2.0)
		draw_line(Vector2(x, rect.position.y + 56.0), Vector2(x + 30.0, rect.position.y + 34.0), Color("5d4632"), 1.2)
	for plank in range(4):
		var y := rect.position.y + 88.0 + plank * 12.0
		draw_line(Vector2(rect.position.x + 56.0, y), Vector2(rect.position.x + 94.0, y - 8.0), trim_color, 2.0)
	draw_rect(Rect2(rect.position.x + 16.0, rect.position.y + 22.0, 28, 14), trim_color.darkened(0.08), true)
	draw_rect(Rect2(rect.position.x + 52.0, rect.position.y + 18.0, 16, 10), Color("3e5d74"), true)
	draw_rect(Rect2(rect.position.x + 72.0, rect.position.y + 22.0, 18, 8), Color("b7a06b"), true)
	for puddle in range(2):
		var center := rect.position + Vector2(34.0 + puddle * 30.0, rect.end.y - 10.0)
		var points := PackedVector2Array()
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			points.append(center + Vector2(cos(angle) * 16.0, sin(angle) * 5.0))
		draw_colored_polygon(points, Color(0.52, 0.68, 0.74, 0.28))


func _draw_exchange_service_alley(rect: Rect2, wall_color: Color, trim_color: Color) -> void:
	draw_rect(rect, Color(wall_color.r, wall_color.g, wall_color.b, 0.8), true)
	draw_rect(Rect2(rect.position.x + 20.0, rect.position.y + 18.0, 54, 84), wall_color.darkened(0.12), true)
	draw_rect(Rect2(rect.position.x + 28.0, rect.position.y + 30.0, 18, 42), trim_color.darkened(0.16), true)
	draw_rect(Rect2(rect.position.x + 52.0, rect.position.y + 34.0, 14, 12), Color("a68958"), true)
	for step in range(4):
		draw_rect(Rect2(rect.position.x + 76.0 + step * 10.0, rect.position.y + 98.0 + step * 10.0, 48.0 - step * 12.0, 10), trim_color, true)
	for crate in range(3):
		var pos := rect.position + Vector2(88.0 + crate * 18.0, rect.end.y - 28.0 + float(crate % 2) * 4.0)
		draw_rect(Rect2(pos, Vector2(16, 12)), Color("7d6141"), true)
		draw_rect(Rect2(pos + Vector2(2.0, -8.0), Vector2(12, 8)), Color("94724c"), true)
	for ledger in range(3):
		var x := rect.position.x + 24.0 + ledger * 34.0
		draw_line(Vector2(x, rect.position.y + 12.0), Vector2(x, rect.end.y - 10.0), Color(0, 0, 0, 0.08), 1.0)
	draw_rect(Rect2(rect.position.x + 98.0, rect.position.y + 20.0, 24, 10), Color("8f2f33"), true)
	draw_rect(Rect2(rect.position.x + 126.0, rect.position.y + 20.0, 12, 10), Color("6f8752"), true)


func _draw_laundry_backyard_alley(rect: Rect2, yard_color: Color, cloth_color: Color) -> void:
	draw_rect(rect, Color(yard_color.r, yard_color.g, yard_color.b, 0.8), true)
	for lane in range(3):
		var y := rect.position.y + 18.0 + lane * 28.0
		draw_rect(Rect2(rect.position.x + 14.0, y, rect.size.x - 28.0, 12), yard_color.darkened(0.1), true)
	for line_index in range(3):
		var y := rect.position.y + 20.0 + line_index * 24.0
		draw_line(Vector2(rect.position.x + 12.0, y), Vector2(rect.end.x - 12.0, y + 2.0), Color("4d3527"), 1.6)
		for cloth_index in range(4):
			var x := rect.position.x + 18.0 + cloth_index * 34.0 + float(line_index % 2) * 6.0
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(x, y + 2.0),
					Vector2(x + 18.0, y + 2.0),
					Vector2(x + 15.0, y + 16.0),
					Vector2(x + 4.0, y + 14.0),
				]),
				cloth_color if cloth_index % 2 == 0 else Color("6f8752")
			)
	for post in range(4):
		var post_x := rect.position.x + 10.0 + post * 48.0
		draw_line(Vector2(post_x, rect.position.y + 10.0), Vector2(post_x, rect.end.y - 8.0), Color("4e3829"), 2.0)
	draw_rect(Rect2(rect.position.x + 24.0, rect.end.y - 26.0, 22, 12), Color("8e6f48"), true)
	draw_rect(Rect2(rect.position.x + 54.0, rect.end.y - 24.0, 14, 10), Color("7c8e92"), true)
	draw_rect(Rect2(rect.position.x + 84.0, rect.end.y - 28.0, 18, 14), Color("9c7a54"), true)
	for puddle in range(2):
		var center := rect.position + Vector2(118.0 + puddle * 26.0, rect.end.y - 10.0)
		var points := PackedVector2Array()
		for step in range(14):
			var angle := TAU * float(step) / 14.0
			points.append(center + Vector2(cos(angle) * 14.0, sin(angle) * 5.0))
		draw_colored_polygon(points, Color(0.56, 0.66, 0.7, 0.22))


func _draw_factory_ash_drain(rect: Rect2, ash_color: Color, channel_color: Color) -> void:
	draw_rect(rect, Color(ash_color.r, ash_color.g, ash_color.b, 0.84), true)
	draw_rect(Rect2(rect.position.x + 18.0, rect.position.y + 18.0, rect.size.x - 36.0, 16), channel_color, true)
	draw_rect(Rect2(rect.position.x + 26.0, rect.position.y + 22.0, rect.size.x - 52.0, 8), Color("1f1a18"), true)
	for branch in range(4):
		var x := rect.position.x + 40.0 + branch * 54.0
		draw_line(Vector2(x, rect.position.y + 12.0), Vector2(x - 14.0, rect.position.y + 34.0), Color("241f1c"), 1.4)
		draw_line(Vector2(x, rect.position.y + 40.0), Vector2(x + 12.0, rect.end.y - 12.0), Color("241f1c"), 1.2)
	for grate in range(5):
		var x := rect.position.x + 26.0 + grate * 48.0
		draw_rect(Rect2(x, rect.position.y + 16.0, 18, 20), Color("4a4137"), true)
		draw_line(Vector2(x + 6.0, rect.position.y + 18.0), Vector2(x + 6.0, rect.position.y + 34.0), Color("26211d"), 1.0)
		draw_line(Vector2(x + 12.0, rect.position.y + 18.0), Vector2(x + 12.0, rect.position.y + 34.0), Color("26211d"), 1.0)
	for slurry in range(3):
		var center := rect.position + Vector2(74.0 + slurry * 72.0, rect.end.y - 12.0 + float(slurry % 2) * 2.0)
		var points := PackedVector2Array()
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			points.append(center + Vector2(cos(angle) * 18.0, sin(angle) * 6.0))
		draw_colored_polygon(points, Color(0.2, 0.18, 0.18, 0.32))


func _draw_rope_wet_alley(rect: Rect2, wood_color: Color, moss_color: Color) -> void:
	draw_rect(rect, Color(wood_color.r, wood_color.g, wood_color.b, 0.78), true)
	for plank in range(5):
		var y := rect.position.y + 16.0 + plank * 22.0
		draw_rect(Rect2(rect.position.x + 12.0, y, rect.size.x - 24.0, 10), wood_color.darkened(0.12), true)
		draw_line(Vector2(rect.position.x + 14.0, y + 5.0), Vector2(rect.end.x - 14.0, y + 5.0), Color(1, 1, 1, 0.04), 1.0)
	for rope in range(4):
		var x := rect.position.x + 22.0 + rope * 22.0
		draw_line(Vector2(x, rect.position.y + 10.0), Vector2(x + 8.0, rect.end.y - 12.0), Color("59402e"), 2.0)
		draw_circle(Vector2(x + 10.0, rect.position.y + 36.0 + float(rope % 2) * 18.0), 5.0, Color("7e6246"))
	for puddle in range(2):
		var center := rect.position + Vector2(36.0 + puddle * 34.0, rect.end.y - 12.0)
		var points := PackedVector2Array()
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			points.append(center + Vector2(cos(angle) * 16.0, sin(angle) * 5.0))
		draw_colored_polygon(points, Color(0.5, 0.66, 0.72, 0.24))
	draw_rect(Rect2(rect.position.x + 76.0, rect.position.y + 22.0, 18, 12), moss_color, true)
	draw_rect(Rect2(rect.position.x + 82.0, rect.position.y + 44.0, 10, 8), Color("87a0aa"), true)


func _draw_stone_courtyard_garden(rect: Rect2, stone_color: Color, leaf_color: Color) -> void:
	draw_rect(rect, Color(stone_color.r, stone_color.g, stone_color.b, 0.74), true)
	for row in range(4):
		for column in range(4):
			var x := rect.position.x + 16.0 + column * 34.0 + float(row % 2) * 4.0
			var y := rect.position.y + 16.0 + row * 28.0
			draw_rect(Rect2(x, y, 24, 14), stone_color.lightened(0.06) if (row + column) % 2 == 0 else stone_color.darkened(0.04), true)
	for planter in range(3):
		var base := rect.position + Vector2(18.0 + planter * 42.0, rect.end.y - 34.0)
		draw_rect(Rect2(base, Vector2(26, 14)), Color("816343"), true)
		draw_rect(Rect2(base + Vector2(4.0, -12.0), Vector2(18, 12)), leaf_color, true)
	draw_rect(Rect2(rect.position.x + 112.0, rect.position.y + 18.0, 34, 48), stone_color.darkened(0.12), true)
	draw_rect(Rect2(rect.position.x + 120.0, rect.position.y + 26.0, 18, 30), Color("b99a62"), true)
	for vine in range(3):
		var vine_x := rect.position.x + 110.0 + vine * 12.0
		draw_line(Vector2(vine_x, rect.position.y + 10.0), Vector2(vine_x - 6.0, rect.position.y + 48.0), leaf_color.darkened(0.1), 1.2)


func _draw_corner_hearth(rect: Rect2, wall_color: Color, ember_color: Color) -> void:
	draw_rect(rect, Color(wall_color.r, wall_color.g, wall_color.b, 0.78), true)
	draw_rect(Rect2(rect.position.x + 10.0, rect.position.y + 18.0, 34, 24), wall_color.darkened(0.12), true)
	draw_rect(Rect2(rect.position.x + 18.0, rect.position.y + 26.0, 18, 10), Color("7d5b3e"), true)
	draw_rect(Rect2(rect.position.x + 54.0, rect.position.y + 46.0, 24, 14), Color("6b5038"), true)
	draw_circle(Vector2(rect.position.x + 66.0, rect.position.y + 44.0), 10.0, Color("35261b"))
	draw_circle(Vector2(rect.position.x + 66.0, rect.position.y + 44.0), 5.0, ember_color)
	draw_line(Vector2(rect.position.x + 66.0, rect.position.y + 18.0), Vector2(rect.position.x + 66.0, rect.position.y + 34.0), Color("413026"), 2.0)
	for smoke in range(3):
		var center := rect.position + Vector2(66.0 + float(smoke % 2) * 10.0, 10.0 + smoke * 12.0)
		var points := PackedVector2Array()
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			points.append(center + Vector2(cos(angle) * (9.0 + smoke), sin(angle) * (4.0 + smoke * 0.8)))
		draw_colored_polygon(points, Color(0.34, 0.32, 0.3, 0.18))
	draw_rect(Rect2(rect.position.x + 18.0, rect.end.y - 18.0, 20, 8), Color("9a7a54"), true)
	draw_rect(Rect2(rect.position.x + 44.0, rect.end.y - 16.0, 16, 8), Color("7f8d92"), true)


func _draw_stake_net_beach(rect: Rect2, wood_color: Color, reed_color: Color) -> void:
	draw_rect(rect, Color(wood_color.r, wood_color.g, wood_color.b, 0.62), true)
	for stake in range(5):
		var x := rect.position.x + 18.0 + stake * 28.0
		draw_line(Vector2(x, rect.position.y + 12.0), Vector2(x, rect.end.y - 8.0), Color("5a4030"), 2.2)
		draw_line(Vector2(x, rect.position.y + 30.0), Vector2(x + 18.0, rect.position.y + 44.0), Color("6d523d"), 1.2)
	for rack in range(3):
		var x := rect.position.x + 10.0 + rack * 48.0
		draw_line(Vector2(x, rect.position.y + 26.0), Vector2(x + 32.0, rect.position.y + 26.0), Color("4e3828"), 2.0)
		draw_rect(Rect2(x + 4.0, rect.position.y + 30.0, 24, 16), Color("78939b"), true)
		draw_line(Vector2(x + 6.0, rect.position.y + 32.0), Vector2(x + 26.0, rect.position.y + 44.0), Color(1, 1, 1, 0.06), 1.0)
	for puddle in range(3):
		var center := rect.position + Vector2(28.0 + puddle * 42.0, rect.end.y - 10.0 + float(puddle % 2) * 2.0)
		var points := PackedVector2Array()
		for step in range(16):
			var angle := TAU * float(step) / 16.0
			points.append(center + Vector2(cos(angle) * 18.0, sin(angle) * 5.0))
		draw_colored_polygon(points, Color(0.48, 0.64, 0.72, 0.24))
	draw_rect(Rect2(rect.position.x + 128.0, rect.position.y + 18.0, 18, 12), reed_color, true)
	draw_rect(Rect2(rect.position.x + 132.0, rect.position.y + 36.0, 12, 8), Color("b79a62"), true)


func _draw_coal_sack_loading_bay(rect: Rect2, timber_color: Color, coal_color: Color) -> void:
	draw_rect(rect, Color(timber_color.r, timber_color.g, timber_color.b, 0.78), true)
	for lane in range(3):
		var y := rect.position.y + 14.0 + lane * 22.0
		draw_rect(Rect2(rect.position.x + 12.0, y, rect.size.x - 24.0, 10), timber_color.darkened(0.1), true)
		draw_line(Vector2(rect.position.x + 16.0, y + 5.0), Vector2(rect.end.x - 16.0, y + 5.0), Color(1, 1, 1, 0.04), 1.0)
	for stack in range(4):
		var base := rect.position + Vector2(14.0 + stack * 32.0, rect.end.y - 24.0 + float(stack % 2) * 4.0)
		draw_circle(base + Vector2(10.0, 8.0), 8.0, coal_color)
		draw_circle(base + Vector2(22.0, 8.0), 8.0, coal_color.darkened(0.04))
		draw_rect(Rect2(base + Vector2(6.0, -6.0), Vector2(22, 6)), Color("86715a"), true)
	for rail in range(3):
		var x := rect.position.x + 18.0 + rail * 46.0
		draw_line(Vector2(x, rect.position.y + 8.0), Vector2(x, rect.end.y - 10.0), Color("3b2d24"), 2.0)
		draw_line(Vector2(x + 18.0, rect.position.y + 8.0), Vector2(x + 18.0, rect.end.y - 10.0), Color("4d3a2f"), 1.2)
	draw_rect(Rect2(rect.position.x + 112.0, rect.position.y + 18.0, 26, 12), Color("9b835d"), true)
	draw_rect(Rect2(rect.position.x + 118.0, rect.position.y + 36.0, 14, 8), Color("6e7b62"), true)


func _draw_arcade_notice_wall(rect: Rect2, wall_color: Color, paper_color: Color) -> void:
	draw_rect(rect, Color(wall_color.r, wall_color.g, wall_color.b, 0.8), true)
	draw_rect(Rect2(rect.position.x + 10.0, rect.position.y + 10.0, rect.size.x - 20.0, rect.size.y - 20.0), wall_color.darkened(0.08), true)
	for row in range(3):
		for col in range(3):
			var x := rect.position.x + 18.0 + col * 42.0 + float(row % 2) * 4.0
			var y := rect.position.y + 18.0 + row * 28.0
			draw_rect(Rect2(x, y, 24, 16), paper_color if (row + col) % 2 == 0 else paper_color.darkened(0.08), true)
			draw_line(Vector2(x + 4.0, y + 6.0), Vector2(x + 20.0, y + 6.0), Color("8d6b49"), 1.0)
			draw_line(Vector2(x + 4.0, y + 10.0), Vector2(x + 18.0, y + 10.0), Color("8d6b49"), 1.0)
	for pin in range(4):
		var pin_x := rect.position.x + 20.0 + pin * 34.0
		draw_circle(Vector2(pin_x, rect.position.y + 12.0), 2.0, Color("8f2f33"))
	draw_rect(Rect2(rect.position.x + 108.0, rect.end.y - 24.0, 22, 10), Color("7a5b3c"), true)


func _draw_post_pair(start: Vector2, ending: Vector2, wood_color: Color) -> void:
	draw_line(start, start + Vector2(0, 20), wood_color, 3.0)
	draw_line(ending, ending + Vector2(0, 20), wood_color, 3.0)
	draw_line(start + Vector2(0, 6), ending + Vector2(0, 8), wood_color.lightened(0.12), 2.0)


func _draw_dry_fish_rack(origin: Vector2, count: int) -> void:
	for index in range(count):
		var base := origin + Vector2(index * 34.0, fmod(float(index) * 5.0, 7.0))
		draw_line(base, base + Vector2(0, 26), Color("5b3c28"), 2.4)
		draw_line(base + Vector2(18, 0), base + Vector2(18, 26), Color("5b3c28"), 2.4)
		draw_line(base, base + Vector2(18, 0), Color("81613c"), 2.0)
		draw_line(base + Vector2(3, 4), base + Vector2(10, 18), Color("a7bac3"), 1.2)
		draw_line(base + Vector2(14, 5), base + Vector2(8, 18), Color("a7bac3"), 1.2)


func _draw_ramp_run(origin: Vector2, sections: int) -> void:
	for index in range(sections):
		var pos := origin + Vector2(index * 38.0, 0)
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, 0),
			pos + Vector2(32, 6),
			pos + Vector2(32, 14),
			pos + Vector2(0, 8)
		]), Color("7a5738"))
		draw_line(pos + Vector2(0, 4), pos + Vector2(32, 10), Color("4f341f"), 1.2)


func _draw_chain_moorings(origin: Vector2, count: int) -> void:
	for index in range(count):
		var start := origin + Vector2(index * 60.0, 0)
		draw_arc(start, 7.0, 0.2, PI - 0.2, 10, Color("8f7d62"), 1.4)
		draw_arc(start + Vector2(10, 0), 7.0, 0.2, PI - 0.2, 10, Color("8f7d62"), 1.4)


func _draw_branch_jetty(origin: Vector2, spans: int, wood_color: Color) -> void:
	for index in range(spans):
		var y := origin.y + index * 20.0
		draw_rect(Rect2(origin.x, y, 76, 10), wood_color, true)
		draw_line(Vector2(origin.x + 12, y), Vector2(origin.x + 12, y + 10), wood_color.darkened(0.22), 1.2)
		draw_line(Vector2(origin.x + 44, y), Vector2(origin.x + 44, y + 10), wood_color.darkened(0.22), 1.2)
	for index in range(spans + 1):
		var x := origin.x + 10.0 + float(index % 2) * 32.0
		var y := origin.y + index * 18.0
		draw_line(Vector2(x, y), Vector2(x, y + 28), wood_color.darkened(0.28), 2.0)


func _draw_tide_steps(origin: Vector2, steps: int, stone_color: Color) -> void:
	for index in range(steps):
		draw_rect(Rect2(origin.x - index * 12.0, origin.y + index * 10.0, 30, 8), stone_color, true)
		draw_rect(Rect2(origin.x - index * 12.0, origin.y + index * 10.0, 30, 8), Color(0, 0, 0, 0.08), false, 1.0)


func _draw_boiler_tanks(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 46.0, sin(float(index) * 0.6) * 3.0)
		_draw_ellipse(pos, Vector2(18, 10), Color("6e5b4e"))
		draw_rect(Rect2(pos.x - 18, pos.y, 36, 30), Color("5d4a3f"), true)
		_draw_ellipse(pos + Vector2(0, 30), Vector2(18, 10), Color("4a3a31"))


func _draw_rail_siding(origin: Vector2, sleepers: int) -> void:
	for index in range(sleepers):
		var pos := origin + Vector2(index * 30.0, 0)
		draw_line(pos + Vector2(0, 0), pos + Vector2(0, 42), Color("3f2b1b"), 1.8)
	draw_line(origin + Vector2(-8, 6), origin + Vector2((sleepers - 1) * 30.0 + 8, 10), Color("8c6a40"), 2.4)
	draw_line(origin + Vector2(-8, 24), origin + Vector2((sleepers - 1) * 30.0 + 8, 28), Color("8c6a40"), 2.4)


func _draw_conveyor_frame(origin: Vector2, spans: int) -> void:
	for index in range(spans):
		var pos := origin + Vector2(index * 38.0, 0)
		draw_rect(Rect2(pos, Vector2(28, 8)), Color("785a3c"), true)
		draw_line(pos + Vector2(0, 8), pos + Vector2(0, 30), Color("4b3120"), 2.0)
		draw_line(pos + Vector2(28, 8), pos + Vector2(28, 30), Color("4b3120"), 2.0)


func _draw_loading_yard(rect: Rect2, base_color: Color, plank_color: Color) -> void:
	draw_rect(rect, base_color, true)
	for index in range(5):
		var x := rect.position.x + 18.0 + index * 28.0
		draw_rect(Rect2(x, rect.position.y + 8, 18, rect.size.y - 16.0), plank_color, true)
		draw_line(Vector2(x + 9, rect.position.y + 8), Vector2(x + 9, rect.position.y + rect.size.y - 8.0), plank_color.darkened(0.18), 1.0)


func _draw_arcade_shadow_band(rect: Rect2) -> void:
	for index in range(8):
		var pos := rect.position + Vector2(index * rect.size.x / 8.0, 0)
		draw_rect(Rect2(pos, Vector2(rect.size.x / 16.0, rect.size.y)), Color(0, 0, 0, 0.08), true)


func _draw_plaza_mosaic(center: Vector2, rings: int) -> void:
	for ring in range(rings):
		var radius := 12.0 + ring * 12.0
		draw_arc(center, radius, 0.0, TAU, 28, Color("b79b69"), 1.2)
	for angle_index in range(8):
		var angle := TAU * float(angle_index) / 8.0
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * 42.0, Color("9c845a"), 1.0)


func _draw_side_arcade(origin: Vector2, bays: int, column_color: Color, roof_color: Color) -> void:
	draw_rect(Rect2(origin.x - 8, origin.y - 14, bays * 34.0 + 16.0, 14), roof_color, true)
	for index in range(bays + 1):
		var x := origin.x + index * 34.0
		draw_rect(Rect2(x, origin.y, 10, 48), column_color, true)
		draw_rect(Rect2(x + 2, origin.y, 2, 48), Color(1, 1, 1, 0.1), true)
	for index in range(bays):
		var x := origin.x + 8.0 + index * 34.0
		draw_arc(Vector2(x + 9, origin.y + 18), 11.0, PI, TAU, 14, column_color.darkened(0.06), 2.0)


func _draw_field_gate(origin: Vector2, wood_color: Color, dark_color: Color) -> void:
	draw_line(origin, origin + Vector2(0, 36), dark_color, 3.0)
	draw_line(origin + Vector2(36, 0), origin + Vector2(36, 36), dark_color, 3.0)
	draw_line(origin, origin + Vector2(36, 6), wood_color, 2.0)
	draw_line(origin + Vector2(0, 18), origin + Vector2(36, 24), wood_color, 2.0)
	draw_line(origin, origin + Vector2(36, 36), dark_color, 2.0)


func _draw_ground_clutter(rect: Rect2, zone: int, base_color: Color) -> void:
	for index in range(24):
		var x := rect.position.x + 20.0 + fmod(float(index) * 57.0 + float(zone) * 13.0, rect.size.x - 40.0)
		var y := rect.position.y + 16.0 + fmod(float(index) * 43.0 + float(zone) * 19.0, rect.size.y - 32.0)
		var center := Vector2(x, y)
		match zone:
			0:
				_draw_ellipse(center, Vector2(10.0 + float(index % 3) * 2.0, 4.0), Color(0.26, 0.18, 0.13, 0.18))
				if index % 2 == 0:
					draw_line(center + Vector2(-3, 7), center + Vector2(-5, -3), Color("687848"), 1.5)
					draw_line(center + Vector2(1, 7), center + Vector2(2, -5), Color("798c56"), 1.4)
			1:
				draw_rect(Rect2(center - Vector2(8, 3), Vector2(16, 6)), Color(0.77, 0.76, 0.67, 0.14), true)
				if index % 3 == 0:
					draw_line(center + Vector2(-4, 6), center + Vector2(-6, -4), Color("6c7c4a"), 1.3)
					draw_line(center + Vector2(2, 6), center + Vector2(5, -2), Color("8aa063"), 1.1)
			2:
				_draw_ellipse(center, Vector2(9.0, 4.0), Color(0.18, 0.13, 0.1, 0.22))
				draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 4)), Color(0.56, 0.42, 0.22, 0.18), true)
			3:
				draw_rect(Rect2(center - Vector2(8, 4), Vector2(16, 8)), base_color.lightened(0.16), true)
				draw_rect(Rect2(center - Vector2(6, 2), Vector2(12, 4)), base_color.darkened(0.1), false, 1.0)
				if index % 4 == 0:
					draw_circle(center + Vector2(0, -8), 3.0, Color("73864f"))


func _draw_scatter_stones() -> void:
	for index in range(22):
		var x := 46.0 + fmod(float(index) * 131.0, 1504.0)
		var y := 42.0 + fmod(float(index) * 97.0, 884.0)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x, y),
				Vector2(x + 8, y - 3),
				Vector2(x + 14, y + 4),
				Vector2(x + 5, y + 11),
				Vector2(x - 3, y + 6)
			]),
			Color("7c715c")
		)


func _draw_meadow_hut(origin: Vector2, roof_color: Color) -> void:
	draw_rect(Rect2(origin, Vector2(72, 52)), Color("7d6545"), true)
	draw_rect(Rect2(origin + Vector2(-8, -16), Vector2(88, 20)), roof_color, true)
	draw_rect(Rect2(origin + Vector2(20, 18), Vector2(16, 34)), Color("39251a"), true)
	draw_rect(Rect2(origin + Vector2(46, 18), Vector2(14, 14)), Color("cfbf95"), true)
	_draw_window_glow(Rect2(origin + Vector2(46, 18), Vector2(14, 14)))


func _draw_farm_patch(rect: Rect2) -> void:
	draw_rect(rect, Color("56472f"), true)
	for row in range(4):
		for column in range(8):
			var x := rect.position.x + 14 + column * 24
			var y := rect.position.y + 10 + row * 16
			draw_line(Vector2(x, y), Vector2(x + 8, y + 5), Color("7e6b41"), 1.6)
			draw_line(Vector2(x + 3, y - 2), Vector2(x + 4, y + 10), Color("9fb15b"), 1.2)


func _draw_orchard_row(origin: Vector2, count: int, leaf_color: Color) -> void:
	for index in range(count):
		var trunk := origin + Vector2(index * 40.0, sin(float(index) * 0.9) * 5.0)
		draw_rect(Rect2(trunk + Vector2(-3, 6), Vector2(6, 18)), Color("543722"), true)
		draw_circle(trunk + Vector2(0, 2), 14.0, leaf_color)
		draw_circle(trunk + Vector2(-7, 6), 9.0, leaf_color.darkened(0.08))
		draw_circle(trunk + Vector2(7, 7), 8.0, leaf_color.lightened(0.06))


func _draw_patchwork_roof(origin: Vector2, size: Vector2) -> void:
	var patch_colors: Array[Color] = [Color("7e5136"), Color("8d6a2f"), Color("5e4331"), Color("8f2f33")]
	for index in range(4):
		var segment := Rect2(origin + Vector2(index * size.x / 4.0, 0), Vector2(size.x / 4.0 - 1.0, size.y))
		var patch_color: Color = patch_colors[index]
		draw_rect(segment, patch_color, true)
		draw_rect(segment, Color(0, 0, 0, 0.14), false, 1.0)


func _draw_clutter_bundle(origin: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2(index * 12.0, fmod(float(index) * 5.0, 11.0))
		draw_rect(Rect2(origin + offset, Vector2(10, 8)), Color("7b5a38"), true)
		draw_rect(Rect2(origin + offset + Vector2(2, -4), Vector2(6, 4)), Color("cab17d"), true)


func _draw_puddle_cluster(origin: Vector2, count: int) -> void:
	for index in range(count):
		var center := origin + Vector2(index * 22.0, sin(float(index) * 1.7) * 4.0)
		_draw_ellipse(center, Vector2(16, 8), Color(0.24, 0.3, 0.35, 0.42))
		_draw_ellipse(center + Vector2(3, -1), Vector2(7, 3), Color(0.72, 0.78, 0.82, 0.16))


func _draw_bucket_row(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 14.0, fmod(float(index) * 3.0, 5.0))
		draw_rect(Rect2(pos, Vector2(9, 10)), Color("66513f"), true)
		draw_arc(pos + Vector2(4.5, 2.0), 4.0, PI, TAU, 12, Color("d0bb92"), 1.0)


func _draw_mooring_posts(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 82.0, 0)
		draw_rect(Rect2(pos, Vector2(10, 22)), Color("523721"), true)
		draw_line(pos + Vector2(0, 8), pos + Vector2(14, 8), Color("d2b27c"), 2.0)
		draw_line(pos + Vector2(0, 14), pos + Vector2(14, 14), Color("d2b27c"), 2.0)


func _draw_fish_crates(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 28.0, fmod(float(index) * 6.0, 9.0))
		draw_rect(Rect2(pos, Vector2(22, 14)), Color("785334"), true)
		draw_rect(Rect2(pos, Vector2(22, 14)), Color("3f2919"), false, 1.5)
		draw_line(pos + Vector2(4, 4), pos + Vector2(18, 10), Color("a7bac3"), 1.3)
		draw_line(pos + Vector2(18, 4), pos + Vector2(4, 10), Color("a7bac3"), 1.3)


func _draw_wave_foam(rect: Rect2) -> void:
	for index in range(12):
		var x := rect.position.x + 18.0 + index * 54.0
		var y := rect.position.y + rect.size.y - 8.0 + sin(_time * 2.2 + index) * 2.0
		draw_arc(Vector2(x, y), 10.0, PI * 1.05, PI * 1.95, 10, Color(0.91, 0.96, 0.98, 0.28), 1.6)


func _draw_buoy_pair(origin: Vector2) -> void:
	for index in range(2):
		var center := origin + Vector2(index * 18.0, sin(_time * 1.8 + index) * 4.0)
		draw_circle(center, 5.0, Color("b34c39"))
		draw_circle(center + Vector2(0, -6), 2.0, Color("ead8a6"))


func _draw_gear_pile(origin: Vector2) -> void:
	_draw_cog(origin, 16.0, Color("6a5847"))
	_draw_cog(origin + Vector2(22, 10), 10.0, Color("7a6651"))


func _draw_cog(center: Vector2, radius: float, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(16):
		var angle := TAU * float(step) / 16.0
		var tooth_radius := radius + (3.0 if step % 2 == 0 else -1.0)
		points.append(center + Vector2(cos(angle) * tooth_radius, sin(angle) * tooth_radius))
	draw_colored_polygon(points, color_value)
	_draw_ellipse(center, Vector2(radius * 0.35, radius * 0.35), Color("2c2118"))


func _draw_smokestack_cluster(origin: Vector2, count: int) -> void:
	for index in range(count):
		var x := origin.x + index * 34.0
		var height := 42.0 + index * 8.0
		draw_rect(Rect2(Vector2(x, origin.y - height), Vector2(18, height)), Color("4c3a2d"), true)
		draw_rect(Rect2(Vector2(x - 2, origin.y - height - 8), Vector2(22, 8)), Color("2f2119"), true)


func _draw_warning_lantern(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 18), Color("3f2a1c"), 2.0)
	draw_circle(origin + Vector2(0, 24), 6.0, Color("b98b3f"))
	draw_circle(origin + Vector2(0, 24), 13.0, Color(0.95, 0.72, 0.3, lerpf(0.04, 0.16, 1.0 - light_level)))


func _draw_fountain(center: Vector2) -> void:
	_draw_ellipse(center, Vector2(34, 14), Color("7b6548"))
	_draw_ellipse(center, Vector2(24, 9), Color("4f7e8e"))
	draw_line(center + Vector2(0, -16), center + Vector2(0, 2), Color("cbb58a"), 3.0)
	draw_circle(center + Vector2(0, -18), 6.0, Color("d9c7a0"))


func _draw_flag_row(origin: Vector2, count: int, color_a: Color, color_b: Color) -> void:
	draw_line(origin, origin + Vector2(count * 48.0, 0), Color("6b4a2d"), 2.0)
	for index in range(count):
		var start := origin + Vector2(index * 48.0 + 6.0, 0)
		var color_value := color_a if index % 2 == 0 else color_b
		draw_colored_polygon(PackedVector2Array([
			start,
			start + Vector2(18, 5),
			start + Vector2(3, 18)
		]), color_value)


func _draw_carriage(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(46, 18)), Color("7b5937"), true)
	draw_rect(Rect2(origin + Vector2(8, -14), Vector2(30, 14)), Color("8c6b45"), true)
	draw_circle(origin + Vector2(10, 20), 8.0, Color("4d3420"))
	draw_circle(origin + Vector2(36, 20), 8.0, Color("4d3420"))
	draw_circle(origin + Vector2(10, 20), 3.0, Color("cdb588"))
	draw_circle(origin + Vector2(36, 20), 3.0, Color("cdb588"))
	draw_line(origin + Vector2(46, 8), origin + Vector2(74, 0), Color("5d422a"), 2.0)


func _draw_dirt_path(points: PackedVector2Array, width: float) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var ending := points[index + 1]
		var direction := (ending - start).normalized()
		var normal := Vector2(-direction.y, direction.x) * width * 0.5
		draw_colored_polygon(PackedVector2Array([
			start + normal * 0.86,
			ending + normal,
			ending - normal * 0.72,
			start - normal
		]), Color("6b5437"))
		for sample in range(3):
			var ratio := float(sample + 1) / 4.0
			var center := start.lerp(ending, ratio)
			var wobble := Vector2(-direction.y, direction.x) * (width * 0.22 if sample % 2 == 0 else -width * 0.18)
			draw_circle(center + wobble, 5.0 + float((index + sample) % 3) * 1.5, Color(0.42, 0.32, 0.2, 0.18))
			draw_circle(center - wobble * 0.55, 4.0 + float(sample % 2), Color(0.56, 0.46, 0.3, 0.14))


func _draw_ellipse(center: Vector2, radii: Vector2, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(18):
		var angle := TAU * float(step) / 18.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)


func _draw_forecourt_bleed(rect: Rect2, soil_color: Color, fringe_color: Color) -> void:
	for index in range(7):
		var ratio := float(index) / 6.0
		var x := rect.position.x + 8.0 + ratio * (rect.size.x - 16.0)
		var y_top := rect.position.y + sin(float(index) * 0.8) * 4.0
		var y_bottom := rect.end.y + sin(float(index) * 0.6 + 0.4) * 5.0
		draw_circle(Vector2(x, y_top), 10.0 + float(index % 2) * 3.0, fringe_color)
		draw_circle(Vector2(x + 4.0, y_bottom), 12.0 + float((index + 1) % 2) * 3.0, soil_color)
	for index in range(4):
		var y := rect.position.y + 16.0 + index * (rect.size.y - 32.0) / 3.0
		draw_circle(Vector2(rect.position.x - 4.0, y), 8.0 + float(index % 2) * 2.0, fringe_color)
		draw_circle(Vector2(rect.end.x + 3.0, y + 4.0), 9.0 + float((index + 1) % 2) * 2.0, soil_color)


func _draw_brush_strokes(rect: Rect2, color_value: Color, count: int) -> void:
	for index in range(count):
		var x := rect.position.x + 20.0 + fmod(float(index) * 73.0, rect.size.x - 40.0)
		var y := rect.position.y + 16.0 + fmod(float(index) * 49.0, rect.size.y - 32.0)
		var width := 12.0 + fmod(float(index) * 5.0, 22.0)
		draw_line(Vector2(x, y), Vector2(x + width, y + sin(float(index) * 0.7) * 3.0), color_value, 1.4)


func _draw_ink_hatching(rect: Rect2, spacing: float, alpha: float) -> void:
	var lines := int(rect.size.x / spacing) + 2
	for index in range(lines):
		var start := rect.position + Vector2(index * spacing - 24.0, rect.size.y)
		var ending := rect.position + Vector2(index * spacing + 22.0, 0.0)
		draw_line(start, ending, Color(0, 0, 0, alpha), 1.0)


func _draw_stone_seams(rect: Rect2, vertical: bool) -> void:
	if vertical:
		for index in range(10):
			var y := rect.position.y + 26.0 + index * 80.0
			draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.position.x + rect.size.x - 8, y + 8), Color(0, 0, 0, 0.08), 1.6)
	else:
		for index in range(18):
			var x := rect.position.x + 18.0 + index * 82.0
			draw_line(Vector2(x, rect.position.y + 8), Vector2(x - 8, rect.position.y + rect.size.y - 8), Color(0, 0, 0, 0.08), 1.6)


func _draw_broken_cart(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(44, 18)), Color("755338"), true)
	draw_rect(Rect2(origin, Vector2(44, 18)), Color("3f2919"), false, 2.0)
	draw_line(origin + Vector2(44, 8), origin + Vector2(72, 0), Color("5c412c"), 3.0)
	draw_circle(origin + Vector2(10, 22), 9.0, Color("5d422c"))
	draw_circle(origin + Vector2(34, 22), 9.0, Color("5d422c"))
	draw_circle(origin + Vector2(10, 22), 4.0, Color("d8be85"))
	draw_circle(origin + Vector2(34, 22), 4.0, Color("d8be85"))


func _draw_barrel_group(origin: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2(index * 16.0, fmod(float(index) * 7.0, 10.0))
		draw_rect(Rect2(origin + offset, Vector2(14, 20)), Color("704d31"), true)
		draw_rect(Rect2(origin + offset, Vector2(14, 20)), Color("3d2818"), false, 1.5)
		draw_line(origin + offset + Vector2(0, 6), origin + offset + Vector2(14, 6), Color("c8ab74"), 1.2)
		draw_line(origin + offset + Vector2(0, 14), origin + offset + Vector2(14, 14), Color("c8ab74"), 1.2)


func _draw_mud_patch(rect: Rect2, color_value: Color) -> void:
	draw_rect(rect, color_value, true)
	for index in range(6):
		var center := rect.position + Vector2(18 + index * 30, 10 + fmod(float(index) * 9.0, rect.size.y - 12.0))
		draw_circle(center, 5.0 + fmod(float(index) * 2.0, 4.0), color_value.darkened(0.08))


func _draw_net_rack(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, 40), Color("5b3f2a"), 3.0)
	draw_line(origin + Vector2(46, 0), origin + Vector2(46, 40), Color("5b3f2a"), 3.0)
	draw_line(origin, origin + Vector2(46, 0), Color("7d5e3a"), 3.0)
	for index in range(5):
		draw_line(origin + Vector2(index * 10, 4), origin + Vector2(index * 10 + 8, 34), Color(0.88, 0.8, 0.62, 0.34), 1.0)
		draw_line(origin + Vector2(index * 10 + 8, 4), origin + Vector2(index * 10, 34), Color(0.88, 0.8, 0.62, 0.34), 1.0)


func _draw_palisade_run(origin: Vector2, posts: int, height: float, wood_color: Color, shadow_color: Color) -> void:
	for index in range(posts):
		var pos := origin + Vector2(index * 28.0, sin(float(index) * 0.5) * 2.0)
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-8, 0),
			pos + Vector2(0, -height),
			pos + Vector2(8, 0)
		]), wood_color)
		draw_rect(Rect2(pos + Vector2(-8, 0), Vector2(16, height * 0.08 + 3.0)), shadow_color, true)
	for rail in [16.0, 32.0]:
		draw_line(origin + Vector2(-6, -rail), origin + Vector2((posts - 1) * 28.0 + 6, -rail + 3.0), shadow_color, 3.0)


func _draw_harbor_masts(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 96.0, sin(float(index) * 0.7) * 4.0)
		draw_line(pos, pos + Vector2(0, -54), Color("503523"), 2.0)
		draw_line(pos + Vector2(0, -44), pos + Vector2(32, -40), Color("6b4a31"), 1.8)
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(2, -44),
			pos + Vector2(26, -38),
			pos + Vector2(4, -18)
		]), Color(1, 1, 1, 0.16))


func _draw_plank_walkway(rect: Rect2, boards: int) -> void:
	draw_rect(rect, Color("765236"), true)
	for index in range(boards):
		var x := rect.position.x + index * rect.size.x / float(boards)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), Color("4f341f"), 1.4)


func _draw_pipe_run(origin: Vector2, segments: int) -> void:
	for index in range(segments):
		var base := origin + Vector2(index * 112.0, sin(float(index) * 0.7) * 5.0)
		draw_rect(Rect2(base, Vector2(90, 12)), Color("4e3a2f"), true)
		draw_circle(base + Vector2(90, 6), 6.0, Color("6b5446"))


func _draw_pipe_bridge(origin: Vector2, spans: int) -> void:
	for index in range(spans):
		var base := origin + Vector2(index * 52.0, sin(float(index) * 0.5) * 3.0)
		draw_rect(Rect2(base, Vector2(44, 10)), Color("5a4538"), true)
		draw_line(base + Vector2(6, 10), base + Vector2(6, 30), Color("3f2d21"), 2.0)
		draw_line(base + Vector2(38, 10), base + Vector2(38, 30), Color("3f2d21"), 2.0)
		draw_circle(base + Vector2(44, 5), 5.0, Color("7b6554"))


func _draw_slag_pool(origin: Vector2, size: Vector2) -> void:
	var rect := Rect2(origin, size)
	draw_rect(rect, Color("2a1c17"), true)
	for index in range(4):
		var x := rect.position.x + 8.0 + index * (rect.size.x - 16.0) / 3.0
		draw_circle(Vector2(x, rect.position.y + rect.size.y * 0.45), 5.0 + index, Color(0.93, 0.47, 0.14, 0.15))


func _draw_catwalk(origin: Vector2, spans: int) -> void:
	for index in range(spans):
		var base := origin + Vector2(index * 42.0, 0)
		draw_rect(Rect2(base, Vector2(34, 10)), Color("7e5e3e"), true)
		draw_line(base + Vector2(0, 10), base + Vector2(0, 28), Color("4a3021"), 2.0)
		draw_line(base + Vector2(34, 10), base + Vector2(34, 28), Color("4a3021"), 2.0)


func _draw_sawtooth_hall(origin: Vector2, size: Vector2, teeth: int) -> void:
	draw_rect(Rect2(origin, size), Color("59463a"), true)
	var tooth_width := size.x / float(teeth)
	for index in range(teeth):
		var base_x := origin.x + index * tooth_width
		draw_colored_polygon(PackedVector2Array([
			Vector2(base_x, origin.y),
			Vector2(base_x + tooth_width * 0.72, origin.y - 18.0),
			Vector2(base_x + tooth_width, origin.y),
		]), Color("34251c"))
		draw_line(Vector2(base_x + tooth_width * 0.52, origin.y - 12.0), Vector2(base_x + tooth_width * 0.74, origin.y - 16.0), Color("d6bf8e"), 2.0)
	for index in range(3):
		draw_rect(Rect2(origin + Vector2(18 + index * 34, 26), Vector2(18, 28)), Color("d1ba8b"), true)
	draw_rect(Rect2(origin + Vector2(94, 34), Vector2(22, 44)), Color("271a13"), true)


func _draw_arcade_columns(rect: Rect2) -> void:
	for index in range(5):
		var x := rect.position.x + 28.0 + index * 62.0
		draw_rect(Rect2(x, rect.position.y + 18, 14, rect.size.y - 30), Color("d9c79d"), true)
		draw_rect(Rect2(x - 4, rect.position.y + 8, 22, 10), Color("b49764"), true)
		draw_rect(Rect2(x - 4, rect.position.y + rect.size.y - 12, 22, 10), Color("b49764"), true)


func _draw_planter(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(62, 20)), Color("7b5936"), true)
	draw_rect(Rect2(origin, Vector2(62, 20)), Color("462c1a"), false, 2.0)
	for index in range(3):
		var plant := origin + Vector2(14 + index * 16, 8 + sin(float(index)) * 2.0)
		draw_circle(plant, 9.0, Color("5b7343"))
		draw_circle(plant + Vector2(3, 3), 5.0, Color("6b874f"))


func _draw_bench(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(54, 8)), Color("755236"), true)
	draw_line(origin + Vector2(6, 8), origin + Vector2(6, 24), Color("4d301f"), 3.0)
	draw_line(origin + Vector2(48, 8), origin + Vector2(48, 24), Color("4d301f"), 3.0)


func _draw_window_glow(rect: Rect2) -> void:
	draw_rect(rect, Color("ead7a4"), true)
	var glow_alpha := lerpf(0.04, 0.18, 1.0 - light_level)
	draw_rect(rect.grow(6.0), Color(0.96, 0.85, 0.52, glow_alpha), true)


func _draw_ticker_board(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(138, 50)), Color("2d2118"), true)
	draw_rect(Rect2(pos + Vector2(10, 10), Vector2(118, 10)), Color("9a7f43"), true)
	draw_rect(Rect2(pos + Vector2(10, 28), Vector2(86, 8)), Color("7d6335"), true)


func _draw_clock_tower(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(54, 118)), Color("6f583e"), true)
	draw_rect(Rect2(pos + Vector2(-8, -18), Vector2(70, 18)), Color("432c1c"), true)
	draw_rect(Rect2(pos + Vector2(16, 70), Vector2(20, 48)), Color("2b1c14"), true)
	draw_circle(pos + Vector2(27, 34), 12.0, Color("dccb9b"))
	draw_line(pos + Vector2(27, 34), pos + Vector2(27, 26), Color("4a3522"), 2.0)
	draw_line(pos + Vector2(27, 34), pos + Vector2(35, 38), Color("4a3522"), 2.0)


func _draw_townhouse(pos: Vector2) -> void:
	_draw_building_plinth(Rect2(pos + Vector2(-12, 58), Vector2(112, 24)), Color("35261b"), Color("735a3e"))
	draw_rect(Rect2(pos, Vector2(88, 72)), Color("73583d"), true)
	draw_rect(Rect2(pos + Vector2(-6, -12), Vector2(100, 14)), Color("41291a"), true)
	draw_rect(Rect2(pos + Vector2(12, 20), Vector2(18, 20)), Color("d2bb90"), true)
	draw_rect(Rect2(pos + Vector2(58, 20), Vector2(18, 20)), Color("d2bb90"), true)
	draw_rect(Rect2(pos + Vector2(34, 36), Vector2(18, 36)), Color("2c1b12"), true)


func _draw_building_plinth(rect: Rect2, shadow_color: Color, top_color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 10), rect.size), Color(0, 0, 0, 0.18), true)
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(0, 4),
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size + Vector2(0, -3),
		rect.position + Vector2(6, rect.size.y)
	]), top_color)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 6), Vector2(rect.size.x, 8)), shadow_color, true)
	for stone in range(4):
		var x := rect.position.x + 10.0 + stone * (rect.size.x - 22.0) / 3.0
		draw_rect(Rect2(x, rect.position.y + 6.0 + float(stone % 2), 18, 6), Color(top_color.r, top_color.g, top_color.b, 0.24), true)


func _draw_hedge_row(origin: Vector2, count: int) -> void:
	for index in range(count):
		draw_circle(origin + Vector2(index * 42, 0), 18.0, Color("556b40"))


func _draw_lamp_post(pos: Vector2) -> void:
	draw_line(pos + Vector2(0, -18), pos + Vector2(0, 12), Color("3f2918"), 3.0)
	draw_circle(pos + Vector2(0, -18), 5.0, Color("b98b3d"))


func _draw_glow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in range(24):
		var angle := TAU * float(step) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_dirt_track(start_pos: Vector2, end_pos: Vector2, width: float, fill: Color, edge: Color) -> void:
	draw_line(start_pos, end_pos, fill, width)
	draw_line(start_pos, end_pos, edge, max(width * 0.12, 2.0))


func _draw_textured_river_band(points: PackedVector2Array, fill: Color, edge: Color) -> void:
	draw_colored_polygon(points, fill)
	for index in range(points.size()):
		var next_index := (index + 1) % points.size()
		draw_line(points[index], points[next_index], edge, 3.0)


func _draw_subregion_expansions() -> void:
	_draw_forest_farm_expansion()
	_draw_port_expansion()
	_draw_factory_expansion()
	_draw_exchange_expansion()


func _draw_forest_farm_expansion() -> void:
	_draw_meadow_patch(PackedVector2Array([
		Vector2(94, 118), Vector2(856, 136), Vector2(894, 572), Vector2(114, 612), Vector2(68, 306)
	]), Color("84a45d"))
	_draw_textured_river_band(PackedVector2Array([
		Vector2(164, 424), Vector2(238, 344), Vector2(352, 316), Vector2(448, 360), Vector2(504, 456),
		Vector2(472, 548), Vector2(336, 574), Vector2(210, 524)
	]), Color("8ad7ea"), Color("5da5b8"))
	_draw_forest_path(Vector2(404, 538), Vector2(618, 372), 24.0)
	_draw_forest_path(Vector2(618, 372), Vector2(774, 314), 28.0)
	_draw_giant_forest_tree(Vector2(168, 402), 1.34, Color("5b7c49"), true)
	_draw_giant_forest_tree(Vector2(296, 358), 1.18, Color("5d7f4b"), false)
	_draw_giant_forest_tree(Vector2(418, 340), 1.08, Color("5a7748"), false)
	_draw_forest_canopy_band(Rect2(84, 102, 520, 130), 8)
	_draw_forest_house_cluster(Vector2(626, 252))
	_draw_fenced_plot(Rect2(652, 260, 188, 142))
	_draw_crop_rows(Rect2(670, 292, 136, 74), Color("86bb4c"), Color("c98e56"), 4)
	_draw_mushroom_ring(Vector2(226, 488), 6)
	_draw_mushroom_ring(Vector2(384, 302), 4)
	_draw_glow_ellipse(Vector2(290, 416), Vector2(132, 44), Color(0.9, 0.98, 0.7, 0.08))
	_draw_glow_ellipse(Vector2(378, 358), Vector2(96, 34), Color(0.52, 0.78, 1.0, 0.06))


func _draw_port_expansion() -> void:
	_draw_meadow_patch(PackedVector2Array([
		Vector2(1302, 108), Vector2(1524, 118), Vector2(1514, 326), Vector2(1322, 362), Vector2(1278, 212)
	]), Color("8fb15f"))
	_draw_shipyard_slip(Rect2(1332, 154, 238, 188))
	_draw_crane_frame(Vector2(1558, 164), 104.0)
	_draw_ship_frame(Vector2(1434, 244), Vector2(174, 66), Color("7f5b39"))
	_draw_stone_quay(Rect2(1602, 164, 506, 256))
	_draw_textured_water_lane(Rect2(1654, 206, 452, 238))
	_draw_dock_finger(Vector2(1706, 206), Vector2(44, 138))
	_draw_dock_finger(Vector2(1842, 232), Vector2(48, 158))
	_draw_dock_finger(Vector2(1984, 262), Vector2(44, 172))
	_draw_dock_boat(Vector2(1758, 314), Vector2(126, 44), Color("7f5a38"))
	_draw_dock_boat(Vector2(1898, 358), Vector2(112, 40), Color("744f32"))
	_draw_dock_boat(Vector2(2026, 408), Vector2(118, 42), Color("815a36"))
	_draw_harbor_house_row(Vector2(1768, 138), [96.0, 108.0, 92.0, 118.0])
	_draw_crate_strip(Rect2(1624, 252, 152, 46), Color("8f6d46"))
	_draw_crate_strip(Rect2(1940, 296, 126, 42), Color("92744b"))
	_draw_stone_quay(Rect2(1496, 438, 476, 188))
	_draw_textured_water_lane(Rect2(1602, 458, 330, 130))
	_draw_bridge_arc(Vector2(1816, 530), Vector2(156, 72))
	_draw_harbor_house_row(Vector2(1518, 414), [132.0, 104.0, 84.0])
	_draw_dock_boat(Vector2(1694, 528), Vector2(114, 38), Color("785236"))
	_draw_dock_boat(Vector2(1886, 548), Vector2(112, 40), Color("6e4c31"))


func _draw_factory_expansion() -> void:
	_draw_meadow_patch(PackedVector2Array([
		Vector2(122, 846), Vector2(562, 854), Vector2(600, 1180), Vector2(128, 1216)
	]), Color("91ad61"))
	_draw_textured_river_band(PackedVector2Array([
		Vector2(434, 828), Vector2(536, 864), Vector2(548, 1182), Vector2(456, 1168), Vector2(414, 996)
	]), Color("84d5ee"), Color("5ba8be"))
	_draw_stone_quay(Rect2(184, 884, 262, 212))
	_draw_watermill_block(Vector2(194, 888))
	_draw_waterwheel(Vector2(462, 1022), 76.0)
	_draw_bridge_arc(Vector2(408, 1134), Vector2(118, 56))
	_draw_dirt_track(Vector2(284, 1146), Vector2(544, 1146), 26.0, Color("c59d63"), Color("926d3f"))
	_draw_stone_quay(Rect2(574, 930, 408, 242))
	_draw_stoneyard_camp(Rect2(610, 958, 346, 172))
	_draw_crate_strip(Rect2(650, 1038, 182, 58), Color("8b6741"))
	_draw_pipe_beam(Vector2(648, 1112), Vector2(922, 1112))


func _draw_exchange_expansion() -> void:
	_draw_market_square_block(Vector2(1380, 854))
	_draw_rune_tower_compound(Vector2(1838, 822))
	_draw_churchyard_block(Vector2(1730, 1128))


func _draw_scaled_texture(texture: Texture2D, pos: Vector2, size: Vector2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(pos, size), false, modulate)


func _draw_town_region(region: Rect2, pos: Vector2, scale: Vector2) -> void:
	if town_tileset == null:
		return
	draw_texture_rect_region(
		town_tileset,
		Rect2(pos, region.size * scale),
		region,
		Color.WHITE
	)


func _draw_textured_water_lane(rect: Rect2) -> void:
	draw_rect(rect, Color("5091ae"), true)
	for stripe in range(7):
		var y := rect.position.y + 18.0 + stripe * 22.0
		draw_line(Vector2(rect.position.x + 18.0, y), Vector2(rect.end.x - 24.0, y + 12.0), Color(0.88, 0.97, 1.0, 0.18), 2.0)


func _draw_stone_quay(rect: Rect2) -> void:
	draw_rect(rect, Color("cfbf9e"), true)
	for row in range(int(rect.size.y / 20.0)):
		var y := rect.position.y + row * 20.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("b8a783"), 1.0)
	for col in range(int(rect.size.x / 34.0)):
		var x := rect.position.x + col * 34.0 + (12.0 if col % 2 == 0 else 0.0)
		draw_line(Vector2(x, rect.position.y), Vector2(x - 10.0, rect.end.y), Color(0.42, 0.35, 0.26, 0.12), 1.0)


func _draw_dock_plaza(rect: Rect2) -> void:
	draw_rect(rect, Color("d6c7a7"), true)
	for plank in range(10):
		var y := rect.position.y + 12.0 + plank * 14.0
		draw_line(Vector2(rect.position.x + 14.0, y), Vector2(rect.end.x - 18.0, y + sin(float(plank)) * 2.0), Color("8a6442"), 2.0)


func _draw_dock_boat(center: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-size.x * 0.5, 0),
		center + Vector2(-size.x * 0.2, -size.y * 0.5),
		center + Vector2(size.x * 0.32, -size.y * 0.42),
		center + Vector2(size.x * 0.5, 0),
		center + Vector2(size.x * 0.3, size.y * 0.42),
		center + Vector2(-size.x * 0.3, size.y * 0.38),
	])
	draw_colored_polygon(points, color)
	draw_line(center + Vector2(-size.x * 0.34, 0), center + Vector2(size.x * 0.34, 0), Color("3f2919"), 2.0)


func _draw_bridge_arc(center: Vector2, size: Vector2) -> void:
	var rect := Rect2(center - size * 0.5, size)
	draw_arc(center, size.x * 0.5, PI, TAU, 18, Color("bfae8e"), 8.0)
	draw_rect(Rect2(rect.position.x, center.y - 8.0, size.x, 16.0), Color("cab998"), true)


func _draw_crate_strip(rect: Rect2, color: Color) -> void:
	for row in range(2):
		for col in range(int(rect.size.x / 40.0)):
			var pos := rect.position + Vector2(col * 34.0, row * 22.0)
			draw_rect(Rect2(pos, Vector2(26, 18)), color, true)
			draw_rect(Rect2(pos, Vector2(26, 18)), Color("5a3e29"), false, 1.0)


func _draw_fenced_plot(rect: Rect2) -> void:
	draw_rect(rect, Color(0.32, 0.24, 0.16, 0.08), true)
	for index in range(int(rect.size.x / 24.0) + 1):
		var x := rect.position.x + index * 24.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + 12.0), Color("7a5634"), 2.0)
		draw_line(Vector2(x, rect.end.y), Vector2(x, rect.end.y - 12.0), Color("7a5634"), 2.0)
	for index in range(int(rect.size.y / 24.0) + 1):
		var y := rect.position.y + index * 24.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + 12.0, y), Color("7a5634"), 2.0)
		draw_line(Vector2(rect.end.x, y), Vector2(rect.end.x - 12.0, y), Color("7a5634"), 2.0)


func _draw_crop_rows(rect: Rect2, leaf_color: Color, root_color: Color, count: int) -> void:
	for row in range(count):
		for col in range(5):
			var center := rect.position + Vector2(18 + col * 28.0 + float(row % 2) * 8.0, 16 + row * 14.0)
			draw_line(center, center + Vector2(0, -12), leaf_color, 3.0)
			draw_line(center, center + Vector2(-6, -8), leaf_color.darkened(0.12), 2.0)
			draw_line(center, center + Vector2(6, -9), leaf_color.lightened(0.08), 2.0)
			draw_circle(center + Vector2(0, 3), 3.0, root_color)


func _draw_tree_line(origin: Vector2, count: int, spacing: float, trunk_color: Color, crown_color: Color) -> void:
	for index in range(count):
		var root := origin + Vector2(index * spacing, sin(float(index) * 0.8) * 10.0)
		draw_rect(Rect2(root.x - 10.0, root.y, 20.0, 56.0), trunk_color, true)
		draw_circle(root + Vector2(0, -10), 34.0, crown_color)
		draw_circle(root + Vector2(-22, -8), 22.0, crown_color.lightened(0.08))
		draw_circle(root + Vector2(24, -12), 20.0, crown_color.darkened(0.06))
		draw_circle(root + Vector2(0, 54), 18.0, Color(0, 0, 0, 0.08))


func _draw_waterwheel(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color("5d4430"))
	draw_circle(center, radius - 12.0, Color("7a5b3d"))
	for spoke in range(8):
		var angle := TAU * float(spoke) / 8.0
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * (radius - 8.0), Color("342217"), 4.0)


func _draw_factory_court(rect: Rect2) -> void:
	draw_rect(rect, Color("8b7a5d"), true)
	for plank in range(8):
		var x := rect.position.x + plank * 42.0
		draw_line(Vector2(x, rect.position.y), Vector2(x + 24.0, rect.end.y), Color(0, 0, 0, 0.09), 2.0)


func _draw_pipe_beam(start_pos: Vector2, end_pos: Vector2) -> void:
	draw_line(start_pos, end_pos, Color("5f4e3f"), 10.0)
	draw_line(start_pos, end_pos, Color("8c775f"), 4.0)


func _draw_market_court(rect: Rect2) -> void:
	draw_rect(rect, Color("d8caac"), true)
	for row in range(5):
		for col in range(8):
			var tile := Rect2(rect.position + Vector2(col * 36.0, row * 28.0), Vector2(30.0, 22.0))
			draw_rect(tile, Color("ccb78f").lightened(float((row + col) % 2) * 0.04), true)


func _draw_market_canopy_row(origin: Vector2, count: int) -> void:
	var canopy_colors := [Color("b24739"), Color("d9c54b"), Color("3f7ca9"), Color("a84f36")]
	for index in range(count):
		var pos := origin + Vector2(index * 68.0, 0)
		draw_rect(Rect2(pos, Vector2(44, 26)), canopy_colors[index % canopy_colors.size()], true)
		draw_line(pos + Vector2(0, 0), pos + Vector2(44, 26), Color(1, 1, 1, 0.4), 2.0)
		draw_line(pos + Vector2(44, 0), pos + Vector2(0, 26), Color(1, 1, 1, 0.28), 2.0)
		draw_line(pos + Vector2(5, 26), pos + Vector2(5, 56), Color("604129"), 3.0)
		draw_line(pos + Vector2(39, 26), pos + Vector2(39, 56), Color("604129"), 3.0)


func _draw_grave_row(origin: Vector2, count: int) -> void:
	for index in range(count):
		var pos := origin + Vector2(index * 82.0, 0)
		draw_rect(Rect2(pos, Vector2(28, 38)), Color("b8b7b3"), true)
		draw_arc(pos + Vector2(14, 0), 14.0, PI, TAU, 10, Color("b8b7b3"), 28.0)
		draw_circle(pos + Vector2(14, 40), 18.0, Color(0, 0, 0, 0.08))


func _draw_forest_path(start_pos: Vector2, end_pos: Vector2, width: float) -> void:
	_draw_dirt_track(start_pos, end_pos, width, Color("c9a266"), Color("8d6940"))


func _draw_giant_forest_tree(root: Vector2, scale: float, crown_color: Color, glowing: bool) -> void:
	var trunk_rect := Rect2(root.x - 26.0 * scale, root.y - 104.0 * scale, 52.0 * scale, 118.0 * scale)
	draw_rect(trunk_rect, Color("6a472b"), true)
	draw_rect(Rect2(root.x - 10.0 * scale, root.y - 34.0 * scale, 20.0 * scale, 52.0 * scale), Color("7e5635"), true)
	draw_circle(root + Vector2(-48.0, -96.0) * scale, 52.0 * scale, crown_color)
	draw_circle(root + Vector2(0, -114.0) * scale, 60.0 * scale, crown_color.lightened(0.06))
	draw_circle(root + Vector2(52.0, -90.0) * scale, 48.0 * scale, crown_color.darkened(0.08))
	draw_circle(root + Vector2(-18.0, -52.0) * scale, 42.0 * scale, crown_color.darkened(0.12))
	draw_circle(root + Vector2(24.0, -46.0) * scale, 44.0 * scale, crown_color.lightened(0.04))
	draw_colored_polygon(PackedVector2Array([
		root + Vector2(-18.0, 0) * scale,
		root + Vector2(-60.0, 30.0) * scale,
		root + Vector2(-34.0, 8.0) * scale
	]), Color("69492d"))
	draw_colored_polygon(PackedVector2Array([
		root + Vector2(18.0, -4.0) * scale,
		root + Vector2(66.0, 28.0) * scale,
		root + Vector2(30.0, 10.0) * scale
	]), Color("69492d"))
	_draw_mushroom_ring(root + Vector2(-12.0, 18.0) * scale, 4)
	if glowing:
		_draw_glow_ellipse(root + Vector2(0, 8.0) * scale, Vector2(78, 24) * scale, Color(0.98, 0.96, 0.72, 0.1))


func _draw_forest_canopy_band(rect: Rect2, count: int) -> void:
	for index in range(count):
		var center := rect.position + Vector2(48 + index * rect.size.x / max(count - 1, 1), 26 + sin(float(index) * 0.7) * 10.0)
		draw_circle(center, 56.0, Color("5c7a45"))
		draw_circle(center + Vector2(-34, 2), 34.0, Color("678551"))
		draw_circle(center + Vector2(36, 6), 32.0, Color("53703f"))


func _draw_forest_house_cluster(origin: Vector2) -> void:
	_draw_dirt_path(PackedVector2Array([
		origin + Vector2(136, 220),
		origin + Vector2(186, 200),
		origin + Vector2(246, 206),
		origin + Vector2(318, 234)
	]), 26.0)
	draw_rect(Rect2(origin.x + 92.0, origin.y + 188.0, 242.0, 16.0), Color(0, 0, 0, 0.12), true)
	_draw_scaled_texture(medieval_house_texture, origin + Vector2(74, 38), Vector2(220, 196))
	_draw_scaled_texture(medieval_hut_texture, origin + Vector2(222, 56), Vector2(158, 158))
	_draw_scaled_texture(medieval_hut_texture, origin + Vector2(98, 74), Vector2(120, 118))
	_draw_scaled_texture(medieval_well_texture, origin + Vector2(8, 146), Vector2(96, 96))
	_draw_scaled_texture(medieval_barrel_texture, origin + Vector2(314, 168), Vector2(46, 46))
	_draw_scaled_texture(medieval_crate_texture, origin + Vector2(276, 180), Vector2(44, 44))
	_draw_town_region(Rect2(126, 206, 36, 38), origin + Vector2(154, 184), Vector2(2.0, 2.0))
	_draw_town_region(Rect2(214, 204, 56, 40), origin + Vector2(286, 190), Vector2(1.8, 1.8))
	_draw_field_gate(origin + Vector2(56, 168), Color("9c7446"), Color("5d3d26"))
	_draw_bucket_row(origin + Vector2(118, 198), 2)
	_draw_shrub_cluster(origin + Vector2(30, 202), 5, Color("5d8446"), Color("89af64"))
	_draw_shrub_cluster(origin + Vector2(330, 216), 4, Color("55733f"), Color("7f9f58"))


func _draw_mushroom_ring(center: Vector2, count: int) -> void:
	for index in range(count):
		var angle: float = TAU * float(index) / maxf(float(count), 1.0)
		var pos := center + Vector2(cos(angle) * 20.0, sin(angle) * 8.0)
		draw_circle(pos + Vector2(0, 4), 6.0, Color("f1c85b"))
		draw_rect(Rect2(pos.x - 2.0, pos.y + 4.0, 4.0, 10.0), Color("decfad"), true)


func _draw_shipyard_slip(rect: Rect2) -> void:
	draw_rect(rect, Color("86aa58"), true)
	for index in range(8):
		var x := rect.position.x + 18.0 + index * 24.0
		draw_line(Vector2(x, rect.position.y + 28.0), Vector2(x + 10.0, rect.end.y - 18.0), Color("6b4d2f"), 3.0)
	for beam in range(5):
		var y := rect.position.y + 26.0 + beam * 30.0
		draw_line(Vector2(rect.position.x + 8.0, y), Vector2(rect.end.x - 12.0, y + 6.0), Color("4f341f"), 2.0)
	for prop in range(3):
		var pos := rect.position + Vector2(22.0 + prop * 56.0, rect.end.y - 34.0 + float(prop % 2) * 6.0)
		draw_rect(Rect2(pos, Vector2(30, 12)), Color("8a6540"), true)
		draw_line(pos + Vector2(0, 0), pos + Vector2(30, 12), Color("5a3b24"), 1.2)


func _draw_crane_frame(pos: Vector2, height: float) -> void:
	draw_line(pos, pos + Vector2(0, height), Color("6d4a2c"), 5.0)
	draw_line(pos, pos + Vector2(76, 0), Color("6d4a2c"), 5.0)
	draw_line(pos + Vector2(76, 0), pos + Vector2(76, 38), Color("6d4a2c"), 4.0)
	draw_circle(pos + Vector2(76, 40), 6.0, Color("3e2718"))


func _draw_ship_frame(center: Vector2, size: Vector2, color: Color) -> void:
	_draw_dock_boat(center, size, color)
	for rib in range(5):
		var offset := -size.x * 0.28 + rib * size.x * 0.14
		draw_line(center + Vector2(offset, -size.y * 0.36), center + Vector2(offset, size.y * 0.32), Color("4a2f1c"), 2.0)
	draw_line(center + Vector2(-size.x * 0.18, -size.y * 0.64), center + Vector2(-size.x * 0.18, -size.y * 0.08), Color("4f331e"), 4.0)


func _draw_dock_finger(pos: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(pos, size), Color("86613d"), true)
	for index in range(3):
		var x := pos.x + 8.0 + index * (size.x - 16.0) / 2.0
		draw_rect(Rect2(x, pos.y + size.y - 10.0, 8.0, 22.0), Color("5e4128"), true)


func _draw_harbor_house_row(origin: Vector2, widths: Array) -> void:
	var x := origin.x
	for index in range(widths.size()):
		var width_value = widths[index]
		var width := float(width_value)
		var pos := Vector2(x, origin.y)
		var size := Vector2(width, 152)
		draw_rect(Rect2(pos.x + 6.0, pos.y + 120.0, width - 4.0, 30.0), Color("9d8b73"), true)
		draw_rect(Rect2(pos.x, pos.y + 122.0, width, 30.0), Color(0, 0, 0, 0.08), true)
		if index % 3 == 0:
			_draw_scaled_texture(medieval_roof_house_texture, pos + Vector2(0, -6), size + Vector2(0, 6))
		elif index % 3 == 1:
			_draw_scaled_texture(medieval_house_texture, pos, size)
		else:
			_draw_scaled_texture(medieval_roof_hut_texture, pos + Vector2(0, 4), Vector2(width, 144))
		if town_tileset != null:
			if index % 2 == 0:
				_draw_town_region(Rect2(126, 206, 36, 38), pos + Vector2(width * 0.2, 100), Vector2(1.1, 1.1))
			else:
				_draw_town_region(Rect2(214, 204, 56, 40), pos + Vector2(width * 0.12, 96), Vector2(0.9, 0.9))
		draw_rect(Rect2(pos.x + width * 0.38, pos.y + 98.0, 22.0, 50.0), Color("4b3020"), true)
		draw_rect(Rect2(pos.x + 18.0, pos.y + 96.0, 20.0, 18.0), Color("cbd6da"), true)
		draw_rect(Rect2(pos.x + width - 40.0, pos.y + 90.0, 18.0, 18.0), Color("cbd6da"), true)
		draw_line(pos + Vector2(16, 112), pos + Vector2(width - 16.0, 112), Color(0, 0, 0, 0.08), 1.4)
		if index == 0:
			_draw_scaled_texture(medieval_sign_texture, pos + Vector2(width - 24.0, 88), Vector2(30, 30))
		elif index == widths.size() - 1:
			_draw_scaled_texture(medieval_barrel_texture, pos + Vector2(width - 30.0, 120), Vector2(30, 30))
		x += width - 14.0


func _draw_watermill_block(origin: Vector2) -> void:
	draw_rect(Rect2(origin.x + 14.0, origin.y + 146.0, 252.0, 20.0), Color(0, 0, 0, 0.1), true)
	_draw_scaled_texture(medieval_roof_house_texture, origin + Vector2(0, 6), Vector2(188, 176))
	_draw_scaled_texture(medieval_roof_hut_texture, origin + Vector2(146, 42), Vector2(118, 122))
	draw_rect(Rect2(origin.x + 122.0, origin.y + 44.0, 92.0, 138.0), Color("897e6f"), true)
	draw_rect(Rect2(origin.x + 126.0, origin.y + 50.0, 84.0, 128.0), Color("c1b59d"), false, 2.0)
	draw_rect(Rect2(origin.x + 168.0, origin.y + 104.0, 26.0, 74.0), Color("4a3020"), true)
	draw_rect(Rect2(origin.x + 18.0, origin.y + 112.0, 22.0, 18.0), Color("d4e0e2"), true)
	draw_rect(Rect2(origin.x + 64.0, origin.y + 92.0, 22.0, 18.0), Color("d4e0e2"), true)
	_draw_town_region(Rect2(214, 204, 56, 40), origin + Vector2(16, 156), Vector2(1.0, 1.0))
	_draw_scaled_texture(medieval_barrel_texture, origin + Vector2(92, 154), Vector2(34, 34))
	_draw_scaled_texture(medieval_crate_texture, origin + Vector2(126, 152), Vector2(34, 34))
	_draw_bucket_row(origin + Vector2(172, 154), 2)


func _draw_stoneyard_camp(rect: Rect2) -> void:
	draw_rect(rect, Color("d0c4a6"), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 84.0)), Color("8c7552"), true)
	_draw_stone_wall_loop(Rect2(rect.position + Vector2(-16, -18), rect.size + Vector2(32, 36)))
	_draw_canvas_tent(rect.position + Vector2(204, -10))
	_draw_hanging_rack(rect.position + Vector2(276, 34))
	_draw_fire_pit(rect.position + Vector2(236, 86))


func _draw_stone_wall_loop(rect: Rect2) -> void:
	for index in range(int(rect.size.x / 34.0)):
		var x := rect.position.x + index * 34.0
		draw_rect(Rect2(x, rect.position.y, 28.0, 22.0), Color("bda885"), true)
		draw_rect(Rect2(x, rect.end.y - 22.0, 28.0, 22.0), Color("bda885"), true)
	for index in range(int(rect.size.y / 32.0)):
		var y := rect.position.y + index * 32.0
		draw_rect(Rect2(rect.position.x, y, 20.0, 28.0), Color("bda885"), true)
		draw_rect(Rect2(rect.end.x - 20.0, y, 20.0, 28.0), Color("bda885"), true)


func _draw_canvas_tent(pos: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, 54), pos + Vector2(46, 0), pos + Vector2(92, 54)
	]), Color("d6c487"))
	draw_line(pos + Vector2(46, 0), pos + Vector2(46, 54), Color("674927"), 3.0)


func _draw_hanging_rack(pos: Vector2) -> void:
	draw_line(pos, pos + Vector2(0, 54), Color("5c3f27"), 4.0)
	draw_line(pos + Vector2(54, 0), pos + Vector2(54, 54), Color("5c3f27"), 4.0)
	draw_line(pos, pos + Vector2(54, 0), Color("5c3f27"), 4.0)
	draw_circle(pos + Vector2(44, 34), 6.0, Color("7f4a34"))


func _draw_fire_pit(center: Vector2) -> void:
	draw_circle(center, 22.0, Color("9f8f72"))
	draw_circle(center, 14.0, Color("6d4d33"))
	draw_circle(center + Vector2(0, -4), 8.0, Color("ef9a45"))


func _draw_market_square_block(origin: Vector2) -> void:
	_draw_stone_quay(Rect2(origin.x, origin.y + 40, 466, 294))
	_draw_market_court(Rect2(origin.x + 56, origin.y + 108, 320, 144))
	_draw_harbor_house_row(origin + Vector2(0, 18), [114.0, 102.0, 120.0])
	_draw_clocktower_gate(origin + Vector2(240, 0))
	_draw_harbor_house_row(origin + Vector2(330, 36), [116.0, 104.0])
	_draw_harbor_house_row(origin + Vector2(22, 238), [112.0, 116.0, 106.0])
	_draw_market_canopy_row(origin + Vector2(96, 154), 4)
	_draw_side_arcade(origin + Vector2(36, 90), 4, Color("9b917e"), Color("84563a"))
	_draw_stall_counter(origin + Vector2(92, 282), 6, Color("8a633d"))
	_draw_stall_counter(origin + Vector2(286, 286), 4, Color("8a633d"))
	_draw_bucket_row(origin + Vector2(66, 292), 3)
	_draw_clutter_bundle(origin + Vector2(394, 286), 3)
	_draw_flag_row(origin + Vector2(78, 128), 5, Color("d45b44"), Color("f0cf64"))


func _draw_clocktower_gate(origin: Vector2) -> void:
	draw_rect(Rect2(origin.x, origin.y + 8.0, 82.0, 148.0), Color("978c79"), true)
	draw_rect(Rect2(origin.x + 10.0, origin.y + 18.0, 62.0, 128.0), Color("d0c3a7"), true)
	draw_rect(Rect2(origin.x + 18.0, origin.y + 76.0, 46.0, 70.0), Color("3a2718"), true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(6, 16),
		origin + Vector2(41, -18),
		origin + Vector2(76, 16)
	]), Color("8a4a35"))
	draw_circle(origin + Vector2(41, 44), 18.0, Color("f1e1b4"))
	draw_circle(origin + Vector2(41, 44), 14.0, Color("d5c08d"))
	draw_line(origin + Vector2(41, 44), origin + Vector2(41, 30), Color("5d4330"), 3.0)
	draw_line(origin + Vector2(41, 44), origin + Vector2(51, 44), Color("5d4330"), 3.0)
	draw_rect(Rect2(origin.x + 28.0, origin.y + 18.0, 26.0, 14.0), Color("5b4635"), true)


func _draw_rune_tower_compound(origin: Vector2) -> void:
	_draw_scaled_texture(medieval_hut_texture, origin + Vector2(10, 138), Vector2(138, 126))
	_draw_scaled_texture(medieval_castle_texture, origin + Vector2(110, -6), Vector2(258, 274))
	draw_rect(Rect2(origin.x + 138.0, origin.y + 34.0, 216.0, 228.0), Color(0.12, 0.1, 0.18, 0.26), false, 2.0)
	_draw_glow_ellipse(origin + Vector2(236, 6), Vector2(36, 18), Color(0.42, 0.72, 1.0, 0.22))
	var rune_colors := [Color("f2cb43"), Color("45d4ff"), Color("e64d79"), Color("80dc59")]
	for idx in range(8):
		var pos := origin + Vector2(154 + float(idx % 4) * 42.0, 108 + float(idx / 4) * 46.0)
		draw_line(pos, pos + Vector2(10, -12), rune_colors[idx % rune_colors.size()], 2.0)
		draw_line(pos + Vector2(10, -12), pos + Vector2(18, 4), rune_colors[idx % rune_colors.size()], 2.0)
	_draw_stone_quay(Rect2(origin.x + 118.0, origin.y + 236.0, 182.0, 40.0))
	_draw_clutter_bundle(origin + Vector2(18, 224), 3)
	_draw_scaled_texture(medieval_barrel_texture, origin + Vector2(84, 226), Vector2(28, 28))


func _draw_churchyard_block(origin: Vector2) -> void:
	_draw_church(origin + Vector2(70, 12))
	_draw_graveyard_fence(Rect2(origin.x + 10.0, origin.y + 52.0, 356.0, 214.0))
	_draw_grave_row(origin + Vector2(28, 184), 4)
	_draw_grave_row(origin + Vector2(202, 184), 3)
	_draw_grave_row(origin + Vector2(24, 246), 4)
	_draw_grave_row(origin + Vector2(236, 246), 2)
	_draw_tree_line(Vector2(origin.x + 34.0, origin.y + 38.0), 4, 86.0, Color("4a3323"), Color("60804b"))


func _draw_church(origin: Vector2) -> void:
	draw_rect(Rect2(origin.x + 46.0, origin.y + 202.0, 220.0, 14.0), Color(0, 0, 0, 0.1), true)
	draw_rect(Rect2(origin.x + 40.0, origin.y + 40.0, 224.0, 164.0), Color("d7ccb7"), true)
	draw_rect(Rect2(origin.x, origin.y + 18.0, 64.0, 186.0), Color("c1b49c"), true)
	draw_rect(Rect2(origin.x + 220.0, origin.y + 22.0, 64.0, 182.0), Color("c1b49c"), true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(28, 44), origin + Vector2(142, -8), origin + Vector2(256, 44)
	]), Color("8a4a35"))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-6, 28), origin + Vector2(34, -36), origin + Vector2(74, 28)
	]), Color("8a4a35"))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(214, 28), origin + Vector2(252, -28), origin + Vector2(292, 28)
	]), Color("8a4a35"))
	draw_circle(origin + Vector2(150, 100), 36.0, Color("8d5b87"))
	draw_circle(origin + Vector2(150, 100), 28.0, Color("dba87a"))
	for petal in range(8):
		var angle := TAU * float(petal) / 8.0
		draw_circle(origin + Vector2(150, 100) + Vector2(cos(angle), sin(angle)) * 18.0, 6.0, Color("7d8fd8") if petal % 2 == 0 else Color("d77063"))
	draw_rect(Rect2(origin.x + 130.0, origin.y + 146.0, 44.0, 58.0), Color("4a3020"), true)
	draw_rect(Rect2(origin.x + 18.0, origin.y + 84.0, 16.0, 44.0), Color("44516c"), true)
	draw_rect(Rect2(origin.x + 246.0, origin.y + 84.0, 16.0, 44.0), Color("44516c"), true)
	_draw_dirt_path(PackedVector2Array([
		origin + Vector2(152, 204),
		origin + Vector2(148, 236),
		origin + Vector2(154, 272)
	]), 32.0)


func _draw_graveyard_fence(rect: Rect2) -> void:
	for index in range(int(rect.size.x / 32.0) + 1):
		var x := rect.position.x + index * 32.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + 18.0), Color("7a5737"), 3.0)
		draw_line(Vector2(x, rect.end.y), Vector2(x, rect.end.y - 18.0), Color("7a5737"), 3.0)
	for index in range(int(rect.size.y / 28.0) + 1):
		var y := rect.position.y + index * 28.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + 16.0, y), Color("7a5737"), 3.0)
		draw_line(Vector2(rect.end.x, y), Vector2(rect.end.x - 16.0, y), Color("7a5737"), 3.0)


func _district_color(name: String) -> Color:
	var base_color := Color("4f3a2a")
	match name:
		"贫民街":
			base_color = Color("3a2a1f")
		"港口":
			base_color = Color("234252")
		"工厂区":
			base_color = Color("35281f")
		"交易所":
			base_color = Color("4b3a28")
	var state := str(district_states.get(name, "normal"))
	match state:
		"tense":
			return base_color.darkened(0.08)
		"prosperous":
			return base_color.lightened(0.08)
		"unrest":
			return base_color.darkened(0.16)
		"declining":
			return base_color.darkened(0.22)
	return base_color
