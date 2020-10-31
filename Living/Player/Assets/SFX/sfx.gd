extends Node2D

func _ready():
	pass # Replace with function body.

func play(sfx):
	if !get_node(sfx).is_playing():
		get_node(sfx).play()
	
func stop(sfx):
	get_node(sfx).stop()
#func load_sounds(sound_name):
#	var sound = sfx_directory.get_next()
#	while sound != "":
#		if sound.substr(0, len(sound_name)) == sound_name:
#			sfx.append(load("res://Living/Player/Assets/SFX/" + sound))
#		sound = sfx_directory.get_next()
#
#	for file in sfx: # fucking .import files
#		if file == null:
#			sfx.erase(file)
#
#	return sfx
