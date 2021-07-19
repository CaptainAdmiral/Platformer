extends Projectile

var max_speed = 2000
var acceleration = 100


func _physics_process(delta):
	var dir = motion.normalized()
	if motion.length() < max_speed:
		motion += dir*acceleration
