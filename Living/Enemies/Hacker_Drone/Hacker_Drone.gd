extends Living


func _ready():
	setMaxHealth(2)
	fallSpeed = 0
	knockbackMultiplier = 1
	manaOnKill = 10


func _physics_process(delta):
	motion *= 0.9
