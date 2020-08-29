extends Camera2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _input(event):
	if event is InputEventMouseMotion:
		position = -0.5*get_viewport().get_visible_rect().size + event.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
