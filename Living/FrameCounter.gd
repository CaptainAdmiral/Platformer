extends Node

class_name FrameCounter

var frame : int = 0 setget setFrame, getFrame
var justFinished = false
export(int) var activeFrames = 0 setget setActiveFrames, getActiveFrames

signal finished

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(_delta):
	justFinished = false
	if frame != 0:
		frame -= 1
		if frame == 0:
			justFinished = true
			emit_signal("finished")
	else:
		set_physics_process(false)
	
func active() -> bool:
	return frame != 0
	
func start():
	frame = activeFrames
	if frame != 0:
		set_physics_process(true)
	if activeFrames == 0: # I think this is okay because activeFrames == 0 is a very specific use case
			justFinished = true
			set_physics_process(true)
	
func stop():
	frame = 0
	
func setFrame(f:int) -> void:
	assert(f >= 0)
	frame = f
	if frame != 0:
		set_physics_process(true)

func getFrame() -> int:
	return frame
	
func setActiveFrames(f : int) -> void:
	assert(f>=0)
	activeFrames = f
	
func getActiveFrames() -> int:
	return activeFrames
	
func addFrames(f:int) -> void:
	frame = max(0, frame+f)
	if frame != 0:
		set_physics_process(true)
	
