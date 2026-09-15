class_name ArtAtlas
extends RefCounted

const ATLAS_PATHS := {1: "res://game/art/atlas_1x.png", 2: "res://game/art/atlas_2x.png"}

static var _cache := {}


static func texture(sprite_name: String, scale: int = 0) -> AtlasTexture:
	var atlas_scale := scale if scale > 0 else current_scale()
	var key := "%d:%s" % [atlas_scale, sprite_name]
	if _cache.has(key):
		return _cache[key]
	if not has_sprite(sprite_name):
		push_warning("Atlas has no sprite named %s" % sprite_name)
		return null
	var s: Array = AtlasData.SPRITES[sprite_name]
	var factor := atlas_scale / 2.0
	var result := AtlasTexture.new()
	result.atlas = load(ATLAS_PATHS[atlas_scale])
	result.region = Rect2(s[0] * factor, s[1] * factor, s[2] * factor, s[3] * factor)
	_cache[key] = result
	return result


static func has_sprite(sprite_name: String) -> bool:
	return AtlasData.SPRITES.has(sprite_name)


static func pivot(sprite_name: String) -> Vector2:
	if not has_sprite(sprite_name):
		return Vector2(0.5, 0.5)
	var s: Array = AtlasData.SPRITES[sprite_name]
	return Vector2(s[4], s[5])


static func current_scale() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var quality := tree.root.get_node_or_null("Quality") if tree else null
	if quality and quality.profile:
		return quality.profile.atlas_scale
	return 2
