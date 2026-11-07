class_name ArtGallery
extends AcceptDialog

var storage_path := "user://"
var files: Array[Dictionary] = []
var current_index := -1
var preview: TextureRect
var message: Label
var previous_button: Button
var next_button: Button

func _ready() -> void:
	title = "My Art Gallery"
	ok_button_text = "BACK TO DRAWING"
	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(740, 540)
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)

	var title_label := Label.new()
	title_label.text = "YOUR MASTERPIECES"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	layout.add_child(title_label)

	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(720, 410)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(preview)

	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 42
	layout.add_child(message)

	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 24)
	layout.add_child(navigation)
	previous_button = Button.new()
	previous_button.text = "◀  NEWER"
	previous_button.custom_minimum_size = Vector2(180, 54)
	previous_button.pressed.connect(_show_previous)
	navigation.add_child(previous_button)
	next_button = Button.new()
	next_button.text = "OLDER  ▶"
	next_button.custom_minimum_size = Vector2(180, 54)
	next_button.pressed.connect(_show_next)
	navigation.add_child(next_button)

func open_gallery() -> void:
	refresh()
	popup_centered()

func refresh() -> void:
	files.clear()
	current_index = -1
	preview.texture = null
	var directory := DirAccess.open(storage_path)
	if directory == null:
		var error := DirAccess.get_open_error()
		push_error("Could not open artwork gallery: " + error_string(error))
		message.text = "Could not open your gallery. Ask an adult for help."
		_update_navigation()
		return
	var error := directory.list_dir_begin()
	if error != OK:
		push_error("Could not list artwork gallery: " + error_string(error))
		message.text = "Could not open your gallery. Ask an adult for help."
		_update_navigation()
		return
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.begins_with("artwork_") and filename.ends_with(".png"):
			var path := storage_path.path_join(filename)
			files.append({"name": filename, "path": path, "modified": FileAccess.get_modified_time(path)})
		filename = directory.get_next()
	directory.list_dir_end()
	files.sort_custom(_newer_first)
	if files.is_empty():
		message.text = "No artwork yet! Save a masterpiece and it will appear here."
		_update_navigation()
		return
	_show_artwork(0)

func _newer_first(a: Dictionary, b: Dictionary) -> bool:
	if a["modified"] != b["modified"]:
		return a["modified"] > b["modified"]
	return a["name"] > b["name"]

func _show_artwork(index: int) -> void:
	if index < 0 or index >= files.size():
		return
	current_index = index
	preview.texture = null
	var image := Image.new()
	var error := image.load(files[index]["path"])
	if error != OK or image.is_empty():
		push_error("Could not load artwork %s: %s" % [files[index]["name"], error_string(error)])
		message.text = "Picture %d of %d could not be opened. Try another picture." % [index + 1, files.size()]
	else:
		preview.texture = ImageTexture.create_from_image(image)
		message.text = "Picture %d of %d  •  Newest first" % [index + 1, files.size()]
	_update_navigation()

func _update_navigation() -> void:
	previous_button.disabled = current_index <= 0
	next_button.disabled = current_index < 0 or current_index >= files.size() - 1

func _show_previous() -> void:
	_show_artwork(current_index - 1)

func _show_next() -> void:
	_show_artwork(current_index + 1)
