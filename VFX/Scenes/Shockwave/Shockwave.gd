extends Node2D


export var lifeTime = 0.75
export var pixel_displacement = 0.08
	

# Called when the node enters the scene tree for the first time.
func _ready():
	$Tween.interpolate_property($ColorRect.material, "shader_param/radius", 0, 1, lifeTime,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_property($ColorRect.material, "shader_param/displacement", pixel_displacement, 0, lifeTime,Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	$Tween.start()

func onFinish():
	queue_free()
