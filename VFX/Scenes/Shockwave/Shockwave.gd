extends Node2D


export var lifeTime = 0.5
export var pixel_displacement = 0.08
	

# Called when the node enters the scene tree for the first time.
func _ready():
	$ColorRect.rect_size = get_viewport().size
	$ColorRect.rect_position -= get_viewport().size/2
	$Tween.interpolate_property($ColorRect.material, "shader_param/radius", 0, 1, lifeTime,Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_property($ColorRect.material, "shader_param/displacement", pixel_displacement, 0, lifeTime,Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	$Tween.start()

func onFinish():
	queue_free()
