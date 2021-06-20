extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	Globals.paused = !Globals.paused
	get_tree().paused = Globals.paused
	if Globals.paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	$Menu.visible = get_tree().paused

func _on_Continue_pressed():
	toggle_pause()


func _on_Save_pressed():
	get_tree().quit()
