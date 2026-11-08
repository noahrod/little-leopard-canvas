extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Control = load("res://main.tscn").instantiate()
	scene.suppress_setup = true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.canvas.set_page(null)
	scene.canvas.set_color(Color.RED)
	scene.text_input.text = "Hello!"
	await scene._prepare_text()
	assert(scene.canvas.tool == "text")
	assert(scene.canvas.text_image != null and not scene.canvas.text_image.is_empty())
	var before: Image = scene.canvas.artwork.duplicate()
	scene.canvas._start(scene.canvas.size / 2)
	var changed := 0
	for y in range(scene.canvas.HEIGHT):
		for x in range(scene.canvas.WIDTH):
			if not scene.canvas.artwork.get_pixel(x, y).is_equal_approx(before.get_pixel(x, y)):
				changed += 1
	assert(changed > 50)
	scene.canvas.undo()
	assert(scene.canvas.artwork.get_data() == before.get_data())
	assert(scene.canvas.fill_image.get_data() == before.get_data())
	scene.canvas._start(Vector2(scene.canvas.size.x - 1, 1))
	assert(scene.canvas.history.size() == 1)
	scene.canvas.undo()
	print("Text placement tests passed.")
	quit()
