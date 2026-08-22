extends Area2D

# ============================================================
#    THE CHIP
#    Pops out of a GREEN block. Eat it and the cat runs much
#    faster for ten seconds. It's a snack. The cat is a snack cat.
# ============================================================

const BOB_HEIGHT = 2.0
const BOB_SPEED = 4.5

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta
	position.y = resting_y + sin(clock * BOB_SPEED) * BOB_HEIGHT

	# A little wiggle, so it looks tasty rather than just sitting there.
	rotation = sin(clock * BOB_SPEED * 0.7) * 0.18


func _someone_touched_me(who):
	if who.has_method("eat_the_chip"):
		who.eat_the_chip()
		queue_free()
