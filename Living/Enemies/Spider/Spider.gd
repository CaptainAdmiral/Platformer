extends Living

var speed = 300
var acceleration = 50


# Called when the node enters the scene tree for the first time.
func _ready():
	setMaxHealth(6)
	canBePulled = true
	
	setFacing(facing)


func _physics_process(delta):
	if abs(motion.x) < speed:
		if facing == Direction.RIGHT:
			motion.x = min(speed, motion.x+acceleration)
		elif facing == Direction.LEFT:
			motion.x = max(-speed, motion.x-acceleration)
	else:
		motion.x *= 0.95
		
	if is_on_floor() and (is_on_wall() or !$FallDetector.is_colliding()):	
		motion.x = -motion.x
		if facing == Direction.RIGHT:
			setFacing(Direction.LEFT)
		else:
			setFacing(Direction.RIGHT)


func _on_AttackHitbox_body_entered(player):
	var damage = Damage.new(self, 1, Damage.TYPE.PHYSICAL)
	if player.hurt(damage):
		player.addKnockback(Vector2(global_position.direction_to(player.global_position).x*600, -600), true)
