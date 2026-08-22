extends CharacterBody2D

# A fireball. It flies forward, bounces off the ground, and squashes
# any mushroom it touches. It burns out after a few seconds.

const SPEED = 190.0
const GRAVITY = 700.0
const BOUNCE = -230.0
const HOW_LONG_IT_LASTS = 2.5
const SPIN_SPEED = 14.0

# 1 = flying right, -1 = flying left. The cat sets this when it shoots.
var direction := 1

# Once you've picked up the axe you throw axes instead of fireballs.
# The cat sets this too, just before it lets go.
var is_axe := false

var axe_picture = preload("res://assets/sprites/axe.png")

var age := 0.0


func _ready():
	# Joining a group is how the cat counts how many fireballs
	# are already flying about.
	add_to_group("fireballs")
	$Hitbox.body_entered.connect(_hit_something)

	if is_axe:
		$Sprite.texture = axe_picture


func _physics_process(delta):
	age += delta
	if age > HOW_LONG_IT_LASTS:
		queue_free()
		return

	velocity.y += GRAVITY * delta
	velocity.x = SPEED * direction
	move_and_slide()

	# Boing! Fireballs bounce along the floor.
	if is_on_floor():
		velocity.y = BOUNCE

	# Smacked into a wall? That's the end of it.
	if is_on_wall():
		queue_free()
		return

	$Sprite.rotation += delta * SPIN_SPEED * direction


func _hit_something(who):
	# Only a thrown axe can hurt the dog.
	if is_axe and who.has_method("hit_by_axe"):
		who.hit_by_axe()
		queue_free()
		return

	if who.has_method("hit_by_fireball"):
		who.hit_by_fireball()
		queue_free()
