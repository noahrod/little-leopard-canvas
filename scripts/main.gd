extends Control

const CanvasScript = preload("res://scripts/drawing_canvas.gd")
const PAGE_PATHS := [
	"res://assets/coloring/school_clean.png",
	"res://assets/coloring/banner_clean.png",
	"res://assets/coloring/mascot.png",
	"res://assets/coloring/pto.png",
	"res://assets/coloring/app_icon_outline.png",
	""
]
const PAGE_NAMES := ["School", "Lowell", "Leopard", "Paw", "Art Club", "Blank"]
const COLORS := ["#1857a4", "#ef4936", "#ffc92f", "#ff8f2f", "#39ad69", "#37b8d5", "#8d5bd5", "#ec70a4", "#70452f", "#1a2841", "#ffffff", "#a4db79"]
const SIZES := [10.0, 20.0, 36.0]
const NAVY := Color("#123d78")
const BLUE := Color("#1757a4")
const GOLD := Color("#ffcf40")
const RED := Color("#ed573b")
const INK := Color("#15365d")

var canvas: DrawingCanvas
var status_label: Label
var tool_buttons: Dictionary = {}
var color_buttons: Array[Button] = []
var stamp_buttons: Dictionary = {}
var size_buttons: Array[Button] = []
var page_buttons: Array[Button] = []
var page_textures: Array[Texture2D] = []
var page_dialog: AcceptDialog
var page_start := 0
var page_previous: Button
var page_next: Button
var text_dialog: ConfirmationDialog
var text_input: LineEdit
var selected_tool := "brush"
var selected_stamp := "paw"
var selected_color := 0
var selected_size := 1
var selected_page := 0
var pending_page := -1
var confirm_dialog: ConfirmationDialog
var confirm_action := ""
var color_dialog: ConfirmationDialog
var color_picker: ColorPicker
var custom_button: Button
var glitter_button: Button
var glitter_enabled := false
var profile_store := ProfileStore.new()
var profiles_available := true
var profile_dialog: AcceptDialog
var profile_picker: OptionButton
var profile_name_input: LineEdit
var grade_picker: OptionButton
var profile_message: Label
var profile_button: Button
var artist_caption: Label
var editing_profile := -1
var saving_art := false
var gallery: ArtGallery

func _ready() -> void:
	var profile_error := profile_store.load_profiles()
	if profile_error != OK:
		profiles_available = false
		push_error("Could not load profiles: " + error_string(profile_error))
	_load_pages()
	_build_interface()
	_select_color(0)
	_select_size(1)
	_select_stamp("paw")
	_select_tool("brush")
	_select_page(0)
	if not profiles_available:
		status_label.text = "Profiles could not be loaded. Please ask an adult for help."
	_refresh_profile_button()

func _load_pages() -> void:
	for path in PAGE_PATHS:
		var texture: Texture2D = null
		if not path.is_empty():
			if ResourceLoader.exists(path):
				texture = load(path) as Texture2D
			if texture == null:
				push_error("Could not load page: " + path)
		page_textures.append(texture)

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BLUE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 62
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)
	var badge := TextureRect.new()
	badge.name = "AppBadge"
	badge.texture = load("res://assets/app_icon/little_leopard_canvas.png")
	badge.custom_minimum_size = Vector2(58, 58)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(badge)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	heading.add_child(_label("LITTLE LEOPARD CANVAS", 25, Color.WHITE))
	artist_caption = _label("ART CLUB  •  Choose an artist profile", 14, GOLD)
	artist_caption.clip_text = true
	heading.add_child(artist_caption)
	profile_button = _header_button("PROFILES", "profile", Vector2(120, 54), Color("#e8f3ff"), "Choose or edit an artist")
	profile_button.pressed.connect(_open_profiles)
	header.add_child(profile_button)
	var gallery_button := _header_button("GALLERY", "gallery", Vector2(120, 54), Color("#e8f3ff"), "View saved artwork")
	gallery_button.pressed.connect(_open_gallery)
	header.add_child(gallery_button)
	var new_button := _header_button("NEW", "new", Vector2(90, 54), Color("#e8f3ff"), "Choose a new page")
	new_button.pressed.connect(_open_pages)
	header.add_child(new_button)
	var undo_button := _header_button("", "undo", Vector2(58, 54), Color("#e8f3ff"), "Undo last change")
	undo_button.pressed.connect(_on_undo)
	header.add_child(undo_button)
	var clear_button := _header_button("CLEAR", "clear", Vector2(105, 54), Color("#fff0e8"), "Clear the page")
	clear_button.pressed.connect(_ask_clear)
	header.add_child(clear_button)
	var save_button := _header_button("SAVE ART", "save", Vector2(130, 54), GOLD, "Save your artwork")
	save_button.pressed.connect(_on_save)
	header.add_child(save_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)

	var tools := _panel(Color("#f7fbff"), 18)
	tools.custom_minimum_size.x = 82
	body.add_child(tools)
	var tool_list := VBoxContainer.new()
	tool_list.add_theme_constant_override("separation", 8)
	tools.add_child(tool_list)
	for entry in [["brush", "Brush"], ["fill", "Fill"], ["stamp", "Stamp"], ["eraser", "Eraser"], ["text", "Text"]]:
		var button := _button("", Vector2(62, 62), Color.WHITE)
		button.icon = load("res://assets/ui/" + entry[0] + ".svg")
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 42)
		button.tooltip_text = entry[1]
		if entry[0] == "text":
			button.pressed.connect(_open_text)
		else:
			button.pressed.connect(_select_tool.bind(entry[0]))
		tool_list.add_child(button)
		tool_buttons[entry[0]] = button

	var board := _panel(Color("#ffdc62"), 18)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(board)
	var frame := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 4)
	board.add_child(frame)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = float(CanvasScript.WIDTH) / CanvasScript.HEIGHT
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(aspect)
	canvas = CanvasScript.new()
	canvas.name = "DrawingCanvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	aspect.add_child(canvas)
	canvas.text_placement_requested.connect(_place_text)

	var choices := _panel(Color("#f7fbff"), 18)
	choices.custom_minimum_size.x = 218
	body.add_child(choices)
	var choice_list := VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 4)
	choices.add_child(choice_list)
	choice_list.add_child(_label("PICK A COLOR", 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var colors := GridContainer.new()
	colors.columns = 4
	colors.add_theme_constant_override("h_separation", 5)
	colors.add_theme_constant_override("v_separation", 5)
	choice_list.add_child(colors)
	for i in COLORS.size():
		var swatch := _button("", Vector2(43, 40), Color(COLORS[i]))
		swatch.tooltip_text = "Color " + str(i + 1)
		swatch.pressed.connect(_select_color.bind(i))
		colors.add_child(swatch)
		color_buttons.append(swatch)
	var extra := HBoxContainer.new()
	extra.add_theme_constant_override("separation", 5)
	choice_list.add_child(extra)
	custom_button = _button("MORE COLORS", Vector2(112, 42), Color("#e4f0ff"), 12)
	custom_button.pressed.connect(_open_color_picker)
	extra.add_child(custom_button)
	glitter_button = _button("GLITTER", Vector2(80, 42), Color("#fff0be"), 12)
	glitter_button.pressed.connect(_toggle_glitter)
	extra.add_child(glitter_button)
	choice_list.add_child(_label("BRUSH SIZE", 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override("separation", 5)
	choice_list.add_child(sizes)
	for i in SIZES.size():
		var button := _button(["S", "M", "L"][i], Vector2(53, 40), Color.WHITE)
		button.pressed.connect(_select_size.bind(i))
		sizes.add_child(button)
		size_buttons.append(button)
	choice_list.add_child(_label("STAMPS", 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var stamps := GridContainer.new()
	stamps.columns = 3
	stamps.add_theme_constant_override("h_separation", 5)
	stamps.add_theme_constant_override("v_separation", 4)
	choice_list.add_child(stamps)
	for entry in [["paw", "PAW"], ["star", "STAR"], ["heart", "HEART"], ["leopard", "LEOPARD"], ["sun", "SUN"], ["flower", "FLOWER"]]:
		var button := _button("", Vector2(59, 48), Color.WHITE)
		button.icon = canvas.create_stamp_icon(entry[0])
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 36)
		button.tooltip_text = entry[1]
		button.pressed.connect(_select_stamp.bind(entry[0]))
		stamps.add_child(button)
		stamp_buttons[entry[0]] = button

	status_label = _label("Let's make art!", 14, Color.WHITE)
	status_label.custom_minimum_size.y = 20
	layout.add_child(status_label)

	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Are you sure?"
	confirm_dialog.ok_button_text = "Yes"
	confirm_dialog.confirmed.connect(_confirmed)
	confirm_dialog.canceled.connect(_confirmation_canceled)
	add_child(confirm_dialog)

	color_dialog = ConfirmationDialog.new()
	color_dialog.title = "Pick your own color!"
	color_dialog.ok_button_text = "USE THIS COLOR"
	color_picker = ColorPicker.new()
	color_picker.custom_minimum_size = Vector2(330, 300)
	color_picker.picker_shape = ColorPicker.SHAPE_HSV_WHEEL
	color_picker.edit_alpha = false
	color_picker.sliders_visible = false
	color_picker.hex_visible = false
	color_picker.color_modes_visible = false
	color_picker.presets_visible = false
	color_picker.sampler_visible = false
	var color_choices := VBoxContainer.new()
	color_choices.add_theme_constant_override("separation", 6)
	color_dialog.add_child(color_choices)
	var shades_caption := _label("TAP A SHADE OR PICK YOUR OWN", 15, INK, HORIZONTAL_ALIGNMENT_CENTER)
	color_choices.add_child(shades_caption)
	var shades := GridContainer.new()
	shades.columns = 6
	shades.add_theme_constant_override("h_separation", 6)
	shades.add_theme_constant_override("v_separation", 6)
	color_choices.add_child(shades)
	for color_hex in COLORS:
		for shade in [Color(color_hex).lightened(0.35), Color(color_hex).darkened(0.3)]:
			var shade_button := _button("", Vector2(49, 38), shade)
			shade_button.tooltip_text = "Choose this shade"
			shade_button.pressed.connect(_pick_shade.bind(shade))
			shades.add_child(shade_button)
	color_choices.add_child(color_picker)
	color_dialog.confirmed.connect(_apply_custom_color)
	add_child(color_dialog)
	_build_profile_dialog()
	_build_page_dialog()
	_build_text_dialog()
	gallery = ArtGallery.new()
	add_child(gallery)

func _open_gallery() -> void:
	gallery.open_gallery()

func _build_page_dialog() -> void:
	page_dialog = AcceptDialog.new()
	page_dialog.title = "Pick a new page"
	page_dialog.ok_button_text = "BACK TO DRAWING"
	add_child(page_dialog)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	page_dialog.add_child(row)
	page_previous = _button("<", Vector2(54, 100), Color("#e8f3ff"), 28)
	page_previous.tooltip_text = "Previous pages"
	page_previous.pressed.connect(_change_page_group.bind(-1))
	row.add_child(page_previous)
	for i in PAGE_NAMES.size():
		var page := _button(PAGE_NAMES[i].to_upper(), Vector2(115, 100), Color.WHITE, 13)
		if page_textures[i]:
			page.icon = page_textures[i]
			page.expand_icon = true
			page.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			page.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		elif not PAGE_PATHS[i].is_empty():
			page.disabled = true
			page.tooltip_text = "This page could not be loaded."
		page.pressed.connect(_request_page.bind(i))
		row.add_child(page)
		page_buttons.append(page)
	page_next = _button(">", Vector2(54, 100), Color("#e8f3ff"), 28)
	page_next.tooltip_text = "More pages"
	page_next.pressed.connect(_change_page_group.bind(1))
	row.add_child(page_next)
	_update_page_group()

func _update_page_group() -> void:
	for i in page_buttons.size():
		page_buttons[i].visible = i >= page_start and i < page_start + 4
	page_previous.disabled = page_start == 0
	page_next.disabled = page_start + 4 >= page_buttons.size()

func _change_page_group(direction: int) -> void:
	page_start = clampi(page_start + direction * 4, 0, 4)
	_update_page_group()

func _open_pages() -> void:
	page_start = (selected_page / 4) * 4
	_update_page_group()
	page_dialog.popup_centered()

func _build_text_dialog() -> void:
	text_dialog = ConfirmationDialog.new()
	text_dialog.title = "Add words to your art"
	text_dialog.ok_button_text = "PLACE WORDS"
	add_child(text_dialog)
	text_input = LineEdit.new()
	text_input.placeholder_text = "Type your words"
	text_input.max_length = 60
	text_input.custom_minimum_size = Vector2(380, 54)
	text_dialog.add_child(text_input)
	text_dialog.confirmed.connect(_prepare_text)

func _open_text() -> void:
	text_dialog.popup_centered()
	text_input.grab_focus()

func _prepare_text() -> void:
	var words := text_input.text.strip_edges()
	if words.is_empty():
		status_label.text = "Type some words before placing text."
		return
	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.size = Vector2i(CanvasScript.WIDTH, 96)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", canvas.brush_color)
	label.size = Vector2(CanvasScript.WIDTH, 96)
	label.clip_text = true
	viewport.add_child(label)
	canvas.add_child(viewport)
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.is_empty():
		push_error("Could not render text for the canvas.")
		status_label.text = "Could not prepare your words. Please try again."
		return
	image.convert(Image.FORMAT_RGBA8)
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		push_error("Rendered text was empty.")
		status_label.text = "Could not prepare your words. Please try again."
		return
	canvas.text_image = image.get_region(used)
	_select_tool("text")

func _place_text(point: Vector2) -> void:
	canvas.place_text(point)
	status_label.text = "Tap again to add your words, or choose another tool."

func _build_profile_dialog() -> void:
	profile_dialog = AcceptDialog.new()
	profile_dialog.title = "Little Leopard artists"
	profile_dialog.ok_button_text = "DONE"
	add_child(profile_dialog)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(430, 0)
	content.add_theme_constant_override("separation", 10)
	profile_dialog.add_child(content)
	content.add_child(_label("Choose an artist", 18, Color.WHITE))
	profile_picker = OptionButton.new()
	profile_picker.custom_minimum_size.y = 48
	profile_picker.item_selected.connect(_profile_chosen)
	content.add_child(profile_picker)
	var new_button := _button("NEW ARTIST", Vector2(0, 48), GOLD)
	new_button.pressed.connect(_new_profile)
	content.add_child(new_button)
	content.add_child(_label("Name", 18, Color.WHITE))
	profile_name_input = LineEdit.new()
	profile_name_input.placeholder_text = "Type your name"
	profile_name_input.max_length = ProfileStore.MAX_NAME_LENGTH
	profile_name_input.custom_minimum_size.y = 48
	content.add_child(profile_name_input)
	content.add_child(_label("Grade", 18, Color.WHITE))
	grade_picker = OptionButton.new()
	grade_picker.custom_minimum_size.y = 48
	grade_picker.add_item("Choose your grade")
	for grade in ProfileStore.GRADES:
		grade_picker.add_item(grade)
	content.add_child(grade_picker)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var save_profile := _button("SAVE PROFILE", Vector2(190, 48), GOLD)
	save_profile.pressed.connect(_save_profile)
	actions.add_child(save_profile)
	var delete_profile := _button("DELETE", Vector2(120, 48), Color("#fff0e8"))
	delete_profile.pressed.connect(_ask_delete_profile)
	actions.add_child(delete_profile)
	profile_message = _label("Choose a profile or create a new artist.", 15, Color.WHITE)
	profile_message.clip_text = true
	content.add_child(profile_message)

func _refresh_profile_button() -> void:
	if profile_store.selected >= 0:
		var artist: Dictionary = profile_store.profiles[profile_store.selected]
		artist_caption.text = "ARTIST: " + artist["name"] + "  •  " + artist["grade"]
	else:
		artist_caption.text = "ART CLUB  •  Choose an artist profile"

func _open_profiles() -> void:
	_refresh_profile_list()
	if profile_store.selected >= 0:
		_edit_profile(profile_store.selected)
	else:
		_new_profile()
	if not profiles_available:
		profile_message.text = "Profiles could not be loaded. Ask an adult for help; existing data was not changed."
	profile_dialog.popup_centered()

func _refresh_profile_list() -> void:
	profile_picker.clear()
	profile_picker.add_item("Choose an artist")
	for entry in profile_store.profiles:
		profile_picker.add_item(entry["name"] + "  •  " + entry["grade"])
	profile_picker.select(profile_store.selected + 1)

func _new_profile() -> void:
	editing_profile = -1
	profile_name_input.text = ""
	grade_picker.select(0)
	profile_message.text = "Enter a name and grade, then tap Save Profile."
	if profile_store.selected >= 0:
		profile_message.text += " The previous artist stays selected until you save."

func _edit_profile(index: int) -> void:
	editing_profile = index
	var entry: Dictionary = profile_store.profiles[index]
	profile_name_input.text = entry["name"]
	grade_picker.select(ProfileStore.GRADES.find(entry["grade"]) + 1)
	profile_message.text = "This artist will sign saved artwork."

func _profile_chosen(index: int) -> void:
	if not profiles_available:
		profile_message.text = "Profiles could not be loaded; changes are disabled."
		_refresh_profile_list()
		return
	var selected := index - 1
	var error := profile_store.commit(profile_store.profiles, selected)
	if error != OK:
		_profile_error(error)
		_refresh_profile_list()
		return
	_refresh_profile_button()
	if selected < 0:
		_new_profile()
	else:
		_edit_profile(selected)

func _save_profile() -> void:
	if not profiles_available:
		profile_message.text = "Profiles could not be loaded; changes are disabled."
		return
	var clean_name := profile_name_input.text.strip_edges()
	if clean_name.is_empty():
		profile_message.text = "Please enter your name."
		return
	if grade_picker.selected <= 0:
		profile_message.text = "Please choose your grade."
		return
	var grade := grade_picker.get_item_text(grade_picker.selected)
	if not profile_store.valid_profile(clean_name, grade):
		profile_message.text = "Please use a name of up to 32 characters on one line."
		return
	var updated: Array[Dictionary] = profile_store.profiles.duplicate(true)
	var index := editing_profile
	if index < 0:
		updated.append({"name": clean_name, "grade": grade})
		index = updated.size() - 1
	else:
		updated[index] = {"name": clean_name, "grade": grade}
	var error := profile_store.commit(updated, index)
	if error != OK:
		_profile_error(error)
		return
	_refresh_profile_list()
	_refresh_profile_button()
	_edit_profile(index)
	profile_message.text = "Profile saved! This artist will sign your artwork."

func _ask_delete_profile() -> void:
	if editing_profile < 0 or not profiles_available:
		profile_message.text = "Choose a saved artist to delete."
		return
	confirm_action = "delete_profile"
	confirm_dialog.dialog_text = "Delete this artist's profile? Saved artwork will not be deleted."
	confirm_dialog.popup_centered()

func _delete_profile() -> void:
	if editing_profile < 0 or editing_profile >= profile_store.profiles.size():
		return
	var updated: Array[Dictionary] = profile_store.profiles.duplicate(true)
	updated.remove_at(editing_profile)
	var selected := profile_store.selected
	if selected == editing_profile:
		selected = -1
	elif selected > editing_profile:
		selected -= 1
	var error := profile_store.commit(updated, selected)
	if error != OK:
		_profile_error(error)
		return
	_refresh_profile_list()
	_refresh_profile_button()
	_new_profile()
	profile_message.text = "Profile deleted. Saved artwork was not changed."

func _profile_error(error: Error) -> void:
	profile_message.text = "Could not save profiles. Ask an adult for help."
	push_error("Could not save profiles: " + error_string(error))

func _panel(color: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(color, radius)
	for side in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		style.set(side, 10.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _style(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(3 if border.a > 0 else 0)
	return style

func _button(text: String, minimum: Vector2, color: Color, font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	button.add_theme_stylebox_override("normal", _style(color, 12))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.1), 12, GOLD))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.1), 12, BLUE))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 12, GOLD))
	return button

func _pad_header_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		button.add_theme_stylebox_override(state, style)
	button.add_theme_constant_override("h_separation", 6)

func _header_button(text: String, icon_name: String, minimum: Vector2, color: Color, hint: String) -> Button:
	var button := _button(text, minimum, color, 14)
	button.name = "Header" + icon_name.capitalize()
	button.icon = load("res://assets/ui/" + icon_name + ".svg")
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER if text.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.tooltip_text = hint
	_pad_header_button(button)
	return button

func _label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label

func _mark(button: Button, color: Color, selected: bool) -> void:
	var border := GOLD if selected else Color("#d3dfeb") if color == Color.WHITE else Color.TRANSPARENT
	button.add_theme_stylebox_override("normal", _style(color, 12, border))

func _select_tool(value: String) -> void:
	selected_tool = value
	canvas.set_tool(value)
	for key in tool_buttons:
		_mark(tool_buttons[key], Color("#d6edff") if key == value else Color.WHITE, key == value)
	var hints := {"brush": "Brush: drag your finger to paint!", "fill": "Fill: tap an area to color it!", "stamp": "Stamp: tap to make a shape!", "eraser": "Eraser: rub away your marks!", "text": "Tap your page to place your words!"}
	status_label.text = hints[value]

func _select_color(index: int) -> void:
	selected_color = index
	canvas.set_color(Color(COLORS[index]))
	for i in color_buttons.size():
		_mark(color_buttons[i], Color(COLORS[i]), i == index)
	if custom_button:
		_mark(custom_button, Color("#e4f0ff"), false)

func _open_color_picker() -> void:
	color_picker.color = canvas.brush_color
	color_dialog.popup_centered()

func _apply_custom_color() -> void:
	selected_color = -1
	canvas.set_color(color_picker.color)
	for i in color_buttons.size():
		_mark(color_buttons[i], Color(COLORS[i]), false)
	_mark(custom_button, Color("#e4f0ff"), true)
	status_label.text = "Your own color is ready!"

func _pick_shade(color: Color) -> void:
	color_picker.color = color
	_apply_custom_color()
	color_dialog.hide()

func _toggle_glitter() -> void:
	glitter_enabled = not glitter_enabled
	canvas.set_glitter(glitter_enabled)
	_mark(glitter_button, Color("#fff0be"), glitter_enabled)
	glitter_button.text = "GLITTER ON" if glitter_enabled else "GLITTER"
	status_label.text = "Sparkle time! Glitter is on." if glitter_enabled else "Glitter is off."

func _select_size(index: int) -> void:
	selected_size = index
	canvas.set_brush_size(SIZES[index])
	for i in size_buttons.size():
		_mark(size_buttons[i], Color("#d6edff") if i == index else Color.WHITE, i == index)

func _select_stamp(value: String) -> void:
	selected_stamp = value
	canvas.set_stamp(value)
	for key in stamp_buttons:
		_mark(stamp_buttons[key], Color("#d6edff") if key == value else Color.WHITE, key == value)
	if is_instance_valid(status_label):
		_select_tool("stamp")

func _request_page(index: int) -> void:
	pending_page = index
	confirm_action = "page"
	confirm_dialog.dialog_text = "Start a new page? Your current drawing will be cleared. Save it first if you want to keep it."
	page_dialog.hide()
	confirm_dialog.popup_centered()

func _confirmation_canceled() -> void:
	if confirm_action == "page":
		pending_page = -1
		page_dialog.popup_centered.call_deferred()
	confirm_action = ""

func _select_page(index: int) -> void:
	selected_page = index
	canvas.set_page(page_textures[index])
	for i in page_buttons.size():
		_mark(page_buttons[i], Color.WHITE, i == index)

func _ask_clear() -> void:
	confirm_action = "clear"
	confirm_dialog.dialog_text = "Clear your drawing? You can undo this afterward."
	confirm_dialog.popup_centered()

func _confirmed() -> void:
	if confirm_action == "clear":
		canvas.clear_drawing()
		status_label.text = "A fresh page! Undo if you change your mind."
	elif confirm_action == "page" and pending_page >= 0:
		_select_page(pending_page)
		page_dialog.hide()
		status_label.text = "New page ready! Let's make art."
		pending_page = -1
	elif confirm_action == "delete_profile":
		_delete_profile()
	confirm_action = ""

func _on_undo() -> void:
	canvas.undo()
	status_label.text = "Undid your last change."

func _on_save() -> void:
	if saving_art:
		return
	if not profiles_available or profile_store.selected < 0:
		status_label.text = "Choose an artist profile before saving."
		_open_profiles()
		return
	var artist: Dictionary = profile_store.profiles[profile_store.selected].duplicate()
	saving_art = true
	status_label.text = "Signing your masterpiece..."
	var signed_image: Image = await canvas.create_signed_image(artist["name"], artist["grade"])
	if signed_image == null:
		saving_art = false
		status_label.text = "Could not add the signature. Please try again."
		return
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://artwork_" + timestamp + "_" + str(Time.get_ticks_msec()) + ".png"
	var result := signed_image.save_png(path)
	if result != OK:
		saving_art = false
		status_label.text = "Could not save artwork."
		push_error("Could not save artwork: " + str(result))
		return
	var last_result := signed_image.save_png("user://last_art.png")
	if last_result != OK:
		saving_art = false
		status_label.text = "Artwork saved, but the latest copy failed."
		push_error("Could not save last artwork: " + str(last_result))
		return
	saving_art = false
	status_label.text = "Your signed masterpiece is saved on this device!"
