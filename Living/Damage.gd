extends Object

class_name Damage

enum TYPE {DIRECT, PHYSICAL, MAGIC, FIRE, ICE, GLITCH}

var source : Node
var amount : int
var type

func _init(source, amount, type):
	self.source = source
	self.amount = amount
	self.type = type

