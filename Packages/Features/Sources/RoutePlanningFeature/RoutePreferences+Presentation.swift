import DesignSystem
import OnsarjDomain
import SwiftUI

extension ChargeStopStrategy {
    var titleKey: LocalizedStringKey {
        switch self {
        case .optimal: "plan.chargeStops.optimal"
        case .fewer: "plan.chargeStops.fewer"
        case .fewest: "plan.chargeStops.fewest"
        }
    }
}

extension RouteAvoidance {
    var titleKey: LocalizedStringKey {
        switch self {
        case .tolls: "plan.avoid.tolls"
        case .highways: "plan.avoid.highways"
        case .ferries: "plan.avoid.ferries"
        case .borders: "plan.avoid.borders"
        }
    }

    var icon: AppIcon {
        switch self {
        case .tolls: .avoidTolls
        case .highways: .avoidHighways
        case .ferries: .avoidFerries
        case .borders: .avoidBorders
        }
    }
}

extension NetworkPickerMode {
    var titleKey: LocalizedStringKey {
        switch self {
        case .prefer: "networks.addPreferred"
        case .avoid: "networks.addAvoided"
        }
    }
}

/// Biçim anahtarlı metinler (`"%@ kaldır"` gibi).
enum PlanText {
    /// Biçimi tek `%@` ile doldurur.
    static func format(_ format: String, _ argument: String) -> String {
        String.localizedStringWithFormat(format, argument)
    }
}
