extends CharacterBody2D

# ============================================================
#    THE MUSHROOM BADDIE
#    It walks back and forth. Land on its head and it gets flat.
#    Touch it any other way and you go back to the start.
# ============================================================

# How fast it shuffles along.
const SPEED = 28.0

const GRAVITY = 900.0

# -1 means it walks left, 1 means it walks right.
var direction := -1

var squashed := false


func _ready():
	$Hitbox.body_entered.connect(_someone_touched_me)


func _physics_process(delta):
	if squashed:
		return

	velocity.y += GRAVITY * delta
	velocity.x = direction * SPEED
	move_and_slide()

	# Point the little feeler at the ground just in front of us.
	$GroundCheck.position.x = 7 * direction
	$GroundCheck.force_raycast_update()

	# Bumped a wall, or there's no floor ahead? Turn around.
	if is_on_wall() or not $GroundCheck.is_colliding():
		direction = -direction

	$Sprite.flip_h = direction > 0


func _someone_touched_me(who):
	if squashed:
		return

	# Only the cat matters. Everything else can walk on by.
	if not who.has_method("stomp"):
		return

	# Was the cat falling, and above us? Then it landed on our head.
	if who.velocity.y > 0 and who.global_position.y < global_position.y - 4:
		get_squashed(who)
	else:
		who.ouch()


# A fireball hit us. Same as being jumped on, but nobody bounces.
func hit_by_fireball():
	if squashed:
		return
	get_squashed(null)


func get_squashed(cat):
	squashed = true
	if cat != null:
		cat.stomp()

	# Go flat, and stop being touchable.
	$Sprite.scale.y = 0.35
	$Sprite.position.y = 6
	$Hitbox.set_deferred("monitoring", false)

	# Sit there flat for a moment, then disappear.
	await get_tree().create_timer(0.5).timeout
	queue_free()
