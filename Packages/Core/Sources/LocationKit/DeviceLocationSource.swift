import CoreLocation

/// Cihazın konumunu `CLLocationManager` üzerinden veren `LocationSource`.
///
/// Uygulama boyunca tek örnek kullanılır; birden çok ekran aynı örneğin akışlarına abone olur.
@MainActor
public final class DeviceLocationSource: NSObject, LocationSource {
    private let manager = CLLocationManager()
    private var authorizationContinuations: [UUID: AsyncStream<LocationAuthorization>.Continuation] = [:]
    private var locationContinuations: [UUID: AsyncStream<CLLocation>.Continuation] = [:]

    override public init() {
        super.init()
        // Yönetici ana iş parçacığında oluşturulur; temsilci çağrıları da oraya gelir.
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public var authorization: LocationAuthorization {
        LocationAuthorization(manager.authorizationStatus)
    }

    public func requestAuthorization() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    public func authorizationUpdates() -> AsyncStream<LocationAuthorization> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationAuthorization.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let id = UUID()
        authorizationContinuations[id] = continuation
        continuation.yield(authorization)
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.authorizationContinuations[id] = nil
            }
        }
        return stream
    }

    public func locationUpdates() -> AsyncStream<CLLocation> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: CLLocation.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let id = UUID()
        locationContinuations[id] = continuation
        if let location = manager.location, authorization == .authorized {
            continuation.yield(location)
        }
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.locationContinuations[id] = nil
                self?.updateLocationUpdates()
            }
        }
        updateLocationUpdates()
        return stream
    }

    /// Konum güncellemelerini abone ve izin durumuna göre başlatır ya da durdurur.
    ///
    /// İzin yokken `startUpdatingLocation()` çağrılmaz: o çağrı izin penceresini kendiliğinden
    /// açabilir ve izin, kullanıcı özelliği ilk kullandığında istenmelidir (CLAUDE.md bölüm 7).
    private func updateLocationUpdates() {
        if locationContinuations.isEmpty || authorization != .authorized {
            manager.stopUpdatingLocation()
        } else {
            manager.startUpdatingLocation()
        }
    }
}

extension DeviceLocationSource: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            let authorization = authorization
            for continuation in authorizationContinuations.values {
                continuation.yield(authorization)
            }
            updateLocationUpdates()
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        MainActor.assumeIsolated {
            for continuation in locationContinuations.values {
                continuation.yield(location)
            }
        }
    }
}
