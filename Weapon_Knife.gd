extends Spatial

const DAMAGE = 40

const IDLE_ANIM_NAME = "Knife_idle"
const FIRE_ANIM_NAME = "Knife_fire"

const CAN_RELOAD = false
const CAN_REFILL = false

const RELOADING_ANIM_NAME = ""

var is_weapon_enabled = false

var player_node = null

var ammo_in_weapon = 1
var spare_ammo = 1
const AMMO_IN_MAG = 1

func _ready():
	pass

func fire_weapon():
	var area = $Area
	var bodies = area.get_overlapping_bodies() #What this weapon effects. This is done through an area, and any bodies in the area are hence effected.

	for body in bodies:
		if body == player_node:
			continue # means the player doesn't take damage despite being in the area

		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, area.global_transform) # How much damage is dealt. Done through having this function trigger on anything in the area with the function "Bullet_Hit"

func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Knife_equip")

	return false

#Equipping and unequipping (Below, but functionly the same) weapon with animations

func unequip_weapon():

	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		player_node.animation_manager.set_animation("Knife_unequip")

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true

	return false

func reload_weapon():
	return false

func reset_weapon():
	ammo_in_weapon = 1
	spare_ammo = 1

