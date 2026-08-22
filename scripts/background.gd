extends Parallax2D

# ============================================================
#    THE BACKGROUND
#
#    The hills and clouds far away behind your level.
#    They slide past SLOWER than the ground you run on, and
#    that one trick is what makes the world look deep instead
#    of looking like a flat painting.
# ============================================================

# How much slower than the ground the hills slide.
#   1.0 = same speed as the ground (looks flat, boring)
#   0.0 = never moves at all (looks stuck on the screen)
# Try 0.2 and then 0.8 and see which one you like.
const HOW_SLOW = 0.4

# All the background pictures live in one sheet,
# 8 pictures across and 3 down. Each one is 24 pixels square.
const PICTURE_SIZE = 24
const SHEET_IS_THIS_WIDE = 8

# Row 0 of the sheet is plain sky.
# Row 1 is the hills, with sky above them.
# Row 2 is the solid colour underneath the hills.
const SKY_ROW = 0
const HILLS_ROW = 1
const UNDER_ROW = 2

# Every column of the sheet is a different look:
#      0, 1, 2, 3   pale blue, big clouds, snowy trees
#      4, 5         orange desert with sand dunes and a cactus
#      6, 7         green forest
#
# Below, each level gets a list of columns. The list repeats all
# the way along the level, so [6, 7] means forest-trees-forest-trees.
# An EMPTY list means no background at all — level 3 is indoors,
# so there is no sky to see.
const LEVEL_LOOKS = [
	[0, 1, 0, 3, 2],   # Level 1 — blue sky, clouds and faraway trees
	[6, 7, 6, 6, 7],   # Level 2 — green forest
	[],                # Level 3 — inside the dog house
]

var background_picture = preload("res://assets/sprites/pixel_backgrounds.png")


# The level calls this once, as soon as it has worked out how big
# it is. `ground_line` is how far down the grass starts.
func build(level_number, level_width, level_height, ground_line):
	scroll_scale = Vector2(HOW_SLOW, 1.0)

	var look = LEVEL_LOOKS[level_number]
	if look.is_empty():
		return

	# Sit the hills so their bottoms land right on the grass line.
	var hills_top = ground_line - PICTURE_SIZE

	var column = 0
	var x = 0
	while x < level_width:
		# Which of the columns from the list this one uses.
		var which = look[column % look.size()]

		# Plain sky all the way from the top down to the hills.
		var y = hills_top - PICTURE_SIZE
		while y > -PICTURE_SIZE:
			hang_up_a_picture(SKY_ROW, which, x, y)
			y -= PICTURE_SIZE

		# The hills themselves.
		hang_up_a_picture(HILLS_ROW, which, x, hills_top)

		# Solid colour underneath, down to the bottom of the level.
		y = ground_line
		while y < level_height:
			hang_up_a_picture(UNDER_ROW, which, x, y)
			y += PICTURE_SIZE

		x += PICTURE_SIZE
		column += 1


# Cuts one little picture out of the sheet and hangs it up.
# Same idea as draw_tile in cat_world.gd, just a different sheet.
func hang_up_a_picture(row, column, x, y):
	var sprite = Sprite2D.new()
	sprite.texture = background_picture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		column * PICTURE_SIZE,
		row * PICTURE_SIZE,
		PICTURE_SIZE, PICTURE_SIZE)
	sprite.position = Vector2(x, y)
	add_child(sprite)
