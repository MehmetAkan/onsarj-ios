import CoreLocation

/// Kullanıcının konumu ve konum izni.
///
/// Ekranlar bu protokolü bilir; somut uygulama (`DeviceLocationSource`) yalnızca uygulama
/// katmanında bağlanır (CLAUDE.md 5.3 kural 2).
///
/// İzin **yalnızca** `requestAuthorization()` ile istenir. Akışlara abone olmak izin
/// penceresini açmaz; izin yokken konum akışı sessizce bekler ve izin verilince başlar.
@MainActor
public protocol LocationSource: AnyObject {
    /// Şu anki izin durumu.
    var authorization: LocationAuthorization { get }

    /// "Uygulamayı kullanırken" iznini ister. Durum `notDetermined` değilse hiçbir şey yapmaz.
    func requestAuthorization()

    /// İzin durumundaki değişiklikler. Akış şu anki durumla başlar.
    func authorizationUpdates() -> AsyncStream<LocationAuthorization>

    /// Kullanıcının konumu. Konum güncellemeleri en az bir abone varken ve izin verilmişken
    /// çalışır; son abone ayrılınca durur.
    func locationUpdates() -> AsyncStream<CLLocation>
}
