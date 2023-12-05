class_name ImageLoader
extends Node

static func load_image(file_path: String, crop_transparent := true):
	var image = Image.load_from_file(file_path)
	if image == null:
		print("ImageLoader: failed to get file at ", file_path)
		return null;

	# crops image to first visible pixels on every side
	# helps minimize small note skins + more compatibility with osu skins
	if crop_transparent and not image.is_invisible():
		image = image.get_region(image.get_used_rect())

	return ImageTexture.create_from_image(image)
