#if DEBUG
import SwiftUI

extension View {

    /// Lets the demo autopilot find this control and press it with `action`, the one the
    /// control runs on a tap. `isEnabled` holds the press until the control is ready,
    /// for example until a page has loaded.
    func demoTarget(_ target: DemoTarget, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        modifier(DemoTargetModifier(target: target, isEnabled: isEnabled, action: action))
    }
}
#endif
