extends PlayerState

class_name PlayerStateHeal

const CHARGE_REQUIRED = 120 # (no. frames for full charge)

var charge = 0

func _init(player).(player, "heal",""):
	self.ground_only = true

func priority():
	return 2 if charge < 20 else 4
	
func is_valid():
	return !player.has_persistent_behaviour("heal") and .is_valid()
	
func update():
	if Input.is_action_pressed("down"):
		charge += 1
	else:
		charge -= 2
	
	if charge > CHARGE_REQUIRED:
		player.add_persistent_behaviour(PlayerPBHeal.new(player))
		stop()
		return
	elif charge < 0:
		stop()
		
	.update()
