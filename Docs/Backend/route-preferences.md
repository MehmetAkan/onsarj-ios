# Rota planlama tercihleri

İstemci: `RoutePreferencesStoring` (Domain), `UserDefaultsRoutePreferencesStore`
(`Packages/Services/Sources/RoutePlanningService`).

**Durum:** Tercihler şimdilik **cihazda** (`UserDefaults`, anahtar `onsarj.routePreferences`) saklanır.
Tercihler kullanıcıya aittir (araca değil). Backend'e taşındığında aşağıdaki biçim önerilir; cihazdaki
kayıt biçimi de bununla aynıdır, böylece taşıma bir kerelik yüklemeyle yapılabilir.

## Uç noktalar (öneri)

| Yöntem | Yol | Gövde | Yanıt |
|---|---|---|---|
| `GET` | `/me/route-preferences` | — | `200` Tercihler (kayıt yoksa varsayılanlar) |
| `PUT` | `/me/route-preferences` | Tercihler | `200` Tercihler |

İstemcide kaydet düğmesi yoktur; her değişiklik hemen gönderilir. `PUT` tercihlerin tamamını değiştirir.

## Biçim

```json
{
  "chargeStops": "fewer",
  "avoid": ["tolls", "ferries"],
  "preferredNetworks": ["net_zes", "net_trugo"],
  "avoidedNetworks": ["net_totalenergies"]
}
```

| Alan | Tip | Zorunlu | Açıklama | Geçerli değerler |
|---|---|---|---|---|
| `chargeStops` | string | evet | Şarj durağı sıklığı. Varsayılan `optimal`; tanınmayan değer istemcide `optimal` | `optimal`, `fewer`, `fewest` |
| `avoid` | string[] | evet | Kaçınılan yol türleri; sırasızdır. Tanınmayan değer istemcide atlanır | `tolls`, `highways`, `ferries`, `borders` |
| `preferredNetworks` | string[] | evet | Tercih edilen şarj ağlarının kimlikleri (`charging-networks.md`), **ekleme sırasıyla** | |
| `avoidedNetworks` | string[] | evet | Kaçınılan şarj ağlarının kimlikleri, ekleme sırasıyla | |

## Doğrulama kuralları

- Bir ağ aynı anda hem `preferredNetworks` hem `avoidedNetworks` içinde olamaz.
- Bir listede aynı kimlik iki kez bulunamaz.
- İstemci okurken bu kuralları kendisi de uygular: tekrar edenlerden ilki kalır; iki listede geçen ağ
  yalnızca tercih edilenlerde kalır. Backend aynı kuralları uygulamalı veya `422 invalid_value` dönmelidir.
- Katalogda artık bulunmayan ağ kimliği listeden **silinmez**; istemci onu "Bilinmeyen ağ" olarak gösterir
  ve kullanıcı kaldırabilir.

## Kaldırılan alan: güçlü tercih

Önceden tercih edilen her ağ `{"id": "...", "isStrong": true}` nesnesiydi ("güçlü tercih", kalp).
Özellik kaldırıldı (Adım 38): `preferredNetworks` artık **düz kimlik listesidir**. İstemci eski biçimdeki
cihaz kayıtlarını okurken yalnızca `id`'yi alır. Backend `isStrong` alanını beklememeli ve göndermemelidir.
