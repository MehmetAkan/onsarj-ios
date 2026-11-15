# Backend sözleşme notları

iOS istemcisinin backend'den beklediği uç noktalar, JSON biçimleri ve doğrulama kuralları.
Buradaki JSON örnekleri istemcideki fixture'larla **birebir aynı alan adlarını** taşır; backend
bu biçimi verdiğinde istemcide yalnızca depo uygulaması değişir (CLAUDE.md K-23, K-26).

Uç noktalar **öneridir**; OpenAPI sözleşmesi (K-10) geldiğinde o esas alınır ve bu belgeler ona
göre güncellenir.

| Belge | Kapsam | İstemcideki durum |
|---|---|---|
| [vehicles.md](vehicles.md) | Araç listesi, araç oluşturma, varsayılan araç, sürüş profilleri, yazma istekleri | Debug'da fixture, Release'de boş |
| [vehicle-catalog.md](vehicle-catalog.md) | Araç kataloğu: marka → model → varyant | Debug'da fixture, Release'de boş |
| [route-preferences.md](route-preferences.md) | Rota planlama tercihleri | Şimdilik cihazda (`UserDefaults`) |
| [charging-networks.md](charging-networks.md) | Şarj ağı kataloğu: arama ve kimlikle getirme | Debug'da fixture, Release'de boş |

## K-26 özeti

Uygulamada yerel olarak saklanmayan her veri (araçlar, sürüş profilleri, kataloglar, istasyonlar,
şarj ağları) Domain'deki bir depo protokolü, DTO ve DTO → Domain eşlemesi üzerinden gelir. Backend
hazır olana kadar bu protokolleri JSON fixture'larla çalışan `#if DEBUG` uygulamalar karşılar.
Yazma işlemleri de backend isteği biçimindeki DTO'larla yapılır; fixture bunları bellekte bir backend
gibi doğrular, uygular ve yanıt DTO'su döner. Yeni veya değişen her DTO ve fixture, aynı görevde bu
klasördeki ilgili belgeyi günceller.

## Genel kurallar

- **Alan adları `camelCase`'dir** (`batteryHealthPercent`, `activeProfileId`). Kısaltmalarda yalnızca
  ilk harf büyüktür: `imageUrl`, `activeProfileId` (`imageURL` değil).
- **Kimlikler opak dizgelerdir.** İstemci biçimlerine anlam yüklemez (`veh_…`, `prof_…` yalnızca örnektir).
- **Sabit değer kümeleri küçük harfli dizgelerdir** (`"type2"`, `"hatchback"`, `"tolls"`). Bir kez
  yayınlanan değer değiştirilmez; yeni değer eklenebilir. İstemci tanımadığı değeri atlar veya
  belgelenen varsayılana çevirir, hata vermez.
- **Tarih ve saat:** ISO 8601, UTC, saniye hassasiyeti: `"2026-11-15T10:30:00Z"`.
- **Sayılar:** ondalık değerler JSON sayısıdır (`17.8`), dizge değildir. Birim alan adındadır
  (`consumptionKwhPer100Km`, `maxSpeedKmh`, `batteryCapacityKwh`).
- **Telefon numarası:** her zaman E.164 biçiminde: `"+905537359394"` (artı, ülke kodu, boşluksuz).
  İstemci numarayı bu biçimde gönderir ve bu biçimde bekler.
- **İsteğe bağlı alanlar:** yanıtta bilinmeyen değer `null` olabilir. Kısmi güncelleme (`PATCH`)
  gövdesinde yalnızca değişecek alanlar bulunur; gövdede olmayan alan değişmez.
- **Yazma yanıtları** değişmiş kaynağın tamamını döner (ör. araç güncellemesi aracın tamamını);
  istemci ekranı bununla günceller.

## Hata yanıtı

Hatalar HTTP durum kodu ve aşağıdaki gövdeyle döner. `code` makine içindir ve sabittir; `message`
yalnızca günlük içindir, kullanıcıya gösterilmez (metin istemcinin String Catalog'undan gelir).
`field`, hatanın ilgili olduğu istek alanıdır; yoksa `null`.

```json
{
  "error": {
    "code": "invalid_value",
    "field": "consumptionKwhPer100Km",
    "message": "consumptionKwhPer100Km must be between 5.0 and 50.0"
  }
}
```

| HTTP | Kullanım |
|---|---|
| 400 | Gövde çözülemedi |
| 401 | Oturum yok veya süresi doldu (istemci yeniler, tek noktadan) |
| 404 | Kaynak yok (`vehicle_not_found`, `variant_not_found`, `profile_not_found`) |
| 409 | Durumla çakışma (`duplicate_profile_name`, `cannot_delete_standard_profile`) |
| 422 | Geçersiz değer (`invalid_value`, `at_least_one_connector_required`) |

Kaynağa özel kodlar ilgili belgededir.

## Kaldırılan alanlar

Backend'in artık beklememesi veya göndermemesi gereken alanlar:

| Kaynak | Alan | Neden | Yerine |
|---|---|---|---|
| Araç | `consumptionWhPerKm` | Tüketim artık sürüş profilinin değeri | `drivingProfiles[].consumptionKwhPer100Km` |
| Araç | `rangeKm` | Menzil istemcide, etkin profilin tüketimiyle hesaplanıyor | Hesap: `vehicles.md` → Menzil |
| Rota tercihleri | `preferredNetworks[].isStrong` ("güçlü tercih") | Özellik kaldırıldı | `preferredNetworks` düz kimlik listesi |
