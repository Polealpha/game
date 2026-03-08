extends Node2D
class_name InteractableView

const REDRAW_INTERVAL := 0.08

var interaction_id := ""
var kind := ""
var title := ""
var district := ""
var subtitle := ""
var is_highlighted := false
var pulse_time := 0.0
var focus_strength := 0.0
var redraw_timer := 0.0

var title_label := Label.new()
var subtitle_label := Label.new()


func _ready() -> void:
	title_label.position = Vector2(-56, 26)
	title_label.size = Vector2(120, 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("f6e7c1"))
	title_label.visible = false
	add_child(title_label)

	subtitle_label.position = Vector2(-70, 42)
	subtitle_label.size = Vector2(140, 20)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override("font_color", Color("dcc89d"))
	subtitle_label.visible = false
	add_child(subtitle_label)
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta
	redraw_timer += delta
	if is_highlighted or focus_strength > 0.2 or redraw_timer >= REDRAW_INTERVAL:
		redraw_timer = 0.0
		queue_redraw()


func configure(data: Dictionary) -> void:
	interaction_id = str(data.get("id", ""))
	kind = str(data.get("kind", ""))
	title = str(data.get("title", ""))
	district = str(data.get("district", ""))
	subtitle = str(data.get("subtitle", ""))
	position = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	if is_instance_valid(title_label):
		title_label.text = title
	if is_instance_valid(subtitle_label):
		subtitle_label.text = subtitle
	queue_redraw()


func set_highlighted(value: bool) -> void:
	if is_highlighted == value:
		return
	is_highlighted = value
	title_label.visible = value
	subtitle_label.visible = value
	queue_redraw()


func set_focus_strength(value: float) -> void:
	var next_focus := clampf(value, 0.0, 1.0)
	if is_equal_approx(focus_strength, next_focus):
		return
	focus_strength = next_focus
	queue_redraw()


func _draw() -> void:
	var visual_focus := maxf(focus_strength, 1.0 if is_highlighted else 0.0)
	var halo_radius := 16.0 + visual_focus * 9.0 + (2.0 * sin(pulse_time * 2.4) if is_highlighted else 0.0)
	var halo_alpha := 0.02 + visual_focus * (0.26 if is_highlighted else 0.08)
	var ring_color := Color("4c3120")
	ring_color.a = 0.55 + visual_focus * 0.45
	draw_circle(Vector2.ZERO, halo_radius, Color(0.96, 0.88, 0.62, halo_alpha))
	draw_circle(Vector2.ZERO, 12.0 + visual_focus * 6.0, ring_color)
	draw_circle(Vector2.ZERO, 8.0 + visual_focus * 5.0, _kind_color().lerp(Color.WHITE, visual_focus * 0.08))
	draw_circle(Vector2.ZERO, 3.0 + visual_focus * 2.0, Color("f6dfb0"))
	if is_highlighted:
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color("f4dc9d"), 2.0)
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48, Color(0.98, 0.9, 0.7, 0.22), 2.0)
	_draw_icon()


func _draw_icon() -> void:
	match kind:
		"work":
			draw_line(Vector2(-7, -4), Vector2(4, 8), Color("49311d"), 2.5)
			draw_line(Vector2(0, -8), Vector2(8, 0), Color("49311d"), 2.5)
		"goods":
			draw_rect(Rect2(Vector2(-7, -6), Vector2(14, 10)), Color("7b5832"), true)
			draw_line(Vector2(-8, -7), Vector2(8, -7), Color("49311d"), 2.0)
		"stocks":
			draw_line(Vector2(-8, 6), Vector2(-2, 0), Color("385f3b"), 2.0)
			draw_line(Vector2(-2, 0), Vector2(2, 2), Color("385f3b"), 2.0)
			draw_line(Vector2(2, 2), Vector2(8, -6), Color("385f3b"), 2.0)
		"info":
			draw_circle(Vector2(0, -2), 4.0, Color("5d3d7f"))
			draw_rect(Rect2(Vector2(-2, 2), Vector2(4, 8)), Color("5d3d7f"), true)
		"tasks":
			draw_rect(Rect2(Vector2(-7, -8), Vector2(14, 16)), Color("f3dfb0"), true)
			draw_line(Vector2(-4, -2), Vector2(4, -2), Color("8f2f33"), 1.8)
			draw_line(Vector2(-4, 2), Vector2(4, 2), Color("8f2f33"), 1.8)
		"end_day":
			draw_circle(Vector2.ZERO, 6.0, Color("b98b3f"))
			draw_line(Vector2(0, 0), Vector2(0, -4), Color("49311d"), 2.0)
			draw_line(Vector2(0, 0), Vector2(4, 0), Color("49311d"), 2.0)
		"house":
			draw_rect(Rect2(Vector2(-8, -1), Vector2(16, 10)), Color("7f5d3a"), true)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-10, -1),
				Vector2(0, -10),
				Vector2(10, -1)
			]), Color("9e7550"))
			draw_rect(Rect2(Vector2(-2, 2), Vector2(4, 7)), Color("3e2819"), true)
		"bed":
			draw_rect(Rect2(Vector2(-8, -2), Vector2(16, 8)), Color("d8c9a6"), true)
			draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 4)), Color("8f3f35"), true)
			draw_line(Vector2(-8, 6), Vector2(-8, -6), Color("49311d"), 1.8)
			draw_line(Vector2(8, 6), Vector2(8, -6), Color("49311d"), 1.8)
		"kitchen":
			draw_circle(Vector2(0, 0), 5.0, Color("352216"))
			draw_arc(Vector2(0, 0), 5.0, PI, TAU, 12, Color("d7aa58"), 2.0)
			draw_line(Vector2(-6, 6), Vector2(6, 6), Color("8b6135"), 2.0)
			draw_circle(Vector2(0, 2), 2.2, Color("f1c76f"))
		"storage":
			draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 12)), Color("855c36"), true)
			draw_line(Vector2(-8, 0), Vector2(8, 0), Color("d7b379"), 1.6)
			draw_circle(Vector2(0, 0), 2.0, Color("d7b379"))
		"desk":
			draw_rect(Rect2(Vector2(-8, -2), Vector2(16, 8)), Color("815734"), true)
			draw_rect(Rect2(Vector2(-5, -8), Vector2(10, 6)), Color("f0dfb5"), true)
			draw_line(Vector2(-3, -5), Vector2(3, -5), Color("8f2f33"), 1.2)
		"exit_house":
			draw_rect(Rect2(Vector2(-6, -8), Vector2(12, 16)), Color("5f3e27"), true)
			draw_line(Vector2(-6, -8), Vector2(6, -8), Color("c7a26a"), 1.6)
			draw_circle(Vector2(2, 1), 1.6, Color("d8bb81"))


func _kind_color() -> Color:
	match kind:
		"work":
			return Color("c18333")
		"goods":
			return Color("cba45d")
		"stocks":
			return Color("6f8c4d")
		"info":
			return Color("8d67ac")
		"tasks":
			return Color("b25b51")
		"end_day":
			return Color("d3bc7c")
		"house":
			return Color("a97c4d")
		"bed":
			return Color("b98c68")
		"kitchen":
			return Color("b46f3d")
		"storage":
			return Color("9f744a")
		"desk":
			return Color("91714f")
		"exit_house":
			return Color("866042")
	return Color("b18a57")
