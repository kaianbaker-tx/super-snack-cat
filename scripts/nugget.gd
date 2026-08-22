extends Area2D

# ============================================================
#    THE CHICKEN NUGGET
#    Pops out of an ORANGE block. Grab it and the cat climbs
#    into a chicken nugget suit — and once you're wearing it,
#    tapping SPACE TWICE throws chicken nuggets.
# ============================================================

const BOB_HEIGHT = 2.5
const BOB_SPEED = 3.5

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta
	position.y = resting_y + sin(clock * BOB_SPEED) * BOB_HEIGHT

	# A slow tumble, so it looks worth having.
	rotation = sin(clock * BOB_SPEED * 0.5) * 0.25


func _someone_touched_me(who):
	if who.has_method("wear_the_nugget_suit"):
		who.wear_the_nugget_suit()
		queue_free()
