extends KinematicBody2D

#TODO refactor for clarity

const UP = Vector2(0, -1)
const SNAP_VECTOR = Vector2(0, 64)

const RUN_SPEED = 700
const RUN_ACCELERATION_FRAMES = 20
const GROUND_FRICTION = 0.7
const FALL_SPEED = 40
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 600
const JUMP_BOOST_FRAMES = 10

const DASH_SPEED = 2000
const DASH_FRAMES = 10

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED/2, JUMP_VELOCITY)
const WALL_SLIDE_SPEED = 240
const WALL_JUMP_GRACE_FRAMES=10

const HOOK_SPEED = 70
const GRAPPLED_AIR_ACCELERATION = 0.1

#calculated values
const AIR_SPEED = RUN_SPEED
const AIR_ACCELERATION_FRAMES = RUN_ACCELERATION_FRAMES*2
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES
const JUMP_BOOST_SPEED = JUMP_VELOCITY / JUMP_BOOST_FRAMES


var motion = Vector2()

onready var inputBuffer = $InputBuffer

var Hook = load("res://Player/Tools/Grappling Hook/Hook.tscn")
var hook : Area2D = null

var canHook = true
var hookCharges = 0
var grappleWindup = 0

var dashFrames = 0
var dashCharges = 0
var dashDirection = Vector2()

var jumpBoost = 0

var canLeftWallJump = 0
var canRightWallJump = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.player = self

func _physics_process(_delta):
	var shouldStick = hook==null
	canHook = true	
	
	#Grappling Hook Stuff
	if Input.is_action_just_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()
		
	if Input.is_action_just_pressed("hook") and canHook and hook == null:
		canHook = false
		hook = Hook.instance()
		hook.setShooter(self)
		get_parent().add_child(hook)
		var direction = (get_global_mouse_position() - position).normalized()
		
		hook.position = position
		hook.motion = direction*HOOK_SPEED
		
	#Ground Movement
	if is_on_floor():
		canHook = true

		#Jump
		if inputBuffer.hasAction("up", false, 10):
			shouldStick = false
			motion.y -= JUMP_VELOCITY
			jumpBoost = JUMP_BOOST_FRAMES
		
		if Input.is_action_pressed("right"):
			if motion.x < 0:
				motion.x *= GROUND_FRICTION
				motion.x+= RUN_ACCELERATION
			if motion.x < RUN_SPEED:
				motion.x = min(motion.x + RUN_ACCELERATION, RUN_SPEED)
				
		elif Input.is_action_pressed("left"):
			if motion.x > 0:
				motion.x *= GROUND_FRICTION
				motion.x-= RUN_ACCELERATION
			if -motion.x < RUN_SPEED:
				motion.x = -min(-motion.x + RUN_ACCELERATION, RUN_SPEED)
				
		else:
			motion.x *= GROUND_FRICTION
			
		if abs(motion.x) > RUN_SPEED:
			motion.x*=0.9
		
	else:
		#In air stuff
		
		if jumpBoost:
			if Input.is_action_pressed("up"):
				motion.y-=JUMP_BOOST_SPEED
			jumpBoost-=1
		
		#Can Wall Jump Check
		if is_on_wall():
			if motion.y > WALL_SLIDE_SPEED:
				motion.y = max(motion.y/2, WALL_SLIDE_SPEED)
			
			for i in range(get_slide_count()):
				var collision = get_slide_collision(i)
				if collision.normal.x > 0:
					#left wall walljump
					canLeftWallJump = WALL_JUMP_GRACE_FRAMES
					
						
				elif collision.normal.x < 0:
					#right wall walljump
					canRightWallJump = WALL_JUMP_GRACE_FRAMES
		
		#Air Movement
		if Input.is_action_pressed("right"):
			if motion.x < 0:
				motion.x *= AIR_FRICTION
			if motion.x < AIR_SPEED and !(hook != null and hook.isTense()):
				motion.x = min(motion.x + AIR_ACCELERATION, AIR_SPEED)
				
		elif Input.is_action_pressed("left"):
			if motion.x > 0:
				motion.x *= AIR_FRICTION
			if -motion.x < AIR_SPEED and !(hook != null and hook.isTense()):
				motion.x = -min(-motion.x + AIR_ACCELERATION, AIR_SPEED)
		else:
			motion.x *= AIR_FRICTION
			
		motion.y += FALL_SPEED
	
	
	#Wall Jump Movement
	if canLeftWallJump != 0:
		canLeftWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("right", false, 6):
			motion.y=-WALL_JUMP_VELOCITY.y
			motion.x = WALL_JUMP_VELOCITY.x
			jumpBoost=JUMP_BOOST_FRAMES
			canLeftWallJump = 0
			dashFrames = 0
			
		
	if canRightWallJump != 0:
		canRightWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("left", false, 6):
			motion.y=-WALL_JUMP_VELOCITY.y
			motion.x = -WALL_JUMP_VELOCITY.x
			jumpBoost=JUMP_BOOST_FRAMES
			canRightWallJump = 0
			dashFrames = 0
		
	if Input.is_action_just_pressed("dash"):
		shouldStick = false
		if hook != null and hook.isDashing:
			hook.setDead()
		if hook != null and hook.attachedTo != null:
			motion += getDirectionFromInput() * DASH_SPEED * 0.5
		else:
			dashDirection = getDirectionFromInput()
			dashFrames = DASH_FRAMES
		
	if dashFrames:
		motion = dashDirection * DASH_SPEED
		dashFrames -= 1
		if !dashFrames:
			motion = dashDirection * AIR_SPEED
	
	motion = move_and_slide_with_snap(motion, SNAP_VECTOR if shouldStick else Vector2(), UP)
		

func getDirectionFromInput():
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("up"):
		y-=1
	if Input.is_action_pressed("down"):
		y+=1
	if Input.is_action_pressed("left"):
		x-=1
	if Input.is_action_pressed("right"):
		x+=1
												#Baked value for 1/sqrt2
	return Vector2(x, y) if !(x!=0 and y!=0) else 0.70710678118*Vector2(x, y)
