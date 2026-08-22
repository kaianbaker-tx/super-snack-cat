extends Area2D

# A checkpoint flag.
# It starts grey. Touch it and it lights up, and from then on the
# cat comes back HERE when it gets hurt, instead of going all the
# way back to the start of the level.

var lit_up := false


func _ready():
	modulate = Color(0.55, 0.55, 0.62)     # grey, because nobody's touched it
	body_entered.connect(_someone_touched_me)


func _someone_touched_me(who):
	if lit_up:
		return
	if not who.has_method("touch_checkpoint"):
		return

	lit_up = true
	modulate = Color(1, 1, 1)             # back to full colour
	who.touch_checkpoint(global_position)
