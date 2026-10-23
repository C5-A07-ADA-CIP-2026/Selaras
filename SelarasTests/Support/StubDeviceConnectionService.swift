//
//  StubDeviceConnectionService.swift
//  SelarasTests
//

@testable import Selaras

struct StubDeviceConnectionService: DeviceConnectionService {
    var initial = ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    var updates: [ColorMeasurement] = []
    /// When set, `readInitialColorMeasurement` suspends until this stream yields or finishes.
    var readGate: AsyncStream<Void>?
    var onReadStarted: (@Sendable () -> Void)?
    /// When set, `measurementUpdates` returns this stream instead of `updates`.
    var liveUpdates: AsyncStream<ColorMeasurement>?

    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        onReadStarted?()
        if let readGate {
            for await _ in readGate {
                break
            }
        }
        return initial
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        if let liveUpdates {
            return liveUpdates
        }
        let updates = updates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}
