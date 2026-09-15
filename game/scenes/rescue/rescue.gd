extends Control

var level_id := -1
var breed := "tekir"
var name_input: LineEdit
var suggestion_buttons: Array[Button] = []
var cat_rig: CatRig


func _ready() -> void:
	var progress := UiKit.progress()
	var fallback: int = progress.next_pending_rescue_level() if progress else -1
	level_id = int(UiKit.router_params().get("level_id", fallback))
	if progress:
		breed = progress.pending_rescue_breed()

	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 26)
	page.add_child(column)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 380)
	column.add_child(stage)
	cat_rig = CatRig.new()
	stage.add_child(cat_rig)
	stage.resized.connect(func() -> void: cat_rig.position = Vector2(stage.size.x / 2.0, stage.size.y))
	cat_rig.setup(breed, 340.0, UiKit.idle_level())

	column.add_child(UiKit.centered_label("Yeni bir dost!", 64))
	var breed_word := str(MetaRules.BREED_LABELS.get(breed, "")).to_lower()
	column.add_child(UiKit.centered_label("Bu %s kediyi sen kurtardın.\nOna bir isim ver." % breed_word, 30, UiKit.MUTED))

	name_input = LineEdit.new()
	name_input.custom_minimum_size = Vector2(0, 100)
	name_input.max_length = MetaRules.MAX_NAME_LENGTH
	name_input.placeholder_text = "Kedinin adı"
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.add_theme_font_size_override("font_size", 42)
	name_input.add_theme_color_override("font_color", UiKit.INK)
	name_input.add_theme_color_override("font_placeholder_color", UiKit.MUTED)
	name_input.add_theme_color_override("caret_color", UiKit.ACCENT)
	name_input.add_theme_stylebox_override("normal", UiKit.box(Color.WHITE, 26, 16))
	var focus := UiKit.box(Color.WHITE, 26, 16)
	focus.set_border_width_all(4)
	focus.border_color = UiKit.ACCENT
	name_input.add_theme_stylebox_override("focus", focus)
	column.add_child(name_input)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 14)
	column.add_child(chips)
	var taken: Array = progress.cats().map(func(cat: Dictionary) -> String: return str(cat.name)) if progress else []
	for suggestion in MetaRules.suggest_names(taken, 3, level_id * 31 + taken.size()):
		var chip := UiKit.button(suggestion, 30, Vector2(190, 84), Color.WHITE, UiKit.INK, 42)
		chip.pressed.connect(func() -> void: name_input.text = suggestion)
		chips.add_child(chip)
		suggestion_buttons.append(chip)

	var confirm := UiKit.button("Barınağa götür", 36, Vector2(0, 112), UiKit.ACCENT, Color.WHITE, 56)
	confirm.pressed.connect(_on_confirm)
	column.add_child(confirm)
	UiKit.sound(&"meow")


# On phones Back first closes the keyboard; only a Back without it leaves, and an empty name gets a suggestion.
func handle_back() -> void:
	if name_input.has_focus():
		name_input.release_focus()
		return
	_on_confirm()


func save_rescue() -> Dictionary:
	var progress := UiKit.progress()
	return progress.rescue_cat(level_id, name_input.text) if progress else {}


func _on_confirm() -> void:
	save_rescue()
	UiKit.go(&"shelter")
