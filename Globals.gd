extends Node

signal player_joined_scene(player)

var debug = true
var paused = false

# This should be used for client side operations ONLY. NOT as a server side global for grabbing a reference
# to "the player" (To allow for coop no such paradigm exists)
var client_player = null

func _ready():
	pass
	
