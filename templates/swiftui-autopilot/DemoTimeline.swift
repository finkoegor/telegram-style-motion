#if DEBUG
import Foundation

/// What a demo run writes for the editing script: when it began on the wall clock, to
/// line it up with the recording, and every press.
struct DemoTimeline: Codable {
    let started: TimeInterval
    let taps: [DemoTap]
}
#endif
