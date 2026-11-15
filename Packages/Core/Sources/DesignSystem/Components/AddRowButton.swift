import SwiftUI

/// Kutu içindeki listenin altındaki "+ … ekle" satırı: artı simgesi ve ikincil renkte metin.
///
/// Arama sayfasındaki "Kayıtlı ekle" ile aynı dil; bağlantı mavisi değildir. Satırın tamamı
/// dokunulabilir ve en az `Spacing.minTapTarget` yüksekliğindedir.
public struct AddRowButton: View {
    private let title: Text
    private let action: () -> Void

    public init(_ title: Text, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                AppIcon.add
                title
            }
            .font(Typography.secondary)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTapTarget, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Kutu içindeki satırlar arasındaki ince ayırıcı; satır içeriğinin sol kenarından (`Spacing.lg`)
/// başlar.
public struct InsetDivider: View {
    public init() {}

    public var body: some View {
        Divider()
            .overlay(Theme.borderSubtle)
            .padding(.leading, Spacing.lg)
    }
}
