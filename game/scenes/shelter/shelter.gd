extends Control

const RIG_HEIGHT := 150.0
const MAIL_LIST_HEIGHT := 520.0
const EMPTY_MAIL_HEIGHT := 90.0
const LETTER_HEIGHT := 190.0
# Feet positions of the four cats in a room, as fractions of the room size.
const SLOTS := [Vector2(0.17, 0.93), Vector2(0.39, 0.86), Vector2(0.61, 0.94), Vector2(0.83, 0.87)]

var room_index := 0
var room_rigs: Array[CatRig] = []
var cat_buttons: Array[Button] = []
var detail_cat_id := ""

var _count_label: Label
var _room_title: Label
var _room_stage: Control
var _room_backdrop: RoomBackdrop
var _room_lock: Label
var _room_note_y := 0.5
var _grid: GridContainer
var _mail_button: Button
var _next_label: Label
var _next_button: Button
var _detail_rows: VBoxContainer
var _detail_rig: CatRig
var _detail_name: Label
var _detail_info: Label
var _favorite_button: Button
var _adopt_button: Button
var _adopt_reason: Label
var _adopt_armed := false
var _mail_rows: VBoxContainer
var _mail_scroll: ScrollContainer
var _mail_list: VBoxContainer
var _shown_letters := 0


func _ready() -> void:
	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	page.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	column.add_child(top)
	var back := UiKit.button("‹", 40, Vector2(80, 72))
	back.pressed.connect(func() -> void: UiKit.go(&"map"))
	top.add_child(back)
	var title := UiKit.label("Barınak", 46)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var count := UiKit.pill("", Color.WHITE, UiKit.INK, 28)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_count_label = count.get_child(0)
	top.add_child(count)

	var room_card := PanelContainer.new()
	room_card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 28, 14))
	column.add_child(room_card)
	var room_column := VBoxContainer.new()
	room_column.add_theme_constant_override("separation", 10)
	room_card.add_child(room_column)
	var room_header := HBoxContainer.new()
	room_column.add_child(room_header)
	var previous := UiKit.button("‹", 36, Vector2(76, 64))
	previous.pressed.connect(show_room.bind(-1, true))
	room_header.add_child(previous)
	_room_title = UiKit.centered_label("", 32)
	_room_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_header.add_child(_room_title)
	var following := UiKit.button("›", 36, Vector2(76, 64))
	following.pressed.connect(show_room.bind(1, true))
	room_header.add_child(following)
	_room_stage = _build_room_stage()
	room_column.add_child(_room_stage)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	var album := UiKit.button("Albüm", 30, Vector2(0, 88))
	album.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album.pressed.connect(func() -> void: UiKit.go(&"album"))
	actions.add_child(album)
	_mail_button = UiKit.button("Mektuplar", 30, Vector2(0, 88))
	_mail_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_button.pressed.connect(open_mail)
	actions.add_child(_mail_button)

	column.add_child(UiKit.label("Kurtardıkların", 32))
	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)

	var next_card := PanelContainer.new()
	next_card.add_theme_stylebox_override("panel", UiKit.box(UiKit.INK, 28, 18))
	column.add_child(next_card)
	var next_row := HBoxContainer.new()
	next_row.add_theme_constant_override("separation", 16)
	next_card.add_child(next_row)
	var silhouette := TextureRect.new()
	silhouette.texture = ArtAtlas.texture("cat_silhouette")
	silhouette.custom_minimum_size = Vector2(76, 76)
	silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	silhouette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	next_row.add_child(silhouette)
	_next_label = UiKit.label("", 28, Color("fff3e6"))
	_next_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_row.add_child(_next_label)
	_next_button = UiKit.button("Oyna", 30, Vector2(170, 80), UiKit.ACCENT, Color.WHITE, 40)
	_next_button.pressed.connect(_on_next_pressed)
	next_row.add_child(_next_button)

	_build_detail_popup()
	_build_mail_popup()
	var progress := UiKit.progress()
	if progress:
		progress.changed.connect(_refresh)
	_refresh()


func show_room(index: int, relative: bool = false) -> void:
	room_index = clampi(room_index + index if relative else index, 0, MetaRules.ROOM_NAMES.size() - 1)
	var progress := UiKit.progress()
	var cats: Array = progress.shelter_cats() if progress else []
	_room_title.text = MetaRules.ROOM_NAMES[room_index]
	for rig in room_rigs:
		rig.queue_free()
	room_rigs.clear()
	var locked := room_index >= MetaRules.rooms_unlocked(cats.size())
	_room_backdrop.room_index = room_index
	_room_backdrop.locked = locked
	_style_room_note(locked)
	_place_room_note.call_deferred()
	if locked:
		_room_lock.text = "%d dosta ulaşınca açılır" % (room_index * MetaRules.ROOM_CAPACITY)
		_room_lock.visible = true
		return
	var start := room_index * MetaRules.ROOM_CAPACITY
	# A room opens once the rooms before it are full, so a freshly opened room starts out empty.
	_room_lock.visible = start >= cats.size()
	if not cats.is_empty():
		_room_lock.text = "Bu oda yeni dostlarını bekliyor."
	elif progress and progress.next_pending_rescue_level() > 0:
		_room_lock.text = "Yeni dostun seni bekliyor!\nAşağıdan onunla tanış."
	else:
		_room_lock.text = "İlk dostun %d. bölümde seni bekliyor." % MetaRules.RESCUE_LEVELS[0]
	for n in range(start, mini(start + MetaRules.ROOM_CAPACITY, cats.size())):
		var rig := CatRig.new()
		_room_stage.add_child(rig)
		rig.setup(str(cats[n].breed), RIG_HEIGHT, UiKit.idle_level())
		room_rigs.append(rig)
	_place_rigs()


func open_detail(cat_id: String) -> void:
	detail_cat_id = cat_id
	_adopt_armed = false
	UiKit.sound(&"meow", randf_range(0.9, 1.15))
	_update_detail()
	UiKit.popup_root(_detail_rows).visible = true


func close_detail() -> void:
	UiKit.popup_root(_detail_rows).visible = false
	detail_cat_id = ""


func detail_visible() -> bool:
	return UiKit.popup_root(_detail_rows).visible


func toggle_favorite() -> void:
	var progress := UiKit.progress()
	var cat: Dictionary = progress.find_cat(detail_cat_id)
	if cat.is_empty():
		return
	progress.set_favorite(detail_cat_id, not bool(cat.favorite))
	_update_detail()


func open_mail() -> void:
	for child in _mail_list.get_children():
		child.queue_free()
	var progress := UiKit.progress()
	var delivered: Array = progress.mailbox() if progress else []
	# Newest first, so a fresh letter is never hidden below the scroll. The mailbox keeps arrival order,
	# so letters delivered on the same day put the one that arrived last on top.
	var order: Array = range(delivered.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var day_a := str(delivered[a].deliver_on)
		var day_b := str(delivered[b].deliver_on)
		return day_a > day_b if day_a != day_b else a > b)
	var letters: Array = order.map(func(n: int) -> Dictionary: return delivered[n])
	_shown_letters = letters.size()
	# The window grows with the letters up to a scrolling maximum; an empty mailbox only needs its note.
	_mail_scroll.custom_minimum_size.y = EMPTY_MAIL_HEIGHT if letters.is_empty() else minf(MAIL_LIST_HEIGHT, LETTER_HEIGHT * letters.size())
	if letters.is_empty():
		_mail_list.add_child(UiKit.centered_label("Henüz mektup yok. Yeni yuvasına giden dostların sana yazacak.", 28, UiKit.MUTED))
	for letter in letters:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.box(Color("fff4e8"), 20, 18, false))
		var text := UiKit.label(str(letter.text), 26)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(text)
		_mail_list.add_child(card)
	UiKit.popup_root(_mail_rows).visible = true
	if progress:
		progress.mark_mail_read()


func shown_letters() -> int:
	return _shown_letters


func _refresh() -> void:
	var progress := UiKit.progress()
	var cats: Array = progress.shelter_cats() if progress else []
	_count_label.text = "%d dost" % cats.size()
	for button in cat_buttons:
		button.queue_free()
	cat_buttons.clear()
	for cat in cats:
		var button := UiKit.button(str(cat.name), 22, Vector2(150, 176), Color.WHITE, UiKit.INK, 24)
		button.icon = ArtAtlas.texture("cat_%s_face" % cat.breed)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", 100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.pressed.connect(open_detail.bind(str(cat.id)))
		if bool(cat.favorite):
			var heart := HeartBadge.new()
			heart.anchor_left = 1.0
			heart.anchor_right = 1.0
			heart.offset_left = -50.0
			heart.offset_right = -10.0
			heart.offset_top = 10.0
			heart.offset_bottom = 48.0
			button.add_child(heart)
		_grid.add_child(button)
		cat_buttons.append(button)
	var unread: int = progress.unread_mail_count() if progress else 0
	_mail_button.text = "Mektuplar (%d)" % unread if unread > 0 else "Mektuplar"
	var pending: int = progress.next_pending_rescue_level() if progress else -1
	var left: int = progress.levels_until_next_rescue() if progress else -1
	if pending > 0:
		_next_label.text = "Seni bekleyen bir dost var!"
		_next_button.text = "Tanış"
	elif left < 0:
		_next_label.text = "Şimdilik tüm dostlar kurtarıldı."
		_next_button.text = "Harita"
	else:
		_next_label.text = "Sıradaki dost\n%d bölüm kaldı" % left
		_next_button.text = "Oyna"
	show_room(room_index)


func _build_room_stage() -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 330)
	stage.clip_contents = true
	_room_backdrop = RoomBackdrop.new()
	_room_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(_room_backdrop)
	# The note sits on a soft card so it stays readable over busy scenery such as the library shelves.
	_room_lock = UiKit.label("", 30)
	_room_lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_lock.add_theme_stylebox_override("normal", UiKit.box(Color(1.0, 0.98, 0.94, 0.92), 22, 14, false))
	_room_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_room_lock)
	stage.resized.connect(_place_rigs)
	stage.resized.connect(_place_room_note)
	return stage


# Locked rooms put the note under the padlock; other notes sit in the middle of the room.
func _style_room_note(locked: bool) -> void:
	_room_note_y = 0.76 if locked else 0.5


# Sizes the note card to its text and centres it at _room_note_y of the room.
func _place_room_note() -> void:
	var needed := _room_lock.get_combined_minimum_size()
	var center := Vector2(_room_stage.size.x / 2.0, _room_stage.size.y * _room_note_y)
	_room_lock.position = (center - needed / 2.0).floor()
	_room_lock.size = needed


func _place_rigs() -> void:
	for n in room_rigs.size():
		room_rigs[n].position = SLOTS[n] * _room_stage.size


func _build_detail_popup() -> void:
	_detail_rows = UiKit.popup(self, 560.0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 240)
	_detail_rows.add_child(holder)
	_detail_rig = CatRig.new()
	holder.add_child(_detail_rig)
	holder.resized.connect(func() -> void: _detail_rig.position = Vector2(holder.size.x / 2.0, holder.size.y))
	_detail_name = UiKit.centered_label("", 46)
	_detail_rows.add_child(_detail_name)
	_detail_info = UiKit.centered_label("", 26, UiKit.MUTED)
	_detail_rows.add_child(_detail_info)
	_favorite_button = UiKit.button("", 30, Vector2(0, 88))
	_favorite_button.pressed.connect(toggle_favorite)
	_detail_rows.add_child(_favorite_button)
	_adopt_button = UiKit.button("Sahiplendir", 30, Vector2(0, 88), Color("cfe9ff"), UiKit.INK, 44)
	_adopt_button.pressed.connect(_on_adopt_pressed)
	_detail_rows.add_child(_adopt_button)
	_adopt_reason = UiKit.centered_label("", 24, UiKit.MUTED)
	_detail_rows.add_child(_adopt_reason)
	var close := UiKit.button("Kapat", 28, Vector2(0, 80))
	close.pressed.connect(close_detail)
	_detail_rows.add_child(close)


func _update_detail() -> void:
	var progress := UiKit.progress()
	if progress == null:
		return
	var cat: Dictionary = progress.find_cat(detail_cat_id)
	if cat.is_empty():
		return
	_detail_rig.setup(str(cat.breed), 220.0, UiKit.idle_level())
	_detail_name.text = str(cat.name)
	_detail_info.text = "%s · %d. bölümde kurtarıldı" % [MetaRules.BREED_LABELS.get(cat.breed, ""), int(cat.level)]
	_favorite_button.text = "Favoriden çıkar" if bool(cat.favorite) else "Favori yap"
	var reason := MetaRules.adoption_block_reason(cat, progress.highest_beaten())
	_adopt_button.disabled = not reason.is_empty()
	_adopt_button.text = "Evet, yeni yuvasına gitsin" if _adopt_armed else "Sahiplendir"
	_adopt_reason.text = reason if not reason.is_empty() else "Sahiplendirilen dostlar sana mektup yazar."


func _on_adopt_pressed() -> void:
	if not _adopt_armed:
		_adopt_armed = true
		_update_detail()
		return
	var progress := UiKit.progress()
	if progress and progress.adopt_cat(detail_cat_id).is_empty():
		close_detail()


func _build_mail_popup() -> void:
	_mail_rows = UiKit.popup(self, 600.0)
	_mail_rows.add_child(UiKit.centered_label("Mektuplar", 46))
	_mail_scroll = DragScroll.new()
	_mail_scroll.custom_minimum_size = Vector2(0, MAIL_LIST_HEIGHT)
	_mail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_mail_rows.add_child(_mail_scroll)
	_mail_list = VBoxContainer.new()
	_mail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_list.add_theme_constant_override("separation", 14)
	_mail_scroll.add_child(_mail_list)
	var close := UiKit.button("Kapat", 28, Vector2(0, 80))
	close.pressed.connect(func() -> void: UiKit.popup_root(_mail_rows).visible = false)
	_mail_rows.add_child(close)


func _on_next_pressed() -> void:
	var progress := UiKit.progress()
	var pending: int = progress.next_pending_rescue_level() if progress else -1
	if pending > 0:
		UiKit.go(&"rescue", {"level_id": pending})
	else:
		UiKit.go(&"map")
