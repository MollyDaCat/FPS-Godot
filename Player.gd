extends KinematicBody

const MAX_HEALTH = 200

const RESPAWN_TIME = 4
var dead_time = 0
var is_dead = false

var globals


const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL = 4.5

var grabbed_object = null
const OBJECT_THROW_FORCE = 120
const OBJECT_GRAB_DISTANCE = 7
const OBJECT_GRAB_RAY_DISTANCE = 10


var mouse_scroll_value = 0
const MOUSE_SENSITIVITY_SCROLL_WHEEL = 0.08

var grenade_amounts = {"Grenade":2, "Sticky Grenade":2}
var current_grenade = "Grenade"
var grenade_scene = preload("res://Grenade.tscn")
var sticky_grenade_scene = preload("res://Sticky_Grenade.tscn")
const GRENADE_THROW_FORCE = 50


var simple_audio_player = preload("res://Simple_Audio_Player.tscn")


var reloading_weapon = false


# constants for things like max speed of the player and other things like acceleration

#Sprinting & Falshlight

const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
var is_sprinting = false

var flashlight

var dir = Vector3()

const DEACCEL = 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

# Variables to make it easier to input things like rotation helper without having to direct it to the specific item and location

var MOUSE_SENSITIVITY = 0.5

# Weapons

var animation_manager

var current_weapon_name = "UNARMED"
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"} #Binds for weapons
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
var changing_weapon = false
var changing_weapon_name = "UNARMED"

var health = 100

var UI_status_label

const POWER_TIME = 60
var power_left = 0


func _ready():
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	
	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
	
	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin
	
	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			weapon_node.player_node = self
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad(180))
			
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	
	UI_status_label = $HUD/Panel/Gun_label
	flashlight = $Rotation_Helper/Flashlight
	
	globals = get_node("/root/Globals")
	global_transform.origin = globals.get_respawn_position()

	
	


func _physics_process(delta):
	
	if !is_dead:
		process_input(delta)
		process_view_input(delta)
		process_movement(delta) #Links these processes to _physics_process(delta) so that they run on delta (same for below)

	
	if grabbed_object == null:
		process_changing_weapons(delta)
		process_reloading(delta)
	
	process_UI(delta)
	process_respawn(delta)
	dimension(delta)



func process_input(delta):
	
	
	
	#Walking or something like it
	dir = Vector3()
	var cam_xform = camera.get_global_transform() #Where the player sees from
	
	var input_movement_vector = Vector2() # Means that the movement is done on vector 2 (x and y axis or forward, back, left, right)
	
	if Input.is_action_pressed("movement_forward"): #Binds movement key (same for all the below) (in this case forward is w, s is backwards, etc)
		input_movement_vector.y +=1 #Movement on the specific axis. Forward increases y axis, meaning you move forward. All of the below functions act in the same way
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1
	
	
	dir += -cam_xform.basis.z * input_movement_vector.y #Moves camera
	dir += cam_xform.basis.x * input_movement_vector.x #Also moves camera
	
	# Jumping code
	
	if is_on_floor(): #detects if the player is on the floor, if they are, they can jump
		if Input.is_action_just_pressed("movement_jump"): #detects if the player wants to jump
			vel.y = JUMP_SPEED # Upwards velocity is set so you move up, and hence jump
	
	#--
	
	#Capturing/freeing the cursor ( This is so that the mouse will move the camera, while when it is not captured the cursor will instead just move across the screen, this works in conjunction with another part of the code)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# ----------------------------------
	# Sprinting
	if Input.is_action_pressed("movement_sprint"): #If the input is being pressed, the max speed increases by changing the is sprinting variables
		is_sprinting = true
	else: #same as above, but instead it sets the player to not sprint if the input is not being pressed.
		is_sprinting = false
	# ----------------------------------
	
	# ----------------------------------
	# Turning the flashlight on/off
	if Input.is_action_just_pressed("flashlight"): # Detects if the player wants to turn off the flashlight
		if flashlight.is_visible_in_tree(): # Detects if it is off
			flashlight.hide() #turns off by hiding it from the scene
	else:
		flashlight.show() # Shows flashlight by unhiding it
	# ----------------------------------
	
	# ----------------------------------
	# Changing weapons.
	var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
	
	if Input.is_key_pressed(KEY_1): #Key 1 is in this case the number 1 on the keybaord, and the following occurs. This detects if this is pressed.
		weapon_change_number = 0 #Works off an array above. Weapon 0 is unarmed, Weapon 1 the knife, 2 the pistol, 3 the rifle
	if Input.is_key_pressed(KEY_2):
		weapon_change_number = 1
	if Input.is_key_pressed(KEY_3):
		weapon_change_number = 2
	if Input.is_key_pressed(KEY_4):
		weapon_change_number = 3
	
	if Input.is_action_just_pressed("shift_weapon_positive"): #allows the scroll wheel to change the weapon the player is using
		weapon_change_number += 1
	if Input.is_action_just_pressed("shift_weapon_negative"):
		weapon_change_number -= 1
	
	weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size() - 1)
	
	if changing_weapon == false:
		if reloading_weapon == false:
			if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
				changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
				changing_weapon = true
		if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
			changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
			changing_weapon = true
			mouse_scroll_value = weapon_change_number
			#This stops the player from chaning weapon when doing things like reloading.

	# ----------------------------------
	
# ----------------------------------
# Firing the weapons
	if Input.is_action_pressed("fire"): # Detects if the player wants to fire the weapon
		if changing_weapon == false:
			var current_weapon = weapons[current_weapon_name]
			if current_weapon != null:
				if current_weapon.ammo_in_weapon > 0:
					if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
						animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME) # Plays the firing animation
# ----------------------------------
	# ----------------------------------
	
	# ----------------------------------
	# Reloading
	if reloading_weapon == false:
		if changing_weapon == false:
			if Input.is_action_just_pressed("reload"):
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null:
					if current_weapon.CAN_RELOAD == true:
						var current_anim_state = animation_manager.current_state
						var is_reloading = false
						for weapon in weapons:
							var weapon_node = weapons[weapon]
							if weapon_node != null:
								if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
									is_reloading = true
						if is_reloading == false:
							reloading_weapon = true
							
							#Plays the reloading animation
# ----------------------------------
	
	#Grabbing stuff
	if Input.is_action_just_pressed("fire_grenade"):
		if grabbed_object == null:
			var state = get_world().direct_space_state
			var center_position = get_viewport().size/2
			var ray_from = camera.project_ray_origin(center_position)
			var ray_to = ray_from + camera.project_ray_normal(center_position) * OBJECT_GRAB_RAY_DISTANCE
			var ray_result = state.intersect_ray(ray_from, ray_to, [self, $Rotation_Helper/Gun_Fire_Points/Knife_Point/Area])
			if !ray_result.empty():
				if ray_result["collider"] is RigidBody:
					grabbed_object = ray_result["collider"]
					grabbed_object.mode = RigidBody.MODE_STATIC
					grabbed_object.collision_layer = 0
					grabbed_object.collision_mask = 0
					#Gives the grenade a direction it is thrown. 
		else: 
			grabbed_object.mode = RigidBody.MODE_RIGID
			grabbed_object.apply_impulse(Vector3(0, 0, 0), -camera.global_transform.basis.z.normalised() * OBJECT_THROW_FORCE)
			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1
			grabbed_object = null
			#Throws objects if they have beeen picked up
	if grabbed_object !=null:
		grabbed_object.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z.normalized() * OBJECT_GRAB_DISTANCE)
	
	

func process_changing_weapons(delta):
	if changing_weapon == true:

		var weapon_unequipped = false
		var current_weapon = weapons[current_weapon_name]

		if current_weapon == null:
			weapon_unequipped = true
		else:
			if current_weapon.is_weapon_enabled == true:
				weapon_unequipped = current_weapon.unequip_weapon()
			else:
				weapon_unequipped = true

		if weapon_unequipped == true:

			var weapon_equipped = false
			var weapon_to_equip = weapons[changing_weapon_name]

			if weapon_to_equip == null:
				weapon_equipped = true
			else:
				if weapon_to_equip.is_weapon_enabled == false:
					weapon_equipped = weapon_to_equip.equip_weapon()
				else:
					weapon_equipped = true

			if weapon_equipped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name
				changing_weapon_name = ""

#Code for chaning weapons. Pretty much detects if the player wants to change

func fire_bullet():
	if changing_weapon == true:
		return

	weapons[current_weapon_name].fire_weapon() 

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized() #means that the direction depends on where the cemera is facing meaning forward is always forward instead of along the y.axis

	vel.y += delta * GRAVITY #Player is effected by gravity

	var hvel = vel
	hvel.y = 0

	var target = dir

	if is_sprinting:
		target *= MAX_SPRINT_SPEED # Nax speed / movement
	else:
		target *= MAX_SPEED # max speed / movement

	var accel

	if dir.dot(hvel) > 0:
		if is_sprinting:
			accel = SPRINT_ACCEL #accelerates the player at either sprint or normal speed depending on previous variables / inputs
		else:
			accel = ACCEL
	else:
		accel = DEACCEL #Slows player down

	hvel = hvel.linear_interpolate(target, accel * delta) # Means the player cant go faster if they are moving to the left and forward due to C^2 = A^2+B^2 meaning C^2 is bigger, this prevents this
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			if event.button_index == BUTTON_WHEEL_UP:
				mouse_scroll_value += MOUSE_SENSITIVITY_SCROLL_WHEEL
			elif event.button_index == BUTTON_WHEEL_DOWN:
				mouse_scroll_value -= MOUSE_SENSITIVITY_SCROLL_WHEEL

			mouse_scroll_value = clamp(mouse_scroll_value, 0, WEAPON_NUMBER_TO_NAME.size() - 1)

			if changing_weapon == false:
				if reloading_weapon == false:
					var round_mouse_scroll_value = int(round(mouse_scroll_value))
					if WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value] != current_weapon_name:
						changing_weapon_name = WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value]
						changing_weapon = true
						mouse_scroll_value = round_mouse_scroll_value
	
	if Input.is_action_just_pressed("change_grenade"):
		if current_grenade == "Grenade":
			current_grenade = "Sticky Grenade"
		elif current_grenade == "Sticky Grenade":
			current_grenade = "Grenade"

	if Input.is_action_just_pressed("fire_grenade"):
		if grenade_amounts[current_grenade] > 0:
			grenade_amounts[current_grenade] -= 1

			var grenade_clone
			if current_grenade == "Grenade":
				grenade_clone = grenade_scene.instance()
			elif current_grenade == "Sticky Grenade":
				grenade_clone = sticky_grenade_scene.instance()
				# Sticky grenades will stick to the player if we do not pass ourselves
				grenade_clone.player_body = self

			get_tree().root.add_child(grenade_clone)
			grenade_clone.global_transform = $Rotation_Helper/Grenade_Toss_Pos.global_transform
			grenade_clone.apply_impulse(Vector3(0, 0, 0), grenade_clone.global_transform.basis.z * GRENADE_THROW_FORCE)
# ----------------------------------
	
	
	
	if is_dead:
		return



func process_UI(delta):
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		# First line: Health, second line: Grenades, third line: score
		UI_status_label.text = "HEALTH: " + str(round(health)) + \
				"\n" + current_grenade + ": " + str(grenade_amounts[current_grenade]) + \
				"\nSCORE: " + str(round(Globals.score))
	else:
		var current_weapon = weapons[current_weapon_name]
		# First line: Health, second line: weapon and ammo, third line: grenades, fourth line: score
		UI_status_label.text = "HEALTH: " + str(round(health)) + \
				"\nAMMO: " + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo) + \
				"\n" + current_grenade + ": " + str(grenade_amounts[current_grenade]) + \
				"\nSCORE: " + str(round(Globals.score))

func process_reloading(delta):
	if reloading_weapon == true:
		var current_weapon = weapons[current_weapon_name]
		if current_weapon != null:
			current_weapon.reload_weapon()
		reloading_weapon = false

func create_sound(sound_name, position=null):
	globals.play_sound(sound_name, false, position)



func add_health(additional_health):
	health += additional_health
	health = clamp(health, 0, MAX_HEALTH)


func add_ammo(additional_ammo):
	if (current_weapon_name != "UNARMED"):
		if (weapons[current_weapon_name].CAN_REFILL == true):
			weapons[current_weapon_name].spare_ammo += weapons[current_weapon_name].AMMO_IN_MAG * additional_ammo

func add_grenade(additional_grenade):
	grenade_amounts[current_grenade] += additional_grenade
	grenade_amounts[current_grenade] = clamp(grenade_amounts[current_grenade], 0, 4)

func bullet_hit(damage, bullet_hit_pos):
	health -= damage
	Globals.score -= damage
	print (Globals.score)

func process_respawn(delta):

	# If we've just died
	if health <= 0 and !is_dead:
		$Body_CollisionShape.disabled = true
		$Feet_CollisionShape.disabled = true

		changing_weapon = true
		changing_weapon_name = "UNARMED"

		$HUD/Death_Screen.visible = true

		$HUD/Panel.visible = false
		$HUD/Crosshair.visible = false

		dead_time = RESPAWN_TIME
		is_dead = true

		if grabbed_object != null:
			grabbed_object.mode = RigidBody.MODE_RIGID
			grabbed_object.apply_impulse(Vector3(0, 0, 0), -camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE / 2)

			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1

			grabbed_object = null

	if is_dead:
		dead_time -= delta

		var dead_time_pretty = str(dead_time).left(3)
		$HUD/Death_Screen/Label.text = "You died\n" + dead_time_pretty + " seconds till respawn"

		if dead_time <= 0:
			global_transform.origin = globals.get_respawn_position()

			$Body_CollisionShape.disabled = false
			$Feet_CollisionShape.disabled = false

			$HUD/Death_Screen.visible = false

			$HUD/Panel.visible = true
			$HUD/Crosshair.visible = true

			for weapon in weapons:
				var weapon_node = weapons[weapon]
				if weapon_node != null:
					weapon_node.reset_weapon()

			health = 100
			grenade_amounts = {"Grenade":2, "Sticky Grenade":2}
			current_grenade = "Grenade"

			is_dead = false


func process_view_input(delta):
	pass

func dimension(delta) :
	
	if Globals.dimension > 0:
		power_left = POWER_TIME
		if power_left > 0:
			power_left -= delta
		else:
			Globals.dimension = 0
	
	if Globals.dimension == 0:
		pass
	if Globals.dimension == 1:
		if health <= MAX_HEALTH :
			health += 5 * delta
		if health > MAX_HEALTH : 
			health == MAX_HEALTH
		else : 
			pass
		print (health)
		print (Globals.dimension)
	if Globals.dimension == 2:
		pass
	if Globals.dimension == 3:
		pass
	if Globals.dimension == 4:
		pass
	if Globals.dimension == 5:
		pass

#Above is the framework for powerups. This is done both here and in a few other places depending on what is being effected. For example the changes for damage are changed in the bullet scene.

