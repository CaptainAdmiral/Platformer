extends CanvasLayer


var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	set_player(Globals.client_player)
	Globals.connect("update_client_player", self, "set_player")
	
func set_player(player):
	self.player = player
	if player == null:
		return
	
	player.connect("post_hurt", self, "update_health")
	update()
	
func update():
	if player == null:
		return
	update_health()

func update_health(damage=null):
	if player == null:
		return
	
	$Health/Hearts.margin_right = $Health/Hearts.margin_left + 32*player.health
	$Health/EmptyHearts.margin_right = $Health/EmptyHearts.margin_left + 32*player.max_health
