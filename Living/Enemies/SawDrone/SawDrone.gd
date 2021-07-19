extends Living

const MAX_RPS = 24
const SPIN_ACCELERATION = 0.2
const MINIMUM_DAMAGING_RPS = 12
const RANGE_DISPLAY_DIST = 1200

var rps : float = 0

func _ready():
	set_max_health(2)
	fall_speed = 0
	knockback_multiplier = 0.1
	mana_on_kill = 10

func _physics_process(delta):
	motion *= 0.9
	
	if $Spinning.is_stopped():
		rps = max(rps-SPIN_ACCELERATION, 0)
		if rps < MINIMUM_DAMAGING_RPS and $Hitbox.active:
			$Hitbox.set_active(false)
		var dist = RANGE_DISPLAY_DIST
		var nearestPlayer = Math.get_nearest_to_point(global_position, get_tree().get_nodes_in_group("players"))
		dist = max(global_position.distance_to(nearestPlayer.global_position), 1)
		
		$RangeIndicator.modulate.a = min(1 - abs(dist-500)/(RANGE_DISPLAY_DIST-500), 1)
		$RangeIndicator.rotation = global_position.angle_to_point(nearestPlayer.global_position)-0.5*PI
	else:
		rps = min(rps+SPIN_ACCELERATION, MAX_RPS)
		if rps > MINIMUM_DAMAGING_RPS and !$Hitbox.active:
			$Hitbox.set_active(true)
			
	if rps > 0:
		$AnimatedSprite.rotate(rps*delta)
		for body in $Range.get_overlapping_bodies():
			if body is Living:
				var dir = body.global_position.direction_to(global_position)
				body.motion += dir*(600 - body.global_position.distance_to(global_position))*rps*0.005
				


func _on_range_entered(body):
	$Spinning.start()
	$RangeIndicator.modulate.a = 0
	
