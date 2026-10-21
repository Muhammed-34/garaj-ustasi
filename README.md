# Garaj Ustası – Match 3 Mobil Oyun

Müşterilerin araçlarını tamir edip galerini doldurduğun, **60 bölümlük** Türkçe bir match 3 oyunu. **Godot 4.7.2** ve **GDScript** ile Android için geliştirildi; oyun mantığı görüntüden ayrı, test edilebilir bir çekirdek olarak yazıldı. Reklam yok, oyun içi satın alma yok, internet izni yok.

![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-355570?logo=godotengine&logoColor=white)
![Android](https://img.shields.io/badge/Android-7.0+-3DDC84?logo=android&logoColor=white)
![gdUnit4](https://img.shields.io/badge/Testler-gdUnit4-6E4C9E)
![Claude](https://img.shields.io/badge/Yapay_Zekâ_Destekli-Claude-D97757?logo=anthropic&logoColor=white)

<p align="center">
  <img src="docs/title.png" width="250" alt="Ana ekran: Mahalle Garajı">
  <img src="docs/gameplay.gif" width="250" alt="Oynanış">
</p>

## Özellikler

| Bölüm | İçerik |
|---|---|
| **İş emri ve sabır** | Müşteriler aracını getirir; toplanan parçalar ilk bekleyen iş emrine sayılır. Her takas, teslim edilmemiş müşterilerin sabrını bir azaltır; sabrı biten müşteri gider ve bölüm kaybedilir. |
| **Teslim etme** | İş emri tamamlanınca tamir edilen araç tahtaya düşer; daha fazla inemeyince müşteriye teslim edilir. |
| **Parçalar ve özel taşlar** | Direksiyon, dişli, far, buji ve lastik · 4'lü eşleşme satır/sütun temizler, L ve T bomba yapar, 2x2 kare uçan taş çıkarır, 5'li eşleşme renk bombası verir. |
| **Engeller** | Lastik yığını, paslı varil, zincirli parça, yağ lekesi, garajdaki fare ve konveyör bant. |
| **Galeri ve rütbeler** | 12 araç, her 5 bölümde biri açılır. Galeri doldukça garajın rütbesi büyür: Mahalle Garajı, Oto Tamirhanesi, Usta Atölyesi, Şampiyon Galeri. |

Ayrıca:

- **Can sistemi:** 3 yakıt bidonu; kaybedilen deneme bir bidonu boşaltır, bidonlar 30 dakikada bir dolar.
- **Güçlendiriciler:** Anahtar, kompresör ve çekiç; oyunda kazanılan altınla alınır.
- **Ayarlar:** Düşük/orta/yüksek grafik profili, "animasyonları azalt", pil tasarrufu ve titreşim.
- **Gizlilik:** Oyun veri toplamaz ve internete bağlanmaz; ilerleme yalnızca cihazdaki `save.json` dosyasında tutulur.
- **Özgün içerik:** Bütün çizimler SVG kodundan, bütün sesler koddan üretildi; gerçek bir araba markası, logosu ya da model adı kullanılmadı.

| Harita | Oynanış | Galeri |
|---|---|---|
| <img src="docs/map.png" width="230" alt="Harita: Yarış Pisti"> | <img src="docs/gameplay.png" width="230" alt="Lastik yığınlı bölüm"> | <img src="docs/collection.png" width="230" alt="Galeri"> |

## Mimari

```
addons/match3/     → Oyun mantığı: tahta, eşleştirici, özel taşlar, iş emirleri, çözümleyici, hamle bulucu, bot (Node kullanmaz)
game/autoload/     → Kayıt ve ilerleme, kalite profilleri, ses, sahne yönlendirici, reklam kapısı (kapalı)
game/board_view/   → Tahtanın görünümü ve efektleri
game/scenes/       → Ana ekran, harita, oyun, galeri, ayarlar, lisanslar
game/meta/         → Oyun kuralları: araçlar, garaj rütbeleri, müşteri sözleri, takvim, ekonomi
data/levels/       → 60 bölüm (.tres, araçla üretilir)
tools/             → Çizim, ses, bölüm ayarlama ve test araçları (oyuna dahil edilmez)
tests/             → gdUnit4 testleri: çekirdek, oyun, denge
```

- **Mantık ile görüntü ayrıdır.** `addons/match3` bir hamleyi senkron çözer ve adım listesi döner; görünüm katmanı bu adımları oynatır.
- **Bot ile bölüm ayarı.** Bot, oyunu ekran olmadan oynayarak bölümlerin zorluğunu ölçer; bölümler bir tablodan bu ölçümle ayarlanıp üretilir.
- **Tekrarlanabilir rastgelelik.** Taş üretimi ve karıştırma bölüm tohumundan türeyen ayrı `RandomNumberGenerator` nesneleriyle yapılır; aynı tohum aynı tahtayı verir.
- **Güvenli kayıt.** Kayıt dosyası önce geçici dosyaya yazılıp yeniden adlandırılır (atomik yazma).
- **Performans.** Compatibility (GLES3) işleyici, tek doku atlası, taş ve parçacık nesneleri için havuz.

## Kullanılan Teknolojiler

**Oyun:** Godot 4.7.2, GDScript, Compatibility (GLES3) işleyici, Android dışa aktarma

**Test:** gdUnit4 (361 test: çekirdek kurallar, oyun ekranları, bölüm dengesi), ekransız bot ile oynanış taraması

**Araçlar:** Node.js + resvg-js (SVG çizimlerden doku atlası), GDScript ile ses sentezi ve bölüm üretimi, PowerShell test betiği

## Kurulum

### Telefona yükleme

1. [Releases](../../releases) sayfasından en son `garaj-ustasi-*.apk` dosyasını telefonuna indir.
2. Dosyayı aç. Android "bilinmeyen kaynak" uyarısı verirse bu kaynağa izin ver.
3. Android 7.0 ve üstü gerekir. Uygulama test sürümüdür, hata ayıklama anahtarıyla imzalanmıştır; Play Store sürümü değildir.

### Kaynaktan çalıştırma

Gereksinimler: [Godot 4.7.2](https://godotengine.org/download) (APK için dışa aktarma şablonları, JDK 17 ve Android SDK).

```bash
git clone https://github.com/Muhammed-34/garaj-ustasi.git
cd garaj-ustasi
godot --path .
```

Testler, çizim ve ses üretimi, bölüm ayarlama ve APK alma adımları için: [docs/gelistirme.md](docs/gelistirme.md)

## Yapay Zekâ Destekli Geliştirme

Bu proje, kodun büyük bölümü **Claude (Anthropic)** ile birlikte yazılarak geliştirildi. Yapay zekâyı bir kod yazma aracı olarak kullandım; projeyi yönlendiren kararlar ve doğrulama bana aitti:

- **Fikir ve oyun tasarımı:** Garaj temasını, iş emri ve sabır mekaniğini, araç galerisini ve rütbe sistemini belirledim.
- **Mimari kararlar:** Motor olarak Godot'u, oyun mantığını görüntüden ayıran çekirdek yapıyı, ortak match 3 çekirdeğinin başka oyunlarla paylaşılmasını ve reklamsız, internet izni olmayan bir sürümü seçtim.
- **Test:** Oyunu telefonda oynayarak denedim; testlerin ve bot taramasının sonuçlarını takip ettim, bölüm zorluğunu bu sonuçlara göre ayarlattım.
- **Hata ayıklama:** Cihazda karşılaştığım görsel ve oynanış hatalarını tespit edip düzeltilmesini yönettim ve düzeltmeleri doğruladım.
- **Yayın:** Android dışa aktarmasını, uygulama simgesini, tanıtım görsellerini ve GitHub Releases üzerinden APK yayınını hazırladım.

Bütün çizimlerin ve seslerin hazır paketlerden alınmak yerine koddan üretilmesi de bu süreçte alınan bir karardır; lisans dökümü [CREDITS.md](CREDITS.md) dosyasındadır.

## Lisans

Kod **MIT** lisanslıdır ([LICENSE](LICENSE)).

## Geliştirici

**Muhammed Çakıroğlu** · [LinkedIn](https://linkedin.com/in/muhammedcakiroglu) · [GitHub](https://github.com/Muhammed-34)
