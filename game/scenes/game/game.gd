extends Control

const BOOSTERS := [
	{"id": M3.BOOSTER_ROW, "label": "Lazer", "icon": "booster_row"},
	{"id": M3.BOOSTER_SHUFFLE, "label": "Kedi nanesi", "icon": "booster_shuffle"},
	{"id": M3.BOOSTER_SINGLE, "label": "Pençe", "icon": "booster_single"},
]
const COMBO_WORDS := {3: "Harika!", 5: "Muhteşem!", 7: "Pati-stik!"}
const KIND_NAMES := {
	1: "mama", 2: "yün", 3: "balık", 4: "pati", 5: "çıngırak",
	M3.GOAL_BOX: "kutu", M3.GOAL_PAW: "pati izi", M3.GOAL_SACK: "mama çuvalı", M3.GOAL_KNOT: "yün düğümü", M3.GOAL_KITTEN: "yavru",
	M3.GOAL_SLEEPER: "uyuyan kedi", M3.GOAL_FUR: "tüy yığını", M3.GOAL_CAGE: "kafes", M3.GOAL_MOUSE: "fare",
}
const GOAL_ART := {M3.GOAL_BOX: "box_1", M3.GOAL_PAW: "paw_print", M3.GOAL_SACK: "sack", M3.GOAL_KNOT: "knot", M3.GOAL_KITTEN: "crate_2", M3.GOAL_SLEEPER: "sleeper_3", M3.GOAL_FUR: "fur", M3.GOAL_CAGE: "cage", M3.GOAL_MOUSE: "mouse"}
const INTROS := {
	"basics": {"tile": [1, M3.Special.NONE], "title": "Hoş geldin!", "text": "Bir taşı yanındakiyle yer değiştir. Aynı türden 3 taş yan yana gelince patlar. Hedefteki taşları topla!"},
	"line": {"tile": [4, M3.Special.LINE_H], "title": "4'lü eşleşme", "text": "Bir sırada 4 taş eşleştirirsen çizgili taş çıkar. Onu patlatınca bütün sıra temizlenir."},
	"bomb": {"tile": [3, M3.Special.BOMB], "title": "L ve T şekli", "text": "Taşları L ya da T şeklinde eşleştirirsen bomba çıkar; patlayınca çevresini temizler."},
	"flyer": {"tile": [2, M3.Special.FLYER], "title": "Kare eşleşme", "text": "2x2 kare eşleştir: kağıt uçak çıkar ve hedeflerinden birine uçup vurur."},
	"color": {"tile": [0, M3.Special.COLOR], "title": "5'li eşleşme", "text": "Bir sırada 5 taş eşleştirirsen gökkuşağı yumağı çıkar. Bir taşla yer değiştir, o türdeki bütün taşlar gitsin!"},
	"box": {"art": "box_2", "title": "Yeni: Karton kutu", "text": "Kutunun hemen yanında eşleşme yap ya da özel taşla vur. Çift bantlı kutular iki vuruşta açılır."},
	"paw": {"art": "paw_print", "title": "Yeni: Pati izi", "text": "Pati izinin üstündeki taşı eşleştir, iz silinsin. Bütün izleri temizle!"},
	"sack": {"art": "sack", "title": "Yeni: Mama çuvalı", "text": "Çuvallar eşleşmez. Altındaki taşları temizle ya da çuvalı alttaki taşla yer değiştirerek aşağı it; en alt sıraya inince toplanır."},
	"knot": {"art": "knot", "title": "Yeni: Yün düğümü", "text": "Düğümlü taş yerinden oynamaz. Onu bir eşleşmeye kat, düğüm çözülsün."},
	"kitten": {"art": "crate_2", "title": "Sandıktaki yavrular", "text": "Sandıklarda mahsur yavrular var! Sandığa iki kez vur, yavruları kurtar."},
	"sleeper": {"art": "sleeper_3", "title": "Yeni: Uyuyan kedi", "text": "Yanında eşleşme yaparak kediyi üç kez dürt, uyansın. Bir hamle boyunca dokunmazsan yeniden uykuya dalar!"},
	"stages": {"art": "star_on", "title": "Yeni: İki aşamalı hedef", "text": "Önce ilk hedefleri tamamla, sonra aynı hamlelerle ikinci hedefler açılır. İlk aşamada kırdığın engeller de sayılır!"},
	"belt": {"art": "belt", "title": "Yeni: Konveyör", "text": "Bant her hamleden sonra taşları bir adım ok yönünde taşır; sondaki taş başa döner. Kayan taşlar da eşleşebilir!"},
	"mouse": {"art": "mouse", "title": "Yeni: Kaçan fare", "text": "Fareler her hamlede yandaki taşa kaçar. Farenin üstünde durduğu taşı patlat, yakala!"},
	"cage": {"art": "cage", "title": "Yeni: Kafes ve anahtar", "text": "Kafeslerde kediler mahsur! Anahtar eşleşmez; onu aşağı indir. Daha fazla inemeyince en yakın kafesi açar."},
	"fur": {"art": "fur", "title": "Yeni: Yayılan tüy", "text": "Tüy yığınının yanında eşleşme yap, temizlensin. Bir hamlede hiç tüy temizlemezsen tüy yanındaki taşa yayılır!"},
}
const STAGE_BANNER_HOLD := 1.2
const HINT_DELAY_EARLY := 3.0
const HINT_DELAY := 6.0
const HINT_EARLY_LEVELS := 10
const FLYER_POOL := 8
const TILE_KINDS := 5
const WIN_CAT := "tarcin"
const LOSE_CAT := "duman"
const FALLBACK_STOCK := 3
const VIBRATION_MS := 40

var level: M3LevelDef
var session: M3Session
var board_view: BoardView
var result := {}

var _textures: Array[Texture2D] = [null]
var _level_label: Label
var _badge: PanelContainer
var _moves_label: Label
var _goal_row: HBoxContainer
var _goal_items := {}
var _booster_buttons := {}
var _armed: StringName = &""
var _combo_label: Label
var _overlay: ColorRect
var _end_panel: PanelContainer
var _end_state: StringName = &""
var _end_cat: CatRig
var _end_title: Label
var _end_detail: Label
var _stars_row: HBoxContainer
var _continue_coins: Button
var _continue_ad: Button
var _primary: Button
var _secondary: Button
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _confirm_yes: Button
var _confirm_no: Button
var _confirm_action := Callable()
var _continued := false
var _fly_layer: Node2D
var _flyers: Array[Sprite2D] = []
var _bot: M3Bot
var _fixed_seed := 0
var _demo := false
var _demo_timer := 0.0
var _show_win_on_start := false
var pause_button: Button
var _pause_panel: PanelContainer
var _pause_sound: Button
var _pause_vibration: Button
var _idle := 0.0
var _intro_panel: PanelContainer
var _intro_art: TextureRect
var _intro_tile: TileView
var _intro_title: Label
var _intro_text: Label
var _intro_id := ""
var _attempt_open := false
var _pause_note: Label


func _ready() -> void:
	_read_dev_args()
	for kind in range(1, M3.SACK + 1):
		if kind <= TILE_KINDS:
			_textures.append(ArtAtlas.texture("tile_%d" % kind))
		elif kind == M3.KEY:
			_textures.append(ArtAtlas.texture("key"))
		elif kind == M3.SACK:
			_textures.append(ArtAtlas.texture("sack"))
		else:
			_textures.append(null)
	_build_ui()
	_start_level()
	if _show_win_on_start:
		result = {"stars": 3, "coins": 40}
		_present_win()


func _process(delta: float) -> void:
	if board_view.busy or _overlay.visible or session.is_finished():
		_idle = 0.0
		return
	if _demo:
		_demo_timer -= delta
		if _demo_timer > 0.0:
			return
		_demo_timer = 0.45
		var move := _bot.choose_move(session)
		if move != M3Bot.NO_MOVE:
			_on_swap_requested(session.board.pos(move.x), session.board.pos(move.y))
		return
	if _armed != &"" or board_view.hint_move != BoardView.NO_HINT:
		return
	_idle += delta
	if _idle >= (HINT_DELAY_EARLY if level.id <= HINT_EARLY_LEVELS else HINT_DELAY):
		_idle = 0.0
		var hint := _bot.choose_move(session)
		if hint != M3Bot.NO_MOVE:
			board_view.show_hint(hint)


func end_state() -> StringName:
	return _end_state


func intro_visible() -> bool:
	return _overlay.visible and _intro_panel.visible


func show_intro(intro_id: String) -> void:
	var intro: Dictionary = INTROS[intro_id]
	_intro_id = intro_id
	_intro_art.visible = intro.has("art")
	_intro_tile.visible = intro.has("tile")
	if intro.has("art"):
		_intro_art.texture = ArtAtlas.texture(intro.art)
	else:
		var kind: int = intro.tile[0]
		_intro_tile.setup(kind, intro.tile[1], _textures[kind] if kind > 0 else null, 150.0)
	_intro_title.text = intro.title
	_intro_text.text = intro.text
	_end_panel.visible = false
	_confirm_panel.visible = false
	_pause_panel.visible = false
	_intro_panel.visible = true
	_overlay.visible = true


func _maybe_show_intro() -> bool:
	var progress := UiKit.progress()
	if _demo or not INTROS.has(level.intro) or (progress != null and progress.intro_seen(level.intro)):
		return false
	show_intro(level.intro)
	return true


func _on_intro_done() -> void:
	var progress := UiKit.progress()
	if progress:
		progress.mark_intro_seen(_intro_id)
	_close_overlay()


func _goal_texture(key: int) -> Texture2D:
	if key < _textures.size() and _textures[key] != null:
		return _textures[key]
	return ArtAtlas.texture(GOAL_ART.get(key, "star_on"))


func _start_level() -> void:
	level = Levels.load_level(int(UiKit.router_params().get("level_id", 1))).duplicate()
	level.rng_seed = _fixed_seed if _fixed_seed > 0 else randi_range(1, 1000000)
	session = M3Session.new(level)
	_bot = M3Bot.new(level.rng_seed)
	_continued = false
	_attempt_open = false
	_end_state = &""
	_set_armed(&"")
	_level_label.text = "Bölüm %d" % level.id
	_badge.visible = level.difficulty > 0
	_badge.get_child(0).text = "Zor" if level.difficulty == 1 else "Çok zor"
	_moves_label.text = str(session.moves_left)
	_build_goals()
	_refresh_goals(session.goals)
	_refresh_boosters()
	_close_overlay()
	board_view.setup(session.board)
	_idle = 0.0
	_maybe_show_intro()


func _on_swap_requested(a: Vector2i, b: Vector2i) -> void:
	if session.is_finished() or board_view.busy:
		return
	var steps := session.swap(a, b)
	if steps.is_empty():
		board_view.play_invalid(a, b)
		return
	_moves_label.text = str(session.moves_left)
	_open_attempt()
	await board_view.play(steps)
	_check_end()


func _check_end() -> void:
	if session.is_won():
		_on_won()
	elif session.is_lost():
		_on_lost()


func _on_won() -> void:
	_close_attempt()
	_end_state = &"party"
	var progress := UiKit.progress()
	if progress:
		result = progress.record_win(level.id, session.moves_left, level.moves)
	else:
		result = {"stars": 1, "coins": 0}
	var ads := UiKit.ads()
	if ads:
		ads.level_completed()
	await _play_party()
	_present_win()


func _play_party() -> void:
	var steps := session.party(MetaRules.PARTY_MAX_MOVES, level.rng_seed)
	if steps.is_empty():
		return
	_show_banner("Kedi Partisi!")
	await board_view.play(steps)
	_moves_label.text = str(session.moves_left)


func _present_win() -> void:
	_end_state = &"win"
	UiKit.sound(&"win")
	_end_title.text = "Harika, kazandın!"
	var detail := "+%d altın" % int(result.get("coins", 0))
	if int(result.get("party_coins", 0)) > 0:
		detail += "  (Kedi Partisi +%d)" % int(result.party_coins)
	var rescue := rescue_pending()
	if rescue:
		detail += "\nBir dost seni bekliyor!"
	_end_detail.text = detail
	_stars_row.visible = true
	_show_stars(int(result.get("stars", 1)))
	_continue_coins.visible = false
	_continue_ad.visible = false
	_primary.text = "Yeni dostla tanış" if rescue else "Devam"
	_secondary.text = "Tekrar oyna"
	_open_end(WIN_CAT)


# An attempt starts with the first move or booster; winning closes it for free, anything else costs a bowl.
func _open_attempt() -> void:
	if _attempt_open:
		return
	_attempt_open = true
	var progress := UiKit.progress()
	if progress and level:
		progress.begin_attempt(level.id)


func _close_attempt() -> void:
	_attempt_open = false
	var progress := UiKit.progress()
	if progress:
		progress.end_attempt()


func fail_attempt() -> void:
	if not _attempt_open:
		return
	_attempt_open = false
	var progress := UiKit.progress()
	if progress:
		progress.spend_bowl()


func out_of_bowls() -> bool:
	var progress := UiKit.progress()
	return progress != null and not progress.can_start_level()


# Plays the level again, or sends the player to the map to wait when every bowl is empty.
func _retry() -> void:
	fail_attempt()
	if out_of_bowls():
		UiKit.go(&"map", {"bowls_empty": true})
	else:
		_start_level()


func rescue_pending() -> bool:
	var progress := UiKit.progress()
	return progress != null and level != null and progress.next_pending_rescue_level() == level.id


func _on_lost() -> void:
	_end_state = &"lose"
	UiKit.sound(&"lose")
	_end_title.text = "Hamleler bitti"
	_end_detail.text = _goals_left_text() + "\nVazgeçersen bir kap boşalır."
	_stars_row.visible = false
	var progress := UiKit.progress()
	var ads := UiKit.ads()
	_continue_coins.visible = not _continued and progress != null and progress.coins() >= progress.CONTINUE_COST
	if progress:
		_continue_coins.text = "+%d hamle · %d altın" % [progress.CONTINUE_MOVES, progress.CONTINUE_COST]
	_continue_ad.visible = not _continued and ads != null and ads.is_rewarded_available(&"continue")
	_primary.text = "Tekrar dene"
	_secondary.text = "Haritaya dön"
	_open_end(LOSE_CAT)


func _on_primary() -> void:
	if _end_state == &"win" and rescue_pending():
		UiKit.go(&"rescue", {"level_id": level.id})
	elif _end_state == &"win":
		_leave_to_map(true)
	else:
		_retry()


func _on_secondary() -> void:
	if _end_state == &"win":
		_retry()
	else:
		fail_attempt()
		_leave_to_map(false)


func _leave_to_map(after_win: bool) -> void:
	var ads := UiKit.ads()
	if after_win and ads:
		await ads.maybe_show_interstitial(&"win_continue", level.id)
	UiKit.go(&"map")


func _on_coin_continue() -> void:
	var progress := UiKit.progress()
	if progress == null or not progress.spend_coins(progress.CONTINUE_COST):
		return
	UiKit.sound(&"coin")
	_grant_extra_moves(progress.CONTINUE_MOVES)


func _on_ad_continue() -> void:
	var ads := UiKit.ads()
	if ads == null:
		return
	if await ads.show_rewarded(&"continue"):
		var progress := UiKit.progress()
		_grant_extra_moves(progress.CONTINUE_MOVES if progress else 5)


func _grant_extra_moves(amount: int) -> void:
	_continued = true
	session.add_moves(amount)
	_moves_label.text = str(session.moves_left)
	_close_overlay()


func _stock(booster: StringName) -> int:
	var progress := UiKit.progress()
	return progress.booster_stock(booster) if progress else FALLBACK_STOCK


func _on_booster_pressed(booster: StringName) -> void:
	if board_view.busy or session.is_finished():
		return
	if _stock(booster) <= 0:
		_offer_booster_purchase(booster)
		return
	if booster == M3.BOOSTER_SHUFFLE:
		_use_booster(booster, Vector2i.ZERO)
		return
	_set_armed(&"" if _armed == booster else booster)


func _offer_booster_purchase(booster: StringName) -> void:
	var progress := UiKit.progress()
	if progress == null:
		return
	var price: int = progress.BOOSTER_PRICES[str(booster)]
	var booster_name := _booster_label(booster)
	if progress.coins() < price:
		_confirm("%s için %d altın gerekiyor.\nŞu an %d altının var." % [booster_name, price, progress.coins()], "Tamam", Callable())
		return
	_confirm("%s satın alınsın mı?\n%d altın" % [booster_name, price], "Satın al", func() -> void:
		if progress.buy_booster(booster):
			UiKit.sound(&"coin")
			_refresh_boosters())


func _on_cell_tapped(cell: Vector2i) -> void:
	if _armed != &"":
		_use_booster(_armed, cell)


func _use_booster(booster: StringName, cell: Vector2i) -> void:
	_set_armed(&"")
	var steps := session.use_booster(booster, cell)
	if steps.is_empty():
		return
	_open_attempt()
	var progress := UiKit.progress()
	if progress:
		progress.use_booster(booster)
	_refresh_boosters()
	await board_view.play(steps)
	_check_end()


func _set_armed(booster: StringName) -> void:
	_armed = booster
	board_view.booster_armed = booster != &""
	_refresh_boosters()


func _booster_label(booster: StringName) -> String:
	for entry in BOOSTERS:
		if entry.id == booster:
			return entry.label
	return ""


func _confirm(message: String, yes_text: String, action: Callable) -> void:
	_confirm_action = action
	_confirm_label.text = message
	_confirm_yes.text = yes_text
	_confirm_no.visible = action.is_valid()
	_intro_panel.visible = false
	_pause_panel.visible = false
	_end_panel.visible = false
	_confirm_panel.visible = true
	_overlay.visible = true


func _on_confirm_yes() -> void:
	var action := _confirm_action
	_confirm_action = Callable()
	_close_overlay()
	if action.is_valid():
		action.call()


func _on_confirm_no() -> void:
	_confirm_action = Callable()
	_close_overlay()


func _open_end(cat_id: String) -> void:
	_confirm_panel.visible = false
	_intro_panel.visible = false
	_pause_panel.visible = false
	_end_panel.visible = true
	_end_cat.setup(cat_id, 210.0, UiKit.idle_level())
	_overlay.visible = true


func _close_overlay() -> void:
	_overlay.visible = false
	_end_panel.visible = false
	_confirm_panel.visible = false
	_intro_panel.visible = false
	_pause_panel.visible = false


func _show_stars(count: int) -> void:
	var n := 0
	for star: TextureRect in _stars_row.get_children():
		star.texture = ArtAtlas.texture("star_on" if n < count else "star_off")
		star.pivot_offset = star.custom_minimum_size / 2.0
		star.scale = Vector2.ONE
		if n < count:
			star.scale = Vector2(0.2, 0.2)
			var tween := create_tween()
			tween.tween_interval(0.12 * n)
			tween.tween_property(star, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var pitch := 1.0 + 0.12 * n
			tween.parallel().tween_callback(func() -> void: UiKit.sound(&"star", pitch))
		n += 1


func _goals_left_text() -> String:
	var parts := PackedStringArray()
	for kind in session.goals:
		if session.goals[kind] > 0:
			parts.append("%d %s" % [session.goals[kind], KIND_NAMES.get(kind, "taş")])
	var text := "Kalan: " + ", ".join(parts)
	if session.stage < session.stage_count():
		text += " (ve ikinci hedef)"
	return text


# The second goal set replaces the goal cards once the first one is done.
func _on_stage_changed(_stage: int) -> void:
	_build_goals()
	_refresh_goals(session.goals)
	_show_banner("İkinci hedef!", STAGE_BANNER_HOLD, true)


func _refresh_goals(remaining: Dictionary) -> void:
	for kind in _goal_items:
		# Fur goals grow while fur spreads, so the total comes from the session.
		# Not get(kind, level.goals[kind]): the default is evaluated first and a second-stage key is not in level.goals.
		var total: int = session.goal_totals[kind] if session.goal_totals.has(kind) else int(level.goals.get(kind, 0))
		var done: int = total - int(remaining.get(kind, 0))
		_goal_items[kind].count.text = "%d / %d" % [done, total]
		_goal_items[kind].bar.max_value = total
		_goal_items[kind].bar.value = done


func _refresh_boosters() -> void:
	var progress := UiKit.progress()
	for booster in BOOSTERS:
		var button: Button = _booster_buttons.get(booster.id)
		if button == null:
			continue
		var stock := _stock(booster.id)
		if stock > 0 or progress == null:
			button.text = "%s  %d" % [booster.label, stock]
		else:
			button.text = "%s · %d" % [booster.label, progress.BOOSTER_PRICES[str(booster.id)]]
		button.modulate = Color(1.0, 0.86, 0.72) if _armed == booster.id else Color.WHITE


func _on_special_created(_special: int) -> void:
	var progress := UiKit.progress()
	if progress == null or bool(progress.setting("vibration")):
		Input.vibrate_handheld(VIBRATION_MS)


func _on_tile_cleared(kind: int, global_pos: Vector2) -> void:
	if not _goal_items.has(kind):
		return
	var sprite: Sprite2D = null
	for candidate in _flyers:
		if not candidate.visible:
			sprite = candidate
			break
	if sprite == null:
		return
	var icon: TextureRect = _goal_items[kind].icon
	var target := icon.get_global_rect().get_center()
	sprite.texture = _goal_texture(kind)
	sprite.global_position = global_pos
	var base := board_view.cell_size() * 0.8 / sprite.texture.get_width()
	sprite.scale = Vector2(base, base)
	sprite.visible = true
	var duration := 0.45 * _quality_scale()
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "global_position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2(base, base) * 0.5, duration)
	tween.chain().tween_callback(_on_flyer_arrived.bind(sprite, icon))


func _on_flyer_arrived(sprite: Sprite2D, icon: TextureRect) -> void:
	sprite.visible = false
	icon.pivot_offset = icon.size / 2.0
	var tween := create_tween()
	tween.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.07)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.12)


func _on_combo(count: int) -> void:
	if COMBO_WORDS.has(count) and _end_state == &"":
		_show_banner(COMBO_WORDS[count])


# hold: seconds the text stays before fading; combo words flash, announcements linger.
# Low quality shortens tweens, even to zero; an announcement keeps its full reading time.
func _show_banner(text: String, hold: float = 0.35, keep_readable: bool = false) -> void:
	_combo_label.text = text
	_combo_label.reset_size()
	_combo_label.pivot_offset = _combo_label.size / 2.0
	_combo_label.global_position = board_view.get_global_rect().get_center() - _combo_label.size / 2.0
	_combo_label.scale = Vector2(0.4, 0.4)
	_combo_label.modulate.a = 1.0
	_combo_label.visible = true
	var tween := create_tween()
	tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold if keep_readable else hold * _quality_scale())
	tween.tween_property(_combo_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: _combo_label.visible = false)


func _quality_scale() -> float:
	var quality := UiKit.autoload("Quality")
	return quality.duration(1.0) if quality and quality.profile else 1.0


func _build_ui() -> void:
	add_child(UiKit.background())
	var page := UiKit.page()
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	page.add_child(column)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	column.add_child(top)
	pause_button = UiKit.button("II", 30, Vector2(80, 72))
	pause_button.pressed.connect(open_pause)
	top.add_child(pause_button)
	_level_label = UiKit.label("", 44)
	top.add_child(_level_label)
	_badge = UiKit.pill("Zor", UiKit.DANGER, Color.WHITE, 22)
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_badge)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var moves_panel := PanelContainer.new()
	moves_panel.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 40, 12))
	top.add_child(moves_panel)
	var moves_row := HBoxContainer.new()
	moves_row.add_theme_constant_override("separation", 8)
	moves_panel.add_child(moves_row)
	_moves_label = UiKit.label("", 36)
	moves_row.add_child(_moves_label)
	var moves_word := UiKit.label("hamle", 22, UiKit.MUTED)
	moves_word.size_flags_vertical = Control.SIZE_SHRINK_END
	moves_row.add_child(moves_word)

	var goal_card := PanelContainer.new()
	goal_card.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 28, 18))
	column.add_child(goal_card)
	_goal_row = HBoxContainer.new()
	_goal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_goal_row.add_theme_constant_override("separation", 32)
	goal_card.add_child(_goal_row)

	var play_area := VBoxContainer.new()
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_area.alignment = BoxContainer.ALIGNMENT_CENTER
	play_area.add_theme_constant_override("separation", 26)
	column.add_child(play_area)

	board_view = BoardView.new()
	board_view.textures = _textures
	board_view.swap_requested.connect(_on_swap_requested)
	board_view.cell_tapped.connect(_on_cell_tapped)
	board_view.goals_changed.connect(_refresh_goals)
	board_view.stage_changed.connect(_on_stage_changed)
	board_view.tile_cleared.connect(_on_tile_cleared)
	board_view.combo.connect(_on_combo)
	board_view.special_created.connect(_on_special_created)
	board_view.touched.connect(_on_board_touched)
	play_area.add_child(board_view)
	column.resized.connect(func() -> void: board_view.custom_minimum_size = Vector2(0, column.size.x))

	var boosters := HBoxContainer.new()
	boosters.alignment = BoxContainer.ALIGNMENT_CENTER
	boosters.add_theme_constant_override("separation", 20)
	play_area.add_child(boosters)
	for booster in BOOSTERS:
		var button := UiKit.button("", 24, Vector2(200, 136))
		button.icon = ArtAtlas.texture(booster.icon)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", 64)
		button.pressed.connect(_on_booster_pressed.bind(booster.id))
		boosters.add_child(button)
		_booster_buttons[booster.id] = button

	_fly_layer = Node2D.new()
	add_child(_fly_layer)
	for n in FLYER_POOL:
		var flyer := Sprite2D.new()
		flyer.visible = false
		_fly_layer.add_child(flyer)
		_flyers.append(flyer)

	_combo_label = UiKit.label("", 76, Color.WHITE)
	_combo_label.add_theme_color_override("font_outline_color", UiKit.ACCENT)
	_combo_label.add_theme_constant_override("outline_size", 20)
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label.visible = false
	add_child(_combo_label)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.2, 0.1, 0.05, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	_build_end_panel(center)
	_build_confirm_panel(center)
	_build_intro_panel(center)
	_build_pause_panel(center)


func pause_visible() -> bool:
	return _overlay.visible and _pause_panel.visible


# Opens the break menu; only while the player could otherwise make a move.
func open_pause() -> void:
	if _overlay.visible or session.is_finished():
		return
	_refresh_pause_toggles()
	_pause_note.text = "Yeniden başlarsan ya da çıkarsan bir mama kabı boşalır." if _attempt_open else "Henüz hamle yapmadın; çıkmak ücretsiz."
	_end_panel.visible = false
	_confirm_panel.visible = false
	_intro_panel.visible = false
	_pause_panel.visible = true
	_overlay.visible = true


func close_pause() -> void:
	if pause_visible():
		_close_overlay()


# Android back button: closes whatever card is open, otherwise opens the break menu.
func handle_back() -> void:
	if pause_visible():
		close_pause()
	elif intro_visible():
		_on_intro_done()
	elif _overlay.visible and _confirm_panel.visible:
		_on_confirm_no()
	elif not _overlay.visible:
		open_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and session != null:
		open_pause()


func _on_pause_restart() -> void:
	_close_overlay()
	_retry()


func _on_pause_quit() -> void:
	_close_overlay()
	fail_attempt()
	UiKit.go(&"map")


func _toggle_setting(key: String) -> void:
	var progress := UiKit.progress()
	if progress:
		progress.set_setting(key, not bool(progress.setting(key)))
	_refresh_pause_toggles()


func _refresh_pause_toggles() -> void:
	var progress := UiKit.progress()
	var sound_on: bool = progress == null or bool(progress.setting("sound"))
	var vibration_on: bool = progress == null or bool(progress.setting("vibration"))
	_pause_sound.text = "Ses: %s" % ("Açık" if sound_on else "Kapalı")
	_pause_vibration.text = "Titreşim: %s" % ("Açık" if vibration_on else "Kapalı")


func _build_pause_panel(parent: Control) -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.custom_minimum_size = Vector2(540, 0)
	_pause_panel.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 36, 40))
	_pause_panel.visible = false
	parent.add_child(_pause_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	_pause_panel.add_child(rows)
	rows.add_child(UiKit.centered_label("Mola", 52))
	rows.add_child(UiKit.centered_label("Kediler seni bekliyor.", 28, UiKit.MUTED))
	var resume := UiKit.button("Devam et", 34, Vector2(0, 100), UiKit.ACCENT, Color.WHITE, 50)
	resume.pressed.connect(close_pause)
	rows.add_child(resume)
	var restart := UiKit.button("Yeniden başla", 30, Vector2(0, 88))
	restart.pressed.connect(_on_pause_restart)
	rows.add_child(restart)
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 14)
	rows.add_child(toggles)
	_pause_sound = UiKit.button("", 26, Vector2(0, 80), Color("fff4e8"), UiKit.INK, 40)
	_pause_sound.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_sound.pressed.connect(_toggle_setting.bind("sound"))
	toggles.add_child(_pause_sound)
	_pause_vibration = UiKit.button("", 26, Vector2(0, 80), Color("fff4e8"), UiKit.INK, 40)
	_pause_vibration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_vibration.pressed.connect(_toggle_setting.bind("vibration"))
	toggles.add_child(_pause_vibration)
	var quit := UiKit.button("Haritaya dön", 28, Vector2(0, 84))
	quit.pressed.connect(_on_pause_quit)
	rows.add_child(quit)
	_pause_note = UiKit.centered_label("", 22, UiKit.MUTED)
	rows.add_child(_pause_note)


func _on_board_touched() -> void:
	_idle = 0.0


func _build_intro_panel(parent: Control) -> void:
	_intro_panel = PanelContainer.new()
	_intro_panel.custom_minimum_size = Vector2(560, 0)
	_intro_panel.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 36, 40))
	_intro_panel.visible = false
	parent.add_child(_intro_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 20)
	_intro_panel.add_child(rows)
	var art_holder := Control.new()
	art_holder.custom_minimum_size = Vector2(0, 180)
	rows.add_child(art_holder)
	_intro_art = TextureRect.new()
	_intro_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_holder.add_child(_intro_art)
	_intro_tile = TileView.new()
	art_holder.add_child(_intro_tile)
	art_holder.resized.connect(func() -> void: _intro_tile.position = art_holder.size / 2.0)
	_intro_title = UiKit.centered_label("", 44)
	rows.add_child(_intro_title)
	_intro_text = UiKit.centered_label("", 30, UiKit.MUTED)
	rows.add_child(_intro_text)
	var done := UiKit.button("Anladım", 34, Vector2(0, 100), UiKit.ACCENT, Color.WHITE, 50)
	done.pressed.connect(_on_intro_done)
	rows.add_child(done)


func _build_end_panel(parent: Control) -> void:
	_end_panel = PanelContainer.new()
	_end_panel.custom_minimum_size = Vector2(560, 0)
	_end_panel.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 36, 40))
	parent.add_child(_end_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	_end_panel.add_child(rows)
	var cat_holder := Control.new()
	cat_holder.custom_minimum_size = Vector2(0, 220)
	rows.add_child(cat_holder)
	_end_cat = CatRig.new()
	cat_holder.add_child(_end_cat)
	cat_holder.resized.connect(func() -> void: _end_cat.position = Vector2(cat_holder.size.x / 2.0, cat_holder.size.y))
	_end_title = UiKit.label("", 50)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_end_title)
	_stars_row = HBoxContainer.new()
	_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars_row.add_theme_constant_override("separation", 10)
	rows.add_child(_stars_row)
	for n in 3:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(72, 72)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_stars_row.add_child(star)
	_end_detail = UiKit.label("", 30, UiKit.MUTED)
	_end_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_end_detail)
	_continue_coins = UiKit.button("", 30, Vector2(0, 92), Color("ffe38a"), UiKit.INK, 46)
	_continue_coins.pressed.connect(_on_coin_continue)
	rows.add_child(_continue_coins)
	_continue_ad = UiKit.button("+5 hamle · reklam izle", 30, Vector2(0, 92), Color("cfe9ff"), UiKit.INK, 46)
	_continue_ad.pressed.connect(_on_ad_continue)
	rows.add_child(_continue_ad)
	_primary = UiKit.button("", 34, Vector2(0, 100), UiKit.ACCENT, Color.WHITE, 50)
	_primary.pressed.connect(_on_primary)
	rows.add_child(_primary)
	_secondary = UiKit.button("", 28, Vector2(0, 84))
	_secondary.pressed.connect(_on_secondary)
	rows.add_child(_secondary)


func _build_confirm_panel(parent: Control) -> void:
	_confirm_panel = PanelContainer.new()
	_confirm_panel.custom_minimum_size = Vector2(520, 0)
	_confirm_panel.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, 36, 40))
	_confirm_panel.visible = false
	parent.add_child(_confirm_panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 22)
	_confirm_panel.add_child(rows)
	_confirm_label = UiKit.label("", 34)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_confirm_label)
	_confirm_yes = UiKit.button("", 32, Vector2(0, 96), UiKit.ACCENT, Color.WHITE, 48)
	_confirm_yes.pressed.connect(_on_confirm_yes)
	rows.add_child(_confirm_yes)
	_confirm_no = UiKit.button("Vazgeç", 28, Vector2(0, 84))
	_confirm_no.pressed.connect(_on_confirm_no)
	rows.add_child(_confirm_no)


func _build_goals() -> void:
	for child in _goal_row.get_children():
		child.queue_free()
	_goal_items.clear()
	# The session's totals follow the current stage and grow with spreading fur.
	var totals: Dictionary = session.goal_totals if session else level.goals
	for kind in totals:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 12)
		_goal_row.add_child(item)
		var icon := TextureRect.new()
		icon.texture = _goal_texture(kind)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(icon)
		var info := VBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		item.add_child(info)
		var count := UiKit.label("", 28)
		info.add_child(count)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(120, 14)
		bar.show_percentage = false
		bar.max_value = totals[kind]
		bar.add_theme_stylebox_override("background", UiKit.box(UiKit.TRACK, 7, 0, false))
		bar.add_theme_stylebox_override("fill", UiKit.box(UiKit.ACCENT, 7, 0, false))
		info.add_child(bar)
		_goal_items[kind] = {"icon": icon, "count": count, "bar": bar}


func _read_dev_args() -> void:
	if not OS.is_debug_build():
		return
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo = true
		elif arg == "--show-win":
			_show_win_on_start = true
		elif arg.begins_with("--seed="):
			_fixed_seed = maxi(arg.trim_prefix("--seed=").to_int(), 1)
