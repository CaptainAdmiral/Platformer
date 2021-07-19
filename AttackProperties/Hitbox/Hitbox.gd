extends Area2D

class_name Hitbox

signal hit_living(living)
signal hit(hit)

enum TRIGGER {COLLISION, OTHER,}

export(Resource) var properties setget set_properties, get_properties
# Defers responsibily to owning class for calling on_hit if set to OTHER. 
# Recommended to use hit_overlapping() in this case if desired behaviour.
export(TRIGGER) var trigger_type = TRIGGER.COLLISION 
export(int) var repeat_rate : int = 0 # How many frames before the hitbox can re-hit an entity. If set to 0 will not repeat ever.
export var active : bool = false setget set_active, get_active

var exceptions = []
var already_hit = []

var frame = 0
var just_active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_collision_mask(4)
	set_active(active)
	if properties.source != null:
		exceptions.append(properties.source)
	connect("body_entered", self, "on_collide_with_body")
	connect("area_entered", self, "on_collide_with_area")
	
	var parent = get_parent()
	while parent != null:
		if parent is Living:
			add_exception(parent)
		parent = parent.get_parent()
	
func _physics_process(_delta):
	if !(repeat_rate == 0 and trigger_type == TRIGGER.COLLISION):
		frame += 1
		if frame == repeat_rate:
			var ahCopy = already_hit.duplicate()
			already_hit.clear()
			if trigger_type == TRIGGER.COLLISION:
				for hit in ahCopy:
					if is_instance_valid(hit):
						if (hit is Area2D and overlaps_area(hit)) or overlaps_body(hit):
							on_hit(hit)
			frame = 0
				
func add_exception(exc):
	exceptions.append(exc)
	
func set_properties(ap : AttackProperties):
	properties = ap
	
func get_properties() -> AttackProperties:
	return properties
	
func hit_overlapping():
	for body in get_overlapping_bodies():
		on_hit(body)
	for area in get_overlapping_areas():
		on_hit(area)
	
func on_hit(body: Node):
	if body in exceptions:
		return
	if trigger_type == TRIGGER.COLLISION:
		if body in already_hit:
			return
	elif trigger_type == TRIGGER.OTHER and repeat_rate != 0:
		if body in already_hit:
			return
	emit_signal("hit", body)
	if body is Living:
		emit_signal("hit_living", body)
		if (body as Living).hurt(properties):
			if !(trigger_type == TRIGGER.OTHER and repeat_rate == 0):
				already_hit.append(body)
#	elif body is Area2D:
#		pass

# CAUTION - Disabling / re-enabling hitbox will take place at end of frame, not immediately
func set_active(act):
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", !act)
	if active != act:
		already_hit.clear()
		if act and trigger_type == TRIGGER.COLLISION:
			hit_overlapping()
			
	active = act
	
func get_active():
	return active
			
func on_collide_with_body(body : Node):
	if trigger_type != TRIGGER.COLLISION:
		return
	on_hit(body)
	
func on_collide_with_area(area : Area2D):
	if trigger_type != TRIGGER.COLLISION:
		return
	on_hit(area)
