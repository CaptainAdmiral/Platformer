extends Living


func _ready():
	set_max_health(2)
	fall_speed = 0
	knockback_multiplier = 1
	mana_on_kill = 10


func _physics_process(delta):
	motion *= 0.9
