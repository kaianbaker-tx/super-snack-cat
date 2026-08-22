extends CharacterBody2D

# ============================================================
#    THE BAT
#    Flies back and forth in a wavy line, flapping its wings.
#    Gravity doesn't touch it, because it can fly and you can't.
#    Land on its head and it drops. Touch it anywhere else and it
#    gets you.
#
#    Write an E in the level to hang one up.
# ============================================================

# How fast it flies sideways.
const SPEED = 42.0

# The wavy up-and-down flight.
#   HOW_HIGH is how far up and down it swings, in pixels.
#   HOW_WAVY is how many swings it does per second. Turn this up
#   and it goes from a lazy glide to a panicky flutter.
const HOW_HIGH = 22.0
const HOW_WAVY = 1.6

# How far it will wander from where you put it before turning back.
const WANDER = 70.0

# How fast the wings flap. Bigger = faster flapping.
const FLAP_SPEED = 9.0

# The three wing pictures, in the order they play.
const WING_PICTURES = [
	Rect2(144, 48, 24, 24),   # wings down
	Rect2(168, 48, 24, 24),   # wings out flat
	Rect2(192, 48, 24, 24),   # wings up
]

var direction := -1
var home = Vector2.ZERO
var clock := 0.0
var knocked_out := false


func _ready():
	home = position
	# Start each bat at a different point in its wave, so a group
	# of them looks like a swarm instead of a marching band.
	clock = position.x * 0.03
	$Hitbox.body_entered.connect(_someone_touched_me)


func _physics_process(delta):
	if knocked_out:
		# Wings folded, dropping out of the sky.
		velocity.y += 700.0 * delta
		move_and_slide()
		return

	clock += delta

	# Turn round if we've wandered too far from home, or bonked a wall.
	if absf(position.x - home.x) > WANDER or is_on_wall():
		direction = -direction
		# Nudge it back inside, so it can't get stuck flipping
		# left-right-left forever on the edge.
		position.x = clampf(position.x, home.x - WANDER, home.x + WANDER)

	velocity.x = direction * SPEED

	# The wave. sin() goes smoothly from -1 to 1 and back forever,
	# which is exactly the shape of a bat's flight path.
	var wave = sin(clock * HOW_WAVY * TAU)
	position.y = home.y + wave * HOW_HIGH
	velocity.y = 0.0

	move_and_slide()
	flap()


func flap():
	var which = int(clock * FLAP_SPEED) % WING_PICTURES.size()
	$Sprite.region_rect = WING_PICTURES[which]
	$Sprite.flip_h = direction > 0


func _someone_touched_me(who):
	if knocked_out:
		return
	if not who.has_method("stomp"):
		return

	# Falling, and above us? That's a stomp.
	if who.velocity.y > 0 and who.global_position.y < global_position.y - 4:
		get_knocked_out(who)
	else:
		who.ouch()


# A fireball got it.
func hit_by_fireball():
	get_knocked_out(null)


func get_knocked_out(cat):
	if knocked_out:
		return
	knocked_out = true
	if cat != null:
		cat.stomp()

	# Wings folded, spinning as it falls.
	$Sprite.region_rect = WING_PICTURES[2]
	$Hitbox.set_deferred("monitoring", false)
	velocity = Vector2(direction * 20.0, -60.0)

	var spin = create_tween()
	spin.set_parallel(true)
	spin.tween_property($Sprite, "rotation", TAU, 0.8)
	spin.tween_property($Sprite, "modulate:a", 0.0, 0.8)
	await spin.finished
	queue_free()
