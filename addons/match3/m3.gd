class_name M3
extends RefCounted

enum Special { NONE, LINE_H, LINE_V, BOMB, COLOR, FLYER }
# BOX, CRATE, SLEEPER and FUR fill their cell; KNOT sits on a tile and pins it in place.
# A SLEEPER (sleeping cat) regains a hit after every swap that did not disturb it.
# FUR creeps onto a neighbouring tile after every swap that cleared no fur.
# HOLE is not part of the board at all: never filled, never hit, tiles cannot fall through it.
# CAGE holds a cat; matches and blasts cannot open it, only a collected key.
enum Block { NONE, BOX, KNOT, CRATE, SLEEPER, FUR, HOLE, CAGE }

const EMPTY := 0
const MAX_CASCADES := 50
# A sack is a tile that never matches or explodes; it is collected at the bottom row.
const SACK := 9
# A key is an item like the sack; it is collected once it cannot fall any further and opens a cage.
# It sits below SACK so it never collides with the M3.GOAL_* keys that share the texture index space.
const KEY := 8
const SLEEPER_HP := 3

# Goal keys beyond tile kinds.
const GOAL_BOX := 10
const GOAL_PAW := 11
const GOAL_SACK := 12
const GOAL_KNOT := 13
const GOAL_KITTEN := 14
const GOAL_SLEEPER := 15
const GOAL_FUR := 16
const GOAL_CAGE := 17
const GOAL_MOUSE := 18

const STEP_SWAP := &"swap"
const STEP_CLEAR := &"clear"
const STEP_SPECIAL := &"special"
const STEP_FALL := &"fall"
const STEP_SPAWN := &"spawn"
const STEP_SHUFFLE := &"shuffle"
const STEP_GOAL := &"goal"
const STEP_BLOCKER := &"blocker"
const STEP_GROUND := &"ground"
const STEP_COLLECT := &"collect"
const STEP_DOZE := &"doze"
const STEP_SPREAD := &"spread"
const STEP_STAGE := &"stage"
const STEP_CATCH := &"catch"
const STEP_RUN := &"run"
const STEP_BELT := &"belt"

const BOOSTER_SINGLE := &"single"
const BOOSTER_ROW := &"row"
const BOOSTER_SHUFFLE := &"shuffle"


static func is_matchable(kind: int) -> bool:
	return kind > EMPTY and kind < KEY


# Items never match or explode and travel down the board to be collected.
static func is_item(kind: int) -> bool:
	return kind == SACK or kind == KEY
