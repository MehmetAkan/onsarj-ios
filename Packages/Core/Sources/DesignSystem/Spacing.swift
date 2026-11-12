import CoreGraphics

/// Boşluk ölçeği.
///
/// Tüm değerler **4 noktalık ızgaraya** oturur. Izgara dışı bir boşluk (13, 18, 22 gibi)
/// yazmak ekranlar arasında hizalama bozukluğu yaratır; gözle fark edilmez ama
/// bir araya geldiğinde tasarımı özensiz gösterir.
///
/// Boşluklar yazı boyutuyla birlikte **ölçeklenmez.** Metin `xxxLarge` ayarında
/// büyürken boşlukların sabit kalması, ekranın dikeyde taşmasını sınırlar.
/// Bir bileşen gerçekten ölçeklenen boşluğa ihtiyaç duyarsa `@ScaledMetric` kullanılır,
/// ama bu istisnadır.
public enum Spacing {

    // MARK: - Ölçek

    /// 4pt — simge ile etiket arası gibi en dar aralıklar.
    public static let xs: CGFloat = 4

    /// 8pt — ilişkili öğeler arası, kart içi sıkı gruplar.
    public static let sm: CGFloat = 8

    /// 12pt — form alanı iç boşluğu, liste satırı dikey boşluğu.
    public static let md: CGFloat = 12

    /// 16pt — varsayılan boşluk. Kart iç boşluğu, öğeler arası standart aralık.
    public static let lg: CGFloat = 16

    /// 24pt — bölümler arası ayrım.
    public static let xl: CGFloat = 24

    /// 32pt — büyük bölüm ayrımı, başlık ile içerik arası.
    public static let xxl: CGFloat = 32

    /// 48pt — ekran üstü/altı geniş nefes alanı.
    public static let xxxl: CGFloat = 48

    // MARK: - Yerleşim sabitleri

    /// 20pt — ekranın sol ve sağ kenar boşluğu.
    ///
    /// Tüm ekranlarda aynıdır. Ekranlar arası geçişte içeriğin yatayda
    /// kaymaması buna bağlıdır.
    public static let screenMargin: CGFloat = 20

    /// 44pt — dokunulabilir her öğenin en küçük boyutu.
    ///
    /// Apple'ın insan arayüzü kılavuzunun alt sınırı. Görsel olarak daha küçük
    /// bir simge kullanılabilir, ancak dokunma alanı bu değerin altına inmemelidir.
    /// Araç içinde, hareket halinde kullanılan bir uygulamada bu sınır daha da önemlidir.
    public static let minTapTarget: CGFloat = 44
}
