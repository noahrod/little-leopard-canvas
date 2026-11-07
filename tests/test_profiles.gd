extends SceneTree

const Store = preload("res://scripts/profile_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test_path := "user://profile_test_%s.json" % Time.get_ticks_usec()
	var store := Store.new(test_path)
	assert(store.load_profiles() == OK)
	assert(store.profiles.is_empty())
	assert(store.selected == -1)
	assert(not store.valid_profile("   ", "4K"))
	assert(not store.valid_profile("Artist", "6th"))
	assert(not store.valid_profile("A\nB", "4K"))
	for grade in Store.GRADES:
		assert(store.valid_profile("Renée", grade))
	var profiles: Array[Dictionary] = [
		{"name": "Renée", "grade": "4K"},
		{"name": "Alex", "grade": "5th"}
	]
	assert(store.commit(profiles, 1) == OK)
	var reloaded := Store.new(test_path)
	assert(reloaded.load_profiles() == OK)
	assert(reloaded.profiles == profiles)
	assert(reloaded.selected == 1)
	profiles[0] = {"name": "Renée", "grade": "5K"}
	assert(reloaded.commit(profiles, 0) == OK)
	var again := Store.new(test_path)
	assert(again.load_profiles() == OK)
	assert(again.profiles[0]["grade"] == "5K")
	assert(again.selected == 0)
	profiles.remove_at(0)
	assert(again.commit(profiles, -1) == OK)
	assert(again.commit([{"name": "", "grade": "4K"}], 0) == ERR_INVALID_PARAMETER)
	assert(again.profiles.size() == 1)
	var corrupt := FileAccess.open(test_path, FileAccess.WRITE)
	corrupt.store_string("not json")
	corrupt.close()
	assert(Store.new(test_path).load_profiles() == ERR_PARSE_ERROR)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path)) == OK)

	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.profile_store = Store.new(test_path)
	scene._refresh_profile_button()
	scene._open_profiles()
	scene.profile_name_input.text = "Jordan"
	scene.grade_picker.select(0)
	scene._save_profile()
	assert(scene.profile_store.profiles.is_empty())
	assert(scene.profile_message.text.contains("grade"))
	scene.grade_picker.select(1)
	scene._save_profile()
	assert(scene.profile_store.selected == 0)
	assert(scene.artist_caption.text.contains("Jordan"))
	scene._new_profile()
	scene.profile_name_input.text = "Taylor"
	scene.grade_picker.select(7)
	scene._save_profile()
	assert(scene.profile_store.selected == 1)
	assert(scene.profile_picker.item_count == 3)
	scene._profile_chosen(1)
	assert(scene.profile_store.selected == 0)
	scene.profile_name_input.text = "Jordan R"
	scene._save_profile()
	assert(scene.profile_store.profiles[0]["name"] == "Jordan R")
	scene._delete_profile()
	assert(scene.profile_store.selected == -1)
	assert(scene.profile_store.profiles.size() == 1)
	var ui_saved := Store.new(test_path)
	assert(ui_saved.load_profiles() == OK)
	assert(ui_saved.profiles[0]["name"] == "Taylor")
	assert(ui_saved.selected == -1)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path)) == OK)
	scene.queue_free()
	print("Profile persistence tests passed.")
	quit()
