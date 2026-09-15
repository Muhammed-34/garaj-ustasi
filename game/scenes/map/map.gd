extends Control

const NODE_SIZE := 150.0
const NODE_RADIUS := 75
const BOTTOM_ROOM := 90.0

static var _calendar_offered_on := ""
# Level opened from the map this session; the map reopens there. 0 means none yet.
static var last_opened_level := 0

var level_buttons: Array[Button] = []
var recipes_button: Button
var gift_button: Button
var calendar_cells: Array[PanelContainer] = []
var recipe_markers := {}
var bottom_button: Button
var next_button: Button
var home_button: Button
var finale_card: PanelContainer
var bowl_icons: Array[TextureRect] = []

var _bowl_label: Label
var _bowls_rows: VBoxContainer
var _bowls_wait_label: Label
var _refill_button: Button
var coins_short_label: Label
var _bowl_lost_rows: VBoxContainer
var _bowl_tick := 0.0

var _star_rows := {}
var _coins_label: Label
var _scroll: DragScroll
var _calendar_rows: VBoxContainer
var _claim_button: Button


func _ready() -> void:
	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	page.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	column.add_child(top)
	home_button = UiKit.button("‹", 44, Vector2(72, 72))
	home_button.pressed.connect(func() -> void: UiKit.go(&"title"))
	top.add_child(home_button)
	var title := UiKit.label(MetaRules.GAME_NAME, 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	var coins := UiKit.pill("", Color.WHITE, UiKit.INK, 28)
	coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_coins_label = coins.get_child(0)
	top.add_child(coins)
	var settings := UiKit.button("Ayarlar", 26, Vector2(150, 72))
	settings.pressed.connect(func() -> void: UiKit.go(&"settings"))
	top.add_child(settings)

	var bowl_card := PanelContainer.new()
	bowl_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bowl_card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 999, 10, false))
	column.add_child(bowl_card)
	var bowl_row := HBoxContainer.new()
	bowl_row.add_theme_constant_override("separation", 6)
	bowl_card.add_child(bowl_row)
	for n in MetaRules.MAX_BOWLS:
		var icon := TextureRect.new()
		icon.texture = ArtAtlas.texture("fuel")
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bowl_row.add_child(icon)
		bowl_icons.append(icon)
	_bowl_label = UiKit.label("", 24, UiKit.MUTED)
	_bowl_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bowl_row.add_child(_bowl_label)

	var map_area := Control.new()
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area.clip_contents = true
	column.add_child(map_area)
	_scroll = DragScroll.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	map_area.add_child(_scroll)
	var path := VBoxContainer.new()
	path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path.add_theme_constant_override("separation", 30)
	_scroll.add_child(path)
	# Shown above the last level once every level is beaten, so finishing the game has an ending.
	finale_card = PanelContainer.new()
	finale_card.add_theme_stylebox_override("panel", UiKit.box(Color("fff4e8"), 30, 28))
	var finale_rows := VBoxContainer.new()
	finale_rows.add_theme_constant_override("separation", 10)
	finale_card.add_child(finale_rows)
	finale_rows.add_child(UiKit.centered_label("Tebrikler!", 48))
	finale_rows.add_child(UiKit.centered_label("Bütün bölümleri bitirdin. Müşteriler sayende çok mutlu; yeni araçlar yolda!", 28, UiKit.MUTED))
	finale_card.visible = false
	path.add_child(finale_card)
	level_buttons.resize(Levels.COUNT)
	for id in range(Levels.COUNT, 0, -1):
		path.add_child(_level_row(id))
	# Room below level 1 so the "next level" button never covers its stars at the bottom of the map.
	var bottom_room := Control.new()
	bottom_room.custom_minimum_size = Vector2(0, BOTTOM_ROOM)
	path.add_child(bottom_room)
	_build_jump_buttons(map_area)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	column.add_child(bottom)
	recipes_button = UiKit.button("Galeri", 32, Vector2(0, 104), Color("3d5a80"), Color.WHITE, 52)
	recipes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes_button.icon = ArtAtlas.texture("dish_kupa")
	recipes_button.add_theme_constant_override("icon_max_width", 84)
	recipes_button.pressed.connect(func() -> void: UiKit.go(&"recipes"))
	bottom.add_child(recipes_button)
	gift_button = UiKit.button("Hediye", 30, Vector2(220, 104), Color("ffe38a"), UiKit.INK, 52)
	gift_button.pressed.connect(open_calendar)
	bottom.add_child(gift_button)
	_build_calendar()
	_build_bowls_popup()
	_build_bowl_lost_popup()

	var progress := UiKit.progress()
	if progress:
		progress.changed.connect(_refresh)
	_refresh()
	_scroll_to_focus.call_deferred()
	if bool(UiKit.router_params().get("bowls_empty", false)):
		open_bowls_popup()
		return
	if progress and progress.take_bowl_lost_note():
		UiKit.popup_root(_bowl_lost_rows).visible = true
		return
	var today := Time.get_date_string_from_system()
	if progress and progress.highest_beaten() >= 1 and progress.can_claim_calendar() and _calendar_offered_on != today:
		_calendar_offered_on = today
		open_calendar()


func _process(delta: float) -> void:
	_bowl_tick += delta
	if _bowl_tick >= 1.0:
		_bowl_tick = 0.0
		_refresh_bowls()


func open_bowls_popup() -> void:
	_refresh_bowls()
	UiKit.popup_root(_bowls_rows).visible = true


func bowls_popup_visible() -> bool:
	return UiKit.popup_root(_bowls_rows).visible


func refill_bowls() -> bool:
	var progress := UiKit.progress()
	if progress == null or not progress.refill_bowls_with_coins():
		return false
	UiKit.sound(&"coin")
	UiKit.popup_root(_bowls_rows).visible = false
	_refresh_bowls()
	return true


static func format_wait(seconds: int) -> String:
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _refresh_bowls() -> void:
	var progress := UiKit.progress()
	if progress == null:
		return
	var count: int = progress.bowls()
	var wait := format_wait(progress.seconds_to_next_bowl())
	for n in bowl_icons.size():
		bowl_icons[n].modulate = Color.WHITE if n < count else Color(1, 1, 1, 0.25)
	_bowl_label.text = "Depo dolu" if count >= MetaRules.MAX_BOWLS else "Sıradaki bidon %s" % wait
	_bowls_wait_label.text = "Bidonlar dolarken biraz mola ver.\nSıradaki bidon %s sonra dolar." % wait
	_refill_button.text = "Hepsini doldur · %d altın" % MetaRules.BOWL_REFILL_ALL_COST
	_refill_button.disabled = progress.coins() < MetaRules.BOWL_REFILL_ALL_COST
	coins_short_label.visible = _refill_button.disabled
	coins_short_label.text = "Altının yetmiyor (%d / %d)" % [progress.coins(), MetaRules.BOWL_REFILL_ALL_COST]
	if bowls_popup_visible() and count > 0:
		UiKit.popup_root(_bowls_rows).visible = false


func _build_bowls_popup() -> void:
	_bowls_rows = UiKit.popup(self, 600.0)
	_bowls_rows.add_child(UiKit.centered_label("Yakıt bitti", 46))
	var bowl := TextureRect.new()
	bowl.texture = ArtAtlas.texture("fuel")
	bowl.custom_minimum_size = Vector2(0, 120)
	bowl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bowl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bowl.modulate = Color(1, 1, 1, 0.4)
	_bowls_rows.add_child(bowl)
	_bowls_wait_label = UiKit.centered_label("", 28, UiKit.MUTED)
	_bowls_rows.add_child(_bowls_wait_label)
	_refill_button = UiKit.button("", 30, Vector2(0, 96), Color("ffe38a"), UiKit.INK, 48)
	_refill_button.pressed.connect(refill_bowls)
	_bowls_rows.add_child(_refill_button)
	coins_short_label = UiKit.centered_label("", 24, UiKit.MUTED)
	_bowls_rows.add_child(coins_short_label)
	var close := UiKit.button("Bekleyeceğim", 28, Vector2(0, 84))
	close.pressed.connect(func() -> void: UiKit.popup_root(_bowls_rows).visible = false)
	_bowls_rows.add_child(close)


func bowl_lost_note_visible() -> bool:
	return UiKit.popup_root(_bowl_lost_rows).visible


func _build_bowl_lost_popup() -> void:
	_bowl_lost_rows = UiKit.popup(self, 600.0)
	_bowl_lost_rows.add_child(UiKit.centered_label("Yarım kalan bölüm", 44))
	var bowl := TextureRect.new()
	bowl.texture = ArtAtlas.texture("fuel")
	bowl.custom_minimum_size = Vector2(0, 110)
	bowl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bowl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bowl.modulate = Color(1, 1, 1, 0.4)
	_bowl_lost_rows.add_child(bowl)
	_bowl_lost_rows.add_child(UiKit.centered_label("Bölümü yarıda bıraktığın için bir yakıt bidonu boşaldı.", 28, UiKit.MUTED))
	var ok := UiKit.button("Tamam", 30, Vector2(0, 90), UiKit.ACCENT, Color.WHITE, 45)
	ok.pressed.connect(func() -> void: UiKit.popup_root(_bowl_lost_rows).visible = false)
	_bowl_lost_rows.add_child(ok)


func open_calendar() -> void:
	_refresh_calendar()
	UiKit.popup_root(_calendar_rows).visible = true


func close_calendar() -> void:
	UiKit.popup_root(_calendar_rows).visible = false


func calendar_visible() -> bool:
	return UiKit.popup_root(_calendar_rows).visible


func claim_calendar() -> Dictionary:
	var progress := UiKit.progress()
	var reward: Dictionary = progress.claim_calendar() if progress else {}
	_refresh_calendar()
	if not reward.is_empty():
		_claim_button.text = "Alındı: " + MetaRules.reward_text(reward)
		UiKit.sound(&"coin")
	return reward


func _build_calendar() -> void:
	_calendar_rows = UiKit.popup(self, 620.0)
	_calendar_rows.add_child(UiKit.centered_label("Günlük hediye", 46))
	_calendar_rows.add_child(UiKit.centered_label("Her gün uğra, hediyen büyüsün.", 26, UiKit.MUTED))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_calendar_rows.add_child(grid)
	for n in MetaRules.CALENDAR.size():
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(126, 132)
		var rows := VBoxContainer.new()
		rows.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(rows)
		rows.add_child(UiKit.centered_label("%d. gün" % (n + 1), 22, UiKit.MUTED))
		rows.add_child(UiKit.centered_label(MetaRules.reward_text(MetaRules.CALENDAR[n]), 22))
		grid.add_child(cell)
		calendar_cells.append(cell)
	_claim_button = UiKit.button("", 34, Vector2(0, 100), UiKit.ACCENT, Color.WHITE, 50)
	_claim_button.pressed.connect(claim_calendar)
	_calendar_rows.add_child(_claim_button)
	var close := UiKit.button("Kapat", 28, Vector2(0, 80))
	close.pressed.connect(close_calendar)
	_calendar_rows.add_child(close)


func _refresh_calendar() -> void:
	var progress := UiKit.progress()
	var index: int = progress.calendar_index() if progress else 0
	var can_claim: bool = progress.can_claim_calendar() if progress else false
	# A week finished today wraps the index to 0; keep all seven days shown as claimed until tomorrow.
	if progress and not can_claim and index == 0 and int(progress.data.calendar.index) > 0:
		index = calendar_cells.size()
	for n in calendar_cells.size():
		var fill := Color("fff4e8")
		if n < index:
			fill = UiKit.TRACK
		elif n == index and can_claim:
			fill = Color("ffe38a")
		calendar_cells[n].add_theme_stylebox_override("panel", UiKit.box(fill, 20, 8, false))
		calendar_cells[n].modulate.a = 0.6 if n < index else 1.0
	_claim_button.disabled = not can_claim
	_claim_button.text = "Hediyeni al" if can_claim else "Yarın yine gel"


func shown_stars(level_id: int) -> int:
	var count := 0
	var on := ArtAtlas.texture("star_on")
	for star in _star_rows[level_id].get_children():
		if star.texture == on and star.modulate.a > 0.9:
			count += 1
	return count


func _level_row(id: int) -> Control:
	var level := Levels.load_level(id)
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(170.0 + sin(id * 1.3) * 150.0, 0)
	row.add_child(spacer)
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", 6)
	row.add_child(node)
	var button := UiKit.button(str(id), 54, Vector2(NODE_SIZE, NODE_SIZE), Color.WHITE, UiKit.INK, NODE_RADIUS)
	button.pressed.connect(_open_level.bind(id))
	node.add_child(button)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	for n in 3:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(42, 42)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars.add_child(star)
	node.add_child(stars)
	if level.difficulty > 0:
		var badge := UiKit.pill("Zor" if level.difficulty == 1 else "Çok zor", UiKit.DANGER, Color.WHITE, 22)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		node.add_child(badge)
	if MetaRules.recipe_index_for_level(id) >= 0:
		var recipe := TextureRect.new()
		recipe.custom_minimum_size = Vector2(104, 78)
		recipe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		recipe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		recipe.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(recipe)
		recipe_markers[id] = recipe
	level_buttons[id - 1] = button
	_star_rows[id] = stars
	return row


func _refresh() -> void:
	var progress := UiKit.progress()
	_coins_label.text = "%d altın" % (progress.coins() if progress else 0)
	_refresh_bowls()
	if progress:
		gift_button.modulate = Color.WHITE if progress.can_claim_calendar() else Color(1, 1, 1, 0.6)
	finale_card.visible = all_levels_done()
	var star_on := ArtAtlas.texture("star_on")
	var star_off := ArtAtlas.texture("star_off")
	# A vehicle marker shows the car once its level is won, and a covered car until then.
	for n in MetaRules.RECIPES.size():
		var marker: TextureRect = recipe_markers.get(MetaRules.recipe_unlock_level(n))
		if marker == null:
			continue
		var unlocked: bool = progress != null and progress.is_recipe_unlocked(n)
		marker.texture = ArtAtlas.texture(("dish_%s" % MetaRules.RECIPES[n].id) if unlocked else "dish_locked")
		marker.tooltip_text = str(MetaRules.RECIPES[n].name) if unlocked else "Bu bölümde yeni bir araç seni bekliyor"
	for id in range(1, Levels.COUNT + 1):
		var unlocked: bool = progress.is_unlocked(id) if progress else id == 1
		var stars: int = progress.stars_for(id) if progress else 0
		var button := level_buttons[id - 1]
		button.disabled = not unlocked
		var current := unlocked and stars == 0
		UiKit.style_button(button, UiKit.ACCENT if current else Color.WHITE, Color.WHITE if current else UiKit.INK, NODE_RADIUS)
		var n := 0
		for star in _star_rows[id].get_children():
			star.texture = star_on if n < stars else star_off
			star.modulate.a = 1.0 if unlocked else 0.35
			n += 1


func _open_level(id: int) -> void:
	var progress := UiKit.progress()
	if progress and not progress.can_start_level():
		open_bowls_popup()
		return
	last_opened_level = id
	UiKit.go(&"game", {"level_id": id})


func all_levels_done() -> bool:
	var progress := UiKit.progress()
	return progress != null and progress.stars_for(Levels.COUNT) > 0


func current_level() -> int:
	var progress := UiKit.progress()
	return clampi(int(progress.data.unlocked), 1, Levels.COUNT) if progress else 1


# The level the map opens at: the one last opened this session, otherwise the next level to play.
func focus_level() -> int:
	return last_opened_level if last_opened_level >= 1 and last_opened_level <= Levels.COUNT else current_level()


func is_level_on_screen(level_id: int) -> bool:
	var center := _row_center(level_id) - _scroll.scroll_vertical
	return center >= 0.0 and center <= _scroll.size.y


# The map runs from level 1 at the bottom to the last level at the top. Players jump either back to
# level 1 or to the next level to play; there is no jump to the locked top of the map.
func jump_to_bottom(animate: bool = true) -> void:
	_scroll.glide_to(_scroll.max_offset(), animate)
	_update_jump_buttons()


func jump_to_next(animate: bool = true) -> void:
	_scroll.glide_to(_offset_for(current_level()), animate)
	_update_jump_buttons()


func _row_center(level_id: int) -> float:
	var row: Control = level_buttons[level_id - 1].get_parent().get_parent()
	return row.position.y + row.size.y / 2.0


func _offset_for(level_id: int) -> float:
	return _row_center(level_id) - _scroll.size.y / 2.0


func _scroll_to_focus() -> void:
	await get_tree().process_frame
	_scroll.glide_to(_offset_for(focus_level()), false)
	_update_jump_buttons()


func _build_jump_buttons(area: Control) -> void:
	bottom_button = _round_jump_button(false)
	bottom_button.anchor_left = 1.0
	bottom_button.anchor_right = 1.0
	bottom_button.anchor_top = 1.0
	bottom_button.anchor_bottom = 1.0
	bottom_button.offset_left = -112.0
	bottom_button.offset_right = -16.0
	bottom_button.offset_top = -112.0
	bottom_button.offset_bottom = -16.0
	bottom_button.pressed.connect(jump_to_bottom)
	area.add_child(bottom_button)
	next_button = UiKit.button("", 26, Vector2(0, 76), UiKit.ACCENT, Color.WHITE, 38)
	next_button.anchor_left = 0.5
	next_button.anchor_right = 0.5
	next_button.anchor_top = 1.0
	next_button.anchor_bottom = 1.0
	next_button.offset_left = -150.0
	next_button.offset_right = 150.0
	next_button.offset_top = -96.0
	next_button.offset_bottom = -20.0
	next_button.pressed.connect(jump_to_next)
	area.add_child(next_button)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: _update_jump_buttons())
	_scroll.resized.connect(_update_jump_buttons)


func _round_jump_button(up: bool) -> Button:
	var button := UiKit.button("", 20, Vector2(96, 96), Color.WHITE, UiKit.INK, 48)
	var chevron := Chevron.new()
	chevron.pointing_up = up
	chevron.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(chevron)
	return button


# Jump buttons only show when they would move the map: level 1 more than half a screen away,
# and the "next level" button only while that level is out of view.
func _update_jump_buttons() -> void:
	if bottom_button == null or _scroll.size.y <= 0.0:
		return
	var margin := _scroll.size.y * 0.5
	bottom_button.visible = _scroll.scroll_vertical < _scroll.max_offset() - margin
	next_button.visible = not is_level_on_screen(current_level()) and not all_levels_done()
	next_button.text = "%d. bölüme git" % current_level()
