extends Control

const APP_ICON: Texture2D = preload("res://assets/app_icon/little_leopard_canvas.png")

var profile_name := ""
var grade := ""
var caption := "LITTLE LEOPARD ARTIST"
var pride := "Made with pride!"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#fff9e6"))
	draw_rect(Rect2(0, 0, size.x, 3), Color("#ffcf40"))
	draw_texture_rect(APP_ICON, Rect2(16, 8, 64, 64), false)
	var font := get_theme_default_font()
	draw_string(font, Vector2(92, 34), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#1857a4"))
	draw_string(font, Vector2(92, 59), pride, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#1857a4"))
	var text := profile_name + "  •  " + grade
	var font_size := 24
	while font_size > 12 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 500:
		font_size -= 1
	draw_string(font, Vector2(size.x - 526, 48), text, HORIZONTAL_ALIGNMENT_RIGHT, 500, font_size, Color("#15365d"))
