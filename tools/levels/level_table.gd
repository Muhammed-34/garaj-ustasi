extends RefCounted

# Level design table shared by make_levels.gd (writes the .tres files) and tune.gd (balances them).
# Row: [moves, difficulty, goals, layout, sacks, intro, second-stage goals (optional)]
#   difficulty: 0 normal, 1 hard, 2 very hard
#   goals: tile kinds 1 food bowl, 2 yarn, 3 fish, 4 paw, 5 bell, or obstacle keys below.
#          An obstacle goal of 0 means every such obstacle in the layout.
#   layout: a LAYOUTS key, "" for a plain board. sacks: food sacks dropped during the level.
#   intro: mechanic explained once before the level (see INTROS in game.gd).
# tune.gd scales the tile goal counts (or, for obstacle-only levels, the moves) and prints rows to paste back.
# Levels 1-5 are set by hand well below the tuned values: the bot plays far better than a first-time player.
const BOX := M3.GOAL_BOX
const PAW := M3.GOAL_PAW
const SACK := M3.GOAL_SACK
const KNOT := M3.GOAL_KNOT
const KITTEN := M3.GOAL_KITTEN
const SLEEPER := M3.GOAL_SLEEPER
const FUR := M3.GOAL_FUR
const CAGE := M3.GOAL_CAGE
const MOUSE := M3.GOAL_MOUSE
const GOAL_NAMES := {BOX: "BOX", PAW: "PAW", SACK: "SACK", KNOT: "KNOT", KITTEN: "KITTEN", SLEEPER: "SLEEPER", FUR: "FUR", CAGE: "CAGE", MOUSE: "MOUSE"}

const LAYOUTS := {
	"box_center": [".......", ".......", "..111..", "..111..", ".......", ".......", "......."],
	"box_corners": ["11...11", "1.....1", ".......", ".......", ".......", "1.....1", "11...11"],
	"box_wall": [".......", ".......", ".......", "2211122", ".......", ".......", "......."],
	"box_bottom": [".......", ".......", ".......", ".......", "1111111", "2222222", "......."],
	"paw_center": [".......", ".......", "..PPP..", "..PPP..", "..PPP..", ".......", "......."],
	"paw_x": ["P.....P", ".P...P.", "..P.P..", "...P...", "..P.P..", ".P...P.", "P.....P"],
	"paw_bottom": [".......", ".......", ".......", ".......", "PPPPPPP", "PPPPPPP", "PPPPPPP"],
	"paw_box": ["..111..", ".......", "PPPPPPP", "P.....P", "PPPPPPP", ".......", "..111.."],
	"sack_boxes": [".......", ".......", ".......", "1.1.1.1", ".......", ".......", "......."],
	"knot_diamond": [".......", "...K...", "..K.K..", ".K...K.", "..K.K..", "...K...", "......."],
	"knot_rows": [".......", ".......", "K.K.K.K", ".......", "K.K.K.K", ".......", "......."],
	"knot_paw": [".......", "PPPPPPP", ".K.K.K.", "PPPPPPP", ".......", ".......", "......."],
	"knot_box": [".......", "2.....2", ".K.K.K.", "2.....2", ".K.K.K.", ".......", "......."],
	"crate_one": [".......", ".......", ".......", "...C...", ".......", ".......", "......."],
	"crate_two": [".......", ".......", ".C...C.", ".......", ".......", ".......", "......."],
	"crate_box": [".......", "..1C1..", "..111..", ".......", ".......", ".......", "......."],
	"crate_paw": [".......", "PPPPPPP", ".C...C.", "PPPPPPP", ".......", ".......", "......."],
	"crate_knot": [".......", "..K.K..", ".C...C.", "..K.K..", ".......", ".......", "......."],
	"finale": [".......", "1C1.1C1", "PPPPPPP", ".......", "PPPPPPP", ".......", "......."],
	"sleep_one": [".......", ".......", ".......", "...Z...", ".......", ".......", "......."],
	"sleep_two": [".......", ".......", ".Z...Z.", ".......", ".......", ".......", "......."],
	"sleep_box": [".......", ".......", "..1Z1..", ".......", ".......", ".......", "......."],
	"sleep_paw": [".......", "PPPPPPP", ".Z...Z.", "PPPPPPP", ".......", ".......", "......."],
	"sleep_corners": [".......", ".Z...Z.", ".......", ".......", ".......", ".Z...Z.", "......."],
	"sleep_crate": [".......", ".C...C.", ".......", "...Z...", ".......", ".......", "......."],
	"sleep_knot": [".......", "..K.K..", ".Z.Z.Z.", "..K.K..", ".......", ".......", "......."],
	"fur_center": [".......", ".......", ".......", "..FFF..", ".......", ".......", "......."],
	"fur_corner": ["FF.....", "F......", ".......", ".......", ".......", "......F", ".....FF"],
	"fur_box": [".......", "..1.1..", "...F...", "..1.1..", ".......", ".......", "......."],
	"fur_crate": [".......", ".C...C.", ".......", "..FFF..", ".......", ".......", "......."],
	"fur_paw": [".......", ".......", "PPPPPPP", "...F...", "PPPPPPP", ".......", "......."],
	"fur_sleep": [".......", ".Z...Z.", ".......", "...F...", ".......", ".......", "......."],
	"fur_knot": [".......", "..K.K..", "...F...", "..K.K..", ".......", ".......", "......."],
	"fur_rows": [".......", "F.....F", ".......", ".......", ".......", "F.....F", "......."],
	# Shaped boards ("#" is a hole). Sacks need a full bottom row, so sack levels never use these.
	"heart": ["#..#..#", ".......", ".......", ".......", "#.....#", "##...##", "###.###"],
	"diamond": ["###.###", "##...##", "#.....#", ".......", "#.....#", "##...##", "###.###"],
	"ring_box": [".......", ".1...1.", "..###..", "..###..", "..###..", ".1...1.", "......."],
	"cross_paw": ["##...##", "##PPP##", "P.....P", "P.....P", "P.....P", "##PPP##", "##...##"],
	"heart_mix": ["#..#..#", ".......", ".Z...Z.", "...F...", "#.....#", "##...##", "###.###"],
	"corners_knot": ["#.....#", ".K...K.", ".......", "..K.K..", ".......", ".K...K.", "#.....#"],
	"cross": ["##...##", "##...##", ".......", ".......", ".......", "##...##", "##...##"],
	"ring_crate": [".......", ".C...C.", "..###..", "..###..", "..###..", ".......", "......."],
	"diamond_fur": ["###.###", "##...##", "#..F..#", ".......", "#.....#", "##...##", "###.###"],
	"cross_sleep": ["##...##", "##...##", ".Z...Z.", ".......", ".......", "##...##", "##...##"],
	"box_sleep": ["11...11", "1.....1", ".......", ".Z...Z.", ".......", "1.....1", "11...11"],
	"cross_paw_fur": ["##...##", "##PPP##", "P..F..P", "P.....P", "P..F..P", "##PPP##", "##...##"],
	# Cages ("G"): every cage gets one key dropped during the level.
	"cage_one": [".......", ".......", ".......", "...G...", ".......", ".......", "......."],
	"cage_two": [".......", "..G.G..", ".......", ".......", ".......", ".......", "......."],
	"cage_box": [".......", ".......", "1.G.G.1", ".......", ".......", ".......", "......."],
	"cage_paw": [".......", "..G.G..", ".......", "PPPPPPP", ".......", ".......", "......."],
	"cage_fur": [".......", ".G...G.", ".......", "...F...", ".......", ".......", "......."],
	"cage_sleep": [".......", "..G.G..", ".......", ".Z...Z.", ".......", ".......", "......."],
	"cage_three": [".......", ".G.G.G.", ".......", ".......", ".......", ".......", "......."],
	# Mice ("M") start on a tile and run to a neighbouring tile after every swap.
	"mouse_one": [".......", ".......", ".......", "...M...", ".......", ".......", "......."],
	"mouse_two": [".......", ".M...M.", ".......", ".......", ".......", ".......", "......."],
	"mouse_box": [".......", ".M...M.", ".......", "..111..", ".......", ".......", "......."],
	"mouse_paw": [".......", "PPPPPPP", ".M...M.", "PPPPPPP", ".......", ".......", "......."],
	"mouse_three": [".......", ".......", ".M.M.M.", ".......", ".......", ".......", "......."],
	"sleep_mouse": [".......", ".Z...Z.", ".......", "...M...", ".......", ".......", "......."],
	"knot_mouse": [".......", "..K.K..", ".M...M.", "..K.K..", ".......", ".......", "......."],
	# Conveyor belts (">" right, "<" left) turn once after every swap; no obstacles on belt cells.
	"belt_one": [".......", ".......", ".......", ">>>>>>>", ".......", ".......", "......."],
	"belt_two": [".......", ">>>>>>>", ".......", ".......", ".......", "<<<<<<<", "......."],
	"belt_box": [".......", "..1.1..", ">>>>>>>", "..1.1..", ".......", ".......", "......."],
	"belt_mouse": [".......", ".M...M.", ".......", ">>>>>>>", ".......", ".......", "......."],
	"belt_paw": [".......", "PPPPPPP", ">>>>>>>", ".......", "<<<<<<<", "PPPPPPP", "......."],
}

const TABLE := [
	[20, 0, {1: 18}, "", 0, "basics"],
	[20, 0, {3: 18}, "", 0, ""],
	[20, 0, {1: 20, 2: 20}, "", 0, ""],
	[22, 0, {4: 26, 5: 20}, "", 0, "line"],
	[20, 0, {1: 24, 3: 22}, "", 0, ""],
	[20, 0, {2: 28}, "", 0, ""],  # bot 0.97
	[20, 0, {3: 33, 5: 27}, "", 0, "bomb"],  # bot 0.97
	[20, 0, {1: 32, 4: 29}, "", 0, ""],  # bot 0.97
	[20, 1, {2: 44, 3: 41, 5: 36}, "", 0, ""],  # bot 0.63
	[22, 0, {1: 33, 2: 28, 4: 28}, "", 0, ""],  # bot 0.95
	[20, 0, {5: 33, 2: 29}, "", 0, "flyer"],  # bot 0.95
	[22, 0, {1: 37, 3: 37}, "", 0, ""],  # bot 0.95
	[20, 0, {4: 29}, "", 0, ""],  # bot 0.95
	[22, 0, {2: 34, 3: 34, 4: 34}, "", 0, "color"],  # bot 0.95
	[20, 0, {1: 26, 5: 22}, "", 0, ""],  # bot 0.95
	[20, 0, {3: 28}, "", 0, ""],  # bot 0.95
	[22, 0, {1: 27, 2: 27, 5: 27}, "", 0, ""],  # bot 0.95
	[15, 0, {BOX: 0}, "box_center", 0, "box"],  # bot 1.00
	[20, 1, {BOX: 0, 1: 43}, "box_corners", 0, ""],  # bot 0.60
	[22, 0, {BOX: 0, 3: 35}, "box_wall", 0, ""],  # bot 0.95
	[20, 0, {2: 36, 5: 36}, "", 0, ""],  # bot 0.85
	[22, 0, {BOX: 0, 2: 38}, "box_corners", 0, ""],  # bot 0.85
	[22, 0, {1: 41, 2: 41, 3: 41}, "", 0, ""],  # bot 0.85
	[22, 0, {BOX: 0, 4: 34}, "box_bottom", 0, ""],  # bot 0.85
	[20, 0, {3: 32, 4: 32}, "", 0, ""],  # bot 0.85
	[15, 0, {PAW: 0}, "paw_center", 0, "paw"],  # bot 1.00
	[20, 1, {PAW: 0, 1: 42}, "paw_x", 0, ""],  # bot 0.68
	[22, 0, {PAW: 0, 5: 41}, "paw_bottom", 0, ""],  # bot 0.85
	[22, 0, {BOX: 0, 2: 33, 3: 33}, "box_wall", 0, ""],  # bot 0.85
	[24, 2, {PAW: 0, BOX: 0, 1: 64}, "paw_box", 0, ""],  # bot 0.45
	[20, 0, {5: 36}, "", 0, ""],  # bot 0.85
	[22, 0, {PAW: 0, 2: 39}, "paw_center", 0, ""],  # bot 0.88
	[22, 0, {BOX: 0, 1: 43}, "box_center", 0, ""],  # bot 0.85
	[18, 0, {SACK: 3}, "", 3, "sack"],  # bot 0.95 at 15; raised after emulator play: pushing sacks alone used 14 of 15
	[22, 0, {SACK: 4, 3: 15}, "", 4, ""],  # bot 0.93
	[22, 0, {PAW: 0, 3: 38}, "paw_x", 0, ""],  # bot 0.90
	[22, 0, {SACK: 4, 1: 25}, "sack_boxes", 4, ""],  # bot 0.85
	[22, 0, {1: 39, 4: 39, 5: 39}, "", 0, ""],  # bot 0.88
	[20, 1, {SACK: 5, 2: 20}, "", 5, ""],  # bot 0.63
	[22, 0, {BOX: 0, PAW: 0, 5: 31}, "paw_box", 0, ""],  # bot 0.85
	[22, 0, {SACK: 5, 4: 14}, "", 5, ""],  # bot 0.88
	[15, 0, {KNOT: 0}, "knot_diamond", 0, "knot"],  # bot 1.00
	[22, 0, {KNOT: 0, 5: 42}, "knot_rows", 0, ""],  # bot 0.88
	[22, 0, {SACK: 4, PAW: 0, 2: 29}, "paw_center", 4, ""],  # bot 0.85
	[22, 0, {KNOT: 0, PAW: 0, 3: 43}, "knot_paw", 0, ""],  # bot 0.85
	[20, 0, {3: 41, 1: 32}, "", 0, ""],  # bot 0.85
	[20, 1, {KNOT: 0, BOX: 0, 4: 39}, "knot_box", 0, ""],  # bot 0.60
	[24, 0, {SACK: 4, KNOT: 0, 1: 13}, "knot_diamond", 4, ""],  # bot 0.85
	[22, 0, {PAW: 0, 2: 36, 4: 36}, "paw_bottom", 0, ""],  # bot 0.85
	[22, 0, {KNOT: 0, SACK: 4, 2: 18}, "knot_rows", 4, ""],  # bot 0.85
	[22, 0, {BOX: 0, PAW: 0, 5: 31}, "paw_box", 0, ""],  # bot 0.85
	[15, 0, {KITTEN: 0}, "crate_two", 0, "kitten"],  # one crate took 2 moves in emulator play
	[22, 0, {KITTEN: 0, 1: 42}, "crate_two", 0, ""],  # bot 0.88
	[24, 0, {SACK: 4, 3: 30}, "", 4, ""],  # bot 0.88
	[22, 0, {KITTEN: 0, BOX: 0, 3: 43}, "crate_box", 0, ""],  # bot 0.85
	[22, 0, {KNOT: 0, PAW: 0, 1: 38}, "knot_paw", 0, ""],  # bot 0.88
	[20, 1, {KITTEN: 0, PAW: 0, 4: 46}, "crate_paw", 0, ""],  # bot 0.63
	[22, 0, {SACK: 5, BOX: 0, 2: 15}, "sack_boxes", 5, ""],  # bot 0.85
	[22, 0, {KITTEN: 0, KNOT: 0, 5: 39}, "crate_knot", 0, ""],  # bot 0.88
	[24, 2, {KITTEN: 0, PAW: 0, 1: 60}, "finale", 0, ""],  # bot 0.47
	[22, 0, {1: 43, 3: 43}, "", 0, ""],  # bot 0.85
	[15, 0, {SLEEPER: 0}, "sleep_one", 0, "sleeper"],  # bot 1.00
	[22, 0, {SLEEPER: 0, 2: 33}, "sleep_two", 0, ""],  # bot 0.88
	[22, 0, {BOX: 0, 4: 40}, "box_wall", 0, ""],  # bot 0.85
	[22, 0, {SLEEPER: 0, BOX: 0, 5: 40}, "sleep_box", 0, ""],  # bot 0.88
	[22, 0, {SACK: 4, 1: 22}, "", 4, ""],  # bot 0.85
	[22, 0, {SLEEPER: 0, PAW: 0, 3: 44}, "sleep_paw", 0, ""],  # bot 0.85
	[22, 0, {KNOT: 0, 2: 42}, "knot_rows", 0, ""],  # bot 0.85
	[20, 1, {SLEEPER: 0, 1: 36}, "sleep_corners", 0, ""],  # bot 0.60
	[22, 0, {KITTEN: 0, SLEEPER: 0, 4: 39}, "sleep_crate", 0, ""],  # bot 0.88
	[22, 0, {SLEEPER: 0, KNOT: 0, 5: 33}, "sleep_knot", 0, ""],  # bot 0.85
	[22, 0, {2: 38, 4: 38}, "", 0, ""],  # bot 0.88
	# Sleeping cats and sacks leave no room for a tile goal (the tuner cut it to 3), so only moves are tuned.
	[23, 0, {SLEEPER: 0, SACK: 4}, "sleep_two", 4, ""],  # bot 0.90
	[15, 0, {FUR: 0}, "fur_center", 0, "fur"],  # bot 1.00
	[22, 0, {FUR: 0, 2: 35}, "fur_center", 0, ""],  # bot 0.85
	[22, 0, {SLEEPER: 0, 3: 36}, "sleep_two", 0, ""],  # bot 0.85
	[20, 1, {FUR: 0, 1: 41}, "fur_corner", 0, ""],  # bot 0.65
	[22, 0, {3: 39, 5: 39}, "", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, BOX: 0, 4: 43}, "fur_box", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, KITTEN: 0, 2: 39}, "fur_crate", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, PAW: 0, 5: 38}, "fur_paw", 0, ""],  # bot 0.88
	[22, 0, {SACK: 4, 1: 22}, "", 4, ""],  # bot 0.85
	[22, 0, {FUR: 0, SLEEPER: 0, 3: 34}, "fur_sleep", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, KNOT: 0, 4: 44}, "fur_knot", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, 1: 40, 2: 40}, "fur_rows", 0, ""],  # bot 0.90
	[22, 0, {2: 27, 5: 27}, "heart", 0, ""],  # bot 0.85
	[20, 1, {1: 24, 4: 24}, "diamond", 0, ""],  # bot 0.63
	[22, 0, {BOX: 0, 3: 17}, "ring_box", 0, ""],  # bot 0.85
	[22, 0, {PAW: 0, 2: 26}, "cross_paw", 0, ""],  # bot 0.85
	[24, 2, {FUR: 0, SLEEPER: 0, 1: 39}, "heart_mix", 0, ""],  # bot 0.50
	[22, 0, {KNOT: 0, 5: 33}, "corners_knot", 0, ""],  # bot 0.88
	[22, 0, {3: 28, 4: 28}, "cross", 0, ""],  # bot 0.85
	[22, 0, {KITTEN: 0, 2: 18}, "ring_crate", 0, ""],  # bot 0.85
	[22, 0, {FUR: 0, 1: 24}, "diamond_fur", 0, ""],  # bot 0.85
	[22, 0, {SLEEPER: 0, 5: 27}, "cross_sleep", 0, ""],  # bot 0.88
	[22, 0, {BOX: 0}, "box_center", 0, "stages", {3: 34}],  # bot 0.85
	[22, 0, {1: 39}, "sleep_two", 0, "", {SLEEPER: 0}],  # bot 0.85
	[22, 0, {PAW: 0}, "paw_center", 0, "", {2: 32, 4: 32}],  # bot 0.85
	[20, 1, {KNOT: 0}, "knot_rows", 0, "", {5: 28}],  # bot 0.63
	[24, 0, {KITTEN: 0}, "crate_two", 0, "", {1: 36, 3: 36}],  # bot 0.90
	[22, 0, {FUR: 0}, "fur_center", 0, "", {2: 31}],  # bot 0.85
	[22, 0, {3: 15}, "heart", 0, "", {4: 15}],  # bot 0.85
	[22, 0, {BOX: 0, 1: 40}, "box_sleep", 0, "", {SLEEPER: 0}],  # bot 0.85
	[22, 0, {SACK: 3}, "", 3, "", {5: 16}],  # bot 0.90
	[15, 0, {PAW: 0}, "cross_paw_fur", 0, "", {FUR: 0}],  # bot 0.88
	[22, 0, {1: 33, 5: 33}, "", 0, ""],  # bot 0.85
	[20, 1, {SLEEPER: 0, 2: 41}, "sleep_corners", 0, ""],  # bot 0.63
	[15, 0, {CAGE: 0}, "cage_one", 0, "cage"],  # bot 1.00
	[22, 0, {CAGE: 0, 3: 32}, "cage_two", 0, ""],  # bot 0.85
	[22, 0, {CAGE: 0, BOX: 0, 4: 32}, "cage_box", 0, ""],  # bot 0.85
	[15, 0, {CAGE: 0, PAW: 0}, "cage_paw", 0, ""],  # bot 0.95
	[22, 0, {2: 23, 4: 23}, "diamond", 0, ""],  # bot 0.88
	[22, 0, {CAGE: 0, FUR: 0, 1: 28}, "cage_fur", 0, ""],  # bot 0.85
	[22, 0, {CAGE: 0}, "cage_sleep", 0, "", {SLEEPER: 0, 3: 21}],  # bot 0.85
	[22, 0, {CAGE: 0, 2: 26}, "cage_three", 0, ""],  # bot 0.85
	[22, 0, {3: 37, 4: 37}, "", 0, ""],  # bot 0.85
	[20, 1, {CAGE: 0, 1: 40}, "cage_two", 0, ""],  # bot 0.60
	[22, 0, {KNOT: 0, FUR: 0, 5: 42}, "fur_knot", 0, ""],  # bot 0.88
	[22, 0, {BOX: 0}, "box_corners", 0, "", {2: 18}],  # bot 0.85
	[24, 2, {SLEEPER: 0, CAGE: 0, 3: 49}, "cage_sleep", 0, ""],  # bot 0.45
	[22, 0, {PAW: 0, 1: 34}, "paw_x", 0, ""],  # bot 0.85
	[15, 0, {MOUSE: 0}, "mouse_one", 0, "mouse"],  # bot 1.00
	[22, 0, {MOUSE: 0, 2: 41}, "mouse_two", 0, ""],  # bot 0.85
	[22, 0, {MOUSE: 0, BOX: 0, 4: 43}, "mouse_box", 0, ""],  # bot 0.85
	[15, 0, {MOUSE: 0, PAW: 0}, "mouse_paw", 0, ""],  # bot 0.97
	[22, 0, {2: 42, 5: 42}, "", 0, ""],  # bot 0.85
	[20, 1, {MOUSE: 0, 3: 49}, "mouse_two", 0, ""],  # bot 0.60
	[22, 0, {CAGE: 0, FUR: 0, 4: 33}, "cage_fur", 0, ""],  # bot 0.85
	[22, 0, {SACK: 4, 2: 25}, "", 4, ""],  # bot 0.88
	[22, 0, {MOUSE: 0}, "mouse_three", 0, "", {1: 36}],  # bot 0.90
	[22, 0, {KITTEN: 0, 4: 16}, "ring_crate", 0, ""],  # bot 0.90
	[22, 0, {SLEEPER: 0, MOUSE: 0, 5: 40}, "sleep_mouse", 0, ""],  # bot 0.85
	[22, 0, {1: 24, 3: 24}, "cross", 0, ""],  # bot 0.85
	[15, 0, {KNOT: 0, MOUSE: 0}, "knot_mouse", 0, ""],  # bot 1.00
	[22, 0, {BOX: 0, CAGE: 0, 2: 31}, "cage_box", 0, ""],  # bot 0.85
	[18, 0, {3: 30}, "belt_one", 0, "belt"],  # tuner asked 52 (bot 0.85); kept low so the belt intro stays gentle
	[20, 1, {1: 71, 4: 71}, "belt_two", 0, ""],  # bot 0.65; belts line up free cascades, so tile goals run high
	[22, 0, {BOX: 0, 2: 61}, "belt_box", 0, ""],  # bot 0.85
	[22, 0, {MOUSE: 0, 5: 59}, "belt_mouse", 0, ""],  # bot 0.85
	[22, 0, {PAW: 0, 3: 81}, "belt_paw", 0, ""],  # bot 0.88
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
	level.layout = PackedStringArray(LAYOUTS.get(row[3], []))
	level.sacks = row[4]
	level.keys = layout_count(level.layout, CAGE)
	level.intro = row[5]
	level.rng_seed = 1000 + level.id
	for key in row[2]:
		level.goals[key] = _goal_count(level, key, row[2][key])
	if row.size() > 6:
		for key in row[6]:
			level.goals_2[key] = _goal_count(level, key, row[6][key])
	return level


# An obstacle goal of 0 means every such obstacle in the layout (or every sack dropped).
static func _goal_count(level: M3LevelDef, key: int, count: int) -> int:
	if count != 0:
		return count
	return level.sacks if key == SACK else layout_count(level.layout, key)


static func layout_count(layout: PackedStringArray, key: int) -> int:
	var symbols: String = {BOX: "12", KITTEN: "C", KNOT: "K", PAW: "P", SLEEPER: "Z", FUR: "F", CAGE: "G", MOUSE: "M"}.get(key, "")
	var count := 0
	for row in layout:
		for ch in row:
			if symbols.contains(ch):
				count += 1
	return count
