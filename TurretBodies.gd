extends StaticBody

export (NodePath) var path_to_turret_root

func _ready():
	pass

func bullet_hit(damage, bullet_hit_pos):
	if path_to_turret_root != null:
		get_parent().get_parent().bullet_hit(damage, bullet_hit_pos)
