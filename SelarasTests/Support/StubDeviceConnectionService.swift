//
//  StubDeviceConnectionService.swift
//  SelarasTests
//

import Foundation
@testable import Selaras

/// Thread-safe counter for how many device reads a stub received.
final nonisolated class ReadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = 0

    var value: Int {
        lock.withLock { storage }
    }

    /// Adds one and returns the new count.
    func increment() -> Int {
        lock.withLock {
            storage += 1
            return storage
        }
    }
}

struct StubDeviceConnectionService: DeviceConnectionService {
    var initial = ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    var updates: [ColorMeasurement] = []
    /// When set, the first `readInitialColorMeasurement` suspends until this stream yields or finishes.
    var readGate: AsyncStream<Void>?
    var onReadStarted: (@Sendable () -> Void)?
    /// When set, `measurementUpdates` returns this stream instead of `updates`.
    var liveUpdates: AsyncStream<ColorMeasurement>?
    /// When set, `readInitialColorMeasurement` throws this error (after the gate, if any).
    var readError: (any Error)?
    /// Counts every `readInitialColorMeasurement` call.
    let readCounter = ReadCounter()

    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        let readNumber = readCounter.increment()
        onReadStarted?()
        // Only the first read waits: a gate stream supports a single consumer.
        if let readGate, readNumber == 1 {
            for await _ in readGate {
                break
            }
        }
        if let readError {
            throw readError
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
