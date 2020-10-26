extends Object

func _init():
	push_error("Attempting to initialize helper class")

static func makeAttackRayCast(var attacker, var from : Vector2, var to : Vector2, var exceptions, var collisionMask, var damage : Damage):
	var collisions = []
	var collision = attacker.get_world_2d().direct_space_state.intersect_ray(from, to, exceptions, collisionMask)
	while collision and damage.canDodge and "isDodging" in collision.collider and collision.collider.isDodging:
		exceptions.append(collision.collider)
		collision = attacker.get_world_2d().direct_space_state.intersect_ray(from, to, exceptions, collisionMask)
	
	collisions.append(collision)
	if collision and damage.canParry and "isParrying" in collision.collider and collision.collider.isParrying:
		var direction
		if collision.collider.has_method("getParryDirection"):
			direction = collision.collider.getParryDirection()
		else:
			direction = collision.position.direction_to(attacker.global_position)
		var length = (to - from).length()
		exceptions.erase(attacker)
		exceptions.append(collision.collider)
		var canParry = damage.canParry
		damage.canParry = false
		collisions += makeAttackRayCast(collision.collider, collision.position, collision.position+length*direction, exceptions, 4, damage)
		damage.canParry = true

	return collisions
