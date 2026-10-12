import AuthFeature
import DesignSystem
import SwiftUI

/// Uygulamanın kök görünümü.
///
/// Şu an yalnızca karşılama ekranını gösterir. Ekranlar arası geçiş `AppRouter`
/// ile kurulacak; o gelene kadar karşılama ekranının kapanışları boştur.
struct RootView: View {
    var body: some View {
        WelcomeView(
            onContinue: {},
            onLogin: {}
        )
        .onsarjDynamicTypeRange()
    }
}