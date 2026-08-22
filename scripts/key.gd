extends Area2D

# ============================================================
#    A KEY
#    Pick it up, then walk into a locked door to open it.
#    Write a k in the level to hide one somewhere.
# ============================================================

# How far it bobs up and down, and how fast. Same idea as a coin,
# but a bit slower so it feels heavier and more important.
const BOB_HEIGHT = 2.5
const BOB_SPEED = 3.0

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta * BOB_SPEED
	position.y = resting_y + sin(clock) * BOB_HEIGHT


func _someone_touched_me(who):
	if who.has_method("take_a_key"):
		who.take_a_key()
		queue_free()
