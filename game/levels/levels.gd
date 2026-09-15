class_name Levels
extends RefCounted

const COUNT := 140
const PATH := "res://data/levels/level_%03d.tres"


static func load_level(id: int) -> M3LevelDef:
	return load(PATH % clampi(id, 1, COUNT))
