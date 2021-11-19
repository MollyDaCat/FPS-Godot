extends Node

var score = 0

var dimension = 2 #Keeps track of which powerup the player is currently in



var mouse_sensitivity = 0.08
var joypad_sensitivity = 2

const MAIN_MENU_PATH = "res://Main_Menu.tscn"
const POPUP_SCENE = preload("res://Pause_Popup.tscn")
var popup = null

var audio_clips = {
	"Pistol_shot": preload("res://211566__ballistiq85__laugh-1.wav"),
	"Rifle_shot": preload("res://211566__ballistiq85__laugh-1.wav"),
	"Gun_cock": preload("res://211566__ballistiq85__laugh-1.wav"),
}

#This loads the audio for the guns being shot. However at the moment all of these are place-holders. However the script is still here. When the guns fire they get the audio from here.

const SIMPLE_AUDIO_PLAYER_SCENE = preload("res://Simple_Audio_Player.tscn")
var created_audio = [] 

# All the GUI/UI-related variables

var canvas_layer = null

var respawn_points = null


const DEBUG_DISPLAY_SCENE = preload("res://Debug_Display.tscn")
var debug_display = null



func _ready():
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	randomize()



func load_new_scene(new_scene_path):
	get_tree().change_scene(new_scene_path)
	respawn_points = null
	for sound in created_audio:
		if (sound != null):
			sound.queue_free()
	created_audio.clear()

#This is the script used to load new scenes. As such, for example, in the main menu, we run the scene change through this script here.




func set_debug_display(display_on):
	if display_on == false:
		if debug_display != null:
			debug_display.queue_free()
			debug_display = null
	else:
		if debug_display == null:
			debug_display = DEBUG_DISPLAY_SCENE.instance()
			canvas_layer.add_child(debug_display)

#Adds a debug display to the game

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if popup == null:
			popup = POPUP_SCENE.instance()

			popup.get_node("Button_quit").connect("pressed", self, "popup_quit")
			popup.connect("popup_hide", self, "popup_closed")
			popup.get_node("Button_resume").connect("pressed", self, "popup_closed")
			#Gives the three buttons in the pause menu a function instead of looking pretty. For the function read the name and it should be pretty obvious

			canvas_layer.add_child(popup)
			popup.popup_centered()

			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

			get_tree().paused = true
	if score < 0.5:
		score = 0.5
	score -= delta * 0.5
	#adds a time function to the game as well as linking this to score. This means that the player loses score the longer they take

func popup_closed():
	get_tree().paused = false

	if popup != null:
		popup.queue_free()
		popup = null

func popup_quit():
	get_tree().paused = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if popup != null:
		popup.queue_free()
		popup = null

	load_new_scene(MAIN_MENU_PATH)
#This is the function for the quit button in the meny previously mentioned.

func get_respawn_position():
	if respawn_points == null:
		return Vector3(0, 0, 0)
	else:
		var respawn_point = rand_range(0, respawn_points.size() - 1)
		return respawn_points[respawn_point].global_transform.origin

#Where the player respawns. This script says that if there is no designated respawn point then the base spawn in at the centre of the axis, however if there is a respawn point it will spawn there, and randomise this repsawn point if there is multiple.

func play_sound(sound_name, loop_sound=false, sound_position=null):
	if audio_clips.has(sound_name):
		var new_audio = SIMPLE_AUDIO_PLAYER_SCENE.instance()
		new_audio.should_loop = loop_sound

		add_child(new_audio)
		created_audio.append(new_audio)

		new_audio.play_sound(audio_clips[sound_name], sound_position)

	else:
		print ("ERROR: cannot play sound that does not exist in audio_clips!")

