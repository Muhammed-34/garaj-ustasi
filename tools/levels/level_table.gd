extends RefCounted

# Level design table shared by make_levels.gd (writes the .tres files) and tune.gd (balances them).
# Row: [moves, difficulty, orders, goals, layout, intro]
#   difficulty: 0 normal, 1 hard, 2 very hard
#   orders: tables in order, each [dish id, {ingredient kind: count}, patience]; patience 0 means the level's moves.
#           Ingredient kinds: 1 tomato, 2 pepper, 3 egg, 4 onion, 5 cheese. Dish ids are MetaRules.RECIPES ids;
#           each recipe first appears on level 1 + 5 * its index, where the recipe book gains it.
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
	[20, 0, [["menemen", {1: 8, 2: 6}, 0]], {}, "", "basics"],
	[20, 0, [["menemen", {1: 8, 3: 8}, 0]], {}, "", "serve"],
	[20, 0, [["menemen", {1: 10, 2: 8, 3: 6}, 0]], {}, "", ""],
	[22, 0, [["menemen", {2: 12, 3: 10}, 0]], {}, "", "line"],
	[20, 0, [["menemen", {1: 12, 2: 12}, 0]], {}, "", ""],
	[20, 0, [["coban", {1: 14, 4: 12}, 0]], {}, "", ""],
	[20, 0, [["coban", {2: 14, 4: 14}, 0]], {}, "", "bomb"],
	[20, 0, [["menemen", {1: 14, 3: 14}, 0]], {}, "", ""],
	[20, 1, [["coban", {1: 18, 2: 16, 4: 14}, 0]], {}, "", ""],
	[22, 0, [["menemen", {2: 16, 3: 16}, 0]], {}, "", ""],
	[20, 0, [["omlet", {3: 16, 5: 14}, 0]], {}, "", "flyer"],
	[22, 0, [["coban", {1: 16, 4: 16}, 0]], {}, "", ""],
	[22, 0, [["menemen", {1: 10, 2: 10}, 14], ["omlet", {3: 10, 5: 10}, 22]], {}, "", "tables"],
	[22, 0, [["omlet", {3: 18, 5: 16}, 0]], {}, "", ""],
	[22, 0, [["coban", {2: 16, 4: 16}, 0]], {}, "", "color"],
	[22, 0, [["mercimek", {4: 18, 1: 14}, 0]], {}, "", ""],
	[22, 0, [["omlet", {3: 10, 5: 10}, 14], ["mercimek", {4: 10, 1: 10}, 22]], {}, "", ""],
	[18, 0, [["menemen", {1: 8, 2: 8}, 0]], {BOX: 0}, "box_center", "box"],
	[20, 1, [["coban", {1: 12, 2: 12, 4: 10}, 0]], {BOX: 0}, "box_corners", ""],
	[22, 0, [["mercimek", {4: 14, 1: 14}, 0]], {BOX: 0}, "box_wall", ""],
	[22, 0, [["gozleme", {5: 16, 4: 16}, 0]], {}, "", ""],
	[22, 0, [["omlet", {3: 12, 5: 10}, 14], ["coban", {2: 10, 4: 10}, 22]], {BOX: 0}, "box_corners", ""],
	[22, 0, [["gozleme", {5: 18, 4: 14}, 0]], {BOX: 0}, "box_bottom", ""],
	[18, 0, [["mercimek", {4: 8, 1: 8}, 0]], {PAW: 0}, "paw_center", "paw"],
	[22, 0, [["gozleme", {5: 12, 4: 12}, 0]], {PAW: 0}, "paw_x", ""],
	[22, 0, [["dolma", {2: 16, 4: 16}, 0]], {}, "", ""],
	[20, 1, [["dolma", {2: 14, 4: 12}, 12], ["menemen", {1: 12, 3: 12}, 20]], {PAW: 0}, "paw_center", ""],
	[22, 0, [["coban", {1: 12, 2: 12}, 0]], {BOX: 0, PAW: 0}, "paw_box", ""],
	[22, 0, [["dolma", {2: 18, 4: 14}, 0]], {PAW: 0}, "paw_bottom", ""],
	[24, 2, [["gozleme", {5: 14, 4: 14}, 14], ["dolma", {2: 14, 4: 12}, 24]], {BOX: 0, PAW: 0}, "paw_box", ""],
	[22, 0, [["pide", {5: 16, 3: 16}, 0]], {}, "", ""],
	[18, 0, [["pide", {5: 10, 3: 8}, 0]], {KNOT: 0}, "knot_diamond", "knot"],
	[22, 0, [["omlet", {3: 14, 5: 12}, 0]], {KNOT: 0}, "knot_rows", ""],
	[22, 0, [["pide", {5: 10, 3: 10}, 14], ["mercimek", {4: 10, 1: 10}, 22]], {KNOT: 0}, "knot_diamond", ""],
	[22, 0, [["dolma", {2: 14, 4: 14}, 0]], {KNOT: 0, PAW: 0}, "knot_paw", ""],
	[22, 0, [["imam", {4: 14, 1: 12, 2: 10}, 0]], {}, "", ""],
	[22, 0, [["imam", {4: 12, 1: 12}, 0]], {KNOT: 0, BOX: 0}, "knot_box", ""],
	[18, 0, [["pide", {5: 8, 3: 8}, 0]], {KITTEN: 0}, "crate_two", "kitten"],
	[20, 1, [["imam", {4: 12, 1: 12}, 12], ["gozleme", {5: 12, 4: 10}, 20]], {KITTEN: 0}, "crate_two", ""],
	[22, 0, [["menemen", {1: 14, 2: 12, 3: 10}, 0]], {KITTEN: 0, BOX: 0}, "crate_box", ""],
	[22, 0, [["kahvalti", {5: 14, 1: 12, 3: 12}, 0]], {}, "", ""],
	[22, 0, [["kahvalti", {5: 12, 3: 12}, 0]], {KITTEN: 0, PAW: 0}, "crate_paw", ""],
	[22, 0, [["pide", {5: 10, 3: 10}, 14], ["imam", {4: 10, 1: 10}, 22]], {KNOT: 0}, "knot_rows", ""],
	[18, 0, [["kahvalti", {1: 8, 3: 8}, 0]], {MOUSE: 0}, "mouse_one", "mouse"],
	[22, 0, [["omlet", {3: 14, 5: 12}, 0]], {MOUSE: 0}, "mouse_two", ""],
	[22, 0, [["lahmacun", {1: 16, 4: 14}, 0]], {}, "", ""],
	[20, 1, [["lahmacun", {1: 12, 4: 12}, 12], ["kahvalti", {5: 12, 3: 10}, 20]], {MOUSE: 0}, "mouse_two", ""],
	[22, 0, [["dolma", {2: 14, 4: 12}, 0]], {MOUSE: 0, BOX: 0}, "mouse_box", ""],
	[22, 0, [["lahmacun", {1: 14, 4: 12}, 0]], {KITTEN: 0, KNOT: 0}, "crate_knot", ""],
	[18, 0, [["menemen", {1: 10, 3: 10}, 0]], {}, "belt_one", "belt"],
	[22, 0, [["karniyarik", {4: 14, 1: 12, 2: 12}, 0]], {}, "", ""],
	[22, 0, [["karniyarik", {4: 12, 1: 12}, 14], ["coban", {2: 10, 4: 10}, 22]], {}, "belt_two", ""],
	[22, 0, [["kahvalti", {5: 14, 3: 12}, 0]], {BOX: 0}, "belt_box", ""],
	[22, 0, [["gozleme", {5: 14, 4: 14}, 0]], {}, "heart", ""],
	[22, 0, [["lahmacun", {1: 12, 4: 12}, 0]], {MOUSE: 0}, "belt_mouse", ""],
	[22, 0, [["cilbir", {3: 16, 2: 14}, 0]], {}, "", ""],
	[20, 1, [["cilbir", {3: 12, 2: 12}, 12], ["karniyarik", {4: 12, 1: 10}, 20]], {KNOT: 0}, "corners_knot", ""],
	[22, 0, [["pide", {5: 14, 3: 12}, 0]], {PAW: 0}, "belt_paw", ""],
	[22, 0, [["imam", {4: 12, 1: 12}, 0]], {KITTEN: 0}, "ring_crate", ""],
	[24, 2, [["menemen", {1: 12, 2: 10}, 12], ["cilbir", {3: 12, 2: 10}, 18], ["karniyarik", {4: 12, 1: 10}, 24]], {KITTEN: 0, PAW: 0}, "finale", ""],
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
