class_name TouchDialog
extends RefCounted

static func configure(dialog: AcceptDialog) -> void:
	var dialog_theme := Theme.new()
	var close_icon: Texture2D = preload("res://assets/ui/close_large.svg")
	var border := StyleBoxFlat.new()
	border.bg_color = Color("#123d78")
	border.set_corner_radius_all(8)
	border.expand_margin_left = 4
	border.expand_margin_right = 4
	border.expand_margin_bottom = 4
	border.expand_margin_top = 64
	dialog_theme.set_stylebox("embedded_border", "Window", border)
	dialog_theme.set_stylebox("embedded_unfocused_border", "Window", border)
	dialog_theme.set_icon("close", "Window", close_icon)
	dialog_theme.set_icon("close_pressed", "Window", close_icon)
	dialog_theme.set_font_size("title_font_size", "Window", 24)
	dialog_theme.set_color("title_color", "Window", Color.WHITE)
	dialog_theme.set_constant("title_height", "Window", 64)
	dialog_theme.set_constant("close_h_offset", "Window", 56)
	dialog_theme.set_constant("close_v_offset", "Window", 56)
	dialog_theme.set_constant("buttons_min_width", "AcceptDialog", 220)
	dialog_theme.set_constant("buttons_min_height", "AcceptDialog", 56)
	dialog.theme = dialog_theme
	dialog.get_ok_button().add_theme_font_size_override("font_size", 18)
