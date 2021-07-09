extends PlayerState

class_name PlayerStateDash

const FREEZE_FRAMES = 5
const DASH_FRAMES = 5
const DASH_SPEED = 3000
const DASH_FINISH_SPEED = 600
const SWING_DASH_BOOST = 500

var dash_direction : Vector2

var Shockwave = preload("res://VFX/Scenes/Shockwave/Shockwave.tscn")
var DashLightning = preload("res://VFX/Scenes/Lightning/DashLightning.tscn")

func _init(player).(player, "dash",""):
	self.duration = FREEZE_FRAMES+DASH_FRAMES

func priority():
	return 4
	
func on_start():
	.on_start()
	player.dash_charges -= 1
	player.reset_attack_timer()
	player.get_node("FrameCounters/SlideCooldown").stop()
	
	if player.on_ground:
		dash_direction = Direction.get_vector_for_direction(player.facing) # TODO input is whatever left/right was pressed last
																	   # TODO this will be a function in input manager
	else:
		dash_direction = Direction.get_direction_to_mouse(player)
		
	if dash_direction.x > 0:
		player.set_facing(Direction.RIGHT)
	elif dash_direction.x < 0:
		player.set_facing(Direction.LEFT)
		
	var rot = dash_direction.angle()+0.5*PI;
	if player.facing == Direction.LEFT:
		rot*=-1;
	player.get_node("VFX/Dash").set_rotation(rot)
	player.get_node("VFX/AnimationPlayer").stop()
	player.get_node("VFX/AnimationPlayer").play("dash")	
		
	if player.is_hook_attached():
		var dashBoost = dash_direction*DASH_FINISH_SPEED*0.5
		if (player.motion + dashBoost).length() < player.motion.length() or \
				(player.motion + dashBoost).length() < (dash_direction*DASH_FINISH_SPEED).length():
			player.motion = dash_direction*DASH_FINISH_SPEED
		else:
			player.motion += dashBoost
		duration -= FREEZE_FRAMES
	
func on_finish():
	.on_finish()
	if !player.is_hook_attached():
		player.motion = dash_direction*DASH_FINISH_SPEED
	
func is_transition_from_valid(newState : LivingState):
	return player.dash_charges > 0 and .is_transition_from_valid(newState)
	
func add_dash_vfx():
	var shockwave = Shockwave.instance()
	shockwave.set_global_position(player.get_global_position())
	player.get_parent().add_child(shockwave)
	
	var lightning = DashLightning.instance()
	lightning.set_global_position(player.get_global_position())
	lightning.set_rotation(dash_direction.angle()+0.5*PI)
	player.get_parent().add_child(lightning)
	
func update():
	if frame < FREEZE_FRAMES and !player.is_hook_attached():
		player.motion = Vector2(0,0)
	elif frame == FREEZE_FRAMES:
		add_dash_vfx()
	else:
		if !player.is_hook_attached():
			player.motion = dash_direction*DASH_SPEED
		else:
			dash_direction = player.motion.normalized()*dash_direction.length()
			player.motion += dash_direction*(DASH_FINISH_SPEED)/DASH_FRAMES
	
	.update()
