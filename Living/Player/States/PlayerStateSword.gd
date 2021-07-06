extends PlayerState

class_name PlayerStateSword

const STARTUP_FRAMES = 2
const ACTIVE_FRAMES = 3
const END_LAG_FRAMES = 10

enum PHASE {STARTUP, ACTIVE, END_LAG}

var hitbox
var hit_something = false
var angle = 0

func _init(player, hitbox).(player, "sword",""):
	self.duration = STARTUP_FRAMES + ACTIVE_FRAMES + END_LAG_FRAMES
	self.hitbox = hitbox

func priority():
	return 2 if frame < STARTUP_FRAMES + ACTIVE_FRAMES else 0
	
func on_start():
	.on_start()
	player.get_node("AttackArea/AttackSprite").play("attack"+str(randi()%2+1))
	player.get_node("FrameCounters/AttackCooldown").start()
	hitbox.connect("hit_living", self, "on_hit")
	angle = player.get_global_mouse_position().angle_to_point(player.global_position)
	
	var rot = player.getSignForDirection()*angle
	hitbox.rotation = rot
	
func on_finish():
	.on_finish()
	hitbox.disconnect("hit_living", self, "on_hit")
	
func get_phase():
	if frame <= STARTUP_FRAMES:
		return PHASE.STARTUP
	elif frame <= ACTIVE_FRAMES:
		return PHASE.ACITVE
	else:
		return PHASE.END_LAG
		
func update():
	if frame == STARTUP_FRAMES:
		pass #Spawn hitbox
	elif frame == STARTUP_FRAMES + ACTIVE_FRAMES and !hit_something:
		player.get_node("sfx").play("sword_miss_" + str(randi()%3+1))
	player.motion = player.prevMotion
	.update()
	
func on_hit(hit):
	if !hit_something:
		player.get_node("sfx").play("sword_hit_" + str(randi()%2+1))
		player.motion = 1000*(player.get_global_mouse_position() - player.position).normalized()
		player.motion.y = min(-700, player.motion.y)
		hit_something = true
