extends Reference


class_name LivingState

var name = ""
var animation : String = ""
var frame : int = 0
var duration : int = 0 # How many frames before the state returns to frame 0. If set to 0 the state will not loop.
var living : Living # The persistant thing that has the states; The state machine
var sprite : AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _init(living, sprite, name = "", animation = ""):
	self.living = living
	self.sprite = sprite
	self.name = name
	self.animation = animation

# Called whenever the state is transitioned to
func on_start():
	sprite.play(animation)

# Called whenever the state is transitioned from
func on_finish():
	pass
	
func stop():
	transition_to(living.get_default_state())

# The state to be transitioned to at the end of this states duration. If left as null will instead
# Transition to the living's default state
func get_next_state() -> LivingState:
	return null

# Interface to be called by the SM class as appropriate (usually in physics update)
func update():
	frame += 1
	if duration > 0 and frame > duration:
		var nextState = get_next_state()
		if nextState != null:
			transition_to(nextState)
		else:
			transition_to(living.get_default_state())

# A transition into a state with the same or lower priority is usually not valid
# A higher priority means more states will cancel into this new state
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
	
