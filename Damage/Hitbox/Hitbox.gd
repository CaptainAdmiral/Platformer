extends Area2D

class_name Hitbox

export(Resource) var damage setget set_damage, get_damage
export(int) var repeat_rate : int = 0 # How many frames before the hitbox can re-hit an entity. If set to 0 will not repeat ever.
export var active : bool = false setget set_active, get_active

var exceptions = []
var already_hit = []

var frame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_collision_mask(2)
	set_active(active)
	if damage.source != null:
		exceptions.append(damage.source)
	connect("body_entered", self, "on_collide_with_body")
	connect("area_entered", self, "on_collide_with_area")
	
func _physics_process(delta):
	if repeat_rate != 0:
		frame += 1
		if frame == repeat_rate:
			for hit in already_hit:
				if (hit is Area2D and overlaps_area(hit)) or overlaps_body(hit):
					on_hit(hit)
			already_hit.clear()
			frame = 0
				
func add_exception(exc):
	exceptions.append(exc)
	
func set_damage(dmg : Damage):
	damage = dmg
	
func get_damage() -> Damage:
	return damage
	
func on_hit(body: Node):
	if body is Living:
		if (body as Living).hurt(damage):
			already_hit.append(body)
#	elif body is Area2D:
#		pass

func set_active(act):
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", !act)
	active = act
	
func get_active():
	return active
			
func on_collide_with_body(body : Node):
	if body in exceptions or body in already_hit:
		return
	on_hit(body)
	
func on_collide_with_area(area : Area2D):
	if area in exceptions or area in already_hit:
		return
	on_hit(area)
