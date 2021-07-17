extends Node

var PlayerHud = preload("res://GUI/PlayerHUD/PlayerHUD.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.connect("player_joined_scene", self, "on_player_ready")

func on_player_ready(player):
	add_player_hud(player)

func add_player_hud(player):
	var playerHud = PlayerHud.instance()
	playerHud.player = player
	get_tree().get_root().call_deferred("add_child", playerHud)
