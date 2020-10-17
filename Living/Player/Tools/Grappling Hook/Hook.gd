extends KinematicBody2D

const DASH_SPEED = 2000
const MAX_LENGTH = 800

var shooter
var startPos : Vector2
var motion = Vector2()
var length = 0
var attachedTo = null
var lastAttached = null
var offset = Vector2()

var isDashing=false
var dashBufferFrames=10

onready var links = $Links

signal dead
signal collided(lastAttached)

# Called when the node enters the scene tree for the first time.
func _ready():
	startPos = global_position
	if shooter != null:
		add_collision_exception_with(shooter)
	self.connect("collided", get_node("/root/Node2D/Player"), "_on_Hook_collided")
	self.connect("dead", get_node("/root/Node2D/Player"), "_on_Hook_dead")
	
func _physics_process(delta):
	if shooter == null:
		queue_free()
		return
		
	if dashBufferFrames:
		dashBufferFrames-=1
	
	if attachedTo == null:
		var collision = move_and_collide(motion*delta)
		if collision!=null:
			length = global_position.distance_to(shooter.global_position)+10
			attachedTo = collision.collider
			if attachedTo is TileMap:
				offset = attachedTo.global_position - collision.position
			set_collision_mask(0)

		if global_position.distance_to(startPos) > MAX_LENGTH:
			setDead()
			return
		
	else:
		global_position = attachedTo.global_position - offset # ERROR when killing enemy then immediately hitting grapple on it
		
		##### draw links and adjust size according to length
		links.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		$Tip.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		links.region_rect.size.y = length * 2
		
	if attachedTo != null:
		lastAttached = attachedTo
		emit_signal("collided", lastAttached)
		if isDashing or "canBePulled" in attachedTo:
			if attachedTo != null and shooter != null:
				if length <= 0 or shooter.position.distance_to(position) < DASH_SPEED*delta*2:
					setDead()
					return
				else:
					length = max(0, length - DASH_SPEED*delta)
					if !isDashing and "canBePulled" in attachedTo and attachedTo.canBePulled:
						if shooter != null:
							shooter.addFreezeFrames(1)
						attachedTo.motion = attachedTo.position.direction_to(shooter.position).normalized()*DASH_SPEED*0.25
					else:
						#Locks the player into a linear path while dashing, disable this line
						#To allow the player to continue swinging while dashing
						#The magnitude of the vector (controlled by the coeficient at the end) determines the
						#carryover speed when the dash ends
						shooter.motion = shooter.position.direction_to(position).normalized()*DASH_SPEED*0.5
						if attachedTo is Living:
							attachedTo.addFreezeFrames(5)
			
		if global_position.distance_to(shooter.global_position) > length:
			var dist = global_position.distance_to(shooter.global_position)
			var x_dist = shooter.global_position.x - global_position.x
			var y_dist = shooter.global_position.y - global_position.y
			var mag = shooter.motion.length()
			var ang = atan2(y_dist, x_dist)
			var motionAng = atan2(shooter.motion.y, shooter.motion.x)
			
			if("canBePulled" in attachedTo and attachedTo.canBePulled and !isDashing):
				attachedTo.move_and_slide(-Vector2((length-dist)*cos(ang), (length-dist)*sin(ang))/delta)
			else:
				shooter.move_and_slide(Vector2((length-dist)*cos(ang), (length-dist)*sin(ang))/delta)
			
			if !isDashing:
				#Component of motion perpendicular to point of grapple
				var perpComp = mag*sin(motionAng - ang)
				
				var perpMotion = Vector2(-perpComp*sin(ang), perpComp*cos(ang))
				shooter.motion = perpMotion
			

			

func isTense():
	return global_position.distance_to(shooter.global_position) >= length*0.99

func setShooter(shooter):
	self.shooter = shooter

func setDashing():
	isDashing=true

func onCollision(body_id, body, body_shape, area_shape):
	if body != shooter:
		length = global_position.distance_to(shooter.global_position)
		attachedTo = body
		offset = body.position - position
		
		if "canBePulled" in body:
			dashBufferFrames = 0
		
func setDead():
	attachedTo = null
	shooter.hook = null
	emit_signal("dead")
	queue_free()

	
