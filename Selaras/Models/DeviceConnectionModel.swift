//
//  DeviceConnectionModel.swift
//  Selaras
//

import Foundation

struct ColorMeasurement: Equatable, Decodable, Sendable {
    let visibleAverage: Double
    let clear: UInt16
    let nir: UInt16
    let waterPH: Double?

    init(
        visibleAverage: Double,
        clear: UInt16,
        nir: UInt16,
        waterPH: Double? = nil
    ) {
        self.visibleAverage = visibleAverage
        self.clear = clear
        self.nir = nir
        self.waterPH = waterPH
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        visibleAverage = try container.decodeIfPresent(Double.self, forKey: .visibleAverage)
            ?? container.decode(Double.self, forKey: .concentrationPercent)
        clear = try container.decode(UInt16.self, forKey: .clear)
        nir = try container.decode(UInt16.self, forKey: .nir)
        waterPH = try container.decodeIfPresent(Double.self, forKey: .waterPH)
    }

    func formattedConcentration(relativeTo baseline: Double) -> String {
        guard baseline > 0 else { return "0.0%" }
        let percentage = (visibleAverage / baseline) * 100
        return String(
            format: "%.1f%%",
            locale: Locale(identifier: "en_US_POSIX"),
            percentage
        )
    }

    private enum CodingKeys: String, CodingKey {
        case visibleAverage
        case concentrationPercent
        case clear
        case nir
        case waterPH = "ph"
    }
}

enum DeviceConnectionState: Equatable {
    case searching
    case found
    case connecting
    case connected
    case failed
}

protocol DeviceConnectionService: Sendable {
    func discoverDevice() async throws -> Bool
    func connectToDevice() async throws
    func readInitialColorMeasurement() async throws -> ColorMeasurement
    func measurementUpdates() -> AsyncStream<ColorMeasurement>
}

struct SimulatedDeviceConnectionService: DeviceConnectionService {
    let discoveryDelay: Duration
    let connectionDelay: Duration

    init(
        discoveryDelay: Duration = .seconds(2),
        connectionDelay: Duration = .seconds(2)
    ) {
        self.discoveryDelay = discoveryDelay
        self.connectionDelay = connectionDelay
    }

    func discoverDevice() async throws -> Bool {
        print("[Simulator] 🔍 Mensimulasikan pencarian perangkat ESP32...")
        try await Task.sleep(for: discoveryDelay)
        print("[Simulator] ✨ Perangkat simulasi ESP32 ditemukan.")
        return true
    }

    func connectToDevice() async throws {
        print("[Simulator] ⏳ Mensimulasikan koneksi ke ESP32...")
        try await Task.sleep(for: connectionDelay)
        print("[Simulator] ✅ Perangkat simulasi ESP32 terhubung.")
    }

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        ColorMeasurement(visibleAverage: 1000, clear: 1000, nir: 100)
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            continuation.yield(ColorMeasurement(visibleAverage: 1000, clear: 1000, nir: 100))
        }
    }
}
