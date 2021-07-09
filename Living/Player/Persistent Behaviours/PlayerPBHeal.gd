extends PersistentBehaviour

class_name PlayerPBHeal

const _MANA_PER_HEALTH : float = 25.0
const _MANA_PER_FRAME: float = 0.15
var _mana_until_next_heal : float  = _MANA_PER_HEALTH

func _init(player).(player, "heal", 0):
	pass

func on_start():
	.on_start()
	living.connect("hurt", self, "_on_player_hurt")
	
func on_finish():
	.on_finish()
	living.disconnect("hurt", self, "_on_player_hurt")

func update():
	if living.health == living.max_health:
		set_finished()
		
	if living.use_mana(_MANA_PER_FRAME):
		_mana_until_next_heal -= _MANA_PER_FRAME
		if _mana_until_next_heal <= 0:
			living.heal(1)
			_mana_until_next_heal += _MANA_PER_HEALTH
	else:
		set_finished()
		living.mana = 0
		
func _on_player_hurt(damage):
	set_finished()
