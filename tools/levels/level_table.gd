extends RefCounted

# Level design table shared by make_levels.gd (writes the .tres files) and tune.gd (balances them).
# Row: [moves, difficulty, orders, goals, layout, intro]
#   difficulty: 0 normal, 1 hard, 2 very hard
#   orders: repair jobs in order, each [vehicle id, {part kind: count}, patience]; patience 0 means the level's moves.
#           Part kinds: 1 steering wheel, 2 gear, 3 headlight, 4 spark plug, 5 tyre. Vehicle ids are MetaRules.RECIPES ids;
#           each vehicle first appears on level 1 + 5 * its index, where the gallery gains it.
#   goals: obstacle keys below; 0 means every such obstacle in the layout.
#   layout: a LAYOUTS key, "" for a plain board.
#   intro: mechanic explained once before the level (see INTROS in game.gd).
# tune.gd scales the ingredient counts and prints rows to paste back.
# Levels 1-5 are set by hand well below the tuned values: the bot plays far better than a first-time player.
const BOX := M3.GOAL_BOX
const PAW := M3.GOAL_PAW
const SACK := M3.GOAL_SACK
const KNOT := M3.GOAL_KNOT
const KITTEN := M3.GOAL_KITTEN
const CAGE := M3.GOAL_CAGE
const MOUSE := M3.GOAL_MOUSE
const GOAL_NAMES := {BOX: "BOX", PAW: "PAW", SACK: "SACK", KNOT: "KNOT", KITTEN: "KITTEN", CAGE: "CAGE", MOUSE: "MOUSE"}

const LAYOUTS := {
	"box_center": [".......", ".......", "..111..", "..111..", ".......", ".......", "......."],
	"box_corners": ["11...11", "1.....1", ".......", ".......", ".......", "1.....1", "11...11"],
	"box_wall": [".......", ".......", ".......", "2211122", ".......", ".......", "......."],
	"box_bottom": [".......", ".......", ".......", ".......", "1111111", "2222222", "......."],
	"paw_center": [".......", ".......", "..PPP..", "..PPP..", "..PPP..", ".......", "......."],
	"paw_x": ["P.....P", ".P...P.", "..P.P..", "...P...", "..P.P..", ".P...P.", "P.....P"],
	"paw_bottom": [".......", ".......", ".......", ".......", "PPPPPPP", "PPPPPPP", "PPPPPPP"],
	"paw_box": ["..111..", ".......", "PPPPPPP", "P.....P", "PPPPPPP", ".......", "..111.."],
	"knot_diamond": [".......", "...K...", "..K.K..", ".K...K.", "..K.K..", "...K...", "......."],
	"knot_rows": [".......", ".......", "K.K.K.K", ".......", "K.K.K.K", ".......", "......."],
	"knot_paw": [".......", "PPPPPPP", ".K.K.K.", "PPPPPPP", ".......", ".......", "......."],
	"knot_box": [".......", "2.....2", ".K.K.K.", "2.....2", ".K.K.K.", ".......", "......."],
	"crate_two": [".......", ".......", ".C...C.", ".......", ".......", ".......", "......."],
	"crate_box": [".......", "..1C1..", "..111..", ".......", ".......", ".......", "......."],
	"crate_paw": [".......", "PPPPPPP", ".C...C.", "PPPPPPP", ".......", ".......", "......."],
	"crate_knot": [".......", "..K.K..", ".C...C.", "..K.K..", ".......", ".......", "......."],
	"finale": [".......", "1C1.1C1", "PPPPPPP", ".......", "PPPPPPP", ".......", "......."],
	"mouse_one": [".......", ".......", ".......", "...M...", ".......", ".......", "......."],
	"mouse_two": [".......", ".M...M.", ".......", ".......", ".......", ".......", "......."],
	"mouse_box": [".......", ".M...M.", ".......", "..111..", ".......", ".......", "......."],
	# Conveyor belts (">" right, "<" left) turn once after every swap; no obstacles on belt cells.
	"belt_one": [".......", ".......", ".......", ">>>>>>>", ".......", ".......", "......."],
	"belt_two": [".......", ">>>>>>>", ".......", ".......", ".......", "<<<<<<<", "......."],
	"belt_box": [".......", "..1.1..", ">>>>>>>", "..1.1..", ".......", ".......", "......."],
	"belt_mouse": [".......", ".M...M.", ".......", ">>>>>>>", ".......", ".......", "......."],
	"belt_paw": [".......", "PPPPPPP", ">>>>>>>", ".......", "<<<<<<<", "PPPPPPP", "......."],
	# Shaped boards ("#" is a hole).
	"heart": ["#..#..#", ".......", ".......", ".......", "#.....#", "##...##", "###.###"],
	"corners_knot": ["#.....#", ".K...K.", ".......", "..K.K..", ".......", ".K...K.", "#.....#"],
	"ring_crate": [".......", ".C...C.", "..###..", "..###..", "..###..", ".......", "......."],
}

const TABLE := [
	[20, 0, [["kupa", {1: 8, 2: 6}, 0]], {}, "", "basics"],
	[20, 0, [["kupa", {1: 8, 3: 8}, 0]], {}, "", "serve"],
	[20, 0, [["kupa", {1: 10, 2: 8, 3: 6}, 0]], {}, "", ""],
	[22, 0, [["kupa", {2: 12, 3: 10}, 0]], {}, "", "line"],
	[20, 0, [["kupa", {1: 12, 2: 12}, 0]], {}, "", ""],
	[20, 0, [["skuter", {1: 22, 4: 19}, 0]], {}, "", ""],
	[20, 0, [["skuter", {2: 20, 4: 20}, 0]], {}, "", "bomb"],
	[20, 0, [["kupa", {1: 20, 3: 20}, 0]], {}, "", ""],
	[20, 1, [["skuter", {1: 33, 2: 30, 4: 26}, 0]], {}, "", ""],
	[22, 0, [["kupa", {2: 25, 3: 25}, 0]], {}, "", ""],
	[20, 0, [["pikap", {3: 26, 5: 22}, 0]], {}, "", "flyer"],
	[22, 0, [["skuter", {1: 25, 4: 25}, 0]], {}, "", ""],
	[22, 0, [["kupa", {1: 12, 2: 12}, 14], ["pikap", {3: 12, 5: 12}, 22]], {}, "", "tables"],
	[22, 0, [["pikap", {3: 27, 5: 24}, 0]], {}, "", ""],
	[22, 0, [["skuter", {2: 26, 4: 26}, 0]], {}, "", "color"],
	[22, 0, [["minibus", {4: 31, 1: 24}, 0]], {}, "", ""],
	[22, 0, [["pikap", {3: 10, 5: 10}, 14], ["minibus", {4: 10, 1: 10}, 22]], {}, "", ""],
	[18, 0, [["kupa", {1: 16, 2: 16}, 0]], {BOX: 0}, "box_center", "box"],
	[20, 1, [["skuter", {1: 30, 2: 30, 4: 25}, 0]], {BOX: 0}, "box_corners", ""],
	[22, 0, [["minibus", {4: 23, 1: 23}, 0]], {BOX: 0}, "box_wall", ""],
	[22, 0, [["kros", {5: 30, 4: 30}, 0]], {}, "", ""],
	[22, 0, [["pikap", {3: 12, 5: 10}, 14], ["skuter", {2: 10, 4: 10}, 22]], {BOX: 0}, "box_corners", ""],
	[24, 0, [["kros", {5: 26, 4: 21}, 0]], {BOX: 0}, "box_bottom", ""],
	[18, 0, [["minibus", {4: 23, 1: 23}, 0]], {PAW: 0}, "paw_center", "paw"],
	[22, 0, [["kros", {5: 30, 4: 30}, 0]], {PAW: 0}, "paw_x", ""],
	[22, 0, [["cip", {2: 28, 4: 28}, 0]], {}, "", ""],
	[20, 1, [["cip", {2: 18, 4: 16}, 12], ["kupa", {1: 16, 3: 16}, 20]], {PAW: 0}, "paw_center", ""],
	[22, 0, [["skuter", {1: 28, 2: 28}, 0]], {BOX: 0, PAW: 0}, "paw_box", ""],
	[22, 0, [["cip", {2: 31, 4: 24}, 0]], {PAW: 0}, "paw_bottom", ""],
	[24, 2, [["kros", {5: 16, 4: 16}, 14], ["cip", {2: 16, 4: 14}, 24]], {BOX: 0, PAW: 0}, "paw_box", ""],
	[22, 0, [["klasik", {5: 29, 3: 29}, 0]], {}, "", ""],
	[18, 0, [["klasik", {5: 16, 3: 13}, 0]], {KNOT: 0}, "knot_diamond", "knot"],
	[22, 0, [["pikap", {3: 33, 5: 29}, 0]], {KNOT: 0}, "knot_rows", ""],
	[22, 0, [["klasik", {5: 9, 3: 9}, 14], ["minibus", {4: 9, 1: 9}, 22]], {KNOT: 0}, "knot_diamond", ""],
	[22, 0, [["cip", {2: 34, 4: 34}, 0]], {KNOT: 0, PAW: 0}, "knot_paw", ""],
	[22, 0, [["yaris", {4: 29, 1: 25, 2: 21}, 0]], {}, "", ""],
	[22, 0, [["yaris", {4: 25, 1: 25}, 0]], {KNOT: 0, BOX: 0}, "knot_box", ""],
	[18, 0, [["klasik", {5: 22, 3: 22}, 0]], {KITTEN: 0}, "crate_two", "kitten"],
	[20, 1, [["yaris", {4: 12, 1: 12}, 12], ["kros", {5: 12, 4: 10}, 20]], {KITTEN: 0}, "crate_two", ""],
	[22, 0, [["kupa", {1: 25, 2: 22, 3: 18}, 0]], {KITTEN: 0, BOX: 0}, "crate_box", ""],
	[22, 0, [["cekici", {5: 29, 1: 24, 3: 24}, 0]], {}, "", ""],
	[22, 0, [["cekici", {5: 31, 3: 31}, 0]], {KITTEN: 0, PAW: 0}, "crate_paw", ""],
	[22, 0, [["klasik", {5: 13, 3: 13}, 14], ["yaris", {4: 13, 1: 13}, 22]], {KNOT: 0}, "knot_rows", ""],
	[18, 0, [["cekici", {1: 28, 3: 28}, 0]], {MOUSE: 0}, "mouse_one", "mouse"],
	[22, 0, [["pikap", {3: 29, 5: 24}, 0]], {MOUSE: 0}, "mouse_two", ""],
	[22, 0, [["hizli", {1: 31, 4: 27}, 0]], {}, "", ""],
	[20, 1, [["hizli", {1: 18, 4: 18}, 12], ["cekici", {5: 18, 3: 15}, 20]], {MOUSE: 0}, "mouse_two", ""],
	[22, 0, [["cip", {2: 35, 4: 30}, 0]], {MOUSE: 0, BOX: 0}, "mouse_box", ""],
	[22, 0, [["hizli", {1: 30, 4: 25}, 0]], {KITTEN: 0, KNOT: 0}, "crate_knot", ""],
	[18, 0, [["kupa", {1: 35, 3: 35}, 0]], {}, "belt_one", "belt"],
	[22, 0, [["itfaiye", {4: 31, 1: 26, 2: 26}, 0]], {}, "", ""],
	[22, 0, [["itfaiye", {4: 22, 1: 22}, 14], ["skuter", {2: 19, 4: 19}, 22]], {}, "belt_two", ""],
	[22, 0, [["cekici", {5: 44, 3: 38}, 0]], {BOX: 0}, "belt_box", ""],
	[22, 0, [["kros", {5: 22, 4: 22}, 0]], {}, "heart", ""],
	[22, 0, [["hizli", {1: 48, 4: 48}, 0]], {MOUSE: 0}, "belt_mouse", ""],
	[22, 0, [["karavan", {3: 33, 2: 29}, 0]], {}, "", ""],
	[20, 1, [["karavan", {3: 15, 2: 15}, 12], ["itfaiye", {4: 15, 1: 13}, 20]], {KNOT: 0}, "corners_knot", ""],
	[22, 0, [["klasik", {5: 56, 3: 48}, 0]], {PAW: 0}, "belt_paw", ""],
	[22, 0, [["yaris", {4: 12, 1: 12}, 0]], {KITTEN: 0}, "ring_crate", ""],
	[24, 2, [["kupa", {1: 14, 2: 12}, 12], ["karavan", {3: 14, 2: 12}, 18], ["itfaiye", {4: 14, 1: 12}, 24]], {KITTEN: 0, PAW: 0}, "finale", ""],
]


# Bot win rate a level is tuned to; the bot plays better than a new player.
static func target_rate(id: int, difficulty: int) -> float:
	if difficulty == 2:
		return 0.45
	if difficulty == 1:
		return 0.6
	return 0.95 if id <= 20 else 0.85


static func build(index: int) -> M3LevelDef:
	var row: Array = TABLE[index]
	var level := M3LevelDef.new()
	level.id = index + 1
	level.moves = row[0]
	level.difficulty = row[1]
	level.layout = PackedStringArray(LAYOUTS.get(row[4], []))
	level.intro = row[5]
	level.rng_seed = 1000 + level.id
	for order in row[2]:
		var goals := {}
		for kind in order[1]:
			goals[int(kind)] = int(order[1][kind])
		var patience: int = order[2] if int(order[2]) > 0 else level.moves
		level.orders.append({"dish": str(order[0]), "goals": goals, "patience": patience})
	for key in row[3]:
		level.goals[key] = _goal_count(level, key, row[3][key])
	level.keys = layout_count(level.layout, CAGE)
	return level


# An obstacle goal of 0 means every such obstacle in the layout.
static func _goal_count(level: M3LevelDef, key: int, count: int) -> int:
	if count != 0:
		return count
	return level.sacks if key == SACK else layout_count(level.layout, key)


static func layout_count(layout: PackedStringArray, key: int) -> int:
	var symbols: String = {BOX: "12", KITTEN: "C", KNOT: "K", PAW: "P", CAGE: "G", MOUSE: "M"}.get(key, "")
	var count := 0
	for row in layout:
		for ch in row:
			if symbols.contains(ch):
				count += 1
	return count
