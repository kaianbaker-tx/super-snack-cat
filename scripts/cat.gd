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

# ---- Hearts ----

# How many hits you can take. Lose them all and you go back to the
# last checkpoint with a full set again.
const HOW_MANY_HEARTS = 3

# Hearts out of RED blocks can push you past your starting three,
# up to this many. The score board always shows all the slots, so
# you can see how many you've still got room for.
const MOST_HEARTS = 5

# How long a diamond keeps you safe, in seconds.
const DIAMOND_TIME = 8.0

# How hard a baddie knocks you backwards when it gets you.
const KNOCKED_BACK = 130.0
const KNOCKED_UP = -180.0

# ---- Swimming (the ~ squares) ----

# Water holds you up, so gravity is much gentler down there.
const WATER_GRAVITY = 240.0

# ...and it's thick, so you can't run or sink through it fast.
const SWIMMING_SPEED = 95.0
const FASTEST_YOU_CAN_SINK = 80.0

# One push of the space bar underwater. Tap it over and over to
# climb up through the water.
const SWIM_STROKE = -145.0

# ---- Climbing (the = squares) ----

const CLIMBING_SPEED = 70.0


# ---- Things the cat remembers while the game runs ----

signal coins_changed(total)      # shouts the new number to the score board
signal hearts_changed(left)      # shouts when you lose or refill a heart
signal keys_changed(total)       # shouts when you pick up or use a key
signal shout(words)              # asks for a message on screen
signal finished                  # shouts once, when you eat the sandwich

var coins := 0
var hearts := HOW_MANY_HEARTS
var keys := 0

# How many water squares and ladder squares we're standing inside
# right now. They're counted, not just true/false, because a big
# pond is lots of little squares and you're often in two at once.
var water_squares := 0
var ladder_squares := 0
var climbing := false

# While the clock is below this, a diamond is protecting you.
var diamond_until := -99.0
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

	climb()
	fall(delta)
	jump()
	run(delta)

	move_and_slide()
	choose_picture(delta)

	# Fell off the bottom? Lose a heart and go back to the checkpoint.
	if global_position.y > bottom_of_the_world:
		ouch(true)


# Are we in the water right now?
func is_swimming():
	return water_squares > 0


# Grab a ladder and go up or down it.
func climb():
	# Nowhere near a ladder? Then there's nothing to hold on to.
	if ladder_squares == 0:
		climbing = false
		return

	# Up gives -1, down gives 1, nothing gives 0.
	var up_or_down = Input.get_axis("ui_up", "ui_down")

	# Press up or down while you're on a ladder to grab it.
	if up_or_down != 0:
		climbing = true

	if climbing:
		velocity.y = up_or_down * CLIMBING_SPEED


# Gravity pulls you down, harder on the way down than on the way up.
func fall(delta):
	# Hanging on a ladder beats gravity. That's the whole point
	# of a ladder.
	if climbing:
		time_since_on_floor = 0.0
		return

	if is_on_floor():
		time_since_on_floor = 0.0
		return

	time_since_on_floor += delta

	# In water you drift down slowly instead of dropping like a rock.
	if is_swimming():
		velocity.y += WATER_GRAVITY * delta
		velocity.y = minf(velocity.y, FASTEST_YOU_CAN_SINK)
		return

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

		if is_swimming():
			# Underwater EVERY press is a swimming stroke, even a
			# double tap. Swimming up means tapping fast, and you'd
			# never stop shooting fireballs by accident otherwise.
			velocity.y = SWIM_STROKE
			$JumpSound.play()
		elif this_is_a_double_tap and has_fire:
			shoot_a_fireball()
		elif climbing:
			# Let go of the ladder and spring off it.
			climbing = false
			velocity.y = JUMP_STRENGTH
			$JumpSound.play()
		elif time_since_on_floor < COYOTE_TIME:
			# Standing on the floor, or only just stepped off it. Jump!
			velocity.y = JUMP_STRENGTH
			# Use up the coyote time so you can't jump twice.
			time_since_on_floor = COYOTE_TIME
			$JumpSound.play()

	# Let go of the key while still rising? Cut the jump short.
	# Not in water though — a swimming stroke should always count.
	if Input.is_action_just_released("ui_accept") \
			and velocity.y < SHORT_JUMP and not is_swimming():
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

	# Water is thick. You can't sprint through it.
	var top_speed = SWIMMING_SPEED if is_swimming() else SPEED

	if direction == 0:
		# Nothing held: slide to a stop.
		velocity.x = move_toward(velocity.x, 0.0, SLOWING_DOWN * delta)
	else:
		# Build up to full speed instead of snapping to it.
		velocity.x = move_toward(velocity.x, direction * top_speed, SPEEDING_UP * delta)
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

	# Holding a diamond? Cycle through the rainbow so it's obvious.
	# The last second and a half flickers, as a warning it's running out.
	if is_invincible():
		var running_out = diamond_until - clock < 1.5
		if running_out and fmod(clock, 0.14) < 0.07:
			$Body.modulate = Color.WHITE
		else:
			$Body.modulate = Color.from_hsv(fmod(clock * 1.6, 1.0), 0.65, 1.0)
		return

	# Flash on and off while you're briefly safe after being hit.
	$Body.modulate = Color.WHITE
	if clock < safe_until:
		$Body.modulate.a = 0.35 if fmod(clock, 0.16) < 0.08 else 1.0


# ---- Things the rest of the world asks the cat to do ----

# Anything can ask the cat to put a message on the screen.
func say(words):
	shout.emit(words)

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


# ---- Water ----

# A water square calls this when you swim into it.
func enter_water():
	water_squares += 1

	# Only splash on the way IN, not for every square you cross.
	if water_squares == 1:
		# Hitting water kills your speed — no belly-flopping through
		# a pond at full pelt.
		velocity.y = minf(velocity.y, FASTEST_YOU_CAN_SINK)
		climbing = false
		$SplashSound.play()


func leave_water():
	water_squares = maxi(0, water_squares - 1)

	# Climbing out gets a splash too — but not if the whole level is
	# being put away, because a sound can't play from nowhere.
	if water_squares == 0 and is_inside_tree():
		$SplashSound.play()


# ---- Ladders ----

func touch_ladder():
	ladder_squares += 1


func leave_ladder():
	ladder_squares = maxi(0, ladder_squares - 1)
	if ladder_squares == 0:
		climbing = false


# ---- Hearts and diamonds ----

# A heart out of a red block calls this.
func heal():
	if hearts >= MOST_HEARTS:
		# Already carrying as many as you can. Have a coin instead,
		# so picking it up never feels like a waste.
		collect_coin()
		return

	hearts += 1
	hearts_changed.emit(hearts)
	$PowerUpSound.play()


# A diamond calls this. Nothing can hurt you for a few seconds, and
# anything you touch gets flattened.
func go_invincible():
	diamond_until = clock + DIAMOND_TIME
	$PowerUpSound.play()
	say("UNTOUCHABLE!")


# The baddies ask this before they decide what to do about you.
func is_invincible():
	return clock < diamond_until


# ---- Keys ----

# A key calls this when you pick it up.
func take_a_key():
	keys += 1
	keys_changed.emit(keys)
	$KeySound.play()
	shout.emit("GOT A KEY!")


# A locked door calls this. It hands back true if you had a key to
# spend, and false if you didn't — that's how the door knows
# whether to open.
func use_a_key():
	if keys <= 0:
		say("LOCKED!\nFIND THE KEY")
		return false
	keys -= 1
	keys_changed.emit(keys)
	return true


# ---- Getting hurt ----

# Called when a baddie gets you, or you fall off the world.
# `sent_home` is true only for falling out of the world, where being
# knocked backwards would just drop you out again.
func ouch(sent_home := false):
	if has_finished:
		return

	# Holding a diamond? Nothing gets through at all.
	if is_invincible():
		return

	# Just been hit? Nothing can touch you for a moment.
	if clock < safe_until:
		return

	# With fire powers you only LOSE the powers — no heart lost.
	# Same as Mario losing his fire flower.
	if has_fire and not has_axe:
		has_fire = false
		safe_until = clock + SAFE_TIME_AFTER_A_HIT
		$HurtSound.play()
		return

	hearts -= 1
	hearts_changed.emit(hearts)
	safe_until = clock + SAFE_TIME_AFTER_A_HIT
	$HurtSound.play()

	# Out of hearts. Back to the last checkpoint, with a fresh set.
	if hearts <= 0:
		hearts = HOW_MANY_HEARTS
		hearts_changed.emit(hearts)
		go_back_to_the_checkpoint()
		return

	if sent_home:
		go_back_to_the_checkpoint()
		return

	# Still standing! Just get knocked backwards, and keep playing
	# from right here.
	velocity = Vector2(-facing * KNOCKED_BACK, KNOCKED_UP)
	climbing = false


func go_back_to_the_checkpoint():
	global_position = start_position
	velocity = Vector2.ZERO
	climbing = false


# The sandwich calls this. Level over — you did it!
func finish_level():
	if has_finished:
		return
	has_finished = true
	$WinSound.play()
	finished.emit()
