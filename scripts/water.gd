extends Area2D

# ============================================================
#    WATER
#    One square of it. The level builds a patch of these
#    wherever you write ~ in a level.
#
#    Water doesn't stop you — it just tells the cat it's swimming
#    now, and the cat does the rest in cat.gd.
# ============================================================

func _ready():
	body_entered.connect(_someone_got_in)
	body_exited.connect(_someone_got_out)


func _someone_got_in(who):
	if who.has_method("enter_water"):
		who.enter_water()


func _someone_got_out(who):
	if who.has_method("leave_water"):
		who.leave_water()
