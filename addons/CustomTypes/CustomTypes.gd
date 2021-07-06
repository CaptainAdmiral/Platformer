tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Damage", "Resource", preload("res://Damage/Damage.gd"), null)


func _exit_tree():
	remove_custom_type("Damage")
