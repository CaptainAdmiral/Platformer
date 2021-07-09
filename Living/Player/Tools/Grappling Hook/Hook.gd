extends Projectile

const DASH_SPEED = 2000
const MAX_LENGTH = 600 # Starting length. Increase by 100 each upgrade?

var start_pos : Vector2
var length = 0
var attached_to : Node2D = null
var offset = Vector2()

var is_dashing=false
var dash_buffer_frames=10

onready var links = $Links

# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = global_position
	if shooter != null:
		add_collision_exception_with(shooter)
	
func _physics_process(delta):
	if shooter == null:
		queue_free()
		return
		
	if dash_buffer_frames:
		dash_buffer_frames-=1
	
	if attached_to == null:
		var collision = move_and_collide(motion*delta)
		if collision!=null:
			length = global_position.distance_to(shooter.global_position)+10
			attached_to = collision.collider
			if attached_to is TileMap:
				offset = attached_to.global_position - collision.position
			elif attached_to is Living:
				attached_to.connect("died", self, "set_dead", [], CONNECT_ONESHOT)
			set_collision_mask(0)

		if global_position.distance_to(start_pos) > MAX_LENGTH:
			set_dead()
			return
		
	else:
		global_position = attached_to.global_position - offset
		
		##### draw links and adjust size according to length
		links.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		$Tip.rotation = self.position.angle_to_point(shooter.global_position) + deg2rad(90)
		links.region_rect.size.y = length * 2
		
	if attached_to != null:
		if is_dashing:
			if attached_to != null and shooter != null:
				if length <= 0 or shooter.position.distance_to(position) < DASH_SPEED*delta*2:
					set_dead()
					return
				else:
					length = max(0, length - DASH_SPEED*delta)
					#Locks the player into a linear path while dashing, disable this line
					#To allow the player to continue swinging while dashing
					#The magnitude of the vector (controlled by the coeficient at the end) determines the
					#carryover speed when the dash ends
					shooter.motion = shooter.position.direction_to(position).normalized()*DASH_SPEED*0.5
					if attached_to is Living:
						attached_to.add_freeze_frames(5)
			
		if global_position.distance_to(shooter.global_position) > length:
			var dist = global_position.distance_to(shooter.global_position)
			var x_dist = shooter.global_position.x - global_position.x
			var y_dist = shooter.global_position.y - global_position.y
			var mag = shooter.motion.length()
			var ang = atan2(y_dist, x_dist)
			var motionAng = atan2(shooter.motion.y, shooter.motion.x)
			
			shooter.move_and_slide(Vector2((length-dist)*cos(ang), (length-dist)*sin(ang))/delta)
			
			if !is_dashing:
				#Component of motion perpendicular to point of grapple
				var perpComp = mag*sin(motionAng - ang)
				
				var perpMotion = Vector2(-perpComp*sin(ang), perpComp*cos(ang))
				shooter.motion = perpMotion
				
func get_attached():
	if attached_to == null:
		return null
	if !is_instance_valid(attached_to):
		return null
	return attached_to

func is_tense():
	return attached_to != null and global_position.distance_to(shooter.global_position) >= length*0.99

func set_shooter(shooter):
	self.shooter = shooter

func set_dashing():
	is_dashing=true
		
func set_dead():
	attached_to = null
	shooter.hook = null
	queue_free()
