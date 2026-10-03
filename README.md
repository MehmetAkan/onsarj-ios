# onsarj — iOS

Elektrikli araç sürücüleri için şarj istasyonu bulma, şarj duraklı rota planlama ve
uygulama içi adım adım navigasyon uygulaması.

> **Kod yazmadan önce [CLAUDE.md](CLAUDE.md) okunur.** Çalışma kuralları, mimari sınırlar
> ve alınmış kararlar oradadır. Projenin güncel durumu için [PROGRESS.md](PROGRESS.md).

---

## Gereksinimler

| | |
|---|---|
| Xcode | 16 veya üzeri |
| Minimum iOS | 17.0 |
| Cihaz | iPhone (iPad desteklenmiyor) |
| Bağımlılık yönetimi | Swift Package Manager (CocoaPods kullanılmaz) |

Apple Developer Program üyeliği ve ekibe davet gereklidir.

---

## İlk kurulum

1. Depoyu klonlayın.
2. `Config/Secrets.xcconfig.template` dosyasını `Config/Secrets.xcconfig` olarak kopyalayın
   ve Mapbox genel erişim token'ını girin. Bu dosya `.gitignore`'dadır, depoya işlenmez.
3. Mapbox gizli indirme token'ını `~/.netrc` dosyanıza ekleyin (ekip sorumlusundan isteyin).
4. `Onsarj.xcodeproj` dosyasını açın ve bir iPhone simülatöründe çalıştırın.

---

## Proje yapısı

```
App/          Uygulama hedefi — sahneler, bağımlılık bağlama, yönlendirme (ince)
Widgets/      Live Activity eklentisi
Packages/     TÜM KOD — Core, Domain, MapboxKit, Services, Features
Config/       Derleme ayarları (.xcconfig)
Tooling/      Betikler
ci_scripts/   Xcode Cloud betikleri
Docs/         Mimari notlar ve karar kayıtları
```

Ayrıntılı ağaç ve klasör kuralları için CLAUDE.md bölüm 5.6.

**En önemli iki kural:**
- Kod `App/` içinde değil, `Packages/` içinde yaşar.
- Derleme ayarı Xcode arayüzünden değil, `Config/*.xcconfig` dosyalarından değiştirilir.

---

## Geliştirme ortamı

Kod yazımı VS Code'da, geri kalan her şey Xcode'da yapılır. Simülatör, cihaz ve CarPlay
testi, kod imzalama, proje ayarları, Instruments ve String Catalog düzenlemesi Xcode'a aittir.

---

## CI/CD

| Ne | Nerede |
|---|---|
| Derleme, test, TestFlight | Xcode Cloud |
| SwiftLint, swift-format | GitHub Actions (Linux) |

Her inceleme isteğinde derleme, test ve lint kontrolleri çalışır. Hepsi yeşil olmadan
ana dala birleştirme yapılmaz.

---

## Katkı

Dal (branch) açın, değişikliğinizi yapın, inceleme isteği gönderin. `CODEOWNERS` dosyası
ilgili modülün sorumlusunu otomatik olarak incelemeye ekler.
