extends Node2D

# ============================================================
#   YOUR LEVELS
#
#   Every letter below is one square of the world.
#   Change the letters, press play, and your level changes.
#
#      .  sky (nothing)        C  a coin
#      G  grass ground         M  a mushroom baddie
#      D  dirt                 T  a tree
#      B  a wooden box         b  a bush
#      ?  a question box       S  where the cat starts
#      F  a checkpoint flag    W  the sandwich (finish!)
#      P  a cup of coffee (fire powers!)
#      H  a dog house          X  the dog boss        A  the axe
#
#   Rows have to stay in order, but they can be any length.
#   Try digging a pit, or building a tower of B's.
# ============================================================

const LEVEL_ONE = [
	"................................................................................................................",
	"................................................................................................................",
	"................................................................................................................",
	"................................................................................................................",
	"................................................................................................................",
	"...............................................................................CC...............................",
	".................................................CCCCC..........................................................",
	"...............................................G.BB?BB..........CCC............GG...............................",
	".................B?B..........................GD................GGG..B?B......GDDG..............................",
	"................CCC.........CCC....?.........GDD................DDD..........GDDDDG.....C.C.C.C.................",
	"............................................GDDD..........BB.BB.............GDDDDDDG.....................W......",
	"...S....b....T.P.....M.....GGGGGF.M........GDDDD..M....M............M....F.GDDDDDDDDG.P..M...M...T..b..GGGGGG.T.",
	"GGGGGGGGGGGGGGGGGGGGGGGG...GGGGGGGGGGGGG...GGGGGGGGGGGGGGG...GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"DDDDDDDDDDDDDDDDDDDDDDDD...DDDDDDDDDDDDD...DDDDDDDDDDDDDDD...DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
]

const LEVEL_TWO = [
	"..............................................................................................................",
	"..............................................................................................................",
	"..............................................................................................................",
	"..............................................................................................................",
	"..............................................................................................................",
	".............................................................CC.........................CCC...................",
	".............................................................BB.........................GGG...................",
	"......................................CCMC.........................................CCC..DDD...................",
	"......................B?B...........GGGGGGG...............BB.......................GGG........................",
	"..........CCC......................GDDDDDDDG......................B?B.........CCC..DDD........................",
	"................BB....CCC.........GDDDDDDDDDG...BB.....BB...............BB....GGG......................W......",
	"...S...b..P..M......F......M..M..GDDDDDDDDDDDG.......F......P....M..M.........DDD............M..M.T..GGGGGG.H.",
	"GGGGGGGGGGGGGGG....GGGGGGGGGGGGGGGGGGGGGGGGGGGG....GGGGGGGGGGGGGGGGGGGG....GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	"DDDDDDDDDDDDDDD....DDDDDDDDDDDDDDDDDDDDDDDDDDDD....DDDDDDDDDDDDDDDDDDDD....DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD",
]

# The last level: inside the dog house, with the dog and the axe.
const LEVEL_THREE = [
	"..............................................",
	"..............................................",
	"..............................................",
	"..............................................",
	"..............................................",
	"..............................................",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
	"B............................................B",
	"B...........CCC................CCC...........B",
	"B...........BBB......BBBB......BBB...........B",
	"B.........................................A..B",
	"B..S..P..B..............X.............B..BBB.B",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
]


# Every level in the game, in the order you play them.
# Copy a whole level, paste it on the end, and you have a level 3.
const ALL_LEVELS = [LEVEL_ONE, LEVEL_TWO, LEVEL_THREE]

# The colour behind each level. The last one is dark, because
# you're inside the dog house.
const LEVEL_SKIES = [
	Color(0.83, 0.91, 0.95),
	Color(0.74, 0.88, 0.94),
	Color(0.16, 0.12, 0.15),
]


# Which level we're on right now. 0 means the first one.
# It's "static" so that it remembers, even when the level restarts.
static var level_number := 0

# The level being played right now, copied out of ALL_LEVELS.
var level = []


# Every square in the picture file is 18 pixels across.
const TILE = 18

# The tile sheet is 20 pictures wide, so picture number 22 means
# "3rd along, 2nd row down". Open assets/sprites/pixel_tiles.png
# and count if you want to swap any of these for something else.
const WOODEN_BOX = 6
const QUESTION_BOX = 10
const TREE = 126
const BUSH = 124

# The dog house is far too big for one square, so it gets its own
# picture file instead of coming out of the tile sheet.
var doghouse_picture = preload("res://assets/sprites/doghouse.png")

# Ground is trickier. A block on its own wants a dark line all the
# way round it, but a block in the middle of a long floor does not.
# So we keep four pictures of each kind and pick the right one by
# looking at its neighbours.
#
# The order inside each list is always:
#      [ on its own,     left end,    middle,     right end ]
const GRASS_WITH_DIRT_BELOW = [20, 21, 22, 23]
const GRASS_ON_ITS_OWN = [0, 1, 2, 3]
const DIRT_WITH_MORE_BELOW = [120, 121, 122, 123]
const DIRT_AT_THE_BOTTOM = [140, 141, 142, 143]

# Letters that the cat cannot walk through.
const SOLID_LETTERS = ["G", "D", "B", "?"]

# Letters that count as ground when picking the pictures above.
# Boxes don't count — they already have their own line round them.
const GROUND_LETTERS = ["G", "D"]

# How long the "LEVEL DONE" sign stays up before the next level.
const CHEER_TIME = 2.5

var tiles_picture = preload("res://assets/sprites/pixel_tiles.png")
var coin_scene = preload("res://scenes/coin.tscn")
var mushroom_scene = preload("res://scenes/mushroom.tscn")
var checkpoint_scene = preload("res://scenes/checkpoint.tscn")
var sandwich_scene = preload("res://scenes/sandwich.tscn")
var coffee_scene = preload("res://scenes/coffee.tscn")
var dog_scene = preload("res://scenes/dog.tscn")
var axe_scene = preload("res://scenes/axe.tscn")


func _ready():
	level = ALL_LEVELS[level_number]
	RenderingServer.set_default_clear_color(LEVEL_SKIES[level_number])

	draw_all_the_tiles()
	build_the_invisible_walls()
	place_all_the_things()
	set_up_the_camera()

	# Keep the score board up to date.
	$Cat.coins_changed.connect(show_coins)
	$Cat.finished.connect(show_level_done)
	$Cat.shout.connect(show_a_message)
	show_coins(0)


# ---- Reading the level ----

# What letter is at this square?
func letter_at(x, y):
	if y < 0 or y >= level.size():
		return "."
	var row = level[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


# Can the cat stand on this square?
func is_solid(x, y):
	return letter_at(x, y) in SOLID_LETTERS


# Is this square made of grass or dirt?
func is_ground(x, y):
	return letter_at(x, y) in GROUND_LETTERS


# Turns a square number into a spot on the screen (its middle).
func middle_of(x, y):
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


# ---- Drawing ----

# Cuts one little picture out of the tile sheet and hangs it up.
func draw_tile(x, y, picture_number):
	var sprite = Sprite2D.new()
	sprite.texture = tiles_picture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		(picture_number % 20) * TILE,
		floori(picture_number / 20.0) * TILE,
		TILE, TILE)
	sprite.position = middle_of(x, y)
	$Tiles.add_child(sprite)


# Some things are too big to fit in one square, like the dog house.
# We hang the whole picture up so its feet rest on the bottom of
# the square it was written in.
func draw_big_picture(picture, x, y):
	var sprite = Sprite2D.new()
	sprite.texture = picture
	sprite.position = middle_of(x, y)
	sprite.position.y += TILE / 2.0 - picture.get_height() / 2.0
	$Tiles.add_child(sprite)


# Looks at the squares around this one and picks the ground picture
# that fits. This is what gives your level a neat dark edge instead
# of making it look like a pile of loose bricks.
func which_ground_picture(x, y):
	var buried = is_ground(x, y - 1)
	var more_below = is_ground(x, y + 1)

	# Grass only grows on top. Anything with a block on its head
	# is just dirt.
	var choices
	if letter_at(x, y) == "G" and not buried:
		choices = GRASS_WITH_DIRT_BELOW if more_below else GRASS_ON_ITS_OWN
	else:
		choices = DIRT_WITH_MORE_BELOW if more_below else DIRT_AT_THE_BOTTOM

	var neighbour_left = is_ground(x - 1, y)
	var neighbour_right = is_ground(x + 1, y)
	if neighbour_left and neighbour_right:
		return choices[2]
	if neighbour_right:
		return choices[1]
	if neighbour_left:
		return choices[3]
	return choices[0]


func draw_all_the_tiles():
	for y in level.size():
		for x in level[y].length():
			var letter = letter_at(x, y)
			if letter == "G" or letter == "D":
				draw_tile(x, y, which_ground_picture(x, y))
			elif letter == "B":
				draw_tile(x, y, WOODEN_BOX)
			elif letter == "?":
				draw_tile(x, y, QUESTION_BOX)
			elif letter == "T":
				draw_tile(x, y, TREE)
			elif letter == "b":
				draw_tile(x, y, BUSH)
			elif letter == "H":
				draw_big_picture(doghouse_picture, x, y)


# ---- Bumping into things ----

# The pictures above are only pictures — they can't stop anybody.
# So we lay invisible blocks over the solid ones.
#
# We glue each row of solid squares into ONE long block instead of
# lots of little ones. Otherwise the cat catches on the joins
# between them, like a shoe on a crack in the pavement.
func build_the_invisible_walls():
	var walls = StaticBody2D.new()
	add_child(walls)

	for y in level.size():
		var x = 0
		while x < level[y].length():
			if is_solid(x, y):
				var run_starts_at = x
				while is_solid(x + 1, y):
					x += 1
				add_wall(walls, run_starts_at, x, y)
			x += 1


func add_wall(walls, from_x, to_x, y):
	var how_many = to_x - from_x + 1
	var box = RectangleShape2D.new()
	box.size = Vector2(how_many * TILE, TILE)

	var shape = CollisionShape2D.new()
	shape.shape = box
	shape.position = Vector2(
		from_x * TILE + how_many * TILE / 2.0,
		y * TILE + TILE / 2.0)
	walls.add_child(shape)


# ---- Coins, baddies, flags, the sandwich, and the cat ----

func place_all_the_things():
	for y in level.size():
		for x in level[y].length():
			var letter = letter_at(x, y)
			if letter == "C":
				add_thing(coin_scene, x, y)
			elif letter == "M":
				add_thing(mushroom_scene, x, y)
			elif letter == "F":
				add_thing(checkpoint_scene, x, y)
			elif letter == "W":
				add_thing(sandwich_scene, x, y)
			elif letter == "P":
				add_thing(coffee_scene, x, y)
			elif letter == "X":
				add_thing(dog_scene, x, y)
			elif letter == "A":
				add_thing(axe_scene, x, y)
			elif letter == "S":
				$Cat.position = middle_of(x, y)
				$Cat.start_position = $Cat.position


func add_thing(scene, x, y):
	var thing = scene.instantiate()
	thing.position = middle_of(x, y)
	$Things.add_child(thing)


# ---- The camera ----

# Stops the camera from drifting off past the edges of the level,
# and tells the cat how far it can fall before it's out of bounds.
func set_up_the_camera():
	var widest = 0
	for row in level:
		widest = maxi(widest, row.length())

	var camera = $Cat/Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = widest * TILE
	camera.limit_bottom = level.size() * TILE

	$Cat.bottom_of_the_world = level.size() * TILE + 40


# ---- The score board ----

# Puts a message on the screen for a few seconds, then clears it.
func show_a_message(words):
	$HUD/MessageLabel.text = words
	await get_tree().create_timer(3.0).timeout
	if $HUD/MessageLabel.text == words:
		$HUD/MessageLabel.text = ""


func show_coins(total):
	$HUD/CoinLabel.text = "Level %d       Coins: %d" % [level_number + 1, total]


# The cat shouts when it eats the sandwich.
func show_level_done():
	var last_level = ALL_LEVELS.size() - 1

	if level_number >= last_level:
		$HUD/MessageLabel.text = "YOU BEAT THE DOGGIE!"
		return

	$HUD/MessageLabel.text = "LEVEL %d DONE!" % (level_number + 1)

	# Let the cheering sound finish, then start the next level.
	await get_tree().create_timer(CHEER_TIME).timeout
	level_number += 1
	get_tree().reload_current_scene()
