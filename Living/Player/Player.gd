extends Living


export var swordPogoAnyAngle = false

const RUN_SPEED = 500
const RUN_ACCELERATION_FRAMES = 20
const GROUND_FRICTION = 0.7
const FALL_SPEED = 30
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 500
const JUMP_BOOST_SPEED = 30

const DASH_SPEED = 1800

const CROUCH_SLOWDOWN = 0.875
const SLIDE_SLOWDOWN = 0.96

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED, JUMP_VELOCITY)
const WALL_SLIDE_SPEED = 120

const ATTACK_KNOCKBACK = 1000
const SWORD_POGO_VELOCITY = 700

const HOOK_SPEED = 4200

const DASH_SLOWMO_MULTIPLIER = 40
const DASH_ATTACK_MULTIPLIER = 1

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
var lastHooked = null


var dashModifier : int = DASH_SLOWMO_MULTIPLIER
var maxDashCharges : int = 1
var dashCharges : int = maxDashCharges
var dashDirection = Vector2()
var currentlyDashing : bool = false

var lastAttack : int = 0
onready var AttackArea = $AttackArea

var storedWallJumpMotion : float = 0


var checkpointScene : Node
var checkpoint : Node

var mana : float = 0
var maxMana : int = 100
var manaOvercapDecay = 0.025
var isHealing : bool = false
var manaPerHealth : float = 25
var manaPerFrame : float = 0.15
var manaUntilNextHeal : float  = manaPerHealth
var isChargingHeal : bool = false
var healCharge : int = 0

var slowdownFactor : float = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	fallSpeed = FALL_SPEED
	setMaxHealth(60)

func _physics_process(_delta):
	slowdownFactor = (1/Engine.get_time_scale())

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
				
				print(health)
				print(mana)
				print("\n")
		else:
			isHealing = false
			mana = 0
	
	if !Input.is_action_pressed("down"):
		isChargingHeal = false
	
	######################## GRAPPLING HOOK ##################################
	
	if Input.is_action_just_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()
			$FrameCounters/OnHook.start()
		
	if Input.is_action_just_pressed("hook") and hookCharges > 0 and hook == null:
		throwHook()
		
	if $FrameCounters/OnHookDeath.justFinished:
		lastHooked = null
	
	######################## ATTACK ##################################
	if Input.is_action_just_pressed("attack") and !$FrameCounters/AttackCooldown.active() and lastAttack < 3:
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
				
		if isChargingHeal or !(motion.x > 0 and Input.is_action_pressed("right") or motion.x < 0 and Input.is_action_pressed("left")) and !$FrameCounters/Slide.active():
			motion.x *= GROUND_FRICTION
			
		if abs(motion.x) > RUN_SPEED:
			motion.x*=0.99
			
		if Input.is_action_pressed("down") and !$FrameCounters/Slide.active():
			if abs(motion.x) >= RUN_SPEED:
				motion.x += getSignForDirection()*2*RUN_SPEED
				$FrameCounters/Slide.start()
				$AnimatedSprite.play("slide")
				$Hitbox.set_deferred("disabled", true)
				$CrouchHitbox.set_deferred("disabled", false)
			elif !$FrameCounters/Slide.active():
				isChargingHeal = true
				
		if $FrameCounters/Slide.active():
			slide()

	else:
		######################## IN AIR ##################################
		if prevOnGround == true:
			onLeaveGround()
			
		isChargingHeal = false
		
		if $FrameCounters/JumpBoost.active():
			if Input.is_action_pressed("up"):
				motion.y-=JUMP_BOOST_SPEED
			
		if hook != null and hook.isTense():
			$FrameCounters/Slide.setFinished()
			
		for body in $WallJump.get_overlapping_bodies():
			if body is StaticBody or body is TileMap:
				$FrameCounters/WallJump.start()
		
		#Air Movement
		if hook == null or hook.attachedTo == null or !hook.isTense():
			if !(Input.is_action_pressed("right") and Input.is_action_pressed("left") or $FrameCounters/Slide.active()):
				if Input.is_action_pressed("right"):
					airDrift(Direction.RIGHT)
						
				if Input.is_action_pressed("left"):
					airDrift(Direction.LEFT)
			
			if !(Input.is_action_pressed("right") or Input.is_action_pressed("left")):
				motion.x *= AIR_FRICTION
				
		if $LedgeGrab/LedgeGrab.is_colliding() and !$LedgeGrab/CeilingCheck.is_colliding():
			var collisionPos = $LedgeGrab/LedgeGrab.get_collision_point()
			collisionPos.y -= 1
			$LedgeGrab/LedgeSpace.set_position($LedgeGrab.to_local(collisionPos))
			$LedgeGrab/LedgeSpace.force_raycast_update()
			if !$LedgeGrab/LedgeSpace.is_colliding():
				if Input.is_action_just_pressed("up") and !$FrameCounters/LedgeJump.active():
					position = collisionPos
					position.y-=$Hitbox.shape.extents.y
					motion.y = 0
					$FrameCounters/JumpDisable.start()
#					motion.y = min(motion.y, -JUMP_VELOCITY*1.5)
#					$FrameCounters/LedgeJump.start()
				
		######################## ON WALL ##################################
		if is_on_wall():
			storedWallJumpMotion = max(storedWallJumpMotion, abs(prevMotion.x))
			
			for i in get_slide_count():
				var norm = get_slide_collision(i).normal
				
				if (norm == Vector2(1, 0) and !Input.is_action_pressed("right") and Input.is_action_pressed("left")) or (norm == Vector2(-1, 0) and !Input.is_action_pressed("left") and Input.is_action_pressed("right")):
					motion.y -= min(fallSpeed, storedWallJumpMotion)*0.5
					storedWallJumpMotion -= min(fallSpeed, storedWallJumpMotion)
					
				

			
			if motion.y > WALL_SLIDE_SPEED:
				motion.y = max(motion.y/2, WALL_SLIDE_SPEED)
			
			
		else:
			storedWallJumpMotion = 0
	#Jump
	if $FrameCounters/JumpGrace.active():
		if inputBuffer.hasAction("up", false, 10) and $FrameCounters/DamageInvincibility.getFrame() < $FrameCounters/DamageInvincibility.getActiveFrames() - 5:
			jump()
	
	#Wall Jump Movement
	if $FrameCounters/WallJump.active():
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction(getInputFromDirection(getOppositeDirection(facing)), false, 6):
			wallJump(getOppositeDirection(facing))
		
		
##############################   Dash   ################################
################## Dash Input Controller
	if Input.is_action_just_pressed("dash") and dashCharges > 0:  # Just pressed
		Engine.set_time_scale(0.02)
		$FrameCounters/DashSlowmo.start()
		
	if (Input.is_action_just_released("dash") and $FrameCounters/DashSlowmo.active()) or $FrameCounters/DashSlowmo.justFinished: # Released
		$FrameCounters/DashSlowmo.stop()
		dash((get_global_mouse_position() - position).normalized(), "dashInput")
		
	if $FrameCounters/DashFreeze.active():
		motion = Vector2(0,0)		
	elif $FrameCounters/DashFreeze.justFinished:
		$FrameCounters/Dash.start()

################# Physics Process Dash movement handler
	if $FrameCounters/Dash.active():
		motion = dashDirection * DASH_SPEED * dashModifier #BUG WITH MASHING DASH ATM
	elif $FrameCounters/Dash.justFinished:

		motion = dashDirection * AIR_SPEED * 1.3    
		self.addFreezeFrames(5)
		Engine.set_time_scale(1.0)


#########################   Input Direction   ##########################
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
	
func getInputFromDirection(direction) -> String:
	if direction == Direction.LEFT:
		return "left"
	elif direction == Direction.RIGHT:
		return "right"
	elif direction == Direction.UP:
		return "up"
	elif direction == Direction.DOWN:
		return "down"
	return "err"
	
func jump() -> void:
	if $FrameCounters/JumpDisable.active():
		return
	$FrameCounters/JumpGrace.stop()
	isChargingHeal = false
	lastAttack = 0
	
	motion.y -= JUMP_VELOCITY 
	if $FrameCounters/Slide.getFrame() < $FrameCounters/Slide.getActiveFrames() * 0.5:
		$FrameCounters/JumpBoost.start()
	else:
		$FrameCounters/JumpBoost.setFrame($FrameCounters/JumpBoost.getActiveFrames()/2)
	
	$FrameCounters/Slide.setFinished()
	if $AnimatedSprite.animation == "idle":
		$AnimatedSprite.play("jump")
	elif $AnimatedSprite.animation == "run start":
		var frame = $AnimatedSprite.frame
		$AnimatedSprite.play("jump")
		$AnimatedSprite.set_frame(frame+1)
	else:
		$AnimatedSprite.play("run jump")
	
func slide() -> void:
	motion.x *= SLIDE_SLOWDOWN
	
	if !canStand():
		$FrameCounters/Slide.setMinFrame(2)
		motion.x += getSignForDirection()*RUN_ACCELERATION
		
		
func canStand():
	for body in $StandingHitboxArea.get_overlapping_bodies():
		if body is StaticBody2D or body is TileMap:
			return false
	return true
			
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

func wallJump(direction) -> void:
	turnAround()
	motion.y=-WALL_JUMP_VELOCITY.y
	motion.x = getSignForDirection()*WALL_JUMP_VELOCITY.x
		
	$FrameCounters/WallJump.stop()
	$FrameCounters/JumpBoost.start()
	$FrameCounters/DashFreeze.stop()
	$FrameCounters/Dash.stop()

func dash(direction : Vector2, dashMode : String) -> void:
	
	if dashMode == "dashInput":
		dashModifier = DASH_SLOWMO_MULTIPLIER
		$FrameCounters/DashFreeze.setActiveFrames(3)
		$FrameCounters/Dash.setActiveFrames(5)
	elif dashMode == "attackInput":
		dashModifier = DASH_ATTACK_MULTIPLIER
		$FrameCounters/DashFreeze.setActiveFrames(0)
		if lastAttack < 4:
			$FrameCounters/Dash.setActiveFrames(2)
		else:
			$FrameCounters/Dash.setActiveFrames(1)
	elif dashMode == "dashThroughTarget":
		dashModifier = DASH_ATTACK_MULTIPLIER
		$FrameCounters/DashFreeze.setActiveFrames(0)
		$FrameCounters/Dash.setActiveFrames(8)

	
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
	
func swingSword() -> void: # Handles attack based on context
	if isChargingHeal:
		return
	
	var damage : Damage = Damage.new(self, 1*combo, Damage.TYPE.PHYSICAL)	
	var rot = get_global_mouse_position().angle_to_point(global_position)
	var isDownSwing = rot > PI/5 and rot < 4*PI/5 or (!onGround and swordPogoAnyAngle)
	var hitSomething = false
	
	if $FrameCounters/OnHook.active():
		if lastHooked is Living:
			$AttackAreaLong/AttackSprite.set_frame(0) # this line bugfixes something or other
			AttackArea  = $AttackAreaLong
			dash((lastHooked.position - position).normalized(), "dashThroughTarget")
			$AttackAreaLong/AttackSprite.play("AttackLong")
			$FrameCounters/AttackCooldown.setActiveFrames(30)
			$FrameCounters/AttackCooldown.start()
			lastAttack = 0
			print("TARGET VALID")
		else:
			pass

	elif onGround:   ### Handle animation, combo limitations and cooldowns
		if hook != null:
			hook.setDead()
		match lastAttack:
			0: 
				AttackArea = $AttackArea
				dash((get_global_mouse_position() - position).normalized(), "attackInput")
				$AttackArea/AttackSprite.play("Attack1")
				$FrameCounters/AttackCooldown.setActiveFrames(15)
				$FrameCounters/AttackCooldown.start()
				lastAttack = 1
				
			1: 
				AttackArea = $AttackArea
				dash((get_global_mouse_position() - position).normalized(), "attackInput")
				$AttackArea/AttackSprite.play("Attack2")
				$FrameCounters/AttackCooldown.start()
				lastAttack = 2
			2:
				$AttackAreaLong/AttackSprite.set_frame(0) # this line bugfixes something or other
				AttackArea  = $AttackAreaLong
				dash((get_global_mouse_position() - position).normalized(), "attackInput")
				$AttackAreaLong/AttackSprite.play("AttackLong")
				$FrameCounters/AttackCooldown.setActiveFrames(30)
				$FrameCounters/AttackCooldown.start()
				lastAttack = 0
	else:
		if hook != null:
			hook.setDead()
		if isDownSwing and lastAttack < 4 :
			$AttackAreaLong/AttackSprite.set_frame(0)
			AttackArea  = $AttackAreaLong
			$AttackAreaLong/AttackSprite.play("AttackLong")
			$FrameCounters/AttackCooldown.setActiveFrames(30)
			$FrameCounters/AttackCooldown.start()
			lastAttack = 4  
		else:
			match lastAttack:
				0: 
					AttackArea = $AttackArea
					dash((get_global_mouse_position() - position).normalized(), "attackInput")
					$AttackArea/AttackSprite.play("Attack1")
					$FrameCounters/AttackCooldown.setActiveFrames(15)
					$FrameCounters/AttackCooldown.start()
					lastAttack = 1
					
				1: 
					AttackArea = $AttackArea
					dash((get_global_mouse_position() - position).normalized(), "attackInput")
					$AttackArea/AttackSprite.play("Attack2")
					$FrameCounters/AttackCooldown.start()
					lastAttack = 2
				2:
					$AttackAreaLong/AttackSprite.set_frame(0)
					AttackArea  = $AttackAreaLong
					dash((get_global_mouse_position() - position).normalized(), "attackInput")
					$AttackAreaLong/AttackSprite.play("AttackLong")
					$FrameCounters/AttackCooldown.setActiveFrames(30)
					$FrameCounters/AttackCooldown.start()
					lastAttack = 4
	
	if AttackArea == $AttackAreaLong:
		damage = Damage.new(self, 2*combo, Damage.TYPE.PHYSICAL)	
	else:
		pass
	
	for body in AttackArea.get_overlapping_bodies():   ### Handle Damage
		if body == self:
			continue
		if body is Living:
			var knockback = motion + global_position.direction_to(body.global_position)*ATTACK_KNOCKBACK
			if body.is_on_floor():
				knockback.y = min(-300, knockback.y)
			
			if body.hurt(damage):
				body.addKnockback(knockback, true)
				hitSomething = true
				if body.isDead:
					lastAttack = 0
			
		if body.is_in_group("attackable"):
			body.onAttacked(damage)
			
		if isDownSwing and hitSomething:
			swordPogo()
			lastAttack = 0

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
		
	print(health)
	print(mana)
	print("\n")
		
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
	for rc in $LedgeGrab.get_children():
		rc.set_enabled(true)
	
func onLand() -> void:
	if lastAttack == 3 or lastAttack == 4:
		lastAttack = 0

	for rc in $LedgeGrab.get_children():
		rc.set_enabled(false)

		
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

func _on_Hook_collided(lasthook):
	lastHooked = lasthook

func _on_Hook_dead():
	$FrameCounters/OnHookDeath.start()

func _input(event):
	if event is InputEventMouseMotion:
		if !$FrameCounters/AttackCooldown.active():
			$AttackArea.rotation = get_global_mouse_position().angle_to_point(global_position)
			$AttackAreaLong.rotation = get_global_mouse_position().angle_to_point(global_position)

func _on_Slide_finished():
	$AnimatedSprite.play("run")
	$Hitbox.set_deferred("disabled", false)
	$CrouchHitbox.set_deferred("disabled", true)
