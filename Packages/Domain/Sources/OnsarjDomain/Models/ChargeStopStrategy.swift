/// Rota planlamada şarj duraklarının sıklığı.
///
/// Planlama backend'de yapılır; istemci yalnızca tercihi taşır.
public enum ChargeStopStrategy: Sendable, Equatable, Hashable, CaseIterable {
    /// Toplam süreyi en aza indiren durak dağılımı. Varsayılan.
    case optimal
    /// Daha uzun şarjlarla daha az durak.
    case fewer
    /// Olabilecek en az durak.
    case fewest
}
