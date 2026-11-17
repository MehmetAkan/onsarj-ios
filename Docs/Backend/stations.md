# Şarj istasyonları (harita ve detay)

İstemci: `StationRepository` (Domain), `StationDTO` ve `StationMapper`
(`Packages/Services/Sources/StationService`). Fixture: `FixtureStationRepository` (yalnızca Debug).

Ana haritada istasyon pinleri ve kümeleri için liste (`GET /stations`), pine dokununca açılan detay sayfası
için detay (`GET /stations/{id}`) kullanılır. İstemci yalnızca görünen bölgenin istasyonlarını ister;
kümelemeyi kendisi yapar (Mapbox kaynak düzeyinde kümeleme).

## Uç nokta (öneri)

| Yöntem | Yol | Sorgu | Yanıt |
|---|---|---|---|
| `GET` | `/stations` | `bbox=minLon,minLat,maxLon,maxLat` | `200` Kutudaki istasyonlar |

- `bbox` derece cinsindendir (WGS 84), sıra GeoJSON'daki gibidir: batı, güney, doğu, kuzey.
  Örnek: `GET /stations?bbox=30.62,36.82,30.78,36.98`.
- 180. boylamı geçen kutu gönderilmez.
- **Süzme yoktur:** kutudaki tüm istasyonlar döner (araç konnektörüne göre süzme yapılmaz; proje
  sahibinin kararı).
- İstemci kamera durduktan ≈300 ms sonra, görünen bölgenin 1,5 katı genişliğinde bir kutu ister ve
  önceki isteği iptal eder. Görünen bölge 3 boylam derecesinden genişse (ülke ölçeği) istek atmaz.
  Bu yüzden bir yanıtta en fazla ~4,5° × ~4,5°'lik bir bölgenin istasyonları istenir.

## Yanıt

```json
{
  "stations": [
    {
      "id": "st_001",
      "name": "Trugo Muratpaşa Lara Yolu",
      "availability": "available",
      "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "https://cdn.example.com/networks/trugo.png" },
      "coordinate": { "latitude": 36.8712, "longitude": 30.7452 }
    }
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| `stations` | Station[] | evet | Kutudaki istasyonlar | boş olabilir |
| `stations[].id` | string | evet | İstasyon kimliği | boş olamaz |
| `stations[].name` | string | evet | Gösterilen ad | boş olamaz (kırpıldıktan sonra) |
| `stations[].availability` | string | evet | Anlık müsaitlik; aşağıdaki tablo | tanınmayan değer `unknown` sayılır |
| `stations[].network` | Network | evet | İstasyonu işleten şarj ağı | [charging-networks.md](charging-networks.md) ile aynı biçim |
| `stations[].network.id` | string | evet | Ağ kimliği; şarj ağı kataloğundaki kimlikle **aynıdır** (`net_trugo`, `net_zes`…) | boş olamaz |
| `stations[].network.name` | string | evet | Ağ adı | boş olamaz |
| `stations[].network.logoUrl` | string \| null | hayır | Ağ logosu, `https` | geçersizse logo yok sayılır (pinde şimşek) |
| `stations[].coordinate.latitude` | number | evet | Enlem, derece | -90…90 |
| `stations[].coordinate.longitude` | number | evet | Boylam, derece | -180…180 |

Tek bir kaydın zorunlu alanı eksikse veya koordinatı aralık dışındaysa istemci tüm yanıtı geçersiz
sayar ve haritada o bölgenin istasyonlarını göstermez (kullanıcıya hata gösterilmez).

Ağ kimliklerinin katalogla aynı olması, plan seçeneklerindeki tercih ve kaçınılan ağların ileride
istasyonlarla eşleşmesini sağlar.

## Detay: `GET /stations/{id}`

Yanıt, listedeki istasyon nesnesinin **bütün alanlarını** ve detay alanlarını aynı nesnede taşır. İstasyon
yoksa `404` (`station_not_found`).

```json
{
  "id": "st_001",
  "name": "Trugo Muratpaşa Lara Yolu",
  "availability": "available",
  "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "https://cdn.example.com/networks/trugo.png" },
  "coordinate": { "latitude": 36.8712, "longitude": 30.7452 },
  "address": "Lara Caddesi No: 112, Muratpaşa/Antalya",
  "timeZone": "Europe/Istanbul",
  "openingHours": {
    "alwaysOpen": false,
    "weekly": [
      { "day": "mon", "opens": "08:00", "closes": "22:00" },
      { "day": "fri", "opens": "18:00", "closes": "02:00" }
    ]
  },
  "access": { "type": "restricted", "note": "Yalnızca otopark müşterilerine" },
  "lastSuccessfulChargeAt": "2026-11-17T04:00:00Z",
  "connectors": [
    { "type": "ccs2", "maxPowerKw": 160, "total": 4, "available": 4 },
    { "type": "type2", "maxPowerKw": 22, "total": 2, "available": null }
  ],
  "tariffs": [
    { "name": "Doğrudan ödeme", "paymentMethods": ["contactless", "card"], "pricePerKwh": "14.98",
      "pricePerMinute": null, "currency": "TRY" }
  ],
  "amenities": ["food", "restroom"],
  "rating": { "average": 4.6, "count": 23 }
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| (liste alanları) | | evet | `id`, `name`, `availability`, `network`, `coordinate` | yukarıdaki tablo |
| `address` | string | evet | Açık adres; kullanıcı kopyalayabilir | boş olamaz |
| `timeZone` | string | evet | İstasyonun **IANA** saat dilimi (`Europe/Istanbul`) | geçerli IANA adı; saatler bu dilimdedir |
| `openingHours.alwaysOpen` | bool | evet | 24 saat açık | `true` ise `weekly` gönderilmez |
| `openingHours.weekly[]` | Interval[] | `alwaysOpen` `false` ise | Haftalık açık aralıklar | listede olmayan gün kapalıdır; bir günde birden çok aralık olabilir |
| `weekly[].day` | string | evet | `mon \| tue \| wed \| thu \| fri \| sat \| sun` | |
| `weekly[].opens`, `closes` | string | evet | `"HH:mm"`, istasyonun yerel saati | `closes` ≤ `opens` ise aralık gece yarısını geçer (`18:00`–`02:00`); `"24:00"` günün sonudur |
| `access.type` | string | evet | `public` (tüm EV'lere açık) \| `restricted` | |
| `access.note` | string | `restricted` ise | Kısıtlamanın açıklaması, kullanıcıya gösterilir | boş olamaz |
| `lastSuccessfulChargeAt` | string \| null | hayır | Son başarılı şarj, ISO 8601 UTC | bilinmiyorsa `null`; satır gizlenir |
| `connectors[]` | Group[] | evet | Aynı tür ve güçteki soket grupları | boş olabilir |
| `connectors[].type` | string | evet | `type1 \| type2 \| ccs1 \| ccs2 \| chademo \| nacs` | tanınmayan türdeki grup atlanır |
| `connectors[].maxPowerKw` | number | evet | Soket başına en yüksek güç | > 0 |
| `connectors[].total` | int | evet | Soket sayısı | > 0 |
| `connectors[].available` | int \| null | evet | Boş soket sayısı | 0…`total`; canlı veri yoksa `null` |
| `tariffs[]` | Tariff[] | hayır | Fiyat seçenekleri | yoksa "Fiyat bilgisi yok" |
| `tariffs[].name` | string | evet | Tarife adı | boş olamaz |
| `tariffs[].paymentMethods` | string[] | hayır | `contactless \| card \| app \| rfid` | tanınmayan değer atlanır |
| `tariffs[].pricePerKwh` | string \| null | hayır | kWh fiyatı, **dizge** | aşağıya bakın |
| `tariffs[].pricePerMinute` | string \| null | hayır | Dakika ücreti, **dizge** | aşağıya bakın |
| `tariffs[].currency` | string | evet | ISO 4217 kodu (`TRY`) | 3 harf |
| `amenities` | string[] | hayır | `food \| cafe \| restroom \| wifi \| shopping \| parking \| hotel \| playground` | tanınmayan değer atlanır |
| `rating` | Rating \| null | hayır | `average` (1–5) ve `count` (> 0) | değerlendirme yoksa `null` |

**Para değerleri dizgedir:** `"14.98"`, sayı (`14.98`) değil. İstemci değeri kayan noktaya çevirmeden
`Decimal` olarak, kayıpsız çözer. Biçim: rakamlar, isteğe bağlı nokta ve ondalık rakamlar (`^\d+(\.\d+)?$`);
virgül, işaret ve üs kabul edilmez. Geçersiz fiyat tüm yanıtı geçersiz kılar (yanlış fiyat göstermektense hiç
göstermemek). Gösterim para birimi ve kullanıcının yerel ayarıyla yapılır (`₺14,98/kWh`).

**Kurallar:**
- **Müsaitlik** (gruplar ve istasyon toplamı) pinlerdeki kuralla aynıdır: hepsi boş → `available`, en az biri
  boş → `partial`, hiçbiri → `unavailable`, canlı veri yok (`available: null`) → `unknown`. Bir grubun bile
  canlı verisi yoksa istasyon toplamı bilinmiyor sayılır. Detaydaki müsaitlik listedeki `availability` ile
  tutarlı olmalıdır.
- **Hız sınıfı** soketin en yüksek gücünden istemcide hesaplanır: `< 50 kW` normal (1 şimşek),
  `50–149 kW` hızlı (2), `≥ 150 kW` çok hızlı (3). İstasyonun sınıfı gruplardaki en yüksek güçtür.
- **"Şu an açık mı"** istemcide, `timeZone` ve cihaz saatiyle hesaplanır; backend durum alanı göndermez.

## Müsaitlik değerleri

| Değer | Anlamı | Pindeki renk |
|---|---|---|
| `available` | Tüm soketler boş | yeşil |
| `partial` | En az bir soket dolu, en az biri boş | turuncu |
| `unavailable` | Tüm soketler dolu veya arızalı | kırmızı |
| `unknown` | Canlı veri yok | gri |

Yeni değer eklenebilir; istemci tanımadığı değeri `unknown` gösterir.

## Fixture

Debug'daki fixture iki senaryo içerir; başlatma argümanıyla seçilir (`-onsarjStationScenario`):

- `default`: elle yazılmış 49 istasyon — Antalya'da 40 (Muratpaşa, Kepez, Konyaaltı, havalimanı,
  Aksu, Döşemealtı), İstanbul'da 5, Ankara'da 4. Ağlar: Trugo, ZES, Eşarj, Shell Recharge ve logosuz
  Voltrun. Dört müsaitlik hali karışık.
- `dense`: Antalya çevresinde sabit tohumla üretilen 1000 istasyon (kümeleme ve performans sınaması).

Detay: elle yazılmış beş istasyonun (`st_001`–`st_004`, `st_012`) zengin detayı var (24 saat / saatli /
gece yarısını geçen saatler, kısıtlı erişim, birden çok soket türü ve tarife, olanaklı/olanaksız, puanlı/
puansız, son şarjlı/son şarjsız). Diğer tüm istasyonların (`dense` dahil) detayı istasyon kimliğinden türetilen
sabit tohumla üretilir. Fixture tarihleri her açılışta şimdiye kaydırılır.

Ad ve koordinatlar örnektir, gerçeklik iddiası yoktur. Fixture'da `logoUrl` bir görsel adıdır
(`operator-togg`, `operator-zes`, `operator-esarj`, `operator-shell`); Debug kompozisyonu bunu yerel
`file://` adresine çevirir. Release'de depo boş liste döner.
