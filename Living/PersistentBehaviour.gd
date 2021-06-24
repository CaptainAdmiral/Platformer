extends Reference


var frame : int = 0
var duration : int = 0 #How many frames the behavior lasts. If set to 0 will last indefinitely
var living : Living  #The persistant thing that this behavior applies to
var is_finished : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _init(living, duration):
	self.living = living

#Called whenever the behavior is added to an entity
func on_start():
	pass

#Called whenever the behavior is removed from an enitty
func on_finished():
	pass

#Interface for update to be called by the entity as appropriate (usually in physics update)
func update():
	frame += 1
	if frame > duration:
		is_finished = true
