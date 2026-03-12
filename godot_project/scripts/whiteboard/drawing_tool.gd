class_name DrawingTool
extends RefCounted
## Stateless drawing utilities for the whiteboard canvas.

const COLORS := {
	"black": Color.BLACK,
	"red": Color(0.9, 0.2, 0.2),
	"blue": Color(0.2, 0.4, 0.9),
	"green": Color(0.2, 0.7, 0.3),
}


static func draw_circle_on_image(img: Image, center: Vector2, radius: int, color: Color) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var px = int(center.x) + dx
				var py = int(center.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)


static func draw_line_on_image(img: Image, from: Vector2, to: Vector2, size: int, color: Color) -> void:
	var x0 = int(from.x)
	var y0 = int(from.y)
	var x1 = int(to.x)
	var y1 = int(to.y)
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		draw_circle_on_image(img, Vector2(x0, y0), size / 2, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


static func draw_grid(img: Image, spacing: int, color: Color) -> void:
	for x in range(0, img.get_width(), spacing):
		for y in range(img.get_height()):
			img.set_pixel(x, y, color)
	for y in range(0, img.get_height(), spacing):
		for x in range(img.get_width()):
			img.set_pixel(x, y, color)
