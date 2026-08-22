extends Area2D

# A coin. It bobs up and down, and vanishes when the cat touches it.

# How far it bobs, and how fast.
const BOB_HEIGHT = 2.0
const BOB_SPEED = 4.0

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	# Start each coin at a slightly different point in the bob,
	# so a row of coins ripples instead of moving as one lump.
	clock = position.x * 0.05
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta * BOB_SPEED
	position.y = resting_y + sin(clock) * BOB_HEIGHT


func _someone_touched_me(who):
	if who.has_method("collect_coin"):
		who.collect_coin()
		queue_free()
