extends CharacterBody2D

# ============================================================
#    THE SPIKY BALL
#    It rolls along the ground and it is spiky ALL THE WAY ROUND.
#    You cannot jump on it. You cannot burn it. You just have to
#    get out of its way.
#
#    Write an O in the level to set one rolling.
# ============================================================

# How fast it rolls. Faster than a mushroom, because it's rolling
# and mushrooms are walking.
const SPEED = 46.0

const GRAVITY = 900.0

# How fast the picture spins as it rolls. This is worked out from
# the speed so the spin always matches the rolling — turn SPEED up
# and the spin keeps up on its own.
const SPIN = 0.09

# -1 rolls left, 1 rolls right.
var direction := -1


func _ready():
	$Hitbox.body_entered.connect(_someone_touched_me)


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	velocity.x = direction * SPEED
	move_and_slide()

	# Feel for the floor just ahead, so it turns at a cliff edge
	# instead of rolling off into nothing.
	$GroundCheck.position.x = 8 * direction
	$GroundCheck.force_raycast_update()

	if is_on_wall() or not $GroundCheck.is_colliding():
		direction = -direction

	# Roll the picture. A ball rolling right spins clockwise.
	$Sprite.rotation += direction * SPEED * SPIN * delta


var smashed := false


func _someone_touched_me(who):
	if smashed:
		return
	if not who.has_method("ouch"):
		return

	# There is exactly one way to beat a spiky ball, and it's a
	# diamond. Jumping on it will never work.
	if who.is_invincible():
		get_smashed()
		return

	# No stomping. No mercy. Spikes on every side.
	who.ouch()


func get_smashed():
	smashed = true
	$Hitbox.set_deferred("monitoring", false)
	set_physics_process(false)

	# Fly off sideways, spinning, and fade out.
	var fly = create_tween()
	fly.set_parallel(true)
	fly.tween_property(self, "position:y", position.y - 30.0, 0.6)
	fly.tween_property(self, "position:x", position.x + direction * 40.0, 0.6)
	fly.tween_property($Sprite, "rotation", $Sprite.rotation + TAU * 2.0, 0.6)
	fly.tween_property($Sprite, "modulate:a", 0.0, 0.6)
	await fly.finished
	queue_free()
