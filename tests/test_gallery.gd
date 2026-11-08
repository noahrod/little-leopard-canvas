extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := "user://gallery_test_%s" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(folder)) == OK)
	var scene: Control = load("res://main.tscn").instantiate()
	scene.suppress_setup = true
	root.add_child(scene)
	await process_frame
	await process_frame
	var gallery: ArtGallery = scene.gallery
	assert(gallery.theme.get_icon("close", "Window").get_width() >= 48)
	assert(gallery.theme.get_constant("buttons_min_height", "AcceptDialog") >= 54)
	assert(scene.profile_dialog.theme.get_icon("close", "Window").get_width() >= 48)
	assert(scene.profile_dialog.theme.get_constant("buttons_min_height", "AcceptDialog") >= 54)
	for dialog in [gallery, scene.profile_dialog]:
		var title_height: int = dialog.theme.get_constant("title_height", "Window")
		var close_y: int = dialog.theme.get_constant("close_v_offset", "Window")
		var close_x: int = dialog.theme.get_constant("close_h_offset", "Window")
		var close_size: Vector2 = dialog.theme.get_icon("close", "Window").get_size()
		var border: StyleBoxFlat = dialog.theme.get_stylebox("embedded_border", "Window")
		assert(title_height >= 64 and border.expand_margin_top >= title_height)
		assert(close_y <= title_height and close_y >= close_size.y)
		assert(close_x >= close_size.x)
		assert(dialog.theme.get_font_size("title_font_size", "Window") >= 24)
	gallery.storage_path = folder
	var canvas: DrawingCanvas = scene.canvas
	canvas.set_page(null)
	canvas.artwork.set_pixel(50, 50, Color.RED)
	scene._open_gallery()
	await process_frame
	await process_frame
	assert(gallery.get_ok_button().size.y >= 54)
	assert(gallery.files.is_empty())
	assert(gallery.message.text.contains("No artwork yet"))
	assert(gallery.previous_button.disabled and gallery.next_button.disabled)
	assert(gallery.export_button.disabled)
	assert(gallery.size.y <= 900)
	assert(gallery.next_button.get_global_rect().end.y < gallery.size.y)

	var old := Image.create(20, 10, false, Image.FORMAT_RGBA8)
	old.fill(Color.RED)
	var recent := Image.create(20, 12, false, Image.FORMAT_RGBA8)
	recent.fill(Color.BLUE)
	var old_path := folder.path_join("artwork_2020-01-01T00-00-00.png")
	var new_path := folder.path_join("artwork_2025-01-01T00-00-00_10.png")
	var unrelated_path := folder.path_join("last_art.png")
	assert(old.save_png(old_path) == OK)
	assert(recent.save_png(new_path) == OK)
	assert(recent.save_png(unrelated_path) == OK)
	gallery.refresh()
	assert(gallery.files.size() == 2)
	assert(gallery.files[0]["path"] == new_path)
	assert(gallery.current_index == 0)
	assert(gallery.previous_button.disabled and not gallery.next_button.disabled)
	assert(gallery.preview.texture.get_image().get_pixel(0, 0).is_equal_approx(Color.BLUE))
	assert(not gallery.export_button.disabled)
	var exported_path := ProjectSettings.globalize_path(folder.path_join("exported.png"))
	gallery._export_to_path(exported_path)
	assert(FileAccess.file_exists(exported_path))
	assert(Image.load_from_file(exported_path).get_pixel(0, 0).is_equal_approx(Color.BLUE))
	gallery._show_next()
	assert(gallery.current_index == 1)
	assert(not gallery.previous_button.disabled and gallery.next_button.disabled)
	assert(gallery.preview.texture.get_image().get_pixel(0, 0).is_equal_approx(Color.RED))
	gallery._show_previous()
	assert(gallery.current_index == 0)
	assert(canvas.artwork.get_pixel(50, 50).is_equal_approx(Color.RED))

	var invalid_path := folder.path_join("artwork_2030-01-01T00-00-00.png")
	var bad_file := FileAccess.open(invalid_path, FileAccess.WRITE)
	bad_file.store_string("not a png")
	bad_file.close()
	gallery.refresh()
	assert(gallery.files.size() == 3)
	assert(gallery.preview.texture == null)
	assert(gallery.export_button.disabled)
	assert(gallery.message.text.contains("could not be opened"))
	gallery._show_next()
	assert(gallery.preview.texture != null)
	gallery.hide()
	assert(canvas.artwork.get_pixel(50, 50).is_equal_approx(Color.RED))

	for path in [old_path, new_path, unrelated_path, invalid_path, exported_path]:
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(folder)) == OK)
	print("Gallery tests passed.")
	quit()
