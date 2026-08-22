# Super Snack Cat

A jump-and-run game. You play a cat. There are coins, mushroom baddies,
bats, spiky balls, spikes, ponds to swim in, ladders to climb, locked doors
to unlock, a cup of coffee that gives you fire powers, and a dog boss at
the end.

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
| Space Space (quick) | Shoot a fireball — only after you drink the coffee |
| R | Start the level over |

## Hearts

You start every level with **three hearts**, shown under the score.

- A baddie takes one heart and knocks you backwards. You keep playing.
- Fire powers act as a shield — the first hit takes those instead of a heart.
- Lose all three and you go back to the last checkpoint flag with a
  fresh set of three.

## The three levels

| # | Where | How you finish it |
|---|---|---|
| 1 | Outside, grass and dirt | Unlock the gate, eat the sandwich |
| 2 | Longer, more baddies | Unlock the gate, eat the sandwich |
| 3 | Inside the dog house | Unlock the gate, grab the axe, beat the dog |

Each level hides **one key**. No key, no gate, no finish.

## Where everything is

| What | Where |
|---|---|
| The levels (drawn with letters!) | `scripts/cat_world.gd` |
| How the cat moves, jumps and swims | `scripts/cat.gd` |
| The faraway hills behind the level | `scripts/background.gd` |
| The bat, the spiky ball, the mushroom | `scripts/bat.gd`, `spiky_ball.gd`, `mushroom.gd` |
| Pictures | `assets/sprites/` |
| Sounds | `assets/audio/` |
| Art you can shop from | `~/GameAssets/Kenney/` |

## Changing a level

Levels are just rows of letters near the top of `scripts/cat_world.gd`.
Change a letter, press play, and the level changes.

```
.  sky (nothing)     C  a coin           M  a mushroom baddie
G  grass ground      T  a tree           b  a bush
D  dirt              B  a wooden box     ?  a question box
S  where you start   F  a checkpoint     W  the sandwich (finish!)
P  a cup of coffee   H  a dog house      X  the dog boss     A  the axe

^  spikes — they hurt          ~  water — you swim in it
=  a ladder — press UP         k  a key
L  a locked door (needs a key)
E  a bat — flies in a wavy line, you CAN stomp it
O  a spiky ball — rolls at you, you CANNOT stomp it
```

Try digging a pit and filling it with `~`, or building a tower of `B`s with
a `=` ladder up the side.

## Numbers worth playing with

Every one of these is near the top of its file, with a comment saying what
it does. Change one, press play, feel the difference.

| File | Try changing |
|---|---|
| `cat.gd` | `SPEED`, `JUMP_STRENGTH`, `HOW_MANY_HEARTS`, `SWIM_STROKE` |
| `background.gd` | `HOW_SLOW` — how far away the hills feel |
| `bat.gd` | `HOW_WAVY` — a lazy glide or a panicky flutter |
| `spiky_ball.gd` | `SPEED` — the spin keeps up on its own |
