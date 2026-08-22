extends Area2D

# ============================================================
#    A HEART
#    Pops out of a RED block. Picking it up gives you one heart
#    back, up to the most you're allowed to carry.
# ============================================================

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
	if who.has_method("heal"):
		who.heal()
		queue_free()
