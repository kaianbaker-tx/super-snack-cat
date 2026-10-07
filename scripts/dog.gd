extends CharacterBody2D

# ============================================================
#   THE DOG BOSSES — one in the castle at the end of each area.
#
#      World 2-4   the Poodle            (bouncy!)
#      World 4-4   the Golden Retriever  (fast!)
#      World 6-4   the Husky             (dashes at you!)
#      World 8-4   the big Doggie himself
#
#   They stomp back and forth and hop about. You CANNOT jump on
#   their heads, they're far too big — touching one hurts, every
#   time. Fireballs just bounce off.
#
#   The only thing that beats a boss is the AXE at the end of
#   its castle. Grab it, then tap space twice to throw it. Every
#   hit makes them angrier — and faster.
#
#   The level says which boss is in it, with "boss": "poodle".
# ============================================================

# Every boss, and how it behaves:
#   name       what the score board calls it
#   speed      how fast it walks
#   hop        how high it hops (NEGATIVE, up is negative)
#   hop_every  how many seconds between hops
#   hits       how many axes it takes
#   dash       true = every so often it charges at double speed
const BOSSES = {
	"poodle": {"name": "THE POODLE", "speed": 36.0, "hop": -380.0,
		"hop_every": 1.1, "hits": 2, "dash": false},
	"golden": {"name": "THE GOLDEN RETRIEVER", "speed": 68.0, "hop": -280.0,
		"hop_every": 3.0, "hits": 3, "dash": false},
	"husky": {"name": "THE HUSKY", "speed": 50.0, "hop": -330.0,
		"hop_every": 2.0, "hits": 4, "dash": true},
	"dog": {"name": "THE DOGGIE", "speed": 44.0, "hop": -320.0,
		"hop_every": 2.2, "hits": 5, "dash": false},
}

const GRAVITY = 900.0

# Every axe that hits makes the boss this much faster. 1.0 = never.
const ANGRIER = 1.15

# The husky's dash: how often, how long, and how much faster.
const DASH_EVERY = 3.5
const DASH_TIME = 0.8
const DASH_SPEED_UP = 2.2

# Which boss this is. The level fills it in before it wakes up.
var kind := "dog"

# -1 means walking left, 1 means right.
var direction := -1

var beaten := false
var hop_timer := 0.0
var walk_timer := 0.0
var dash_timer := 0.0
var speed := 44.0
var hits_left := 1

var picture_walk1 = null
var picture_walk2 = null
var picture_beaten = null


func _ready():
	if not BOSSES.has(kind):
		kind = "dog"
	speed = BOSSES[kind]["speed"]
	hits_left = BOSSES[kind]["hits"]

	picture_walk1 = load("res://assets/sprites/%s_walk1.png" % kind)
	picture_walk2 = load("res://assets/sprites/%s_walk2.png" % kind)
	picture_beaten = load("res://assets/sprites/%s_beaten.png" % kind)
	$Sprite.texture = load("res://assets/sprites/%s_idle.png" % kind)

	$Hitbox.body_entered.connect(_someone_touched_me)
	tell_the_score_board()


func boss_name():
	return BOSSES[kind]["name"]


# Puts the boss's name and hearts up on the score board.
func tell_the_score_board():
	var world = get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("show_boss_hearts"):
		world.show_boss_hearts(boss_name(), hits_left, BOSSES[kind]["hits"])


func _physics_process(delta):
	velocity.y += GRAVITY * delta

	# Beaten? Just flop to the floor and stay there.
	if beaten:
		velocity.x = 0.0
		move_and_slide()
		return

	# The husky charges every few seconds.
	var how_fast = speed
	if BOSSES[kind]["dash"]:
		dash_timer += delta
		if dash_timer > DASH_EVERY:
			how_fast = speed * DASH_SPEED_UP
			if dash_timer > DASH_EVERY + DASH_TIME:
				dash_timer = 0.0
	velocity.x = direction * how_fast

	# Angry hop, but only when on the ground.
	hop_timer += delta
	if hop_timer > BOSSES[kind]["hop_every"] and is_on_floor():
		hop_timer = 0.0
		velocity.y = BOSSES[kind]["hop"]
		$BarkSound.play()

	move_and_slide()

	# Feel for the floor just ahead, same as the mushrooms do.
	$GroundCheck.position.x = 12 * direction
	$GroundCheck.force_raycast_update()
	if is_on_wall() or not $GroundCheck.is_colliding():
		direction = -direction

	# Stomping animation.
	walk_timer += delta * 6.0
	$Sprite.texture = picture_walk1 if int(walk_timer) % 2 == 0 else picture_walk2
	$Sprite.flip_h = direction > 0


func _someone_touched_me(who):
	if beaten:
		return
	# No stomping this one. Touching it hurts, whichever way you came.
	if who.has_method("ouch"):
		who.ouch()


# A plain fireball. Bounces right off — it doesn't even notice.
func hit_by_fireball():
	if beaten:
		return
	$ClangSound.play()
	# Flash white for a moment so you can see it did nothing.
	$Sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		$Sprite.modulate = Color(1, 1, 1)


# The axe! This is the one that gets them.
func hit_by_axe():
	if beaten:
		return

	hits_left -= 1
	tell_the_score_board()

	# Not beaten yet: yelp, flash red, and get ANGRIER (faster).
	if hits_left > 0:
		$BarkSound.play()
		speed *= ANGRIER
		$Sprite.modulate = Color(1.0, 0.35, 0.35)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self) and not beaten:
			$Sprite.modulate = Color(1, 1, 1)
		return

	beaten = true
	velocity = Vector2.ZERO
	$Sprite.texture = picture_beaten
	$Sprite.modulate = Color(1, 1, 1)
	$Hitbox.set_deferred("monitoring", false)
	$BeatenSound.play()

	# Tell the cat it has won the level.
	var cat = get_tree().get_first_node_in_group("cat")
	if cat != null and cat.has_method("finish_level"):
		cat.finish_level()
