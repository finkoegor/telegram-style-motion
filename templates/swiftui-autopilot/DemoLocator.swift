#if DEBUG
import UIKit

/// Finds controls the system draws itself, which SwiftUI can't measure, in screen points.
enum DemoLocator {

    /// The tab bar button at `index`, counted from the left. The buttons carry no labels of
    /// their own, so they are told apart by place; the bar draws each one twice, plain and
    /// selected, at the same spot.
    static func frameOfTab(at index: Int) -> CGRect? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard let bar = windows.lazy.compactMap({ first(UITabBar.self, in: $0) }).first else { return nil }
        let buttons = descendants(of: bar)
            .filter { String(describing: type(of: $0)) == "_UITabButton" && !$0.isHidden }
            .map { $0.convert($0.bounds, to: nil) }
            .reduce(into: [CGRect]()) { frames, frame in
                if !frames.contains(where: { abs($0.minX - frame.minX) < 1 }) { frames.append(frame) }
            }
            .sorted { $0.minX < $1.minX }
        return buttons.indices.contains(index) ? buttons[index] : nil
    }

    private static func first<View: UIView>(_ type: View.Type, in view: UIView) -> View? {
        if let match = view as? View { return match }
        for subview in view.subviews {
            if let match = first(type, in: subview) { return match }
        }
        return nil
    }

    private static func descendants(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(descendants(of:))
    }
}
#endif
