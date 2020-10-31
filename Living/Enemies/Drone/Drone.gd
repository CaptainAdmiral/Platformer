extends Living

const MAX_AGRO_RANGE : float = 2000.0
const PATROL_RANGE : float = 1000.0


var patrolPoint : Vector2 = Vector2()

var driftSpeed : float = 20
var attackAcceleration : float = 50
var nearHover = false

var target : Living = null setget setTarget

var attackPosition : Vector2 = Vector2()
var isCurAttacker = false
var targetOffset = Vector2(0, 0)

var RayCastAttack = load("res://Living/Attacks/RayCastAttack.gd")

var rng = RandomNumberGenerator.new()

var deathFlag = false


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
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
	if deathFlag == true && !$FrameCounter/Death.active():
		.setDead()
	
	if motion.length() > driftSpeed:
		motion *= 0.9
		
	if target == null and patrolPoint.distance_to(global_position) > PATROL_RANGE:
		var randAng = rand_range(0, 2*PI)
		var newPos = patrolPoint + rand_range(0, 1)*PATROL_RANGE*Vector2(cos(randAng), sin(randAng))
		motion = driftSpeed*global_position.direction_to(newPos)
		
		
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE and !($FrameCounter/AttackTargeting.active() or $FrameCounter/Attack.active()):
		setTarget(null)
		update()
		
#	if $WallDetector.is_colliding():
#		var dist = max(100, global_position.distance_squared_to($WallDetector.get_collision_point()))
#		motion -= 1000000*global_position.direction_to($WallDetector.get_collision_point())/dist
		
	$WallDetector.rotate(2.1*PI/10)
		
	for drone in get_tree().get_nodes_in_group("drones"):
		if drone == self:
			continue
		
		if target == null:
			var dist = max(20, global_position.distance_squared_to(drone.global_position))
			motion -= 1000*global_position.direction_to(drone.global_position)/dist
		else:
			var dist = max(100, global_position.distance_squared_to(drone.global_position))
			motion -= 150000*global_position.direction_to(drone.global_position)/dist
			
	if target != null:
		if randi()%600 == 0:
			var radial_change = clamp(rng.randfn(0, PI*0.65), PI*0.12, PI*0.99)
			targetOffset = global_position.direction_to(target.global_position).rotated(radial_change)*460
#
		if randi()%200 == 0:
			nearHover = !nearHover
		var maxDist = 800 if nearHover else 1000
		var dist = max(400, global_position.distance_to(target.global_position))*1.2
		var speedMultiplier = 2 if !$FrameCounter/ChargeAttack.active() else 3 #
		var balance_factor = 100 if !$FrameCounter/ChargeAttack.active() else 30
		var offset = targetOffset if !$FrameCounter/ChargeAttack.active() else Vector2(0,0)
		motion += attackAcceleration*global_position.direction_to(target.global_position + offset) * speedMultiplier# Force Towards Player
		motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position + offset)/dist * (exp(balance_factor/max(100,global_position.distance_to(target.global_position + offset))))  # Balancing Motion

#		motion += target.motion*0.025
		if !$FrameCounter/ChargeAttack.active():
			motion += 40*global_position.direction_to(target.global_position + offset)
		
#		if randi()%200 == 0:
#			nearHover = true
#		var maxDist = 400 if nearHover else 500
#		var dist = max(400, global_position.distance_to(target.global_position))
#		motion += attackAcceleration*global_position.direction_to(target.global_position+targetOffset)
#		motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position)/dist
#		motion += target.motion*0.05

		if $FrameCounter/ChargeAttack.justFinished:
			end_attack()

		if isCurAttacker and false and !$FrameCounter/ChargeAttack.active() and !$FrameCounter/AttackTargeting.active():
			begin_attack()
			
		if $FrameCounter/Attack.justFinished:
			$FrameCounter/AttackCooldown.start()
			$FrameCounter/AttackCooldown.addFrames(randi()%int(1.8*$FrameCounter/AttackCooldown.activeFrames*get_tree().get_nodes_in_group("agro").size()))
		
		if $FrameCounter/AttackCooldown.justFinished:
			$FrameCounter/AttackTargeting.start()
			
		if $FrameCounter/AttackTargeting.justFinished:
			$sfx.play("drone laser " + str(randi()%5+1))
			$FrameCounter/Attack.start()
			var collision = get_world_2d().direct_space_state.intersect_ray(global_position, global_position + global_position.direction_to(target.global_position)*30000, [self, target], 3)
			if collision:
				attackPosition = collision.position
			else:
				attackPosition = global_position.direction_to(target.global_position)*30000
				
		if $FrameCounter/Attack.justFinished:
			var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
			var collisions = RayCastAttack.makeAttackRayCast(self, global_position, attackPosition, [self], 2, damage)
			if !collisions.empty():
				var lastCollision = collisions[collisions.size()-1]
				var originForKnockback = global_position
				if collisions.size() >= 2:
					originForKnockback = collisions[collisions.size()-2].position
				if lastCollision and lastCollision.collider is Living:
					if lastCollision.collider.hurt(damage):
						lastCollision.collider.addKnockback(originForKnockback.direction_to(lastCollision.collider.global_position)*600, true)
				
		
func hurt(damage : Damage) -> bool:
	damage(damage.amount)
	if isDead and damage.source != null and damage.source.is_in_group("players"):
		damage.source.onKill(self)
	else:
		$sfx.play("drone hurt " + str(randi()%5+1))
	return true
	
func end_attack():
	for body in $AttackArea.get_overlapping_bodies():
		var player = body
		var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
		if player.hurt(damage):
			player.addKnockback(Vector2(global_position.direction_to(player.global_position).x*600, -600), true)

	selectNewAttacker()

func begin_attack():
	$AnimatedSprite.play("attack")
	$AnimatedSprite.frame = 0
#	$FrameCounter/Attack.setActiveFrames(60)
	$FrameCounter/ChargeAttack.start()		
		
func selectNewAttacker() -> void:
	assert(isCurAttacker)
	isCurAttacker = false
	var agro = get_tree().get_nodes_in_group("agro")
	if agro.empty():
		return
	agro[randi()%agro.size()].isCurAttacker = true
					
func setTarget(tgt) -> void:
	if target != null and tgt == null:
		$AnimatedSprite.play("idle")
		remove_from_group("agro")
		target = tgt
		if isCurAttacker:
			selectNewAttacker()
	elif target == null and tgt != null:
		$AnimatedSprite.play("agro")
		add_to_group("agro")
		target = tgt
		var flag = false
		for drone in get_tree().get_nodes_in_group("agro"):
			if ! drone.isCurAttacker:
				continue
			flag = true
		if !flag:
			isCurAttacker = true
		
			
func _draw():
	if target != null:
		if $FrameCounter/AttackTargeting.active():
			draw_line(Vector2(0,0), target.global_position - global_position, Color(1, 0, 0), 4)
		elif $FrameCounter/Attack.active():	
			draw_line(Vector2(0,0), attackPosition - global_position, Color(1, 1, 0), 4)
		elif $FrameCounter/Attack.justFinished:
			var damage = Damage.new(self, 0, Damage.TYPE.PHYSICAL)
			var collisions = RayCastAttack.makeAttackRayCast(self, global_position, attackPosition, [self], 2, damage)
			var lastCollisionPos = Vector2(0,0)
			for collision in collisions:
				if !collision:
					break
				draw_line(lastCollisionPos, collision.position - global_position, Color(1, 0, 0.3), 20)
				lastCollisionPos = collision.position - global_position
			
func setDead() -> void:
	$AnimatedSprite.hide()
	$FrameCounter/Death.start()
	deathFlag = true
	$sfx.play("drone death " + str(randi()%13+1))
	if isCurAttacker:
		selectNewAttacker()
		
func _on_DetectionArea_body_entered(body):
	if target != null:
		return
	if body.is_in_group("players"):
		setTarget(body)
		nearHover = randi()%2
		$FrameCounter/AttackCooldown.start()
		$FrameCounter/AttackCooldown.addFrames(randi()%(2*$FrameCounter/AttackCooldown.activeFrames*get_tree().get_nodes_in_group("agro").size()))
		


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("agro")
