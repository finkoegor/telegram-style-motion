#if DEBUG
/// A control the demo autopilot presses. Name every control your script touches and
/// mark the control's view with `.demoTarget(.name) { action }`.
enum DemoTarget: String, Codable {
    case add
    case save
}
#endif
