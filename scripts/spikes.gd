extends Area2D

# ============================================================
#    SPIKES
#    Sharp. Don't land on them.
#    Write a ^ in the level to put some down.
# ============================================================

func _ready():
	body_entered.connect(_someone_touched_me)


func _someone_touched_me(who):
	# Only the cat can be hurt. Baddies walk over spikes happily,
	# which is annoying, and that is the point.
	if who.has_method("ouch"):
		who.ouch()
