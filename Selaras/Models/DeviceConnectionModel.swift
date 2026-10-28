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

    /// Percentage of `baseline`; nil when there is no positive baseline to compare with.
    func concentration(relativeTo baseline: Double) -> Double? {
        guard baseline > 0 else { return nil }
        return (visibleAverage / baseline) * 100
    }

    func formattedConcentration(relativeTo baseline: Double) -> String {
        guard let percentage = concentration(relativeTo: baseline) else { return "0.0%" }
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

/// A Selaras device found while scanning.
struct DiscoveredDevice: Identifiable, Hashable, Sendable {
    /// Shown while a device has not revealed its name yet.
    static let unnamed = "Tanpa Nama"

    let id: UUID
    let nama: String

    /// The name to show for a peripheral. The advertised name comes first because iOS caches `peripheralName`
    /// and can keep an old one. Blank names count as missing; nil means neither source has a name yet.
    nonisolated static func resolveName(peripheralName: String?, advertisedName: String?) -> String? {
        [advertisedName, peripheralName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}

/// Finds and connects to devices. This is all `DeviceListViewModel` needs.
protocol DeviceConnecting: Sendable {
    /// Emits each device as it is found and finishes when the scan ends.
    func scanDevices() -> AsyncThrowingStream<DiscoveredDevice, any Error>
    /// Connects to `device`. Cancelling the calling task abandons the attempt with `CancellationError`.
    func connect(to device: DiscoveredDevice) async throws
    /// Drops the connection to `device`.
    func disconnect(from device: DiscoveredDevice) async
}

/// Reads color measurements from a connected device. This is all `ProyekViewModel` needs.
protocol ColorMeasurementSource: Sendable {
    func readInitialColorMeasurement() async throws -> ColorMeasurement
    func measurementUpdates() -> AsyncStream<ColorMeasurement>
}

/// A device that can both connect and measure (the BLE and simulated implementations).
protocol DeviceConnectionService: DeviceConnecting, ColorMeasurementSource, Sendable {}

struct SimulatedDeviceConnectionService: DeviceConnectionService {
    static let devices = ["A", "B", "C", "D", "E", "F"].enumerated().map { index, letter in
        DiscoveredDevice(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000E\(index + 1)")!,
            nama: "ESP 32 - \(letter)"
        )
    }

    let discoveryDelay: Duration
    let connectionDelay: Duration

    init(
        discoveryDelay: Duration = .seconds(1),
        connectionDelay: Duration = .seconds(2)
    ) {
        self.discoveryDelay = discoveryDelay
        self.connectionDelay = connectionDelay
    }

    func scanDevices() -> AsyncThrowingStream<DiscoveredDevice, any Error> {
        let delay = discoveryDelay
        return AsyncThrowingStream { continuation in
            let task = Task {
                print("[Simulator] 🔍 Mensimulasikan pencarian perangkat ESP32...")
                for device in Self.devices {
                    try? await Task.sleep(for: delay)
                    if Task.isCancelled {
                        break
                    }
                    continuation.yield(device)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func connect(to device: DiscoveredDevice) async throws {
        print("[Simulator] ⏳ Mensimulasikan koneksi ke \(device.nama)...")
        try await Task.sleep(for: connectionDelay)
        print("[Simulator] ✅ Perangkat simulasi \(device.nama) terhubung.")
    }

    func disconnect(from device: DiscoveredDevice) async {
        print("[Simulator] 🔌 Perangkat simulasi \(device.nama) diputus.")
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
