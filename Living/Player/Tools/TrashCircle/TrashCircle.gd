extends Node2D



# Declare member variables here. Examples:
var a = 2
var b = "text"
var active_drones = []
var active_drones_destination = []
var attacker 
var shooter  
var attack_delay = 40 # Frames between attack commands (minus random delay)
var last_rand_drone

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	# Clean arrays for dead drones (there's probably a better way to clean..)
	for drone in active_drones:
		if drone == null or !is_instance_valid(drone):
			active_drones_destination.remove(active_drones.find(drone))
			active_drones.erase(drone)
	
	if !$FrameCounter.active() && randi()%int(GaussianRandom.nextGaussian3(100, 30, 1, 130)) == 0:  
		
		if !(active_drones.size() == 0) && !(active_drones == [null]):
			$FrameCounter.setActiveFrames(attack_delay)
			$FrameCounter.start()
			var num_drones = active_drones.size()
			var rand_drone = randi()%(num_drones)
			
			if num_drones > 1:
				if last_rand_drone == rand_drone:
					if num_drones % 2 == rand_drone:
						attacker = active_drones[rand_drone + 1]
					else:
						attacker = active_drones[num_drones - rand_drone - 1]
				else:
					attacker = active_drones[rand_drone]
			
			last_rand_drone = rand_drone
#			if active_drones.size() > 1:
#				shooter = active_drones[rand_drone]
			
			for drone in active_drones:
				if is_instance_valid(drone): # this is the only way I avoid rare errors tbh
					if drone == attacker:
#						attack_command(drone)
						drone.get_node("../").begin_attack()
#					elif drone == shooter:
#						drone.get_node("../").shoot()
#						print("Shot command issued")

	
	if !(active_drones == [null]):
		var i = 0
		for drone in active_drones:
			if drone == null:
				continue
			if !(drone == attacker):
				# send drone global position update (local stays same)
				drone.get_node("../").controller_move(self.global_position + active_drones_destination[i])
				# Then maybe shoot
				if randi()%(int(GaussianRandom.nextGaussian3(600, 300, 1, 900))) == 0 && active_drones.size() > 1 && is_instance_valid(drone):
					drone.get_node("../").shoot()
					var radial_change = GaussianRandom.nextGaussian3(0, PI*0.65, PI*0.12, PI*0.99)
					active_drones_destination[i] = self.global_position.direction_to(drone.global_position).rotated(radial_change)*$Area2D/CollisionShape2D.shape.radius
			i += 1

func _on_Area2D_area_shape_entered(area_id, area, area_shape, self_shape):
	if area.get_node("../") in get_tree().get_nodes_in_group("drones") and area.get_name() == "SelfArea" and !(area in active_drones):
		active_drones.append(area)
		active_drones_destination.append(self.global_position)
		print("New Drone entered!\n", area)
		print("List of active drones:", active_drones)
