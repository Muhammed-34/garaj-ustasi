class_name MetaRules
extends RefCounted

# Shown on the title sign, the map header and the boot screen; change it here only.
const GAME_NAME := "Tarif Mutfağı"
# Recipe book in unlock order; ids match the dish_<id> sprites drawn by tools/art/dishes.mjs.
const RECIPES := [
	{"id": "menemen", "name": "Menemen"},
	{"id": "coban", "name": "Çoban Salatası"},
	{"id": "omlet", "name": "Peynirli Omlet"},
	{"id": "mercimek", "name": "Mercimek Çorbası"},
	{"id": "gozleme", "name": "Gözleme"},
	{"id": "dolma", "name": "Biber Dolması"},
	{"id": "pide", "name": "Peynirli Pide"},
	{"id": "imam", "name": "İmam Bayıldı"},
	{"id": "kahvalti", "name": "Kahvaltı Tabağı"},
	{"id": "lahmacun", "name": "Lahmacun"},
	{"id": "karniyarik", "name": "Karnıyarık"},
	{"id": "cilbir", "name": "Çılbır"},
]
const QUOTES := [
	"Tam kıvamında, eline sağlık!",
	"Annemin yemeği gibi olmuş!",
	"Bir porsiyon daha alabilir miyim?",
	"Mis gibi kokuyor!",
	"Şefe selamlarımı iletin!",
]
const RESCUE_LEVELS := [5, 12, 20, 30, 40, 50, 60]
const BREEDS := ["tekir", "pamuk", "tarcin", "gece", "boncuk", "fistik", "limon", "duman"]
const BREED_LABELS := {
	"tekir": "Tekir", "pamuk": "Beyaz", "tarcin": "Sarman", "gece": "Siyah",
	"boncuk": "Krem", "fistik": "Kahverengi", "limon": "Sarı", "duman": "Gri",
}
const ROOM_NAMES := ["Salon", "Bahçe", "Çatı katı", "Kış bahçesi", "Kütüphane"]
const ROOM_CAPACITY := 4
const ADOPTION_UNLOCK_LEVEL := 60
const PARTY_MAX_MOVES := 8
const PARTY_COINS := 5
# Lives: a failed or abandoned attempt empties one food bowl; bowls refill one at a time.
const MAX_BOWLS := 3
const BOWL_REFILL_SECONDS := 30 * 60
const BOWL_REFILL_ALL_COST := 300
const MAX_NAME_LENGTH := 14
const NAME_POOL := [
	"Zeytin", "Paşa", "Mırmır", "Karamel", "Bulut", "Minnoş", "Şans", "Tontiş",
	"Pofuduk", "Fındık", "Kömür", "Pıtırcık", "Lokum", "Susam", "Bıcır", "Maviş",
]
const BOOSTER_NAMES := {"row": "Oklava", "shuffle": "Kepçe", "single": "Bıçak"}
# A new recipe joins the book every RECIPE_STEP levels, starting with level 1.
const RECIPE_STEP := 5
# The restaurant grows as the recipe book fills.
const RESTAURANTS := [
	{"name": "Esnaf Lokantası", "recipes": 0},
	{"name": "Ev Yemekleri Salonu", "recipes": 4},
	{"name": "Şef Restoranı", "recipes": 8},
	{"name": "Usta Mutfağı", "recipes": 12},
]
const CALENDAR := [
	{"coins": 50},
	{"coins": 75},
	{"coins": 100},
	{"booster": "single"},
	{"coins": 150},
	{"coins": 200},
	{"coins": 300, "booster": "row"},
]
const LETTERS := [
	"Merhaba! %s artık evimizin neşesi. Çocuklar her akşam onunla yün yumağı oynuyor.",
	"%s yeni evine hemen alıştı. Sabahları pencerenin önünde güneşlenmeyi çok seviyor.",
	"Bizim %s mama saatini hiç kaçırmıyor, mutfak kapısında bizi bekliyor. Onu bize emanet ettiğin için teşekkürler!",
	"%s dün gece ilk kez kucağımda uyudu. Barınaktaki herkese selamlar!",
]
const FAMILIES := ["Yılmaz ailesi", "Demir ailesi", "Kaya ailesi", "Şahin ailesi", "Aydın ailesi"]


static func recipe_name(id: String) -> String:
	for recipe in RECIPES:
		if recipe.id == id:
			return recipe.name
	return "Sipariş"


static func quote_for(level_id: int) -> String:
	return QUOTES[level_id % QUOTES.size()]


static func recipe_unlock_level(index: int) -> int:
	return 1 + index * RECIPE_STEP


# The recipe that joins the book when this level is first beaten, or -1.
static func recipe_index_for_level(level_id: int) -> int:
	if level_id < 1 or (level_id - 1) % RECIPE_STEP != 0:
		return -1
	var index := (level_id - 1) / RECIPE_STEP
	return index if index < RECIPES.size() else -1


static func restaurant_index(recipe_count: int) -> int:
	var index := 0
	for n in RESTAURANTS.size():
		if recipe_count >= int(RESTAURANTS[n].recipes):
			index = n
	return index


static func breed_for_rescue(index: int) -> String:
	return BREEDS[index % BREEDS.size()]


static func new_cat(id_number: int, rescue_index: int, cat_name: String, level_id: int) -> Dictionary:
	return {
		"id": "cat_%d" % id_number,
		"breed": breed_for_rescue(rescue_index),
		"name": cat_name,
		"level": level_id,
		"favorite": false,
		"adopted": false,
	}


static func sanitize_name(raw: String) -> String:
	var kept := ""
	for ch in raw.strip_edges():
		if ch == " " or ch.is_valid_int() or ch.to_upper() != ch.to_lower():
			kept += ch
	return " ".join(kept.split(" ", false)).substr(0, MAX_NAME_LENGTH).strip_edges()


static func suggest_names(taken: Array, count: int, seed_value: int) -> PackedStringArray:
	var pool := NAME_POOL.filter(func(candidate: String) -> bool: return not taken.has(candidate))
	if pool.is_empty():
		pool = NAME_POOL.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result := PackedStringArray()
	while result.size() < count and not pool.is_empty():
		var pick := rng.randi_range(0, pool.size() - 1)
		result.append(pool[pick])
		pool.remove_at(pick)
	return result


static func rooms_unlocked(shelter_count: int) -> int:
	return clampi(1 + floori(shelter_count / float(ROOM_CAPACITY)), 1, ROOM_NAMES.size())


static func adoption_block_reason(cat: Dictionary, highest_beaten: int) -> String:
	if bool(cat.get("adopted", false)):
		return "Bu dost zaten yeni yuvasında."
	if bool(cat.get("favorite", false)):
		return "Favori kediler barınakta kalır."
	if highest_beaten < ADOPTION_UNLOCK_LEVEL:
		return "Sahiplendirme %d. bölümden sonra açılır." % ADOPTION_UNLOCK_LEVEL
	return ""


static func reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	if reward.has("coins"):
		parts.append("%d altın" % int(reward.coins))
	if reward.has("booster"):
		parts.append(BOOSTER_NAMES.get(str(reward.booster), ""))
	return " + ".join(parts)


static func letter_text(cat: Dictionary) -> String:
	var number := str(cat.id).trim_prefix("cat_").to_int()
	return (LETTERS[number % LETTERS.size()] % str(cat.name)) + "\n— " + FAMILIES[number % FAMILIES.size()]


static func next_day(date: String) -> String:
	return Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(date) + 86400)
