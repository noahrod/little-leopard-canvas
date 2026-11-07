class_name ProfileStore
extends RefCounted

const GRADES := ["4K", "5K", "1st", "2nd", "3rd", "4th", "5th"]
const MAX_NAME_LENGTH := 32

var path: String
var profiles: Array[Dictionary] = []
var selected := -1

func _init(storage_path: String = "user://profiles.json") -> void:
	path = storage_path

func load_profiles() -> Error:
	if not FileAccess.file_exists(path):
		return OK
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return ERR_PARSE_ERROR
	var data: Variant = json.data
	if not data is Dictionary or not data.get("profiles") is Array:
		return ERR_FILE_CORRUPT
	var selection: Variant = data.get("selected")
	if not (selection is int or selection is float) or not is_finite(float(selection)) or float(selection) != floorf(float(selection)):
		return ERR_FILE_CORRUPT
	var loaded: Array[Dictionary] = []
	for entry in data["profiles"]:
		if not entry is Dictionary or not entry.get("name") is String or not entry.get("grade") is String:
			return ERR_FILE_CORRUPT
		if not valid_profile(entry["name"], entry["grade"]):
			return ERR_FILE_CORRUPT
		loaded.append({"name": entry["name"], "grade": entry["grade"]})
	var saved_selected := int(selection)
	if saved_selected < -1 or saved_selected >= loaded.size():
		return ERR_FILE_CORRUPT
	profiles = loaded
	selected = saved_selected
	return OK

func valid_profile(profile_name: String, grade: String) -> bool:
	var clean_name := profile_name.strip_edges()
	return not clean_name.is_empty() and clean_name.length() <= MAX_NAME_LENGTH and clean_name.find("\n") == -1 and clean_name.find("\r") == -1 and grade in GRADES

func commit(new_profiles: Array[Dictionary], new_selected: int) -> Error:
	if new_selected < -1 or new_selected >= new_profiles.size():
		return ERR_INVALID_PARAMETER
	for entry in new_profiles:
		if not entry.has("name") or not entry.has("grade") or not entry["name"] is String or not entry["grade"] is String:
			return ERR_INVALID_PARAMETER
		if not valid_profile(entry["name"], entry["grade"]):
			return ERR_INVALID_PARAMETER
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"profiles": new_profiles, "selected": new_selected}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		return error
	profiles = new_profiles.duplicate(true)
	selected = new_selected
	return OK
