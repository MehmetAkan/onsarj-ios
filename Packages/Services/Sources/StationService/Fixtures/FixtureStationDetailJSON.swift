// Geçici veri (K-23, K-26): backend hazır olana kadar istasyon detayları bu dosyadan gelir; backend bağlanınca
// dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
//
// Adresler, saatler, soketler, fiyatlar, olanaklar ve puanlar ÖRNEKTİR; gerçek istasyonlarla ilgisi yoktur.
// Yalnızca detay alanları yazılır; özet alanları (ad, ağ, konum, müsaitlik) `FixtureStationJSON`'dan gelir ve
// birleştirilen nesne gerçek yanıtla aynı biçimdedir. Tarihler `anchor` anına göre yazılmıştır; depo onları
// şimdiye kaydırır ("5 saat önce" her açılışta aynı görünür). Müsait soket sayıları istasyonun özetteki
// müsaitliğiyle uyumludur.
#if DEBUG
enum FixtureStationDetailJSON {
    /// Tarihlerin yazıldığı an.
    static let anchor = "2026-11-17T09:00:00Z"

    static let details = """
        {
          "st_001": {
            "address": "Lara Caddesi No: 112, Muratpaşa/Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": { "alwaysOpen": true },
            "access": { "type": "public" },
            "lastSuccessfulChargeAt": "2026-11-17T04:00:00Z",
            "connectors": [ { "type": "ccs2", "maxPowerKw": 160, "total": 4, "available": 4 } ],
            "tariffs": [
              { "name": "Doğrudan ödeme", "paymentMethods": ["contactless", "card"], "pricePerKwh": "14.98",
                "pricePerMinute": null, "currency": "TRY" }
            ],
            "amenities": ["food"],
            "rating": null
          },
          "st_002": {
            "address": "Kaleiçi Katlı Otoparkı, Barbaros Mah., Muratpaşa/Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": {
              "alwaysOpen": false,
              "weekly": [
                { "day": "mon", "opens": "08:00", "closes": "22:00" },
                { "day": "tue", "opens": "08:00", "closes": "22:00" },
                { "day": "wed", "opens": "08:00", "closes": "22:00" },
                { "day": "thu", "opens": "08:00", "closes": "22:00" },
                { "day": "fri", "opens": "08:00", "closes": "23:30" },
                { "day": "sat", "opens": "09:00", "closes": "23:30" },
                { "day": "sun", "opens": "09:00", "closes": "20:00" }
              ]
            },
            "access": { "type": "restricted", "note": "Yalnızca otopark müşterilerine" },
            "lastSuccessfulChargeAt": "2026-11-16T21:15:00Z",
            "connectors": [
              { "type": "ccs2", "maxPowerKw": 60, "total": 2, "available": null },
              { "type": "type2", "maxPowerKw": 22, "total": 4, "available": null }
            ],
            "tariffs": [
              { "name": "ZES üyeliği", "paymentMethods": ["app", "rfid"], "pricePerKwh": "11.49",
                "pricePerMinute": null, "currency": "TRY" },
              { "name": "Doğrudan ödeme", "paymentMethods": ["contactless"], "pricePerKwh": "13.99",
                "pricePerMinute": "0.50", "currency": "TRY" }
            ],
            "amenities": ["cafe", "restroom", "wifi", "parking", "shopping", "unknownAmenity"],
            "rating": { "average": 4.6, "count": 23 }
          },
          "st_003": {
            "address": "Işıklar Caddesi No: 41, Muratpaşa/Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": {
              "alwaysOpen": false,
              "weekly": [
                { "day": "mon", "opens": "06:00", "closes": "02:00" },
                { "day": "tue", "opens": "06:00", "closes": "02:00" },
                { "day": "wed", "opens": "06:00", "closes": "02:00" },
                { "day": "thu", "opens": "06:00", "closes": "02:00" },
                { "day": "fri", "opens": "06:00", "closes": "02:00" },
                { "day": "sat", "opens": "06:00", "closes": "02:00" },
                { "day": "sun", "opens": "06:00", "closes": "02:00" }
              ]
            },
            "access": { "type": "public" },
            "lastSuccessfulChargeAt": null,
            "connectors": [
              { "type": "ccs2", "maxPowerKw": 120, "total": 2, "available": 0 },
              { "type": "chademo", "maxPowerKw": 50, "total": 1, "available": 0 },
              { "type": "type2", "maxPowerKw": 22, "total": 2, "available": 0 }
            ],
            "tariffs": [],
            "amenities": [],
            "rating": null
          },
          "st_004": {
            "address": "Fener Mahallesi, Tekelioğlu Caddesi No: 9, Muratpaşa/Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": {
              "alwaysOpen": false,
              "weekly": [
                { "day": "mon", "opens": "07:00", "closes": "23:00" },
                { "day": "tue", "opens": "07:00", "closes": "23:00" },
                { "day": "wed", "opens": "07:00", "closes": "23:00" },
                { "day": "thu", "opens": "07:00", "closes": "23:00" },
                { "day": "fri", "opens": "07:00", "closes": "23:00" },
                { "day": "sat", "opens": "07:00", "closes": "23:00" }
              ]
            },
            "access": { "type": "public" },
            "lastSuccessfulChargeAt": "2026-11-17T08:40:00Z",
            "connectors": [
              { "type": "ccs2", "maxPowerKw": 300, "total": 4, "available": 1 },
              { "type": "nacs", "maxPowerKw": 250, "total": 2, "available": 0 }
            ],
            "tariffs": [
              { "name": "Shell Recharge", "paymentMethods": ["contactless", "card", "app"], "pricePerKwh": "16.75",
                "pricePerMinute": "1.25", "currency": "TRY" }
            ],
            "amenities": ["cafe", "restroom", "shopping", "wifi"],
            "rating": { "average": 3.9, "count": 8 }
          },
          "st_012": {
            "address": "Ermenek Mahallesi, 2540. Sokak No: 3, Muratpaşa/Antalya",
            "timeZone": "Europe/Istanbul",
            "openingHours": { "alwaysOpen": true },
            "access": { "type": "restricted", "note": "Yalnızca site sakinlerine ve misafirlerine" },
            "lastSuccessfulChargeAt": null,
            "connectors": [ { "type": "type2", "maxPowerKw": 11, "total": 2, "available": null } ],
            "tariffs": [
              { "name": "Voltrun kartı", "paymentMethods": ["rfid"], "pricePerKwh": "8.90", "pricePerMinute": null,
                "currency": "TRY" }
            ],
            "amenities": ["playground", "parking"],
            "rating": { "average": 4.2, "count": 5 }
          }
        }
        """
}
#endif
