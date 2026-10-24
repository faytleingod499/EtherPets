extends Node

# EtherPets
# A little pet (a wolf or a cat) that follows you around: it walks after you, waits next to you and
# sits down when you stand still for a while. Click the paw button (or press P) to choose your pet and
# its colours. Your choices are shared through the Steam lobby, so other players who have this mod
# see your pet exactly as you made it. Players without the mod do not see pets. Works on any server.

const VERSION = "2.12.7"
const CONFIG_PATH = "user://etherpets.json"
const OLD_CONFIG_PATH = "user://wolfpets.json" # from when it was Wolf Pets
const SHADOW_PATH = "res://Scenes/Entities/Shadow/shadow.tscn"
const SYNC_KEY = "etherpet"
const PAT_KEY = "etherpat"  # "<pet owner's steam id>;<count>" while petting, empty otherwise
const AREA_SCRIPT = "res://mods/EtherPets/pet_area.gd"
const COOLDOWN_MIN = 15    # seconds between answers to a bark: the slider's range and default
const COOLDOWN_MAX = 600
const COOLDOWN_DEFAULT = 120
const SKELETON_PATH = "body/player_body/Armature/Skeleton"
const POPUP_ID = "ETHERPETS"
const DEFAULT_PAW_POS = Vector2(16, 140)

const PET_SCALE = 0.82    # a wolf at size 100%, about 60% of a player's height (see SPECIES for others)
const SIZE_MIN = 0.5
const SIZE_MAX = 1.5
const FOLLOW_NEAR = 2.1    # stops when this close to its owner
const FOLLOW_FAR = 3.0     # starts walking again when further than this
const MAX_PALETTES = 12
const PAT_TIME = 3.5       # seconds of petting
const LIE_AFTER = 0.6      # seconds after its owner sits down
const TELEPORT_DIST = 16.0 # this far behind it just appears next to its owner again
const WALK_SPEED = 3.0
const RUN_SPEED = 7.5
const SIT_AFTER = 5.0      # seconds of standing still before it sits down

# fetch: the Tennis Ball in the inventory, held and thrown with the mouse; the pet runs after it and brings it back
const BALL_ITEM = "etherpets_ball"
const BALL_REF = 1868100427  # always the same, so a hotbar slot with the ball on it still works next time
const BALL_MIN_POWER = 0.35  # a quick click is a short toss, holding the button throws further
const BALL_CHARGE_TIME = 1.6 # seconds to full strength
const BALL_KEY = "etherball" # "1;<throw number>;<x,y,z where it left the hand>;<x,y,z speed>", the last throw
const BALL_RADIUS = 0.09
const BALL_SPEED = 21.2      # 15 * sqrt(2): twice the distance of 2.10.1
const BALL_GRAVITY = 18.0
const BALL_BOUNCE = 0.5      # how much of its speed into the ground it keeps on a bounce
const BALL_STEP = 1.0 / 60.0
const FETCH_SPEED = 9.0      # it really runs for a ball
const FETCH_WAIT = 0.5       # seconds it watches the ball fly before it runs after it
const FETCH_GIVE_UP = 25.0   # seconds; a ball it can't reach (in the sea, up a cliff) is let go
const THROW_COOLDOWN_MS = 600
# where the ball sits in its mouth: in its head bone's own space, model units (bone y = forward, z = down)
const MOUTH = {"wolf": Vector3(0, 0.64, 0.22), "cat": Vector3(0, 0.43, 0.14), "raccoon": Vector3(0, 0.58, 0.12), "fox": Vector3(0, 0.70, 0.22)}

# the parts that can be coloured: key, label, the model's material for it.
# The first six keep their places (older versions of the mod read the lobby text by position).
const PARTS = [
	["fur", "Body", "pet_fur"],
	["back", "Back", "pet_dark"],
	["belly", "Belly", "pet_light"],
	["eyes", "Eyes", "pet_eye"],
	["nose", "Nose", "pet_black"],
	["ears", "Inner ears", "pet_ear_inner"],
	["paws", "Paws", "pet_paws"],
	["tail", "Tail tip", "pet_tail"],     # the raccoon's tail rings
	["mask", "Mask", "pet_mask"],
	["earback", "Ear backs", "pet_ear_back"],
	["mouth", "Mouth", "pet_mouth"],
	["tongue", "Tongue", "pet_tongue"],
	["shine", "Eye shine", "pet_white"],
	["whiskers", "Whiskers", "pet_whiskers"],
	["muzzle", "Muzzle", "pet_muzzle"],
	["legs", "Front legs", "pet_legs"],
	["head", "Head", "pet_head"],
	["neck", "Neck", "pet_neck"],
	["throat", "Throat", "pet_throat"],
	["hindlegs", "Back legs", "pet_hindlegs"],
	["tailbase", "Tail", "pet_tailbase"],
	["face", "Face", "pet_face"],
]
# a part with no colour of its own (an older palette, or someone on an older version) takes
# the colour of the part it used to share, or a fixed colour ("#...")
const DERIVE = {"paws": "belly", "muzzle": "belly", "legs": "paws", "tail": "back", "mask": "back", "earback": "back", "mouth": "nose",
	"tongue": "ears", "shine": "#ffffff", "whiskers": "#f2f2f2",
	"head": "fur", "neck": "fur", "throat": "belly", "hindlegs": "fur", "tailbase": "fur", "face": "head"}

# every kind of pet: its model, how big it is, its noises, and its ready-made looks.
# All of them share one skeleton and one set of animations, so the rest of the mod works for each.
# "move": how it gets about ("walk", or "roll" in somersaults: "roll_dist" is how far one somersault
#         carries it, in the model's own units). "sit": what it does when its owner sits down
#         ("beside" them, in their "lap", or on their "head").
const SPECIES_ORDER = ["wolf", "fox", "cat", "raccoon"]
const STANDARD_PARTS = ["fur", "back", "belly", "legs", "hindlegs", "paws", "tailbase", "eyes", "shine", "mouth", "tongue",
	"earback", "ears", "head", "face", "muzzle", "nose"]
const SPECIES = {
	"wolf": {
		"label": "Wolf", "model": "res://mods/EtherPets/wolf.scn", "scale": 0.82, "move": "walk", "sit": "beside",
		# the areas every kind has, in the same order, then its own special ones
		"parts": STANDARD_PARTS + ["neck", "throat", "tail"],
		"derive": {"legs": "fur"},                                         # its front legs were "fur" before
		"pet_sound": "res://Sounds/dog_whine.ogg", "pet_pitch": 1.2,       # a happy whine
		"call_sound": "res://mods/EtherPets/howl.wav", "call_pitch": 1.0, # a short howl
		"call_time": 2.0, "call_lift": 40.0,                               # nose to the sky
		"presets": [
			["Grey", {"fur": "aaadb8", "back": "797c89", "belly": "e7eaed", "eyes": "303038", "nose": "303038", "ears": "e7bfc8"}],
			["White", {"fur": "eff0f2", "back": "d4d8df", "belly": "fcfcfa", "eyes": "303038", "nose": "303038", "ears": "e7bfc8"}],
			["Black", {"fur": "4d4d55", "back": "2c2c30", "belly": "95979e", "eyes": "e8a23a", "nose": "1c1c20", "ears": "e7bfc8"}],
		],
	},
	"fox": {
		# the wolf's skeleton and animations, in a slimmer body with a long snout, big ears and a bushy tail
		"label": "Fox", "model": "res://mods/EtherPets/fox.scn", "scale": 0.68, "move": "walk", "sit": "head",
		"perch_anim": "fox_curl", "perch_centre": Vector3(0.23, 0, -0.21), "hop_anim": "fox_leap", "hop_time": 0.6, # pounces up onto its owner's head and curls up
		"parts": STANDARD_PARTS + ["neck", "throat", "tail"],
		"derive": {"legs": "fur"},
		"pet_sound": "res://Sounds/dog_whine.ogg", "pet_pitch": 1.6,       # a high, happy whine
		"call_sound": "res://Sounds/dog_bark.ogg", "call_pitch": 1.9,      # a yip back
		"call_time": 0.9, "call_lift": 22.0,
		"presets": [
			["Red", {"fur": "d9772b", "back": "b85a1c", "belly": "f6ece0", "eyes": "2a1c10", "nose": "1c1c20", "ears": "e8b8b0",
				"earback": "3a2a22", "legs": "3a2a22", "hindlegs": "3a2a22", "paws": "2a2020", "tail": "fbf6ee", "muzzle": "f6ece0", "throat": "f6ece0"}],
			["Arctic", {"fur": "f2f4f6", "back": "dfe3e8", "belly": "ffffff", "eyes": "2a2a30", "nose": "1c1c20", "ears": "f0c8cc",
				"earback": "e8ebef", "legs": "f2f4f6", "hindlegs": "f2f4f6", "paws": "e8ebef", "tail": "ffffff", "muzzle": "ffffff", "throat": "ffffff"}],
			["Silver", {"fur": "8e939c", "back": "5f636c", "belly": "e9ebee", "eyes": "d9a83a", "nose": "1c1c20", "ears": "e0b8bc",
				"earback": "2c2c32", "legs": "3a3a40", "hindlegs": "3a3a40", "paws": "2a2a30", "tail": "f4f4f6", "muzzle": "e9ebee", "throat": "e9ebee"}],
		],
	},
	"cat": {
		"label": "Cat", "model": "res://mods/EtherPets/cat.scn", "scale": 0.55, "move": "walk", "sit": "lap",
		"parts": STANDARD_PARTS + ["neck", "throat", "tail", "whiskers"],
		"derive": {"legs": "fur", "earback": "fur"},                       # these were "fur" before
		"pet_sound": "res://Sounds/cat_purr.ogg", "pet_pitch": 1.0,       # a purr
		"call_sound": "res://Sounds/cat_meow.ogg", "call_pitch": 1.1,     # a meow back
		"call_time": 0.9, "call_lift": 18.0,
		"presets": [
			["Ginger", {"fur": "e8a25a", "back": "c47a35", "belly": "fbe9d6", "eyes": "6fae4a", "nose": "e79aa8", "ears": "f0b8c0"}],
			["Grey", {"fur": "a9adb5", "back": "7c808b", "belly": "eef0f2", "eyes": "d9b84a", "nose": "e79aa8", "ears": "f0b8c0"}],
			["Black", {"fur": "3a3a40", "back": "25252a", "belly": "5c5c64", "eyes": "e8c23a", "nose": "2a2a30", "ears": "d9a0a8"}],
		],
	},
	"raccoon": {
		"label": "Raccoon", "model": "res://mods/EtherPets/raccoon.scn", "scale": 0.6, "move": "roll", "sit": "head",
		"parts": STANDARD_PARTS + ["tail", "mask"],
		"labels": {"tail": "Tail rings"},
		# its dark legs were "back" before; its ear backs were "fur"; and it has a pink tongue whatever its ears are.
		# Its "back" was the dark of its mask and legs, before it had a back of its own: see _color_text
		"derive": {"paws": "back", "earback": "fur", "tongue": "#d98c98"},
		"roll_dist": 2.8,                                                 # one somersault, curled up and back onto its feet
		"anims": {"wolf_sit": "raccoon_sit", "wolf_lie": "raccoon_flop"}, # its own loaf and sprawl
		"pet_sound": "res://mods/EtherPets/trill.wav", "pet_pitch": 1.0,  # a happy churring trill
		"call_sound": "res://mods/EtherPets/chitter.wav", "call_pitch": 1.0, # a chitter
		"call_time": 1.2, "call_lift": 15.0,
		"presets": [
			["Classic", {"fur": "666666", "back": "575757", "head": "666666", "belly": "d9d9d9", "eyes": "0d0c06", "nose": "0d0c06", "ears": "d9d9d9",
				"mask": "333333", "paws": "333333", "legs": "333333", "tail": "333333"}],
			["Silver", {"fur": "b4b6bc", "back": "9d9fa6", "head": "b4b6bc", "belly": "eeeff1", "eyes": "1a1410", "nose": "1c1c20", "ears": "f2eeee",
				"mask": "4a4a52", "paws": "4a4a52", "legs": "4a4a52", "tail": "4a4a52"}],
			["Brown", {"fur": "8c7458", "back": "7a644b", "head": "8c7458", "belly": "e2d6c4", "eyes": "1a1410", "nose": "2a1e18", "ears": "f0e2d0",
				"mask": "3a2c22", "paws": "3a2c22", "legs": "3a2c22", "tail": "3a2c22"}],
		],
	},
}

var steam = null
var verify_timer = 0.0
var scenes = {}  # species -> its model scene
var sounds = {}  # path -> loaded sound
var shadow_scene = null

# my pet
var show_pet = true
var species = "wolf"
var species_buttons = {}
var preset_row
var pet_size = 1.0 # times the normal size
var howl_on = true # answers its owner's bark (a wolf howls, a cat meows)
var howl_box
var answer_cooldown = COOLDOWN_DEFAULT # seconds
var cooldown_slider
var cooldown_label
var pet_name = ""  # the name of the palette it wears, shown above it
var name_layer
var menu_title
var size_slider
var size_label
var colors = {}
var sync_dirty = true
var my_side = 0 # which side of me my pet lies on while I sit (-1 left, 1 right, 0 not lying down), shared so everyone sees the same
var sync_timer = 0.0
var synced_lobby = 0

# every pet in the world: key -> {node, model, anim, meshes, mats, speed, still, anim_name, sig}
var pets = {}
var remote_cfg = {} # steam id -> {"show": bool, "colors": {}, "raw": text}
var read_timer = 0.0

# petting: petter key ("me" or a steam id) -> {petter, pet_key, phase, t, w, start, lean, neck}
var pats = {}
var my_pat_seq = 0
var pat_read_timer = 0.0
var remote_pat_seen = {}
var my_ball_seq = 0
var ball_seen = {} # steam id -> the throw number last seen from them
var ball_read_timer = 0.0
var last_throw = -100000
var ball_material = null
var ball_icon = null
var charging_since = -1      # ms when the mouse button went down with the ball in hand, -1 when not
var told_no_mod = {}         # players without the mod, already told I'm holding nothing (see _hide_ball_from_others)
var told_timer = 0.0
var keep_timer = 0.0
var fetch_hint
var charge_panel
var charge_fill
var charge_label
var arc_node = null   # the dots of the preview arc while charging a throw
var land_node = null  # and the disc where it lands
const ARC_DOTS = 40
var area_script = null

# the paw button and the menu
var layer
var paw
var paw_hover = false
var paw_pressed = false
var paw_dragging = false
var press_pos = Vector2()
var drag_offset = Vector2()
var menu
var show_box
var pickers = {}
var picker_labels = {} # part -> its label in the colour grid
var menu_open = false
var palettes = {} # name -> colours, the player's own saved looks
var name_field
var palette_box
var palette_toggle
var palettes_open = false # the saved palette list starts folded
var colors_grid
var colors_toggle
var colors_open = false # so do the colour pickers
var locked_hud = null
var theme_applied = false


func _ready():
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
	for key in SPECIES_ORDER:
		var info = SPECIES[key]
		if ResourceLoader.exists(info["model"]):
			scenes[key] = load(info["model"])
		for which in ["pet_sound", "call_sound"]:
			var path = info[which]
			if not sounds.has(path):
				sounds[path] = _load_wav(path) if path.ends_with(".wav") else (load(path) if ResourceLoader.exists(path) else null)
	if ResourceLoader.exists(AREA_SCRIPT):
		area_script = load(AREA_SCRIPT)
	if ResourceLoader.exists(SHADOW_PATH):
		shadow_scene = load(SHADOW_PATH)
	_register_ball_item()
	_reset_colors(0)
	_build_ui()
	_load_config()
	_rebuild_palettes()
	_apply_to_pickers()


func _exit_tree():
	_set_ball_in_inventory(false)
	if arc_node != null and is_instance_valid(arc_node):
		arc_node.queue_free()
		land_node.queue_free()
	_unlock_hud()
	if pats.has("me"):
		_send_pat("")
	for key in pets.keys():
		_remove_pet(key)


# --- colours ---

# preset: its number in the current kind's list, or its name
func _reset_colors(preset):
	var list = SPECIES[species]["presets"]
	var index = 0
	if typeof(preset) == TYPE_STRING:
		for i in range(list.size()):
			if list[i][0] == preset:
				index = i
	else:
		index = clamp(int(preset), 0, list.size() - 1)
	colors = {}
	for part in PARTS:
		colors[part[0]] = _color_text(list[index][1], part[0], species)


func _color_of(cfg_colors, key, kind = "wolf"):
	return Color(_color_text(cfg_colors, key, kind))


# a part's colour, or the colour it takes from the part it used to share
func _color_text(cfg_colors, key, kind = "wolf", depth = 0):
	var text = str(cfg_colors.get(key, ""))
	# a raccoon from before it had a back of its own (no "head" yet): its "back" was the dark of its
	# mask and legs, so its new back stays its body colour. The mask and legs still take that dark.
	if key == "back" and kind == "raccoon" and depth == 0 and not str(cfg_colors.get("head", "")).is_valid_html_color():
		return _color_text(cfg_colors, "fur", kind, depth + 1)
	if text.is_valid_html_color():
		return text
	var from = str(SPECIES.get(kind, {}).get("derive", {}).get(key, DERIVE.get(key, "")))
	if from.begins_with("#"):
		return from.substr(1)
	if from != "" and depth < 4:
		return _color_text(cfg_colors, from, kind, depth + 1)
	return str(SPECIES["wolf"]["presets"][0][1].get(key, "ffffff"))


# what goes into the lobby: "1;1;fur,back,belly,eyes,nose,ears;1.00;Name;1;wolf"
# (format, shown, colours, size, name, answers barks, species)
func _sync_text():
	var list = []
	for part in PARTS:
		list.append(_color_text(colors, part[0], species))
	return "1;" + ("1" if show_pet else "0") + ";" + PoolStringArray(list).join(",") + ";" + ("%.2f" % pet_size) + ";" + _clean_name(pet_name) + ";" + ("1" if howl_on else "0") + ";" + species + ";" + str(answer_cooldown) + ";" + str(my_side)


# names travel inside the lobby text, so they lose the separators and stay short
func _clean_name(text):
	return str(text).replace(";", "").replace("\n", " ").strip_edges().left(20)


func _parse_sync(text):
	var bits = str(text).split(";")
	if bits.size() < 3 or bits[0] != "1":
		return null
	var cfg = {"show": bits[1] == "1", "colors": {}, "raw": text}
	var list = bits[2].split(",")
	for i in range(PARTS.size()):
		if i < list.size() and list[i].is_valid_html_color():
			cfg["colors"][PARTS[i][0]] = list[i]
	cfg["size"] = clamp(float(bits[3]), SIZE_MIN, SIZE_MAX) if bits.size() > 3 and bits[3].is_valid_float() else 1.0
	cfg["name"] = _clean_name(bits[4]) if bits.size() > 4 else ""
	cfg["howl"] = bits[5] != "0" if bits.size() > 5 else true
	cfg["species"] = bits[6] if bits.size() > 6 and SPECIES.has(bits[6]) else "wolf"
	cfg["cooldown"] = clamp(int(bits[7]), COOLDOWN_MIN, COOLDOWN_MAX) if bits.size() > 7 and bits[7].is_valid_integer() else COOLDOWN_DEFAULT
	cfg["side"] = int(bits[8]) if bits.size() > 8 and bits[8] in ["-1", "1"] else 0
	return cfg


# --- every frame ---

func _process(delta):
	_refresh_ui()
	_update_charge_bar()

	var net = get_node_or_null("/root/Network")
	var lobby = 0
	if net != null and not net.PLAYING_OFFLINE and net.STEAM_LOBBY_ID > 0:
		lobby = net.STEAM_LOBBY_ID

	# tell the lobby about my pet (not more than once a second, colour dragging changes it a lot)
	sync_timer += delta
	if lobby != synced_lobby:
		synced_lobby = lobby
		sync_dirty = true
	# what I wrote may not have stuck: a write made while still joining the lobby is dropped by Steam,
	# and then nobody sees my pet until I change something. So every few seconds read it back and resend.
	verify_timer += delta
	if verify_timer >= 3.0 and lobby > 0 and steam != null and steam.has_method("getLobbyMemberData") and net != null:
		verify_timer = 0.0
		if str(steam.getLobbyMemberData(lobby, int(net.STEAM_ID), SYNC_KEY)) != _sync_text():
			sync_dirty = true
	if sync_dirty and sync_timer >= 1.0 and lobby > 0 and steam != null and steam.has_method("setLobbyMemberData"):
		sync_timer = 0.0
		sync_dirty = false
		steam.setLobbyMemberData(lobby, SYNC_KEY, _sync_text())

	# read everyone else's pets once a second
	read_timer += delta
	if read_timer >= 1.0:
		read_timer = 0.0
		_read_remote(lobby)

	# someone else starting or stopping to pet a pet is read more often, so it starts quickly
	pat_read_timer += delta
	if pat_read_timer >= 0.2:
		pat_read_timer = 0.0
		_read_remote_pats(lobby, net)

	keep_timer += delta
	if keep_timer >= 0.1:
		keep_timer = 0.0
		_keep_ball_item()
	told_timer += delta
	if told_timer >= 2.0:
		told_timer = 0.0
		_hide_ball_from_others(lobby, net)

	# someone throwing a ball for their pet
	ball_read_timer += delta
	if ball_read_timer >= 0.2:
		ball_read_timer = 0.0
		_read_remote_balls(lobby)

	_update_pets(delta, net)
	_update_pats(delta)


func _read_remote(lobby):
	remote_cfg = {}
	if lobby <= 0 or steam == null or not steam.has_method("getLobbyMemberData"):
		return
	for player in get_tree().get_nodes_in_group("player"):
		if not _is_real_player(player) or player.get("controlled") == true:
			continue
		var id = player.get("owner_id")
		var cfg = _parse_sync(steam.getLobbyMemberData(lobby, id, SYNC_KEY))
		if cfg != null:
			remote_cfg[id] = cfg


func _is_real_player(player):
	if not is_instance_valid(player):
		return false
	if player.get("dead_actor") == true or player.get("NPC_body") == true:
		return false
	var id = player.get("owner_id")
	return id != null and int(id) > 0


func _update_pets(delta, net):
	var wanted = {} # pet key -> [owner node, show, colours]
	for player in get_tree().get_nodes_in_group("player"):
		if not _is_real_player(player):
			continue
		if player.get("controlled") == true:
			wanted["me"] = [player, show_pet, colors, pet_size, pet_name, howl_on, species, answer_cooldown, my_side]
		else:
			var id = player.get("owner_id")
			if remote_cfg.has(id) and remote_cfg[id]["show"]:
				wanted[id] = [player, true, remote_cfg[id]["colors"], remote_cfg[id]["size"], remote_cfg[id]["name"], remote_cfg[id]["howl"], remote_cfg[id]["species"], remote_cfg[id]["cooldown"], remote_cfg[id]["side"]]

	for key in pets.keys():
		var pet = pets[key]
		# gone, hidden, or turned into another kind of pet: it is made again
		if not wanted.has(key) or not wanted[key][1] or not is_instance_valid(pet["node"]) \
				or not is_instance_valid(pet["owner"]) or pet["owner"] != wanted[key][0] \
				or pet["species"] != wanted[key][6]:
			_remove_pet(key)

	for key in wanted.keys():
		var owner_node = wanted[key][0]
		if not wanted[key][1] or not scenes.has(wanted[key][6]):
			continue
		if not pets.has(key):
			var pet = _make_pet(owner_node, wanted[key][6])
			if pet == null:
				continue
			pet["key"] = key
			pets[key] = pet
			if pet["area"] != null:
				pet["area"].pet_key = key
		var pet = pets[key]
		var sig = str(wanted[key][2].hash()) + "/" + str(wanted[key][3])
		if pet["sig"] != sig:
			pet["sig"] = sig
			_paint(pet, wanted[key][2])
			_apply_size(pet, wanted[key][3])
		if pet["pat"] == null:
			_move_pet(pet, owner_node, delta)
		if pet["anim_name"] != "raccoon_ball":
			pet["spin"].rotation.x = lerp_angle(wrapf(pet["spin"].rotation.x, -PI, PI), 0.0, clamp(delta * 10.0, 0.0, 1.0))
		_place_label(pet, wanted[key][4])
		pet["howl_on"] = wanted[key][5]
		pet["cooldown"] = wanted[key][7]
		pet["told_side"] = wanted[key][8]
		_listen_for_bark(pet, owner_node, delta)
		_hide_held_ball(pet, owner_node)
		# "Pet <name>" is offered while it stands or walks, not while it sits, lies down or is being petted
		if pet["area"] != null and is_instance_valid(pet["area"]):
			var name = str(wanted[key][4])
			pet["area"].text = "Pet " + (name if name != "" else SPECIES[pet["species"]]["label"].to_lower())
			pet["area"].visible = pet["pat"] == null and pet["lap"] == "" and pet.get("fetch") == null and not pet["anim_name"] in ["wolf_sit", "wolf_lie", "cat_curl", "raccoon_flop", "raccoon_sit", "fox_curl"]


# --- making a pet ---

func _make_pet(owner_node, kind):
	var parent = owner_node.get_parent()
	if parent == null:
		return null
	var node = Spatial.new()
	node.name = "EtherPet"
	parent.add_child(node)

	# a pivot in the middle of the pet, for the kinds that roll along
	var spin = Spatial.new()
	spin.name = "Spin"
	node.add_child(spin)
	var model = scenes[kind].instance()
	model.rotation_degrees = Vector3(0, 180, 0) # the model looks along +Z, Godot's forward is -Z
	model.scale = Vector3.ONE * PET_SCALE
	spin.add_child(model)

	if shadow_scene != null:
		var shadow = shadow_scene.instance()
		node.add_child(shadow)

	# the spot the game's interact key finds, so walking up to a pet offers "Pet <name>"
	var area = null
	if area_script != null:
		area = Area.new()
		area.set_script(area_script)
		area.mod = self
		var shape = CollisionShape.new()
		var sphere = SphereShape.new()
		sphere.radius = 0.9 * PET_SCALE
		shape.shape = sphere
		shape.translation = Vector3(0, 0.6 * PET_SCALE, 0)
		area.add_child(shape)
		node.add_child(area)
		area.set_meta("shape", shape)

	var anim = model.find_node("AnimationPlayer", true, false)
	var meshes = []
	_collect_meshes(model, meshes)

	# each pet gets its own materials so everyone's pet can have different colours
	var mats = {}
	for mi in meshes:
		for i in range(mi.mesh.get_surface_count()):
			var base = mi.mesh.surface_get_material(i)
			if base == null:
				continue
			var own = base.duplicate()
			mi.set_surface_material(i, own)
			mats[base.resource_name.split(".")[0]] = own

	# start next to its owner
	var start = owner_node.global_transform.origin + Vector3(1.0, 0, 1.0).normalized() * FOLLOW_NEAR
	node.global_transform.origin = _ground(node, start, _feet_y(owner_node))

	var pet = {"node": node, "model": model, "anim": anim, "mats": mats, "owner": owner_node,
		"speed": 0.0, "still": 0.0, "anim_name": "", "sig": "", "moving": false, "sat": 0.0,
		"area": area, "pat": null, "skeleton": model.find_node("Skeleton", true, false),
		"scale": PET_SCALE, "size": 1.0, "side": 0, "label": _make_label(), "species": kind, "spin": spin, "lap": "", "hop_t": 0.0, "hop_from": Vector3(),
		"voice": _make_voice(node), "barking": false, "howl_wait": -1.0, "howl_t": -1.0,
		"howl_on": true, "last_answer": -10000000, "told_side": 0, "key": "", "fetch": null}
	_play(pet, "wolf_idle", 1.0)
	return pet


# --- noises ---

# a .wav packed with the mod, read straight into a sound the engine can play
func _load_wav(path):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return null
	var bytes = file.get_buffer(file.get_len())
	file.close()
	if bytes.size() < 44:
		return null
	var rate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24)
	var channels = bytes[22] | (bytes[23] << 8)
	var i = 12
	while i + 8 <= bytes.size():
		var id = bytes.subarray(i, i + 3).get_string_from_ascii()
		var size = bytes[i + 4] | (bytes[i + 5] << 8) | (bytes[i + 6] << 16) | (bytes[i + 7] << 24)
		if id == "data":
			var sample = AudioStreamSample.new()
			sample.format = AudioStreamSample.FORMAT_16_BITS
			sample.mix_rate = rate
			sample.stereo = channels == 2
			sample.data = bytes.subarray(i + 8, min(i + 8 + size, bytes.size()) - 1)
			return sample
		i += 8 + size + (size % 2)
	return null


# the pet's voice, set up like the players' own barks
func _make_voice(node):
	var voice = AudioStreamPlayer3D.new()
	voice.unit_db = 0.2
	voice.unit_size = 2.2
	voice.max_db = -12.0
	voice.max_distance = 50.0
	voice.attenuation_filter_cutoff_hz = 8000.0
	voice.bus = "SFX"
	voice.translation = Vector3(0, 0.9 * PET_SCALE, 0)
	node.add_child(voice)
	return voice


# bigger wolves sound deeper, smaller ones higher
func _say(pet, sound, pitch):
	var voice = pet.get("voice")
	if sound == null or voice == null or not is_instance_valid(voice):
		return
	voice.stream = sound
	voice.pitch_scale = clamp(pitch / sqrt(pet["size"]), 0.6, 2.0)
	voice.play()


# when its owner barks (or meows) it answers with a short howl, nose to the sky
func _listen_for_bark(pet, owner_node, delta):
	# any bark: the dog's and cat's, and the ones custom species add through Lure ("bark_<species>")
	var barking = false
	var sm = owner_node.get_node_or_null("sound_manager")
	if sm != null:
		for player in sm.get_children():
			if player.name.begins_with("bark_") and player.get("playing") == true:
				barking = true
				break
	var now = OS.get_ticks_msec()
	if barking and not pet["barking"] and pet["howl_on"] \
			and now >= pet["last_answer"] + int(pet.get("cooldown", COOLDOWN_DEFAULT)) * 1000 \
			and pet["howl_t"] < 0.0 and pet["howl_wait"] < 0.0:
		pet["howl_wait"] = 0.35
		pet["last_answer"] = now
	pet["barking"] = barking
	if pet["howl_wait"] >= 0.0:
		pet["howl_wait"] -= delta
		if pet["howl_wait"] < 0.0:
			pet["howl_t"] = 0.0
			var info = SPECIES[pet["species"]]
			_say(pet, sounds.get(info["call_sound"]), info["call_pitch"])
	if pet["howl_t"] >= 0.0:
		pet["howl_t"] += delta
		var ws = pet["skeleton"]
		var neck = ws.find_bone("neck") if ws != null and is_instance_valid(ws) else -1
		var call_time = SPECIES[pet["species"]]["call_time"]
		if pet["howl_t"] > call_time or pet["pat"] != null:
			pet["howl_t"] = -1.0
			if neck >= 0 and pet["pat"] == null:
				ws.set_bone_global_pose_override(neck, Transform(), 0.0, true)
		elif neck >= 0:
			# up quickly, held while it howls, then down again as the howl fades
			var w = clamp(pet["howl_t"] / 0.25, 0.0, 1.0) * clamp((call_time - pet["howl_t"]) / 0.4, 0.0, 1.0)
			var fwd = _facing(pet["node"])
			var axis = ws.global_transform.basis.inverse().xform(Vector3.UP.cross(fwd)).normalized()
			var g = ws.get_bone_global_pose_no_override(neck)
			ws.set_bone_global_pose_override(neck, Transform(Basis(axis, deg2rad(-SPECIES[pet["species"]]["call_lift"])) * g.basis, g.origin), w, true)


func _make_label():
	var label = Label.new()
	label.align = Label.ALIGN_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	label.add_color_override("font_color", Color(1, 1, 1))
	label.add_color_override("font_color_shadow", Color(0.05, 0.1, 0.15, 0.9))
	label.add_constant_override("shadow_as_outline", 1)
	label.add_constant_override("shadow_offset_x", 1)
	label.add_constant_override("shadow_offset_y", 1)
	name_layer.add_child(label)
	return label


# the name floats above its head, smaller the further away it is, like the players' own names
func _place_label(pet, name):
	var label = pet["label"]
	if label == null or not is_instance_valid(label):
		return
	# the game draws the world inside its own viewport, so the camera (and the spot on screen) is there
	var world_view = pet["node"].get_viewport()
	var camera = world_view.get_camera() if world_view != null else null
	var hud = _get_hud()
	if name == "" or camera == null or not pet["node"].is_visible_in_tree() or (hud != null and hud.get("hud_hidden") == true):
		label.visible = false
		return
	var ws = pet["skeleton"]
	var top = pet["node"].global_transform.origin + Vector3.UP * 1.3 * pet["scale"]
	if ws != null and is_instance_valid(ws) and ws.find_bone("head") >= 0:
		top = ws.global_transform.xform(ws.get_bone_global_pose(ws.find_bone("head")).origin) + Vector3.UP * 0.55 * pet["scale"]
	var dist = camera.global_transform.origin.distance_to(top)
	if camera.is_position_behind(top) or dist > 30.0:
		label.visible = false
		return
	if label.text != name:
		label.text = name
		label.rect_size = Vector2()
	var s = clamp(8.0 / max(dist, 0.1), 0.45, 1.0)
	label.rect_scale = Vector2(s, s)
	var size = label.get_combined_minimum_size()
	label.rect_size = size
	var at = camera.unproject_position(top)
	var holder = world_view.get_parent()
	if holder is ViewportContainer and world_view.size.x > 0 and world_view.size.y > 0:
		var box = holder.get_global_rect()
		at = box.position + at * (box.size / world_view.size)
	label.rect_position = at - Vector2(size.x * s / 2.0, size.y * s)
	label.visible = true


func _apply_size(pet, size):
	size = clamp(float(size), SIZE_MIN, SIZE_MAX)
	pet["size"] = size
	pet["scale"] = SPECIES[pet["species"]]["scale"] * size
	pet["model"].scale = Vector3.ONE * pet["scale"]
	pet["spin"].translation = Vector3()
	pet["model"].translation = Vector3()
	var area = pet["area"]
	if area != null and is_instance_valid(area) and area.has_meta("shape"):
		var shape = area.get_meta("shape")
		shape.shape.radius = 0.9 * pet["scale"]
		shape.translation = Vector3(0, 0.6 * pet["scale"], 0)


# how close it stays depends on how big it is
func _near(pet):
	return FOLLOW_NEAR * (0.4 + 0.6 * pet["size"])


func _far(pet):
	return _near(pet) + FOLLOW_FAR - FOLLOW_NEAR


func _collect_meshes(node, out):
	if node is MeshInstance and node.mesh != null:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)


func _paint(pet, cfg_colors):
	for part in PARTS:
		var mat = pet["mats"].get(part[2])
		if mat != null and mat is SpatialMaterial:
			mat.albedo_color = _color_of(cfg_colors, part[0], pet["species"])


func _remove_pet(key):
	if not pets.has(key):
		return
	_end_fetch(pets[key])
	if pets[key].get("hid_sprite", false) and is_instance_valid(pets[key]["owner"]):
		var sprite = pets[key]["owner"].get("item_sprite")
		if sprite != null and is_instance_valid(sprite):
			sprite.visible = true
	var node = pets[key]["node"]
	if is_instance_valid(node):
		node.queue_free()
	var label = pets[key].get("label")
	if label != null and is_instance_valid(label):
		label.queue_free()
	pets.erase(key)


# --- moving a pet ---

func _move_pet(pet, owner_node, delta):
	var node = pet["node"]
	node.visible = owner_node.is_visible_in_tree()

	var target = owner_node.global_transform.origin
	var pos = node.global_transform.origin
	var flat = Vector3(target.x - pos.x, 0, target.z - pos.z)
	var dist = flat.length()

	# how fast its owner is going (anything that speeds them up, running, flying, boosts),
	# so it can match it; a sudden jump across the map is a teleport, not speed
	var last = pet.get("owner_last")
	pet["owner_last"] = target
	if last != null and delta > 0.0:
		var v = Vector2(target.x - last.x, target.z - last.z).length() / delta
		if v < 200.0:
			pet["owner_speed"] = lerp(pet.get("owner_speed", 0.0), v, clamp(delta * 5.0, 0.0, 1.0))
	var owner_speed = pet.get("owner_speed", 0.0)

	# a ball is out: that comes first
	if pet.get("fetch") != null:
		_fetch(pet, owner_node, delta)
		return

	# it only gives up and pops back next to its owner when it really cannot keep up, or when it's left far below
	# (or above) them while they stand on solid ground
	var height_gap = abs(node.global_transform.origin.y - _feet_y(owner_node))
	var owner_grounded = owner_node.has_method("is_on_floor") and owner_node.is_on_floor()
	if dist > max(TELEPORT_DIST, owner_speed * 2.5) or (owner_grounded and height_gap > 5.0 and pet["lap"] == ""):
		var back = Vector3(1.0, 0, 1.0).normalized() * _near(pet)
		node.global_transform.origin = _ground(node, target + back, _feet_y(owner_node))
		pet["speed"] = 0.0
		pet["still"] = 0.0
		pet["moving"] = false
		_play(pet, "wolf_idle", 1.0)
		return

	# walk when it fell behind, stop again once it is close; it hurries when far away
	# when its owner sits down it comes to lie beside them
	if _is_sitting(owner_node):
		var sit = SPECIES[pet["species"]]["sit"]
		if sit == "beside":
			_lie_beside(pet, owner_node, delta)
		else:
			_perch(pet, owner_node, delta, sit)
		return
	pet["side"] = 0
	if str(pet["key"]) == "me" and my_side != 0:
		my_side = 0
		sync_dirty = true
	# its owner stood up while it was in their lap: it hops down first
	if pet["lap"] != "" and pet["lap"] != "go":
		_hop_down(pet, owner_node, delta)
		return
	pet["lap"] = ""

	if dist > _far(pet):
		pet["moving"] = true
	elif dist < _near(pet):
		pet["moving"] = false
	var want = 0.0
	if pet["moving"]:
		# its owner's own speed plus a bit more the further behind it is, no upper limit but theirs
		var top = max(RUN_SPEED, owner_speed * 1.3 + 3.0)
		want = clamp((dist - _near(pet)) * 2.2 + owner_speed * 0.9, WALK_SPEED * 0.6, top)
	pet["speed"] = lerp(pet["speed"], want, clamp(delta * (6.0 + pet["speed"] * 0.2), 0.0, 1.0))

	var dir = flat / dist if dist > 0.001 else Vector3()
	if pet["speed"] > 0.05:
		pos += dir * min(pet["speed"] * delta, dist)
	pos = _ground(node, pos, _feet_y(owner_node), pos.y, delta)
	node.global_transform.origin = pos

	# turn to where it walks, or to its owner while standing; once it sits or lies down it stays
	# put until it gets up to follow, so its owner can sit right beside it
	var settled = pet["anim_name"] in ["wolf_sit", "wolf_lie", "cat_curl", "raccoon_flop", "raccoon_sit", "fox_curl"]
	if dist > 0.05 and (pet["speed"] > 0.3 or not settled):
		var yaw = atan2(-dir.x, -dir.z)
		node.rotation.y = lerp_angle(node.rotation.y, yaw, clamp(delta * (8.0 if pet["speed"] > 0.3 else 3.0), 0.0, 1.0))

	# idle, walk, and sit after a while of standing still
	if pet["speed"] > 0.35:
		pet["still"] = 0.0
		# the legs speed up with it, quicker still when it runs
		_locomote(pet, delta)
	else:
		pet["still"] += delta
		# lies down next to its owner while they sit, otherwise sits after a while
		if _is_sitting(owner_node):
			pet["sat"] += delta
		else:
			pet["sat"] = 0.0
		if pet["sat"] > LIE_AFTER:
			_play(pet, "wolf_lie", 1.0)
		else:
			_play(pet, "wolf_sit" if pet["still"] > SIT_AFTER else "wolf_idle", 1.0)


# walks to the owner's side (whichever side it is already on), turns the way they face and lies down
func _lie_beside(pet, owner_node, delta):
	var node = pet["node"]
	var here = owner_node.global_transform.origin
	var f = _facing(owner_node)
	var right = f.cross(Vector3.UP).normalized()
	var pos = node.global_transform.origin
	# Every player moves my pet on their own screen, so it can be on a different side of me for each of
	# them. My game picks the side (whichever one it is already on) and tells everyone; theirs follow it.
	if str(pet["key"]) != "me" and pet["told_side"] != 0:
		pet["side"] = pet["told_side"]
	elif pet["side"] == 0:
		pet["side"] = 1 if (pos - here).dot(right) >= 0 else -1
	if str(pet["key"]) == "me" and my_side != pet["side"]:
		my_side = pet["side"]
		sync_dirty = true
	# set back by the length of its neck and head, so its head lies level with its owner
	var spot = here + right * pet["side"] * (0.35 * _player_size(owner_node) + 0.42 * pet["scale"]) - f * 0.85 * pet["scale"]
	var to = Vector3(spot.x - pos.x, 0, spot.z - pos.z)
	var dist = to.length()
	if dist > 0.08:
		pet["speed"] = lerp(pet["speed"], clamp(dist * 3.0, 1.2, WALK_SPEED), clamp(delta * 6.0, 0.0, 1.0))
		pos += to / dist * min(pet["speed"] * delta, dist)
		node.global_transform.origin = _ground(node, pos, _feet_y(owner_node), pos.y, delta)
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), clamp(delta * 10.0, 0.0, 1.0))
		pet["sat"] = 0.0
		pet["still"] = 0.0
		_locomote(pet, delta)
		return
	pet["speed"] = 0.0
	node.global_transform.origin = _ground(node, spot, _feet_y(owner_node), pos.y, delta)
	node.rotation.y = lerp_angle(node.rotation.y, atan2(-f.x, -f.z), clamp(delta * 5.0, 0.0, 1.0))
	pet["sat"] += delta
	_play(pet, "wolf_lie" if pet["sat"] > LIE_AFTER else "wolf_idle", 1.0)


# moving along: walking legs, or for a roller, somersaults (the roll is in the animation itself),
# turned over just fast enough that each one carries it as far as it actually goes
func _locomote(pet, delta, speed = null):
	var v = pet["speed"] if speed == null else speed
	var info = SPECIES[pet["species"]]
	if info["move"] == "roll":
		var length = 1.0
		if pet["anim"] != null and pet["anim"].has_animation("raccoon_ball"):
			length = pet["anim"].get_animation("raccoon_ball").length
		_play(pet, "raccoon_ball", clamp(v * length / max(info["roll_dist"] * pet["scale"], 0.05), 0.4, 8.0))
	else:
		_play(pet, "wolf_walk", _stride_rate(v))


# how fast the legs go: in step with a walk or a run, and still quicker (but not silly) when it races
func _stride_rate(speed):
	if speed <= RUN_SPEED:
		return clamp(0.6 + speed * 0.45, 0.8, 4.2)
	return min(4.0 + (speed - RUN_SPEED) * 0.15, 9.0)


# --- fetch ---
# The ball is thrown on its owner's screen and the throw (where it left the hand, how fast) goes into the lobby, so
# every player's game throws the same ball and their copy of the pet fetches it. The ball moves the same everywhere
# (same throw, same ground), so the pets do the same.

# --- the Tennis Ball item ---
# A real item in the game's list, so it shows in the inventory and goes on the hotbar like the rod or the guitar.
# The game doesn't check items when it loads a save: an item it doesn't know breaks the inventory screen. So the ball
# is never in a save: it is taken out of the inventory while the pause menu is open (Save, Quit) and just before the
# autosave, and put back right after. The hotbar slot it sits on is saved, and points at nothing without the mod.

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_set_ball_in_inventory(false)


# how hard the throw will be, while the mouse button is held: a bar under the middle of the screen
const CHARGE_WIDTH = 180.0

func _build_charge_bar():
	charge_panel = PanelContainer.new()
	charge_panel.visible = false
	charge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge_panel.add_stylebox_override("panel", _glass(Color(0.06, 0.12, 0.18, 0.55), Color(0.55, 1.0, 1.0, 0.45), 8, 4))
	layer.add_child(charge_panel)
	var column = VBoxContainer.new()
	column.add_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge_panel.add_child(column)
	charge_label = Label.new()
	charge_label.text = "Throw"
	charge_label.align = Label.ALIGN_CENTER
	charge_label.add_color_override("font_color", Color(0.75, 0.95, 1.0))
	column.add_child(charge_label)
	var track = ColorRect.new()
	track.color = Color(0, 0, 0, 0.35)
	track.rect_min_size = Vector2(CHARGE_WIDTH, 10)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(track)
	charge_fill = ColorRect.new()
	charge_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge_fill.rect_size = Vector2(0, 10)
	track.add_child(charge_fill)


func _charge_power():
	if charging_since < 0:
		return 0.0
	var held = (OS.get_ticks_msec() - charging_since) / 1000.0
	return clamp(BALL_MIN_POWER + (1.0 - BALL_MIN_POWER) * held / BALL_CHARGE_TIME, BALL_MIN_POWER, 1.0)


func _update_charge_bar():
	if charging_since >= 0 and not _can_throw():
		charging_since = -1
	var show = charging_since >= 0 and _holding_ball()
	charge_panel.visible = show
	_update_arc(show)
	if not show:
		return
	var power = _charge_power()
	# the bar fills by distance (which grows with the square of the throw's speed): from a short toss to the longest
	var k = (power * power - BALL_MIN_POWER * BALL_MIN_POWER) / (1.0 - BALL_MIN_POWER * BALL_MIN_POWER)
	charge_fill.rect_size = Vector2(round(CHARGE_WIDTH * k), 10)
	# cyan while it builds, warm when it's full
	charge_fill.color = Color(0.3, 1.0, 1.0, 0.85).linear_interpolate(Color(1.0, 0.75, 0.3, 0.95), k)
	charge_label.text = "Throw: max!" if k >= 0.999 else "Throw"
	var area = get_viewport().get_visible_rect().size
	charge_panel.rect_size = Vector2()
	var size = charge_panel.get_combined_minimum_size()
	charge_panel.rect_position = Vector2(round((area.x - size.x) / 2.0), round(area.y * 0.62))


# The arc the ball will fly, worked out with the same steps the real ball takes, up to where it first touches down.
# Only on my screen.
func _update_arc(show):
	var pet = pets.get("me")
	if show and (pet == null or pet.get("fetch") != null or not is_instance_valid(pet["owner"])):
		show = false # no ball to throw right now
	if not show:
		if arc_node != null and is_instance_valid(arc_node):
			arc_node.visible = false
			land_node.visible = false
		return
	var owner_node = pet["owner"]
	var parent = owner_node.get_parent()
	if arc_node == null or not is_instance_valid(arc_node) or arc_node.get_parent() != parent:
		_make_arc(parent)
	var space = owner_node.get_world().direct_space_state if owner_node.get_world() != null else null
	var throw = _throw_from(owner_node, _charge_power())
	var f = {"pos": throw[0], "vel": throw[1], "still": 0.0, "resting": false, "left": 0.0, "start_y": throw[0].y, "hit": false}
	var points = [f["pos"]]
	var landed = false
	for i in range(360): # 6 seconds of flight at most
		_ball_step(f, space)
		points.append(f["pos"])
		if f["hit"]:
			landed = true
			break
	# the dots, spread evenly along the path
	var mm = arc_node.multimesh
	var count = min(ARC_DOTS, points.size())
	mm.visible_instance_count = count
	for i in range(count):
		var at = points[int(round(float(i) / max(1, count - 1) * (points.size() - 1)))]
		mm.set_instance_transform(i, Transform(Basis(), at))
	arc_node.visible = true
	land_node.visible = landed
	if landed:
		var n = f["hit_normal"].normalized()
		var side = n.cross(Vector3.FORWARD if abs(n.z) < 0.9 else Vector3.RIGHT).normalized()
		land_node.global_transform = Transform(Basis(side, n, side.cross(n)), f["hit_at"] + n * 0.03)


func _make_arc(parent):
	if arc_node != null and is_instance_valid(arc_node):
		arc_node.queue_free()
		land_node.queue_free()
	var dot_mat = SpatialMaterial.new()
	dot_mat.flags_unshaded = true
	dot_mat.flags_transparent = true
	dot_mat.albedo_color = Color(0.55, 1.0, 1.0, 0.85)
	var dot = SphereMesh.new()
	dot.radius = 0.045
	dot.height = 0.09
	dot.radial_segments = 8
	dot.rings = 4
	dot.material = dot_mat
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = dot
	mm.instance_count = ARC_DOTS
	arc_node = MultiMeshInstance.new()
	arc_node.name = "EtherBallArc"
	arc_node.multimesh = mm
	arc_node.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(arc_node)
	arc_node.global_transform = Transform()

	var land_mat = SpatialMaterial.new()
	land_mat.flags_unshaded = true
	land_mat.flags_transparent = true
	land_mat.albedo_color = Color(1.0, 0.75, 0.3, 0.6)
	var disc = CylinderMesh.new()
	disc.top_radius = 0.35
	disc.bottom_radius = 0.35
	disc.height = 0.02
	disc.radial_segments = 24
	disc.material = land_mat
	land_node = MeshInstance.new()
	land_node.name = "EtherBallLanding"
	land_node.mesh = disc
	land_node.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	parent.add_child(land_node)


func _register_ball_item():
	var globals = get_node_or_null("/root/Globals")
	if globals == null or typeof(globals.get("item_data")) != TYPE_DICTIONARY:
		return false
	if globals.item_data.has(BALL_ITEM):
		return true
	var script = load("res://Resources/Scripts/item_resource.gd")
	if script == null:
		return false
	var res = script.new()
	res.item_name = "Tennis Ball"
	res.item_description = "Throw it and your pet brings it back! Hold the mouse button to throw further, the bar shows how far. (EtherPets)"
	res.help_text = "throw (hold for further)"
	res.icon = _ball_icon()
	res.show_item = true
	res.show_scene = false
	res.uses_size = false
	res.action = ""          # the mod throws it, the game itself does nothing on a click
	res.category = "tool"
	res.unselectable = true  # can't be mailed or gifted to someone who may not have the mod
	res.unrenamable = true
	res.can_be_sold = false
	res.generate_worth = false
	res.sell_value = 0
	res.loot_table = "none"
	res.obtain_xp = 0
	res.stackable = false
	res.unobtainable = false
	res.alive = false
	res.average_size = 1.0   # its size is 1: no "Microscopic" in front of the name
	globals.item_data[BALL_ITEM] = {"file": res}
	return true


# a tennis ball drawn into a texture: yellow-green with the white seam
func _ball_icon():
	if ball_icon != null:
		return ball_icon
	var size = 64
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	img.lock()
	var c = Vector2(size, size) / 2.0
	var r = size * 0.42
	for y in range(size):
		for x in range(size):
			var p = Vector2(x + 0.5, y + 0.5)
			var d = p.distance_to(c)
			if d > r + 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col = Color(0.82, 0.93, 0.25)
			# shading, lighter toward the top left
			var light = clamp(1.15 - (p - (c - Vector2(r, r) * 0.35)).length() / (r * 2.2), 0.65, 1.15)
			col = Color(col.r * light, col.g * light, col.b * light)
			# the seam: two curves facing away from each other
			var q = (p - c) / r
			var seam = abs(abs(q.x) - (0.55 + 0.35 * q.y * q.y))
			if seam < 0.07:
				col = Color(0.97, 0.97, 0.92)
			if d > r - 1.5:
				col = Color(0.35, 0.42, 0.1) # outline
			col.a = clamp(r + 1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, col)
	img.unlock()
	ball_icon = ImageTexture.new()
	ball_icon.create_from_image(img, Texture.FLAG_FILTER)
	return ball_icon


func _ball_entry_index():
	var data = get_node_or_null("/root/PlayerData")
	if data == null:
		return -1
	for i in range(data.inventory.size()):
		var item = data.inventory[i]
		if typeof(item) == TYPE_DICTIONARY and item.get("id") == BALL_ITEM:
			return i
	return -1


func _set_ball_in_inventory(want):
	var data = get_node_or_null("/root/PlayerData")
	if data == null or typeof(data.get("inventory")) != TYPE_ARRAY:
		return
	var at = _ball_entry_index()
	if want and at < 0:
		if not _register_ball_item():
			return
		# straight into the list: the game's own add would treat a new item as "just caught"
		data.inventory.append({"id": BALL_ITEM, "ref": BALL_REF, "size": 1.0, "quality": 0, "tags": [], "custom_name": "", "count": 1})
		data.emit_signal("_inventory_refresh")
	elif not want and at >= 0:
		# taken out of the list only, the hotbar keeps its slot (PlayerData._remove_item would clear it)
		while at >= 0:
			data.inventory.remove(at)
			at = _ball_entry_index()
		data.emit_signal("_inventory_refresh")


# in the inventory while playing; out of it whenever the game may save
func _keep_ball_item():
	var want = false
	var hud = _get_hud()
	var world = get_tree().get_nodes_in_group("world")
	if hud != null and not world.empty():
		want = hud.get("menu") != 3 # MENUS.ESC: its Save and Quit buttons save the game
		var timer = world[0].get_node_or_null("autosave_timer")
		if timer != null and not timer.is_stopped() and timer.time_left < 1.5:
			want = false
	_set_ball_in_inventory(want)
	if not _holding_ball():
		charging_since = -1


func _holding_ball():
	var players = get_tree().get_nodes_in_group("controlled_player")
	if players.empty():
		return false
	var held = players[0].get("held_item")
	return typeof(held) == TYPE_DICTIONARY and held.get("id") == BALL_ITEM


# Players without EtherPets don't know the ball: their game shows an error and keeps showing whatever I held before.
# So they are told I'm holding nothing (once, and again to anyone who joins while I hold it).
func _hide_ball_from_others(lobby, net):
	if not _holding_ball() or lobby <= 0 or net == null or steam == null:
		told_no_mod = {}
		return
	var players = get_tree().get_nodes_in_group("controlled_player")
	var actor_id = players[0].get("actor_id")
	if actor_id == null or int(actor_id) < 0:
		return
	var members = net.get("LOBBY_MEMBERS")
	if typeof(members) != TYPE_ARRAY:
		return
	for member in members:
		var id = int(member.get("steam_id", 0))
		if id <= 0 or id == int(net.STEAM_ID) or told_no_mod.has(id):
			continue
		if str(steam.getLobbyMemberData(lobby, id, SYNC_KEY)) != "":
			continue # has the mod, sees the ball
		told_no_mod[id] = true
		net._send_P2P_Packet({"type": "actor_action", "actor_id": int(actor_id), "action": "_update_held_item",
			"params": [{"id": "empty_hand", "ref": 0, "size": 1.0, "quality": 0, "tags": []}]}, str(id), 2, net.CHANNELS.ACTOR_ACTION)


# only while nothing else is open (the game's own menus, a popup)
func _hud_free():
	var hud = _get_hud()
	if hud == null:
		return false
	if hud.get("menu") != 0 or hud.get("hud_hidden") == true:
		return false
	var popups = hud.get("popups")
	return typeof(popups) != TYPE_ARRAY or popups.empty()


# my pet is out and free to fetch: one ball at a time, it has to bring it back first
func _can_throw():
	if not pets.has("me") or not show_pet:
		return false
	var pet = pets["me"]
	return is_instance_valid(pet["owner"]) and pet["pat"] == null and pet.get("fetch") == null


func _throw_ball(power = 1.0):
	if not _can_throw():
		return false
	var pet = pets["me"]
	var owner_node = pet["owner"]
	var now = OS.get_ticks_msec()
	if now - last_throw < THROW_COOLDOWN_MS:
		return false
	last_throw = now

	var throw = _throw_from(owner_node, power)
	var from = throw[0]
	var velocity = throw[1]

	my_ball_seq += 1
	var net = get_node_or_null("/root/Network")
	if steam != null and steam.has_method("setLobbyMemberData") and net != null and not net.PLAYING_OFFLINE and net.STEAM_LOBBY_ID > 0:
		steam.setLobbyMemberData(net.STEAM_LOBBY_ID, BALL_KEY, "1;" + str(my_ball_seq) + ";" + _vec_text(from) + ";" + _vec_text(velocity))
	_start_fetch(pet, from, velocity)
	return true


# where the ball leaves the hand and how fast: along where the camera looks, aiming higher throws further
func _throw_from(owner_node, power):
	var flat = _facing(owner_node)
	var pitch = 0.0
	var camera = owner_node.get_viewport().get_camera() if owner_node.get_viewport() != null else null
	if camera != null:
		var aim = -camera.global_transform.basis.z
		if Vector2(aim.x, aim.z).length() > 0.05:
			flat = Vector3(aim.x, 0, aim.z).normalized()
		pitch = asin(clamp(aim.y, -1.0, 1.0))
	var up = clamp(pitch + deg2rad(20.0), deg2rad(5.0), deg2rad(70.0))
	var velocity = (flat * cos(up) + Vector3.UP * sin(up)) * BALL_SPEED * power
	var size = _player_size(owner_node)
	var from = owner_node.global_transform.origin + Vector3.UP * 0.35 * size + flat * 0.45 * size
	return [from, velocity]


func _vec_text(v):
	return "%.3f,%.3f,%.3f" % [v.x, v.y, v.z]


func _text_vec(text):
	var bits = str(text).split(",")
	if bits.size() != 3 or not bits[0].is_valid_float() or not bits[1].is_valid_float() or not bits[2].is_valid_float():
		return null
	return Vector3(float(bits[0]), float(bits[1]), float(bits[2]))


func _read_remote_balls(lobby):
	if lobby <= 0 or steam == null or not steam.has_method("getLobbyMemberData"):
		return
	for key in pets.keys():
		if typeof(key) != TYPE_INT:
			continue
		var bits = str(steam.getLobbyMemberData(lobby, key, BALL_KEY)).split(";")
		if bits.size() < 4 or bits[0] != "1" or not bits[1].is_valid_integer():
			continue
		var seq = int(bits[1])
		# the first time I see someone's pet, their last throw is old news
		if not ball_seen.has(key):
			ball_seen[key] = seq
			continue
		if seq == ball_seen[key]:
			continue
		ball_seen[key] = seq
		var from = _text_vec(bits[2])
		var velocity = _text_vec(bits[3])
		if from == null or velocity == null or velocity.length() > 40.0:
			continue
		_start_fetch(pets[key], from, velocity)


func _start_fetch(pet, from, velocity):
	_end_fetch(pet)
	var parent = pet["node"].get_parent()
	if parent == null:
		return
	var ball = _make_ball()
	parent.add_child(ball)
	ball.global_transform.origin = from
	pet["fetch"] = {"ball": ball, "pos": from, "vel": velocity, "state": "free", "t": 0.0, "still": 0.0,
		"resting": false, "start_y": from.y, "left": 0.0, "acc": 0.0}


func _end_fetch(pet):
	var f = pet.get("fetch")
	if f == null:
		return
	if is_instance_valid(f["ball"]):
		f["ball"].queue_free()
	pet["fetch"] = null


# a tennis ball: yellow-green, with a shadow under it like everything else in the game
func _make_ball():
	var root = Spatial.new()
	root.name = "EtherBall"
	var mesh = MeshInstance.new()
	mesh.name = "Mesh"
	var sphere = SphereMesh.new()
	sphere.radius = BALL_RADIUS
	sphere.height = BALL_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh.mesh = sphere
	if ball_material == null:
		ball_material = SpatialMaterial.new()
		ball_material.albedo_color = Color(0.82, 0.93, 0.25)
		ball_material.roughness = 0.9
	mesh.material_override = ball_material
	root.add_child(mesh)
	if shadow_scene != null:
		var shadow = shadow_scene.instance()
		shadow.scale = Vector3.ONE * 0.35
		root.add_child(shadow)
	return root


# the ball flying, bouncing and rolling, in small fixed steps so it lands the same on every screen
func _move_ball(f, space, delta):
	f["acc"] += min(delta, 0.1)
	while f["acc"] >= BALL_STEP:
		f["acc"] -= BALL_STEP
		if f["resting"]:
			break
		_ball_step(f, space)
	var ball = f["ball"]
	if is_instance_valid(ball):
		var mesh = ball.get_node_or_null("Mesh")
		var flat = Vector3(f["vel"].x, 0, f["vel"].z)
		if mesh != null and flat.length() > 0.05 and not f["resting"]:
			mesh.rotate(flat.normalized().cross(Vector3.UP).normalized(), -flat.length() * delta / BALL_RADIUS)
		ball.global_transform.origin = f["pos"]


# one 1/60 s step of the ball: the throw, the preview arc and every other player's copy all use this
func _ball_step(f, space):
	var v = f["vel"]
	v.y -= BALL_GRAVITY * BALL_STEP
	var from = f["pos"]
	var to = from + v * BALL_STEP
	var reach = v.normalized() * BALL_RADIUS if v.length() > 0.001 else Vector3()
	var hit = space.intersect_ray(from, to + reach, [], 1 | 2) if space != null else {}
	if hit.empty() and space != null and v.y <= 0.0:
		# resting on or rolling along the ground
		var below = space.intersect_ray(to, to + Vector3(0, -BALL_RADIUS - 0.02, 0), [], 1 | 2)
		if not below.empty():
			hit = below
	f["hit"] = not hit.empty()
	if not hit.empty():
		f["hit_at"] = hit["position"]
		f["hit_normal"] = hit["normal"]
		if not f.has("first_hit"):
			f["first_hit"] = hit["position"]
		var n = hit["normal"]
		to = hit["position"] + n * BALL_RADIUS
		var into = v.dot(n)
		if into < 0.0:
			var along = v - n * into
			if -into > 1.5:
				v = along * 0.8 - n * into * BALL_BOUNCE # a bounce
			else:
				v = along * (1.0 - min(1.0, 2.5 * BALL_STEP)) # rolling, slowing down
		if n.y > 0.6 and v.length() < 0.25:
			f["still"] += BALL_STEP
		else:
			f["still"] = 0.0
	else:
		f["still"] = 0.0
	f["pos"] = to
	f["vel"] = v
	f["left"] += BALL_STEP
	if f["still"] > 0.3 or f["left"] > 10.0:
		f["resting"] = true
	if f["pos"].y < f["start_y"] - 60.0:
		f["resting"] = true
		f["lost"] = true


# The ball can't be in the hand and out on the grass: the held ball is hidden while the pet has it (on every screen
# with the mod, for every player), and shows again when it's brought back. Only the ball is ever hidden.
func _hide_held_ball(pet, owner_node):
	var sprite = owner_node.get("item_sprite")
	if sprite == null or not is_instance_valid(sprite):
		return
	var held = owner_node.get("held_item")
	var holding = typeof(held) == TYPE_DICTIONARY and held.get("id") == BALL_ITEM
	var f = pet.get("fetch")
	var hide = holding and f != null and f["state"] in ["free", "carry"]
	if hide and sprite.visible:
		sprite.visible = false
		pet["hid_sprite"] = true
	elif not hide and pet.get("hid_sprite", false):
		sprite.visible = true
		pet["hid_sprite"] = false


# where the ball sits when the pet carries it
func _mouth(pet):
	var ws = pet["skeleton"]
	if ws == null or not is_instance_valid(ws) or ws.find_bone("head") < 0:
		return pet["node"].global_transform.origin + _facing(pet["node"]) * 1.2 * pet["scale"] + Vector3.UP * 0.8 * pet["scale"]
	var local = MOUTH.get(pet["species"], MOUTH["wolf"])
	return ws.global_transform.xform(ws.get_bone_global_pose(ws.find_bone("head")).xform(local))


# runs (or rolls) toward a spot; true once it is within stop of it
func _run_to(pet, target, stop, speed, fallback_y, delta):
	var node = pet["node"]
	var pos = node.global_transform.origin
	var to = Vector3(target.x - pos.x, 0, target.z - pos.z)
	var dist = to.length()
	if dist <= stop + 0.05: # a little slack, each step only closes part of the gap
		pet["speed"] = lerp(pet["speed"], 0.0, clamp(delta * 10.0, 0.0, 1.0))
		if dist > 0.05:
			node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), clamp(delta * 8.0, 0.0, 1.0))
		node.global_transform.origin = _ground(node, pos, fallback_y, pos.y, delta)
		return true
	var want = clamp((dist - stop) * 3.0, WALK_SPEED * 0.6, speed)
	pet["speed"] = lerp(pet["speed"], want, clamp(delta * 6.0, 0.0, 1.0))
	pos += to / dist * min(pet["speed"] * delta, dist - stop)
	node.global_transform.origin = _ground(node, pos, fallback_y, pos.y, delta)
	node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), clamp(delta * 10.0, 0.0, 1.0))
	pet["still"] = 0.0
	pet["sat"] = 0.0
	_locomote(pet, delta)
	return false


func _fetch(pet, owner_node, delta):
	var f = pet["fetch"]
	var node = pet["node"]
	if not is_instance_valid(f["ball"]):
		pet["fetch"] = null
		return
	var space = node.get_world().direct_space_state if node.get_world() != null else null
	f["t"] += delta
	var speed = max(FETCH_SPEED * (0.7 + 0.3 * pet["size"]), pet.get("owner_speed", 0.0) * 1.3 + 3.0)

	# in a lap or on a head: down first
	if pet["lap"] != "" and pet["lap"] != "go":
		_move_ball(f, space, delta)
		_hop_down(pet, owner_node, delta)
		return
	pet["lap"] = ""
	pet["side"] = 0

	if f["state"] == "free":
		_move_ball(f, space, delta)
		# out of reach (in the sea, off a cliff, too long): it lets it go and comes back
		if f.get("lost", false) or f["t"] > FETCH_GIVE_UP:
			_end_fetch(pet)
			return
		# it watches the ball fly for a moment first, so it doesn't snatch it out of the air at its owner's side
		if f["t"] < FETCH_WAIT:
			_run_to(pet, f["pos"], 100000.0, 0.0, _feet_y(owner_node), delta)
			_play(pet, "wolf_idle", 1.0)
			return
		var ground_y = _ground(node, f["pos"], f["pos"].y)
		var reach = 1.1 * pet["scale"] + 0.15
		var low = f["pos"].y - ground_y.y < 0.45 * pet["scale"] + 0.2
		if _run_to(pet, f["pos"], reach * 0.8, speed, f["pos"].y, delta):
			if low:
				f["state"] = "carry" # got it
			else:
				_play(pet, "wolf_idle", 1.0) # waiting for it to come down
		return

	if f["state"] == "carry":
		f["ball"].global_transform.origin = _mouth(pet)
		var home = owner_node.global_transform.origin
		if Vector2(home.x - node.global_transform.origin.x, home.z - node.global_transform.origin.z).length() > 80.0:
			_end_fetch(pet) # its owner went somewhere else entirely
			return
		# close enough that the ball drops at its owner's feet
		var at_feet = 1.15 * pet["scale"] + 0.45 * _player_size(owner_node)
		if _run_to(pet, home, at_feet, speed, _feet_y(owner_node), delta):
			# dropped at its owner's feet, a happy wiggle and its happy sound (the one it makes when petted),
			# and the ball is back in their hand
			f["state"] = "drop"
			var info = SPECIES[pet["species"]]
			_say(pet, sounds.get(info["pet_sound"]), info["pet_pitch"])
			f["t"] = 0.0
			f["pos"] = _mouth(pet)
			f["vel"] = _facing(node) * 0.6
			f["resting"] = false
			f["still"] = 0.0
			f["left"] = 0.0
		return

	if f["state"] == "drop":
		_move_ball(f, space, delta)
		_run_to(pet, owner_node.global_transform.origin, 1000.0, 0.0, _feet_y(owner_node), delta)
		_play(pet, "wolf_happy", 1.0)
		if f["t"] > 1.4:
			_end_fetch(pet)
			pet["still"] = 0.0


# --- in its owner's lap (a cat) or on their head (a raccoon) ---

const LAP_HOP_TIME = 0.45
const LAP_FORWARD = 0.22   # how far in front of the thighs' middle it lies, times the player's size
const LAP_DROP = 0.05      # how far below the thighs' middle its belly sits, so it rests on the lap
const CURL_CENTRE = Vector3(-0.253, 0, -0.128) # middle of the curled-up cat, from its origin, at size 1
const HEAD_TOP = 0.94      # from a player's head bone up to the top of their head, times their size
const HEAD_BACK = 0.18 # how far behind the head bone the middle of the head is (times the player's size)
const PERCH = {
	"lap": {"anim": "cat_curl", "turn": -PI / 2.0, "hop": 0.15},
	"head": {"anim": "raccoon_flop", "turn": 0.0, "hop": 0.6},
}


# the top of a sitting player's thighs, from their skeleton, whatever their size
func _lap_point(owner_node):
	var size = _player_size(owner_node)
	var sk = owner_node.get_node_or_null(SKELETON_PATH)
	if sk != null:
		var pts = []
		for name in ["leg.l", "foot.l", "leg.r", "foot.r"]:
			var b = sk.find_bone(name)
			if b >= 0:
				pts.append(sk.global_transform.xform(sk.get_bone_global_pose(b).origin))
		if pts.size() == 4:
			var mid = (pts[0] + pts[1] + pts[2] + pts[3]) / 4.0
			return mid - Vector3.UP * LAP_DROP * size
	return owner_node.global_transform.origin + _facing(owner_node) * 0.25 * size + Vector3.UP * (0.35 * size - owner_node.global_transform.basis.y.length())


func _head_top(owner_node):
	var size = _player_size(owner_node)
	var sk = owner_node.get_node_or_null(SKELETON_PATH)
	if sk != null and sk.find_bone("head") >= 0:
		var head = sk.global_transform.xform(sk.get_bone_global_pose(sk.find_bone("head")).origin)
		return head + Vector3.UP * HEAD_TOP * size
	return owner_node.global_transform.origin + Vector3.UP * 1.0 * size


# where its origin goes: a cat with the middle of its curl on the lap, lying across it;
# a raccoon flopped belly-down on top of the head, facing the same way as its owner
func _perch_spot(pet, owner_node, mode):
	var yaw = atan2(-_facing(owner_node).x, -_facing(owner_node).z) + PERCH[mode]["turn"]
	if mode == "head":
		# the head bone sits toward the face, so shift back to put its belly over the middle of the head
		var spot = _head_top(owner_node) - _facing(owner_node) * HEAD_BACK * _player_size(owner_node)
		var centre = SPECIES[pet["species"]].get("perch_centre", Vector3.ZERO)   # put the middle of a curl over the head
		return [spot - Basis(Vector3.UP, yaw).xform(centre * pet["scale"]), yaw]
	var basis = Basis(Vector3.UP, yaw)
	# a little forward of the thighs' middle, so it lies on the lap and not inside its owner
	var forward = _facing(owner_node) * LAP_FORWARD * _player_size(owner_node)
	return [_lap_point(owner_node) + forward - basis.xform(CURL_CENTRE * pet["scale"]), yaw]


# goes up to its sitting owner, hops up (into the lap or onto the head) and settles there
func _perch(pet, owner_node, delta, mode):
	var node = pet["node"]
	if pet["lap"] == "" or pet["lap"] == "down":
		pet["lap"] = "go"
	if pet["lap"] == "go":
		var here = owner_node.global_transform.origin
		var size = _player_size(owner_node)
		var spot = here + _facing(owner_node) * (0.45 * size + 0.5 * pet["scale"])
		var pos = node.global_transform.origin
		var to = Vector3(spot.x - pos.x, 0, spot.z - pos.z)
		var dist = to.length()
		if dist > 0.1:
			pet["speed"] = lerp(pet["speed"], clamp(dist * 3.0, 1.2, WALK_SPEED), clamp(delta * 6.0, 0.0, 1.0))
			pos += to / dist * min(pet["speed"] * delta, dist)
			node.global_transform.origin = _ground(node, pos, _feet_y(owner_node), pos.y, delta)
			node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), clamp(delta * 10.0, 0.0, 1.0))
			_locomote(pet, delta)
			return
		pet["speed"] = 0.0
		pet["lap"] = "hop"
		pet["hop_t"] = 0.0
		pet["hop_from"] = node.global_transform.origin
	var target = _perch_spot(pet, owner_node, mode)
	if pet["lap"] == "hop":
		pet["hop_t"] += delta
		var k = clamp(pet["hop_t"] / SPECIES[pet["species"]].get("hop_time", LAP_HOP_TIME), 0.0, 1.0)
		var arc = sin(k * PI) * (0.25 * pet["scale"] + PERCH[mode]["hop"] * _player_size(owner_node))
		node.global_transform.origin = pet["hop_from"].linear_interpolate(target[0], k) + Vector3.UP * arc
		node.rotation.y = lerp_angle(node.rotation.y, target[1], k)
		_play(pet, SPECIES[pet["species"]].get("hop_anim", "wolf_sit"), 1.0)
		if k >= 1.0:
			pet["lap"] = "in"
		return
	# settled, staying with its owner as they move about in their seat
	node.global_transform.origin = target[0]
	node.rotation.y = lerp_angle(node.rotation.y, target[1], clamp(delta * 8.0, 0.0, 1.0))
	_play(pet, SPECIES[pet["species"]].get("perch_anim", PERCH[mode]["anim"]), 1.0)


func _hop_down(pet, owner_node, delta):
	var node = pet["node"]
	if pet["lap"] != "down":
		pet["lap"] = "down"
		pet["hop_t"] = 0.0
		pet["hop_from"] = node.global_transform.origin
	var size = _player_size(owner_node)
	var spot = owner_node.global_transform.origin + _facing(owner_node) * (0.45 * size + 0.5 * pet["scale"])
	spot = _ground(node, spot, _feet_y(owner_node))
	pet["hop_t"] += delta
	var k = clamp(pet["hop_t"] / LAP_HOP_TIME, 0.0, 1.0)
	node.global_transform.origin = pet["hop_from"].linear_interpolate(spot, k) + Vector3.UP * sin(k * PI) * (0.2 + 0.2 * pet["scale"])
	_play(pet, "wolf_idle", 1.0)
	if k >= 1.0:
		pet["lap"] = ""
		pet["still"] = 0.0


func _is_sitting(player):
	var data = player.get("animation_data")
	if typeof(data) == TYPE_DICTIONARY and data.get("sitting") == true:
		return true
	return player.get("sitting") == true and player.get("controlled") == true


# a player's origin is at the middle of their body, a metre (times their size) above their feet
func _feet_y(player):
	return player.global_transform.origin.y - player.global_transform.basis.y.length()


# how big a player is drawn, whatever made them bigger or smaller
func _player_size(player):
	var skel = player.get_node_or_null(SKELETON_PATH)
	if skel != null:
		return skel.global_transform.basis.get_scale().y
	return player.global_transform.basis.get_scale().y


func _facing(node):
	var f = -node.global_transform.basis.z
	f.y = 0
	return f.normalized() if f.length() > 0.001 else Vector3(0, 0, -1)


# the floor under a spot; when there is none it keeps to its owner's height
func _ground(node, pos, fallback_y, current_y = null, delta = 0.0):
	var y = fallback_y
	var space = node.get_world().direct_space_state if node.get_world() != null else null
	if space != null:
		# Looks down from above whichever is higher, the pet or where it's going (its owner's feet): looking only from
		# its own height, a pet following its owner up a ladder or a blue mushroom started inside the cliff, found no
		# ground and stayed down there, inside the ground.
		var top = max(pos.y, fallback_y) + 1.5
		var bottom = min(pos.y, fallback_y) - 4.0
		var hit = space.intersect_ray(Vector3(pos.x, top, pos.z), Vector3(pos.x, bottom, pos.z), [], 1 | 2)
		if not hit.empty():
			y = hit["position"].y
	if current_y != null:
		y = lerp(current_y, y, clamp(delta * 12.0, 0.0, 1.0))
	return Vector3(pos.x, y, pos.z)


func _play(pet, name, rate):
	var anim = pet["anim"]
	if anim == null:
		return
	name = SPECIES[pet["species"]].get("anims", {}).get(name, name)
	anim.playback_speed = rate
	if pet["anim_name"] != name and anim.has_animation(name):
		pet["anim_name"] = name
		anim.play(name, 0.3)


# --- petting ---

# the game's interact key on a pet
func _on_pet_activated(pet_key, actor):
	if actor == null or actor.get("controlled") != true or pats.has("me") or not pets.has(pet_key):
		return
	if pets[pet_key]["pat"] != null:
		return # someone is already petting it
	_start_pat("me", actor, pet_key)
	my_pat_seq += 1
	_send_pat(str(_owner_steam_id(pet_key)) + ";" + str(my_pat_seq))


func _owner_steam_id(pet_key):
	if str(pet_key) == "me":
		var net = get_node_or_null("/root/Network")
		return net.STEAM_ID if net != null else 0
	return pet_key


func _send_pat(text):
	var net = get_node_or_null("/root/Network")
	if steam == null or net == null or net.PLAYING_OFFLINE or net.STEAM_LOBBY_ID <= 0:
		return
	if steam.has_method("setLobbyMemberData"):
		steam.setLobbyMemberData(net.STEAM_LOBBY_ID, PAT_KEY, text)


func _read_remote_pats(lobby, net):
	if lobby <= 0 or steam == null or not steam.has_method("getLobbyMemberData") or net == null:
		return
	for player in get_tree().get_nodes_in_group("player"):
		if not _is_real_player(player) or player.get("controlled") == true:
			continue
		var id = player.get("owner_id")
		var text = str(steam.getLobbyMemberData(lobby, id, PAT_KEY))
		if text == str(remote_pat_seen.get(id, "")):
			continue
		remote_pat_seen[id] = text
		if text == "":
			if pats.has(id):
				_end_pat(id, false)
			continue
		var bits = text.split(";")
		var owner = int(bits[0])
		var pet_key = "me" if owner == int(net.STEAM_ID) else owner
		if pets.has(pet_key):
			_start_pat(id, player, pet_key)


func _start_pat(petter_key, petter, pet_key):
	for k in pats.keys():
		if str(pats[k]["pet_key"]) == str(pet_key) or str(k) == str(petter_key):
			_drop_pat(k)
	pats[petter_key] = {"petter": petter, "pet_key": pet_key, "phase": "approach", "t": 0.0, "w": 0.0,
		"start": petter.global_transform.origin, "lean": 0.0, "neck": 0.0, "low": false,
		"head_off": 0.75 * pets[pet_key]["scale"]}
	pets[pet_key]["pat"] = petter_key


# winds the petting down smoothly, or drops it at once
func _end_pat(petter_key, at_once):
	if not pats.has(petter_key):
		return
	if str(petter_key) == "me":
		_send_pat("")
	if at_once:
		_drop_pat(petter_key)
	elif pats[petter_key]["phase"] != "out":
		pats[petter_key]["phase"] = "out"


func _drop_pat(petter_key):
	var pat = pats.get(petter_key)
	if pat == null:
		return
	_clear_pose(pat)
	if pets.has(pat["pet_key"]) and str(pets[pat["pet_key"]]["pat"]) == str(petter_key):
		var pet = pets[pat["pet_key"]]
		pet["pat"] = null
		pet["still"] = 0.0
		pet["moving"] = false
	pats.erase(petter_key)


# lets go of the bones this petting bent
func _clear_pose(pat):
	var petter = pat["petter"]
	if is_instance_valid(petter):
		var sk = petter.get_node_or_null(SKELETON_PATH)
		if sk != null:
			for name in ["torso", "arm.r"]:
				var b = sk.find_bone(name)
				if b >= 0:
					sk.set_bone_global_pose_override(b, Transform(), 0.0, true)
	if pets.has(pat["pet_key"]):
		var ws = pets[pat["pet_key"]]["skeleton"]
		if ws != null and is_instance_valid(ws) and ws.find_bone("neck") >= 0:
			ws.set_bone_global_pose_override(ws.find_bone("neck"), Transform(), 0.0, true)


func _update_pats(delta):
	for k in pats.keys():
		var pat = pats[k]
		var petter = pat["petter"]
		if not is_instance_valid(petter) or not pets.has(pat["pet_key"]) or not is_instance_valid(pets[pat["pet_key"]]["node"]):
			_end_pat(k, true)
			continue
		var pet = pets[pat["pet_key"]]
		pat["t"] += delta

		# walking away or sitting down stops it
		var here = petter.global_transform.origin
		var moved = Vector2(here.x - pat["start"].x, here.z - pat["start"].z).length()
		if pat["phase"] != "out" and (moved > 0.5 * _player_size(petter) or _is_sitting(petter)):
			_end_pat(k, pat["phase"] == "approach")
			if not pats.has(k):
				continue

		var size = _player_size(petter)
		var fwd = _facing(petter)
		var node = pet["node"]
		# the pet stands right in front of the player, facing them, its head within reach
		var spot = here + fwd * (0.37 * size + pat["head_off"])
		spot = _ground(node, spot, _feet_y(petter))
		var face_yaw = atan2(fwd.x, fwd.z) # looking back at the player

		if pat["phase"] == "approach":
			var pos = node.global_transform.origin
			var to = Vector3(spot.x - pos.x, 0, spot.z - pos.z)
			var dist = to.length()
			if dist < 0.08 or pat["t"] > 4.0:
				node.global_transform.origin = spot
				pat["phase"] = "pet"
				var info = SPECIES[pet["species"]]
				_say(pet, sounds.get(info["pet_sound"]), info["pet_pitch"])
				pat["t"] = 0.0
			else:
				var step = min(WALK_SPEED * delta, dist)
				pos += to / dist * step
				node.global_transform.origin = _ground(node, pos, spot.y, pos.y, delta)
				node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), clamp(delta * 10.0, 0.0, 1.0))
				_locomote(pet, delta, WALK_SPEED)
			continue

		node.rotation.y = lerp_angle(node.rotation.y, face_yaw, clamp(delta * 8.0, 0.0, 1.0))
		node.global_transform.origin = node.global_transform.origin.linear_interpolate(spot, clamp(delta * 4.0, 0.0, 1.0))
		# for a very small player it lies down so its head comes down to them
		_play(pet, "wolf_lie" if pat["low"] else "wolf_happy", 1.0)
		if pat["phase"] == "pet":
			pat["w"] = min(1.0, pat["w"] + delta * 3.0)
			if pat["t"] > PAT_TIME:
				_end_pat(k, false)
		else:
			pat["w"] -= delta * 3.0
			if pat["w"] <= 0.0:
				_drop_pat(k)
				continue
		_pose_pat(pat, pet, petter, size)


# the size-aware part: the pet lifts or lowers its head toward the player's hand height, and the
# player leans forward (or straightens up, or reaches up when small) until their hand meets its head
func _pose_pat(pat, pet, petter, size):
	var w = clamp(pat["w"], 0.0, 1.0)
	var sk = petter.get_node_or_null(SKELETON_PATH)
	var ws = pet["skeleton"]
	if sk == null or ws == null or not is_instance_valid(ws):
		return
	var torso = sk.find_bone("torso")
	var arm = sk.find_bone("arm.r")
	var elbow = sk.find_bone("elbow.r")
	var hand = sk.find_bone("hand.r")
	var neck = ws.find_bone("neck")
	var head = ws.find_bone("head")
	if torso < 0 or arm < 0 or elbow < 0 or hand < 0 or neck < 0 or head < 0:
		return
	var W = sk.global_transform
	var shoulder_w = W.xform(sk.get_bone_global_pose_no_override(arm).origin)

	# the pet's head: tip it down for a small player, up for a big one
	var WW = ws.global_transform
	var pet_fwd = _facing(pet["node"])
	var pet_axis = Vector3.UP.cross(pet_fwd).normalized() # turning about this moves the head down
	var g_neck = ws.get_bone_global_pose_no_override(neck)
	var pivot = WW.xform(g_neck.origin)
	var ps = pet["scale"]
	var forehead = WW.xform(ws.get_bone_global_pose_no_override(head).origin) + pet_fwd * 0.14 * ps + Vector3.UP * 0.27 * ps
	var want_y = shoulder_w.y - 0.05 * size
	if want_y < 0.55 * ps / 0.82:
		pat["low"] = true
	var best = 0.0
	var best_cost = 1e9
	for i in range(31):
		var deg = -25.0 + i * 2.5
		var y = pivot.y + (forehead - pivot).rotated(pet_axis, deg2rad(deg)).y
		var cost = abs(y - want_y) + 0.0005 * abs(deg)
		if cost < best_cost:
			best_cost = cost
			best = deg
	pat["neck"] = lerp(pat["neck"], best, 0.15)
	var neck_rad = deg2rad(pat["neck"])
	var pet_axis_s = WW.basis.inverse().xform(pet_axis).normalized()
	ws.set_bone_global_pose_override(neck, Transform(Basis(pet_axis_s, neck_rad) * g_neck.basis, g_neck.origin), w, true)

	# where the hand goes: the top of the head, stroking back and forth along it
	var stroke = sin(pat["t"] * TAU * 1.3)
	var target_w = pivot + (forehead - pivot).rotated(pet_axis, neck_rad)
	target_w += -pet_fwd * (0.06 * ps * stroke) + Vector3.UP * (0.02 * ps * abs(stroke))
	pat["target_w"] = target_w
	var head_point = pivot + (forehead - pivot).rotated(pet_axis, neck_rad)
	var node_pos = pet["node"].global_transform.origin
	pat["head_off"] = lerp(pat["head_off"], Vector2(head_point.x - node_pos.x, head_point.z - node_pos.z).length(), 0.1)
	var target = W.affine_inverse().xform(target_w)

	# the lean: tip the body forward until the shoulder is an arm's length from the target
	var g_torso = sk.get_bone_global_pose_no_override(torso)
	var g_arm = sk.get_bone_global_pose_no_override(arm)
	var g_elbow = sk.get_bone_global_pose_no_override(elbow)
	var g_hand = sk.get_bone_global_pose_no_override(hand)
	# the fingertips: a little past the hand bone, along the forearm
	var finger = 0.08
	var tip_point = g_hand.origin + (g_hand.origin - g_elbow.origin).normalized() * finger
	var reach = g_arm.origin.distance_to(g_elbow.origin) + g_elbow.origin.distance_to(g_hand.origin) + finger
	var axis_s = W.basis.inverse().xform(Vector3.UP.cross(_facing(petter))).normalized()
	var lean_best = 0.0
	best_cost = 1e9
	for i in range(37):
		var deg = -15.0 + i * 2.5
		var s = g_torso.origin + (g_arm.origin - g_torso.origin).rotated(axis_s, deg2rad(deg))
		var cost = abs(s.distance_to(target) - 0.92 * reach) + 0.004 * abs(deg)
		if cost < best_cost:
			best_cost = cost
			lean_best = deg
	pat["lean"] = lerp(pat["lean"], lean_best, 0.15)
	var torso_pose = Transform(Basis(axis_s, deg2rad(pat["lean"])) * g_torso.basis, g_torso.origin)
	sk.set_bone_global_pose_override(torso, torso_pose, w, true)

	# the arm: point the whole arm (shoulder to fingertips) at the target
	var rebase = torso_pose * g_torso.affine_inverse()
	var a = rebase * g_arm
	var v = (rebase.xform(tip_point) - a.origin).normalized()
	var d = (target - a.origin).normalized()
	var c = v.cross(d)
	var turn = Basis()
	if c.length() > 0.0001:
		turn = Basis(c.normalized(), acos(clamp(v.dot(d), -1.0, 1.0)))
	sk.set_bone_global_pose_override(arm, Transform(turn * a.basis, a.origin), w, true)


# --- the paw button ---

func _build_ui():
	# pet names sit underneath the game's own windows
	name_layer = CanvasLayer.new()
	name_layer.layer = 0
	add_child(name_layer)

	layer = CanvasLayer.new()
	layer.layer = 3
	add_child(layer)

	paw = Control.new()
	paw.rect_size = Vector2(34, 34)
	paw.rect_min_size = Vector2(34, 34)
	paw.rect_position = DEFAULT_PAW_POS
	paw.mouse_filter = Control.MOUSE_FILTER_STOP
	paw.visible = false
	paw.connect("draw", self, "_draw_paw")
	paw.connect("gui_input", self, "_on_paw_input")
	paw.connect("mouse_entered", self, "_on_paw_hover", [true])
	paw.connect("mouse_exited", self, "_on_paw_hover", [false])
	layer.add_child(paw)
	_add_tooltip(paw, "Pet", "Click for your pet, drag to move this button")

	menu = PanelContainer.new()
	menu.visible = false
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.add_stylebox_override("panel", _glass(Color(0.06, 0.12, 0.18, 0.75), Color(0.55, 1.0, 1.0, 0.45), 10, 6))
	layer.add_child(menu)

	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_constant_override("margin_" + side, 8)
	menu.add_child(margin)

	var column = VBoxContainer.new()
	column.add_constant_override("separation", 6)
	margin.add_child(column)

	var head = HBoxContainer.new()
	column.add_child(head)
	var title = Label.new()
	menu_title = title
	title.text = "Your Pet"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_color_override("font_color", Color(0.75, 0.95, 1.0))
	head.add_child(title)
	var close = Button.new()
	close.text = "x"
	close.focus_mode = Control.FOCUS_NONE
	close.connect("pressed", self, "_set_menu", [false])
	_glass_button(close)
	head.add_child(close)

	# which pet: a button with a little face for each kind
	var species_row = HBoxContainer.new()
	species_row.add_constant_override("separation", 6)
	species_row.alignment = BoxContainer.ALIGN_CENTER
	column.add_child(species_row)
	for kind in SPECIES_ORDER:
		var b = Button.new()
		b.rect_min_size = Vector2(46, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.connect("pressed", self, "_on_species", [kind])
		b.connect("draw", self, "_draw_face", [b, kind])
		species_row.add_child(b)
		_add_tooltip(b, SPECIES[kind]["label"], "Make your pet a " + SPECIES[kind]["label"].to_lower())
		species_buttons[kind] = b
	_style_species_buttons()

	show_box = CheckBox.new()
	show_box.text = "Show my pet"
	show_box.focus_mode = Control.FOCUS_NONE
	show_box.add_color_override("font_color", Color(1, 1, 1))
	show_box.add_color_override("font_color_hover", Color(1, 1, 1))
	show_box.add_color_override("font_color_pressed", Color(1, 1, 1))
	show_box.connect("toggled", self, "_on_show_toggled")
	column.add_child(show_box)

	howl_box = CheckBox.new()
	howl_box.text = "Answer when I bark"
	howl_box.focus_mode = Control.FOCUS_NONE
	howl_box.add_color_override("font_color", Color(1, 1, 1))
	howl_box.add_color_override("font_color_hover", Color(1, 1, 1))
	howl_box.add_color_override("font_color_pressed", Color(1, 1, 1))
	howl_box.connect("toggled", self, "_on_howl_toggled")
	_add_tooltip(howl_box, "Answer", "Your pet answers when you bark or meow (a wolf howls, a cat meows), at most once every 2 minutes")
	column.add_child(howl_box)

	# small, and wrapped to the menu's width so it doesn't make the menu wider
	fetch_hint = Label.new()
	fetch_hint.text = "Put the Tennis Ball on your hotbar to play fetch"
	fetch_hint.autowrap = true
	fetch_hint.add_color_override("font_color", Color(0.75, 0.95, 1.0))
	column.add_child(fetch_hint)

	_build_charge_bar()

	var cd_row = HBoxContainer.new()
	cd_row.add_constant_override("separation", 8)
	column.add_child(cd_row)
	var cd_name = Label.new()
	cd_name.text = "Wait"
	cd_name.add_color_override("font_color", Color(1, 1, 1))
	cd_row.add_child(cd_name)
	cooldown_slider = HSlider.new()
	cooldown_slider.min_value = COOLDOWN_MIN
	cooldown_slider.max_value = COOLDOWN_MAX
	cooldown_slider.step = 15
	cooldown_slider.value = COOLDOWN_DEFAULT
	cooldown_slider.focus_mode = Control.FOCUS_NONE
	cooldown_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cooldown_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cooldown_slider.connect("value_changed", self, "_on_cooldown_changed")
	cd_row.add_child(cooldown_slider)
	_add_tooltip(cooldown_slider, "Wait", "How long your pet waits before it answers a bark again")
	cooldown_label = Label.new()
	cooldown_label.text = _clock(COOLDOWN_DEFAULT)
	cooldown_label.rect_min_size = Vector2(42, 0)
	cooldown_label.align = Label.ALIGN_RIGHT
	cooldown_label.add_color_override("font_color", Color(1, 1, 1))
	cd_row.add_child(cooldown_label)

	var size_row = HBoxContainer.new()
	size_row.add_constant_override("separation", 8)
	column.add_child(size_row)
	var size_name = Label.new()
	size_name.text = "Size"
	size_name.add_color_override("font_color", Color(1, 1, 1))
	size_row.add_child(size_name)
	size_slider = HSlider.new()
	size_slider.min_value = SIZE_MIN
	size_slider.max_value = SIZE_MAX
	size_slider.step = 0.05
	size_slider.value = 1.0
	size_slider.focus_mode = Control.FOCUS_NONE
	size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_slider.connect("value_changed", self, "_on_size_changed")
	size_row.add_child(size_slider)
	size_label = Label.new()
	size_label.text = "100%"
	size_label.rect_min_size = Vector2(42, 0)
	size_label.align = Label.ALIGN_RIGHT
	size_label.add_color_override("font_color", Color(1, 1, 1))
	size_row.add_child(size_label)

	preset_row = HBoxContainer.new()
	preset_row.add_constant_override("separation", 6)
	column.add_child(preset_row)
	_rebuild_presets()

	# the colour pickers fold away under a header too, the list gets long
	colors_toggle = Button.new()
	colors_toggle.align = Button.ALIGN_LEFT
	colors_toggle.focus_mode = Control.FOCUS_NONE
	colors_toggle.connect("pressed", self, "_on_toggle_colors")
	_glass_button(colors_toggle)
	colors_toggle.add_color_override("font_color", Color(0.75, 0.95, 1.0))
	column.add_child(colors_toggle)
	var grid = GridContainer.new()
	colors_grid = grid
	grid.visible = colors_open
	grid.columns = 4 # two parts to a row, so the longer lists stay compact
	grid.add_constant_override("hseparation", 8)
	grid.add_constant_override("vseparation", 4)
	column.add_child(grid)
	for part in PARTS:
		var label = Label.new()
		label.text = part[1]
		label.add_color_override("font_color", Color(1, 1, 1))
		grid.add_child(label)
		var picker = ColorPickerButton.new()
		picker.rect_min_size = Vector2(40, 22)
		picker.edit_alpha = false
		picker.focus_mode = Control.FOCUS_NONE
		picker.connect("color_changed", self, "_on_color_changed", [part[0]])
		picker.connect("popup_closed", self, "_save_config")
		grid.add_child(picker)
		pickers[part[0]] = picker
		picker_labels[part[0]] = label
	_update_part_rows()

	# saving the current colours under a name
	var save_row = HBoxContainer.new()
	save_row.add_constant_override("separation", 6)
	column.add_child(save_row)
	name_field = LineEdit.new()
	name_field.placeholder_text = "palette name"
	name_field.max_length = 20
	name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_field.add_stylebox_override("normal", _glass(Color(0, 0, 0, 0.30), Color(0.55, 1.0, 1.0, 0.35), 8, 0))
	name_field.add_stylebox_override("focus", _glass(Color(0, 0, 0, 0.40), Color(0.8, 1.0, 1.0, 0.9), 8, 0))
	name_field.add_color_override("font_color", Color(1, 1, 1))
	name_field.connect("text_entered", self, "_on_save_palette")
	save_row.add_child(name_field)
	var save = Button.new()
	save.text = "Save"
	save.focus_mode = Control.FOCUS_NONE
	save.connect("pressed", self, "_on_save_palette")
	_glass_button(save)
	save_row.add_child(save)

	# the saved palettes fold away under a header so they don't fill the screen
	palette_toggle = Button.new()
	palette_toggle.align = Button.ALIGN_LEFT
	palette_toggle.focus_mode = Control.FOCUS_NONE
	palette_toggle.connect("pressed", self, "_on_toggle_palettes")
	_glass_button(palette_toggle)
	palette_toggle.add_color_override("font_color", Color(0.75, 0.95, 1.0))
	column.add_child(palette_toggle)
	palette_box = VBoxContainer.new()
	palette_box.add_constant_override("separation", 3)
	palette_box.visible = palettes_open
	column.add_child(palette_box)


func _draw_paw():
	var box = paw.rect_size
	var fill = Color(0.3, 1.0, 1.0, 0.30 if paw_hover else 0.16)
	if menu_open:
		fill = Color(0.3, 1.0, 1.0, 0.45)
	paw.draw_style_box(_glass(fill, Color(0.55, 1.0, 1.0, 0.8 if paw_hover else 0.5), 8, 0), Rect2(Vector2(), box))
	var c = Color(1, 1, 1, 0.95)
	var mid = box / 2.0 + Vector2(0, 3)
	# the big pad, a little wider than tall
	paw.draw_set_transform(mid, 0.0, Vector2(1.2, 0.95))
	paw.draw_circle(Vector2(), 6.0, c)
	paw.draw_set_transform(Vector2(), 0.0, Vector2(1, 1))
	# four toes
	for toe in [Vector2(-8.5, -6.5), Vector2(-3.2, -11.0), Vector2(3.2, -11.0), Vector2(8.5, -6.5)]:
		paw.draw_circle(mid + toe, 2.7, c)


func _on_paw_hover(inside):
	paw_hover = inside
	paw.update()


func _on_paw_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			paw_pressed = true
			paw_dragging = false
			press_pos = event.global_position
			drag_offset = paw.rect_position - press_pos
			paw.accept_event()


# dragging is followed here so it keeps going when the mouse leaves the button
func _input(event):
	if paw_pressed:
		if event is InputEventMouseMotion:
			var mouse = event.position
			if not paw_dragging and mouse.distance_to(press_pos) > 4.0:
				paw_dragging = true
			if paw_dragging:
				var area = get_viewport().get_visible_rect().size
				var pos = mouse + drag_offset
				pos.x = clamp(pos.x, 0, max(0, area.x - paw.rect_size.x))
				pos.y = clamp(pos.y, 0, max(0, area.y - paw.rect_size.y))
				paw.rect_position = pos
				_place_menu()
		elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
			paw_pressed = false
			if paw_dragging:
				paw_dragging = false
				_save_config()
			else:
				_set_menu(not menu_open)
		return

	# P opens and closes the pet menu (the game has nothing on P)
	if event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_P:
		if not _typing() and (paw.visible or menu_open):
			_set_menu(not menu_open)
			get_tree().set_input_as_handled()
			return

	if menu_open and event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		_set_menu(false)
		get_tree().set_input_as_handled()
		return

	# with the Tennis Ball in hand the mouse button throws it: hold it down to throw further
	if event.is_action("primary_action") and not event.is_echo() and _holding_ball():
		if event.is_pressed():
			if not _typing() and not menu_open and _hud_free() and _can_throw():
				charging_since = OS.get_ticks_msec()
		elif charging_since >= 0:
			var power = _charge_power()
			charging_since = -1
			_throw_ball(power)


func _typing():
	var hud = _get_hud()
	if hud != null and hud.get("using_chat") == true:
		return true
	var focus = paw.get_focus_owner()
	return focus != null and focus is LineEdit


func _set_menu(open):
	if menu_open == open:
		return
	menu_open = open
	menu.visible = open
	if open:
		_apply_to_pickers()
		_place_menu()
		_lock_hud()
	else:
		for key in pickers.keys():
			var popup = pickers[key].get_popup()
			if popup != null and popup.visible:
				popup.hide()
		_unlock_hud()
		_save_config()
	paw.update()


# the menu opens beside the paw, on whichever side has room
func _place_menu():
	if not menu.visible:
		return
	var area = get_viewport().get_visible_rect().size
	var size = menu.get_combined_minimum_size()
	menu.rect_size = size
	var pos = paw.rect_position + Vector2(paw.rect_size.x + 6, 0)
	if pos.x + size.x > area.x:
		pos.x = paw.rect_position.x - size.x - 6
	pos.x = clamp(pos.x, 0, max(0, area.x - size.x))
	pos.y = clamp(pos.y, 0, max(0, area.y - size.y))
	menu.rect_position = pos


func _apply_to_pickers():
	if show_box != null:
		show_box.set_block_signals(true)
		show_box.pressed = show_pet
		show_box.set_block_signals(false)
	if howl_box != null:
		howl_box.set_block_signals(true)
		howl_box.pressed = howl_on
	if cooldown_slider != null:
		cooldown_slider.set_block_signals(true)
		cooldown_slider.value = answer_cooldown
		cooldown_slider.set_block_signals(false)
		cooldown_label.text = _clock(answer_cooldown)
		howl_box.set_block_signals(false)
	for key in pickers.keys():
		pickers[key].color = _color_of(colors, key, species)
	if size_slider != null:
		size_slider.set_block_signals(true)
		size_slider.value = pet_size
		size_slider.set_block_signals(false)
		size_label.text = str(int(round(pet_size * 100))) + "%"


func _on_size_changed(value):
	pet_size = clamp(value, SIZE_MIN, SIZE_MAX)
	size_label.text = str(int(round(pet_size * 100))) + "%"
	sync_dirty = true
	_save_config()


func _clock(seconds):
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _on_cooldown_changed(value):
	answer_cooldown = int(clamp(value, COOLDOWN_MIN, COOLDOWN_MAX))
	cooldown_label.text = _clock(answer_cooldown)
	sync_dirty = true
	_save_config()
	# a shorter wait counts from the last answer straight away
	if pets.has("me"):
		pets["me"]["cooldown"] = answer_cooldown


func _on_howl_toggled(on):
	howl_on = on
	sync_dirty = true
	_save_config()


func _on_show_toggled(on):
	show_pet = on
	sync_dirty = true
	_save_config()


func _set_pet_name(name):
	pet_name = _clean_name(name)
	if menu_title != null:
		menu_title.text = pet_name if pet_name != "" else "Your Pet"
	sync_dirty = true


# the ready-made looks of the current kind of pet
func _rebuild_presets():
	if preset_row == null:
		return
	for child in preset_row.get_children():
		preset_row.remove_child(child)
		child.queue_free()
	var list = SPECIES[species]["presets"]
	for i in range(list.size()):
		var b = Button.new()
		b.text = list[i][0]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.connect("pressed", self, "_on_preset", [i])
		_glass_button(b)
		preset_row.add_child(b)


func _style_species_buttons():
	for kind in species_buttons.keys():
		var b = species_buttons[kind]
		var chosen = kind == species
		var edge = Color(0.8, 1.0, 1.0, 0.95) if chosen else Color(0.55, 1.0, 1.0, 0.45)
		var fill = Color(0.3, 1.0, 1.0, 0.42) if chosen else Color(0.2, 0.9, 0.95, 0.12)
		b.add_stylebox_override("normal", _glass(fill, edge, 8, 0))
		b.add_stylebox_override("hover", _glass(Color(0.3, 1.0, 1.0, 0.5 if chosen else 0.28), Color(0.8, 1.0, 1.0, 0.9), 8, 0))
		b.add_stylebox_override("pressed", _glass(Color(0.3, 1.0, 1.0, 0.5), Color(0.8, 1.0, 1.0, 0.95), 8, 0))
		b.add_stylebox_override("focus", StyleBoxEmpty.new())
		b.update()


# little drawn faces, so they do not depend on any font or picture
func _draw_face(b, kind):
	var c = b.rect_size / 2.0 + Vector2(0, 2)
	var fur = Color(0.96, 0.97, 0.98)
	var dark = Color(0.13, 0.16, 0.2)
	var pink = Color(0.95, 0.62, 0.7)
	if kind == "wolf":
		for sx in [-1, 1]:
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 12, -5), c + Vector2(sx * 10, -17), c + Vector2(sx * 3, -9)]), fur)
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 10, -7), c + Vector2(sx * 9.5, -14), c + Vector2(sx * 5, -9)]), pink)
		b.draw_colored_polygon(PoolVector2Array([c + Vector2(-12, -6), c + Vector2(-8, -10), c + Vector2(0, -11), c + Vector2(8, -10),
			c + Vector2(12, -6), c + Vector2(11, 2), c + Vector2(6, 7), c + Vector2(3, 13), c + Vector2(-3, 13), c + Vector2(-6, 7), c + Vector2(-11, 2)]), fur)
		b.draw_circle(c + Vector2(-5, -3), 1.7, dark)
		b.draw_circle(c + Vector2(5, -3), 1.7, dark)
		b.draw_circle(c + Vector2(0, 10.5), 2.2, dark)
	elif kind == "fox":
		var orange = Color(0.92, 0.5, 0.17)
		for sx in [-1, 1]:
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 13, -3), c + Vector2(sx * 10, -19), c + Vector2(sx * 2, -9)]), orange)
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 10.5, -6), c + Vector2(sx * 9.5, -15), c + Vector2(sx * 5, -9)]), dark)
		b.draw_colored_polygon(PoolVector2Array([c + Vector2(-12, -7), c + Vector2(-7, -10), c + Vector2(0, -11), c + Vector2(7, -10),
			c + Vector2(12, -7), c + Vector2(9, 1), c + Vector2(4, 8), c + Vector2(0, 14), c + Vector2(-4, 8), c + Vector2(-9, 1)]), orange)
		b.draw_colored_polygon(PoolVector2Array([c + Vector2(-9, 1), c + Vector2(-4, -1), c + Vector2(0, 2), c + Vector2(4, -1), c + Vector2(9, 1),
			c + Vector2(4, 8), c + Vector2(0, 14), c + Vector2(-4, 8)]), fur)
		b.draw_circle(c + Vector2(-5, -4), 1.6, dark)
		b.draw_circle(c + Vector2(5, -4), 1.6, dark)
		b.draw_circle(c + Vector2(0, 12.5), 1.8, dark)
	elif kind == "raccoon":
		var mask = Color(0.2, 0.22, 0.26)
		for sx in [-1, 1]:
			b.draw_circle(c + Vector2(sx * 8.5, -9), 4.5, fur)
			b.draw_circle(c + Vector2(sx * 8.5, -9), 2.2, mask)
		b.draw_circle(c + Vector2(0, 1), 11.5, fur)
		b.draw_colored_polygon(PoolVector2Array([c + Vector2(-11, -4), c + Vector2(-4, -3), c + Vector2(0, -1), c + Vector2(4, -3),
			c + Vector2(11, -4), c + Vector2(10, 2), c + Vector2(4, 2), c + Vector2(0, 1), c + Vector2(-4, 2), c + Vector2(-10, 2)]), mask)
		b.draw_circle(c + Vector2(-5, -1), 1.6, fur)
		b.draw_circle(c + Vector2(5, -1), 1.6, fur)
		b.draw_circle(c + Vector2(0, 6), 4.0, Color(0.88, 0.89, 0.9))
		b.draw_circle(c + Vector2(0, 4.6), 1.6, dark)
	else:
		for sx in [-1, 1]:
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 12, -2), c + Vector2(sx * 11, -15), c + Vector2(sx * 2, -9)]), fur)
			b.draw_colored_polygon(PoolVector2Array([c + Vector2(sx * 10, -5), c + Vector2(sx * 10, -12), c + Vector2(sx * 5, -8)]), pink)
		b.draw_circle(c + Vector2(0, 1), 11.0, fur)
		b.draw_circle(c + Vector2(-4.5, -0.5), 2.0, dark)
		b.draw_circle(c + Vector2(4.5, -0.5), 2.0, dark)
		b.draw_colored_polygon(PoolVector2Array([c + Vector2(-1.8, 4), c + Vector2(1.8, 4), c + Vector2(0, 6)]), pink)
		for sx in [-1, 1]:
			b.draw_line(c + Vector2(sx * 3, 6), c + Vector2(sx * 15, 4), dark, 1.0)
			b.draw_line(c + Vector2(sx * 3, 7), c + Vector2(sx * 15, 8), dark, 1.0)


# switching kind: if it wore one of the old kind's ready-made looks, it gets the matching look of the new one
func _set_species(kind, keep_colors):
	if not SPECIES.has(kind):
		return
	var old = species
	species = kind
	if not keep_colors and old != kind:
		var list = SPECIES[old]["presets"]
		for i in range(list.size()):
			var same = true
			for part in PARTS:
				if _color_text(list[i][1], part[0], old).to_lower() != _color_text(colors, part[0], old).to_lower():
					same = false
			if same:
				_reset_colors(min(i, SPECIES[kind]["presets"].size() - 1))
				_apply_to_pickers()
				break
	_style_species_buttons()
	_rebuild_presets()
	_update_part_rows()
	sync_dirty = true


# the colour grid shows only the parts this kind of pet has, under its own names for them
func _update_part_rows():
	var info = SPECIES[species]
	# the rows go in this kind's order: the standard areas first, then its special ones
	if colors_grid != null:
		var at = 0
		for key in info.get("parts", []):
			if pickers.has(key):
				colors_grid.move_child(picker_labels[key], at)
				colors_grid.move_child(pickers[key], at + 1)
				at += 2
	for part in PARTS:
		if not pickers.has(part[0]):
			continue
		var shown = info.get("parts", []).has(part[0])
		pickers[part[0]].visible = shown
		picker_labels[part[0]].visible = shown
		picker_labels[part[0]].text = info.get("labels", {}).get(part[0], part[1])
	_update_colors_toggle()


func _on_toggle_colors():
	colors_open = not colors_open
	_update_colors_toggle()
	_save_config()
	if menu_open:
		call_deferred("_place_menu")


func _update_colors_toggle():
	if colors_grid != null:
		colors_grid.visible = colors_open
	if colors_toggle != null:
		colors_toggle.text = ("-  " if colors_open else "+  ") + "Colours (%d)" % SPECIES[species].get("parts", []).size()


func _on_species(kind):
	_set_species(kind, false)
	_save_config()


func _on_preset(name):
	_reset_colors(name)
	_set_pet_name("")
	_apply_to_pickers()
	sync_dirty = true
	_save_config()


func _on_save_palette(_text = ""):
	var name = name_field.text.strip_edges()
	if name == "":
		name_field.placeholder_text = "type a name first"
		return
	if not palettes.has(name) and palettes.size() >= MAX_PALETTES:
		name_field.text = ""
		name_field.placeholder_text = "full, delete one first"
		return
	palettes[name] = colors.duplicate()
	palettes[name]["species"] = species
	_set_pet_name(name)
	name_field.text = ""
	name_field.placeholder_text = "palette name"
	name_field.release_focus()
	_rebuild_palettes()
	_save_config()


func _on_use_palette(name):
	if not palettes.has(name):
		return
	for part in PARTS:
		colors[part[0]] = _color_text(palettes[name], part[0], species)
	name_field.text = name # so saving again updates it
	_set_pet_name(name)
	# only the colours and name: the pet stays the kind it is (a palette made on a wolf can dress a cat)
	_apply_to_pickers()
	sync_dirty = true
	_save_config()


func _on_delete_palette(name):
	palettes.erase(name)
	_rebuild_palettes()
	_save_config()


func _on_toggle_palettes():
	palettes_open = not palettes_open
	_update_palette_toggle()
	_save_config()
	if menu_open:
		call_deferred("_place_menu")


func _update_palette_toggle():
	if palette_box != null:
		palette_box.visible = palettes_open
	if palette_toggle != null:
		palette_toggle.text = ("-  " if palettes_open else "+  ") + "My palettes (%d)" % palettes.size()


# one row per saved palette: its colours as little swatches, its name, and a delete button
func _rebuild_palettes():
	if palette_box == null:
		return
	for child in palette_box.get_children():
		palette_box.remove_child(child)
		child.queue_free()
	var names = palettes.keys()
	names.sort()
	if names.empty():
		var none = Label.new()
		none.text = "none saved yet"
		none.add_color_override("font_color", Color(1, 1, 1, 0.5))
		palette_box.add_child(none)
	for name in names:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", 4)
		palette_box.add_child(row)
		var use = Button.new()
		use.text = name
		use.clip_text = true
		use.align = Button.ALIGN_LEFT
		use.focus_mode = Control.FOCUS_NONE
		use.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		use.connect("pressed", self, "_on_use_palette", [name])
		_glass_button(use)
		row.add_child(use)
		for key in ["fur", "back", "belly", "eyes"]:
			var swatch = ColorRect.new()
			swatch.rect_min_size = Vector2(8, 18)
			swatch.color = _color_of(palettes[name], key)
			swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(swatch)
		var del = Button.new()
		del.text = "x"
		del.focus_mode = Control.FOCUS_NONE
		del.connect("pressed", self, "_on_delete_palette", [name])
		_glass_button(del)
		row.add_child(del)
	_update_palette_toggle()
	if menu_open:
		call_deferred("_place_menu")


func _on_color_changed(color, key):
	colors[key] = color.to_html(false)
	sync_dirty = true


# like the game's own hotbar: only there while no menu of the game is open
func _refresh_ui():
	var hud = _get_hud()
	var show = hud != null
	if show:
		if hud.get("menu") != 0 or hud.get("hud_hidden") == true:
			show = false
		var popups = hud.get("popups")
		if typeof(popups) == TYPE_ARRAY:
			for entry in popups:
				if entry != POPUP_ID:
					show = false
		var options = get_node_or_null("/root/OptionsMenu")
		if options != null and options.get("open") == true:
			show = false
	if show and not theme_applied:
		theme_applied = true
		var main = hud.get_node_or_null("main")
		if main != null and main.theme != null:
			paw.theme = main.theme
			menu.theme = main.theme
			charge_panel.theme = main.theme
			# the game's font, smaller, for the fetch hint
			var base = menu.get_font("font", "Label")
			if base is DynamicFont:
				var small = base.duplicate()
				small.size = int(max(10, round(base.size * 0.72)))
				small.outline_size = int(round(base.outline_size * 0.72))
				fetch_hint.add_font_override("font", small)
				charge_label.add_font_override("font", small)
	if not show and menu_open:
		_set_menu(false)
	if not show:
		paw_pressed = false
		paw_dragging = false
	paw.visible = show


func _get_hud():
	var players = get_tree().get_nodes_in_group("controlled_player")
	if players.empty():
		return null
	var hud = players[0].get("hud")
	if hud == null or not is_instance_valid(hud):
		return null
	return hud


# while the menu is open the game must not react to keys (typing a colour code would change the hotbar)
func _lock_hud():
	var hud = _get_hud()
	if hud == null:
		return
	var popups = hud.get("popups")
	if typeof(popups) == TYPE_ARRAY and not popups.has(POPUP_ID):
		popups.append(POPUP_ID)
	locked_hud = hud


func _unlock_hud():
	if locked_hud != null and is_instance_valid(locked_hud):
		var popups = locked_hud.get("popups")
		if typeof(popups) == TYPE_ARRAY:
			popups.erase(POPUP_ID)
	locked_hud = null


# --- looks ---

func _glass(fill, edge, radius, shadow):
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = shadow
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box


func _glass_button(button):
	var edge = Color(0.55, 1.0, 1.0, 0.5)
	button.add_stylebox_override("normal", _glass(Color(0.2, 0.9, 0.95, 0.16), edge, 8, 0))
	button.add_stylebox_override("hover", _glass(Color(0.3, 1.0, 1.0, 0.30), Color(0.8, 1.0, 1.0, 0.8), 8, 0))
	button.add_stylebox_override("pressed", _glass(Color(0.3, 1.0, 1.0, 0.45), Color(0.8, 1.0, 1.0, 0.9), 8, 0))
	button.add_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_color_override("font_color", Color(1, 1, 1))
	button.add_color_override("font_color_hover", Color(1, 1, 1))
	button.add_color_override("font_color_pressed", Color(1, 1, 1))


# the game's own hover box, so it looks like the rest of the game
func _add_tooltip(control, header, body):
	var scene = load("res://Scenes/Singletons/Tooltips/tooltip_node.tscn") if ResourceLoader.exists("res://Scenes/Singletons/Tooltips/tooltip_node.tscn") else null
	if scene == null or get_node_or_null("/root/Tooltip") == null:
		control.hint_tooltip = header
		return
	var tip = scene.instance()
	tip.header = "[color=#6a4420]" + header + "[/color]"
	tip.body = body
	tip.mouse_filter = Control.MOUSE_FILTER_PASS
	control.add_child(tip)


# --- saving ---

func _load_config():
	var file = File.new()
	var path = CONFIG_PATH if file.file_exists(CONFIG_PATH) else OLD_CONFIG_PATH
	if not file.file_exists(path) or file.open(path, File.READ) != OK:
		return
	var data = parse_json(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	if data.has("x") and data.has("y"):
		paw.rect_position = Vector2(float(data["x"]), float(data["y"]))
	if data.has("show"):
		show_pet = bool(data["show"])
	if data.has("colors_open"):
		colors_open = bool(data["colors_open"])
	if data.has("palettes_open"):
		palettes_open = bool(data["palettes_open"])
	if data.has("howl"):
		howl_on = bool(data["howl"])
	if data.has("cooldown"):
		answer_cooldown = int(clamp(float(data["cooldown"]), COOLDOWN_MIN, COOLDOWN_MAX))
	if SPECIES.has(str(data.get("species", ""))):
		species = str(data["species"])
		_style_species_buttons()
		_rebuild_presets()
		_update_part_rows()
	if data.has("size"):
		pet_size = clamp(float(data["size"]), SIZE_MIN, SIZE_MAX)
	if data.has("name"):
		_set_pet_name(str(data["name"]))
	if typeof(data.get("palettes")) == TYPE_DICTIONARY:
		for name in data["palettes"].keys():
			if typeof(data["palettes"][name]) == TYPE_DICTIONARY and palettes.size() < MAX_PALETTES:
				palettes[str(name)] = data["palettes"][name]
	_rebuild_palettes()
	if typeof(data.get("colors")) == TYPE_DICTIONARY:
		# parts saved before they could be coloured on their own take the colour they shared
		for part in PARTS:
			colors[part[0]] = _color_text(data["colors"], part[0], species)
	if pet_name == "":
		# saved before names existed: if its colours are one of the saved palettes, take that name
		for key in palettes.keys():
			var same = true
			for part in PARTS:
				if str(palettes[key].get(part[0], "")).to_lower() != str(colors.get(part[0], "")).to_lower():
					same = false
			if same:
				_set_pet_name(key)
				break
	sync_dirty = true


func _save_config():
	var file = File.new()
	if file.open(CONFIG_PATH, File.WRITE) != OK:
		return
	file.store_string(to_json({"x": paw.rect_position.x, "y": paw.rect_position.y, "show": show_pet, "species": species, "howl": howl_on, "cooldown": answer_cooldown, "size": pet_size, "name": pet_name, "colors": colors, "palettes": palettes, "palettes_open": palettes_open, "colors_open": colors_open}))
	file.close()
