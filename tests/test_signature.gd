extends SceneTree

const CanvasScript = preload("res://scripts/drawing_canvas.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var canvas: DrawingCanvas = CanvasScript.new()
	root.add_child(canvas)
	await process_frame
	canvas.set_page(null)
	canvas.artwork.set_pixel(20, 20, Color.RED)
	var signed: Image = await canvas.create_signed_image("Alex", "4K")
	assert(signed != null)
	assert(signed.get_size() == Vector2i(canvas.WIDTH, canvas.HEIGHT + 80))
	assert(signed.get_pixel(20, 20).is_equal_approx(Color.RED))
	assert(not signed.get_pixel(48, canvas.HEIGHT + 40).is_equal_approx(Color("#fff9e6")))
	assert(canvas.artwork.get_size() == Vector2i(canvas.WIDTH, canvas.HEIGHT))
	var second: Image = await canvas.create_signed_image("Renée", "4K")
	assert(second != null)
	var differences := 0
	for y in range(canvas.HEIGHT + 10, canvas.HEIGHT + 70):
		for x in range(310, 820):
			if not signed.get_pixel(x, y).is_equal_approx(second.get_pixel(x, y)):
				differences += 1
	assert(differences > 40)
	var third: Image = await canvas.create_signed_image("Alex", "5th")
	assert(third != null)
	differences = 0
	for y in range(canvas.HEIGHT + 10, canvas.HEIGHT + 70):
		for x in range(310, 820):
			if not signed.get_pixel(x, y).is_equal_approx(third.get_pixel(x, y)):
				differences += 1
	assert(differences > 20)
	var path := "user://signature_test_%s.png" % Time.get_ticks_usec()
	assert(signed.save_png(path) == OK)
	var saved := Image.load_from_file(path)
	assert(saved.get_size() == signed.get_size())
	assert(saved.get_pixel(20, 20).is_equal_approx(Color.RED))
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	print("Signature rendering tests passed.")
	quit()
