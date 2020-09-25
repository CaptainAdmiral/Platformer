extends Living

var target : Living = null
var acceleration = 40
var runSpeedIdle = 150
var runSpeedAgro = 1700
const TURN_AROUND_COOLDOWN = 10
var turnAroundCooldownFrames : int = 0
const MAX_AGRO_RANGE : float = 3000.0
export var patrolRange = 500
var patrolPoint : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(10)
	knockbackMultiplier = 0.2
	patrolPoint = global_position


func _physics_process(delta):
	if turnAroundCooldownFrames:
		turnAroundCooldownFrames -= 1
	
	if onGround and !turnAroundCooldownFrames:
		if target != null:
			if target.global_position.x - global_position.x > 0:
				setFacing(Direction.RIGHT)
			else:
				setFacing(Direction.LEFT)
			turnAroundCooldownFrames = TURN_AROUND_COOLDOWN
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
		$AnimatedSprite.play("idle")
		
	var collider = $View.get_collider()
	if collider != null:
		if collider.is_in_group("players"):
			target = collider
			if onGround:
				motion.y += 300
			$AnimatedSprite.play("agro")


func _on_AttackArea_body_entered(player):
	var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
	if player.hurt(damage):
		player.addKnockback(motion*0.5 + Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
