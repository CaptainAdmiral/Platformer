extends Resource

class_name Damage

enum TYPE {DIRECT, PHYSICAL, MAGIC, FIRE, ICE, GLITCH}

var source : Node = null
export var amount : int
export var knockback : Vector2
export(TYPE) var type = TYPE.PHYSICAL
export var canDodge : bool = true
export var canParry : bool = true

func _init(source, amount, type):
	self.source = source
	self.amount = amount
	self.type = type

