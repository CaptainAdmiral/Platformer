extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("lightning")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
