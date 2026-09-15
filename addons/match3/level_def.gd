class_name M3LevelDef
extends Resource

@export var id := 1
@export_range(3, 9) var width := 7
@export_range(3, 9) var height := 7
@export_range(3, 6) var kind_count := 5
@export_range(1, 99) var moves := 20
# Keys are tile kinds (1-5) or M3.GOAL_* values.
@export var goals: Dictionary[int, int] = {}
# Second stage: opens with the same moves once every goal above is done. Empty means one stage.
@export var goals_2: Dictionary[int, int] = {}
@export var rng_seed := 1
@export_enum("Normal", "Zor", "Çok zor") var difficulty := 0
# Rows of M3Board.apply_layout characters; empty means a plain board.
@export var layout := PackedStringArray()
@export_range(0, 40) var sacks := 0
# Keys dropped during the level; each collected key opens one cage.
@export_range(0, 40) var keys := 0
# Mechanic introduced on this level, shown once before play.
@export var intro := ""
