//
//  WaitUntil.swift
//  SeronaTests
//

/// Polls `condition` on the main actor until it holds or `timeout` elapses.
/// Returns whether the condition held, so tests can `#expect(await waitUntil { ... })`.
@MainActor
func waitUntil(
    timeout: Duration = .seconds(2),
    interval: Duration = .milliseconds(5),
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() {
        if clock.now >= deadline {
            return false
        }
        try? await Task.sleep(for: interval)
    }
    return true
}
