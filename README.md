# Super Snack Cat

A jump-and-run game, as long as the first Super Mario: **8 worlds, 4
levels each — 32 levels**. You play a cat. There are coins, lucky blocks,
mushroom baddies, bats, spiky balls, spikes, pipes, mushroom tops to hop
across, ponds to swim in, ladders to climb, slippery snow, locked doors to
unlock, and a dog boss waiting at the very end, in World 8-4.

The whole game takes about an hour.

## Playing it

Open the folder in Godot and press the play button, or from a terminal:

```
godot --path "$HOME/Super Snack Cat"
```

| Key | What it does |
|---|---|
| ← → | Run |
| Space | Jump. Hold it longer to jump higher. |
| Space (in water) | One swimming stroke. Tap it over and over to swim up. |
| ↑ ↓ | Climb a ladder |
| Space Space (quick) | Throw a fireball (after coffee) or a chicken nugget (in the suit) |
| R | Start the level over |
| F | Full screen on and off (Esc also gets you out) |
| P | Options — music and sound volume sliders |
| N (in the options box) | Go all the way back to World 1-1 |

The game **remembers which level you got to**. Close it, come back
tomorrow, and you carry on from the same level. Beat the dog and the next
game starts from 1-1 again.

## Hearts

You start every level with **three hearts**, shown under the score. Red
blocks can push you up to **five**.

- A baddie takes one heart and knocks you backwards. You keep playing.
- Fire powers act as a shield — the first hit takes those instead of a heart.
- Lose all three and you go back to the last checkpoint flag with a
  fresh set of three.

## Lucky blocks and power-up blocks

Jump up and **bonk a block with your head**.

The shiny gold block with a **!** on it is a **lucky block** — Kenney's own
gold block. It glows so you can spot it. You never know what's inside:

| Surprise | How often |
|---|---|
| A shower of five coins | lots |
| A **chicken nugget** suit | sometimes |
| A cup of **coffee**, for fire powers | sometimes |
| A **chip** | sometimes |
| A heart | sometimes |
| A **diamond** | not often |
| BAD LUCK — a mushroom baddie jumps out! | not often |

Change how often each one comes out with `LUCKY_SURPRISES` at the top of
`scripts/powerup_block.gd`. Bigger number, more often.

There are **no loose cups of coffee** lying around any more. Coffee only
comes out of blocks.

The coloured blocks always give the same thing:

| Block | What comes out |
|---|---|
| **Orange** | A **chicken nugget** |
| **Red** | A heart — one of your lost ones back |
| **Green** | A **chip** |
| **Blue** | A **diamond** |
| **Brown** | A cup of coffee, for fire powers |

The chip makes you **run much faster for 10 seconds** — 215 instead of 135.
The cat glows warm and leaves an orange trail, and flickers for the last
second and a half as a warning. You keep the same jump, so at that speed
ledges arrive a lot sooner than you expect.

The chicken nugget puts you in a **chicken nugget suit**. Tap SPACE TWICE
and you throw chicken nuggets — no coffee needed, and you can have four in
the air at once instead of two. The suit also takes one hit for you before
it comes off, so it's armour as well as a weapon.

A thrown nugget squashes mushrooms and knocks bats out of the sky. Spiky
balls still shrug them off — those only go down to a diamond.

Want *every* coloured block to drop nuggets? Change every line in
`BLOCK_COLOURS` in `scripts/cat_world.gd` to say `"nugget"`.

The diamond makes you **untouchable for 8 seconds**. You flash through the
rainbow, nothing can hurt you, and anything you run into gets flattened —
including a spiky ball, which is the only way to beat one.

A used-up block goes dark, so you can see at a glance which ones you've
already had.

Adding a new colour is one line in `BLOCK_COLOURS` in
`scripts/cat_world.gd`.

## Volume

Press **P** for the options box. Two sliders: one for the music, one for
every other sound. Sliding one all the way down mutes it completely.

Whatever you set is remembered, so the game starts that way next time.
It's kept in a small file the game writes for itself, nothing you have to
look after.

## The music

Quiet 8-bit loops from Kenney's retro pack. Every look in `LOOKS` in
`scripts/cat_world.gd` says which loop it plays, and `MUSIC_LOUDNESS` sets
how loud. All five tracks are already in `assets/audio/`.

## The worlds

| World | Where | Levels |
|---|---|---|
| 1 | Grassy Hills | grass, underground cave, mushroom tops, grass |
| 2 | Sandy Desert | desert, inside the pyramid, desert, pyramid |
| 3 | Deep Forest | forest, cave, mushroom tops, forest |
| 4 | Snowy Mountains | snow, ice cave, snowy ledges, ice cave |
| 5 | Lakeside | lots of water, cave, mushroom tops, water |
| 6 | Desert Night | the desert in the dark, pyramids |
| 7 | Cloud Land | cloud ledges high in the sky, ice cave, snow |
| 8 | The Dog's Backyard | at night, a cave, and then... **the Dog House** |

Every level starts with its name on screen, like **WORLD 2-3 — SANDY
DESERT**. It gets harder as you go: more baddies, wider gaps, and spiky
balls later on.

**Snow and ice are slippery!** The cat takes longer to get going and
slides when it stops.

Every level hides **one key**, often on top of a tower with a ladder or on
top of a row of blocks. The gate near the sandwich opens when you walk into
it carrying the key — but the gate is only two blocks tall, so if you can't
find the key you can always just jump it. Nothing in this game can trap
you.

Every level was checked by a helper that pretends to be the cat — a
slightly *weaker* cat than the real one — so every jump in the game has a
little room to spare.

## Where everything is

| What | Where |
|---|---|
| The levels (drawn with letters!) | `scripts/levels.gd` |
| How each world looks (ground, trees, music) | `LOOKS` in `scripts/cat_world.gd` |
| The lucky block | `scripts/powerup_block.gd` |
| How the cat moves, jumps and swims | `scripts/cat.gd` |
| The faraway hills behind the level | `scripts/background.gd` |
| The bat, the spiky ball, the mushroom | `scripts/bat.gd`, `spiky_ball.gd`, `mushroom.gd` |
| Pictures | `assets/sprites/` |
| Sounds | `assets/audio/` |
| Art you can shop from | `~/GameAssets/Kenney/` |

## Changing a level

Levels are just rows of letters in `scripts/levels.gd`. Change a letter,
press play, and the level changes. Every level has a `"name"` (like
`"2-3"`), a `"look"`, and 14 rows.

```
.  sky (nothing)     C  a coin           M  a mushroom baddie
G  ground            T  a tree           b  a bush
D  dirt              B  a wooden box     !  a LUCKY block
S  where you start   F  a checkpoint     W  the sandwich (finish!)
H  a dog house       X  the dog boss     A  the axe

^  spikes — they hurt          ~  water — you swim in it
=  a ladder — press UP         k  a key
L  a locked door (needs a key)
E  a bat — flies in a wavy line, you CAN stomp it
O  a spiky ball — rolls at you, you CANNOT stomp it

p  a pipe — stack p's to make it taller
_  a ledge — jump up through it from underneath
m  a mushroom top — jump up through it too
|  a mushroom stalk, under an m (just for looks)
>  an arrow sign    f  a fence (just for looks)

?  orange block (nugget)   R  red (heart)     N  green (chip)
U  blue (diamond)          Y  brown (coffee)
```

The look decides what `G`, `T` and `b` turn into: grass and a pine tree on
the hills, sand and a cactus in the desert, snow and a snowman in the
mountains.

To test just one level, start the game with its name:

```
godot --path "$HOME/Super Snack Cat" -- --level=4-2
```

## Numbers worth playing with

Every one of these is near the top of its file, with a comment saying what
it does. Change one, press play, feel the difference.

| File | Try changing |
|---|---|
| `cat.gd` | `SPEED`, `JUMP_STRENGTH`, `HOW_MANY_HEARTS`, `SWIM_STROKE`, `ICE_GRIP` |
| `powerup_block.gd` | `LUCKY_SURPRISES`, `COINS_IN_A_SHOWER`, `SHINE_SPEED` |
| `background.gd` | `HOW_SLOW` — how far away the hills feel |
| `bat.gd` | `HOW_WAVY` — a lazy glide or a panicky flutter |
| `spiky_ball.gd` | `SPEED` — the spin keeps up on its own |
