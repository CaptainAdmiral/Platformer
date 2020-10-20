extends Area2D


# Declare member variables here. Examples:
var velocity
var player 
var direction 
var position_init
var proj_range
var extra_range = 400 # Range beyond the player where projectile will disappear

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func init(parent, vel):
		position = parent.position
		position_init = position
		velocity = vel
		
		parent.get_node("/root/Node2D/Projectiles").add_child(self)
		player = parent.get_node("/root/Node2D/Player")
		proj_range = position.distance_to(player.position) + extra_range
		direction = position.direction_to(player.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += direction.normalized() * velocity * delta
	if position.distance_to(position_init) > proj_range:
		queue_free()
