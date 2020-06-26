extends Area2D #TODO change to kinematic

var shooter
var motion = Vector2()
var isAttached = false
var length = 0
var attatchedTo = null
var offset = 0
var releaseTension=false
onready var links = $Links 
var direction = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

#func _process(_delta: float) -> void:
	

func _physics_process(delta):
	if shooter == null:
		queue_free()
		return
	
	if attatchedTo == null:
		position += motion
	else:
		position = attatchedTo.position - offset
		
		##### draw links and adjust size according to length
		links.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		$Tip.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		links.region_rect.size.y = length * 2
		
	if isAttached:
		if releaseTension:
			length = max(length, global_position.distance_to(shooter.global_position))
		else:	
			if global_position.distance_to(shooter.global_position) >= length:
				var dist = global_position.distance_to(shooter.global_position)
				var x_dist = shooter.global_position.x - global_position.x
				var y_dist = shooter.global_position.y - global_position.y
				var ang = atan2(y_dist, x_dist)
				shooter.position.x -= (dist-length)*cos(ang)
				shooter.position.y -= (dist-length)*sin(ang)
				
				var mag = sqrt(pow(shooter.motion.x, 2)+pow(shooter.motion.y, 2))
				var motionAng = atan2(shooter.motion.y, shooter.motion.x)
				var mag2 = mag*sin(90-ang+atan2(y_dist, x_dist))
				print(mag)
				
				shooter.motion-=Vector2(mag2*cos(ang), mag2*sin(ang))
				#TODO replace with conserved momentum formula if already at max range

func isTense():
	return global_position.distance_to(shooter.global_position) >= length*0.99

func setShooter(shooter):
	self.shooter = shooter

func onCollision(body_id, body, body_shape, area_shape):
	if body != shooter:
		isAttached = true
		length = global_position.distance_to(shooter.global_position)
		attatchedTo = body
		offset = body.position - position
