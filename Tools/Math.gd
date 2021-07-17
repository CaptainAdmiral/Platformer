extends Node

class_name Math

static func get_nearest_to_point(point : Vector2, collection) -> Node2D:
	var nearest : Node2D = null
	var dist = -1
	var nearestDist = dist
	
	for node in collection:
		if nearest == null:
			nearest = node
			nearestDist = point.distance_to((node as Node2D).global_position)
			continue
			
		dist = point.distance_to((node as Node2D).global_position)
		
		if dist < nearestDist:
			nearest = node
			nearestDist = dist
			continue
			
	return nearest
