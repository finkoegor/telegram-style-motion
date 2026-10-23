#if DEBUG
import Foundation
import Observation
import QuartzCore
import SwiftUI

/// Plays a scripted run through the app for promo recordings. A debug build launched
/// with `-Demo` presses controls on a timer through their own actions, so the pacing
/// is exact and every animation is the real one, and writes where and when each press
/// landed to `demo-taps.json` in the app's temporary folder.
///
/// Start it once the root view is up: `.task { await DemoAutopilot.shared?.run() }`.
@MainActor @Observable
final class DemoAutopilot {

    static let shared: DemoAutopilot? = ProcessInfo.processInfo.arguments.contains("-Demo") ? DemoAutopilot() : nil

    /// Anything the script needs from the launch arguments, as `-DemoLink <url>`.
    static func argument(_ name: String) -> String? {
        UserDefaults.standard.string(forKey: "Demo" + name)
    }

    /// The control to press now; its view runs the action and reports back.
    private(set) var pressing: DemoTarget?

    /// Where each control's press lands, in screen points.
    @ObservationIgnored private var points: [DemoTarget: CGPoint] = [:]
    @ObservationIgnored private var enabled: Set<DemoTarget> = []
    @ObservationIgnored private var taps: [DemoTap] = []
    @ObservationIgnored private var start: CFTimeInterval = 0
    @ObservationIgnored private var startedAt = Date()

    static let timelineURL = FileManager.default.temporaryDirectory.appending(path: "demo-taps.json")

    /// The scenario. `press` waits until the control is on screen and enabled, so a
    /// step that depends on loading needs no guesswork; `after` holds it a while longer.
    func run() async {
        start = CACurrentMediaTime()
        startedAt = Date()
        // Let the first screen settle before the clip begins.
        await pause(2.5)
        await press(.add)
        await pause(1.2)
        await press(.save, after: 0.6)
        await pause(2.0)
        writeTimeline()
    }

    func place(_ target: DemoTarget, at frame: CGRect, anchor: UnitPoint = .center) {
        points[target] = CGPoint(x: frame.minX + frame.width * anchor.x, y: frame.minY + frame.height * anchor.y)
    }

    func setEnabled(_ target: DemoTarget, _ isEnabled: Bool) {
        if isEnabled { enabled.insert(target) } else { enabled.remove(target) }
    }

    func remove(_ target: DemoTarget) {
        points[target] = nil
        enabled.remove(target)
    }

    func didPress(_ target: DemoTarget) {
        if pressing == target { pressing = nil }
    }

    private func press(_ target: DemoTarget, after delay: TimeInterval = 0) async {
        while points[target] == nil || !enabled.contains(target) {
            await pause(0.05)
        }
        await pause(delay)
        guard let point = points[target] else { return }
        taps.append(DemoTap(target: target, time: CACurrentMediaTime() - start, x: point.x, y: point.y))
        pressing = target
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func writeTimeline() {
        let timeline = DemoTimeline(started: startedAt.timeIntervalSince1970, taps: taps)
        guard let data = try? JSONEncoder().encode(timeline) else { return }
        try? data.write(to: Self.timelineURL)
    }
}
#endif
