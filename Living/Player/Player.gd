extends Living

const RUN_SPEED = 500
const RUN_ACCELERATION_FRAMES = 20
const GROUND_FRICTION = 0.7
const FALL_SPEED = 30
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 500
const JUMP_BOOST_FRAMES = 15
const JUMP_GRACE_FRAMES = 5

const DASH_SPEED = 1800
const DASH_FRAMES = 10
const DASH_FREEZE_FRAMES = 3

const CROUCH_SLOWDOWN = 0.875
const SLIDE_SLOWDOWN = 0.95
const SLIDE_FRAMES = 40

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED, JUMP_VELOCITY)
const WALL_SLIDE_SPEED = 120
const WALL_JUMP_GRACE_FRAMES=10
const WALL_JUMP_GRACE_DISTANCE = 40

const ATTACK_COOLDOWN_FRAMES = 15
const ATTACK_KNOCKBACK = 1000
const SWORD_POGO_VELOCITY = 700

#How many frames the player is immune for after taking damage
const DAMAGE_IFRAMES = 60

const HOOK_SPEED = 4200

#calculated values
const AIR_SPEED = RUN_SPEED
const AIR_ACCELERATION_FRAMES = RUN_ACCELERATION_FRAMES*2
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES
const JUMP_BOOST_SPEED = JUMP_VELOCITY / JUMP_BOOST_FRAMES

onready var inputBuffer = $InputBuffer

var attackCooldownFrames : int = 0
var attackDamage : float  = 1
var maxCombo : int = 3
var combo : int = 1
var maxComboFrames : int = 300
var comboFrames : int = 0

var hurtFrames : int = 0

export(String, FILE, "*.tscn") var HookPath
onready var Hook = load(HookPath)
var hook : KinematicBody2D = null

var maxHookCharges: int = 1
var hookCharges : int = maxHookCharges
var grappleWindup : int = 0

var dashFrames : int = 0
var maxDashCharges : int = 1
var dashCharges : int = maxDashCharges
var dashDirection = Vector2()

var jumpBoost : int = 0
var jumpGraceFrames : int = 0

var canLeftWallJump : int = 0
var canRightWallJump : int = 0

var isCrouching : bool = false

var slideFrames : int = 0

var onGround = false
var prevOnGround = false

var checkpointScene : Node
var checkpoint : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	fallSpeed = FALL_SPEED

func _physics_process(_delta):
	prevOnGround = onGround
	onGround = is_on_floor()
	
	if comboFrames:
		comboFrames -= 1
		if comboFrames == 0:
			combo = 1
	
	######################## ANIMATIONS ##################################
	if ($AnimatedSprite.animation == "run" or $AnimatedSprite.animation == "run start") and abs(motion.x) < 50:
		$AnimatedSprite.stop()
	
	if !$AnimatedSprite.playing:
		$AnimatedSprite.play("idle")
		
	if !onGround and motion.y > 10:
		if $AnimatedSprite.animation == "jump":
			$AnimatedSprite.play("fall")
		elif $AnimatedSprite.animation == "run jump" or $AnimatedSprite.animation == "run":
			$AnimatedSprite.play("fall")
			$AnimatedSprite.set_frame(3)
	
			
	
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
		
	######################## ATTACK ##################################
	if attackCooldownFrames:
		attackCooldownFrames -= 1
		
	if hurtFrames:
		hurtFrames -= 1
	
	if Input.is_action_just_pressed("attack") and ! attackCooldownFrames:
		swingSword()
	
	######################## ON GROUND ##################################
	if is_on_floor():	
		refreshHook()
		refreshDash()
		jumpGraceFrames = JUMP_GRACE_FRAMES
		
		if prevOnGround == false:
			onLand()
			
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
		if prevOnGround == true:
			onLeaveGround()
		
		if jumpBoost:
			if Input.is_action_pressed("up"):
				motion.y-=JUMP_BOOST_SPEED
			jumpBoost-=1
			
		if hook != null and hook.isTense():
			slideFrames = 0
		
		#Air Movement
		if hook == null or hook.attachedTo == null or !hook.isTense():
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
			
			
	
	#Jump
	if jumpGraceFrames:
		jumpGraceFrames-=1
		if inputBuffer.hasAction("up", false, 10) and hurtFrames < DAMAGE_IFRAMES - 5:
			jump()
	
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

	#Dash
	if dashFrames:
		dashFrames -= 1
		if dashFrames >= DASH_FRAMES:
			motion = Vector2(0,0)
		else:
			motion = dashDirection * DASH_SPEED
			if !dashFrames:
				motion = dashDirection * AIR_SPEED * 1.3
				
	
	motion = move_and_slide(motion, Vector2(0, -1))	

func getDirectionFromInput() -> Vector2:
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
	
func setFacing(direction) -> void:
	facing = direction
	if direction == Direction.LEFT:
		$AnimatedSprite.flip_h = true
	elif direction == Direction.RIGHT:
		$AnimatedSprite.flip_h = false
	
func jump() -> void:
	jumpGraceFrames=0
	
	motion.y -= JUMP_VELOCITY
	if slideFrames < SLIDE_FRAMES * 0.5:
		jumpBoost = JUMP_BOOST_FRAMES
	else:
# warning-ignore:integer_division
		jumpBoost = JUMP_BOOST_FRAMES / 2
	
	slideFrames = 0
	if $AnimatedSprite.animation == "idle":
		$AnimatedSprite.play("jump")
	elif $AnimatedSprite.animation == "run start":
		var frame = $AnimatedSprite.frame
		$AnimatedSprite.play("jump")
		$AnimatedSprite.set_frame(frame+1)
	else:
		$AnimatedSprite.play("run jump")
	
func slide() -> void:
	if !slideFrames and !isCrouching:
		setCrouching(true)
		if motion.x >= RUN_SPEED*0.75:
			slideFrames = SLIDE_FRAMES
			motion.x += RUN_SPEED*1.75
		elif -motion.x >= RUN_SPEED*0.75:
			slideFrames = SLIDE_FRAMES
			motion.x -= RUN_SPEED*1.75
	
func setCrouching(crouching) -> void:
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
		$AnimatedSprite.play("slide")
		$Hitbox.set_deferred("disabled", true)
		$CrouchHitbox.set_deferred("disabled", false)
	else:
		$AnimatedSprite.play("run")
		$Hitbox.set_deferred("disabled", false)
		$CrouchHitbox.set_deferred("disabled", true)
	
	
func run(direction) -> void:
	setFacing(direction)
	
	if $AnimatedSprite.animation == "idle":
		$AnimatedSprite.play("run start")
	elif !$AnimatedSprite.playing:
		$AnimatedSprite.play("run")
	
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

func airDrift(direction) -> void:
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
			
func _on_Right_body_entered(_body):
	canRightWallJump = WALL_JUMP_GRACE_FRAMES

func _on_Left_body_entered(_body):
	canLeftWallJump = WALL_JUMP_GRACE_FRAMES

func wallJump(direction) -> void:
	motion.y=-WALL_JUMP_VELOCITY.y
	if direction == Direction.RIGHT:
		motion.x = WALL_JUMP_VELOCITY.x
		canLeftWallJump = 0
		setFacing(Direction.RIGHT)
	elif direction == Direction.LEFT:
		motion.x = -WALL_JUMP_VELOCITY.x
		canRightWallJump = 0
		setFacing(Direction.LEFT)
	jumpBoost=JUMP_BOOST_FRAMES
	dashFrames = 0

func dash(direction) -> void:
	if slideFrames:
		return
	dashCharges -= 1
	if hook != null and hook.isDashing:
		hook.setDead()
	if hook != null and hook.attachedTo != null and direction != Vector2(0,0):
		motion += direction * DASH_SPEED * 0.5
	else:
		dashDirection = direction
		dashFrames = DASH_FRAMES + DASH_FREEZE_FRAMES
		
		
func throwHook() -> void:
	hookCharges -= 1
	hook = Hook.instance()
	hook.setShooter(self)
	hook.position = position
	hook.motion = (get_global_mouse_position() - position).normalized()*HOOK_SPEED
	get_parent().add_child(hook)
	
func swingSword() -> void:
	attackCooldownFrames = ATTACK_COOLDOWN_FRAMES
	
	var rot = get_global_mouse_position().angle_to_point(global_position)
	var isDownSwing = rot > PI/5 and rot < 4*PI/5
	var hitSomething = false
	
	$AttackArea.rotation = rot
	
	
	if hook != null:
		hook.setDead()
		
	var damage : Damage = Damage.new(self, 1*combo, Damage.TYPE.PHYSICAL)	
	for body in $AttackArea.get_overlapping_bodies():
		print(body.get_name())
		if body is Living:
			var knockback = motion + global_position.direction_to(body.global_position)*ATTACK_KNOCKBACK
			if body.is_on_floor():
				knockback.y = min(-300, knockback.y)
			
			if body.hurt(damage):
				body.addKnockback(knockback, true)
				hitSomething = true
			
		if body.is_in_group("attackable"):
			body.onAttacked(damage)
			
		if isDownSwing and hitSomething:
			swordPogo()
			

func swordPogo():
	motion.y = min(-SWORD_POGO_VELOCITY, motion.y)

func hurt(damage : Damage) -> bool:
	if hurtFrames:
		return false
	hurtFrames = DAMAGE_IFRAMES
	attackCooldownFrames = ATTACK_COOLDOWN_FRAMES
	dashFrames = 0
	jumpGraceFrames = 0
	jumpBoost = 0
	if hook !=null:
		hook.setDead()
	return .hurt(damage)
	
func onKill(body : Living) -> void:
	combo += 1
	comboFrames = maxComboFrames
	
	refreshDash()
	refreshHook()
	
func refreshDash():
	dashCharges = maxDashCharges
	
func refreshHook():
	hookCharges = maxHookCharges
	
func setDead() -> void:
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
	
func onLeaveGround() -> void:
	pass
	
func onLand() -> void:
	if $AnimatedSprite.animation == "run jump":
		$AnimatedSprite.stop()
		
	if $AnimatedSprite.animation == "jump":
		$AnimatedSprite.stop()
		
	if $AnimatedSprite.animation == "fall":
		$AnimatedSprite.stop()


func onAnimationFinished() -> void:
	var anim = $AnimatedSprite.animation
	
	if anim == "run start":
		$AnimatedSprite.play("run")
