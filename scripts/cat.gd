extends CharacterBody2D

# ============================================================
#    THE CAT
#    Change any number below, press play, and feel what happens.
# ============================================================

# How fast the cat runs. Bigger = faster.
const SPEED = 135.0

# How quickly it gets up to full speed, and how quickly it stops.
# Small numbers feel slippery, like ice.
const SPEEDING_UP = 900.0
const SLOWING_DOWN = 1100.0

# How hard the jump pushes. NEGATIVE, because in games up is negative.
const JUMP_STRENGTH = -330.0

# Gravity while you are going UP, and while you are coming DOWN.
# Falling faster than you rise is the secret trick that makes
# Mario jumps feel snappy instead of floaty.
const GRAVITY_GOING_UP = 950.0
const GRAVITY_COMING_DOWN = 1500.0

# Let go of the jump key early and the cat stops rising here.
# That is how you get little hops AND big jumps from one button.
const SHORT_JUMP = -90.0

# A tiny bit of extra time to jump after you walk off a ledge.
# Real Mario does this too. Nobody notices, it just feels fair.
const COYOTE_TIME = 0.1

# How big the bounce is when you land on a baddie's head.
const STOMP_BOUNCE = 0.7

# ---- Fire powers (you get these from the cup of coffee) ----

# Tap the space bar TWICE quickly to shoot. This is how quick
# "quickly" has to be.
const DOUBLE_TAP_TIME = 0.35

# You can't have more than this many fireballs flying at once.
const MOST_FIREBALLS_AT_ONCE = 2

# How long you flash and can't be hurt after losing your fire powers.
const SAFE_TIME_AFTER_A_HIT = 1.5


# ---- Things the cat remembers while the game runs ----

signal coins_changed(total)      # shouts the new number to the score board
signal shout(words)              # asks for a message on screen
signal finished                  # shouts once, when you eat the sandwich

var coins := 0
var facing := 1                  # 1 = looking right, -1 = looking left
var start_position := Vector2.ZERO
var time_since_on_floor := 0.0
var walk_timer := 0.0
var has_finished := false
var has_axe := false           # true once you pick up the axe
var has_fire := false          # true after you drink the coffee
var last_jump_press := -99.0   # used to spot a double tap
var clock := 0.0               # counts up forever, so we can time things
var safe_until := -99.0        # nothing can hurt you until this time

# Fall below this line and you've fallen out of the world.
# The level sets this for us when the game starts.
var bottom_of_the_world := 400.0

# The four pictures of the cat: standing, walking A, walking B, jumping.
var normal_pictures = [
	preload("res://assets/sprites/cat_idle.png"),
	preload("res://assets/sprites/cat_walk1.png"),
	preload("res://assets/sprites/cat_walk2.png"),
	preload("res://assets/sprites/cat_jump.png"),
]

# The same four, but red with overalls, for when you have fire powers.
var fire_pictures = [
	preload("res://assets/sprites/firecat_idle.png"),
	preload("res://assets/sprites/firecat_walk1.png"),
	preload("res://assets/sprites/firecat_walk2.png"),
	preload("res://assets/sprites/firecat_jump.png"),
]

var fireball_scene = preload("res://scenes/fireball.tscn")


func _ready():
	# Joining a group is how the dog finds the cat later on.
	add_to_group("cat")

	# Remember the starting spot.
	start_position = global_position

	# Make R the restart key.
	if not InputMap.has_action("restart"):
		InputMap.add_action("restart")
		var key := InputEventKey.new()
		key.keycode = KEY_R
		InputMap.action_add_event("restart", key)


func _physics_process(delta):
	# R starts the whole level over.
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return

	# Once you've eaten the sandwich, the cat takes a rest.
	if has_finished:
		velocity.x = move_toward(velocity.x, 0.0, SLOWING_DOWN * delta)
		move_and_slide()
		return

	clock += delta

	fall(delta)
	jump()
	run(delta)

	move_and_slide()
	choose_picture(delta)

	# Fell off the bottom? Go back to the start.
	if global_position.y > bottom_of_the_world:
		ouch()


# Gravity pulls you down, harder on the way down than on the way up.
func fall(delta):
	if is_on_floor():
		time_since_on_floor = 0.0
		return

	time_since_on_floor += delta
	if velocity.y < 0:
		velocity.y += GRAVITY_GOING_UP * delta
	else:
		velocity.y += GRAVITY_COMING_DOWN * delta


func jump():
	if Input.is_action_just_pressed("ui_accept"):
		# Two quick taps of the space bar means SHOOT, not jump.
		# (You can't jump again in mid-air anyway, so that second
		# tap was doing nothing before.)
		var this_is_a_double_tap = clock - last_jump_press < DOUBLE_TAP_TIME
		last_jump_press = clock

		if this_is_a_double_tap and has_fire:
			shoot_a_fireball()
		elif time_since_on_floor < COYOTE_TIME:
			# Standing on the floor, or only just stepped off it. Jump!
			velocity.y = JUMP_STRENGTH
			# Use up the coyote time so you can't jump twice.
			time_since_on_floor = COYOTE_TIME
			$JumpSound.play()

	# Let go of the key while still rising? Cut the jump short.
	if Input.is_action_just_released("ui_accept") and velocity.y < SHORT_JUMP:
		velocity.y = SHORT_JUMP


func shoot_a_fireball():
	# Only two fireballs in the air at a time. Otherwise you could
	# hold the button down and clear the whole level from the start.
	if get_tree().get_nodes_in_group("fireballs").size() >= MOST_FIREBALLS_AT_ONCE:
		return

	var ball = fireball_scene.instantiate()
	ball.position = position + Vector2(11 * facing, -1)
	ball.direction = facing
	ball.is_axe = has_axe
	get_parent().add_child.call_deferred(ball)
	$FireballSound.play()


func run(delta):
	# Left arrow gives -1, right arrow gives 1, nothing gives 0.
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction == 0:
		# Nothing held: slide to a stop.
		velocity.x = move_toward(velocity.x, 0.0, SLOWING_DOWN * delta)
	else:
		# Build up to full speed instead of snapping to it.
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEEDING_UP * delta)
		facing = 1 if direction > 0 else -1


# Picks which of the four cat pictures to show right now.
func choose_picture(delta):
	$Body.flip_h = facing < 0

	# Red cat in overalls if you have fire powers, orange cat if not.
	var pictures = fire_pictures if has_fire else normal_pictures

	if not is_on_floor():
		$Body.texture = pictures[3]
	elif absf(velocity.x) > 5.0:
		# Flip between the two walking pictures. Faster running,
		# faster flipping.
		walk_timer += delta * absf(velocity.x) * 0.05
		$Body.texture = pictures[1] if int(walk_timer) % 2 == 0 else pictures[2]
	else:
		$Body.texture = pictures[0]

	# Flash on and off while you're briefly safe after being hit.
	if clock < safe_until:
		$Body.modulate.a = 0.35 if fmod(clock, 0.16) < 0.08 else 1.0
	else:
		$Body.modulate.a = 1.0


# ---- Things the rest of the world asks the cat to do ----

# A coin calls this when you touch it.
func collect_coin():
	coins += 1
	$CoinSound.play()
	coins_changed.emit(coins)


# A mushroom calls this when you land on its head.
func stomp():
	velocity.y = JUMP_STRENGTH * STOMP_BOUNCE
	$StompSound.play()


# A checkpoint flag calls this when you run past it.
# From now on, getting hurt sends you back HERE instead of all
# the way to the beginning of the level.
func touch_checkpoint(where):
	start_position = where
	$CheckpointSound.play()


# The axe calls this. Now your double tap throws AXES, which are
# the only thing the dog is frightened of.
func grab_the_axe():
	has_axe = true
	has_fire = true          # so you can throw even without coffee
	$PowerUpSound.play()
	shout.emit("GOT THE AXE!\nTAP SPACE TWICE!")


# The cup of coffee calls this. Fire powers!
func drink_the_coffee():
	has_fire = true
	$PowerUpSound.play()


# Called when a baddie gets you, or you fall off the world.
func ouch():
	if has_finished:
		return

	# Just been hit? Nothing can touch you for a moment.
	if clock < safe_until:
		return

	# With fire powers you only LOSE the powers — you don't go back
	# to the checkpoint. Same as Mario losing his fire flower.
	if has_fire and not has_axe:
		has_fire = false
		safe_until = clock + SAFE_TIME_AFTER_A_HIT
		$HurtSound.play()
		return

	# Holding the axe? You keep it, but you still get knocked back
	# to the checkpoint if the dog gets you.
	if has_axe:
		safe_until = clock + SAFE_TIME_AFTER_A_HIT

	$HurtSound.play()
	global_position = start_position
	velocity = Vector2.ZERO


# The sandwich calls this. Level over — you did it!
func finish_level():
	if has_finished:
		return
	has_finished = true
	$WinSound.play()
	finished.emit()
