extends Area2D

var shooter
var motion = Vector2()
var isAttached = false
var length = 0
var attatchedTo = null
var offset = Vector2()
var releaseTension=false
var tenseLastFrame=false

onready var links = $Links

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
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
		tenseLastFrame = false
		if releaseTension:
			length = max(length, global_position.distance_to(shooter.global_position))
		else:
			if global_position.distance_to(shooter.global_position) >= length:
				var dist = global_position.distance_to(shooter.global_position)
				var x_dist = shooter.global_position.x - global_position.x
				var y_dist = shooter.global_position.y - global_position.y
				var mag = sqrt(pow(shooter.motion.x, 2)+pow(shooter.motion.y, 2))
				var ang = atan2(y_dist, x_dist)
				
				if !tenseLastFrame:
					shooter.position.x -= (dist-length)*cos(ang)
					shooter.position.y -= (dist-length)*sin(ang)
					
					var motionAng = atan2(shooter.motion.y, shooter.motion.x)
					var mag2 = mag*sin(90-ang+atan2(y_dist, x_dist))
					
					shooter.motion-=Vector2(mag2*cos(ang), mag2*sin(ang))
				else:
					var newAng = ang - mag/length
					var newPos = Vector2(mag*cos(newAng), mag*sin(newAng))
					shooter.motion = newPos - shooter.position
				tenseLastFrame = true


func isTense():
	return global_position.distance_to(shooter.global_position) >= length*0.999

func setShooter(shooter):
	self.shooter = shooter

func onCollision(body_id, body, body_shape, area_shape):
	if body != shooter:
		isAttached = true
		length = global_position.distance_to(shooter.global_position)
		attatchedTo = body
		offset = body.position - position
