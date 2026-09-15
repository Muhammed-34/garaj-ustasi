extends SceneTree

# Writes data/levels/*.tres from tools/levels/level_table.gd. Edit the table, then run:
#   godot --headless --path . -s tools/levels/make_levels.gd
const LevelTable := preload("res://tools/levels/level_table.gd")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/levels"))
	for i in LevelTable.TABLE.size():
		var level: M3LevelDef = LevelTable.build(i)
		var path := Levels.PATH % level.id
		print("%s -> %s" % [path, error_string(ResourceSaver.save(level, path))])
	quit()
