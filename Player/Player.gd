extends KinematicBody2D

#TODO refactor for clarity

const RUN_SPEED = 700
const RUN_ACCELERATION_FRAMES = 20
const GROUND_FRICTION = 0.7
const FALL_SPEED = 40
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 640
const JUMP_BOOST_FRAMES = 10

const DASH_SPEED = 1800
const DASH_FRAMES = 10
const DASH_FREEZE_FRAMES = 3

const CROUCH_SLOWDOWN = 0.875
const SLIDE_SLOWDOWN = 0.95
const SLIDE_FRAMES = 40

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED, JUMP_VELOCITY)
const WALL_SLIDE_SPEED = 240
const WALL_JUMP_GRACE_FRAMES=10

const HOOK_SPEED = 70

#calculated values
const AIR_SPEED = RUN_SPEED
const AIR_ACCELERATION_FRAMES = RUN_ACCELERATION_FRAMES*2
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES
const JUMP_BOOST_SPEED = JUMP_VELOCITY / JUMP_BOOST_FRAMES


var motion = Vector2()
enum Direction {UP, DOWN, LEFT, RIGHT}
var facing = Direction.RIGHT

onready var inputBuffer = $InputBuffer

var Hook = load("res://Player/Tools/Grappling Hook/Hook.tscn")
var hook : KinematicBody2D = null

var hookCharges : int = 0
var grappleWindup : int = 0

var dashFrames : int = 0
var dashCharges : int = 0
var dashDirection = Vector2()

var jumpBoost : int = 0

var canLeftWallJump : int = 0
var canRightWallJump : int = 0

var isCrouching : bool = false

var slideFrames : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.player = self

func _physics_process(_delta):
	######################## SLIDING / CROUCHING ##################################
	
	if !Input.is_action_pressed("down"):
			setCrouching(false)
	
	if slideFrames:
		slideFrames-=1
	
	######################## GRAPPLING HOOK ##################################
	
	if Input.is_action_just_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()
		
	if Input.is_action_just_pressed("hook") and hookCharges > 0 and hook == null:
		throwHook()
		
	######################## ON GROUND ##################################
	if is_on_floor():
		hookCharges = 2
		dashCharges = 1

		#Jump
		if inputBuffer.hasAction("up", false, 10):
			jump()
			
		if !(Input.is_action_pressed("right") and Input.is_action_pressed("left") or slideFrames):
			if Input.is_action_pressed("right"):
				run(Direction.RIGHT)
				
			if Input.is_action_pressed("left"):
				run(Direction.LEFT)
				
		if !(motion.x > 0 and Input.is_action_pressed("right") or motion.x < 0 and Input.is_action_pressed("left")) and !slideFrames:
			motion.x *= GROUND_FRICTION
		
		if slideFrames:
			motion.x *= SLIDE_SLOWDOWN
		elif isCrouching:
			motion.x *= CROUCH_SLOWDOWN
			
		if abs(motion.x) > RUN_SPEED:
			motion.x*=0.99
			
		if Input.is_action_pressed("down"):
			slide()
			setCrouching(true)
			
	
	else:
		######################## IN AIR ##################################
		
		if jumpBoost:
			if Input.is_action_pressed("up"):
				motion.y-=JUMP_BOOST_SPEED
			jumpBoost-=1
			
		if hook != null and hook.isTense():
			slideFrames = 0
		
		#Air Movement
		if !(Input.is_action_pressed("right") and Input.is_action_pressed("left") or slideFrames):
			if Input.is_action_pressed("right"):
				airDrift(Direction.RIGHT)
					
			if Input.is_action_pressed("left"):
				airDrift(Direction.LEFT)
			
		if !(Input.is_action_pressed("right") or Input.is_action_pressed("left")):
			motion.x *= AIR_FRICTION
		
		######################## ON WALL ##################################
		if is_on_wall():
			if motion.y > WALL_SLIDE_SPEED:
				motion.y = max(motion.y/2, WALL_SLIDE_SPEED)
			
			setCanWallJump()
	
	
	#Wall Jump Movement
	if canLeftWallJump:
		canLeftWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("right", false, 6):
			wallJump(Direction.RIGHT)
			
		
	if canRightWallJump:
		canRightWallJump-=1
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("left", false, 6):
			wallJump(Direction.LEFT)
		
	if Input.is_action_just_pressed("dash") and dashCharges > 0:
		dash(getDirectionFromInput())	

		
	if dashFrames:
		dashFrames -= 1
		if dashFrames >= DASH_FRAMES:
			motion = Vector2(0,0)
		else:
			motion = dashDirection * DASH_SPEED
			if !dashFrames:
				motion = dashDirection * AIR_SPEED * 1.3
				
	motion.y += FALL_SPEED
	
	motion = move_and_slide(motion, Vector2(0, -1))
	
	if(is_on_floor() and motion.y > FALL_SPEED):
		motion.y = FALL_SPEED
		

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
	
func setFacing(direction):
	facing = direction
	if direction == Direction.LEFT:
		$AnimatedSprite.flip_h = true
	elif direction == Direction.RIGHT:
		$AnimatedSprite.flip_h = false
	
func jump():
	motion.y -= JUMP_VELOCITY
	if slideFrames < SLIDE_FRAMES * 0.5:
		jumpBoost = JUMP_BOOST_FRAMES
	else:
		jumpBoost = JUMP_BOOST_FRAMES / 2
	
	slideFrames = 0
	
func slide():
	if !slideFrames and !isCrouching:
		setCrouching(true)
		if motion.x >= RUN_SPEED*0.75:
			slideFrames = SLIDE_FRAMES
			motion.x += RUN_SPEED*1.75
		elif -motion.x >= RUN_SPEED*0.75:
			slideFrames = SLIDE_FRAMES
			motion.x -= RUN_SPEED*1.75
	
func setCrouching(crouching):
	if isCrouching == crouching:
		return
		
	if slideFrames:
		return
		
	var canStand = true
	
	for body in $StandingHitboxArea.get_overlapping_bodies():
		if body is StaticBody2D or body is TileMap:
			canStand = false
		
	if !crouching and !canStand:
		return
	
	isCrouching = crouching
	
	#TODO place on ground
	
	if isCrouching:
		$AnimatedSprite.scale.y *= 0.5
		$Hitbox.set_deferred("disabled", true)
		$CrouchHitbox.set_deferred("disabled", false)
	else:
		$AnimatedSprite.scale.y *= 2
		$Hitbox.set_deferred("disabled", false)
		$CrouchHitbox.set_deferred("disabled", true)
	
	
func run(direction):
	setFacing(direction)
	if direction == Direction.RIGHT:
		if motion.x < 0:
			motion.x *= GROUND_FRICTION
			motion.x += RUN_ACCELERATION
		if motion.x < RUN_SPEED:
			motion.x = min(motion.x + RUN_ACCELERATION, RUN_SPEED)
	elif direction == Direction.LEFT:
		if motion.x > 0:
			motion.x *= GROUND_FRICTION
			motion.x -= RUN_ACCELERATION
		if -motion.x < RUN_SPEED:
			motion.x = max(motion.x - RUN_ACCELERATION, -RUN_SPEED)

func airDrift(direction):
	setFacing(direction)
	if direction == Direction.RIGHT:
		if motion.x < 0:
			motion.x *= AIR_FRICTION
		if motion.x < AIR_SPEED and !(hook != null and hook.isTense()):
			motion.x = min(motion.x + AIR_ACCELERATION, AIR_SPEED)
	elif direction == Direction.LEFT:
		if motion.x > 0:
			motion.x *= AIR_FRICTION
		if -motion.x < AIR_SPEED and !(hook != null and hook.isTense()):
			motion.x = max(motion.x - AIR_ACCELERATION, -AIR_SPEED)
		
		
func setCanWallJump():
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		if collision.normal.x > 0:
			#left wall walljump
			canLeftWallJump = WALL_JUMP_GRACE_FRAMES
			
				
		elif collision.normal.x < 0:
			#right wall walljump
			canRightWallJump = WALL_JUMP_GRACE_FRAMES

func wallJump(direction):
	motion.y=-WALL_JUMP_VELOCITY.y
	if direction == Direction.RIGHT:
		motion.x = WALL_JUMP_VELOCITY.x
		canLeftWallJump = 0
		setFacing(Direction.RIGHT)
	elif direction == Direction.LEFT:
		motion.x = -WALL_JUMP_VELOCITY.x
		canRightWallJump = 0
		facing = Direction.LEFT
		setFacing(Direction.LEFT)
	jumpBoost=JUMP_BOOST_FRAMES
	dashFrames = 0

func dash(direction):
	if slideFrames:
		return
	dashCharges -= 1
	if hook != null and hook.isDashing:
		hook.setDead()
	if hook != null and hook.attachedTo != null:
		motion += direction * DASH_SPEED * 0.5
	else:
		dashDirection = direction
		dashFrames = DASH_FRAMES + DASH_FREEZE_FRAMES
		
		
func throwHook():
	hookCharges -= 1
	hook = Hook.instance()
	hook.setShooter(self)
	get_parent().add_child(hook)
	
	hook.position = position
	hook.motion = (get_global_mouse_position() - position).normalized()*HOOK_SPEED
