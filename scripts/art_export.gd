class_name ArtExport
extends RefCounted

static func save_to_android_photos(path: String) -> String:
	var runtime := Engine.get_singleton("AndroidRuntime")
	if runtime == null:
		return "Android photo export is not available on this device."
	var version := JavaClassWrapper.wrap("android.os.Build$VERSION")
	if version == null:
		return "Could not check the Android version."
	if version.SDK_INT < 29:
		return "Photo export requires Android 10 or newer on this build."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not read the saved artwork."
	var bytes := file.get_buffer(file.get_length())
	if bytes.is_empty():
		return "The saved artwork is empty."

	var activity = runtime.getActivity()
	var exception = JavaClassWrapper.get_exception()
	if exception != null or activity == null:
		return "Could not access Android photo storage."
	var resolver = activity.getContentResolver()
	exception = JavaClassWrapper.get_exception()
	if exception != null or resolver == null:
		return "Could not access Android photo storage."
	var values_class := JavaClassWrapper.wrap("android.content.ContentValues")
	var uri_class := JavaClassWrapper.wrap("android.net.Uri")
	var integer_class := JavaClassWrapper.wrap("java.lang.Integer")
	if values_class == null or uri_class == null or integer_class == null:
		return "Could not load Android photo storage."
	var values = values_class.ContentValues()
	exception = JavaClassWrapper.get_exception()
	if exception != null or values == null:
		return "Could not prepare Android photo storage."
	var uri = uri_class.parse("content://media/external/images/media")
	exception = JavaClassWrapper.get_exception()
	if exception != null or uri == null:
		return "Could not prepare Android photo storage."
	values.put("_display_name", path.get_file())
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the picture name."
	values.put("mime_type", "image/png")
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the picture format."
	values.put("relative_path", "DCIM/Camera")
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the pictures folder."
	var pending = integer_class.valueOf(1)
	if JavaClassWrapper.get_exception() != null:
		return "Could not prepare the picture."
	values.put("is_pending", pending)
	if JavaClassWrapper.get_exception() != null:
		return "Could not prepare the picture."
	var saved_uri = resolver.insert(uri, values)
	exception = JavaClassWrapper.get_exception()
	if exception != null or saved_uri == null:
		return "Could not create a picture in Android Photos."
	var stream = resolver.openOutputStream(saved_uri)
	exception = JavaClassWrapper.get_exception()
	if exception != null or stream == null:
		_remove_pending(resolver, saved_uri)
		return "Could not open the picture for writing."
	stream.write(bytes)
	var write_error := JavaClassWrapper.get_exception()
	stream.close()
	var close_error := JavaClassWrapper.get_exception()
	if write_error != null or close_error != null:
		_remove_pending(resolver, saved_uri)
		return "Could not write the picture to Android Photos."
	values.clear()
	if JavaClassWrapper.get_exception() != null:
		_remove_pending(resolver, saved_uri)
		return "Could not finish saving the picture."
	pending = integer_class.valueOf(0)
	if JavaClassWrapper.get_exception() != null:
		_remove_pending(resolver, saved_uri)
		return "Could not finish saving the picture."
	values.put("is_pending", pending)
	if JavaClassWrapper.get_exception() != null:
		_remove_pending(resolver, saved_uri)
		return "Could not finish saving the picture."
	var updated: int = resolver.update(saved_uri, values, null, null)
	if JavaClassWrapper.get_exception() != null or updated != 1:
		_remove_pending(resolver, saved_uri)
		return "Could not finish saving the picture."
	return ""

static func _remove_pending(resolver, uri) -> void:
	var removed: int = resolver.delete(uri, null, null)
	if JavaClassWrapper.get_exception() != null or removed != 1:
		push_error("Could not remove the incomplete Android picture.")
