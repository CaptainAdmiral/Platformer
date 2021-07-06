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

var attackDamage : float  = 1
var maxCombo : int = 3
var combo : int = 1
var already_sword_dashed = false
var hit_something_last_attack = false

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
	$AttackArea.add_exception(self)
	$AttackArea.damage.source = self

func _physics_process(_delta):
	######################## WALL RUN ##################################
	
	storedWallRun += abs(motion.x)
	storedWallRun *= 0.5
	
	######################## MANA / HEALING ##################################
	
	if mana > maxMana:
		mana -= manaOvercapDecay
	
	######################## GRAPPLING HOOK ##################################		
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
	if $FrameCounters/AttackStartup.justFinished:
		swingSword()
		
	if $FrameCounters/AttackStartup.frame == 1:
		var rot = Direction.getSignForDirection(facing)*get_global_mouse_position().angle_to_point(global_position)
		$AttackArea.rotation = rot

	######################## ON GROUND ##################################
	if is_on_floor():	
		refreshHook()
		if state.name != "dash" or state.frame > PlayerStateDash.FREEZE_FRAMES+1:
			refreshDash()
			
		if state.name != "run" and state.name != "slide" and !is_hook_attached():
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
		if InputBuffer.has_action("up", false, 10) and state.priority() < 4 and $FrameCounters/DamageInvincibility.getFrame() < $FrameCounters/DamageInvincibility.getActiveFrames() - 5:
			jump()
	
	#Wall Jump Movement
	if $FrameCounters/WallJump.active():
		if InputBuffer.has_action("up", false, 6) and InputBuffer.has_action(Direction.getInputFromDirection(Direction.getOppositeDirection(facing)), false, 6):
			wallJump(Direction.getOppositeDirection(facing))
			
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
		if !$FrameCounters/Dodge.active() and !$FrameCounters/DodgeCooldown.active():
			state.transition_to(PlayerStateDodge.new(self))
			$FrameCounters/Dodge.start()
			setDodging(true)
			$FrameCounters/AttackCooldown.stop()
	elif event.is_action_pressed("dash"):
		state.transition_to(PlayerStateDash.new(self))
	elif event.is_action_pressed("attack") and !$FrameCounters/AttackCooldown.active() and !$FrameCounters/AttackStartup.active():
		$FrameCounters/AttackStartup.start()
		already_sword_dashed = false
	elif event.is_action_released("hook") and hook != null:
		if hook.attachedTo!=null and !hook.dashBufferFrames:
			hook.setDead()
			$sfx.play("grapple_hit_release")
		if hook != null and hook.dashBufferFrames:
			hook.setDashing()	
	elif event.is_action_pressed("hook") and hookCharges > 0 and hook == null:
		throwHook()
		
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
		
	var idleState = PlayerState.new(self, "idle", "idle", -1)
	idleState.ground_only = true
	return idleState
	
func setFacing(direction):
	if facing == direction:
		return
	$AttackArea.scale.x*=-1
	.setFacing(direction)
	
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
	motion.x = Direction.getSignForDirection(facing)*WALL_JUMP_VELOCITY.x
		
	$FrameCounters/WallJump.stop()
	add_persistent_behaviour(PlayerPBJumpBoost.new(self, JUMP_BOOST_FRAMES))

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
	if state.disable_sword:
		return

	if isDodging:
		setDodging(false)
		$FrameCounters/Parry.start()
		isParrying = true
	
	match randi()%2:
		0:
			$AttackArea/AttackSprite.set_frame(0)
			$AttackArea/AttackSprite.play("attack1")
		1:
			$AttackArea/AttackSprite.set_frame(0)
			$AttackArea/AttackSprite.play("attack2")
			
	$AttackArea.damage.amount = 1*combo
	$AttackArea.damage.knockback = 600*Direction.getDirectionToMouse(self).normalized()
	$AttackArea.hit_overlapping()
	$FrameCounters/AttackCooldown.start()
		
	if !hit_something_last_attack:	
		$sfx.play("sword_miss_" + str(randi()%3+1))
		
		
func _on_hit_with_sword(hit):
	hit_something_last_attack = true
	$sfx.play("sword_hit_" + str(randi()%2+1))
	if !already_sword_dashed:
		if !onGround:
			if lastHooked != null:
				swordDash(1200*motion.normalized())
			else:
				swordDash(700*(get_global_mouse_position() - position).normalized())
		already_sword_dashed = true

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
	
func reset_attack_timer():
	$FrameCounters/AttackCooldown.stop()
	
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

