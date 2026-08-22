extends StaticBody2D

# ============================================================
#    A POWER-UP BLOCK
#
#    Jump up and BONK it with your head and something comes out.
#    What comes out depends on the colour:
#
#       gold   →  a coin
#       red    →  a heart, to get a lost one back
#       green  →  a cup of coffee — fire powers!
#       blue   →  a diamond — nothing can hurt you for a bit
#
#    They're all the same picture underneath, just painted a
#    different colour, so a new colour is one line of code.
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


# The level fills these two in when it builds the block.
var gives := "coin"
var colour := Color.WHITE

var used := false

var heart_scene = preload("res://scenes/heart.tscn")
var coffee_scene = preload("res://scenes/coffee.tscn")
var diamond_scene = preload("res://scenes/diamond.tscn")


func _ready():
	$Sprite.modulate = colour
	$Underneath.body_entered.connect(_something_bonked_me)


func _something_bonked_me(who):
	if used:
		return

	# Only the cat can bonk a block. A baddie walking past underneath
	# shouldn't set it off.
	if not who.has_method("collect_coin"):
		return

	# You have to be moving UP. Walking into the side doesn't count.
	if who.velocity.y >= 0:
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
	$Sprite.region_rect = USED_PICTURE
	$Sprite.modulate = colour.darkened(0.45)

	if gives == "coin":
		# A coin goes straight into your pocket, like it does in Mario.
		# The little picture flying up is just for show.
		cat.collect_coin()
		fling_a_coin_up()
		return

	let_something_out()


# Makes the thing this block was holding, and floats it up out of
# the top of the block.
func let_something_out():
	var thing = null
	if gives == "heart":
		thing = heart_scene.instantiate()
	elif gives == "coffee":
		thing = coffee_scene.instantiate()
	elif gives == "diamond":
		thing = diamond_scene.instantiate()
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
	sparkle.texture = $Sprite.texture
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
