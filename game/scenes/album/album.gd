extends Control

var cards := {}
var home_badges := {}

var _discovered := 0


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
	back.pressed.connect(func() -> void: UiKit.go(&"shelter"))
	top.add_child(back)
	var title := UiKit.label("Albüm", 46)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var count := UiKit.pill("", Color.WHITE, UiKit.INK, 28)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(count)

	var scroll := DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	var progress := UiKit.progress()
	var all_cats: Array = progress.cats() if progress else []
	for breed in MetaRules.BREEDS:
		var of_breed := all_cats.filter(func(cat: Dictionary) -> bool: return cat.breed == breed)
		grid.add_child(_card(breed, of_breed))
	count.get_child(0).text = "%d / %d" % [_discovered, MetaRules.BREEDS.size()]


func handle_back() -> void:
	UiKit.go(&"shelter")


func discovered_count() -> int:
	return _discovered


func _card(breed: String, of_breed: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 24, 16))
	var rows := VBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 6)
	card.add_child(rows)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(0, 150)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture = ArtAtlas.texture("cat_silhouette" if of_breed.is_empty() else "cat_%s_face" % breed)
	rows.add_child(face)
	rows.add_child(UiKit.centered_label(MetaRules.BREED_LABELS.get(breed, ""), 30))
	var names := ", ".join(PackedStringArray(of_breed.map(func(cat: Dictionary) -> String: return str(cat.name))))
	rows.add_child(UiKit.centered_label(names if not names.is_empty() else "Henüz tanışmadınız", 22, UiKit.MUTED))
	# Every card keeps the badge's space so cards in a row line up; it is only shown for adopted breeds.
	var home := UiKit.pill("Yuvada", Color("5fb36b"), Color.WHITE, 20)
	home.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.modulate.a = 1.0 if of_breed.any(func(cat: Dictionary) -> bool: return bool(cat.adopted)) else 0.0
	rows.add_child(home)
	home_badges[breed] = home
	if not of_breed.is_empty():
		_discovered += 1
	cards[breed] = card
	return card
