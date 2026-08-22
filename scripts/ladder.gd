extends Area2D

# ============================================================
#    A LADDER RUNG
#    One square of ladder. Write = in a level to build one,
#    and stack them up to make a tall ladder.
#
#    You can walk straight through a ladder. Press UP or DOWN
#    while you're on it to start climbing.
# ============================================================

func _ready():
	body_entered.connect(_someone_grabbed_on)
	body_exited.connect(_someone_let_go)


func _someone_grabbed_on(who):
	if who.has_method("touch_ladder"):
		who.touch_ladder()


func _someone_let_go(who):
	if who.has_method("leave_ladder"):
		who.leave_ladder()
