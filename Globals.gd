extends Node

signal update_client_player(player)

var debug = true
var paused = false

# This should be used for client side operations ONLY. NOT as a server side global for grabbing a reference
# to "the player" (To allow for coop no such paradigm exists)
var client_player = null setget set_client_player

func _ready():
	pass
	
func set_client_player(player):
	client_player = player
	emit_signal("update_client_player", player)
