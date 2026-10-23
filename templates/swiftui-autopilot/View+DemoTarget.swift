#if DEBUG
import SwiftUI

extension View {

    /// Lets the demo autopilot find this control and press it with `action`, the one the
    /// control runs on a tap. `isEnabled` holds the press until the control is ready, for
    /// example until a page has loaded. `anchor` is where in the control the press lands,
    /// the right end of a slider for its highest value. A `nil` target marks nothing, so
    /// one item of a list can be picked: `.demoTarget(tag == "Home" ? .location : nil)`.
    @ViewBuilder
    func demoTarget(_ target: DemoTarget?, isEnabled: Bool = true, anchor: UnitPoint = .center, action: @escaping () -> Void) -> some View {
        if let target {
            modifier(DemoTargetModifier(target: target, isEnabled: isEnabled, anchor: anchor, action: action))
        } else {
            self
        }
    }

    /// For a control the system draws, such as a tab bar item: `locate` finds its frame in
    /// screen points when the press comes, `action` does what a tap on it does.
    func demoTarget(_ target: DemoTarget, locate: @escaping () -> CGRect?, anchor: UnitPoint = .center, action: @escaping () -> Void) -> some View {
        modifier(DemoTargetModifier(target: target, isEnabled: true, anchor: anchor, locate: locate, action: action))
    }
}
#endif
