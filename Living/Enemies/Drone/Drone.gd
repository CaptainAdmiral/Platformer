extends Living

const MAX_AGRO_RANGE : float = 2000.0
const PATROL_RANGE : float = 1000.0

var patrolPoint : Vector2 = Vector2()

var driftSpeed : float = 20
var attackAcceleration : float = 50
var nearHover = false

var target : Living = null

var attackPosition : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(3)
	fallSpeed = 0
	knockbackMultiplier = 2
	manaOnKill = 10
	motion = Vector2(driftSpeed, 0).rotated(rand_range(0, 2*PI))
	$AnimatedSprite.frame = randi()%5+1
	
	patrolPoint = global_position
	
func _process(delta):
	if target != null:
		update()

func _physics_process(delta):
	if motion.length() > driftSpeed:
		motion *= 0.9
		
	if target == null and patrolPoint.distance_to(global_position) > PATROL_RANGE:
		var randAng = rand_range(0, 2*PI)
		var newPos = patrolPoint + rand_range(0, 1)*PATROL_RANGE*Vector2(cos(randAng), sin(randAng))
		motion = driftSpeed*global_position.direction_to(newPos)
		
		
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE and !($FrameCounter/AttackTargeting.active() or $FrameCounter/Attack.active()):
		target = null
		$AnimatedSprite.play("idle")
		update()
		
	if $WallDetector.is_colliding():
		var dist = max(100, global_position.distance_squared_to($WallDetector.get_collision_point()))
		motion -= 1000000*global_position.direction_to($WallDetector.get_collision_point())/dist
		
	$WallDetector.rotate(2.1*PI/10)
		
	for drone in get_tree().get_nodes_in_group("drones"):
		if drone == self:
			continue
		
		if target == null:
			var dist = max(20, global_position.distance_squared_to(drone.global_position))
			motion -= 1000*global_position.direction_to(drone.global_position)/dist
		else:
			var dist = max(800, global_position.distance_squared_to(drone.global_position))
			motion -= 800000*global_position.direction_to(drone.global_position)/dist
			
	if target != null:
		if randi()%200 == 0:
			nearHover = !nearHover
		var maxDist = 400 if nearHover else 800
		var dist = max(400, global_position.distance_to(target.global_position))
		motion += attackAcceleration*global_position.direction_to(target.global_position)
		motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position)/dist
		
		if $FrameCounter/Attack.justFinished:
			for body in $AttackArea.get_overlapping_bodies():
				var player = body
				var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
				if player.hurt(damage):
					player.addKnockback(global_position.direction_to(player.global_position)*1200, true)
			$FrameCounter/AttackCooldown.start()
			$FrameCounter/AttackCooldown.addFrames(randi()%420)
		
		if $FrameCounter/AttackCooldown.justFinished:
			$FrameCounter/AttackTargeting.start()
			
		if $FrameCounter/AttackTargeting.justFinished:
			$AnimatedSprite.play("attack")
			$AnimatedSprite.frame = 0
			$FrameCounter/Attack.start()
			var collision = get_world_2d().direct_space_state.intersect_ray(global_position, global_position + global_position.direction_to(target.global_position)*30000, [self, target], 3)
			if collision:
				attackPosition = collision.position
			else:
				attackPosition = global_position.direction_to(target.global_position)*30000
				
		if $FrameCounter/Attack.justFinished:
			var collision = get_world_2d().direct_space_state.intersect_ray(global_position, attackPosition, [self], 2)
			if collision:
				var player = collision.collider
				var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
				if player.hurt(damage):
					player.addKnockback(global_position.direction_to(player.global_position)*600, true)
			
func _draw():
	if target != null:
		if $FrameCounter/AttackTargeting.active():
			draw_line(Vector2(0,0), target.global_position - global_position, Color(255, 0, 0), 4)
		elif $FrameCounter/Attack.active():	
			draw_line(Vector2(0,0), attackPosition - global_position, Color(255, 255, 0), 4)
		elif $FrameCounter/Attack.justFinished:
			draw_line(Vector2(0,0), attackPosition - global_position, Color(255, 0, 50), 20)

func _on_DetectionArea_body_entered(body):
	if target != null:
		return
	if body.is_in_group("players"):
		target = body
		nearHover = randi()%2
		$AnimatedSprite.play("agro")
		$FrameCounter/AttackCooldown.start()


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("agro")
