extends Control

# Opening screen ("Sıcak Salon"): the shelter's living room with the game's name on a hanging sign.
# Cats sit on the rug and hop when tapped; the room idles gently unless motion is reduced.
const CATS := [
	{"breed": "tarcin", "x": 0.24, "height": 250.0},
	{"breed": "tekir", "x": 0.5, "height": 320.0},
	{"breed": "pamuk", "x": 0.76, "height": 250.0},
]
# The middle cat is added last so it sits in front of its neighbours.
const DRAW_ORDER := [0, 2, 1]
const BUTTON_AREA := 400.0
const CREAM := Color("fff4e8")
const LABEL_OUTLINE := Color("7a4a2a")

var room: TitleRoom
var play_button: Button
var shelter_button: Button
var settings_button: Button
var next_label: Label
var cat_rigs: Array[CatRig] = []
var pets := 0


func _ready() -> void:
	room = TitleRoom.new()
	room.title_text = MetaRules.GAME_NAME
	add_child(room)
	for entry in CATS:
		var rig := CatRig.new()
		rig.setup(entry.breed, entry.height, UiKit.idle_level())
		cat_rigs.append(rig)
	for n in DRAW_ORDER:
		add_child(cat_rigs[n])

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
	play_button = UiKit.button("Oyna", 54, Vector2(0, 136), UiKit.ACCENT, Color.WHITE, 68)
	play_button.pressed.connect(func() -> void: UiKit.go(&"map"))
	play_button.resized.connect(func() -> void: play_button.pivot_offset = play_button.size / 2.0)
	column.add_child(play_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	shelter_button = UiKit.button("Barınak", 32, Vector2(0, 100), CREAM, UiKit.INK, 50)
	shelter_button.icon = ArtAtlas.texture("cat_tekir_face")
	shelter_button.add_theme_constant_override("icon_max_width", 64)
	shelter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelter_button.pressed.connect(func() -> void: UiKit.go(&"shelter"))
	row.add_child(shelter_button)
	settings_button = UiKit.button("Ayarlar", 32, Vector2(0, 100), CREAM, UiKit.INK, 50)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(func() -> void: UiKit.go(&"settings"))
	row.add_child(settings_button)
	var version := _floor_label(22)
	version.text = "Sürüm %s" % ProjectSettings.get_setting("application/config/version", "")
	column.add_child(version)

	resized.connect(_place_cats)
	_place_cats.call_deferred()
	_refresh()
	var moving := UiKit.idle_level() > 0
	set_process(moving)
	if moving:
		var pulse := create_tween().set_loops()
		pulse.tween_property(play_button, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	room.time += delta


# Android back on the opening screen leaves the game.
func handle_back() -> void:
	get_tree().quit()


func pet_cat(index: int) -> void:
	if index < 0 or index >= cat_rigs.size():
		return
	pets += 1
	var rig := cat_rigs[index]
	UiKit.sound(&"paw", 1.0 + index * 0.2)
	var hop := create_tween()
	hop.tween_property(rig, "scale", Vector2(1.1, 0.88), 0.08)
	hop.tween_property(rig, "scale", Vector2(0.94, 1.1), 0.12)
	hop.tween_property(rig, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var star := TextureRect.new()
	star.texture = ArtAtlas.texture("star_on")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.size = Vector2(60, 60)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.position = rig.position + Vector2(-30, -float(CATS[index].height) - 30.0)
	add_child(star)
	var rise := create_tween().set_parallel()
	rise.tween_property(star, "position:y", star.position.y - 90.0, 0.7).set_ease(Tween.EASE_OUT)
	rise.tween_property(star, "modulate:a", 0.0, 0.7)
	rise.chain().tween_callback(star.queue_free)


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
		next_label.text = "Kediler seni bekliyor"


# Taps that miss the buttons land here; the nearest cat under the finger hops.
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var best := -1
	var best_distance := INF
	for n in cat_rigs.size():
		var rig := cat_rigs[n]
		var height := float(CATS[n].height)
		if event.position.y < rig.position.y - height or event.position.y > rig.position.y + 20.0:
			continue
		var distance := absf(event.position.x - rig.position.x)
		if distance < height * 0.38 and distance < best_distance:
			best = n
			best_distance = distance
	pet_cat(best)


func _place_cats() -> void:
	for n in cat_rigs.size():
		cat_rigs[n].position = Vector2(size.x * float(CATS[n].x), size.y * TitleRoom.RUG_Y + 8.0)


# Cream text with a wood-brown outline, readable on the plank floor.
func _floor_label(font_size: int) -> Label:
	var label := UiKit.centered_label("", font_size, CREAM)
	label.add_theme_color_override("font_outline_color", LABEL_OUTLINE)
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 4))
	return label
