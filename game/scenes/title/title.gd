extends Control

# Opening screen ("Mahalle Garajı"): a neighbourhood garage with the game's name on a metal sign and a
# freshly repaired car on the lift. Tapping the car makes it bounce and shine; sparkles idle unless motion is reduced.
const BUTTON_AREA := 400.0
const PLAY := Color("ff8a3d")
const CREAM := Color("fff4e8")
const LABEL_OUTLINE := Color("2b2f36")
const SHINE_FADE := 1.2

var garage: TitleGarage
var car: TextureRect
var play_button: Button
var recipes_button: Button
var settings_button: Button
var next_label: Label
var honks := 0


func _ready() -> void:
	garage = TitleGarage.new()
	garage.title_text = MetaRules.GAME_NAME
	add_child(garage)
	car = TextureRect.new()
	car.texture = ArtAtlas.texture("dish_kupa")
	car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(car)

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
	next_label = _floor_label(30)
	column.add_child(next_label)
	play_button = UiKit.button("Oyna", 54, Vector2(0, 136), PLAY, Color.WHITE, 68)
	play_button.pressed.connect(func() -> void: UiKit.go(&"map"))
	play_button.resized.connect(func() -> void: play_button.pivot_offset = play_button.size / 2.0)
	column.add_child(play_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	recipes_button = UiKit.button("Galeri", 30, Vector2(0, 100), Color.WHITE, LABEL_OUTLINE, 50)
	recipes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes_button.size_flags_stretch_ratio = 1.4
	recipes_button.pressed.connect(func() -> void: UiKit.go(&"recipes"))
	row.add_child(recipes_button)
	settings_button = UiKit.button("Ayarlar", 30, Vector2(0, 100), Color.WHITE, LABEL_OUTLINE, 50)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(func() -> void: UiKit.go(&"settings"))
	row.add_child(settings_button)
	var version := _floor_label(22)
	version.text = "Sürüm %s" % ProjectSettings.get_setting("application/config/version", "")
	column.add_child(version)

	resized.connect(_place_car)
	_place_car.call_deferred()
	_refresh()
	var moving := UiKit.idle_level() > 0
	set_process(moving)
	if moving:
		var pulse := create_tween().set_loops()
		pulse.tween_property(play_button, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	garage.shine = maxf(0.0, garage.shine - delta / SHINE_FADE)
	garage.time += delta


# Android back on the opening screen leaves the game.
func handle_back() -> void:
	get_tree().quit()


# The car bounces on its springs and its paint flashes.
func honk() -> void:
	honks += 1
	garage.shine = 1.0
	UiKit.sound(&"star", 0.8 + (honks % 3) * 0.12)
	var bounce := create_tween()
	bounce.tween_property(car, "scale", Vector2(1.04, 0.92), 0.08)
	bounce.tween_property(car, "scale", Vector2(0.97, 1.06), 0.12)
	bounce.tween_property(car, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
		next_label.text = "Müşteriler seni bekliyor"


# Taps that miss the buttons land here; one on the car makes it bounce.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if garage.car_rect().has_point(event.position):
			honk()


func _place_car() -> void:
	garage.stage_bottom = size.y - BUTTON_AREA
	var rect := garage.car_rect()
	car.position = rect.position
	car.size = rect.size
	# Bounce from the wheels, not the middle, so the car stays on the lift.
	car.pivot_offset = Vector2(rect.size.x * 0.5, rect.size.y * 109.0 / 120.0)


# Cream text with a dark outline, readable on the garage floor.
func _floor_label(font_size: int) -> Label:
	var label := UiKit.centered_label("", font_size, CREAM)
	label.add_theme_color_override("font_outline_color", LABEL_OUTLINE)
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 4))
	return label
