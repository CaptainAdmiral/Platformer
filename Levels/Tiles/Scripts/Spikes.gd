extends StaticBody2D



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func onCollision(body):
	if body is Living:
		body.setDead()
