extends PlayerState

class_name PlayerStateDash

const FREEZE_FRAMES = 5
const DASH_FRAMES = 5
const DASH_SPEED = 3000
const DASH_FINISH_SPEED = 600
const SWING_DASH_BOOST = 500

var dashDirection : Vector2

var Shockwave = preload("res://VFX/Scenes/Shockwave/Shockwave.tscn")
var DashLightning = preload("res://VFX/Scenes/Lightning/DashLightning.tscn")

func _init(player).(player, "dash",""):
	self.duration = FREEZE_FRAMES+DASH_FRAMES

func priority():
	return 4
	
func on_start():
	.on_start()
	player.dashCharges -= 1
	player.startDash()
	
	if player.onGround:
		dashDirection = player.get_vector_for_direction(player.facing) # TODO input is whatever left/right was pressed last
																	   # TODO this will be a function in input manager
	else:
		dashDirection = player.getDirectionToMouse()
	if player.onGround and abs(fmod(abs(dashDirection.angle())+0.5*PI,PI)-0.5*PI) < 0.2:
		dashDirection.y = 0
	if dashDirection.x > 0:
		player.setFacing(player.Direction.RIGHT)
	elif dashDirection.x < 0:
		player.setFacing(player.Direction.LEFT)
		
	if player.is_hook_attached():
		var dashBoost = dashDirection*DASH_FINISH_SPEED*0.5
		if (player.motion + dashBoost).length() < player.motion.length() or \
				(player.motion + dashBoost).length() < (dashDirection*DASH_FINISH_SPEED).length():
			player.motion = dashDirection*DASH_FINISH_SPEED
		else:
			player.motion += dashBoost
		duration -= FREEZE_FRAMES
	
func on_finish():
	.on_finish()
	if !player.is_hook_attached():
		player.motion = dashDirection*DASH_FINISH_SPEED
	
func is_transition_from_valid(newState : LivingState):
	return player.dashCharges > 0 and .is_transition_from_valid(newState)
	
func add_dash_vfx():
	var shockwave = Shockwave.instance()
	shockwave.set_global_position(player.get_global_position())
	player.get_parent().add_child(shockwave)
	
	var lightning = DashLightning.instance()
	lightning.set_global_position(player.get_global_position())
	lightning.set_rotation(dashDirection.angle()+0.5*PI)
	player.get_parent().add_child(lightning)
	
func update():
	if frame < FREEZE_FRAMES and !player.is_hook_attached():
		player.motion = Vector2(0,0)
	elif frame == FREEZE_FRAMES:
		add_dash_vfx()
	else:
		if !player.is_hook_attached():
			player.motion = dashDirection*DASH_SPEED
		else:
			dashDirection = player.motion.normalized()*dashDirection.length()
			player.motion += dashDirection*(DASH_FINISH_SPEED)/DASH_FRAMES
	
	.update()
