extends Node

class_name FrameCounter

var frame : int = 0 setget set_frame, get_frame
var just_finished = false
export(int) var activeFrames = 0 setget set_active_frames, get_active_frames

signal finished

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(_delta):
	just_finished = false
	if frame != 0:
		frame -= 1
		if frame == 0:
			just_finished = true
			emit_signal("finished")
	else:
		set_physics_process(false)
	
func active() -> bool:
	return frame != 0
	
func start():
	frame = activeFrames
	if frame != 0:
		set_physics_process(true)
	
func stop():
	frame = 0
	
func pause():
	set_physics_process(false)
	
func resume():
	if frame != 0:
		set_physics_process(true)
	
func set_finished():
	if frame == 0:
		return
	frame = 0
	just_finished = true
	emit_signal("finished")
	
func set_frame(f:int) -> void:
	assert(f >= 0)
	frame = f
	if frame != 0:
		set_physics_process(true)
		
func set_min_frame(f:int) -> void:
	assert(f >= 0)
	frame = max(frame, f)
	if frame != 0:
		set_physics_process(true)

func get_frame() -> int:
	return frame
	
func set_active_frames(f : int) -> void:
	assert(f>=0)
	activeFrames = f
	
func get_active_frames() -> int:
	return activeFrames
	
func add_frames(f:int) -> void:
	frame = max(0, frame+f)
	if frame != 0:
		set_physics_process(true)
	
