extends Living


const MAX_AGRO_RANGE : float = 1500.0
var driftSpeed = 20
var attackAcceleration = 30

var target : Living = null


# Called when the node enters the scene tree for the first time.
func _ready():
	maxHealth = 3
	health = maxHealth
	fallSpeed = 0
	canBePulled = true
	knockbackMultiplier = 1.5
	motion = Vector2(driftSpeed, 0).rotated(rng.randf_range(0, 2*PI))
	$AnimatedSprite.frame = rng.randi()%5+1


func _physics_process(delta):
	if motion.length() > driftSpeed:
		motion *= 0.9
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE:
		target = null
		$AnimatedSprite.play("idle")
		
	if $WallDetector.is_colliding():
		var dist = max (100, global_position.distance_to($WallDetector.get_collision_point()))
		motion-= 1000*global_position.direction_to($WallDetector.get_collision_point())/dist
		
	$WallDetector.rotate(2*PI/16)
		
	for drone in get_tree().get_nodes_in_group("drones"):
		if drone == self:
			continue
		var dist = max(20, global_position.distance_squared_to(drone.global_position))
		motion -= 200000*global_position.direction_to(drone.global_position)/dist
			
	if target != null:
		var maxDist = 600
		var dist = max(300, global_position.distance_to(target.global_position))*1.2
		motion += attackAcceleration*global_position.direction_to(target.global_position)
		motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position)/dist


func _on_DetectionArea_body_entered(body):
	if body.is_in_group("players"):
		target = body
		$AnimatedSprite.play("agro")
