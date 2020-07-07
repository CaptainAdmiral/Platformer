extends Node2D

var storedMotion = Vector2(0,0)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#the following can probably be optimized by setget somehow
	storedMotion = get_node("../../Player").get("storedMotion")
	$GUI/HBoxContainer/storedMotion/Background/Number.text = String(int(storedMotion.length()))
	$GUI/HBoxContainer/storedMotion/Background/Arrow.set_rotation(-atan2(storedMotion.x, storedMotion.y) + PI/2) 
