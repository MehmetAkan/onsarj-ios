// Geçici veri (K-23, K-26): backend hazır olana kadar istasyonlar bu dosyadan gelir; backend bağlanınca
// dosya silinir. JSON, K-23 ek notu gereği kaynak dosyası değil dizge sabitidir.
//
// Adlar, koordinatlar ve müsaitlikler ÖRNEKTİR; gerçek istasyonlarla ilgisi yoktur, gerçeklik iddiası
// taşımaz. Ağ kimlikleri şarj ağı kataloğuyla (`FixtureChargingNetworkCatalog`) aynıdır. `logoUrl` bir
// adres değil görsel adıdır; `FixtureStationRepository` onu yerel dosya adresine çevirir. Voltrun'un
// logosu yoktur: pinin şimşekli hali bu kayıtlarla görünür.
#if DEBUG
extension FixtureStationRepository {
    static let handwrittenJSON = """
        {
          "stations": [
            {
              "id": "st_001", "name": "Trugo Muratpaşa Lara Yolu", "availability": "available",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.8712, "longitude": 30.7452 }
            },
            {
              "id": "st_002", "name": "ZES Muratpaşa Kaleiçi Otopark", "availability": "unknown",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8849, "longitude": 30.7046 }
            },
            {
              "id": "st_003", "name": "Eşarj Muratpaşa Işıklar", "availability": "unavailable",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8889, "longitude": 30.7113 }
            },
            {
              "id": "st_004", "name": "Shell Recharge Muratpaşa Fener", "availability": "partial",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.8556, "longitude": 30.7612 }
            },
            {
              "id": "st_005", "name": "Trugo Muratpaşa Güzeloba", "availability": "partial",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.8637, "longitude": 30.7898 }
            },
            {
              "id": "st_006", "name": "ZES Muratpaşa Şirinyalı", "availability": "available",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8601, "longitude": 30.7381 }
            },
            {
              "id": "st_007", "name": "Eşarj Muratpaşa Meltem", "availability": "unknown",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8862, "longitude": 30.6735 }
            },
            {
              "id": "st_008", "name": "Shell Recharge Muratpaşa Memerli", "availability": "unavailable",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.8778, "longitude": 30.728 }
            },
            {
              "id": "st_009", "name": "Trugo Muratpaşa Gebizli", "availability": "unavailable",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.8935, "longitude": 30.7344 }
            },
            {
              "id": "st_010", "name": "ZES Muratpaşa Yeşilbahçe", "availability": "partial",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8817, "longitude": 30.7189 }
            },
            {
              "id": "st_011", "name": "Eşarj Muratpaşa Kızılarık", "availability": "available",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8999, "longitude": 30.752 }
            },
            {
              "id": "st_012", "name": "Voltrun Muratpaşa Ermenek", "availability": "unknown",
              "network": { "id": "net_voltrun", "name": "Voltrun", "logoUrl": null },
              "coordinate": { "latitude": 36.9035, "longitude": 30.7183 }
            },
            {
              "id": "st_013", "name": "Trugo Muratpaşa Lara Plajı", "availability": "unknown",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.854, "longitude": 30.812 }
            },
            {
              "id": "st_014", "name": "ZES Muratpaşa Çağlayan", "availability": "unavailable",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.851, "longitude": 30.7795 }
            },
            {
              "id": "st_015", "name": "Shell Recharge Kepez Varsak", "availability": "partial",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.981, "longitude": 30.7287 }
            },
            {
              "id": "st_016", "name": "Trugo Kepez Altınova", "availability": "available",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.944, "longitude": 30.806 }
            },
            {
              "id": "st_017", "name": "ZES Kepez Gazi Bulvarı", "availability": "available",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.9338, "longitude": 30.7172 }
            },
            {
              "id": "st_018", "name": "Eşarj Kepez Göksu", "availability": "unknown",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.9273, "longitude": 30.6795 }
            },
            {
              "id": "st_019", "name": "Shell Recharge Kepez Erenköy", "availability": "unavailable",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.9152, "longitude": 30.7015 }
            },
            {
              "id": "st_020", "name": "Trugo Kepez Sanayi", "availability": "partial",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.9221, "longitude": 30.7389 }
            },
            {
              "id": "st_021", "name": "ZES Kepez Habibler", "availability": "partial",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.9681, "longitude": 30.6988 }
            },
            {
              "id": "st_022", "name": "Eşarj Kepez Kültür", "availability": "available",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.9395, "longitude": 30.6914 }
            },
            {
              "id": "st_023", "name": "Voltrun Kepez Fabrikalar", "availability": "unknown",
              "network": { "id": "net_voltrun", "name": "Voltrun", "logoUrl": null },
              "coordinate": { "latitude": 36.9122, "longitude": 30.6847 }
            },
            {
              "id": "st_024", "name": "Shell Recharge Kepez Duraliler", "availability": "unavailable",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.9535, "longitude": 30.7432 }
            },
            {
              "id": "st_025", "name": "Trugo Kepez Düden Şelalesi", "availability": "unavailable",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.959, "longitude": 30.73 }
            },
            {
              "id": "st_026", "name": "ZES Konyaaltı Sahil", "availability": "partial",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8636, "longitude": 30.6371 }
            },
            {
              "id": "st_027", "name": "Eşarj Konyaaltı Liman", "availability": "available",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8355, "longitude": 30.6087 }
            },
            {
              "id": "st_028", "name": "Trugo Konyaaltı Hurma", "availability": "unknown",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.8487, "longitude": 30.6061 }
            },
            {
              "id": "st_029", "name": "Shell Recharge Konyaaltı Sarısu", "availability": "unknown",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.8384, "longitude": 30.5948 }
            },
            {
              "id": "st_030", "name": "ZES Konyaaltı Uncalı", "availability": "unavailable",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8826, "longitude": 30.6261 }
            },
            {
              "id": "st_031", "name": "Eşarj Konyaaltı Arapsuyu", "availability": "partial",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8676, "longitude": 30.6378 }
            },
            {
              "id": "st_032", "name": "Trugo Konyaaltı Altınkum", "availability": "available",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.8786, "longitude": 30.6522 }
            },
            {
              "id": "st_033", "name": "Shell Recharge Konyaaltı Hurma Kavşağı", "availability": "available",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.854, "longitude": 30.6189 }
            },
            {
              "id": "st_034", "name": "ZES Konyaaltı Gürsu", "availability": "unknown",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.873, "longitude": 30.661 }
            },
            {
              "id": "st_035", "name": "Eşarj Konyaaltı Akdeniz Üniversitesi", "availability": "unavailable",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.8968, "longitude": 30.6503 }
            },
            {
              "id": "st_036", "name": "Trugo Konyaaltı Çakırlar", "availability": "partial",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 36.902, "longitude": 30.5605 }
            },
            {
              "id": "st_037", "name": "Shell Recharge Havalimanı Dış Hatlar", "availability": "partial",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 36.9076, "longitude": 30.8016 }
            },
            {
              "id": "st_038", "name": "ZES Aksu Kundu", "availability": "available",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 36.8662, "longitude": 30.8668 }
            },
            {
              "id": "st_039", "name": "Eşarj Aksu Pınarlı", "availability": "unknown",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 36.9367, "longitude": 30.8378 }
            },
            {
              "id": "st_040", "name": "Trugo Döşemealtı Yağca", "availability": "unavailable",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 37.0245, "longitude": 30.607 }
            },
            {
              "id": "st_041", "name": "ZES İstanbul Kadıköy Rıhtım", "availability": "unavailable",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 40.9918, "longitude": 29.0234 }
            },
            {
              "id": "st_042", "name": "Trugo İstanbul Levent", "availability": "partial",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 41.0812, "longitude": 29.0108 }
            },
            {
              "id": "st_043", "name": "Shell Recharge İstanbul Ataşehir", "availability": "available",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 40.9923, "longitude": 29.1244 }
            },
            {
              "id": "st_044", "name": "Eşarj İstanbul Bakırköy Sahil", "availability": "unknown",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 40.9762, "longitude": 28.8708 }
            },
            {
              "id": "st_045", "name": "Voltrun İstanbul Maslak", "availability": "unknown",
              "network": { "id": "net_voltrun", "name": "Voltrun", "logoUrl": null },
              "coordinate": { "latitude": 41.1086, "longitude": 29.0201 }
            },
            {
              "id": "st_046", "name": "Trugo Ankara Çankaya Kızılay", "availability": "unavailable",
              "network": { "id": "net_trugo", "name": "Trugo", "logoUrl": "operator-togg" },
              "coordinate": { "latitude": 39.9208, "longitude": 32.8541 }
            },
            {
              "id": "st_047", "name": "ZES Ankara Çukurambar", "availability": "partial",
              "network": { "id": "net_zes", "name": "ZES", "logoUrl": "operator-zes" },
              "coordinate": { "latitude": 39.9037, "longitude": 32.8102 }
            },
            {
              "id": "st_048", "name": "Eşarj Ankara Ümitköy", "availability": "available",
              "network": { "id": "net_esarj", "name": "Eşarj", "logoUrl": "operator-esarj" },
              "coordinate": { "latitude": 39.8946, "longitude": 32.7086 }
            },
            {
              "id": "st_049", "name": "Shell Recharge Ankara Eskişehir Yolu", "availability": "available",
              "network": { "id": "net_shell", "name": "Shell Recharge", "logoUrl": "operator-shell" },
              "coordinate": { "latitude": 39.9093, "longitude": 32.7608 }
            }
          ]
        }
        """
}
#endif
