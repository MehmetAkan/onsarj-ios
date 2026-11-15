# Şarj ağı kataloğu

İstemci: `ChargingNetworkCatalog` (Domain), `ChargingNetworkDTO` ve `ChargingNetworkMapper`
(`Packages/Services/Sources/StationService`). Fixture: `FixtureChargingNetworkCatalog` (yalnızca Debug).

Plan seçeneklerinde ağ seçici (arama) ve kayıtlı tercihlerdeki ağ adlarının çözülmesi için kullanılır.

## Uç noktalar (öneri)

| Yöntem | Yol | Sorgu | Yanıt |
|---|---|---|---|
| `GET` | `/charging-networks` | `query` (isteğe bağlı) | `200` Ağ listesi, ada göre sıralı |
| `GET` | `/charging-networks` | `ids=net_zes,net_trugo` | `200` Ağ listesi, **verilen sırayla** |

`query` ve `ids` birlikte gönderilmez.

## Yanıt

```json
{
  "networks": [
    { "id": "net_zes", "name": "ZES" },
    { "id": "net_trugo", "name": "Trugo" },
    { "id": "net_esarj", "name": "Eşarj" }
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama | Kural |
|---|---|---|---|---|
| `networks` | Network[] | evet | Ağlar | |
| `networks[].id` | string | evet | Ağ kimliği; tercihlerde saklanan değer | boş olamaz |
| `networks[].name` | string | evet | Gösterilen ad | boş olamaz (kırpıldıktan sonra) |

Tek bir kaydın kimliği veya adı eksikse istemci tüm yanıtı geçersiz sayar.

## Arama kuralları (`query`)

- **"İçerir" eşleşmesi:** ad sorguyu herhangi bir yerinde içerir ("charg" → "CHARGING TOGETHER SL",
  "Tesla Supercharger").
- **Büyük/küçük harf ve aksan duyarsız, Türkçe kurallarıyla:** `I/ı` ve `İ/i` aynı sayılır;
  `ş/s`, `ç/c`, `ğ/g`, `ö/o`, `ü/u` aynı sayılır. "ESARJ", "eşarj", "şarj" → "Eşarj"; "YAKIT", "yakıt" → "En Yakıt".
- Sorgu kırpılır; boş veya yalnızca boşluk sorgu **tüm listeyi** verir.
- Sonuç Türkçe alfabe sırasıyla ada göre sıralanır ("EDEKA" < "En Yakıt" < "Eşarj").
- İstemci yazımdan ≈300 ms sonra sorgular ve eski isteği iptal eder.

## Kimlikle getirme (`ids`)

- Sonuç **verilen kimlik sırasıyla** döner.
- Katalogda bulunmayan kimlik **atlanır** (hata değildir); istemci onu "Bilinmeyen ağ" olarak gösterir.

## Fixture

Debug'daki fixture 15 ağ içerir: ZES, Trugo, Eşarj, Voltrun, Sharz.net, Astor Şarj, Beefull,
Tesla Supercharger, En Yakıt, Otojet, Aksa Şarj, TotalEnergies, CHARGING TOGETHER SL, WCCC Edgbaston, EDEKA.
Release'de katalog boştur.
