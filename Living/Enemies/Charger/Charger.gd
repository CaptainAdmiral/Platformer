extends Living

var target : Living = null
var acceleration = 40
var run_speed_idle = 150
var run_speed_agro = 1700
const MAX_AGRO_RANGE : float = 3000.0
export var patrol_range = 500
var patrol_point : Vector2 = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	set_max_health(10)
	knockback_multiplier = 0.2
	patrol_point = global_position


func _physics_process(delta):
	if on_ground and !$FrameCounter/TurnAround.active():
		if target != null:
			if target.global_position.x - global_position.x > 0:
				set_facing(Direction.RIGHT)
			else:
				set_facing(Direction.LEFT)
			$FrameCounter/TurnAround.start()
		elif abs(global_position.x - patrol_point.x) > patrol_range:
			if global_position.x - patrol_point.x < 0:
				set_facing(Direction.RIGHT)
			else:
				set_facing(Direction.LEFT)
		elif !$FallDetector.is_colliding() or is_on_wall():
			turn_around()
			
		
	var s = Direction.get_sign_for_direction(facing)
	var speed = run_speed_idle if target == null else run_speed_agro
	
	if on_ground:
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
				if on_ground:
					motion.x = 0
					motion.y -= 300
				$AnimatedSprite.play("agro")


func _on_AttackArea_body_entered(player):
	var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
	if player.hurt(damage):
		player.addKnockback(motion*0.5 + Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
