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
The **Tennis Ball** is an item (`etherpets_ball`, registered in `Globals.item_data` from `item_resource.gd` at start, icon
drawn in code, category tool, `action` empty, unselectable/unrenamable/unsellable). It is put straight into
`PlayerData.inventory` with the fixed ref `BALL_REF`, so a hotbar slot with it survives sessions. The game doesn't check
item ids when loading a save (the inventory screen would break on an unknown one), so the ball is kept out of every save:
`_keep_ball_item` (every 0.1 s) takes it out of the list while the pause menu is open (its Save/Quit buttons save), when
the world's `autosave_timer` has under 1.5 s left, outside the world, on quit and when the mod unloads, and puts it back
afterwards. It only edits the list (not `PlayerData._remove_item`, which would clear the hotbar slot).

With the ball held (`held_item.id`), `primary_action` down/up throws it (`_throw_ball(power)`: power 0.35–1.0 over a
1.6 s hold): along the camera's aim + 20° (5°–70°), up to 21.2 m/s. Players without EtherPets (no `etherpet` member data)
get an `actor_action` `_update_held_item` with the empty hand, since their game errors on the unknown item.

The throw goes into the lobby member data `etherball` = `1;<throw number>;<x,y,z from>;<x,y,z velocity>`; other players
read it every 0.2 s (a player's last throw is ignored the first time their pet is seen) and simulate the same ball. The ball
(`_move_ball`) moves in fixed 1/60 s steps with raycasts on layers 1|2: bounces (keeps 50% of its speed into the surface)
above 1.5 m/s, rolls with friction below, rests when slow on flat ground or after 10 s. The pet (`_fetch`) hops off a lap or
head first, watches it for `FETCH_WAIT` (1 s), runs after the ball (up to 9 m/s, faster when its owner is fast), picks it up when close and the ball is low,
carries it at its mouth (`MOUTH`, in the head bone's space) back to its owner, drops it and plays `wolf_happy` for 1.4 s.
It gives up after 25 s or when the ball fell 60 m. While charging, `_update_arc` runs the same `_ball_step` from the same `_throw_from` until the first touchdown
and shows 40 dots (MultiMesh) and a landing disc, on the thrower's screen only. On the drop the pet plays its `pet_sound`. While the ball is out (free or carried) the holder's `item_sprite` is hidden (`_hide_held_ball`, every screen); a throw (and the meter) only starts when `_can_throw()`. Tests: `e_fetch.gd`, `e_fetch_lap.gd`, `e_ball.gd`.

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
