class_name BoardView
extends Control

signal swap_requested(a: Vector2i, b: Vector2i)
signal cell_tapped(cell: Vector2i)
signal tile_cleared(kind: int, global_pos: Vector2)
signal goals_changed(remaining: Dictionary)
signal stage_changed(stage: int)
signal combo(count: int)
signal special_created(special: int)
signal touched

const NO_CELL := Vector2i(-1, -1)
const NO_HINT := Vector2i(-1, -1)
const BLOCK_GOALS := {M3.Block.BOX: M3.GOAL_BOX, M3.Block.KNOT: M3.GOAL_KNOT, M3.Block.CRATE: M3.GOAL_KITTEN, M3.Block.SLEEPER: M3.GOAL_SLEEPER, M3.Block.FUR: M3.GOAL_FUR, M3.Block.CAGE: M3.GOAL_CAGE}
const BLOCK_COLORS := {M3.Block.BOX: Color("d9a061"), M3.Block.KNOT: Color("a974e0"), M3.Block.CRATE: Color("b07a44"), M3.Block.SLEEPER: Color("f0b37a"), M3.Block.FUR: Color("e6d8c8"), M3.Block.CAGE: Color("f2c94c")}
const PAW_COLOR := Color("e89a86")
const MOUSE_COLOR := Color("c7ccd4")
# Mice sit small in the top-right corner of their cell so the tile under them stays readable.
const MOUSE_SCALE := 0.58
const FRAME_MARGIN := 12.0
const SWAP_TIME := 0.14
const CLEAR_TIME := 0.18
const FALL_TIME := 0.16
const SPECIAL_POP_TIME := 0.22
const HIT_STOP_TIME := 0.12
const MAX_BURSTS_PER_STEP := 10
const DRAG_THRESHOLD := 0.35
const KIND_COLORS := [Color.WHITE, Color("d9574a"), Color("9b6fc6"), Color("4a8fc9"), Color("c9875a"), Color("e9b530")]

var animate := true
var quality: Node
var audio: Node
var textures: Array[Texture2D] = []
var busy := false
var booster_armed := false
var hint_move := NO_HINT
# Counts playbacks that ended out of sync with the board; tests expect zero.
var resyncs := 0

var _board: M3Board
var _tiles: Array = []
var _blocks := {}
var _block_type := PackedInt32Array()
var _block_hp := PackedInt32Array()
var _ground := PackedInt32Array()
var _mice := PackedInt32Array()
var _mouse_sprites := {}
var _block_layer := Node2D.new()
var _hint_tween: Tween
var _pool: Array[TileView] = []
var _all_tiles: Array[TileView] = []
var _layer := Node2D.new()
var _fx := FxPool.new()
var _cell := 96.0
var _origin := Vector2.ZERO
var _press_cell := NO_CELL
var _press_pos := Vector2.ZERO
var _dragged := false
var _selected := NO_CELL
var _frame_style := StyleBoxFlat.new()
var _shape_frame_style := StyleBoxFlat.new()
var _cell_light := StyleBoxFlat.new()
var _cell_dark := StyleBoxFlat.new()
var _select_style := StyleBoxFlat.new()


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_layer)
	# Obstacles draw above tiles by staying the last child of the tile layer (a z_index would
	# also lift them above popups drawn over the board).
	_layer.add_child(_block_layer)
	add_child(_fx)
	resized.connect(_layout)
	_frame_style.bg_color = Color("c98f5a")
	_frame_style.set_corner_radius_all(26)
	_frame_style.border_color = Color("7a4a24")
	_frame_style.border_width_bottom = 8
	_shape_frame_style.bg_color = _frame_style.bg_color
	_shape_frame_style.set_corner_radius_all(14)
	_cell_light.bg_color = Color("fbefdf")
	_cell_dark.bg_color = Color("f1e0c8")
	for style in [_cell_light, _cell_dark]:
		style.set_corner_radius_all(12)
	_select_style.draw_center = false
	_select_style.set_border_width_all(5)
	_select_style.border_color = Color.WHITE
	_select_style.set_corner_radius_all(14)
	_select_style.shadow_color = Color(1.0, 0.77, 0.24, 0.9)
	_select_style.shadow_size = 12


func _ready() -> void:
	if quality == null:
		quality = get_node_or_null("/root/Quality")
	if audio == null:
		audio = get_node_or_null("/root/Audio")


func setup(board: M3Board) -> void:
	clear_hint()
	_board = board
	_selected = NO_CELL
	_block_type = board.blockers.duplicate()
	_block_hp = board.blocker_hp.duplicate()
	_ground = board.ground.duplicate()
	for sprite: Sprite2D in _blocks.values():
		sprite.free()
	_blocks.clear()
	_mice = board.mice.duplicate()
	for sprite: Sprite2D in _mouse_sprites.values():
		sprite.free()
	_mouse_sprites.clear()
	for tile in _tiles:
		if tile != null:
			_release(tile)
	_tiles.resize(board.cell_count())
	_tiles.fill(null)
	for n in board.cell_count() * 2 - _all_tiles.size():
		var spare := TileView.new()
		spare.visible = false
		_layer.add_child(spare)
		_all_tiles.append(spare)
		_pool.append(spare)
	_layer.move_child(_block_layer, -1)
	for i in board.cell_count():
		if _block_type[i] != M3.Block.NONE and _block_type[i] != M3.Block.HOLE:
			var sprite := Sprite2D.new()
			sprite.texture = _block_texture(_block_type[i], _block_hp[i])
			_block_layer.add_child(sprite)
			_blocks[i] = sprite
	for i in board.cell_count():
		if _mice[i] > 0:
			var mouse := Sprite2D.new()
			mouse.texture = ArtAtlas.texture("mouse")
			_block_layer.add_child(mouse)
			_mouse_sprites[i] = mouse
	_layout()
	for i in board.cell_count():
		if board.is_occupied(i):
			_tiles[i] = _acquire(board.kinds[i], board.specials[i], i)
	queue_redraw()


# Gently pulses the two tiles of a suggested move until the player touches the board.
func show_hint(move: Vector2i) -> void:
	clear_hint()
	hint_move = move
	if not animate or busy:
		return
	var ta: TileView = _tiles[move.x]
	var tb: TileView = _tiles[move.y]
	if ta == null or tb == null:
		return
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(ta, "scale", Vector2(1.14, 1.14), 0.28)
	_hint_tween.parallel().tween_property(tb, "scale", Vector2(1.14, 1.14), 0.28)
	_hint_tween.tween_property(ta, "scale", Vector2.ONE, 0.28)
	_hint_tween.parallel().tween_property(tb, "scale", Vector2.ONE, 0.28)
	_hint_tween.tween_interval(0.7)


func clear_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	if hint_move != NO_HINT and _board != null:
		for i in [hint_move.x, hint_move.y]:
			if i < _tiles.size() and _tiles[i] != null:
				_tiles[i].scale = Vector2.ONE
	hint_move = NO_HINT


func block_sprite_count() -> int:
	return _blocks.size()


func mouse_sprite_count() -> int:
	return _mouse_sprites.size()


func cell_size() -> float:
	return _cell


func cell_center(i: int) -> Vector2:
	var p := _board.pos(i)
	return _origin + Vector2((p.x + 0.5) * _cell, (p.y + 0.5) * _cell)


func cell_at(local_pos: Vector2) -> Vector2i:
	if _board == null or _cell <= 0.0:
		return NO_CELL
	var p := ((local_pos - _origin) / _cell).floor()
	return Vector2i(int(p.x), int(p.y))


func pooled_tile_count() -> int:
	return _all_tiles.size()


func active_tile_count() -> int:
	var count := 0
	for tile in _tiles:
		if tile != null:
			count += 1
	return count


func particle_bursts() -> int:
	return _fx.bursts_emitted


func tiles_match_board() -> bool:
	for i in _board.cell_count():
		if _block_hp[i] != _board.blocker_hp[i] or _block_type[i] != _board.blockers[i] or _ground[i] != _board.ground[i]:
			return false
		if _blocks.has(i) != (_board.blockers[i] != M3.Block.NONE and not _board.is_hole(i)):
			return false
		if _mice[i] != _board.mice[i] or _mouse_sprites.has(i) != (_board.mice[i] > 0):
			return false
		var tile: TileView = _tiles[i]
		if not _board.is_occupied(i):
			if tile != null:
				return false
			continue
		if tile == null or tile.kind != _board.kinds[i] or tile.special != _board.specials[i]:
			return false
	return true


func play(steps: Array) -> void:
	clear_hint()
	busy = true
	var chain := 0
	for step in steps:
		if step.type == M3.STEP_SWAP:
			await _play_swap(step.a, step.b)
		elif step.type == M3.STEP_CLEAR:
			chain += 1
			await _play_clear(step, chain)
		elif step.type == M3.STEP_SPECIAL:
			await _play_special(step)
		elif step.type == M3.STEP_FALL:
			await _play_fall(step.moves)
		elif step.type == M3.STEP_SPAWN:
			await _play_spawn(step.cells)
		elif step.type == M3.STEP_SHUFFLE:
			await _play_shuffle(step)
		elif step.type == M3.STEP_BLOCKER:
			await _play_blocker(step)
		elif step.type == M3.STEP_GROUND:
			_play_ground(step)
		elif step.type == M3.STEP_COLLECT:
			await _play_collect(step)
		elif step.type == M3.STEP_DOZE:
			await _play_doze(step)
		elif step.type == M3.STEP_SPREAD:
			await _play_spread(step)
		elif step.type == M3.STEP_STAGE:
			stage_changed.emit(step.stage)
		elif step.type == M3.STEP_CATCH:
			await _play_catch(step)
		elif step.type == M3.STEP_RUN:
			await _play_run(step)
		elif step.type == M3.STEP_BELT:
			await _play_belt(step)
		elif step.type == M3.STEP_GOAL:
			goals_changed.emit(step.remaining)
	if not tiles_match_board():
		push_warning("BoardView drifted from the board state; resyncing.")
		resyncs += 1
		setup(_board)
	busy = false


func play_invalid(a: Vector2i, b: Vector2i) -> void:
	_sfx(&"invalid")
	if not animate or not _board.in_bounds(a) or not _board.in_bounds(b):
		return
	var ta: TileView = _tiles[_board.idx(a)]
	var tb: TileView = _tiles[_board.idx(b)]
	if ta == null or tb == null:
		return
	busy = true
	var pa := cell_center(_board.idx(a))
	var pb := cell_center(_board.idx(b))
	var tween := create_tween().set_parallel()
	tween.tween_property(ta, "position", pa.lerp(pb, 0.35), _d(0.08))
	tween.tween_property(tb, "position", pb.lerp(pa, 0.35), _d(0.08))
	tween.chain().tween_property(ta, "position", pa, _d(0.12))
	tween.tween_property(tb, "position", pb, _d(0.12))
	await tween.finished
	busy = false


func _gui_input(event: InputEvent) -> void:
	if _board == null:
		return
	# On phones the finger usually lifts while the swap is still animating; that release must
	# still end the gesture, or the stale press turns the next touch into a wrong tap.
	if busy:
		if event is InputEventMouseButton and not event.pressed:
			_press_cell = NO_CELL
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clear_hint()
			touched.emit()
			_press_cell = cell_at(event.position)
			_press_pos = event.position
			_dragged = false
		else:
			if not _dragged and _board.in_bounds(_press_cell) and _press_cell == cell_at(event.position):
				_on_tap(_press_cell)
			_press_cell = NO_CELL
	elif event is InputEventMouseMotion and _press_cell != NO_CELL and not _dragged:
		var delta: Vector2 = event.position - _press_pos
		if delta.length() < _cell * DRAG_THRESHOLD:
			return
		_dragged = true
		if booster_armed or not _board.in_bounds(_press_cell):
			return
		var direction := Vector2i(signi(int(delta.x)), 0) if absf(delta.x) > absf(delta.y) else Vector2i(0, signi(int(delta.y)))
		_set_selected(NO_CELL)
		_request(_press_cell, _press_cell + direction)


func _on_tap(cell: Vector2i) -> void:
	if booster_armed:
		cell_tapped.emit(cell)
		return
	if _selected == NO_CELL or _selected == cell:
		_set_selected(NO_CELL if _selected == cell else cell)
	elif absi(_selected.x - cell.x) + absi(_selected.y - cell.y) == 1:
		var first := _selected
		_set_selected(NO_CELL)
		_request(first, cell)
	else:
		_set_selected(cell)


func _request(a: Vector2i, b: Vector2i) -> void:
	if _board.in_bounds(a) and _board.in_bounds(b):
		swap_requested.emit(a, b)


func _set_selected(cell: Vector2i) -> void:
	_selected = cell
	queue_redraw()


func _layout() -> void:
	if _board == null:
		return
	var inner := size - Vector2(FRAME_MARGIN, FRAME_MARGIN) * 2.0
	var new_cell := floorf(minf(inner.x / _board.width, inner.y / _board.height))
	if new_cell <= 0.0:
		return
	_cell = new_cell
	_origin = ((size - Vector2(_board.width, _board.height) * _cell) / 2.0).floor()
	for i in _tiles.size():
		var tile: TileView = _tiles[i]
		if tile != null:
			tile.position = cell_center(i)
			tile.set_cell_size(_cell)
	for i: int in _blocks:
		_fit_block(_blocks[i], i)
	for i: int in _mouse_sprites:
		_fit_mouse(_mouse_sprites[i], i)
	queue_redraw()


func _fit_block(sprite: Sprite2D, i: int) -> void:
	sprite.position = cell_center(i)
	if sprite.texture:
		var factor := _cell * 0.98 / sprite.texture.get_width()
		sprite.scale = Vector2(factor, factor)


func _mouse_position(i: int) -> Vector2:
	return cell_center(i) + Vector2(_cell * 0.22, -_cell * 0.2)


func _fit_mouse(sprite: Sprite2D, i: int) -> void:
	sprite.position = _mouse_position(i)
	if sprite.texture:
		var factor := _cell * MOUSE_SCALE / sprite.texture.get_width()
		sprite.scale = Vector2(factor, factor)


func _block_texture(block: int, hp: int) -> Texture2D:
	if block == M3.Block.BOX:
		return ArtAtlas.texture("box_2" if hp >= 2 else "box_1")
	if block == M3.Block.CRATE:
		return ArtAtlas.texture("crate_2" if hp >= 2 else "crate_1")
	if block == M3.Block.SLEEPER:
		return ArtAtlas.texture("sleeper_%d" % clampi(hp, 1, M3.SLEEPER_HP))
	if block == M3.Block.FUR:
		return ArtAtlas.texture("fur")
	if block == M3.Block.CAGE:
		return ArtAtlas.texture("cage")
	return ArtAtlas.texture("knot")


func _draw() -> void:
	if _board == null:
		return
	var board_rect := Rect2(_origin, Vector2(_board.width, _board.height) * _cell)
	if _board.has_holes():
		# Shaped boards: the frame follows the cells, so holes show the background through.
		for y in _board.height:
			for x in _board.width:
				if not _board.is_hole(y * _board.width + x):
					draw_style_box(_shape_frame_style, Rect2(_origin + Vector2(x, y) * _cell, Vector2(_cell, _cell)).grow(FRAME_MARGIN - 2.0))
	else:
		draw_style_box(_frame_style, board_rect.grow(FRAME_MARGIN - 2.0))
	for y in _board.height:
		for x in _board.width:
			if _board.is_hole(y * _board.width + x):
				continue
			var style := _cell_light if (x + y) % 2 == 0 else _cell_dark
			draw_style_box(style, Rect2(_origin + Vector2(x, y) * _cell + Vector2(2, 2), Vector2(_cell - 4, _cell - 4)))
			var belt := _board.belts[y * _board.width + x]
			if belt != 0:
				# A negative width mirrors the right-pointing belt art for "<" belts.
				var corner := _origin + Vector2(x, y) * _cell + Vector2(_cell if belt < 0 else 0.0, 0)
				draw_texture_rect(ArtAtlas.texture("belt"), Rect2(corner, Vector2(_cell * belt, _cell)), false)
			if _ground[y * _board.width + x] > 0:
				draw_texture_rect(ArtAtlas.texture("paw_print"), Rect2(_origin + Vector2(x, y) * _cell + Vector2(3, 3), Vector2(_cell - 6, _cell - 6)), false)
	if _selected != NO_CELL:
		draw_style_box(_select_style, Rect2(_origin + Vector2(_selected) * _cell, Vector2(_cell, _cell)))


func _acquire(kind: int, special: int, i: int) -> TileView:
	var tile: TileView
	if _pool.is_empty():
		tile = TileView.new()
		_layer.add_child(tile)
		_layer.move_child(_block_layer, -1)
		_all_tiles.append(tile)
	else:
		tile = _pool.pop_back()
	tile.visible = true
	tile.setup(kind, special, _texture_for(kind), _cell)
	tile.position = cell_center(i)
	return tile


func _release(tile: TileView) -> void:
	tile.visible = false
	tile.setup(M3.EMPTY, M3.Special.NONE, null, _cell)
	_pool.append(tile)


func _texture_for(kind: int) -> Texture2D:
	return textures[kind] if kind > 0 and kind < textures.size() else null


func _play_swap(a: int, b: int) -> void:
	_sfx(&"swap")
	var ta: TileView = _tiles[a]
	var tb: TileView = _tiles[b]
	_tiles[a] = tb
	_tiles[b] = ta
	if not animate:
		ta.position = cell_center(b)
		tb.position = cell_center(a)
		return
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ta, "position", cell_center(b), _d(SWAP_TIME))
	tween.tween_property(tb, "position", cell_center(a), _d(SWAP_TIME))
	await tween.finished


func _play_clear(step: Dictionary, chain: int) -> void:
	var cells: PackedInt32Array = step.cells
	var kinds: PackedInt32Array = step.kinds
	var amount := _particles()
	var stride := maxi(1, ceili(cells.size() / float(MAX_BURSTS_PER_STEP)))
	var cleared: Array[TileView] = []
	for n in cells.size():
		var i := cells[n]
		var tile: TileView = _tiles[i]
		_tiles[i] = null
		if tile == null:
			continue
		cleared.append(tile)
		var at := cell_center(i)
		tile_cleared.emit(kinds[n], get_global_transform() * at)
		if n % stride == 0:
			_fx.burst(at, _kind_color(kinds[n]), amount)
	combo.emit(chain)
	if str(step.cause) == "combo" or cells.size() >= 10:
		_sfx(&"blast")
		_shake(7.0)
	else:
		_sfx(&"pop", pow(2.0, clampi(chain - 1, 0, 12) / 12.0))
	if animate and not cleared.is_empty():
		var tween := create_tween().set_parallel()
		for tile in cleared:
			tween.tween_property(tile, "scale", Vector2(1.18, 0.82), _d(CLEAR_TIME * 0.4))
			tween.tween_property(tile, "scale", Vector2.ZERO, _d(CLEAR_TIME * 0.6)).set_delay(_d(CLEAR_TIME * 0.4))
			tween.tween_property(tile, "modulate:a", 0.0, _d(CLEAR_TIME))
		await tween.finished
	for tile in cleared:
		_release(tile)


func _play_special(step: Dictionary) -> void:
	var cells: PackedInt32Array = step.cells
	var kind: int = step.kind
	var tween: Tween = null
	special_created.emit(step.special)
	_sfx(&"color" if step.special == M3.Special.COLOR else &"special")
	for i in cells:
		var tile: TileView = _tiles[i]
		if tile == null:
			tile = _acquire(kind, step.special, i)
			_tiles[i] = tile
		else:
			tile.setup(kind, step.special, _texture_for(kind), _cell)
		if animate:
			if tween == null:
				tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tile.scale = Vector2(1.35, 1.35)
			tween.tween_property(tile, "scale", Vector2.ONE, _d(SPECIAL_POP_TIME))
	if animate and _hit_stop_enabled():
		await get_tree().create_timer(HIT_STOP_TIME).timeout


func _play_fall(moves: Array) -> void:
	var tween: Tween = null
	for move: Vector2i in moves:
		var tile: TileView = _tiles[move.x]
		_tiles[move.x] = null
		_tiles[move.y] = tile
		if tile == null:
			continue
		if not animate:
			tile.position = cell_center(move.y)
			continue
		if tween == null:
			tween = create_tween().set_parallel().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		var rows := float(move.y - move.x) / _board.width
		tween.tween_property(tile, "position", cell_center(move.y), _d(FALL_TIME * sqrt(rows) * 1.6))
	if tween != null:
		await tween.finished


func _play_spawn(spawned: Array) -> void:
	var per_column := PackedInt32Array()
	per_column.resize(_board.width)
	for s: Vector2i in spawned:
		per_column[s.x % _board.width] += 1
	var tween: Tween = null
	for s: Vector2i in spawned:
		var tile := _acquire(s.y, M3.Special.NONE, s.x)
		_tiles[s.x] = tile
		if not animate:
			continue
		if tween == null:
			tween = create_tween().set_parallel().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		if _below_fixed_cell(s.x):
			# Tiles cannot drop through obstacles, so cells under them pop in place.
			tile.scale = Vector2(0.2, 0.2)
			tween.tween_property(tile, "scale", Vector2.ONE, _d(FALL_TIME * 1.8)).set_trans(Tween.TRANS_BACK)
			continue
		var drop := per_column[s.x % _board.width] * _cell
		tile.position = cell_center(s.x) - Vector2(0, drop)
		tile.modulate.a = 0.0
		tween.tween_property(tile, "position", cell_center(s.x), _d(FALL_TIME * 1.8))
		tween.tween_property(tile, "modulate:a", 1.0, _d(FALL_TIME * 0.6))
	if tween != null:
		await tween.finished


func _play_shuffle(step: Dictionary) -> void:
	_sfx(&"color", 0.8)
	var kinds: PackedInt32Array = step.kinds
	var specials: PackedInt32Array = step.specials
	if animate:
		var shrink := create_tween().set_parallel()
		for tile in _tiles:
			if tile != null:
				shrink.tween_property(tile, "scale", Vector2(0.2, 0.2), _d(0.16))
		await shrink.finished
	for i in _tiles.size():
		if kinds[i] == M3.EMPTY and specials[i] == M3.Special.NONE:
			continue
		if _tiles[i] == null:
			_tiles[i] = _acquire(kinds[i], specials[i], i)
		else:
			_tiles[i].setup(kinds[i], specials[i], _texture_for(kinds[i]), _cell)
	if animate:
		var grow := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		for tile in _tiles:
			if tile == null:
				continue
			tile.scale = Vector2(0.2, 0.2)
			grow.tween_property(tile, "scale", Vector2.ONE, _d(0.22))
		await grow.finished


func _play_blocker(step: Dictionary) -> void:
	_sfx(&"box")
	var tween: Tween = null
	for n in step.cells.size():
		var i: int = step.cells[n]
		var block: int = step.blocks[n]
		var hp: int = step.hp[n]
		var at := cell_center(i)
		_block_hp[i] = hp
		_fx.burst(at, BLOCK_COLORS.get(block, Color.WHITE), _particles())
		var sprite: Sprite2D = _blocks.get(i)
		if hp > 0:
			if sprite:
				sprite.texture = _block_texture(block, hp)
				_fit_block(sprite, i)
				if animate:
					if tween == null:
						tween = create_tween().set_parallel()
					var base := sprite.scale
					sprite.scale = base * 1.12
					tween.tween_property(sprite, "scale", base, _d(0.16))
			continue
		_block_type[i] = M3.Block.NONE
		_blocks.erase(i)
		tile_cleared.emit(BLOCK_GOALS[block], get_global_transform() * at)
		if sprite == null:
			continue
		if not animate:
			sprite.free()
			continue
		if tween == null:
			tween = create_tween().set_parallel()
		tween.tween_property(sprite, "scale", sprite.scale * 1.3, _d(0.18))
		tween.tween_property(sprite, "modulate:a", 0.0, _d(0.18))
		tween.chain().tween_callback(sprite.queue_free)
	if tween != null:
		await tween.finished


func _play_ground(step: Dictionary) -> void:
	_sfx(&"paw")
	for n in step.cells.size():
		var i: int = step.cells[n]
		_ground[i] = step.hp[n]
		if _ground[i] == 0:
			var at := cell_center(i)
			_fx.burst(at, PAW_COLOR, _particles())
			tile_cleared.emit(M3.GOAL_PAW, get_global_transform() * at)
	queue_redraw()


# Undisturbed sleeping cats sink back into sleep: their art gains a "z" with a slow breath.
func _play_doze(step: Dictionary) -> void:
	var tween: Tween = null
	for n in step.cells.size():
		var i: int = step.cells[n]
		_block_hp[i] = step.hp[n]
		var sprite: Sprite2D = _blocks.get(i)
		if sprite == null:
			continue
		sprite.texture = _block_texture(M3.Block.SLEEPER, _block_hp[i])
		_fit_block(sprite, i)
		if animate:
			if tween == null:
				tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
			var base := sprite.scale
			sprite.scale = base * 0.9
			tween.tween_property(sprite, "scale", base, _d(0.3))
	if tween != null:
		await tween.finished


func _play_catch(step: Dictionary) -> void:
	_sfx(&"paw", 1.3)
	var tween: Tween = null
	for i: int in step.cells:
		_mice[i] = 0
		var sprite: Sprite2D = _mouse_sprites.get(i)
		_mouse_sprites.erase(i)
		var at := _mouse_position(i)
		_fx.burst(at, MOUSE_COLOR, _particles())
		tile_cleared.emit(M3.GOAL_MOUSE, get_global_transform() * at)
		if sprite == null:
			continue
		if not animate:
			sprite.free()
			continue
		if tween == null:
			tween = create_tween().set_parallel()
		tween.tween_property(sprite, "scale", sprite.scale * 1.4, _d(0.18))
		tween.tween_property(sprite, "modulate:a", 0.0, _d(0.18))
		tween.chain().tween_callback(sprite.queue_free)
	if tween != null:
		await tween.finished


# Mice scurry to their new cells, facing the way they run (the art faces left).
func _play_run(step: Dictionary) -> void:
	var tween: Tween = null
	for move: Vector2i in step.moves:
		_mice[move.x] = 0
		_mice[move.y] = 1
		var sprite: Sprite2D = _mouse_sprites.get(move.x)
		_mouse_sprites.erase(move.x)
		if sprite == null:
			continue
		_mouse_sprites[move.y] = sprite
		var dx := move.y % _board.width - move.x % _board.width
		if dx != 0:
			sprite.flip_h = dx > 0
		if not animate:
			sprite.position = _mouse_position(move.y)
			continue
		if tween == null:
			tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position", _mouse_position(move.y), _d(0.24))
	if tween != null:
		await tween.finished


# Belt tiles slide one cell; a tile that wraps to the start of its run pops in there instead.
func _play_belt(step: Dictionary) -> void:
	var carried: Array[TileView] = []
	for move: Vector2i in step.moves:
		carried.append(_tiles[move.x])
	for move: Vector2i in step.moves:
		_tiles[move.x] = null
	for n in step.moves.size():
		_tiles[step.moves[n].y] = carried[n]
	_sfx(&"swap", 0.8)
	var tween: Tween = null
	for n in step.moves.size():
		var move: Vector2i = step.moves[n]
		var tile := carried[n]
		if tile == null:
			continue
		if not animate:
			tile.position = cell_center(move.y)
			continue
		if tween == null:
			tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		if absi(move.y - move.x) > 1:
			tile.position = cell_center(move.y)
			tile.scale = Vector2(0.2, 0.2)
			tween.tween_property(tile, "scale", Vector2.ONE, _d(0.22))
		else:
			tween.tween_property(tile, "position", cell_center(move.y), _d(0.22))
	if tween != null:
		await tween.finished


# A tuft rolls from the fur pile onto the neighbouring tile and covers it.
func _play_spread(step: Dictionary) -> void:
	var to: int = step.to
	var tile: TileView = _tiles[to]
	_tiles[to] = null
	_block_type[to] = M3.Block.FUR
	_block_hp[to] = 1
	var sprite := Sprite2D.new()
	sprite.texture = _block_texture(M3.Block.FUR, 1)
	_block_layer.add_child(sprite)
	_blocks[to] = sprite
	_fit_block(sprite, to)
	_sfx(&"paw", 0.7)
	if animate:
		var base := sprite.scale
		sprite.position = cell_center(step.from)
		sprite.scale = base * 0.4
		var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position", cell_center(to), _d(0.3))
		tween.tween_property(sprite, "scale", base, _d(0.3))
		if tile != null:
			tween.tween_property(tile, "scale", Vector2(0.3, 0.3), _d(0.22))
		await tween.finished
	if tile != null:
		tile.scale = Vector2.ONE
		_release(tile)


# Sacks count as goals when collected; a key only turns in its lock (the cage it opens follows).
func _play_collect(step: Dictionary) -> void:
	var is_key: bool = step.get("key", false)
	var cells: PackedInt32Array = step.cells
	_sfx(&"coin" if is_key else &"sack")
	var tween: Tween = null
	var leaving: Array[TileView] = []
	for i in cells:
		var tile: TileView = _tiles[i]
		_tiles[i] = null
		if tile == null:
			continue
		leaving.append(tile)
		if not is_key:
			tile_cleared.emit(M3.GOAL_SACK, get_global_transform() * cell_center(i))
		if animate:
			if tween == null:
				tween = create_tween().set_parallel()
			tween.tween_property(tile, "position", tile.position + Vector2(0, _cell * 0.7), _d(0.25))
			tween.tween_property(tile, "modulate:a", 0.0, _d(0.25))
	if tween != null:
		await tween.finished
	for tile in leaving:
		_release(tile)


func _below_fixed_cell(i: int) -> bool:
	var above := i - _board.width
	while above >= 0:
		if _block_type[above] != M3.Block.NONE:
			return true
		above -= _board.width
	return false


func _shake(strength: float) -> void:
	if not animate or not _shake_enabled():
		return
	var tween := create_tween()
	for n in 5:
		tween.tween_property(_layer, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.03)
	tween.tween_property(_layer, "position", Vector2.ZERO, 0.04)


func _sfx(sound: StringName, pitch: float = 1.0) -> void:
	if audio:
		audio.play(sound, pitch)


func _kind_color(kind: int) -> Color:
	return KIND_COLORS[kind] if kind > 0 and kind < KIND_COLORS.size() else Color.WHITE


func _particles() -> int:
	return quality.particles_per_burst() if quality else 12


func _shake_enabled() -> bool:
	return quality.shake_enabled() if quality else true


func _hit_stop_enabled() -> bool:
	return quality.hit_stop_enabled() if quality else true


func _d(seconds: float) -> float:
	return quality.duration(seconds) if quality else seconds
