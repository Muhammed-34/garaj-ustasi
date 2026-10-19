# Geliştirme

Garaj Ustası, **Godot 4.7.2** (GDScript) ile yazıldı ve Tarif Mutfağı ile aynı match 3 çekirdeğini kullanır; tema, çizimler, meta ekranlar ve bölüm tablosu bu depoya özeldir. Çizimler ve sesler depoda hazır durur; aşağıdaki araçlar yalnızca onları yeniden üretmek için gerekir.

Gerekenler: Godot 4.7.2 (dışa aktarma şablonlarıyla), APK için JDK 17 + Android SDK, çizimler için Node.js 18+.

## Çalıştırma ve testler

```bash
# Oyunu çalıştır
godot --path .

# Bütün testler (361 test, gdUnit4)
tools\test.ps1

# Tek bir test grubu
tools\test.ps1 -Suite res://tests/game/map_theme_test.gd
```

## Çizim, ses ve bölümler

```bash
# Çizimler: SVG kodundan atlas ve game/art/atlas_data.gd üretir
cd tools/art && npm install && cd ../..
node tools/art/build.mjs
node tools/art/app_icon.mjs      # icon.png + Android uyarlanabilir simge katmanları

# Sesler koddan üretilir
godot --headless --path . -s tools/audio/make_sfx.gd

# Bölümler: tablo -> bot ile ayar -> .tres dosyaları
godot --headless --path . -s tools/levels/tune.gd -- --from=1 --to=10 --seeds=40
godot --headless --path . -s tools/levels/make_levels.gd

# Bütün bölümleri bot ile baştan sona oyna (oynanış taraması)
godot --headless --path . -s tools/level_bot/smoke.gd -- --from=1 --to=60 --seeds=3

# Test APK'sı
godot --headless --path . --export-debug Android ../garaj-ustasi-test.apk
```

Bölüm tasarımı `tools/levels/level_table.gd` dosyasındaki tablodan gelir; her satır hamleleri, iş emirlerini, sabırları ve engelleri tanımlar. `.tres` dosyaları elle düzenlenmez, `make_levels.gd` ile üretilir.

## Proje yapısı

```
addons/match3/     Oyun mantığı: tahta, eşleştirici, özel taşlar, iş emirleri, çözümleyici, bot (Node kullanmaz)
game/autoload/     Kayıt, ilerleme, reklam kapısı, kalite profilleri, ses, sahne yönlendirici
game/board_view/   Tahtanın görünümü ve efektleri
game/scenes/       Ana ekran, harita, oyun, galeri, ayarlar, lisanslar
game/meta/         Oyun kuralları: araçlar, garaj rütbeleri, müşteri sözleri, takvim, ekonomi
data/levels/       60 bölüm (.tres, üretilir)
tools/             Çizim, ses, bölüm ve test araçları (oyuna dahil edilmez)
tests/             gdUnit4 testleri: çekirdek, oyun, denge
```

Kod içindeki bazı adlar ortak çekirdekten gelir: `RECIPES` araçları, `RESTAURANTS` garaj rütbelerini, `orders` ise iş emirlerini tutar.

## Teknik notlar

- **Mantık ile görüntü ayrıdır.** `addons/match3` bir hamleyi senkron çözer ve adım listesi döner; görünüm bu adımları oynatır. Bot, oyunu ekran olmadan oynayarak bölümleri ölçer.
- **İş emri mantığı çekirdektedir.** Toplanan parça ilk bekleyen iş emrine sayılır; tamamlanınca eşleşmeyen bir araç taşı düşer ve inemeyince teslim edilir. Güçlendiriciler sabrı azaltmaz.
- **Rastgelelik bölüm tohumundan türer**, global `randi()` kullanılmaz; aynı tohum aynı tahtayı verir.
- **Kayıt sürümlüdür**; eski kayıtlar açılışta taşıma adımlarından geçer, yazma atomiktir.
- **Reklam altyapısı kapalıdır.** `Ads` autoload'u şu an hiçbir şey göstermeyen bir sağlayıcı kullanır (`game/ads_enabled=false`).
- **Performans.** Compatibility (GLES3) işleyici, tek atlas, havuzdan taş ve parçacık nesneleri.
- **Tanıtım görselleri.** `docs/` içindeki görüntüler ve oynanış GIF'i oyunun kendi demo modundan alınır; `docs/.gdignore` bu klasörün oyuna girmesini engeller.
