extends Area2D

# The axe at the end of the dog house.
# Pick it up and your double-tap throws axes instead of fireballs —
# and axes are the only thing the dog is scared of.

const BOB_HEIGHT = 2.0
const BOB_SPEED = 3.5

var resting_y := 0.0
var clock := 0.0


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	clock += delta * BOB_SPEED
	position.y = resting_y + sin(clock) * BOB_HEIGHT


func _someone_touched_me(who):
	if who.has_method("grab_the_axe"):
		who.grab_the_axe()
		queue_free()
