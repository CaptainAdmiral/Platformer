extends Living


export var swordPogoAnyAngle = true

const RUN_SPEED = 500
const RUN_ACCELERATION_FRAMES = 20
const GROUND_FRICTION = 0.7
const FALL_SPEED = 30
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 500
const JUMP_BOOST_SPEED = 30

const DASH_SPEED = 1800

const CROUCH_SLOWDOWN = 0.875
const SLIDE_SLOWDOWN = 0.95

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED, JUMP_VELOCITY)
const WALL_SLIDE_SPEED = 120

const ATTACK_KNOCKBACK = 1000
const SWORD_POGO_VELOCITY = 700

const HOOK_SPEED = 4200

#calculated values
const AIR_SPEED = RUN_SPEED
const AIR_ACCELERATION_FRAMES = RUN_ACCELERATION_FRAMES*2
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES

onready var inputBuffer = $InputBuffer

var attackDamage : float  = 1
var maxCombo : int = 3
var combo : int = 1

var hurtFrames : int = 0

export(String, FILE, "*.tscn") var HookPath
onready var Hook = load(HookPath)
var hook : KinematicBody2D = null

var maxHookCharges: int = 1
var hookCharges : int = maxHookCharges
var grappleWindup : int = 0

var maxDashCharges : int = 1
var dashCharges : int = maxDashCharges
var dashDirection = Vector2()
var dashPogo : bool = false

var isCrouching : bool = false

var checkpointScene : Node
var checkpoint : Node

var mana : float = 0
var maxMana : int = 100
var manaOvercapDecay = 0.025
var isHealing : bool = false
var manaPerHealth : float = 50
var manaPerFrame : float = 0.2
var manaUntilNextHeal : float  = manaPerHealth
var isChargingHeal : bool = false
var healCharge : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	fallSpeed = FALL_SPEED
	setMaxHealth(6)

func _physics_process(_delta):
	print(health)
	print(mana)
	print("\n")
	
	
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
			
	######################## MANA / HEALING ##################################
	
	if !isChargingHeal:
		healCharge = 0
	else:
		healCharge+=1
		if healCharge >= 60:
			isHealing = true
			isChargingHeal = false
	
	if mana > maxMana:
		mana -= manaOvercapDecay
		
	if health == maxHealth:
		isHealing = false
		
	if isHealing:
		if useMana(manaPerFrame):
			manaUntilNextHeal-=manaPerFrame
			if manaUntilNextHeal <= 0:
				heal(1)
				manaUntilNextHeal += manaPerHealth
		else:
			isHealing = false
			mana = 0
	else:
		pass
		#manaUntilNextHeal = manaPerHealth
			
			
	
	######################## SLIDING / CROUCHING ##################################
	
	if !Input.is_action_pressed("down"):
		setCrouching(false)
		isChargingHeal = false
	
	######################## GRAPPLING HOOK ##################################
	
	if Input.is_action_just_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()
		
	if Input.is_action_just_pressed("hook") and hookCharges > 0 and hook == null:
		throwHook()
		
	######################## ATTACK ##################################
	if Input.is_action_just_pressed("attack") and !$FrameCounters/AttackCooldown.active():
		swingSword()
	
	######################## ON GROUND ##################################
	if is_on_floor():	
		refreshHook()
		refreshDash()
		$FrameCounters/JumpGrace.start()
		
		if prevOnGround == false:
			onLand()
			
		
		if !(Input.is_action_pressed("right") and Input.is_action_pressed("left") or $FrameCounters/Slide.active()):
			if Input.is_action_pressed("right"):
				run(Direction.RIGHT)
				
			if Input.is_action_pressed("left"):
				run(Direction.LEFT)
				
		if !(motion.x > 0 and Input.is_action_pressed("right") or motion.x < 0 and Input.is_action_pressed("left")) and !$FrameCounters/Slide.active():
			motion.x *= GROUND_FRICTION
		
		if $FrameCounters/Slide.active():
			motion.x *= SLIDE_SLOWDOWN
		elif isCrouching:
			motion.x *= CROUCH_SLOWDOWN
			
		if abs(motion.x) > RUN_SPEED:
			motion.x*=0.99
			
		if Input.is_action_pressed("down"):
			if abs(motion.x) > RUN_SPEED/2:			
				slide()
				setCrouching(true)
			else:
				isChargingHeal = true
				
	
	else:
		######################## IN AIR ##################################
		if prevOnGround == true:
			onLeaveGround()
			
		isChargingHeal = false
		
		if $FrameCounters/JumpBoost.active():
			if Input.is_action_pressed("up"):
				motion.y-=JUMP_BOOST_SPEED
			
		if hook != null and hook.isTense():
			$FrameCounters/Slide.stop()
		
		#Air Movement
		if hook == null or hook.attachedTo == null or !hook.isTense():
			if !(Input.is_action_pressed("right") and Input.is_action_pressed("left") or $FrameCounters/Slide.active()):
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
	if $FrameCounters/JumpGrace.active():
		if inputBuffer.hasAction("up", false, 10) and $FrameCounters/DamageInvincibility.getFrame() < $FrameCounters/DamageInvincibility.getActiveFrames() - 5:
			jump()
	
	#Wall Jump Movement
	if $FrameCounters/LeftWallJump.active():
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("right", false, 6):
			wallJump(Direction.RIGHT)
			
		
	if $FrameCounters/RightWallJump.active():
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction("left", false, 6):
			wallJump(Direction.LEFT)
		
	if Input.is_action_just_pressed("dash") and dashCharges > 0:
		dash(getDirectionFromInput())	

	#Dash
	if $FrameCounters/DashFreeze.active():
		motion = Vector2(0,0)		
	elif $FrameCounters/DashFreeze.justFinished:
		$FrameCounters/Dash.start()
			
	if $FrameCounters/Dash.active():
		motion = dashDirection * DASH_SPEED
	elif $FrameCounters/Dash.justFinished:
		motion = dashDirection * AIR_SPEED * 1.3
		if dashPogo:
			dashPogo = false
			swordPogo()

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
	$FrameCounters/JumpGrace.stop()
	isChargingHeal = false
	
	motion.y -= JUMP_VELOCITY
	if $FrameCounters/Slide.getFrame() < $FrameCounters/Slide.getActiveFrames() * 0.5:
		$FrameCounters/JumpBoost.start()
	else:
		$FrameCounters/JumpBoost.setFrame($FrameCounters/JumpBoost.getActiveFrames()/2)
	
	$FrameCounters/Slide.stop()
	if $AnimatedSprite.animation == "idle":
		$AnimatedSprite.play("jump")
	elif $AnimatedSprite.animation == "run start":
		var frame = $AnimatedSprite.frame
		$AnimatedSprite.play("jump")
		$AnimatedSprite.set_frame(frame+1)
	else:
		$AnimatedSprite.play("run jump")
	
func slide() -> void:
	if !$FrameCounters/Slide.active() and !isCrouching:
		setCrouching(true)
		if motion.x >= RUN_SPEED*0.75:
			$FrameCounters/Slide.start()
			motion.x += RUN_SPEED*1.75
		elif -motion.x >= RUN_SPEED*0.75:
			$FrameCounters/Slide.start()
			motion.x -= RUN_SPEED*1.75
	
func setCrouching(crouching : bool) -> void:
	if isCrouching == crouching:
		return
		
	if $FrameCounters/Slide.active():
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
	if isChargingHeal:
		return
	
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
	$FrameCounters/RightWallJump.start()

func _on_Left_body_entered(_body):
	$FrameCounters/LeftWallJump.start()

func wallJump(direction) -> void:
	motion.y=-WALL_JUMP_VELOCITY.y
	if direction == Direction.RIGHT:
		motion.x = WALL_JUMP_VELOCITY.x
		$FrameCounters/LeftWallJump.stop()
		setFacing(Direction.RIGHT)
	elif direction == Direction.LEFT:
		motion.x = -WALL_JUMP_VELOCITY.x
		$FrameCounters/RightWallJump.stop()
		setFacing(Direction.LEFT)
	$FrameCounters/JumpBoost.start()
	$FrameCounters/DashFreeze.stop()
	$FrameCounters/Dash.stop()

func dash(direction : Vector2) -> void:
	if isChargingHeal:
		return
	if $FrameCounters/Slide.active() or direction == Vector2(0,0):
		return
	dashCharges -= 1
	if hook != null and hook.isDashing:
		hook.setDead()
	if hook != null and hook.attachedTo != null and direction != Vector2(0,0):
		motion += direction * DASH_SPEED * 0.5
	else:
		dashDirection = direction
		$FrameCounters/DashFreeze.start()
		
		
func throwHook() -> void:
	if isChargingHeal:
		return
	hookCharges -= 1
	hook = Hook.instance()
	hook.setShooter(self)
	hook.position = position
	hook.motion = (get_global_mouse_position() - position).normalized()*HOOK_SPEED
	get_parent().add_child(hook)
	
func swingSword() -> void:
	if isChargingHeal:
		return
	$FrameCounters/AttackCooldown.start()
	
	var rot = get_global_mouse_position().angle_to_point(global_position)
	var isDownSwing = rot > PI/5 and rot < 4*PI/5 or (!onGround and swordPogoAnyAngle)
	var hitSomething = false
	
	if hook != null:
		hook.setDead()
		
	var damage : Damage = Damage.new(self, 1*combo, Damage.TYPE.PHYSICAL)	
	for body in $AttackArea.get_overlapping_bodies():
		if body == self:
			continue
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
	if $FrameCounters/Dash.active():
		dashPogo = true
	else:
		motion.y = min(-SWORD_POGO_VELOCITY, motion.y)

func hurt(damage : Damage) -> bool:
	if hurtFrames:
		return false
	$FrameCounters/DamageInvincibility.start()
	$FrameCounters/AttackCooldown.start()
	$FrameCounters/DashFreeze.stop()
	$FrameCounters/Dash.stop()
	$FrameCounters/JumpGrace.stop()
	$FrameCounters/JumpBoost.stop()
	isChargingHeal = false
	if isHealing:
		mana = 0
		isHealing = false
	if hook !=null:
		hook.setDead()
	return .hurt(damage)
	
func onKill(living : Living) -> void:
	combo += 1
	$FrameCounters/ComboTimer.start()
	
	refreshDash()
	refreshHook()
	
	mana += living.manaOnKill
	
func useMana(amount : float) -> bool:
	assert(amount >= 0)
	if amount <= mana:
		mana -= amount
		return true
	else:
		return false
	
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


func _input(event):
	if event is InputEventMouseMotion:
		$AttackArea.rotation = get_global_mouse_position().angle_to_point(global_position)
		
