extends LivingState

class_name PlayerState

var player : Living

func _init(player, name, animation="").(player, name, player.get_node("AnimatedSprite"), animation):
	self.player = player
