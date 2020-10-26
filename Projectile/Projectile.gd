extends KinematicBody2D

class_name Projectile

var motion : Vector2
var shooter = null
var canParry = false
var canDodge = true


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attacks")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
