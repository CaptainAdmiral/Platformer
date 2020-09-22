extends Area2D

#Should really be storing ability pickups in globals

export(String) var ability
export(String) var value


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AbilityPickup_body_entered(body):
	body.get(ability).set(value)
