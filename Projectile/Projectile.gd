tool
extends KinematicBody2D

class_name Projectile

var motion : Vector2
var handle_own_motion = false

export(Resource) var damage = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if damage == null:
		damage = get_hitbox().damage
	
	
	add_to_group("projectiles")

func _physics_process(delta):
	if Engine.editor_hint:
		return
	if !handle_own_motion:
		move_and_collide(motion*delta)
		
func get_hitbox() -> Hitbox:
	for child in get_children():
		if child is Hitbox:
			return child
	return null
	
func _get_configuration_warning():
	if damage == null and get_hitbox() == null:
		return "No damage or hitbox!"
	
	return ""

