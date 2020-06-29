extends Node

enum{UP_PRESS, DOWN_PRESS, LEFT_PRESS, RIGHT_PRESS, JUMP_PRESS, HOOK_PRESS
UP_RELEASE, DOWN_RELEASE, LEFT_RELEASE, RIGHT_RELEASE, JUMP_RELEASE, HOOK_RELEASE}

var size
var buffer=[]
var test = false

func _ready():
	pass

func _init(frames = 10):
	size = frames
	for _i in range(frames):
		buffer.append([])
		
#Advances the buffer by one frame
func nextFrame():
	var i = 0
	buffer.pop_back()
	buffer.push_front([])
		
#Used for adding input to the buffer on event. add() should be used for
#adding individual acitons to the buffer
func addInput(event):
	if event.is_action_pressed("up"):
		add(UP_PRESS)
	if event.is_action_released("up"):
		add(UP_RELEASE)
	if event.is_action_pressed("down"):
		add(DOWN_PRESS)
	if event.is_action_released("down"):
		add(DOWN_RELEASE)	
	if event.is_action_pressed("left"):
		add(LEFT_PRESS)
	if event.is_action_released("left"):
		add(LEFT_RELEASE)
	if event.is_action_pressed("right"):
		add(RIGHT_PRESS)
	if event.is_action_released("right"):
		add(RIGHT_RELEASE)	
	if event.is_action_pressed("jump"):
		add(JUMP_PRESS)	
	if event.is_action_released("jump"):
		add(JUMP_RELEASE)
	if event.is_action_pressed("hook"):
		add(HOOK_PRESS)	
	if event.is_action_released("hook"):
		add(HOOK_RELEASE)	
		
#Adds an action to the buffer if no identical input already exists for that frame
#Returns true if an input was added, else false
func add(action):
	if !buffer[0].has(action):
		buffer[0].append(action)
		return true
	return false
		
#removes an input from the buffer if one is present
#Returns true if an input was removed, else false
func remove(action):
	for frame in buffer:
		if frame.has(action):
			frame.erase(action)
			return true
	return false
	
#Returns true if the input was pressed within the specified number of frames
func hasAction(action, frames = size):
	frames = min(frames, size)
	
	for frame in range(frames):		
		if(buffer[frame].has(action)):
			return true
	return false
		
