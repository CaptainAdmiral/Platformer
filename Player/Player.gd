extends KinematicBody2D

const UP = Vector2(0, -1)
const SNAP_VECTOR = Vector2(0, 64)

const RUN_SPEED = 1500
const RUN_ACCELERATION_FRAMES = 120
const GROUND_FRICTION = 0.8
const FALL_SPEED = 30
const AIR_FRICTION = 0.98 #Only used for horizontal momentum decay in air

const FULL_HOP_VELOCITY = 900
const SHORT_HOP_VELOCITY = 550
const JUMP_SQUAT_FRAMES = 6
const JUMP_BOOST_FRAMES = 12
const JUMP_BOOST_SPEED = SHORT_HOP_VELOCITY / JUMP_BOOST_FRAMES * 0.85

const WALL_SLIDE_SPEED = 240
const WALL_JUMP_GRACE_FRAMES=10

const HOOK_SPEED = 50
const GRAPPLED_AIR_ACCELERATION = 0.5

#calculated values
const AIR_SPEED = RUN_SPEED / 1.5
const AIR_ACCELERATION_FRAMES = RUN_ACCELERATION_FRAMES
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES
const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED / 3, FULL_HOP_VELOCITY)

var motion = Vector2()

onready var inputBuffer = $InputBuffer

var Hook = load("res://Player/Tools/Grappling Hook/Hook.tscn")
var hook : Area2D = null

var jumpSquat = 0
var jumpBoost = 0
var grappleWindup = 0
var slideFrames = 0

var canLeftWallJump = 0
var canRightWallJump = 0

var storedMotion = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.		

func _physics_process(_delta):
	var shouldStick = hook==null
	
	#Momentum Transfer
	if Input.is_action_just_pressed("momentum"):
		var m = motion
		motion = storedMotion
		storedMotion = m
		shouldStick = false
		
	
	#Grappling Hook Stuff
	if Input.is_action_just_released("hook") and hook != null:
		hook.queue_free()
		hook = null
		
	if Input.is_action_just_pressed("hook") and hook == null:
		hook = Hook.instance()
		hook.setShooter(self)
		get_parent().add_child(hook)
#			print(event.position)
#			print(get_global_mouse_position())
#			print(position)
		var direction = (get_global_mouse_position() - position).normalized()
		
		hook.position = position
		hook.motion = direction*HOOK_SPEED

#		hook = Hook.instance()
#		hook.setShooter(self)
#		get_parent().add_child(hook)
#
#		var direction = getDirectionFromInput()
#
#		hook.position = position
#		hook.motion = direction*HOOK_SPEED
		
	if hook != null:
		hook.releaseTension = Input.is_action_pressed("tension")
		
	#Ground Movement
	if is_on_floor():
#		if !jumpSquat and inputBuffer.hasAction(inputBuffer.JUMP_PRESS, 10):
#			jumpSquat = JUMP_SQUAT_FRAMES

		#Jump
		if inputBuffer.hasAction("up", false, 10):
			shouldStick = false
			motion.y -= SHORT_HOP_VELOCITY
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
			
	if !slideFrames and inputBuffer.hasAction("down"):
		slideFrames = 90
	
	if slideFrames:
		if slideFrames == 90:
			motion.x*=1.5
		motion*=0.975
			
		slideFrames-=1
			
			
# warning-ignore:integer_division
		motion.y += FALL_SPEED/2
		
	else:
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
			if motion.x < AIR_SPEED:
				if hook != null and hook.isTense():
					motion.x = min(motion.x + GRAPPLED_AIR_ACCELERATION, AIR_SPEED)
				else:
					motion.x = min(motion.x + AIR_ACCELERATION, AIR_SPEED)
				
		elif Input.is_action_pressed("left"):
			if motion.x > 0:
				motion.x *= AIR_FRICTION
			if -motion.x < AIR_SPEED:
				if hook != null and hook.isTense():
					motion.x = -min(-motion.x + GRAPPLED_AIR_ACCELERATION, AIR_SPEED)
				else:
					motion.x = -min(-motion.x + AIR_ACCELERATION, AIR_SPEED)
		else:
			motion.x *= AIR_FRICTION
			
		motion.y += FALL_SPEED
	
	
	#Wall Jump Movement
	if canLeftWallJump != 0:
		canLeftWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("right", false, 6):
			if motion.y < WALL_SLIDE_SPEED+10:
				motion.y = WALL_SLIDE_SPEED
			motion.y-=WALL_JUMP_VELOCITY.y
			motion.x += WALL_JUMP_VELOCITY.x
			canLeftWallJump = 0
			
		
	if canRightWallJump != 0:
		canRightWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("left", false, 6):
			if motion.y < WALL_SLIDE_SPEED+10:
				motion.y = WALL_SLIDE_SPEED
			motion.y-=WALL_JUMP_VELOCITY.y
			motion.x -= WALL_JUMP_VELOCITY.x
			canRightWallJump = 0
		
		
	#Jump
#	if jumpSquat:
#		if(!Input.is_action_pressed("jump")):
#			jumpSquat = 1
#		if jumpSquat == 1:
#			shouldStick = false
#			if Input.is_action_pressed("jump"):
#				motion.y-=FULL_HOP_VELOCITY
#			else:
#				motion.y-=SHORT_HOP_VELOCITY
#
#		jumpSquat-=1
		
		
	motion = move_and_slide_with_snap(motion, SNAP_VECTOR if shouldStick else Vector2(), UP)
		

func getDirectionFromInput():
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("ui_up"):
		y-=1
	if Input.is_action_pressed("ui_down"):
		y+=1
	if Input.is_action_pressed("ui_left"):
		x-=1
	if Input.is_action_pressed("ui_right"):
		x+=1
												#Baked value for 1/sqrt2
	return Vector2(x, y) if !(x!=0 and y!=0) else 0.70710678118*Vector2(x, y)
