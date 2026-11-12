import SwiftUI

extension EnvironmentValues {
    /// `DetentSheet` şu an parmakla sürükleniyor mu?
    ///
    /// Sayfanın içerik bölgesi sürüklemeyi butonlarla eşzamanlı alır; parmak sayfayı
    /// sürükledikten sonra bir butonun üstünde kalkarsa buton da tetiklenirdi. Sayfanın
    /// içindeki butonlar bu değer `true` iken eylemlerini çalıştırmaz.
    ///
    /// Buton eylemi parmak kalkarken çağrılır; o anda ortam değeri son çizimdeki (`true`)
    /// değerdedir, sürüklemenin bitişi bir sonraki çizimde yansır.
    @Entry var isSheetDragInProgress = false
}
