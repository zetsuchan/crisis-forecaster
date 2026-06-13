import SwiftUI

extension View {
    /// Liquid Glass card surface (iOS 26+ API). The deployment target is iOS 27,
    /// so Liquid Glass is always available — no `#available` gating needed.
    func glassCard(_ cornerRadius: CGFloat = 16) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}
