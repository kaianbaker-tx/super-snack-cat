extends StaticBody2D

# ============================================================
#    A LOCKED DOOR
#    Solid. You cannot walk through it, jump over it, or burn it.
#    Find a key first. Write an L in the level to build one.
# ============================================================

func _ready():
	$Reach.body_entered.connect(_someone_came_close)


func _someone_came_close(who):
	# No key, no entry.
	if not who.has_method("use_a_key"):
		return
	if not who.use_a_key():
		return

	open_up()


func open_up():
	$UnlockSound.play()

	# Stop blocking the way straight away, so the cat can walk on
	# while the door is still swinging open.
	$CollisionShape2D.set_deferred("disabled", true)
	$Reach.set_deferred("monitoring", false)

	# Swing the door open and fade it out.
	var swing = create_tween()
	swing.set_parallel(true)
	swing.tween_property($Sprite, "scale:x", 0.1, 0.25)
	swing.tween_property($Sprite, "modulate:a", 0.0, 0.25)
	await swing.finished
	queue_free()
