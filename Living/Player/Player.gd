extends Living

class_name Player

const RUN_SPEED = 400
const RUN_ACCELERATION_FRAMES = 10
const GROUND_FRICTION = 0.7
const FALL_SPEED = 30
const AIR_ACCELERATION_FRAMES=20
const AIR_FRICTION = 0.95

const JUMP_VELOCITY = 300
const JUMP_BOOST_FRAMES = 10
const JUMP_GRACE_FRAMES = 8

const WALL_JUMP_VELOCITY = Vector2(RUN_SPEED, JUMP_VELOCITY)

const ATTACK_KNOCKBACK = 1000

const HOOK_SPEED = 4200

#calculated values
const AIR_SPEED = RUN_SPEED
const AIR_ACCELERATION = AIR_SPEED / AIR_ACCELERATION_FRAMES
const RUN_ACCELERATION = RUN_SPEED / RUN_ACCELERATION_FRAMES

onready var inputBuffer = $InputBuffer

var attackDamage : float  = 1
var maxCombo : int = 3
var combo : int = 1
var attackNextFrame : bool = false #Area2D only polls at start of physics process

export(String, FILE, "*.tscn") var HookPath
onready var Hook = load(HookPath)
var hook : KinematicBody2D = null

var maxHookCharges: int = 1
var hookCharges : int = maxHookCharges
var grappleWindup : int = 0
var lastHooked = null

var storedWallRun : float = 0

var maxDashCharges : int = 1
var dashCharges : int = maxDashCharges
var dashDirection = Vector2()
var isMouseDash = false

var on_wall = false
var prev_on_wall = false

var isDodging = false
var isParrying = false

var checkpointScene : Node
var checkpoint : Node

var mana : float = 0
var maxMana : int = 100
var manaOvercapDecay = 0.025

# Called when the node enters the scene tree for the first time.
func _ready():
	fallSpeed = FALL_SPEED
	setMaxHealth(6)

func _physics_process(_delta):
	######################## WALL RUN ##################################
	
	storedWallRun += abs(motion.x)
	storedWallRun *= 0.5
	
	######################## MANA / HEALING ##################################
	
	if mana > maxMana:
		mana -= manaOvercapDecay
	
	######################## GRAPPLING HOOK ##################################
	
	if Input.is_action_just_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
			$sfx.play("grapple_hit_release")
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()
		
	if Input.is_action_just_pressed("hook") and hookCharges > 0 and hook == null:
		throwHook()
		
	if hook != null and hook.attachedTo != null:
		if motion.x > 50:
			setFacing(Direction.RIGHT)
		elif motion.x < -50:
			setFacing(Direction.LEFT)
		
		if hook.attachedTo is Living:
			lastHooked = hook.attachedTo
			$FrameCounters/HookAttack.start()
		
	if $FrameCounters/HookAttack.justFinished:
		lastHooked = null
		
	######################## ATTACK ##################################
	if attackNextFrame:
		swingSword()
		attackNextFrame = false
	
	if Input.is_action_just_pressed("attack") and !$FrameCounters/AttackCooldown.active():
		var rot = getSignForDirection()*get_global_mouse_position().angle_to_point(global_position)
		if facing == Direction.LEFT:
			rot+=PI
		$AttackArea.rotation = rot
		$AttackAreaLong.rotation = rot
		attackNextFrame = true
	
	######################## ON GROUND ##################################
	if is_on_floor():	
		refreshHook()
		if state.name != "dash" or state.frame > PlayerStateDash.FREEZE_FRAMES+1:
			refreshDash()
			
		if state.name != "run" and state.name != "slide":
			motion.x *= GROUND_FRICTION
			
		if abs(motion.x) > RUN_SPEED:
			motion.x*=0.99
			
		$FrameCounters/JumpGrace.start()

	else:
		######################## IN AIR ##################################
		for body in $WallJump.get_overlapping_bodies():
			if body is StaticBody or body is TileMap:
				$FrameCounters/WallJump.start()
	#Jump
	if $FrameCounters/JumpGrace.active():
		if inputBuffer.hasAction("up", false, 10) and $FrameCounters/DamageInvincibility.getFrame() < $FrameCounters/DamageInvincibility.getActiveFrames() - 5:
			jump()
	
	#Wall Jump Movement
	if $FrameCounters/WallJump.active():
		if inputBuffer.hasAction("up", false, 6) and inputBuffer.hasAction(getInputFromDirection(getOppositeDirection(facing)), false, 6):
			wallJump(getOppositeDirection(facing))
			
	######################## ON WALL ##################################
	prev_on_wall = on_wall
	on_wall = is_on_wall()
	
	if on_wall and !prev_on_wall:
		on_collide_with_wall()
		
func _input(event:InputEvent) -> void:
	if event.is_action_pressed("left"):
		state.transition_to(PlayerStateRun.new(self, Direction.LEFT))
	elif event.is_action_pressed("right"):
		state.transition_to(PlayerStateRun.new(self, Direction.RIGHT))
	elif event.is_action_pressed("down"):
		if !$FrameCounters/Dodge.active() and !$FrameCounters/DodgeCooldown.active() :
			state.transition_to(PlayerStateDodge.new(self))
			$FrameCounters/Dodge.start()
			setDodging(true)
	elif event.is_action_pressed("dash"):
		state.transition_to(PlayerStateDash.new(self))
		
func on_state_change():
	if Globals.debug:
		print(state.name)
		
func on_state_change_finished():
	if is_on_wall():
		if motion.y < 0:
			state.transition_to(PlayerStateWallRun.new(self, storedWallRun))
		else:
			state.transition_to(PlayerStateWallSlide.new(self))
		

func get_default_state():
	if onGround:
		if !(Input.is_action_pressed("left") and Input.is_action_pressed("right")):
			if Input.is_action_pressed("left"):
				return PlayerStateRun.new(self, Direction.LEFT)
			elif Input.is_action_pressed("right"):
				return PlayerStateRun.new(self, Direction.RIGHT)
	else:
		return PlayerStateAirDrift.new(self)
		
	var idleState = LivingState.new(self, "idle", $AnimatedSprite, "idle", -1)
	idleState.ground_only = true
	return idleState
	
func jump() -> void:
	$FrameCounters/JumpGrace.stop()
	motion.y -= JUMP_VELOCITY
	
	if state.name != "slide" or state.frame > 10:
		add_persistent_behaviour(PlayerPBJumpBoost.new(self, JUMP_BOOST_FRAMES))
	else:
		add_persistent_behaviour(PlayerPBJumpBoost.new(self, JUMP_BOOST_FRAMES/2))
	
	if $AnimatedSprite.animation == "idle":
		$AnimatedSprite.play("jump")
	elif $AnimatedSprite.animation == "run start":
		var frame = $AnimatedSprite.frame
		$AnimatedSprite.play("jump")
		$AnimatedSprite.set_frame(frame+1)
	else:
		$AnimatedSprite.play("run jump")
	
	$sfx.play("grunt_" + str(randi()%3+1))
			
func canStand():
	for body in $StandingHitboxArea.get_overlapping_bodies():
		if body is StaticBody2D or body is TileMap:
			return false
	return true
	
func on_collide_with_wall():
	if !onGround:
		if motion.y < 0:
			state.transition_to(PlayerStateWallRun.new(self, storedWallRun))
		else:
			state.transition_to(PlayerStateWallSlide.new(self))

func wallJump(direction) -> void:
	turnAround()
	motion.y=-WALL_JUMP_VELOCITY.y
	motion.x = getSignForDirection()*WALL_JUMP_VELOCITY.x
		
	$FrameCounters/WallJump.stop()
	add_persistent_behaviour(PlayerPBJumpBoost.new(self, JUMP_BOOST_FRAMES))


func startDash():
	isMouseDash = false
	var rot = dashDirection.angle()+0.5*PI;
	if facing == Direction.LEFT:
		rot*=-1;
	$VFX/Dash.set_rotation(rot)
	$VFX/AnimationPlayer.stop()
	$VFX/AnimationPlayer.play("dash")

func is_swinging() -> bool:
	return hook != null and hook.isTense()
	
func is_hook_dashing():
	return hook != null and hook.isDashing
	
func is_hook_attached() -> bool:
	return hook != null and hook.attachedTo != null
		
func setDodging(dodging : bool):
	isDodging = dodging
	if isDodging:
		$AnimatedSprite.self_modulate = Color(0,1,0)
	else:
		$AnimatedSprite.self_modulate = Color(1,1,1)
		
func _on_dodge_finished():
	$FrameCounters/DodgeCooldown.start()
	setDodging(false)
		
func throwHook() -> void:
	if state.name=="heal":
		return
	hookCharges -= 1
	hook = Hook.instance()
	hook.setShooter(self)
	hook.position = position
	hook.motion = (get_global_mouse_position() - position).normalized()*HOOK_SPEED
	get_parent().add_child(hook)
	$sfx.play("grapple_miss_" + str(randi()%3+1))
	
func swingSword() -> void:
	if state.name=="heal":
		return

	if isDodging:
		setDodging(false)
		$FrameCounters/Parry.start()
		isParrying = true
	
	var rot = get_global_mouse_position().angle_to_point(global_position)
	var hitSomething = false
		
	var attackArea = null
	
	if lastHooked != null:
		$AttackAreaLong/AttackSprite.set_frame(0)
		attackArea  = $AttackAreaLong
		$AttackAreaLong/AttackSprite.play("long attack")
		$FrameCounters/AttackCooldown.setActiveFrames(30)
		$FrameCounters/AttackCooldown.start()
	else:
		match randi()%2:
			0:
				$AttackArea/AttackSprite.set_frame(0)
				attackArea = $AttackArea
				$AttackArea/AttackSprite.play("attack1")
				$FrameCounters/AttackCooldown.setFrame(15)
			1:
				$AttackArea/AttackSprite.set_frame(0)
				attackArea = $AttackArea
				$AttackArea/AttackSprite.play("attack2")
				$FrameCounters/AttackCooldown.start()
				
		
	var damage : Damage = Damage.new(self, 1*combo, Damage.TYPE.PHYSICAL)	
	var bodiesAttacked = attackArea.get_overlapping_bodies()
	if lastHooked != null and !bodiesAttacked.has(lastHooked):
		bodiesAttacked.append(lastHooked)
		
	for body in bodiesAttacked:
		if body == self:
			continue
		if body is Living:
			var knockback = global_position.direction_to(body.global_position)*ATTACK_KNOCKBACK
			if body.is_on_floor():
				knockback.y = min(-300, knockback.y)
			
			if body.hurt(damage):
				body.addKnockback(knockback, true)
				hitSomething = true
				if body.health == 0 && combo == 7:
					$sfx.play("7th column")
				
		if $FrameCounters/Parry.active():
			if body is Projectile:
				var mag = body.motion.length()
				body.motion = Vector2(mag*cos(rot), mag*sin(rot))
				body.shooter = self
			
		if body.is_in_group("attackable"):
			body.onAttacked(damage)

	if hitSomething:
		if !onGround:
			if lastHooked != null:
				swordDash(1200*motion.normalized())
			elif !onGround:
				swordDash(1000*(get_global_mouse_position() - position).normalized())

	
	if hitSomething == true:
		$sfx.play("sword_hit_" + str(randi()%2+1))
	else:
		$sfx.play("sword_miss_" + str(randi()%3+1))
	
	
func getDirectionToMouse() -> Vector2:
	return global_position.direction_to(get_global_mouse_position())
	
func getParryDirection() -> Vector2:
	return getDirectionToMouse()

func swordDash(direction : Vector2):
	motion = direction
	motion.y = min(-700, motion.y)

func hurt(damage : Damage) -> bool:
	if isDodging and damage.canDodge:
		return false
	if isParrying and damage.canParry:
		return false
	$FrameCounters/DamageInvincibility.start()
	$FrameCounters/AttackCooldown.start()
	
	if hook !=null:
		hook.setDead()
		
	print(health)
	print(mana)
	print("\n")
	
	$sfx.play("playerhurt")
	
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

func on_land() -> void:
	.on_land()
	if $AnimatedSprite.animation == "run jump":
		$AnimatedSprite.stop()
		
	if $AnimatedSprite.animation == "jump":
		$AnimatedSprite.stop()
		
	if $AnimatedSprite.animation == "fall":
		$AnimatedSprite.stop()
	
	$sfx.play("landing")
		
func set_crouch(flag):
	if flag:
		$Hitbox.set_deferred("disabled", true)
		$CrouchHitbox.set_deferred("disabled", false)
	else:
		$Hitbox.set_deferred("disabled", false)
		$CrouchHitbox.set_deferred("disabled", true)
	
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
												
	return Vector2(x, y).normalized()
	
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
	
func get_vector_for_direction(direction):
	if direction == Direction.LEFT:
		return Vector2(-1, 0)
	elif direction == Direction.RIGHT:
		return Vector2(1, 0)
	elif direction == Direction.UP:
		return Vector2(0, -1)
	elif direction == Direction.DOWN:
		return Vector2(0, 1)
	return Vector2(0, 0)
	
