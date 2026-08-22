extends Area2D

# The sandwich at the end of the level.
# Eat it and the level is finished.

const BOB_HEIGHT = 2.5
const BOB_SPEED = 3.0

var resting_y := 0.0
var clock := 0.0
var eaten := false


func _ready():
	resting_y = position.y
	body_entered.connect(_someone_touched_me)


func _process(delta):
	if eaten:
		return
	clock += delta * BOB_SPEED
	position.y = resting_y + sin(clock) * BOB_HEIGHT


func _someone_touched_me(who):
	if eaten:
		return
	if not who.has_method("finish_level"):
		return

	eaten = true
	visible = false
	who.finish_level()
