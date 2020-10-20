extends Living

var target : Living = null
var acceleration = 40
var runSpeedIdle = 150
var runSpeedAgro = 1700
const MAX_AGRO_RANGE : float = 3000.0
export var patrolRange = 500
var patrolPoint : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(10)
	knockbackMultiplier = 0.2
	patrolPoint = global_position


func _physics_process(delta):
	if onGround and !$FrameCounter/TurnAround.active():
		if target != null:
			if target.global_position.x - global_position.x > 0:
				setFacing(Direction.RIGHT)
			else:
				setFacing(Direction.LEFT)
			$FrameCounter/TurnAround.start()
		elif abs(global_position.x - patrolPoint.x) > patrolRange:
			if global_position.x - patrolPoint.x < 0:
				setFacing(Direction.RIGHT)
			else:
				setFacing(Direction.LEFT)
		elif !$FallDetector.is_colliding() or is_on_wall():
			turnAround()
			
		
	var s = getSignForDirection()
	var speed = runSpeedIdle if target == null else runSpeedAgro
	
	if onGround:
		if s*motion.x < speed:
			motion.x = s*min(speed, s*motion.x + acceleration)
		
	if target != null and global_position.distance_to(target.global_position) > MAX_AGRO_RANGE:
		target = null
		$View.enabled = true
		$AnimatedSprite.play("idle")
		
	if target == null:
		var collider = $View.get_collider()
		if collider != null:
			if collider.is_in_group("players"):
				target = collider
				$View.enabled = false
				if onGround:
					motion.x = 0
					motion.y -= 300
				$AnimatedSprite.play("agro")


func _on_AttackArea_body_entered(player):
	var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
	if player.hurt(damage):
		player.addKnockback(motion*0.5 + Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
