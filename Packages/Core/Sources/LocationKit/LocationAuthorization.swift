import CoreLocation

/// Uygulamanın konum izni durumu.
///
/// Sistemin beş durumu, ekranların ayırt etmesi gereken üç duruma indirilir. "Her zaman"
/// izni istenmez (CLAUDE.md bölüm 7); kullanıcı Ayarlar'dan kendisi verirse `authorized`
/// sayılır.
public enum LocationAuthorization: Sendable, Equatable {
    /// Henüz sorulmadı. İzin istenebilir.
    case notDetermined
    /// Kullanıcı reddetti ya da cihaz kısıtlıyor (ebeveyn denetimi, kurum yönetimi).
    /// Yeniden sorulamaz; yalnızca Ayarlar'dan açılabilir.
    case denied
    /// Uygulama kullanılırken konuma erişilebilir.
    case authorized

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            self = .authorized
        case .denied, .restricted:
            self = .denied
        @unknown default:
            self = .denied
        }
    }
}
