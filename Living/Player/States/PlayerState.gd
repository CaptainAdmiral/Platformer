extends LivingState

class_name PlayerState

var player : Living
var disable_sword = false

func _init(player, name, animation="", _priority=1).(player, name, player.get_node("AnimatedSprite"), animation, _priority):
	self.player = player
