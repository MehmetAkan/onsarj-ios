# Araç kataloğu

İstemci: `VehicleCatalog` (Domain), `VehicleBrandListDTO` / `VehicleModelListDTO` / `VehicleVariantListDTO` ve
`VehicleCatalogMapper` (`Packages/Services/Sources/VehicleService`). Fixture: `FixtureVehicleCatalog`
(yalnızca Debug). Release'de katalog boştur.

"Araç ekle" akışı marka → model → varyant ilerler; kullanıcı varyanta dokununca araç o varyanttan
oluşturulur (`vehicles.md` → `POST /vehicles`). İstemci yanıtları akış boyunca bellekte tutar.

## Uç noktalar (öneri)

| Yöntem | Yol | Yanıt |
|---|---|---|
| `GET` | `/vehicle-catalog/brands` | `200` Markalar, **ada göre sıralı** |
| `GET` | `/vehicle-catalog/brands/{brandId}/models` | `200` Markanın modelleri |
| `GET` | `/vehicle-catalog/models/{modelId}/variants` | `200` Modelin varyantları |

Marka araması **istemcide** yapılır (marka listesi küçüktür): Türkçe kurallarıyla büyük/küçük harf ve aksan
duyarsız "içerir" eşleşmesi (`charging-networks.md` → Arama kurallarıyla aynı). Backend'den arama uç noktası
beklenmez.

## Markalar

```json
{
  "brands": [
    { "id": "brand_byd", "name": "BYD", "logoUrl": null, "modelCount": 3 },
    { "id": "brand_togg", "name": "Togg", "logoUrl": null, "modelCount": 1 }
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| `id` | string | evet | Marka kimliği | |
| `name` | string | evet | Gösterilen ad | |
| `logoUrl` | string \| null | hayır | Logo; yoksa veya `https` değilse istemci genel araç simgesi gösterir | `https` |
| `modelCount` | integer | evet | Markanın model sayısı ("3 model") | `models` yanıtındaki kayıt sayısına **eşit** |

## Modeller

```json
{
  "models": [
    { "id": "model_byd_dolphin", "brandId": "brand_byd", "name": "Dolphin", "bodyType": "hatchback" }
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| `id` | string | evet | Model kimliği | |
| `brandId` | string | evet | Markası | yoldaki `brandId` |
| `name` | string | evet | Model adı | |
| `bodyType` | string \| null | hayır | Kasa tipi: `hatchback`, `sedan`, `suv`, `crossover`, `wagon`, `coupe`, `van`, `pickup`, `other`. Tanınmayan veya eksik değer istemcide `other` | |

## Varyantlar

```json
{
  "variants": [
    {
      "id": "variant_byd_dolphin_standard",
      "modelId": "model_byd_dolphin",
      "name": "Standart",
      "modelYear": 2023,
      "batteryCapacityKwh": 60.5,
      "connectors": ["type2", "ccs2"],
      "maxAcPowerKw": 11,
      "maxDcPowerKw": 88,
      "referenceConsumptionKwhPer100Km": 17.8,
      "imageUrl": null
    }
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| `id` | string | evet | Varyant kimliği; `POST /vehicles` gövdesindeki `variantId` | |
| `modelId` | string | evet | Modeli | yoldaki `modelId` |
| `name` | string | evet | Donanım paketi, "Comfort"; oluşan aracın `variant` alanı | |
| `modelYear` | integer | evet | Model yılı | |
| `batteryCapacityKwh` | number | evet | Kullanılabilir kapasite | > 0 |
| `connectors` | string[] | evet | `type1`, `type2`, `ccs1`, `ccs2`, `chademo`, `nacs`; tanınmayan değer atlanır | en az 1 |
| `maxAcPowerKw` | number \| null | hayır | En yüksek AC şarj gücü | |
| `maxDcPowerKw` | number \| null | hayır | En yüksek DC şarj gücü | |
| `referenceConsumptionKwhPer100Km` | number | evet | Oluşan aracın standart profilinin tüketimi | 5.0…50.0 |
| `imageUrl` | string \| null | hayır | Araç görseli (K-24); oluşan aracın `imageUrl` alanı | `https` |

Bir kaydın zorunlu alanı eksikse istemci tüm yanıtı geçersiz sayar ve "Katalog yüklenemedi" gösterir.

## Fixture

10 marka (BMW, BYD, Hyundai, Kia, Mercedes-Benz, MG, Renault, Tesla, Togg, Volkswagen), 20 model, 22 varyant.
**Değerler örnektir; teknik doğruluk iddiası yoktur.** Logolar ve görseller `null`. BYD Dolphin "Standart"
varyantı, mevcut fixture aracıyla aynı değerleri taşır.
