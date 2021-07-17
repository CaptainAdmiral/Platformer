extends Living

const RANGE_DISPLAY_DIST = 800

func _ready():
	set_max_health(2)
	fall_speed = 0
	knockback_multiplier = 0.1
	mana_on_kill = 10

func _physics_process(delta):
	motion *= 0.9
	var dist = RANGE_DISPLAY_DIST
	var nearestPlayer = Math.get_nearest_to_point(global_position, get_tree().get_nodes_in_group("players"))
	dist = max(global_position.distance_to(nearestPlayer.global_position), 1)
	
	$RangeIndicator.modulate.a = min(1 - abs(dist-500)/(RANGE_DISPLAY_DIST-500), 1)
	$RangeIndicator.rotation = global_position.angle_to_point(nearestPlayer.global_position)-0.5*PI
