extends Reference


class_name LivingState

var animation : String = ""
var frame : int = 0
var duration : int = 0 #How many frames before the state returns to frame 0. If set to 0 the state will not loop.
var loop : bool = false
var living : Living #The persistant thing that has the states; The state machine

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _init(stateMachine):
	living = stateMachine

#Called whenever the state is transitioned to
func on_start():
	pass

#Called whenever the state is transitioned from
func on_finish():
	pass

#Interface to be called by the SM class as appropriate (usually in physics update)
func update():
	frame += 1
	if frame > duration:
		if loop:
			frame = 0
		else:
			transition_to(living.get_default_state())

#A transition into a state with the same or lower priority is usually not valid
#A higher priority means more states will cancel into this new state
func priority():
	return 0
	
func is_valid_transition(newState : LivingState):
	return newState.priority() > priority()
	
func transition_to(newState : LivingState) -> bool:
	if is_valid_transition(newState):
		living.state = newState
		newState.onStart()
		on_finish()
		return true
	return false
	
