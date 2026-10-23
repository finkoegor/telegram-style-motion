#if DEBUG
import Foundation

/// One press of a demo run, for the editing script to draw: seconds since the run
/// began and the control's center in screen points.
struct DemoTap: Codable {
    let target: DemoTarget
    let time: TimeInterval
    let x: Double
    let y: Double
}
#endif
