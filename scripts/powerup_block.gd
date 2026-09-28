extends StaticBody2D

# ============================================================
#    A POWER-UP BLOCK
#
#    Jump up and BONK it with your head and something comes out.
#    What comes out depends on the colour:
#
#       gold   →  a LUCKY BLOCK — a surprise! (see below)
#       orange →  a chicken nugget — the suit, and nuggets to throw
#       red    →  a heart, to get a lost one back
#       green  →  a chip — run much faster for ten seconds
#       blue   →  a diamond — nothing can hurt you for a bit
#       brown  →  a cup of coffee — fire powers!
#
#    The coloured ones are all the same picture underneath, just
#    painted a different colour, so a new colour is one line of
#    code. The lucky block is Kenney's real gold block, shining.
# ============================================================

# The two pictures in the tile sheet: a fresh block with a ! on it,
# and the flat one with a dot, for after you've used it up.
const FRESH_PICTURE = Rect2(180, 0, 18, 18)
const USED_PICTURE = Rect2(198, 0, 18, 18)

# How far the block jumps when you bonk it, and how long that takes.
const BONK_HEIGHT = 6.0
const BONK_TIME = 0.09

# How far above the block whatever comes out ends up sitting.
const POPS_UP_TO = 18.0

# ---- The lucky block ----

# Kenney's gold block with a ! on it, and the plain brown block it
# turns into once you've had what's inside.
const LUCKY_PICTURE = Rect2(180, 0, 18, 18)
const LUCKY_USED_PICTURE = Rect2(162, 18, 18, 18)

# What can come out of a lucky block. The bigger the number, the
# more often it comes out. Make "coffee" 100 and it's nearly always
# coffee. Make "mushroom" 0 and there's never any bad luck.
const LUCKY_SURPRISES = {
	"coins": 30,       # a shower of five coins
	"nugget": 15,      # the chicken nugget suit
	"coffee": 15,      # fire powers
	"chip": 12,        # super speed
	"heart": 12,       # a heart back
	"diamond": 8,      # untouchable
	"mushroom": 8,     # BAD LUCK — a mushroom baddie jumps out!
}

# How many coins come out in a shower.
const COINS_IN_A_SHOWER = 5

# How fast the lucky block shines.
const SHINE_SPEED = 4.0


# The level fills these two in when it builds the block.
var gives := "coin"
var colour := Color.WHITE

var used := false

# The grey block pictures, made once when the block wakes up.
var fresh_grey = null
var used_grey = null

var heart_scene = preload("res://scenes/heart.tscn")
var coffee_scene = preload("res://scenes/coffee.tscn")
var diamond_scene = preload("res://scenes/diamond.tscn")
var chip_scene = preload("res://scenes/chip.tscn")
var nugget_scene = preload("res://scenes/nugget.tscn")
var mushroom_scene = preload("res://scenes/mushroom.tscn")

# Counts up, to make the lucky block shine.
var clock := 0.0


func _ready():
	$Underneath.body_entered.connect(_something_bonked_me)

	# The lucky block keeps Kenney's own colours. No painting.
	if gives == "lucky":
		$Sprite.region_rect = LUCKY_PICTURE
		return
	set_process(false)

	# Painting a colour on works by MULTIPLYING it into the picture,
	# and the block picture is gold — which has almost no blue in it.
	# Multiply gold by blue and you get mud. So we take the colour out
	# of the picture first, leaving a plain grey block, and then any
	# colour we paint on comes out true.
	fresh_grey = grey_copy_of(FRESH_PICTURE)
	used_grey = grey_copy_of(USED_PICTURE)

	$Sprite.region_enabled = false
	$Sprite.texture = fresh_grey
	$Sprite.modulate = colour


# The lucky block glows brighter and dimmer, over and over, so you
# can spot it from far away — like the ? blocks in Mario.
func _process(delta):
	if used:
		return
	clock += delta * SHINE_SPEED
	var glow = (sin(clock) + 1.0) / 2.0
	$Sprite.modulate = Color(1, 1, 1).lerp(Color(1.35, 1.3, 1.05), glow)


# Cuts one block out of the tile sheet and drains the colour out of
# it, keeping the light bits light and the dark outline dark.
func grey_copy_of(picture_area):
	var block = $Sprite.texture.get_image().get_region(picture_area)
	for y in block.get_height():
		for x in block.get_width():
			var was = block.get_pixel(x, y)
			var how_light = maxf(was.r, maxf(was.g, was.b))
			block.set_pixel(x, y, Color(how_light, how_light, how_light, was.a))
	return ImageTexture.create_from_image(block)


func _something_bonked_me(who):
	if used:
		return

	# Only the cat can bonk a block. A baddie walking past underneath
	# shouldn't set it off.
	if not who.has_method("collect_coin"):
		return

	# You have to be moving UP. Walking into the side doesn't count.
	# Bumping your head stops you dead, so by the time the block
	# hears about it you might not be moving any more — a head that
	# has just hit the ceiling counts too.
	if who.velocity.y >= 0 and not who.is_on_ceiling():
		return

	pop_open(who)


func pop_open(cat):
	used = true
	$BonkSound.play()

	# The block jumps up and drops back, the way it does in Mario.
	var bonk = create_tween()
	bonk.tween_property(self, "position:y", position.y - BONK_HEIGHT, BONK_TIME)
	bonk.tween_property(self, "position:y", position.y, BONK_TIME * 1.4)

	# Go flat and dim, so you can see at a glance it's been used.
	var what = gives
	if gives == "lucky":
		$Sprite.region_rect = LUCKY_USED_PICTURE
		$Sprite.modulate = Color(1, 1, 1)
		what = pick_a_surprise()
	else:
		$Sprite.texture = used_grey
		$Sprite.modulate = colour.darkened(0.45)

	if what == "coin":
		# A coin goes straight into your pocket, like it does in Mario.
		# The little picture flying up is just for show.
		cat.collect_coin()
		fling_a_coin_up()
		return

	if what == "coins":
		shower_of_coins(cat)
		return

	if what == "mushroom":
		cat.say("BAD LUCK!")
		let_a_baddie_out()
		return

	let_something_out(what)


# Spins the lucky wheel. Every surprise gets as many tickets as its
# number in LUCKY_SURPRISES, then we pull one ticket out of the hat.
func pick_a_surprise():
	var all_the_tickets = 0
	for surprise in LUCKY_SURPRISES:
		all_the_tickets += LUCKY_SURPRISES[surprise]

	var ticket = randi_range(1, maxi(all_the_tickets, 1))
	for surprise in LUCKY_SURPRISES:
		ticket -= LUCKY_SURPRISES[surprise]
		if ticket <= 0:
			return surprise
	return "coin"


# Five coins, one after another, straight into your pocket.
func shower_of_coins(cat):
	for i in COINS_IN_A_SHOWER:
		# Pressed R halfway through? Then stop quietly.
		if not is_inside_tree() or not is_instance_valid(cat):
			return
		cat.collect_coin()
		fling_a_coin_up()
		await get_tree().create_timer(0.12).timeout


# Bad luck! A mushroom baddie hops out of the top and walks off.
func let_a_baddie_out():
	var baddie = mushroom_scene.instantiate()
	baddie.position = position - Vector2(0, POPS_UP_TO)
	get_parent().add_child.call_deferred(baddie)
	$PopSound.play()


# Makes the thing this block was holding, and floats it up out of
# the top of the block.
func let_something_out(what):
	var thing = null
	if what == "heart":
		thing = heart_scene.instantiate()
	elif what == "coffee":
		thing = coffee_scene.instantiate()
	elif what == "diamond":
		thing = diamond_scene.instantiate()
	elif what == "chip":
		thing = chip_scene.instantiate()
	elif what == "nugget":
		thing = nugget_scene.instantiate()
	else:
		return

	# Start it hidden inside the block, then slide it out of the top.
	thing.position = position
	get_parent().add_child.call_deferred(thing)
	$PopSound.play()

	# Wait a frame so it's really in the level before we move it.
	await get_tree().process_frame
	if not is_instance_valid(thing):
		return

	# Everything that pops out bobs gently up and down around a
	# "resting" height it works out for itself. So we slide THAT
	# upwards — moving the thing directly would just get overwritten
	# by its own bobbing on the very next frame.
	var rise = create_tween()
	rise.tween_property(thing, "resting_y", position.y - POPS_UP_TO, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# A coin picture that flies up out of the block and fades away.
func fling_a_coin_up():
	var sparkle = Sprite2D.new()
	sparkle.texture = preload("res://assets/sprites/pixel_tiles.png")
	sparkle.region_enabled = true
	sparkle.region_rect = Rect2(198, 126, 18, 18)     # the coin picture
	sparkle.position = position
	get_parent().add_child(sparkle)

	var fly = create_tween()
	fly.set_parallel(true)
	fly.tween_property(sparkle, "position:y", position.y - 28.0, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_property(sparkle, "modulate:a", 0.0, 0.4)
	await fly.finished
	sparkle.queue_free()
