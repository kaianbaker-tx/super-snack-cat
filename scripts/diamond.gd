extends Area2D

# ============================================================
#    THE DIAMOND
#    Pops out of a BLUE block. Grab it and for a few seconds
#    NOTHING can hurt you — and anything you run into gets
#    flattened, even a spiky ball.
# ============================================================

const BOB_HEIGHT = 2.5
const BOB_SPEED = 4.0

# How fast it flickers between colours while it sits there,
# so you can spot one from across the level.
const SPARKLE_SPEED = 6.0

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta
	position.y = resting_y + sin(clock * BOB_SPEED) * BOB_HEIGHT

	# Cycle the colour round the rainbow. h is the hue: 0 is red,
	# 0.33 green, 0.66 blue, and 1 is back to red again.
	$Sprite.modulate = Color.from_hsv(fmod(clock * SPARKLE_SPEED * 0.1, 1.0), 0.55, 1.0)


func _someone_touched_me(who):
	if who.has_method("go_invincible"):
		who.go_invincible()
		queue_free()
