extends Node2D


func _on_Area2D_body_entered(body):
	body.checkpointScene = get_tree().get_current_scene()
	body.checkpoint = self
	body.health = body.maxHealth
	#body.Save()
