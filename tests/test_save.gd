extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := "user://save_test_%s" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(folder)) == OK)
	var scene: Control = load("res://main.tscn").instantiate()
	scene.suppress_setup = true
	scene.settings_store = SettingsStore.new(folder.path_join("settings.cfg"))
	root.add_child(scene)
	await process_frame
	scene.artwork_storage_path = folder
	scene.profile_store.profiles.clear()
	scene.profile_store.profiles.append({"name": "Alex", "grade": "4K"})
	scene.profile_store.selected = 0
	scene.canvas.set_page(null)
	scene._on_save()
	assert(scene.saving_art and scene.save_button.disabled)
	scene._on_save()
	await process_frame
	await process_frame
	assert(not scene.saving_art and scene.saved_dialog.visible)
	var first_path: String = scene.last_saved_path
	assert(FileAccess.file_exists(first_path))
	assert(Image.load_from_file(first_path).get_size() == Vector2i(840, 600))
	scene.saved_dialog.hide()
	scene._on_save()
	assert(scene.saved_dialog.visible and scene.last_saved_path == first_path)
	assert(DirAccess.get_files_at(folder).size() == 2)
	scene.saved_dialog.hide()
	scene.canvas.set_color(Color.RED)
	scene.canvas._start(scene.canvas.size / 2)
	scene.canvas._finish()
	await scene._on_save()
	var second_path: String = scene.last_saved_path
	assert(first_path != second_path and FileAccess.file_exists(second_path))
	assert(Image.load_from_file(second_path).get_pixel(420, 260).is_equal_approx(Color.RED))
	scene.saved_dialog.hide()
	scene.profile_store.profiles[0] = {"name": "Alex", "grade": "5K"}
	await scene._on_save()
	var third_path: String = scene.last_saved_path
	assert(third_path != second_path and FileAccess.file_exists(third_path))
	scene.saved_dialog.hide()
	scene.canvas.set_zoom(2.0, Vector2(630, 260))
	scene.canvas._start(scene.canvas.size / 2)
	scene.canvas._finish()
	scene._on_save()
	scene.canvas.set_color(Color.BLUE)
	scene.canvas._start(scene.canvas.size / 4)
	scene.canvas._finish()
	await process_frame
	await process_frame
	var fourth_path: String = scene.last_saved_path
	assert(FileAccess.file_exists(fourth_path))
	assert(Image.load_from_file(fourth_path).get_pixel(525, 195).is_equal_approx(Color.WHITE))
	scene.saved_dialog.hide()
	await scene._on_save()
	var fifth_path: String = scene.last_saved_path
	assert(fifth_path != fourth_path)
	assert(Image.load_from_file(fifth_path).get_pixel(525, 195).is_equal_approx(Color.BLUE))
	scene.saved_dialog.hide()
	scene._change_language(1)
	await scene._on_save()
	var spanish_path: String = scene.last_saved_path
	assert(spanish_path != fifth_path)
	var english_image := Image.load_from_file(fifth_path)
	var spanish_image := Image.load_from_file(spanish_path)
	var differences := 0
	for y in range(520, 600):
		for x in range(92, 310):
			if not english_image.get_pixel(x, y).is_equal_approx(spanish_image.get_pixel(x, y)):
				differences += 1
	assert(differences > 40)
	scene.saved_dialog.hide()
	scene._change_language(0)
	scene.artwork_storage_path = folder.path_join("missing")
	scene.canvas.clear_drawing()
	await scene._on_save()
	assert(not scene.saved_dialog.visible and scene.save_error_dialog.visible and not scene.saving_art and not scene.save_button.disabled)
	assert(scene.status_label.text.contains("Could not save"))
	for path in [first_path, second_path, third_path, fourth_path, fifth_path, spanish_path, folder.path_join("last_art.png"), folder.path_join("settings.cfg")]:
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(folder)) == OK)
	print("Save feedback and duplicate prevention tests passed.")
	quit()
