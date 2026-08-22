# Pixel Mario

A jump-and-run game. You play a cat. There are coins, mushroom baddies,
a cup of coffee that gives you fire powers, and a dog boss at the end.

## Playing it

Open the folder in Godot and press the play button, or from a terminal:

```
godot --path "$HOME/pixel mario"
```

| Key | What it does |
|---|---|
| ← → | Run |
| Space | Jump. Hold it longer to jump higher. |
| Space Space (quick) | Shoot a fireball — only after you drink the coffee |
| R | Start the level over |

## The three levels

| # | Where | How you finish it |
|---|---|---|
| 1 | Outside, grass and dirt | Eat the sandwich |
| 2 | Longer, more baddies | Eat the sandwich |
| 3 | Inside the dog house | Grab the axe, beat the dog |

## Where everything is

| What | Where |
|---|---|
| The levels (drawn with letters!) | `scripts/cat_world.gd` |
| How the cat moves and jumps | `scripts/cat.gd` |
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
```

Try digging a pit, or building a tower of `B`s.
