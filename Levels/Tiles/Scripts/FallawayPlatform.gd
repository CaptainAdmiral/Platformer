extends StaticBody2D


const FRAMES_BEFORE_FALLAWAY = 30
var fallawayCountdown : int

const FRAMES_BEFORE_RETURN = 300
var returnCountdown : int


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if fallawayCountdown:
		fallawayCountdown -= 1
		if fallawayCountdown == 0:
			set_collision_layer_bit(0, false)
			returnCountdown = FRAMES_BEFORE_RETURN
		
	if returnCountdown:
		returnCountdown -= 1
		if returnCountdown == 0:
			set_collision_layer_bit(0, true)


func _on_Area2D_body_entered(body):
	if !fallawayCountdown or returnCountdown:
		fallawayCountdown = FRAMES_BEFORE_FALLAWAY
