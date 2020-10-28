extends Object

static func pos_to_screen_coords(local_pos : Vector2, viewport : Viewport):
	return viewport.get_canvas_transform() * (viewport.get_global_canvas_transform()  * local_pos)

static func screen_coords_to_screen_ratio(sc : Vector2, viewport : Viewport):
	return sc / viewport.size
	
static func pos_to_screen_ratio(local_pos : Vector2, viewport : Viewport):
	return screen_coords_to_screen_ratio(pos_to_screen_coords(local_pos, viewport), viewport)
