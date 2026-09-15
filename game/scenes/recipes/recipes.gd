extends Control

# Galeri: every vehicle in unlock order. A vehicle joins the gallery the first time its level is won;
# the garage grows a rank as the gallery fills. The "recipe" names come from the shared core.
var cards: Array[PanelContainer] = []
var dish_images: Array[TextureRect] = []
var restaurant_label: Label
var next_label: Label

var _unlocked := 0


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
	back.pressed.connect(handle_back)
	top.add_child(back)
	var title := UiKit.label("Galeri", 46)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var count := UiKit.pill("", Color.WHITE, UiKit.INK, 28)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(count)

	var progress := UiKit.progress()
	_unlocked = progress.recipes_unlocked() if progress else 0
	count.get_child(0).text = "%d / %d" % [_unlocked, MetaRules.RECIPES.size()]

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UiKit.box(Color("3d5a80"), 28, 22))
	column.add_child(header)
	var header_rows := VBoxContainer.new()
	header_rows.add_theme_constant_override("separation", 4)
	header.add_child(header_rows)
	restaurant_label = UiKit.centered_label("", 38, Color.WHITE)
	header_rows.add_child(restaurant_label)
	next_label = UiKit.centered_label("", 24, Color("ffd166"))
	header_rows.add_child(next_label)
	var rank := MetaRules.restaurant_index(_unlocked)
	restaurant_label.text = MetaRules.RESTAURANTS[rank].name
	if rank + 1 < MetaRules.RESTAURANTS.size():
		var next: Dictionary = MetaRules.RESTAURANTS[rank + 1]
		next_label.text = "Sonraki: %s · %d araç kaldı" % [next.name, int(next.recipes) - _unlocked]
	else:
		next_label.text = "Garajın en yüksek rütbesindesin!"

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
	for n in MetaRules.RECIPES.size():
		grid.add_child(_card(n, progress))


func handle_back() -> void:
	UiKit.go(&"map")


func unlocked_count() -> int:
	return _unlocked


func _card(index: int, progress: Node) -> PanelContainer:
	var recipe: Dictionary = MetaRules.RECIPES[index]
	var level_id := MetaRules.recipe_unlock_level(index)
	var unlocked: bool = progress != null and progress.is_recipe_unlocked(index)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE if unlocked else UiKit.LOCKED, 24, 16))
	var rows := VBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 6)
	card.add_child(rows)
	var dish := TextureRect.new()
	dish.custom_minimum_size = Vector2(0, 150)
	dish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish.texture = ArtAtlas.texture(("dish_%s" % recipe.id) if unlocked else "dish_locked")
	rows.add_child(dish)
	var name_label := UiKit.centered_label(str(recipe.name), 28, UiKit.INK if unlocked else UiKit.MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(name_label)
	# Both states keep a row of the same height under the name, so cards in a row line up.
	var status := HBoxContainer.new()
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(0, 40)
	rows.add_child(status)
	if unlocked:
		var stars: int = progress.stars_for(level_id)
		for n in 3:
			var star := TextureRect.new()
			star.texture = ArtAtlas.texture("star_on" if n < stars else "star_off")
			star.custom_minimum_size = Vector2(38, 38)
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			status.add_child(star)
	else:
		var lock := UiKit.centered_label("%d. bölümde açılır" % level_id, 22, UiKit.MUTED)
		lock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status.add_child(lock)
	cards.append(card)
	dish_images.append(dish)
	return card
