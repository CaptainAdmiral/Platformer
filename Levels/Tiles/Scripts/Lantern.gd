extends StaticBody2D


func onAttacked(damage : Damage) -> void:
	if damage.source != null and damage.source.is_in_group("players"):
		damage.source.swordPogo()
		damage.source.refreshHook()
		damage.source.refreshDash()
