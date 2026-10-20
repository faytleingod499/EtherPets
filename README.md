# EtherPets

A little pet, a **wolf**, a **cat** or a **raccoon**, that follows you around in WEBFISHING. It walks after you
(keeping up at any speed), waits beside you and sits down when you stand still for a while. Works on
any server.

*This mod was created with the assistance of AI.*

## Install

Needs [GDWeave](https://github.com/NotNite/GDWeave). Copy the `EtherPets` folder (with
`manifest.json` and `EtherPets.pck`) into `WEBFISHING/GDWeave/mods/`. If you had the older
**WolfPets** mod, delete its folder; your settings carry over.

## Using it

- Press **P** or click the **paw button** (drag it anywhere, it remembers where) for the pet menu:
  - The **wolf**, **cat** and **raccoon** face buttons choose your pet.
  - **Show my pet**, **Answer when I bark** (a wolf howls, a cat meows, a raccoon chitters) and **Wait**, how long it
    waits before answering again (15 seconds to 10 minutes, 2 minutes to start with).
  - **Size** from 50% to 150%.
  - Ready-made looks for each kind, and a colour picker for the fur, back, belly & paws, eyes,
    nose & mouth, and ears & tongue.
  - Type a name and press **Save** to keep a palette (up to 12; it remembers the kind of pet too).
    The palette your pet wears is its name, shown above it.
- Everything is shared through the Steam lobby, so other players with the mod see your pet as you
  made it. Players without the mod do not see pets.

## Fetch
X throws a ball (`_throw_ball`): along the camera's aim, 20° above it (5°–70°), at 15 m/s. The throw goes into the lobby
member data `etherball` = `1;<throw number>;<x,y,z from>;<x,y,z velocity>`; other players read it every 0.2 s (a
player's last throw is ignored the first time their pet is seen) and simulate the same ball. The ball (`_move_ball`)
moves in fixed 1/60 s steps with raycasts on layers 1|2: bounces (keeps 50% of its speed into the surface) above
1.5 m/s, rolls with friction below, rests when slow on flat ground or after 10 s. The pet (`_fetch`) hops off a lap or
head first, runs after the ball (up to 9 m/s, faster when its owner is fast), picks it up when close and the ball is
low, carries it at its mouth (`MOUTH`, in the head bone's space) back to its owner, drops it and plays `wolf_happy`
for 1.4 s. It gives up after 25 s or when the ball fell 60 m. Tests: `e_fetch.gd`, `e_fetch_lap.gd`.

## Petting

Walk up to any pet and press the game's interact key at **Pet <name>**. It comes to stand in front of
you and you lean in and stroke its head, sized to fit you (it lowers or raises its head, or lies down
for a very small player). A wolf gives a happy whine, a cat purrs, a raccoon trills.

When you sit down, a wolf lies down beside you, a cat hops into your lap and curls up, and a
raccoon climbs up and flops on your head. A raccoon (a round, chubby one) doesn't walk: it tucks its tail in and tumbles
head over heels after you.

## Building

`source/mods/EtherPets/` holds the script, the pet scenes and the howl. `model/pet_*.glb` are the
Blender exports, `model/convert.gd` turns an imported one into a pet scene (Godot 3.5),
`model/make_howl.py` and `model/make_chitter.py` make the howl and the chitter, and `pack.gd` packs the `.pck`.

## Building

The mod is plain GDScript (plus models and sounds) packed into `package/EtherPets/EtherPets.pck` with the Godot 3.5 engine's own packer:

```
godot --no-window -s pack.gd
./build.sh
```

`pack.gd` packs `source/mods/EtherPets/` into the pck. `build.sh` then makes `out/EtherPets-mod.zip` (the folder for `GDWeave/mods`) and the Thunderstore upload zip from `thunderstore/`. Requires [GDWeave](https://thunderstore.io/c/webfishing/p/NotNet/GDWeave/).

## License

[MIT](LICENSE): you are free to copy, change and share your own versions of this mod, as long as you keep the copyright notice.
