#if DEBUG
import SwiftUI

/// Tells the demo autopilot where a control is and whether it can be pressed, and runs
/// the control's action when the autopilot presses it.
struct DemoTargetModifier: ViewModifier {
    let target: DemoTarget
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if let demo = DemoAutopilot.shared {
            content
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    demo.place(target, at: frame)
                }
                .onChange(of: isEnabled, initial: true) { _, isEnabled in
                    demo.setEnabled(target, isEnabled)
                }
                .onChange(of: demo.pressing) { _, pressing in
                    guard pressing == target else { return }
                    demo.didPress(target)
                    action()
                }
                .onDisappear { demo.remove(target) }
        } else {
            content
        }
    }
}
#endif
