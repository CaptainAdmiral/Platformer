extends Area2D


export(String, FILE, "*.tscn") var scene


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _physics_process(_delta):
	$Sprite.rotation_degrees+=4


func onCollision(body):
	if body == Globals.player:
		get_tree().change_scene(scene)
