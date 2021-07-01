extends Reference

class_name PersistentBehaviour

var frame : int = 0
var duration : int = 0 #How many frames the behavior lasts. If set to 0 will last indefinitely
var living : Living  #The persistant thing that this behavior applies to
var is_finished : bool = false
var name : String = ""
	
func _init(living, name, duration=0):
	self.living = living
	self.name = name
	self.duration = duration

#Called whenever the behavior is added to an entity
func on_start():
	pass

#Called whenever the behavior is removed from an enitty
func on_finish():
	pass
	
func set_finished(fin=true):
	is_finished = fin

#Interface for update to be called by the entity as appropriate (usually in physics update)
func update():
	frame += 1
	if duration > 0 and frame > duration:
		is_finished = true
