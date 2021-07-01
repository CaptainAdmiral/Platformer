extends PersistentBehaviour

class_name PlayerPBHeal

const _MANA_PER_HEALTH : float = 25.0
const _MANA_PER_FRAME: float = 0.15
var _manaUntilNextHeal : float  = _MANA_PER_HEALTH

func _init(player).(player, "heal", 0):
	pass

func on_start():
	.on_start()
	living.connect("hurt", self, "_on_player_hurt")
	
func on_finish():
	.on_finish()
	living.disconnect("hurt", self, "_on_player_hurt")

func update():
	if living.health == living.maxHealth:
		set_finished()
		
	if living.useMana(_MANA_PER_FRAME):
		_manaUntilNextHeal -= _MANA_PER_FRAME
		if _manaUntilNextHeal <= 0:
			living.heal(1)
			_manaUntilNextHeal += _MANA_PER_HEALTH
	else:
		set_finished()
		living.mana = 0
		
func _on_player_hurt(damage):
	set_finished()
