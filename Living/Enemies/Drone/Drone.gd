extends Living


const MAX_AGRO_RANGE : float = 1500.0
var driftSpeed = 20
var attackAcceleration = 40
var attackingFrames : int = 0

var target : Living = null


# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(3)
	fallSpeed = 0
	canBePulled = true
	knockbackMultiplier = 1.5
	motion = Vector2(driftSpeed, 0).rotated(rng.randf_range(0, 2*PI))
	$AnimatedSprite.frame = rng.randi()%5+1


func _physics_process(delta):
	if attackingFrames:
		attackingFrames -= 1
	
	if motion.length() > driftSpeed:
		motion *= 0.9
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE:
		target = null
		$AnimatedSprite.play("idle")
		
	if $WallDetector.is_colliding():
		var dist = max (100, global_position.distance_to($WallDetector.get_collision_point()))
		motion-= 1000*global_position.direction_to($WallDetector.get_collision_point())/dist
		
	$WallDetector.rotate(2*PI/16)
		
	if !attackingFrames:
		for drone in get_tree().get_nodes_in_group("drones"):
			if drone == self:
				continue
			var dist = max(20, global_position.distance_squared_to(drone.global_position))
			motion -= 150000*global_position.direction_to(drone.global_position)/dist
			
	if target != null:
		var maxDist = 800
		var dist = max(400, global_position.distance_to(target.global_position))*1.2
		var speedMultiplier = 1 if !attackingFrames else 2
		motion += attackAcceleration*global_position.direction_to(target.global_position) * speedMultiplier
		if !attackingFrames:
			motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position)/dist
		
		if attackingFrames == 1:
			for body in $AttackArea.get_overlapping_bodies():
				var player = body
				var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
				if player.hurt(damage):
					player.addKnockback(Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
		
		if !attackingFrames and rng.randi()%300 == 0:
			$AnimatedSprite.play("attack")
			$AnimatedSprite.frame = 0
			attackingFrames = 60


func _on_DetectionArea_body_entered(body):
	if target != null:
		return
	if body.is_in_group("players"):
		target = body
		$AnimatedSprite.play("agro")


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("agro")
