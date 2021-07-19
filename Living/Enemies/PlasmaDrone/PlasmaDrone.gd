extends Living

const RANGE_DISPLAY_DIST = 1000

var deagro_range = 0

var target : Node2D = null
var shoot_queue = []

func _ready():
	set_max_health(2)
	fall_speed = 0
	knockback_multiplier = 0.1
	mana_on_kill = 10
	deagro_range = $Range/CollisionShape2D.shape.radius + 100

func _physics_process(delta):
	motion *= 0.9
	
	if target != null:
		if target.global_position.distance_to(global_position) > deagro_range:
			target = null
	
	if !$ChargeUp.active():
		if $ChargeUp.just_finished:
			$RangeIndicator.scale = Vector2(2.56, 2.56)
		var dist = RANGE_DISPLAY_DIST
		var nearestPlayer = Math.get_nearest_to_point(global_position, get_tree().get_nodes_in_group("players"))
		dist = max(global_position.distance_to(nearestPlayer.global_position), 1)
		
		if target == null:
			$RangeIndicator.modulate.a = min(1 - abs(dist-500)/(RANGE_DISPLAY_DIST-500), 1)
			$RangeIndicator.rotation = global_position.angle_to_point(nearestPlayer.global_position)-0.5*PI
		elif !$ShootCooldown.active():
			shoot()
	else:
		print($ChargeUp.frame)
		$RangeIndicator.modulate.a = ($ChargeUp.frame+1)/$ChargeUp.activeFrames * 2
		$RangeIndicator.scale *= 1.05

func shoot():
	$ShootCooldown.start()
	print("pew")

func _on_range_entered(body):
	if target == null:
		target = body
		
		$ChargeUp.start()
