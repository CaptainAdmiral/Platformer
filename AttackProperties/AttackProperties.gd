extends Resource

class_name AttackProperties

enum TYPE {DIRECT, PHYSICAL, MAGIC, FIRE, ICE, GLITCH}

var source : Node = null
export var damage : int
export var knockback : Vector2
export var knockback_overwrites_motion = true
export(TYPE) var type = TYPE.PHYSICAL
export var can_dodge : bool = true
export var can_parry : bool = true

func _init(source=null, damage=0, knockback = Vector2(), type=TYPE.PHYSICAL):
	self.source = source
	self.damage = damage
	self.type = type
	self.knockback = knockback

