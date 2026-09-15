extends GdUnitTestSuite

const CATS := ["pamuk", "tarcin", "gece", "boncuk", "fistik", "limon", "duman", "tekir"]
const FRAME_PARTS := ["tail", "body", "head", "blink"]


func test_every_tile_kind_has_a_sprite() -> void:
	for kind in range(1, 6):
		assert_bool(ArtAtlas.has_sprite("tile_%d" % kind)).is_true()


func test_booster_and_ui_icons_exist() -> void:
	for sprite_name in ["booster_row", "booster_shuffle", "booster_single", "star_on", "star_off", "cat_silhouette"]:
		assert_bool(ArtAtlas.has_sprite(sprite_name)).is_true()


func test_every_cat_has_all_parts_and_a_face() -> void:
	for cat in CATS:
		for part in FRAME_PARTS + ["face"]:
			assert_bool(ArtAtlas.has_sprite("cat_%s_%s" % [cat, part])).is_true()


func test_cat_parts_share_one_frame_so_they_line_up() -> void:
	for cat in CATS:
		var first: Array = AtlasData.SPRITES["cat_%s_tail" % cat]
		for part in FRAME_PARTS:
			var s: Array = AtlasData.SPRITES["cat_%s_%s" % [cat, part]]
			assert_int(s[2]).is_equal(first[2])
			assert_int(s[3]).is_equal(first[3])


func test_atlas_images_match_generated_sizes() -> void:
	var big: Texture2D = load(ArtAtlas.ATLAS_PATHS[2])
	var small: Texture2D = load(ArtAtlas.ATLAS_PATHS[1])
	assert_int(big.get_width()).is_equal(AtlasData.WIDTH)
	assert_int(big.get_height()).is_equal(AtlasData.HEIGHT)
	assert_int(small.get_width() * 2).is_equal(big.get_width())
	assert_int(small.get_height() * 2).is_equal(big.get_height())


func test_low_detail_regions_are_exactly_half() -> void:
	var big := ArtAtlas.texture("tile_3", 2)
	var small := ArtAtlas.texture("tile_3", 1)
	assert_that(small.region.size * 2.0).is_equal(big.region.size)
	assert_that(small.region.position * 2.0).is_equal(big.region.position)


func test_sprite_coordinates_are_even_for_pixel_exact_half_size() -> void:
	for sprite_name in AtlasData.SPRITES:
		var s: Array = AtlasData.SPRITES[sprite_name]
		for n in 4:
			assert_int(int(s[n]) % 2).is_equal(0)


func test_sprites_do_not_overlap() -> void:
	var rects: Array[Rect2i] = []
	for sprite_name in AtlasData.SPRITES:
		var s: Array = AtlasData.SPRITES[sprite_name]
		rects.append(Rect2i(s[0], s[1], s[2], s[3]))
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			assert_bool(rects[i].intersects(rects[j])).is_false()


func test_sprites_stay_inside_the_atlas() -> void:
	for sprite_name in AtlasData.SPRITES:
		var s: Array = AtlasData.SPRITES[sprite_name]
		assert_int(s[0] + s[2]).is_less_equal(AtlasData.WIDTH)
		assert_int(s[1] + s[3]).is_less_equal(AtlasData.HEIGHT)


func test_textures_are_cached() -> void:
	assert_object(ArtAtlas.texture("tile_1", 2)).is_same(ArtAtlas.texture("tile_1", 2))


func test_tail_pivot_sits_at_the_tail_base() -> void:
	var pivot := ArtAtlas.pivot("cat_tekir_tail")
	assert_float(pivot.x).is_equal_approx(0.74, 0.001)
	assert_float(pivot.y).is_greater(0.8)
