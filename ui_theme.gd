extends RefCounted
class_name UITheme
# Every color used by code-built UI lives here

const PANEL_BG = Color(0.10, 0.09, 0.08, 0.88)
const PANEL_BORDER = Color(0.80, 0.66, 0.36, 1.0)
const TEXT = Color(0.95, 0.92, 0.85, 1.0)
const TEXT_MUTED = Color(0.72, 0.69, 0.62, 1.0)
const TEXT_OUTLINE = Color(0, 0, 0, 1)
const ALERT = Color(1.0, 0.55, 0.45, 1.0)
const BOOT_BG = Color(0.141, 0.141, 0.141, 1.0)
const FONT = preload("res://fonts/mainFont.ttf")


static func panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	return style


static func style_label(label, size, color = TEXT):
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
