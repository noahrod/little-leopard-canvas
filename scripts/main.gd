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
var settings_store := SettingsStore.new()
var settings_available := true
var suppress_setup := false
var settings_dialog: AcceptDialog
var settings_error_dialog: AcceptDialog
var language_picker: OptionButton
var settings_message: Label
var setup_overlay: Control
var setup_language: OptionButton
var setup_step_language: VBoxContainer
var setup_step_artist: VBoxContainer
var setup_name: LineEdit
var setup_grade: OptionButton
var setup_existing: OptionButton
var setup_message: Label
var setup_created_index := -1
var profiles_available := true
var profile_dialog: AcceptDialog
var return_to_settings := false
var profile_picker: OptionButton
var profile_form: VBoxContainer
var profile_name_input: LineEdit
var grade_picker: OptionButton
var delete_profile_button: Button
var profile_message: Label
var profile_button: Button
var artist_caption: Label
var editing_profile := -1
var saving_art := false
var save_button: Button
var saved_dialog: AcceptDialog
var save_error_dialog: AcceptDialog
var artwork_revision := 0
var last_saved_revision := -1
var last_saved_artist: Dictionary = {}
var last_saved_path := ""
var last_saved_language := ""
var artwork_storage_path := "user://"
var gallery: ArtGallery

func _ready() -> void:
	var profile_error := profile_store.load_profiles()
	if profile_error != OK:
		profiles_available = false
		push_error("Could not load profiles: " + error_string(profile_error))
	var settings_error := settings_store.load_settings(_has_existing_data())
	if settings_error != OK:
		settings_available = false
		push_error("Could not load settings: " + error_string(settings_error))
	TranslationServer.set_locale(settings_store.language)
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
	if not settings_available:
		status_label.text = "Could not load settings. Ask an adult for help."
	elif not settings_store.setup_complete and profiles_available and not suppress_setup:
		_show_setup()

func _has_existing_data() -> bool:
	if FileAccess.file_exists(profile_store.path):
		return true
	var directory := DirAccess.open(profile_store.path.get_base_dir())
	if directory == null:
		push_error("Could not check existing artwork: " + error_string(DirAccess.get_open_error()))
		return false
	for filename in directory.get_files():
		if filename == "last_art.png" or (filename.begins_with("artwork_") and filename.ends_with(".png")):
			return true
	return false

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
	var title := _label("LITTLE LEOPARD CANVAS", 25, Color.WHITE)
	title.name = "AppTitle"
	var title_font := FontVariation.new()
	title_font.base_font = preload("res://assets/fonts/Fredoka.ttf")
	title_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	title.add_theme_font_override("font", title_font)
	heading.add_child(title)
	artist_caption = _label("ART CLUB  •  Choose an artist profile", 14, GOLD)
	artist_caption.clip_text = true
	heading.add_child(artist_caption)
	profile_button = _header_button("SETTINGS", "settings", Vector2(120, 54), Color("#e8f3ff"), "Settings")
	profile_button.pressed.connect(_open_settings)
	header.add_child(profile_button)
	var gallery_button := _header_button("GALLERY", "gallery", Vector2(120, 54), Color("#e8f3ff"), "View saved artwork")
	gallery_button.pressed.connect(_open_gallery)
	header.add_child(gallery_button)
	var new_button := _header_button("NEW", "new", Vector2(90, 54), Color("#e8f3ff"), "Choose a new page")
	new_button.pressed.connect(_open_pages)
	header.add_child(new_button)
	var clear_button := _header_button("CLEAR", "clear", Vector2(105, 54), Color("#fff0e8"), "Clear the page")
	clear_button.pressed.connect(_ask_clear)
	header.add_child(clear_button)
	var undo_button := _header_button("", "undo", Vector2(58, 54), Color("#e8f3ff"), "Undo last change")
	undo_button.pressed.connect(_on_undo)
	header.add_child(undo_button)
	header.move_child(undo_button, header.get_child_count() - 3)
	save_button = _header_button("SAVE ART", "save", Vector2(130, 54), GOLD, "Save your artwork")
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
	for entry in [["brush", "Brush"], ["fill", "Fill"], ["stamp", "Stamp"], ["eraser", "Eraser"], ["text", "Text"], ["zoom", "Zoom"]]:
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
	var zoom_out := _button("", Vector2(62, 62), Color("#e8f3ff"))
	zoom_out.icon = load("res://assets/ui/zoom_out.svg")
	zoom_out.expand_icon = true
	zoom_out.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_out.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	zoom_out.add_theme_constant_override("icon_max_width", 42)
	zoom_out.tooltip_text = "Zoom out"
	zoom_out.pressed.connect(_zoom_out)
	tool_list.add_child(zoom_out)

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
	canvas.drawing_changed.connect(_artwork_changed)

	var choices := _panel(Color("#f7fbff"), 18)
	choices.name = "ChoicesPanel"
	choices.custom_minimum_size.x = 188
	var choices_style := choices.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	choices_style.content_margin_left = 7
	choices_style.content_margin_right = 7
	choices.add_theme_stylebox_override("panel", choices_style)
	body.add_child(choices)
	var choice_list := VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 4)
	choices.add_child(choice_list)
	choice_list.add_child(_label("PICK A COLOR", 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var colors := GridContainer.new()
	colors.columns = 3
	colors.add_theme_constant_override("h_separation", 5)
	colors.add_theme_constant_override("v_separation", 5)
	choice_list.add_child(colors)
	for i in COLORS.size():
		var swatch := _button("", Vector2(54, 54), Color(COLORS[i]))
		swatch.tooltip_text = "Color " + str(i + 1)
		swatch.pressed.connect(_select_color.bind(i))
		colors.add_child(swatch)
		color_buttons.append(swatch)
	var extra := HBoxContainer.new()
	extra.add_theme_constant_override("separation", 5)
	choice_list.add_child(extra)
	custom_button = _button("MORE COLORS", Vector2(100, 46), Color("#e4f0ff"), 12)
	custom_button.pressed.connect(_open_color_picker)
	extra.add_child(custom_button)
	glitter_button = _button("GLITTER", Vector2(67, 46), Color("#fff0be"), 12)
	glitter_button.pressed.connect(_toggle_glitter)
	extra.add_child(glitter_button)
	choice_list.add_child(_label("BRUSH SIZE", 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var sizes := HBoxContainer.new()
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	sizes.add_theme_constant_override("separation", 5)
	choice_list.add_child(sizes)
	for i in SIZES.size():
		var button := _button(["S", "M", "L"][i], Vector2(54, 48), Color.WHITE)
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
		var button := _button("", Vector2(54, 56), Color.WHITE)
		button.icon = canvas.create_stamp_icon(entry[0])
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 44)
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
	_build_saved_dialog()
	_build_settings_dialog()
	_build_setup()
	gallery = ArtGallery.new()
	add_child(gallery)

func _language_picker() -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = 54
	picker.add_item("English")
	picker.add_item("Español")
	picker.select(1 if settings_store.language == "es" else 0)
	return picker

func _build_settings_dialog() -> void:
	settings_dialog = AcceptDialog.new()
	settings_dialog.title = "Settings"
	settings_dialog.ok_button_text = "DONE"
	TouchDialog.configure(settings_dialog)
	add_child(settings_dialog)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 430
	content.add_theme_constant_override("separation", 12)
	settings_dialog.add_child(content)
	content.add_child(_label("Language", 20, Color.WHITE))
	language_picker = _language_picker()
	language_picker.item_selected.connect(_change_language)
	content.add_child(language_picker)
	content.add_child(_label("ARTISTS", 20, Color.WHITE))
	var artists := _button("Manage artists", Vector2(0, 54), GOLD, 18)
	artists.pressed.connect(_open_profiles_from_settings)
	content.add_child(artists)
	settings_message = _label("Choose language and artist profiles.", 15, Color.WHITE)
	settings_message.clip_text = true
	settings_message.custom_minimum_size.y = 25
	content.add_child(settings_message)
	settings_error_dialog = AcceptDialog.new()
	settings_error_dialog.title = "Settings"
	settings_error_dialog.ok_button_text = "OK"
	TouchDialog.configure(settings_error_dialog)
	settings_dialog.add_child(settings_error_dialog)

func _open_settings() -> void:
	language_picker.select(1 if settings_store.language == "es" else 0)
	if not settings_available:
		settings_message.text = "Could not load settings. Ask an adult for help."
	settings_dialog.reset_size()
	settings_dialog.popup_centered()
	if not settings_available:
		_show_settings_error("Could not load settings. Ask an adult for help.")

func _show_settings_error(message: String) -> void:
	settings_message.text = message
	settings_error_dialog.dialog_text = message
	settings_error_dialog.popup_centered()

func _open_profiles_from_settings() -> void:
	settings_dialog.hide()
	return_to_settings = true
	_open_profiles()

func _profile_dialog_closed() -> void:
	if return_to_settings and not profile_dialog.visible:
		return_to_settings = false
		_open_settings.call_deferred()

func _change_language(index: int) -> void:
	if not settings_available:
		_show_settings_error("Could not load settings. Ask an adult for help.")
		language_picker.select(1 if settings_store.language == "es" else 0)
		return
	var language := "es" if index == 1 else "en"
	var error := settings_store.save_settings(language, settings_store.setup_complete)
	if error != OK:
		push_error("Could not save settings: " + error_string(error))
		_show_settings_error("Could not save settings. Ask an adult for help.")
		language_picker.select(1 if settings_store.language == "es" else 0)
		return
	_apply_language(language)
	settings_message.text = "Choose language and artist profiles."

func _apply_language(language: String) -> void:
	TranslationServer.set_locale(language)
	_refresh_profile_button()
	_refresh_profile_list()
	_select_tool(selected_tool)
	if gallery.visible:
		gallery.refresh()

func _build_setup() -> void:
	setup_overlay = Control.new()
	setup_overlay.name = "SetupWizard"
	setup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	setup_overlay.hide()
	add_child(setup_overlay)
	var background := ColorRect.new()
	background.color = Color("#1757a4")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.add_child(center)
	var panel := _panel(Color("#f7fbff"), 18)
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var logo := TextureRect.new()
	logo.name = "SetupLogo"
	logo.texture = preload("res://assets/app_icon/little_leopard_canvas.png")
	logo.custom_minimum_size = Vector2(96, 96)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(logo)
	content.add_child(_label("Welcome to Little Leopard Canvas!", 26, INK, HORIZONTAL_ALIGNMENT_CENTER))
	setup_step_language = VBoxContainer.new()
	setup_step_language.add_theme_constant_override("separation", 12)
	content.add_child(setup_step_language)
	setup_step_language.add_child(_label("Choose your language.", 20, INK))
	setup_language = _language_picker()
	setup_language.item_selected.connect(_setup_language_changed)
	setup_step_language.add_child(setup_language)
	var next := _button("NEXT", Vector2(0, 54), GOLD, 18)
	next.pressed.connect(_setup_next)
	setup_step_language.add_child(next)
	setup_step_artist = VBoxContainer.new()
	setup_step_artist.add_theme_constant_override("separation", 10)
	content.add_child(setup_step_artist)
	setup_step_artist.add_child(_label("Choose or create an artist.", 20, INK))
	setup_existing = OptionButton.new()
	setup_existing.custom_minimum_size.y = 54
	setup_existing.item_selected.connect(_setup_artist_chosen)
	setup_step_artist.add_child(setup_existing)
	setup_step_artist.add_child(_label("Name", 18, INK))
	setup_name = LineEdit.new()
	setup_name.placeholder_text = "Type your name"
	setup_name.max_length = ProfileStore.MAX_NAME_LENGTH
	setup_name.custom_minimum_size.y = 54
	setup_step_artist.add_child(setup_name)
	setup_step_artist.add_child(_label("Grade", 18, INK))
	setup_grade = OptionButton.new()
	setup_grade.custom_minimum_size.y = 54
	setup_grade.add_item("Choose your grade")
	for grade in ProfileStore.GRADES:
		setup_grade.add_item(grade)
	setup_step_artist.add_child(setup_grade)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	setup_step_artist.add_child(actions)
	var back := _button("BACK", Vector2(150, 54), Color("#e4f0ff"), 18)
	back.pressed.connect(_setup_back)
	actions.add_child(back)
	var finish := _button("START DRAWING", Vector2(250, 54), GOLD, 18)
	finish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish.pressed.connect(_finish_setup)
	actions.add_child(finish)
	setup_message = _label("", 16, INK)
	setup_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(setup_message)
	setup_step_artist.hide()

func _show_setup() -> void:
	setup_overlay.show()
	setup_step_language.show()
	setup_step_artist.hide()
	setup_language.select(1 if settings_store.language == "es" else 0)

func _setup_language_changed(index: int) -> void:
	_apply_language("es" if index == 1 else "en")

func _setup_next() -> void:
	_refresh_setup_artists()
	setup_step_language.hide()
	setup_step_artist.show()
	setup_message.text = ""

func _setup_back() -> void:
	setup_step_artist.hide()
	setup_step_language.show()
	setup_message.text = ""

func _refresh_setup_artists() -> void:
	var selected := setup_existing.selected
	setup_existing.clear()
	setup_existing.add_item("NEW ARTIST")
	for artist in profile_store.profiles:
		setup_existing.add_item("%s  •  %s" % [artist["name"], tr(artist["grade"])])
	if setup_created_index >= 0:
		selected = setup_created_index + 1
	setup_existing.select(clampi(selected, 0, setup_existing.item_count - 1))
	if setup_existing.selected > 0:
		_setup_artist_chosen(setup_existing.selected)

func _setup_artist_chosen(index: int) -> void:
	setup_name.editable = index == 0
	setup_grade.disabled = index != 0
	if index > 0:
		var artist: Dictionary = profile_store.profiles[index - 1]
		setup_name.text = artist["name"]
		setup_grade.select(ProfileStore.GRADES.find(artist["grade"]) + 1)
	else:
		setup_name.clear()
		setup_grade.select(0)

func _finish_setup() -> void:
	var clean_name := setup_name.text.strip_edges()
	if clean_name.is_empty():
		setup_message.text = "Please enter your name."
		return
	if setup_grade.selected <= 0:
		setup_message.text = "Please choose your grade."
		return
	var grade: String = ProfileStore.GRADES[setup_grade.selected - 1]
	if not profile_store.valid_profile(clean_name, grade):
		setup_message.text = "Please use a name of up to 32 characters on one line."
		return
	var language := "es" if setup_language.selected == 1 else "en"
	var error := settings_store.save_settings(language, false)
	if error != OK:
		push_error("Could not save setup settings: " + error_string(error))
		setup_message.text = "Could not save settings. Ask an adult for help."
		return
	var updated: Array[Dictionary] = profile_store.profiles.duplicate(true)
	var selected := setup_existing.selected - 1
	if selected < 0:
		updated.append({"name": clean_name, "grade": grade})
		selected = updated.size() - 1
	error = profile_store.commit(updated, selected)
	if error != OK:
		push_error("Could not save setup profile: " + error_string(error))
		setup_message.text = "Could not save profiles. Ask an adult for help."
		return
	setup_created_index = selected
	error = settings_store.save_settings(language, true)
	if error != OK:
		push_error("Could not complete setup: " + error_string(error))
		setup_message.text = "Could not save settings. Ask an adult for help."
		_refresh_setup_artists()
		return
	_refresh_profile_button()
	setup_overlay.hide()

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
	TouchDialog.configure(text_dialog)
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
	TouchDialog.configure(profile_dialog)
	profile_dialog.visibility_changed.connect(_profile_dialog_closed)
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
	profile_form = VBoxContainer.new()
	profile_form.add_theme_constant_override("separation", 10)
	profile_form.hide()
	content.add_child(profile_form)
	profile_form.add_child(_label("Name", 18, Color.WHITE))
	profile_name_input = LineEdit.new()
	profile_name_input.placeholder_text = "Type your name"
	profile_name_input.max_length = ProfileStore.MAX_NAME_LENGTH
	profile_name_input.custom_minimum_size.y = 48
	profile_form.add_child(profile_name_input)
	profile_form.add_child(_label("Grade", 18, Color.WHITE))
	grade_picker = OptionButton.new()
	grade_picker.custom_minimum_size.y = 48
	grade_picker.add_item("Choose your grade")
	for grade in ProfileStore.GRADES:
		grade_picker.add_item(grade)
	profile_form.add_child(grade_picker)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	profile_form.add_child(actions)
	var save_profile := _button("SAVE PROFILE", Vector2(190, 48), GOLD)
	save_profile.pressed.connect(_save_profile)
	actions.add_child(save_profile)
	delete_profile_button = _button("DELETE", Vector2(120, 48), Color("#fff0e8"))
	delete_profile_button.pressed.connect(_ask_delete_profile)
	actions.add_child(delete_profile_button)
	profile_message = _label("Choose a profile or create a new artist.", 15, Color.WHITE)
	profile_message.clip_text = true
	content.add_child(profile_message)

func _refresh_profile_button() -> void:
	if profile_store.selected >= 0:
		var artist: Dictionary = profile_store.profiles[profile_store.selected]
		artist_caption.text = tr("ARTIST: %s  •  %s") % [artist["name"], tr(artist["grade"])]
	else:
		artist_caption.text = "ART CLUB  •  Choose an artist profile"

func _open_profiles() -> void:
	_refresh_profile_list()
	if profile_store.selected >= 0:
		_edit_profile(profile_store.selected)
	else:
		_hide_profile_form()
	if not profiles_available:
		profile_message.text = "Profiles could not be loaded. Ask an adult for help; existing data was not changed."
	profile_dialog.reset_size()
	profile_dialog.popup_centered()

func _refresh_profile_list() -> void:
	profile_picker.clear()
	profile_picker.add_item("Choose an artist")
	for entry in profile_store.profiles:
		profile_picker.add_item(entry["name"] + "  •  " + tr(entry["grade"]))
	profile_picker.select(profile_store.selected + 1)

func _new_profile() -> void:
	editing_profile = -1
	profile_name_input.text = ""
	grade_picker.select(0)
	delete_profile_button.hide()
	profile_form.show()
	profile_message.text = "Enter a name and grade, then tap Save Profile."
	if profile_store.selected >= 0:
		profile_message.text = tr("Enter a name and grade, then tap Save Profile.") + tr(" The previous artist stays selected until you save.")

func _edit_profile(index: int) -> void:
	editing_profile = index
	var entry: Dictionary = profile_store.profiles[index]
	profile_name_input.text = entry["name"]
	grade_picker.select(ProfileStore.GRADES.find(entry["grade"]) + 1)
	delete_profile_button.show()
	profile_form.show()
	profile_message.text = "This artist will sign saved artwork."

func _hide_profile_form() -> void:
	editing_profile = -1
	profile_name_input.clear()
	grade_picker.select(0)
	profile_form.hide()
	profile_message.text = "Choose a profile or create a new artist."
	if profile_dialog.visible:
		profile_dialog.reset_size()

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
		_hide_profile_form()
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
	var grade: String = ProfileStore.GRADES[grade_picker.selected - 1]
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
	_hide_profile_form()
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
	var hints := {"brush": "Brush: drag your finger to paint!", "fill": "Fill: tap an area to color it!", "stamp": "Stamp: tap to make a shape!", "eraser": "Eraser: rub away your marks!", "text": "Tap your page to place your words!", "zoom": "Tap to zoom in; drag to move. Tap the minus magnifier to zoom out."}
	status_label.text = hints[value]

func _zoom_out() -> void:
	canvas.set_zoom(canvas.zoom_factor / 2.0, canvas.zoom_center)
	status_label.text = "Zoomed out. Choose a tool to keep drawing."

func _artwork_changed() -> void:
	artwork_revision += 1

func _build_saved_dialog() -> void:
	saved_dialog = AcceptDialog.new()
	saved_dialog.title = "Artwork saved!"
	saved_dialog.ok_button_text = "KEEP DRAWING"
	TouchDialog.configure(saved_dialog)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(440, 150)
	content.add_theme_constant_override("separation", 14)
	var heading := _label("YOUR ART IS SAVED!", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(heading)
	var caption := _label("Find your masterpiece in Gallery.", 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	content.add_child(caption)
	saved_dialog.add_child(content)
	add_child(saved_dialog)
	save_error_dialog = AcceptDialog.new()
	save_error_dialog.title = "Could not finish saving"
	save_error_dialog.ok_button_text = "OK"
	TouchDialog.configure(save_error_dialog)
	add_child(save_error_dialog)

func _show_save_error(message: String) -> void:
	status_label.text = message
	save_error_dialog.dialog_text = tr(message) + "\n" + tr("Please ask an adult for help.")
	save_error_dialog.popup_centered()

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
	if artwork_revision == last_saved_revision and artist == last_saved_artist and settings_store.language == last_saved_language and FileAccess.file_exists(last_saved_path):
		saved_dialog.popup_centered()
		return
	saving_art = true
	save_button.disabled = true
	var saved_revision := artwork_revision
	var saved_language := settings_store.language
	status_label.text = "Signing your masterpiece..."
	var signed_image: Image = await canvas.create_signed_image(artist["name"], artist["grade"])
	if signed_image == null:
		saving_art = false
		save_button.disabled = false
		_show_save_error("Could not add the signature. Please try again.")
		return
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := artwork_storage_path.path_join("artwork_" + timestamp + "_" + str(Time.get_ticks_msec()) + ".png")
	var result := signed_image.save_png(path)
	if result != OK:
		saving_art = false
		save_button.disabled = false
		_show_save_error("Could not save artwork.")
		push_error("Could not save artwork: " + str(result))
		return
	var last_result := signed_image.save_png(artwork_storage_path.path_join("last_art.png"))
	last_saved_revision = saved_revision
	last_saved_artist = artist
	last_saved_path = path
	last_saved_language = saved_language
	if last_result != OK:
		saving_art = false
		save_button.disabled = false
		_show_save_error("Artwork is in Gallery, but the latest copy failed.")
		push_error("Could not save last artwork: " + str(last_result))
		return
	saving_art = false
	save_button.disabled = false
	status_label.text = "Your signed masterpiece is saved on this device!"
	saved_dialog.popup_centered()
