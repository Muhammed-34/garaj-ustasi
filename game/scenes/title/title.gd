extends Control

# Opening screen ("Çinili Mutfak"): a tiled kitchen with the game's name on a green board and menemen
# steaming on the stove. Tapping the pan stirs it; the steam idles gently unless motion is reduced.
const BUTTON_AREA := 400.0
const CREAM := Color("fff4e8")
const LABEL_OUTLINE := Color("1f1b19")
const PUFF_FADE := 1.5

var kitchen: TitleKitchen
var dish: TextureRect
var play_button: Button
var recipes_button: Button
var settings_button: Button
var next_label: Label
var stirs := 0


func _ready() -> void:
	kitchen = TitleKitchen.new()
	kitchen.title_text = MetaRules.GAME_NAME
	add_child(kitchen)
	dish = TextureRect.new()
	dish.texture = ArtAtlas.texture("dish_menemen")
	dish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dish)

	var column := VBoxContainer.new()
	column.anchor_left = 0.0
	column.anchor_right = 1.0
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_left = 30.0
	column.offset_right = -30.0
	column.offset_top = -BUTTON_AREA
	column.offset_bottom = -30.0
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	next_label = _stove_label(30)
	column.add_child(next_label)
	play_button = UiKit.button("Oyna", 54, Vector2(0, 136), UiKit.ACCENT, Color.WHITE, 68)
	play_button.pressed.connect(func() -> void: UiKit.go(&"map"))
	play_button.resized.connect(func() -> void: play_button.pivot_offset = play_button.size / 2.0)
	column.add_child(play_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	recipes_button = UiKit.button("Tarif Defteri", 30, Vector2(0, 100), CREAM, UiKit.INK, 50)
	recipes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes_button.size_flags_stretch_ratio = 1.4
	recipes_button.pressed.connect(func() -> void: UiKit.go(&"recipes"))
	row.add_child(recipes_button)
	settings_button = UiKit.button("Ayarlar", 30, Vector2(0, 100), CREAM, UiKit.INK, 50)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(func() -> void: UiKit.go(&"settings"))
	row.add_child(settings_button)
	var version := _stove_label(22)
	version.text = "Sürüm %s" % ProjectSettings.get_setting("application/config/version", "")
	column.add_child(version)

	resized.connect(_place_dish)
	_place_dish.call_deferred()
	_refresh()
	var moving := UiKit.idle_level() > 0
	set_process(moving)
	if moving:
		var pulse := create_tween().set_loops()
		pulse.tween_property(play_button, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	kitchen.puff = maxf(0.0, kitchen.puff - delta / PUFF_FADE)
	kitchen.time += delta


# Android back on the opening screen leaves the game.
func handle_back() -> void:
	get_tree().quit()


# The pan jiggles like it is being stirred and gives off a burst of steam.
func stir_pan() -> void:
	stirs += 1
	kitchen.puff = 1.0
	UiKit.sound(&"paw", 0.9 + (stirs % 3) * 0.15)
	var jiggle := create_tween()
	jiggle.tween_property(dish, "rotation", 0.08, 0.08)
	jiggle.tween_property(dish, "rotation", -0.06, 0.12)
	jiggle.tween_property(dish, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	var progress := UiKit.progress()
	if progress == null:
		return
	var unlocked := clampi(int(progress.data.unlocked), 1, Levels.COUNT)
	if progress.stars_for(Levels.COUNT) > 0:
		play_button.text = "Oyna"
		next_label.text = "Bütün bölümleri bitirdin!"
	elif unlocked > 1:
		play_button.text = "Devam et"
		next_label.text = "Sıradaki bölüm: %d" % unlocked
	else:
		play_button.text = "Oyna"
		next_label.text = "Masalar seni bekliyor"


# Taps that miss the buttons land here; one on the pan stirs it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if kitchen.dish_rect().has_point(event.position):
			stir_pan()


func _place_dish() -> void:
	var rect := kitchen.dish_rect()
	dish.position = rect.position
	dish.size = rect.size
	dish.pivot_offset = rect.size * 0.5


# Cream text with a dark outline, readable on the stove.
func _stove_label(font_size: int) -> Label:
	var label := UiKit.centered_label("", font_size, CREAM)
	label.add_theme_color_override("font_outline_color", LABEL_OUTLINE)
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 4))
	return label
