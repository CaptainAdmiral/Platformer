extends Node

var size
var buffer=[]

func _ready():
	pass
	
func _physics_process(_delta):
	nextFrame()
	
func _input(event:InputEvent) -> void:
	if(event is InputEventKey):
		add(event)

func _init(frames = 10):
	size = frames
	for _i in range(frames):
		buffer.append([])
		
#Advances the buffer by one frame
func nextFrame():
	buffer.pop_back()
	buffer.push_front([])
		
#Adds an action to the buffer if no identical input already exists for that frame
#Returns true if an input was added, else false
func add(input:InputEvent):
	if(!input.is_action_type()):
		return false
	
	for input1 in buffer[0]:
		if input.shortcut_match(input1):
			return false
	
	buffer[0].append(input)
	return true
	
#Returns true if the input was pressed within the specified number of frames
func hasAction(action:String, release:bool = false, frames:int = size):
	frames = min(frames, size)
	
	for frame in range(frames):
		for input in buffer[frame]:
			if !release:
				if input.is_action_pressed(action):
					return true
			else:
				if input.is_action_released(action):
					return true
	return false
		
