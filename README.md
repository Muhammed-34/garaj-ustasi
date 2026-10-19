# Garaj Ustası

Müşterilerin araçlarını tamir edip galerini doldurduğun, **60 bölümlük** Türkçe bir match 3 oyunu.
Godot 4.7.2 ile yazıldı; bütün çizimler ve sesler kodla üretildi. Reklam yok, oyun içi satın alma yok, internet izni yok.

`Godot 4.7.2` · `Android 7.0+` · `361 test` · `MIT`

<p align="center">
  <img src="docs/title.png" width="250" alt="Ana ekran: Mahalle Garajı">
  <img src="docs/gameplay.gif" width="250" alt="Oynanış">
</p>

## Oyun

- **İş emri ve sabır.** Müşteriler aracını getirir; parçaları topladıkça tamir ilerler. Her takas, teslim edilmemiş müşterilerin sabrını bir azaltır. Sabrı biten müşteri aracını alıp gider ve bölüm kaybedilir.
- **Teslim etme.** İş emri tamamlanınca tamir edilen araç tahtaya düşer. Aracı aşağı indirmen gerekir; daha fazla inemeyince müşteriye teslim edilir.
- **60 bölüm.** İleri bölümlerde aynı anda birden çok müşteri bekler; hedefler bir botla ölçülerek ayarlandı.
- **Parçalar.** Direksiyon, dişli, far, buji ve lastik.
- **Özel taşlar.** 4'lü eşleşme satır/sütun temizler, L ve T bomba yapar, 2x2 kare uçan taş çıkarır, 5'li eşleşme renk bombası verir.
- **Engeller.** Lastik yığını, paslı varil, zincirli parça, yağ lekesi, garajdaki fare ve konveyör bant.
- **Galeri.** 12 araç vardır, her 5 bölümde biri açılır: kupa, skuter, pikap, minibüs, kros motor, cip, klasik, yarış arabası, çekici, hızlı motor, itfaiye aracı ve karavan. Hiçbiri gerçek bir marka ya da model değildir. Galeri doldukça garajın rütbesi büyür: Mahalle Garajı, Oto Tamirhanesi, Usta Atölyesi, Şampiyon Galeri.
- **Can sistemi.** 3 yakıt bidonu vardır; kaybedilen deneme bir bidonu boşaltır, bidonlar zamanla dolar.
- **Güçlendiriciler.** Anahtar, kompresör ve çekiç; altınla alınır.
- **Erişilebilirlik.** Düşük/orta/yüksek grafik profili, "animasyonları azalt", pil tasarrufu ve titreşim ayarı.

## Ekran görüntüleri

| Harita | Oynanış | Galeri |
|---|---|---|
| <img src="docs/map.png" width="230" alt="Harita: Yarış Pisti"> | <img src="docs/gameplay.png" width="230" alt="Lastik yığınlı bölüm"> | <img src="docs/collection.png" width="230" alt="Galeri"> |

## İndir ve oyna

1. [Releases](../../releases) sayfasından en son `garaj-ustasi-*.apk` dosyasını telefonuna indir.
2. Dosyayı aç. Android "bilinmeyen kaynak" uyarısı verirse bu kaynağa izin ver.
3. Android 7.0 ve üstü gerekir. Uygulama test sürümüdür, hata ayıklama anahtarıyla imzalanmıştır; Play Store sürümü değildir.

Oyun hiçbir veri toplamaz ve internete bağlanmaz. İlerlemen yalnızca telefonunda, uygulamanın kendi klasöründeki `save.json` dosyasında tutulur.

## Geliştirme

Gerekenler: **Godot 4.7.2** (dışa aktarma şablonlarıyla), APK üretmek için **JDK 17 + Android SDK**, çizimleri yeniden üretmek için **Node.js 18+**.

```bash
# Oyunu çalıştır
godot --path .

# Bütün testler (361 test, gdUnit4)
tools\test.ps1

# Tek bir test grubu
tools\test.ps1 -Suite res://tests/game/map_theme_test.gd
```

```bash
# Çizimler: SVG kodundan atlas ve game/art/atlas_data.gd üretir
cd tools/art && npm install && cd ../..
node tools/art/build.mjs
node tools/art/app_icon.mjs      # icon.png + Android uyarlanabilir simge katmanları

# Sesler koddan üretilir
godot --headless --path . -s tools/audio/make_sfx.gd
```

```bash
# Bölümler: tablo -> bot ile ayar -> .tres dosyaları
godot --headless --path . -s tools/levels/tune.gd -- --from=1 --to=10 --seeds=40
godot --headless --path . -s tools/levels/make_levels.gd

# Bütün bölümleri bot ile baştan sona oyna (oynanış taraması)
godot --headless --path . -s tools/level_bot/smoke.gd -- --from=1 --to=60 --seeds=3
```

```bash
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

## Teknik notlar

- **Mantık ile görüntü ayrıdır.** `addons/match3` bir hamleyi senkron çözer ve adım listesi döner; görünüm bu adımları oynatır. Bot, oyunu ekran olmadan oynayarak bölümleri ölçer.
- **İş emri mantığı çekirdektedir.** Toplanan parça ilk bekleyen iş emrine sayılır; tamamlanınca eşleşmeyen bir araç taşı düşer ve inemeyince teslim edilir. Güçlendiriciler sabrı azaltmaz.
- **Ortak çekirdek.** Oyun, Tarif Mutfağı ile aynı match 3 çekirdeğini kullanır; tema, çizimler, meta ekranlar ve bölüm tablosu bu depoya özeldir.
- **Rastgelelik bölüm tohumundan türer**, global `randi()` kullanılmaz; aynı tohum aynı tahtayı verir.
- **Reklam altyapısı kapalıdır.** `Ads` autoload'u şu an hiçbir şey göstermeyen bir sağlayıcı kullanır (`game/ads_enabled=false`).
- **Performans.** Compatibility (GLES3) işleyici, tek atlas, havuzdan taş ve parçacık nesneleri.

## Lisans ve kaynaklar

Kod **MIT** lisanslıdır ([LICENSE](LICENSE)).

Oyundaki her çizim, ses ve metin bu proje için üretildi; hiçbiri hazır varlık paketinden alınmadı, gerçek araba markası, logosu ya da model adı kullanılmadı. Ayrıntılı döküm ve kullanılan araçların lisansları için [CREDITS.md](CREDITS.md) ve [LICENSES/](LICENSES) klasörüne bakabilirsin. Godot ve yazı tipi bildirimleri oyun içindeki "Lisanslar" ekranında da gösterilir.

---

**English:** Garaj Ustası ("Garage Master") is a Turkish match 3 game with 60 levels, made with Godot 4.7.2. Customers bring vehicles in for repair and lose patience with every swap; a finished vehicle must be dropped down the board to be delivered, and it then joins your gallery. No real car brands, badges or model names are used. All art and sound are generated from code, with no ads, no in-app purchases and no internet permission. Download the APK from [Releases](../../releases); build instructions are above. Code is MIT licensed.
