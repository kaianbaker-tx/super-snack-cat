extends Node2D

# ============================================================
#   THE CAT WORLD
#
#   This file takes the level you're on and builds it out of
#   Kenney's little pictures.
#
#   The levels themselves are in scripts/levels.gd. Open that
#   one to change a level, or to add a brand new one.
#
#   Every level has a LOOK — grass, sand, snow, a dark cave...
#   All the looks are listed below in LOOKS. A look says which
#   ground pictures, background, music and trees a level gets.
# ============================================================

const Levels = preload("res://scripts/levels.gd")

# Every level in the game, in the order you play them.
const ALL_LEVELS = Levels.ALL_LEVELS

# Which level we're on right now. 0 means the first one.
# It's "static" so that it remembers, even when the level restarts.
static var level_number := 0

# The game writes down which level you got to, so if you close it
# and come back tomorrow, you carry on from the same level.
const PROGRESS_FILE = "user://progress.cfg"
static var progress_loaded := false

# The level being played right now, copied out of ALL_LEVELS.
var level = []

# The look of the level being played right now, out of LOOKS.
var look = {}

# Every square of water that's at the surface, so we can make them
# ripple together.
var rippling_water = []
var ripple_clock = 0.0


# Every square in the picture file is 18 pixels across.
const TILE = 18

# The tile sheet is 20 pictures wide, so picture number 22 means
# "3rd along, 2nd row down". Open assets/sprites/pixel_tiles.png
# and count if you want to swap any of these for something else.
const WOODEN_BOX = 6
const LADDER = 71
const ARROW_SIGN = 85
const FENCE = 105

# Water needs three pictures: two different wavy tops that we flip
# between so the surface ripples, and a plain one for underneath.
const WATER_SURFACE = 33
const WATER_SURFACE_2 = 53
const DEEP_WATER = 73

# How many times a second the surface flips between its two pictures.
const RIPPLE_SPEED = 2.5

# A pipe, like the green ones in Mario — only Kenney's are blue.
const PIPE_TOP = 95
const PIPE_MIDDLE = 115
const PIPE_BOTTOM = 135

# The stalk that holds up a mushroom top. The bottom one has roots.
const STALK = 52
const STALK_WITH_ROOTS = 72

# The two hearts on the score board — a full one and an empty one.
const FULL_HEART = 44
const EMPTY_HEART = 46

# The key picture, for showing how many keys you're carrying.
const KEY_PICTURE = 27

# How big the score board pictures are, next to the words.
const SCOREBOARD_PICTURE_SIZE = 36

# ---- Ground, ledges and mushroom tops ----
#
# A block on its own wants a dark line all the way round it, but a
# block in the middle of a long floor does not. So we keep four
# pictures of each kind and pick the right one by looking at its
# neighbours.
#
# The order inside each list is always:
#      [ on its own,     left end,    middle,     right end ]
#
# Ground has two lists: one for the top of a thin strip (a dark line
# underneath), and one for the top of a thick bit (more dirt below).
const GRASS = {
	"thin": [0, 1, 2, 3],
	"thick": [20, 21, 22, 23],
}
const SAND = {
	"thin": [40, 41, 42, 43],
	"thick": [60, 61, 62, 63],
}
const SNOW = {
	"thin": [80, 81, 82, 83],
	"thick": [100, 101, 102, 103],
}
const BARE_DIRT = {
	"thin": [140, 141, 142, 143],
	"thick": [120, 121, 122, 123],
}

# Underneath the top, the ground is always dirt.
const DIRT_WITH_MORE_BELOW = [120, 121, 122, 123]
const DIRT_AT_THE_BOTTOM = [140, 141, 142, 143]

# Ledges you can jump UP through and land on top of.
const WOODEN_PLANK = [146, 146, 146, 146]
const SNOWY_LEDGE = [156, 153, 154, 155]

# Mushroom tops. You can jump up through these too. The middle one
# that sits on a stalk has its own picture.
const MUSHROOM_TOP = [12, 14, 13, 15]
const MUSHROOM_TOP_ON_A_STALK = 12

# ---- The looks ----
#
# Every level in levels.gd says which one of these it uses.
#
#   title    the words that pop up when the level starts
#   ground   which ground pictures, from the lists just above
#   hills    the faraway background (see background.gd) — an
#            empty list [] means no sky at all, for going indoors
#   sky      the colour behind everything, if there's no background
#   music    which of Kenney's retro loops plays
#   tree     the picture for a T — a tree, a cactus, a snowman...
#   bush     the picture for a b
#   ledge    the picture for an _ ledge
#
# And two extra ones you can add to any look:
#
#   slippery   true makes the ground icy — the cat slides about
#   dark       a colour to tint the whole level, for night time
#
# The music choices are:
#      "retro_mystic"  slow and dreamy, 48 seconds  (the chill one)
#      "retro_beat"    a steady drum groove, 15 seconds
#      "retro_reggae"  bouncy, 8 seconds
#      "retro_polka"   silly, 8 seconds
#      "retro_comedy"  very silly, 6 seconds
const LOOKS = {
	"grass": {
		"title": "GRASSY HILLS",
		"ground": GRASS,
		"hills": [0, 1, 0, 3, 2],
		"sky": Color(0.83, 0.91, 0.95),
		"music": "retro_mystic",
		"tree": 126, "bush": 124, "ledge": WOODEN_PLANK,
	},
	"cave": {
		"title": "UNDERGROUND",
		"ground": BARE_DIRT,
		"hills": [],
		"sky": Color(0.13, 0.11, 0.17),
		"music": "retro_beat",
		"tree": 129, "bush": 144, "ledge": WOODEN_PLANK,
	},
	"treetops": {
		"title": "MUSHROOM TOPS",
		"ground": GRASS,
		"hills": [1, 2, 1, 0, 2],
		"sky": Color(0.83, 0.91, 0.95),
		"music": "retro_reggae",
		"tree": 126, "bush": 124, "ledge": WOODEN_PLANK,
	},
	"desert": {
		"title": "SANDY DESERT",
		"ground": SAND,
		"hills": [4, 5, 4, 4, 5],
		"sky": Color(0.99, 0.80, 0.52),
		"music": "retro_polka",
		"tree": 127, "bush": 125, "ledge": WOODEN_PLANK,
	},
	"pyramid": {
		"title": "INSIDE THE PYRAMID",
		"ground": SAND,
		"hills": [],
		"sky": Color(0.24, 0.15, 0.11),
		"music": "retro_beat",
		"tree": 127, "bush": 144, "ledge": WOODEN_PLANK,
	},
	"desertnight": {
		"title": "DESERT NIGHT",
		"ground": SAND,
		"hills": [4, 5, 4, 4, 5],
		"sky": Color(0.99, 0.80, 0.52),
		"music": "retro_mystic",
		"tree": 127, "bush": 144, "ledge": WOODEN_PLANK,
		"dark": Color(0.58, 0.52, 0.86),
	},
	"snow": {
		"title": "SNOWY MOUNTAINS",
		"ground": SNOW,
		"hills": [3, 0, 3, 2, 3],
		"sky": Color(0.86, 0.94, 0.97),
		"music": "retro_mystic",
		"tree": 126, "bush": 145, "ledge": SNOWY_LEDGE,
		"slippery": true,
	},
	"icecave": {
		"title": "ICE CAVE",
		"ground": SNOW,
		"hills": [],
		"sky": Color(0.10, 0.15, 0.24),
		"music": "retro_beat",
		"tree": 126, "bush": 145, "ledge": SNOWY_LEDGE,
		"slippery": true,
	},
	"sky": {
		"title": "CLOUD LAND",
		"ground": SNOW,
		"hills": [1, 2, 1, 2, 0],
		"sky": Color(0.83, 0.91, 0.95),
		"music": "retro_reggae",
		"tree": 126, "bush": 145, "ledge": SNOWY_LEDGE,
	},
	"forest": {
		"title": "DEEP FOREST",
		"ground": GRASS,
		"hills": [6, 7, 6, 6, 7],
		"sky": Color(0.74, 0.88, 0.94),
		"music": "retro_mystic",
		"tree": 125, "bush": 124, "ledge": WOODEN_PLANK,
	},
	"lake": {
		"title": "LAKESIDE",
		"ground": GRASS,
		"hills": [1, 2, 1, 0, 2],
		"sky": Color(0.83, 0.91, 0.95),
		"music": "retro_reggae",
		"tree": 126, "bush": 125, "ledge": WOODEN_PLANK,
	},
	"night": {
		"title": "THE DOG'S BACKYARD",
		"ground": GRASS,
		"hills": [0, 3, 0, 1, 3],
		"sky": Color(0.83, 0.91, 0.95),
		"music": "retro_beat",
		"tree": 126, "bush": 124, "ledge": WOODEN_PLANK,
		"dark": Color(0.52, 0.56, 0.86),
	},
	"house": {
		"title": "THE DOG HOUSE",
		"ground": BARE_DIRT,
		"hills": [],
		"sky": Color(0.16, 0.12, 0.15),
		"music": "retro_beat",
		"tree": 129, "bush": 144, "ledge": WOODEN_PLANK,
	},

	# The three castles at the end of the first three areas.
	"pinkcastle": {
		"title": "THE POODLE'S CASTLE",
		"ground": BARE_DIRT,
		"hills": [],
		"sky": Color(0.20, 0.11, 0.20),
		"music": "retro_beat",
		"tree": 129, "bush": 144, "ledge": WOODEN_PLANK,
		"dark": Color(1.0, 0.78, 0.92),
	},
	"goldcastle": {
		"title": "THE GOLDEN RETRIEVER'S CASTLE",
		"ground": SAND,
		"hills": [],
		"sky": Color(0.20, 0.14, 0.08),
		"music": "retro_beat",
		"tree": 127, "bush": 144, "ledge": WOODEN_PLANK,
		"dark": Color(1.0, 0.9, 0.62),
	},
	"icecastle": {
		"title": "THE HUSKY'S ICE CASTLE",
		"ground": SNOW,
		"hills": [],
		"sky": Color(0.08, 0.12, 0.22),
		"music": "retro_beat",
		"tree": 126, "bush": 145, "ledge": SNOWY_LEDGE,
		"dark": Color(0.72, 0.86, 1.0),
		"slippery": true,
	},
}

# ---- The power-up blocks ----
#
# Every one is the same block picture painted a different colour —
# except the LUCKY block, which is Kenney's real gold block, and
# gives you a surprise.
# Want a purple one that gives you a key? Add a line here, pick a
# spare letter, and add it to place_all_the_things below.
#
#            letter : [ what comes out,  what colour to paint it ]
const BLOCK_COLOURS = {
	"!": ["lucky",   Color(1.00, 1.00, 1.00)],   # the real gold one
	"?": ["nugget",  Color(1.00, 0.56, 0.16)],   # nugget orange
	"R": ["heart",   Color(1.00, 0.36, 0.36)],   # red
	"N": ["chip",    Color(0.36, 0.90, 0.42)],   # green
	"U": ["diamond", Color(0.40, 0.66, 1.00)],   # blue
	"Y": ["coffee",  Color(0.82, 0.58, 0.32)],   # coffee brown
}

# ---- The music ----

# How loud the background music is. 0 is full blast, -15 is normal
# background music, -24 is so quiet you almost don't notice it.
const MUSIC_LOUDNESS = -14.0

# The dog house is far too big for one square, so it gets its own
# picture file instead of coming out of the tile sheet.
var doghouse_picture = preload("res://assets/sprites/doghouse.png")

# Letters that the cat cannot walk through.
# The power-up blocks are NOT in here: each one is its own little
# scene that brings its own collision along with it.
const SOLID_LETTERS = ["G", "D", "B", "p"]

# Letters you can jump up through from underneath, and then stand on.
const LEDGE_LETTERS = ["_", "m"]

# Letters that count as ground when picking the pictures above.
# Boxes don't count — they already have their own line round them.
const GROUND_LETTERS = ["G", "D"]

# How long the "DONE!" sign stays up before the next level.
const CHEER_TIME = 2.5

var tiles_picture = preload("res://assets/sprites/pixel_tiles.png")
var coin_scene = preload("res://scenes/coin.tscn")
var mushroom_scene = preload("res://scenes/mushroom.tscn")
var checkpoint_scene = preload("res://scenes/checkpoint.tscn")
var sandwich_scene = preload("res://scenes/sandwich.tscn")
var dog_scene = preload("res://scenes/dog.tscn")
var axe_scene = preload("res://scenes/axe.tscn")
var spikes_scene = preload("res://scenes/spikes.tscn")
var key_scene = preload("res://scenes/key.tscn")
var locked_door_scene = preload("res://scenes/locked_door.tscn")
var bat_scene = preload("res://scenes/bat.tscn")
var spiky_ball_scene = preload("res://scenes/spiky_ball.tscn")
var powerup_block_scene = preload("res://scenes/powerup_block.tscn")

# The two little scripts that make a square of water wet and a
# square of ladder climbable.
var water_script = preload("res://scripts/water.gd")
var ladder_script = preload("res://scripts/ladder.gd")


func _ready():
	# Joining a group is how a boss finds the score board.
	add_to_group("world")

	find_out_which_level_we_are_on()
	level = ALL_LEVELS[level_number]["rows"]
	look = LOOKS[ALL_LEVELS[level_number]["look"]]
	RenderingServer.set_default_clear_color(look["sky"])

	start_the_music()
	build_the_background()
	draw_all_the_tiles()
	build_the_invisible_walls()
	build_the_ledges()
	build_the_wet_and_climbable_bits()
	place_all_the_things()
	set_up_the_camera()
	turn_down_the_lights()

	# Snow and ice are slippery.
	$Cat.slippery = look.get("slippery", false)

	# Keep the score board up to date.
	build_the_hearts()
	$Cat.coins_changed.connect(show_coins)
	$Cat.hearts_changed.connect(show_hearts)
	$Cat.keys_changed.connect(show_keys)
	$Cat.finished.connect(show_level_done)
	$Cat.shout.connect(show_a_message)
	show_coins(0)
	show_hearts($Cat.hearts)
	show_keys(0)

	# Say which level this is, the way Mario does. A level with its
	# own "title" uses that; otherwise the look's title. The first
	# level of each area says which area too.
	var this_level = ALL_LEVELS[level_number]
	var words = "WORLD %s\n%s" % [level_name(), this_level.get("title", look["title"])]
	if this_level.has("area"):
		words = this_level["area"] + "\n" + words
	show_a_message(words)


# ---- Remembering where you got to ----

func find_out_which_level_we_are_on():
	# Only look in the file once, when the game first starts.
	# After that, level_number already knows.
	if not progress_loaded:
		progress_loaded = true
		var progress = ConfigFile.new()
		if progress.load(PROGRESS_FILE) == OK:
			level_number = progress.get_value("progress", "level", 0)

		# For testing: start the game with  -- --level=2-3
		# to jump straight to that level.
		for word in OS.get_cmdline_user_args():
			if word.begins_with("--level="):
				var wanted = word.trim_prefix("--level=")
				for i in ALL_LEVELS.size():
					if ALL_LEVELS[i]["name"] == wanted:
						level_number = i

	level_number = clampi(level_number, 0, ALL_LEVELS.size() - 1)
	remember_which_level(level_number)


func remember_which_level(number):
	var progress = ConfigFile.new()
	progress.set_value("progress", "level", number)
	progress.save(PROGRESS_FILE)


# The name of the level, like "2-3" (world 2, level 3).
func level_name():
	return ALL_LEVELS[level_number]["name"]


# The options box calls this when you press N. Back to the very
# beginning.
func start_again_from_world_one():
	level_number = 0
	remember_which_level(0)
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---- The music ----

# Quiet background music that loops round and round forever.
func start_the_music():
	var tune = load("res://assets/audio/%s.ogg" % look["music"])
	tune.loop = true
	$Music.stream = tune
	$Music.volume_db = MUSIC_LOUDNESS
	$Music.play()


# When the level is put away — you pressed R, or finished it, or quit
# the game — stop the music instead of leaving it playing into nothing.
func _exit_tree():
	$Music.stop()


# ---- Night time ----

# A look with "dark" in it tints the whole world that colour, so it
# looks like night. The score board isn't tinted, so you can still
# read it.
func turn_down_the_lights():
	if not look.has("dark"):
		return
	var night = CanvasModulate.new()
	night.color = look["dark"]
	add_child(night)


# ---- The window ----

# Press F to fill the whole screen, and F again to come back.
# The game always draws the same amount of level either way — going
# full screen just makes everything bigger.
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var full_screen_now = \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	# F swaps between full screen and a window.
	if event.keycode == KEY_F:
		if full_screen_now:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Escape always gets you back to a window, so full screen can
	# never trap you.
	elif event.keycode == KEY_ESCAPE and full_screen_now:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ---- Making the water move ----

# Flips every surface square between its two pictures, over and over,
# so the water looks like it's lapping instead of frozen solid.
func _process(delta):
	if rippling_water.is_empty():
		return

	ripple_clock += delta * RIPPLE_SPEED
	var which = WATER_SURFACE if int(ripple_clock) % 2 == 0 else WATER_SURFACE_2
	var picture = Rect2(
		(which % 20) * TILE, floori(which / 20.0) * TILE, TILE, TILE)

	for square in rippling_water:
		square.region_rect = picture


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


# Is this square a ledge you can jump up through?
func is_ledge(x, y):
	return letter_at(x, y) in LEDGE_LETTERS


# Is this square made of grass or dirt?
func is_ground(x, y):
	return letter_at(x, y) in GROUND_LETTERS


# Turns a square number into a spot on the screen (its middle).
func middle_of(x, y):
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


# ---- Drawing ----

# Tells the background how big this level is, so it can build the
# right number of hills. The grass in every level sits on the
# second row from the bottom, which is where the hills should meet
# the ground.
func build_the_background():
	var widest = 0
	for row in level:
		widest = maxi(widest, row.length())

	$Background.build(
		look["hills"],
		widest * TILE,
		level.size() * TILE,
		(level.size() - 2) * TILE)


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


# Picks from a list of four pictures —
#      [ on its own,     left end,    middle,     right end ]
# — by looking at whether the squares either side are the same kind.
func pick_an_end(choices, same_on_the_left, same_on_the_right):
	if same_on_the_left and same_on_the_right:
		return choices[2]
	if same_on_the_right:
		return choices[1]
	if same_on_the_left:
		return choices[3]
	return choices[0]


# Looks at the squares around this one and picks the ground picture
# that fits. This is what gives your level a neat dark edge instead
# of making it look like a pile of loose bricks.
func which_ground_picture(x, y):
	var buried = is_ground(x, y - 1)
	var more_below = is_ground(x, y + 1)

	# Grass (or sand, or snow) only grows on top. Anything with a
	# block on its head is just dirt.
	var choices
	if letter_at(x, y) == "G" and not buried:
		choices = look["ground"]["thick"] if more_below else look["ground"]["thin"]
	else:
		choices = DIRT_WITH_MORE_BELOW if more_below else DIRT_AT_THE_BOTTOM

	return pick_an_end(choices, is_ground(x - 1, y), is_ground(x + 1, y))


func draw_all_the_tiles():
	for y in level.size():
		for x in level[y].length():
			var letter = letter_at(x, y)
			if letter == "G" or letter == "D":
				draw_tile(x, y, which_ground_picture(x, y))
			elif letter == "B":
				draw_tile(x, y, WOODEN_BOX)
			elif letter == "T":
				draw_tile(x, y, look["tree"])
			elif letter == "b":
				draw_tile(x, y, look["bush"])
			elif letter == "=":
				draw_tile(x, y, LADDER)
			elif letter == ">":
				draw_tile(x, y, ARROW_SIGN)
			elif letter == "f":
				draw_tile(x, y, FENCE)
			elif letter == "p":
				draw_pipe(x, y)
			elif letter == "_":
				draw_tile(x, y, pick_an_end(look["ledge"],
					letter_at(x - 1, y) == "_", letter_at(x + 1, y) == "_"))
			elif letter == "m":
				draw_mushroom_top(x, y)
			elif letter == "|":
				draw_tile(x, y, STALK_WITH_ROOTS if is_solid(x, y + 1) else STALK)
			elif letter == "~":
				draw_water(x, y)
			elif letter == "H":
				draw_big_picture(doghouse_picture, x, y)


# A pipe is a stack of p's. The top one gets the wide rim.
func draw_pipe(x, y):
	if letter_at(x, y - 1) != "p":
		draw_tile(x, y, PIPE_TOP)
	elif letter_at(x, y + 1) != "p":
		draw_tile(x, y, PIPE_BOTTOM)
	else:
		draw_tile(x, y, PIPE_MIDDLE)


# A mushroom top is a row of m's. Put a | under one and it grows a
# stalk down to the ground.
func draw_mushroom_top(x, y):
	var picture = pick_an_end(MUSHROOM_TOP,
		letter_at(x - 1, y) == "m", letter_at(x + 1, y) == "m")
	if letter_at(x, y + 1) == "|" and picture == MUSHROOM_TOP[2]:
		picture = MUSHROOM_TOP_ON_A_STALK
	draw_tile(x, y, picture)


# Water goes on TOP of the cat, not behind it, so that swimming
# looks like being underwater instead of standing in front of a
# blue wall. Only the very top square gets the wavy picture.
func draw_water(x, y):
	var picture_number = DEEP_WATER
	if letter_at(x, y - 1) != "~":
		picture_number = WATER_SURFACE

	var sprite = Sprite2D.new()
	sprite.texture = tiles_picture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		(picture_number % 20) * TILE,
		floori(picture_number / 20.0) * TILE,
		TILE, TILE)
	sprite.position = middle_of(x, y)
	$Water.add_child(sprite)

	# Remember the top squares, so we can ripple them.
	if picture_number == WATER_SURFACE:
		rippling_water.append(sprite)


# Water and ladders don't stop you moving, so they don't get an
# invisible wall. Instead each square gets an invisible SENSOR that
# tells the cat "you're swimming now" or "you can climb here".
func build_the_wet_and_climbable_bits():
	for y in level.size():
		for x in level[y].length():
			var letter = letter_at(x, y)
			if letter == "~":
				add_sensor(water_script, x, y, TILE, TILE)
			elif letter == "=":
				# A bit narrower than the square, so you have to be
				# properly on the ladder to climb it.
				add_sensor(ladder_script, x, y, 10, TILE)


func add_sensor(which_script, x, y, wide, tall):
	var sensor = Area2D.new()
	sensor.set_script(which_script)
	sensor.collision_layer = 0
	sensor.collision_mask = 4          # 4 is the cat's layer
	sensor.position = middle_of(x, y)

	var box = RectangleShape2D.new()
	box.size = Vector2(wide, tall)
	var shape = CollisionShape2D.new()
	shape.shape = box
	sensor.add_child(shape)

	$Things.add_child(sensor)


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

	# And a tall wall just past each end of the level, so you can't
	# walk off the edge of the world by going the wrong way.
	var widest = 0
	for row in level:
		widest = maxi(widest, row.length())
	for x in [-1, widest]:
		var box = RectangleShape2D.new()
		box.size = Vector2(TILE, level.size() * TILE * 3)
		var shape = CollisionShape2D.new()
		shape.shape = box
		shape.position = Vector2(x * TILE + TILE / 2.0, 0)
		walls.add_child(shape)


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


# Ledges and mushroom tops only work one way: you can jump up
# through them from underneath, but land on them from above.
# Godot has a switch for exactly that — one_way_collision.
const LEDGE_THICKNESS = 6

func build_the_ledges():
	var ledges = StaticBody2D.new()
	add_child(ledges)

	for y in level.size():
		var x = 0
		while x < level[y].length():
			if is_ledge(x, y):
				var run_starts_at = x
				while is_ledge(x + 1, y):
					x += 1
				var how_many = x - run_starts_at + 1
				var box = RectangleShape2D.new()
				box.size = Vector2(how_many * TILE, LEDGE_THICKNESS)
				var shape = CollisionShape2D.new()
				shape.shape = box
				shape.one_way_collision = true
				shape.position = Vector2(
					run_starts_at * TILE + how_many * TILE / 2.0,
					y * TILE + LEDGE_THICKNESS / 2.0)
				ledges.add_child(shape)
			x += 1


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
			elif letter == "X":
				add_the_boss(x, y)
			elif letter == "A":
				add_thing(axe_scene, x, y)
			elif letter == "^":
				add_thing(spikes_scene, x, y)
			elif letter == "k":
				add_thing(key_scene, x, y)
			elif letter == "L":
				add_thing(locked_door_scene, x, y)
			elif letter == "E":
				add_thing(bat_scene, x, y)
			elif letter == "O":
				add_thing(spiky_ball_scene, x, y)
			elif letter in BLOCK_COLOURS:
				add_a_power_up_block(letter, x, y)
			elif letter == "S":
				$Cat.position = middle_of(x, y)
				$Cat.start_position = $Cat.position


# Builds one power-up block, and tells it what it's holding and
# what colour to be before it wakes up.
func add_a_power_up_block(letter, x, y):
	var recipe = BLOCK_COLOURS[letter]
	var block = powerup_block_scene.instantiate()
	block.gives = recipe[0]
	block.colour = recipe[1]
	block.position = middle_of(x, y)
	$Things.add_child(block)


# A boss. The level says which one with "boss": "poodle" — no boss
# named means the big Doggie himself.
func add_the_boss(x, y):
	var boss = dog_scene.instantiate()
	boss.kind = ALL_LEVELS[level_number].get("boss", "dog")
	boss.position = middle_of(x, y)
	$Things.add_child(boss)


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
	$HUD/CoinLabel.text = "World %s       Coins: %d" % [level_name(), total]


# ---- Hearts and keys ----

# Cuts one picture out of the tile sheet, ready to hang on the
# score board. Same idea as draw_tile, but for the HUD, which wants
# a picture rather than a sprite.
func scoreboard_picture(picture_number):
	var picture = AtlasTexture.new()
	picture.atlas = tiles_picture
	picture.region = Rect2(
		(picture_number % 20) * TILE,
		floori(picture_number / 20.0) * TILE,
		TILE, TILE)
	return picture


# Lay out one heart shape for every heart the cat can have. They
# get filled in or emptied later — we never add or remove them, so
# the row never jumps about.
func build_the_hearts():
	for i in $Cat.MOST_HEARTS:
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(
			SCOREBOARD_PICTURE_SIZE, SCOREBOARD_PICTURE_SIZE)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		$HUD/Hearts.add_child(heart)


func show_hearts(left):
	var i = 0
	for heart in $HUD/Hearts.get_children():
		heart.texture = scoreboard_picture(FULL_HEART if i < left else EMPTY_HEART)
		i += 1


# Keys come and go, so unlike hearts we build this row fresh each
# time. No keys means an empty row, which is exactly what we want.
func show_keys(total):
	for old_key in $HUD/Keys.get_children():
		old_key.queue_free()

	for i in total:
		var key = TextureRect.new()
		key.custom_minimum_size = Vector2(
			SCOREBOARD_PICTURE_SIZE, SCOREBOARD_PICTURE_SIZE)
		key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		key.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		key.texture = scoreboard_picture(KEY_PICTURE)
		$HUD/Keys.add_child(key)


# ---- The boss's hearts ----

# A boss calls this when it wakes up and every time an axe hits it.
# Its name and hearts go up in the top right corner.
var boss_name := ""

func show_boss_hearts(who, left, most):
	boss_name = who
	if not $HUD.has_node("Boss"):
		var corner = VBoxContainer.new()
		corner.name = "Boss"
		corner.anchor_left = 1.0
		corner.anchor_right = 1.0
		corner.offset_left = -420.0
		corner.offset_right = -18.0
		corner.offset_top = 12.0
		corner.alignment = BoxContainer.ALIGNMENT_BEGIN
		var label = Label.new()
		label.name = "Name"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0.24, 0.24, 0.34))
		label.add_theme_constant_override("outline_size", 8)
		corner.add_child(label)
		var row = HBoxContainer.new()
		row.name = "Hearts"
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 4)
		corner.add_child(row)
		$HUD.add_child(corner)

	$HUD/Boss/Name.text = who
	var row = $HUD/Boss/Hearts
	for old in row.get_children():
		old.queue_free()
	for i in most:
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(
			SCOREBOARD_PICTURE_SIZE, SCOREBOARD_PICTURE_SIZE)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.texture = scoreboard_picture(FULL_HEART if i < left else EMPTY_HEART)
		row.add_child(heart)


# The cat shouts when it eats the sandwich (or beats a boss).
func show_level_done():
	var last_level = ALL_LEVELS.size() - 1

	if level_number >= last_level:
		# The whole game is done! Next time, start again from 1-1.
		level_number = 0
		remember_which_level(0)
		$HUD/MessageLabel.text = "YOU BEAT THE DOGGIE!\nPRESS R TO PLAY AGAIN"
		return

	if boss_name != "":
		$HUD/MessageLabel.text = "YOU BEAT %s!" % boss_name
	else:
		$HUD/MessageLabel.text = "WORLD %s DONE!" % level_name()

	# Let the cheering sound finish, then start the next level.
	await get_tree().create_timer(CHEER_TIME).timeout
	level_number += 1
	get_tree().reload_current_scene()
