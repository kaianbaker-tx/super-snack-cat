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
	if not who.has_method("collect_coin"):
		return
	who.collect_coin()

	# Leave a little gold sparkle behind where the coin was.
	var sparkle = preload("res://scenes/puff.tscn").instantiate()
	sparkle.colour = Color(1.0, 0.85, 0.3)
	sparkle.how_many = 6
	sparkle.how_far = 18.0
	sparkle.how_long = 0.35
	sparkle.position = position
	get_parent().add_child.call_deferred(sparkle)

	queue_free()
