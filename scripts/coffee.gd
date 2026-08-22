extends Area2D

# The cup of coffee with a paw print on it.
# Drink it and the cat gets FIRE POWERS.

const BOB_HEIGHT = 2.0
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
	if who.has_method("drink_the_coffee"):
		who.drink_the_coffee()
		queue_free()
