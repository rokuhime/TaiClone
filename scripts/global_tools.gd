class_name GlobalTools


## Comment
static func get_event(key: String) -> InputEvent:
	return InputMap.get_action_list(key)[0]


## Comment
static func get_alpha_texture(file_path: String, alpha_color: Color) -> Texture:
	## Comment
	var image := get_image_texture(file_path).get_data()

	image.convert(Image.FORMAT_RGBA8)
	image.lock()
	for row in range(image.get_height()):
		for column in range(image.get_width()):
			## Comment
			var pixel := image.get_pixel(column, row)

			image.set_pixel(column, row, (Color.transparent if pixel == Color.white or pixel.a < 1 else Color.white) if alpha_color == Color.black else Color(1, 1, 1, min(pixel.a, 1 - (abs(alpha_color.r - pixel.r) + abs(alpha_color.g - pixel.g) + abs(alpha_color.b - pixel.b)) / 3)))

	## Comment
	var new_texture := ImageTexture.new()

	new_texture.create_from_image(image)
	return new_texture


## Comment
static func get_edge_texture(image: Image, copy_image: Image) -> Texture:
	image.blit_rect(copy_image, Rect2(16, 0, 16, 32), Vector2(16, 0))

	## Comment
	var new_texture := ImageTexture.new()

	new_texture.create_from_image(image)
	return new_texture


## Comment
static func get_image_texture(file_path: String, crop_transparent := true) -> Texture:
	## Comment
	var image := Image.new()

	## Comment
	var new_texture := ImageTexture.new()

	if file_path.begins_with("res://"):
		image = (load(file_path) as Texture).get_data()

	elif image.load(file_path):
		return new_texture

	if crop_transparent and not image.is_invisible():
		image = image.get_rect(image.get_used_rect())

	new_texture.create_from_image(image)
	return new_texture


## Comment
static func inputs_empty(inputs: Array) -> bool:
	return int(inputs[0]) > inputs.size()


## Comment
static func send_signal(signal_target: Node, signal_name: String, obj: Object, method: String) -> void:
	if obj.connect(signal_name, signal_target, method):
		push_warning("Attempted to connect %s %s." % [obj.get_class(), signal_name])
