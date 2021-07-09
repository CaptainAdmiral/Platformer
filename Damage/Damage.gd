extends Resource

class_name Damage

enum TYPE {DIRECT, PHYSICAL, MAGIC, FIRE, ICE, GLITCH}

var source : Node = null
export var amount : int
export var knockback : Vector2
export(TYPE) var type = TYPE.PHYSICAL
export var can_dodge : bool = true
export var can_parry : bool = true

func _init(source=null, amount=0, type=TYPE.PHYSICAL):
	self.source = source
	self.amount = amount
	self.type = type

