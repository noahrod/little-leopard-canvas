class_name ArtExport
extends RefCounted

static func save_to_android_photos(path: String) -> String:
	var runtime := Engine.get_singleton("AndroidRuntime")
	if runtime == null:
		return "Android photo export is not available on this device."
	var version := JavaClassWrapper.wrap("android.os.Build$VERSION")
	if version.SDK_INT < 29:
		return "Photo export requires Android 10 or newer on this build."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not read the saved artwork."
	var bytes := file.get_buffer(file.get_length())
	if bytes.is_empty():
		return "The saved artwork is empty."

	var activity = runtime.getActivity()
	if activity == null or JavaClassWrapper.get_exception() != null:
		return "Could not access Android photo storage."
	var resolver = activity.getContentResolver()
	if resolver == null or JavaClassWrapper.get_exception() != null:
		return "Could not access Android photo storage."
	var values_class := JavaClassWrapper.wrap("android.content.ContentValues")
	var uri_class := JavaClassWrapper.wrap("android.net.Uri")
	var integer_class := JavaClassWrapper.wrap("java.lang.Integer")
	var values = values_class.ContentValues()
	var uri = uri_class.parse("content://media/external/images/media")
	if values == null or uri == null or JavaClassWrapper.get_exception() != null:
		return "Could not prepare Android photo storage."
	values.put("_display_name", path.get_file())
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the picture name."
	values.put("mime_type", "image/png")
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the picture format."
	values.put("relative_path", "Pictures/Little Leopard Canvas")
	if JavaClassWrapper.get_exception() != null:
		return "Could not set the pictures folder."
	values.put("is_pending", integer_class.valueOf(1))
	if JavaClassWrapper.get_exception() != null:
		return "Could not prepare the picture."
	var saved_uri = resolver.insert(uri, values)
	if saved_uri == null or JavaClassWrapper.get_exception() != null:
		return "Could not create a picture in Android Photos."
	var stream = resolver.openOutputStream(saved_uri)
	if stream == null or JavaClassWrapper.get_exception() != null:
		resolver.delete(saved_uri, null, null)
		return "Could not open the picture for writing."
	stream.write(bytes)
	var write_error := JavaClassWrapper.get_exception()
	stream.close()
	var close_error := JavaClassWrapper.get_exception()
	if write_error != null or close_error != null:
		resolver.delete(saved_uri, null, null)
		return "Could not write the picture to Android Photos."
	values.clear()
	values.put("is_pending", integer_class.valueOf(0))
	if JavaClassWrapper.get_exception() != null:
		resolver.delete(saved_uri, null, null)
		return "Could not finish saving the picture."
	var updated: int = resolver.update(saved_uri, values, null, null)
	if JavaClassWrapper.get_exception() != null or updated != 1:
		resolver.delete(saved_uri, null, null)
		return "Could not finish saving the picture."
	return ""
