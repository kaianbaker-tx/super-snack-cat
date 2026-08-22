extends Node2D

# ============================================================
#    A PUFF
#
#    A little burst of dots that fly outwards, shrink and fade.
#    Dust when you land, spray when you hit the water, sparkles
#    when you grab a coin — same puff, different colour.
#
#    Nobody has to tidy it up. It deletes itself when it's done.
# ============================================================

# How big one dot is, in pixels.
const DOT_SIZE = 3

# Anything below can be changed before you drop the puff into the
# level, to get a different kind of burst.
var colour := Color(1, 1, 1)
var how_many := 7
var how_far := 26.0        # how far the dots fly
var how_high := 12.0       # how much they drift upwards as they go
var how_long := 0.42       # seconds before it's all gone
var how_big := 1.0

# We draw our own little white square instead of borrowing a dot from
# the tile sheet. A WHITE dot can be painted any colour you like; a
# dark one just comes out dark whatever you do to it.
var dot_picture = null


func _ready():
	var square = Image.create(DOT_SIZE, DOT_SIZE, false, Image.FORMAT_RGBA8)
	square.fill(Color.WHITE)
	dot_picture = ImageTexture.create_from_image(square)

	for i in how_many:
		throw_a_dot(i)

	# Wait for the last dot to finish, then vanish.
	await get_tree().create_timer(how_long + 0.05).timeout
	queue_free()


func throw_a_dot(which):
	var dot = Sprite2D.new()
	dot.texture = dot_picture
	dot.modulate = colour
	dot.scale = Vector2(how_big, how_big)
	add_child(dot)

	# Fan the dots evenly across a half circle pointing upwards, then
	# jiggle each one a little so it doesn't look machine-made.
	var slice = (which + 0.5) / float(how_many)
	var angle = PI + slice * PI + randf_range(-0.2, 0.2)
	var lands_at = Vector2(cos(angle), sin(angle)) * how_far * randf_range(0.6, 1.2)
	lands_at.y -= how_high

	var fly = create_tween()
	fly.set_parallel(true)
	fly.tween_property(dot, "position", lands_at, how_long) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_property(dot, "scale", Vector2(how_big * 0.2, how_big * 0.2), how_long)
	fly.tween_property(dot, "modulate:a", 0.0, how_long)
