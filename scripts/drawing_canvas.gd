class_name DrawingCanvas
extends Control

signal drawing_changed
signal text_placement_requested(position: Vector2)

const WIDTH := 840
const HEIGHT := 520
const MAX_UNDO := 12
const FILL_TOLERANCE := 0.055
const OUTLINE_DARKNESS_THRESHOLD := 0.5

var base_image: Image
var outline_mask: Image
var artwork: Image
var fill_image: Image
var artwork_texture: ImageTexture
var history: Array[Dictionary] = []
var tool := "brush"
var stamp := "paw"
var brush_color := Color("#1857a4")
var brush_size := 18.0
var glitter := false
var drawing := false
var touch_index := -1
var last_point := Vector2.ZERO
var text_image: Image
var zoom_factor := 1.0
var zoom_center := Vector2(WIDTH / 2.0, HEIGHT / 2.0)
var zoom_dragging := false
var zoom_moved := false
var zoom_last_position := Vector2.ZERO
var zoom_start_position := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	set_page(null)

func set_page(texture: Texture2D) -> void:
	base_image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	base_image.fill(Color.WHITE)
	if texture:
		var source: Image = texture.get_image()
		if source == null or source.is_empty():
			push_error("Could not read the selected page image.")
		else:
			source.convert(Image.FORMAT_RGBA8)
			var scale_factor: float = minf(float(WIDTH) / source.get_width(), float(HEIGHT) / source.get_height())
			var target := Vector2i(maxi(1, int(source.get_width() * scale_factor)), maxi(1, int(source.get_height() * scale_factor)))
			source.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
			base_image.blend_rect(source, Rect2i(Vector2i.ZERO, target), Vector2i((WIDTH - target.x) / 2, (HEIGHT - target.y) / 2))
	outline_mask = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_L8)
	outline_mask.fill(Color.BLACK)
	if texture:
		for y in range(HEIGHT):
			for x in range(WIDTH):
				if base_image.get_pixel(x, y).get_luminance() < OUTLINE_DARKNESS_THRESHOLD:
					outline_mask.set_pixel(x, y, Color.WHITE)
	artwork = base_image.duplicate()
	fill_image = base_image.duplicate()
	history.clear()
	drawing = false
	touch_index = -1
	zoom_dragging = false
	zoom_factor = 1.0
	zoom_center = Vector2(WIDTH / 2.0, HEIGHT / 2.0)
	_refresh()
	drawing_changed.emit()

func set_tool(value: String) -> void:
	tool = value

func set_stamp(value: String) -> void:
	stamp = value

func set_color(value: Color) -> void:
	brush_color = value

func set_brush_size(value: float) -> void:
	brush_size = value

func set_glitter(value: bool) -> void:
	glitter = value

func clear_drawing() -> void:
	_remember()
	artwork = base_image.duplicate()
	fill_image = base_image.duplicate()
	_refresh()
	drawing_changed.emit()

func undo() -> void:
	if not history.is_empty():
		var previous: Dictionary = history.pop_back()
		artwork = previous["artwork"]
		fill_image = previous["fill_image"]
		_refresh()
		drawing_changed.emit()

func _remember() -> void:
	if history.size() >= MAX_UNDO:
		history.pop_front()
	history.append({"artwork": artwork.duplicate(), "fill_image": fill_image.duplicate()})

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_start(event.position)
		elif not event.pressed and event.index == touch_index:
			_finish()
			touch_index = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_move(event.position)
		accept_event()
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available() and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start(event.position)
		else:
			_finish()
		accept_event()
	elif event is InputEventMouseMotion and not DisplayServer.is_touchscreen_available() and (drawing or zoom_dragging):
		_move(event.position)
		accept_event()

func _image_point(position: Vector2) -> Vector2:
	var source := _visible_image_rect()
	return Vector2(
		clampf(source.position.x + position.x * source.size.x / size.x, 0.0, WIDTH - 1.0),
		clampf(source.position.y + position.y * source.size.y / size.y, 0.0, HEIGHT - 1.0)
	)

func _visible_image_rect() -> Rect2:
	var visible_size := Vector2(WIDTH, HEIGHT) / zoom_factor
	return Rect2(zoom_center - visible_size / 2.0, visible_size)

func set_zoom(value: float, center: Vector2) -> void:
	zoom_factor = clampf(value, 1.0, 4.0)
	var half_size := Vector2(WIDTH, HEIGHT) / (zoom_factor * 2.0)
	zoom_center = Vector2(
		clampf(center.x, half_size.x, WIDTH - half_size.x),
		clampf(center.y, half_size.y, HEIGHT - half_size.y)
	)
	queue_redraw()

func _start(position: Vector2) -> void:
	if not Rect2(Vector2.ZERO, size).has_point(position):
		return
	if tool == "zoom":
		zoom_dragging = true
		zoom_moved = false
		zoom_last_position = position
		zoom_start_position = position
		return
	var point := _image_point(position)
	if tool == "text":
		text_placement_requested.emit(point)
		return
	if tool == "fill" and _is_outline(int(point.x), int(point.y)):
		return
	_remember()
	if tool == "fill":
		_flood_fill(Vector2i(point), brush_color)
	elif tool == "stamp":
		_draw_stamp(point)
	else:
		drawing = true
		last_point = point
		_dab(point)
	_refresh()
	drawing_changed.emit()

func _move(position: Vector2) -> void:
	if zoom_dragging:
		if not zoom_moved and position.distance_to(zoom_start_position) >= 8.0:
			zoom_moved = true
			zoom_last_position = zoom_start_position
		if zoom_moved:
			var delta := position - zoom_last_position
			set_zoom(zoom_factor, zoom_center - delta * _visible_image_rect().size / size)
			zoom_last_position = position
		return
	if not drawing:
		return
	var point := _image_point(position)
	var distance := last_point.distance_to(point)
	var steps := maxi(1, ceili(distance / maxf(1.0, brush_size * 0.25)))
	for i in range(1, steps + 1):
		_dab(last_point.lerp(point, float(i) / steps))
	last_point = point
	_refresh()
	drawing_changed.emit()

func _finish() -> void:
	if zoom_dragging:
		zoom_dragging = false
		if not zoom_moved:
			set_zoom(zoom_factor * 2.0, _image_point(zoom_last_position))
		return
	if drawing:
		drawing = false
		drawing_changed.emit()

func _dab(center: Vector2) -> void:
	var radius: float = brush_size / 2.0
	var min_x := maxi(0, floori(center.x - radius))
	var max_x := mini(WIDTH - 1, ceili(center.x + radius))
	var min_y := maxi(0, floori(center.y - radius))
	var max_y := mini(HEIGHT - 1, ceili(center.y + radius))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Vector2(x, y).distance_squared_to(center) <= radius * radius and not _is_outline(x, y):
				artwork.set_pixel(x, y, base_image.get_pixel(x, y) if tool == "eraser" else _paint_color(x, y))
				fill_image.set_pixel(x, y, base_image.get_pixel(x, y) if tool == "eraser" else brush_color)

func _paint_color(x: int, y: int) -> Color:
	if not glitter:
		return brush_color
	var sparkle := (x * 37 + y * 61 + x * y * 7) % 97
	if sparkle < 5:
		return brush_color.lerp(Color.WHITE, 0.88)
	if sparkle < 18:
		return brush_color.lightened(0.35)
	if sparkle < 25:
		return brush_color.darkened(0.18)
	return brush_color

func _matches(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= FILL_TOLERANCE and absf(a.g - b.g) <= FILL_TOLERANCE and absf(a.b - b.b) <= FILL_TOLERANCE

func _is_outline(x: int, y: int) -> bool:
	return outline_mask != null and outline_mask.get_pixel(x, y).r > 0.5

func _flood_fill(start: Vector2i, color: Color) -> void:
	if start.x < 0 or start.x >= WIDTH or start.y < 0 or start.y >= HEIGHT or _is_outline(start.x, start.y):
		return
	var original := fill_image.get_pixelv(start)
	var marker := Color.BLACK if original.get_luminance() > 0.5 else Color.WHITE
	var needs_marker := _matches(original, color)
	var pending: Array[Vector2i] = [start]
	var painted_spans: Array[Vector3i] = []
	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		if _is_outline(point.x, point.y) or not _matches(fill_image.get_pixelv(point), original):
			continue
		var left := point.x
		var right := point.x
		while left > 0 and not _is_outline(left - 1, point.y) and _matches(fill_image.get_pixel(left - 1, point.y), original):
			left -= 1
		while right < WIDTH - 1 and not _is_outline(right + 1, point.y) and _matches(fill_image.get_pixel(right + 1, point.y), original):
			right += 1
		for x in range(left, right + 1):
			artwork.set_pixel(x, point.y, color)
			fill_image.set_pixel(x, point.y, marker if needs_marker else color)
		if glitter or needs_marker:
			painted_spans.append(Vector3i(left, right, point.y))
		for adjacent_y in [point.y - 1, point.y + 1]:
			if adjacent_y < 0 or adjacent_y >= HEIGHT:
				continue
			var in_run := false
			for x in range(left, right + 1):
				var matches := not _is_outline(x, adjacent_y) and _matches(fill_image.get_pixel(x, adjacent_y), original)
				if matches and not in_run:
					pending.append(Vector2i(x, adjacent_y))
				in_run = matches
	for span in painted_spans:
		for x in range(span.x, span.y + 1):
			artwork.set_pixel(x, span.z, _paint_color(x, span.z))
			if needs_marker:
				fill_image.set_pixel(x, span.z, color)

func _draw_stamp(center: Vector2) -> void:
	var radius: float = brush_size * 1.5
	var star := PackedVector2Array()
	if stamp == "star":
		for i in range(10):
			var angle: float = -PI / 2.0 + i * PI / 5.0
			var r: float = radius if i % 2 == 0 else radius * 0.45
			star.append(Vector2(cos(angle), sin(angle)) * r)
	for y in range(maxi(0, floori(center.y - radius)), mini(HEIGHT - 1, ceili(center.y + radius)) + 1):
		for x in range(maxi(0, floori(center.x - radius)), mini(WIDTH - 1, ceili(center.x + radius)) + 1):
			var p := (Vector2(x, y) - center) / radius
			var inside := false
			match stamp:
				"star":
					inside = Geometry2D.is_point_in_polygon(Vector2(x, y) - center, star)
				"heart":
					var hx: float = p.x * 1.3
					var hy: float = -p.y * 1.3
					inside = pow(hx * hx + hy * hy - 0.7, 3) - hx * hx * hy * hy * hy <= 0.0
				"sun":
					var r := p.length()
					inside = r < 0.54 or (r < 0.95 and absf(sin(p.angle() * 6.0)) < 0.28)
				"flower":
					inside = p.length_squared() < 0.12
					for i in range(6):
						var angle: float = TAU * i / 6.0
						if (p - Vector2(cos(angle), sin(angle)) * 0.58).length_squared() < 0.11:
							inside = true
				"leopard":
					inside = _is_leopard_shape(p)
				_:
					inside = (Vector2(p.x, p.y - 0.32).length_squared() < 0.23 or
						Vector2(p.x + 0.62, p.y + 0.15).length_squared() < 0.07 or
						Vector2(p.x + 0.22, p.y + 0.55).length_squared() < 0.07 or
						Vector2(p.x - 0.22, p.y + 0.55).length_squared() < 0.07 or
						Vector2(p.x - 0.62, p.y + 0.15).length_squared() < 0.07)
			if inside and not _is_outline(x, y):
				artwork.set_pixel(x, y, _paint_color(x, y))
				fill_image.set_pixel(x, y, brush_color)

func create_stamp_icon(shape: String) -> Texture2D:
	var sample := DrawingCanvas.new()
	sample.artwork = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	sample.fill_image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	sample.artwork.fill(Color.TRANSPARENT)
	sample.fill_image.fill(Color.TRANSPARENT)
	sample.brush_color = Color("#1757a4")
	sample.brush_size = 22.0
	sample.stamp = shape
	sample._draw_stamp(Vector2(50, 50))
	var bounds := sample.artwork.get_used_rect()
	var centered := Image.create(76, 76, false, Image.FORMAT_RGBA8)
	centered.fill(Color.TRANSPARENT)
	centered.blit_rect(sample.artwork, bounds, (Vector2i(76, 76) - bounds.size) / 2)
	var icon := ImageTexture.create_from_image(centered)
	sample.free()
	return icon

func place_text(point: Vector2) -> void:
	if text_image == null or text_image.is_empty():
		push_error("Text is not ready to place.")
		return
	var origin := Vector2i(roundi(point.x), roundi(point.y - text_image.get_height() / 2.0))
	_remember()
	artwork.blend_rect(text_image, Rect2i(Vector2i.ZERO, text_image.get_size()), origin)
	fill_image.blend_rect(text_image, Rect2i(Vector2i.ZERO, text_image.get_size()), origin)
	var affected := Rect2i(origin, text_image.get_size()).intersection(Rect2i(0, 0, WIDTH, HEIGHT))
	for y in range(affected.position.y, affected.end.y):
		for x in range(affected.position.x, affected.end.x):
			if _is_outline(x, y):
				var original := base_image.get_pixel(x, y)
				artwork.set_pixel(x, y, original)
				fill_image.set_pixel(x, y, original)
	_refresh()
	drawing_changed.emit()

func _is_leopard_shape(point: Vector2) -> bool:
	var head := Vector2(point.x / 0.8, point.y / 0.72).length_squared() <= 1.0
	var ears := (point - Vector2(-0.57, -0.58)).length_squared() <= 0.27 * 0.27 \
		or (point - Vector2(0.57, -0.58)).length_squared() <= 0.27 * 0.27
	if not head and not ears:
		return false
	var marks := [
		Vector2(-0.29, -0.12), Vector2(0.29, -0.12),
		Vector2(-0.18, -0.43), Vector2(0.18, -0.43),
		Vector2(-0.53, 0.21), Vector2(0.53, 0.21),
		Vector2(0.0, 0.28)
	]
	for mark in marks:
		if (point - mark).length_squared() < 0.085 * 0.085:
			return false
	return true

func _refresh() -> void:
	if artwork_texture == null:
		artwork_texture = ImageTexture.create_from_image(artwork)
	else:
		artwork_texture.update(artwork)
	queue_redraw()

func _draw() -> void:
	if artwork_texture:
		draw_texture_rect_region(artwork_texture, Rect2(Vector2.ZERO, size), _visible_image_rect())

func save_artwork(path: String) -> Error:
	return artwork.save_png(path)

func create_signed_image(profile_name: String, grade: String) -> Image:
	var artwork_snapshot: Image = artwork.duplicate()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(WIDTH, 80)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	var footer := Control.new()
	footer.set_script(preload("res://scripts/signature_footer.gd"))
	footer.set("profile_name", profile_name)
	footer.set("grade", tr(grade))
	footer.set("caption", tr("LITTLE LEOPARD ARTIST"))
	footer.set("pride", tr("Made with pride!"))
	footer.size = Vector2(WIDTH, 80)
	viewport.add_child(footer)
	add_child(viewport)
	await RenderingServer.frame_post_draw
	var footer_image := viewport.get_texture().get_image()
	viewport.queue_free()
	if footer_image == null or footer_image.is_empty():
		push_error("Could not render the artwork signature.")
		return null
	footer_image.convert(Image.FORMAT_RGBA8)
	var signed_image := Image.create(WIDTH, HEIGHT + 80, false, Image.FORMAT_RGBA8)
	signed_image.blit_rect(artwork_snapshot, Rect2i(0, 0, WIDTH, HEIGHT), Vector2i.ZERO)
	signed_image.blit_rect(footer_image, Rect2i(0, 0, WIDTH, 80), Vector2i(0, HEIGHT))
	return signed_image
