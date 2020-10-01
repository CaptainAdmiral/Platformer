extends Living


const MAX_AGRO_RANGE : float = 1500.0
var driftSpeed = 20
var attackAcceleration = 50
var attacking = null
var projectile = preload("res://Living/Enemies/Drone/Projectile.tscn")
var target : Living = null
var shoot_cd = 90 

# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(3)
	fallSpeed = 0
	canBePulled = true
	knockbackMultiplier = 2
	manaOnKill = 20
	motion = Vector2(driftSpeed, 0).rotated(rng.randf_range(0, 2*PI))
	$AnimatedSprite.frame = rng.randi()%5+1
	$FrameCounter/Shoot.setActiveFrames(shoot_cd) # SHOOTING COOLDOWN


func _physics_process(delta):
	if motion.length() > driftSpeed:
		motion *= 0.9
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE:
		target = null
		$AnimatedSprite.play("idle")
		
#	if $WallDetector.is_colliding():
#		var dist = max (100, global_position.distance_to($WallDetector.get_collision_point()))
#		motion-= 1000*global_position.direction_to($WallDetector.get_collision_point())/dist
#
#	$WallDetector.rotate(2*PI/16)
		
	if !$FrameCounter/Attack.active(): # propel self away from other non-attacking drones (if there are any)
		for drone in get_tree().get_nodes_in_group("drones"):
			if drone == self:
				continue
			var dist = max(100, global_position.distance_squared_to(drone.global_position))
			motion -= 150000*global_position.direction_to(drone.global_position)/dist
			
	if target != null: 
		var maxDist = 800
		var dist = max(400, global_position.distance_to(target.global_position))*1.2
		var speedMultiplier = 2 if !$FrameCounter/Attack.active() else 3 #
		var balance_factor = 100 if !$FrameCounter/Attack.active() else 30
		motion += attackAcceleration*global_position.direction_to(target.global_position) * speedMultiplier# Force Towards Player
		motion -= attackAcceleration*maxDist*global_position.direction_to(target.global_position)/dist * (exp(balance_factor/global_position.distance_to(target.global_position)))  # Balancing Motion
		
#		if attacking != null:
#			if !$FrameCounter/Attack.active():
#				aggro_move(maxDist, dist)
			
		if $FrameCounter/Attack.justFinished:
			end_attack()
			
#			if !$FrameCounter/Attack.active():
#				begin_attack()

func controller_move(destination):
	if !(target == null):
		motion += 40*global_position.direction_to(destination)

func end_attack():
	for body in $AttackArea.get_overlapping_bodies():
		var player = body
		var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
		if player.hurt(damage):
			player.addKnockback(Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
	attacking = null

func begin_attack():
	$AnimatedSprite.play("attack")
	$AnimatedSprite.frame = 0
#	$FrameCounter/Attack.setActiveFrames(60)
	$FrameCounter/Attack.start()

#func _on_Attack_command():
#	begin_attack()

func shoot():
	if !$FrameCounter/Shoot.active():
		projectile.instance().init(self, 400)
		$FrameCounter/Shoot.start()
		
func _on_DetectionArea_body_entered(body):
	if target != null:
		return
	if body.is_in_group("players"):
		target = body
		$AnimatedSprite.play("agro")


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("agro")
