class_name SettingsStore
extends RefCounted

var path: String
var language := "en"
var setup_complete := false

func _init(storage_path: String = "user://settings.cfg") -> void:
	path = storage_path

func load_settings(existing_install: bool) -> Error:
	if not FileAccess.file_exists(path):
		setup_complete = existing_install
		return OK
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return error
	var saved_language: Variant = config.get_value("settings", "language")
	var saved_setup: Variant = config.get_value("settings", "setup_complete")
	if not saved_language is String or saved_language not in ["en", "es"] or not saved_setup is bool:
		return ERR_FILE_CORRUPT
	language = saved_language
	setup_complete = saved_setup
	return OK

func save_settings(new_language: String, completed: bool) -> Error:
	if new_language not in ["en", "es"]:
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	config.set_value("settings", "language", new_language)
	config.set_value("settings", "setup_complete", completed)
	var temporary := path + ".tmp"
	var error := config.save(temporary)
	if error != OK:
		return error
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error == OK:
		language = new_language
		setup_complete = completed
	return error
