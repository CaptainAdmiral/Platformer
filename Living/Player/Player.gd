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

var attack_damage : float  = 1
var max_combo : int = 3
var combo : int = 1
var already_sword_dashed = false
var hit_something_last_attack = false

export(String, FILE, "*.tscn") var hookPath
onready var Hook = load(hookPath)
var hook : KinematicBody2D = null

var max_hook_charges: int = 1
var hook_charges : int = max_hook_charges
var last_hooked = null

var stored_wall_run : float = 0

var max_dash_charges : int = 1
var dash_charges : int = max_dash_charges
var dash_direction = Vector2()
var is_mouse_dash = false

var on_wall = false
var prev_on_wall = false

var is_dodging = false
var is_parrying = false

var checkpoint_scene : Node
var checkpoint : Node

var mana : float = 0
var max_mana : int = 100
var mana_overcap_decay = 0.025

# Called when the node enters the scene tree for the first time.
func _ready():
	fall_speed = FALL_SPEED
	set_max_health(6)
	snap_to_ground = true
	$AttackArea.add_exception(self)
	$AttackArea.properties.source = self
	Globals.client_player = self
	Globals.emit_signal("player_joined_scene", self)

func _physics_process(_delta):
	######################## WALL RUN ##################################
	
	stored_wall_run += abs(motion.x)
	stored_wall_run *= 0.5
	
	######################## MANA / HEALING ##################################
	
	if mana > max_mana:
		mana -= mana_overcap_decay
	
	######################## GRAPPLING HOOK ##################################		
	if hook != null and hook.attached_to != null:
		if motion.x > 50:
			set_facing(Direction.RIGHT)
		elif motion.x < -50:
			set_facing(Direction.LEFT)
		
		if hook.attached_to is Living:
			last_hooked = hook.attached_to
			$FrameCounters/HookAttack.start()
		
	if $FrameCounters/HookAttack.just_finished:
		last_hooked = null
		
	######################## ATTACK ##################################
	if $FrameCounters/AttackStartup.just_finished:
		swing_sword()
		
	if $FrameCounters/AttackStartup.frame == 1:
		var rot = Direction.get_sign_for_direction(facing)*get_global_mouse_position().angle_to_point(global_position)
		$AttackArea.rotation = rot

	######################## ON GROUND ##################################
	if is_on_floor():	
		refresh_hook()
		if state.name != "dash" or state.frame > PlayerStateDash.FREEZE_FRAMES+1:
			refresh_dash()
			
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
		if InputBuffer.has_action("up", false, 10) and state.priority() < 4 and $FrameCounters/DamageInvincibility.get_frame() < $FrameCounters/DamageInvincibility.get_active_frames() - 5:
			jump()
	
	#Wall Jump Movement
	if $FrameCounters/WallJump.active():
		if InputBuffer.has_action("up", false, 6) and InputBuffer.has_action(Direction.get_input_from_direction(Direction.get_opposite_direction(facing)), false, 6):
			wall_jump(Direction.get_opposite_direction(facing))
			
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
			set_dodging(true)
			$FrameCounters/AttackCooldown.stop()
	elif event.is_action_pressed("dash"):
		state.transition_to(PlayerStateDash.new(self))
	elif event.is_action_pressed("attack") and !$FrameCounters/AttackCooldown.active() and !$FrameCounters/AttackStartup.active():
		$FrameCounters/AttackStartup.start()
		already_sword_dashed = false
	elif event.is_action_released("hook") and hook != null:
		if hook.attached_to!=null and !hook.dash_buffer_frames:
			hook.set_dead()
			$sfx.play("grapple_hit_release")
		if hook != null and hook.dash_buffer_frames:
			hook.set_dashing()	
	elif event.is_action_pressed("hook") and hook_charges > 0 and hook == null:
		throw_hook()
		
func on_state_change():
	if Globals.debug:
		print(state.name)
		
func on_state_change_finished():
	if is_on_wall():
		if motion.y < 0:
			state.transition_to(PlayerStateWallRun.new(self, stored_wall_run))
		else:
			state.transition_to(PlayerStateWallSlide.new(self))
		
func get_default_state():
	if on_ground:
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
	
func set_facing(direction):
	if facing == direction:
		return
	$AttackArea.scale.x*=-1
	.set_facing(direction)
	
func jump() -> void:
	snap_to_ground = false
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
			
func can_stand():
	for body in $StandingHitboxArea.get_overlapping_bodies():
		if body is StaticBody2D or body is TileMap:
			return false
	return true
	
func on_collide_with_wall():
	if !on_ground:
		if motion.y < 0:
			state.transition_to(PlayerStateWallRun.new(self, stored_wall_run))
		else:
			state.transition_to(PlayerStateWallSlide.new(self))

func wall_jump(direction) -> void:
	turn_around()
	motion.y=-WALL_JUMP_VELOCITY.y
	motion.x = Direction.get_sign_for_direction(facing)*WALL_JUMP_VELOCITY.x
		
	$FrameCounters/WallJump.stop()
	add_persistent_behaviour(PlayerPBJumpBoost.new(self, JUMP_BOOST_FRAMES))

func is_swinging() -> bool:
	return hook != null and hook.is_tense()
	
func is_hook_dashing():
	return hook != null and hook.is_dashing
	
func is_hook_attached() -> bool:
	return hook != null and hook.attached_to != null
	
func set_dodging(dodging : bool):
	is_dodging = dodging
	if is_dodging:
		$AnimatedSprite.self_modulate = Color(0,1,0)
	else:
		$AnimatedSprite.self_modulate = Color(1,1,1)
		
func _on_dodge_finished():
	$FrameCounters/DodgeCooldown.start()
	set_dodging(false)
		
func throw_hook() -> void:
	if state.name=="heal":
		return
	hook_charges -= 1
	hook = Hook.instance()
	hook.set_shooter(self)
	hook.position = position
	hook.motion = (get_global_mouse_position() - position).normalized()*HOOK_SPEED
	get_parent().add_child(hook)
	$sfx.play("grapple_miss_" + str(randi()%3+1))
	
func swing_sword() -> void:
	if state.disable_sword:
		return

	if is_dodging:
		set_dodging(false)
		$FrameCounters/Parry.start()
		is_parrying = true
	
	match randi()%2:
		0:
			$AttackArea/AttackSprite.set_frame(0)
			$AttackArea/AttackSprite.play("attack1")
		1:
			$AttackArea/AttackSprite.set_frame(0)
			$AttackArea/AttackSprite.play("attack2")
			
	$AttackArea.properties.damage = 1*combo
	$AttackArea.properties.knockback = 600*Direction.get_direction_to_mouse(self).normalized()
	$AttackArea.hit_overlapping()
	$FrameCounters/AttackCooldown.start()
		
	if !hit_something_last_attack:	
		$sfx.play("sword_miss_" + str(randi()%3+1))
		
		
func _on_hit_with_sword(hit):
	hit_something_last_attack = true
	$sfx.play("sword_hit_" + str(randi()%2+1))
	if !already_sword_dashed:
		if !on_ground:
			if last_hooked != null:
				sword_dash(1200*motion.normalized())
			else:
				sword_dash(700*(get_global_mouse_position() - position).normalized())
		already_sword_dashed = true

func sword_dash(direction : Vector2):
	motion = direction
	motion.y = min(-700, motion.y)	

func hurt(ap : AttackProperties) -> bool:
	if $FrameCounters/DamageInvincibility.active():
		return false
	if is_dodging and ap.can_dodge:
		return false
	if is_parrying and ap.can_parry:
		return false
	$FrameCounters/DamageInvincibility.start()
	$FrameCounters/AttackCooldown.start()
	
	state.transition_to(PlayerStateHurt.new(self))
	
	if hook !=null:
		hook.set_dead()
		
	print(health)
	print(mana)
	print("\n")
	
	$sfx.play("playerhurt")
	
	return .hurt(ap)
	
func on_kill(living : Living) -> void:
	combo += 1
	$FrameCounters/ComboTimer.start()
	
	refresh_dash()
	refresh_hook()
	
	mana += living.mana_on_kill
	
func use_mana(amount : float) -> bool:
	assert(amount >= 0)
	if amount <= mana:
		mana -= amount
		return true
	else:
		return false
	
func refresh_dash():
	dash_charges = max_dash_charges
	
func refresh_hook():
	hook_charges = max_hook_charges
	
func reset_attack_timer():
	$FrameCounters/AttackCooldown.stop()
	
func set_dead() -> void:
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
	
func on_leave_ground():
	.on_leave_ground()
	snap_to_ground = true

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

