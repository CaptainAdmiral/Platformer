tool
extends KinematicBody2D

class_name Projectile

export var motion : Vector2
export(Resource) var properties = null setget set_properties, get_properties
export var die_on_hitbox_triggered = true
export var die_on_collision = true

var _handle_own_movement = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var hb = get_hitbox()
	if hb != null:
		hb.connect("hit", self, "on_hitbox_triggered")
	assert(get_properties() != null)
	
	add_to_group("projectiles")
	
func init(position, motion):
	self.global_position = position
	self.motion = motion
		
func add_to_scene(scene, position, motion, shooter = null):
	init(position, motion)
	scene.add_child(self)
	get_properties().source = shooter
		
func set_properties(prop):
	properties = prop
	var hb = get_hitbox()
	if hb != null:
		hb.properties = prop
	
func get_properties():
	var hb = get_hitbox()
	if hb != null:
		return hb.properties
	else:
		return properties
	
func _get_configuration_warning():
	if properties == null and get_hitbox() == null:
		return "No attack properties data! Could not find hitbox to inherit attack properties from!"
	
	return ""

func _physics_process(delta):
	if Engine.editor_hint:
		return
	if !_handle_own_movement:
		var collision = move_and_collide(motion*delta)
		if collision != null:
			on_collision(collision)
		
func get_hitbox() -> Hitbox:
	for child in get_children():
		if child is Hitbox:
			return child
	return null
	
func on_hitbox_triggered(hit):
	if die_on_hitbox_triggered and hit is PhysicsBody2D:
		set_dead()
	
func on_collision(collision):
	if die_on_collision:
		set_dead()
	
func set_dead():
	queue_free()

