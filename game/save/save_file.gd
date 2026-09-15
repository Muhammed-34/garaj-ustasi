class_name SaveFile
extends RefCounted


# Falls back to the backup when the main file is missing or unreadable.
static func read(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if parsed is Dictionary:
			return parsed
	return {}


# Writes to a temp file first so a crash mid-write never leaves a half-written save.
static func write(path: String, data: Dictionary) -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var main_abs := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(main_abs, ProjectSettings.globalize_path(path + ".bak"))
		DirAccess.remove_absolute(main_abs)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), main_abs) == OK
