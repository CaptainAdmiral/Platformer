extends CanvasLayer


var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	player.connect("post_hurt", self, "update_health")
	update()
	
func update():
	update_health()

func update_health(damage=null):
	$Health/Hearts.margin_right = $Health/Hearts.margin_left + 32*player.health
	$Health/EmptyHearts.margin_right = $Health/EmptyHearts.margin_left + 32*player.max_health
