extends GdUnitTestSuite

const PATH := "user://test_save_file.json"


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func test_write_then_read_round_trips() -> void:
	assert_bool(SaveFile.write(PATH, {"coins": 120, "name": "Pamuk"})).is_true()
	var loaded := SaveFile.read(PATH)
	assert_int(int(loaded.coins)).is_equal(120)
	assert_str(loaded.name).is_equal("Pamuk")


func test_write_leaves_no_temp_file() -> void:
	SaveFile.write(PATH, {"a": 1})
	assert_bool(FileAccess.file_exists(PATH + ".tmp")).is_false()


func test_second_write_keeps_the_previous_save_as_backup() -> void:
	SaveFile.write(PATH, {"coins": 1})
	SaveFile.write(PATH, {"coins": 2})
	var backup = JSON.parse_string(FileAccess.get_file_as_string(PATH + ".bak"))
	assert_int(int(backup.coins)).is_equal(1)


func test_corrupt_save_falls_back_to_backup() -> void:
	SaveFile.write(PATH, {"coins": 1})
	SaveFile.write(PATH, {"coins": 2})
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ bozuk")
	file.close()
	assert_int(int(SaveFile.read(PATH).coins)).is_equal(1)


func test_missing_save_reads_as_empty() -> void:
	assert_dict(SaveFile.read("user://does_not_exist.json")).is_empty()
