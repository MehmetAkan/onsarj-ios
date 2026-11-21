# Araçlar ve sürüş profilleri

İstemci: `VehicleRepository` (Domain), `VehicleDTO` / `DrivingProfileDTO` / `UpdateVehicleRequestDTO` /
`DrivingProfileRequestDTO` ve `VehicleMapper` (`Packages/Services/Sources/VehicleService`).
Fixture: `FixtureVehicleRepository` ve `FixtureVehicleBackend` (yalnızca Debug).

## Uç noktalar (öneri)

| Yöntem | Yol | Gövde | Yanıt |
|---|---|---|---|
| `GET` | `/vehicles` | — | `200` Araç listesi, **ekleme sırasıyla** |
| `POST` | `/vehicles` | `CreateVehicleRequest` | `201` Araç |
| `PATCH` | `/vehicles/{vehicleId}` | `UpdateVehicleRequest` | `200` Araç |
| `DELETE` | `/vehicles/{vehicleId}` | — | `204` |
| `POST` | `/vehicles/{vehicleId}/driving-profiles` | `DrivingProfileRequest` | `201` Araç |
| `PUT` | `/vehicles/{vehicleId}/driving-profiles/{profileId}` | `DrivingProfileRequest` | `200` Araç |
| `DELETE` | `/vehicles/{vehicleId}/driving-profiles/{profileId}` | — | `200` Araç |

Profil uç noktaları da **aracın tamamını** döner: profil listesi ve `activeProfileId` birlikte değişebilir.
Etkin profil ve varsayılan araç, araç güncellemesiyle (`PATCH`, `activeProfileId` / `isDefault`) değişir;
ayrı uç nokta yoktur.

**Tek varsayılan araç kuralı:** kullanıcının en çok bir aracı `isDefault: true` taşır; araç varsa tam olarak
biri. Varsayılanı değiştiren her işlem (oluşturma, `isDefault: true`, varsayılanın silinmesi) diğerlerini
`false` yapar. İstemci etkin aracı `isDefault`'tan okur; hiçbiri işaretli değilse listenin ilkini kullanır.

## Araç listesi yanıtı

```json
{
  "vehicles": [
    {
      "id": "veh_fixture_01",
      "make": "BYD",
      "model": "Dolphin",
      "variant": "Standart",
      "modelYear": 2023,
      "nickname": null,
      "batteryCapacityKwh": 60.5,
      "connectors": ["type2", "ccs2"],
      "maxAcPowerKw": 11,
      "maxDcPowerKw": 88,
      "colorHex": "#F2F2F2",
      "bodyType": "hatchback",
      "imageUrl": "https://…/byd-dolphin.png",
      "batteryHealthPercent": 95,
      "isDefault": true,
      "drivingProfiles": [
        {
          "id": "prof_fixture_standard",
          "name": "Standart",
          "consumptionKwhPer100Km": 17.8,
          "maxSpeedKmh": 120,
          "isStandard": true
        },
        {
          "id": "prof_fixture_highway",
          "name": "Otoyol",
          "consumptionKwhPer100Km": 20.5,
          "maxSpeedKmh": 130,
          "isStandard": false
        }
      ],
      "activeProfileId": "prof_fixture_standard"
    }
  ]
}
```

Fixture'da `imageUrl` bir görsel adıdır (`"vehicle-empty-state"`) ve istemci onu yerel dosyaya çevirir;
backend her zaman `https` adresi verir (K-24).

### Araç alanları

| Alan | Tip | Zorunlu | Açıklama | Geçerli aralık |
|---|---|---|---|---|
| `id` | string | evet | Araç kimliği | |
| `make` | string | evet | Marka, "BYD" | |
| `model` | string | evet | Model, "Dolphin" | |
| `variant` | string \| null | hayır | Donanım paketi, "Standart"; ayarlardaki "Araç" satırında görünür | |
| `modelYear` | integer | evet | Model yılı | |
| `nickname` | string \| null | hayır | Kullanıcının verdiği ad | |
| `batteryCapacityKwh` | number | evet | Kullanılabilir kapasite, kWh | > 0 |
| `connectors` | string[] | evet | Şarj soketleri: `type1`, `type2`, `ccs1`, `ccs2`, `chademo`, `nacs`. Tanınmayan değer istemcide atlanır | en az 1 |
| `maxAcPowerKw` | number \| null | hayır | En yüksek AC şarj gücü | |
| `maxDcPowerKw` | number \| null | hayır | En yüksek DC şarj gücü | |
| `colorHex` | string | evet | Boya rengi, `#RRGGBB` | `#` + 6 onaltılık rakam |
| `bodyType` | string | evet | Kasa tipi; tanınmayan değer istemcide `other` | |
| `imageUrl` | string \| null | hayır | Görsel adresi; geçersizse istemci görselsiz gösterir | `https` |
| `batteryHealthPercent` | integer | evet | Batarya sağlığı. Arayüz **bozulma** (`100 − sağlık`) gösterir | 0…100 okunur; yazmada 50…100 |
| `isDefault` | boolean | evet | Varsayılan araç; kart bunu gösterir, yoksa ilk araç | |
| `drivingProfiles` | DrivingProfile[] | evet | Sürüş profilleri | en az 1; tam olarak 1 `isStandard` |
| `activeProfileId` | string \| null | hayır | Etkin profil; yoksa veya listede değilse **standart profil** etkindir | |

### Sürüş profili alanları

| Alan | Tip | Zorunlu | Açıklama | Geçerli aralık |
|---|---|---|---|---|
| `id` | string | evet | Profil kimliği; backend üretir | |
| `name` | string | evet | Profil adı | 1…40 karakter; aynı araçta büyük/küçük harf duyarsız benzersiz |
| `consumptionKwhPer100Km` | number | evet | Referans tüketim, bir ondalık | 5.0…50.0 |
| `maxSpeedKmh` | integer | evet | Sürücünün yolculukta çıktığı tahmini en yüksek hız | 50…250 |
| `isStandard` | boolean | evet | Standart profil; silinemez, adı değişmez | araç başına tam olarak 1 |

### Menzil

Menzil backend'den gelmez; istemci etkin profille hesaplar (çevrimdışıyken de anında güncellenir):

```
menzil (km) = kapasite × sağlık/100 × batarya yüzdesi/100 ÷ (etkin profilin tüketimi / 100)
```

Örnek: 60,5 × 0,95 × 0,30 ÷ 0,178 ≈ **97 km**. Backend ileride bu sonucu kendisi verirse istemcide
yalnızca bu hesap değişir.

## Araç oluşturma: `POST /vehicles`

Araç katalogdaki varyanttan oluşturulur (`vehicle-catalog.md`).

```json
{ "variantId": "variant_togg_t10x_v1_rwd" }
```

| Alan | Tip | Zorunlu | Kural | Hata |
|---|---|---|---|---|
| `variantId` | string | evet | Katalogda olmalı | `404 variant_not_found` |

Backend aracı şöyle oluşturur:

| Araç alanı | Değer |
|---|---|
| `make`, `model`, `variant` | Markanın, modelin ve varyantın `name` alanları |
| `modelYear`, `batteryCapacityKwh`, `connectors`, `maxAcPowerKw`, `maxDcPowerKw`, `imageUrl` | Varyanttan |
| `bodyType` | Modelden |
| `nickname` | `null` |
| `colorHex` | `#F2F2F2` (beyaz) |
| `batteryHealthPercent` | `100` |
| `drivingProfiles` | Tek profil: `isStandard: true`, ad "Standart", `consumptionKwhPer100Km` = varyantın `referenceConsumptionKwhPer100Km`, `maxSpeedKmh` = `120` |
| `activeProfileId` | O standart profil |
| `isDefault` | `true`; kullanıcının diğer araçları `false` olur |

Aynı varyant birden çok kez eklenebilir (iki aynı araç); backend engellemez.

Yanıt: `201`, oluşan aracın tamamı.

## Araç güncelleme: `PATCH /vehicles/{vehicleId}`

Yalnızca gövdede bulunan alanlar değişir.

```json
{
  "nickname": "Beyaz",
  "connectors": ["type2", "ccs2"],
  "batteryHealthPercent": 95,
  "colorHex": "#2A5CAA",
  "activeProfileId": "prof_fixture_highway",
  "isDefault": true
}
```

| Alan | Tip | Açıklama | Kural |
|---|---|---|---|
| `nickname` | string | Takma ad. **Boş dizge takma adı kaldırır** (`null` olur); baştaki/sondaki boşluk kırpılır | |
| `connectors` | string[] | Konnektörlerin tamamı (ekleme/çıkarma değil, yeni liste) | en az 1 → değilse `at_least_one_connector_required` |
| `batteryHealthPercent` | integer | Batarya sağlığı (bozulma 0…50) | 50…100 → değilse `invalid_value` |
| `colorHex` | string | Boya rengi; istemci 8 hazır boyadan birini gönderir (aşağıda) | `#RRGGBB` → değilse `invalid_value` |
| `activeProfileId` | string | Etkin profil | aracın profillerinden biri → değilse `profile_not_found` |
| `isDefault` | boolean | Aracı varsayılan (etkin) yapar; diğer araçlar `false` olur. İstemci yalnızca `true` gönderir (varsayılan seçimi "Araçlarınız"dan yapılır) | yalnızca `true` → `false` gelirse `invalid_value` (`field: "isDefault"`) |

Hazır boyalar (istemcide `VehiclePaint`; backend herhangi bir `#RRGGBB` kabul edebilir):
siyah `#121212`, gri `#9AA0A6`, beyaz `#F2F2F2`, mavi `#2A5CAA`, kırmızı `#D7303A`, turuncu `#E8641B`,
sarı `#F5C518`, yeşil `#2E8B3A`. İstemci büyük/küçük harf duyarsız karşılaştırır.

Yanıt: `200`, aracın tamamı (araç listesindeki tek kayıtla aynı biçim).

## Profil ekleme ve düzenleme

`POST /vehicles/{vehicleId}/driving-profiles` (yeni, backend kimlik üretir, `isStandard: false`) ve
`PUT /vehicles/{vehicleId}/driving-profiles/{profileId}` (düzenleme). Kimlik yoldadır, gövdede değil.

```json
{
  "name": "Şehir",
  "consumptionKwhPer100Km": 15.2,
  "maxSpeedKmh": 90
}
```

| Alan | Tip | Kural | Hata |
|---|---|---|---|
| `name` | string | Kırpılmış, 1…40 karakter | `invalid_value` (`field: "name"`) |
| `name` | | Aynı aracın diğer profilleriyle büyük/küçük harf duyarsız benzersiz (Türkçe `I/ı`, `İ/i` aynı sayılır) | `duplicate_profile_name` |
| `name` | | Standart profilin adı değiştirilemez (`PUT`'ta aynı ad gönderilir) | `invalid_value` (`field: "name"`) |
| `consumptionKwhPer100Km` | number | Bir ondalığa yuvarlanır; 5.0…50.0 | `invalid_value` |
| `maxSpeedKmh` | integer | 50…250 | `invalid_value` |

Yanıt: `201` (ekleme) / `200` (düzenleme), aracın tamamı.

## Profil silme: `DELETE /vehicles/{vehicleId}/driving-profiles/{profileId}`

- Standart profil silinemez → `409 cannot_delete_standard_profile`.
- Silinen profil etkinse **standart profil** etkin olur.

Yanıt: `200`, aracın tamamı.

## Araç silme: `DELETE /vehicles/{vehicleId}`

Yanıt: `204`. Silinen araç varsayılansa **kalan araçlardan en son eklenen** (en yeni oluşturma zamanı)
varsayılan olur. Kural backend'dedir; istemci karar vermez, kartı yeniden yükleyip `isDefault`'u okur.
Kalan araç yoksa varsayılan da yoktur.

## Hata kodları

| `code` | HTTP | İstemcideki karşılık (`VehicleRepositoryError`) |
|---|---|---|
| `vehicle_not_found` | 404 | `vehicleNotFound` |
| `variant_not_found` | 404 | `variantNotFound` |
| `profile_not_found` | 404 | `profileNotFound` |
| `invalid_value` | 422 | `invalidValue(field)`; `field`: `name`, `consumptionKwhPer100Km`, `maxSpeedKmh`, `batteryHealthPercent`, `colorHex`, `isDefault` |
| `duplicate_profile_name` | 409 | `duplicateProfileName` |
| `cannot_delete_standard_profile` | 409 | `cannotDeleteStandardProfile` |
| `at_least_one_connector_required` | 422 | `atLeastOneConnectorRequired` |

## Kaldırılan alanlar

`consumptionWhPerKm` (yerine `drivingProfiles[].consumptionKwhPer100Km`) ve `rangeKm` (menzil istemcide
hesaplanır). Backend bu alanları göndermemelidir; gönderirse istemci yok sayar.
