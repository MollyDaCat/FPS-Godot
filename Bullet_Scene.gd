extends Spatial

var BULLET_SPEED = 70  #Speed of the Bullet
var BULLET_DAMAGE = 15 # Damage dealt by bullet

const KILL_TIMER = 4 #Time till despawn
var timer = 0 #How long "Lived"

var hit_something = false # Hit something, does what it says really

func _ready():
	$Area.connect("body_entered", self, "collided")


func _physics_process(delta):
	var forward_dir = global_transform.basis.z.normalized()
	global_translate(forward_dir * BULLET_SPEED * delta) 
# Movement
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()


func collided(body):
	if hit_something == false:
		if body.has_method("bullet_hit"):
			body.bullet_hit(BULLET_DAMAGE, global_transform)

	hit_something = true
	queue_free()
