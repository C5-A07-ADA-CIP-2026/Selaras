//
//  DeviceConnectionModel.swift
//  Selaras
//

import Foundation

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
}
