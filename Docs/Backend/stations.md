# Şarj istasyonları (harita)

İstemci: `StationRepository` (Domain), `StationDTO` ve `StationMapper`
(`Packages/Services/Sources/StationService`). Fixture: `FixtureStationRepository` (yalnızca Debug).

Ana haritada istasyon pinleri ve kümeleri için kullanılır. İstemci yalnızca görünen bölgenin
istasyonlarını ister; kümelemeyi kendisi yapar (Mapbox kaynak düzeyinde kümeleme). Konnektör,
güç ve fiyat gibi detay alanları istasyon detayı ekranıyla birlikte eklenecek.

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

Ad ve koordinatlar örnektir, gerçeklik iddiası yoktur. Fixture'da `logoUrl` bir görsel adıdır
(`operator-togg`, `operator-zes`, `operator-esarj`, `operator-shell`); Debug kompozisyonu bunu yerel
`file://` adresine çevirir. Release'de depo boş liste döner.
