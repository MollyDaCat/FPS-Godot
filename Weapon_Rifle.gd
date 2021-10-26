extends Spatial

const DAMAGE = 4

const IDLE_ANIM_NAME = "Rifle_idle"
const FIRE_ANIM_NAME = "Rifle_fire"

var is_weapon_enabled = false

var player_node = null

var ammo_in_weapon = 50
var spare_ammo = 100
const AMMO_IN_MAG = 50

const CAN_RELOAD = true
const CAN_REFILL = true

const RELOADING_ANIM_NAME = "Rifle_reload"


func _ready():
	pass



func fire_weapon():
	var ray = $Ray_Cast
	ray.force_raycast_update() #Sends a raycast out to act as a bullet. 
	
	ammo_in_weapon -= 1
	

	if ray.is_colliding():
		var body = ray.get_collider() # Detects if the ray is colliding and makes it so the player cannot be damaged

		if body == player_node:
			pass
		elif body.has_method("bullet_hit"):
			if Globals.dimension == 2:
				body.bullet_hit(DAMAGE * 2, ray.global_transform) #Increased damge for the damage powerup
			else : 
				body.bullet_hit(DAMAGE, ray.global_transform) # Normal damage function
	player_node.create_sound("Rifle_shot", ray.global_transform.origin) # Runs the audio for the rifle being shot


func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Rifle_equip")

	return false

func unequip_weapon():

	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		if player_node.animation_manager.current_state != "Rifle_unequip":
			player_node.animation_manager.set_animation("Rifle_unequip")

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true

	return false

#Above two functions are the animations

func reload_weapon():
	var can_reload = false

	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		can_reload = true # If weapon is idle (so you cant reload while shootng)

	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false # Cant reload if mag full or no spare ammo

	if can_reload == true:
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon #Detects how much ammo is needed for the weapon to reload

		if spare_ammo >= ammo_needed: # Makes sure you have enough ammo in reserve to reload the weapon
			spare_ammo -= ammo_needed # Takes the needed ammo from spare ammo
			ammo_in_weapon = AMMO_IN_MAG # Adds ammo to the gun
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0 # Only reloads the spare ammo if the ammo you have is less then required.

		player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)
		player_node.create_sound("Gun_cock", player_node.camera.global_transform.origin) # reloading audio


		return true

	return false

func reset_weapon():
	ammo_in_weapon = 50
	spare_ammo = 100
	
	#Resets weapon to base values
