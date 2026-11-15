import CoreGraphics

/// Haritanın üst kenarındaki buton sırası; Mapbox'ın kendi öğeleri bu sıraya göre yerleşir.
///
/// Ekran, harita üstüne koyduğu buton sırasını tarif eder; `MapView` Mapbox öğelerini onunla
/// çakışmayacak biçimde dizer:
/// - **Bilgi (attribution) butonu:** sağ üstte, sıranın içinde. Mapbox'ın butonu 44pt karedir;
///   sıra yüksekliği `Spacing.minTapTarget` olduğunda sol üstteki butonla tam aynı hizada durur.
/// - **Pusula:** bilgi butonunun altında. Yalnızca harita döndürülünce görünür.
/// - **Ölçek çubuğu:** sol üstteki butonun sağında. Yalnızca yakınlaştırırken görünür.
///
/// Mapbox logosu varsayılan yerinde (sol alt) kalır.
///
/// Tüm uzunluklar güvenli alana göredir.
public struct MapControlsLayout: Equatable, Sendable {
    /// Sıranın güvenli alanın üst kenarından uzaklığı.
    public var top: CGFloat
    /// Sıranın ekranın sol ve sağ kenarından uzaklığı.
    public var horizontalMargin: CGFloat
    /// Sıradaki butonların yüksekliği; sol üstteki butonun genişliği de budur.
    public var rowHeight: CGFloat
    /// Sıradaki buton ile ona komşu Mapbox öğesi arasındaki boşluk.
    public var spacing: CGFloat

    public init(top: CGFloat, horizontalMargin: CGFloat, rowHeight: CGFloat, spacing: CGFloat) {
        self.top = top
        self.horizontalMargin = horizontalMargin
        self.rowHeight = rowHeight
        self.spacing = spacing
    }
}
