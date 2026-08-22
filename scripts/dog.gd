extends CharacterBody2D

# ============================================================
#   THE DOG — the last boss of the game.
#
#   He stomps back and forth and hops about. You CANNOT jump on
#   his head, he's far too big — touching him hurts, every time.
#   Fireballs just bounce off him.
#
#   The only thing that beats him is the AXE at the end of the
#   dog house. Grab it, then tap space twice to throw it.
# ============================================================

const SPEED = 44.0
const GRAVITY = 900.0

# Every so often he does an angry little hop.
const HOP_STRENGTH = -320.0
const TIME_BETWEEN_HOPS = 2.2

# -1 means he's walking left, 1 means right.
var direction := -1

var beaten := false
var hop_timer := 0.0
var walk_timer := 0.0

var picture_walk1 = preload("res://assets/sprites/dog_walk1.png")
var picture_walk2 = preload("res://assets/sprites/dog_walk2.png")
var picture_beaten = preload("res://assets/sprites/dog_beaten.png")


func _ready():
	$Hitbox.body_entered.connect(_someone_touched_me)


func _physics_process(delta):
	velocity.y += GRAVITY * delta

	# Beaten? Just flop to the floor and stay there.
	if beaten:
		velocity.x = 0.0
		move_and_slide()
		return

	velocity.x = direction * SPEED

	# Angry hop, but only when he's actually on the ground.
	hop_timer += delta
	if hop_timer > TIME_BETWEEN_HOPS and is_on_floor():
		hop_timer = 0.0
		velocity.y = HOP_STRENGTH
		$BarkSound.play()

	move_and_slide()

	# Feel for the floor just ahead, same as the mushrooms do.
	$GroundCheck.position.x = 12 * direction
	$GroundCheck.force_raycast_update()
	if is_on_wall() or not $GroundCheck.is_colliding():
		direction = -direction

	# Stomping animation.
	walk_timer += delta * 6.0
	$Sprite.texture = picture_walk1 if int(walk_timer) % 2 == 0 else picture_walk2
	$Sprite.flip_h = direction > 0


func _someone_touched_me(who):
	if beaten:
		return
	# No stomping this one. Touching him hurts, whichever way you came.
	if who.has_method("ouch"):
		who.ouch()


# A plain fireball. Bounces right off him — he doesn't even notice.
func hit_by_fireball():
	if beaten:
		return
	$ClangSound.play()
	# Flash white for a moment so you can see it did nothing.
	$Sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		$Sprite.modulate = Color(1, 1, 1)


# The axe! This is the one that gets him.
func hit_by_axe():
	if beaten:
		return

	beaten = true
	velocity = Vector2.ZERO
	$Sprite.texture = picture_beaten
	$Sprite.modulate = Color(1, 1, 1)
	$Hitbox.set_deferred("monitoring", false)
	$BeatenSound.play()

	# Tell the cat it has won the whole game.
	var cat = get_tree().get_first_node_in_group("cat")
	if cat != null and cat.has_method("finish_level"):
		cat.finish_level()
