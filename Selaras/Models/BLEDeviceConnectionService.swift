//
//  BLEDeviceConnectionService.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import CoreBluetooth
import Foundation

final class BLEDeviceConnectionService: NSObject, DeviceConnectionService, @unchecked Sendable {
    /// Instance tunggal (singleton) agar CBCentralManager tidak terhapus selama siklus hidup aplikasi
    static let shared = BLEDeviceConnectionService()

    /// Service UUID khusus untuk perangkat Selaras
    static let serviceUUID = CBUUID(string: "4FAFC201-1FB5-459E-8FCC-C5C9C331914B")
    static let measurementCharacteristicUUID = CBUUID(string: "BEA57604-1C34-45B5-927A-94943E992383")

    private var centralManager: CBCentralManager?
    private var discoveredPeripheral: CBPeripheral?
    private var measurementCharacteristic: CBCharacteristic?

    private let discoveryTimeout: TimeInterval
    private let connectionTimeout: TimeInterval

    // Continuation untuk jembatan async/await ke callback delegate CoreBluetooth
    private var discoveryContinuation: CheckedContinuation<Bool, any Error>?
    private var connectionContinuation: CheckedContinuation<Void, any Error>?
    private var characteristicContinuation: CheckedContinuation<Void, any Error>?
    private var measurementContinuation: CheckedContinuation<ColorMeasurement, any Error>?
    private var measurementStreamContinuation: AsyncStream<ColorMeasurement>.Continuation?

    init(
        discoveryTimeout: TimeInterval = 10,
        connectionTimeout: TimeInterval = 10
    ) {
        self.discoveryTimeout = discoveryTimeout
        self.connectionTimeout = connectionTimeout
        super.init()
    }

    private func obtainCentralManager() -> CBCentralManager {
        if let centralManager {
            return centralManager
        }
        let manager = CBCentralManager(delegate: self, queue: .main)
        centralManager = manager
        return manager
    }

    // MARK: - DeviceConnectionService Conformance

    func discoverDevice() async throws -> Bool {
        if let peripheral = discoveredPeripheral, peripheral.state == .connected {
            let name = peripheral.name ?? "ESP32"
            print("[BLE] ℹ️ Perangkat '\(name)' sudah dalam keadaan terhubung.")
            return true
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.discoveryContinuation?.resume(returning: false)
            self.discoveryContinuation = continuation

            print("[BLE] 🔍 Memulai pencarian perangkat Selaras (Service UUID: \(Self.serviceUUID.uuidString))...")
            let manager = obtainCentralManager()
            if manager.state == .poweredOn {
                startScanning(manager: manager)
            } else {
                print("[BLE] ⏳ Menunggu Bluetooth siap (status saat ini: \(manager.state.rawValue))...")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.discoveryTimeout) { [weak self] in
                guard let self, let cont = discoveryContinuation else { return }
                print("[BLE] ⏱️ Waktu pencarian habis (\(Int(discoveryTimeout)) detik). Perangkat tidak ditemukan.")
                centralManager?.stopScan()
                discoveryContinuation = nil
                cont.resume(returning: false)
            }
        }
    }

    func connectToDevice() async throws {
        guard let peripheral = discoveredPeripheral else {
            let errorUserInfo = [NSLocalizedDescriptionKey: "Perangkat belum ditemukan"]
            print("[BLE] ❌ Gagal menghubungkan: belum ada perangkat yang ditemukan.")
            throw NSError(domain: "BLEService", code: 404, userInfo: errorUserInfo)
        }

        if peripheral.state == .connected {
            let name = peripheral.name ?? "ESP32"
            print("[BLE] ℹ️ Perangkat '\(name)' sudah dalam keadaan terhubung.")
            return
        }

        let deviceName = peripheral.name ?? "ESP32"
        print("[BLE] ⏳ Menghubungkan ke '\(deviceName)' [\(peripheral.identifier.uuidString)]...")

        try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation?.resume(throwing: CancellationError())
            self.connectionContinuation = continuation
            let manager = obtainCentralManager()
            manager.connect(peripheral, options: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + self.connectionTimeout) { [weak self] in
                guard let self, let cont = connectionContinuation else { return }
                print("[BLE] ⏱️ Waktu koneksi habis. Membatalkan koneksi...")
                centralManager?.cancelPeripheralConnection(peripheral)
                connectionContinuation = nil
                let timeoutError = NSError(
                    domain: "BLEService",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: "Waktu koneksi habis"]
                )
                cont.resume(throwing: timeoutError)
            }
        }
    }

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        guard let peripheral = discoveredPeripheral, peripheral.state == .connected else {
            throw NSError(
                domain: "BLEService",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "Perangkat belum terhubung"]
            )
        }

        try await obtainMeasurementCharacteristic(from: peripheral)
        guard let characteristic = measurementCharacteristic else {
            throw NSError(
                domain: "BLEService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Characteristic sensor tidak ditemukan"]
            )
        }
        return try await withCheckedThrowingContinuation { continuation in
            measurementContinuation?.resume(throwing: CancellationError())
            measurementContinuation = continuation
            print("[BLE] 📥 Meminta pembacaan characteristic \(Self.measurementCharacteristicUUID.uuidString)...")
            peripheral.readValue(for: characteristic)
        }
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            measurementStreamContinuation = continuation
        }
    }

    private func obtainMeasurementCharacteristic(
        from peripheral: CBPeripheral
    ) async throws {
        if let measurementCharacteristic {
            _ = measurementCharacteristic
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            characteristicContinuation?.resume(throwing: CancellationError())
            characteristicContinuation = continuation
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    private func startScanning(manager: CBCentralManager) {
        print("[BLE] 📡 Sedang memindai sinyal advertising BLE...")
        manager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEDeviceConnectionService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("[BLE] 🟢 Bluetooth aktif dan siap digunakan.")
            if discoveryContinuation != nil {
                startScanning(manager: central)
            }
        case .poweredOff:
            print("[BLE] 🔴 Bluetooth tidak aktif! Harap nyalakan Bluetooth di Pengaturan.")
            let error = NSError(
                domain: "BLEService",
                code: central.state.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Bluetooth tidak aktif"]
            )
            discoveryContinuation?.resume(throwing: error)
            discoveryContinuation = nil
        case .unauthorized:
            print("[BLE] ⚠️ Izin akses Bluetooth ditolak.")
            let error = NSError(
                domain: "BLEService",
                code: central.state.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Izin Bluetooth ditolak"]
            )
            discoveryContinuation?.resume(throwing: error)
            discoveryContinuation = nil
        case .unsupported:
            print("[BLE] ⚠️ Perangkat tidak mendukung Bluetooth Low Energy.")
            let error = NSError(
                domain: "BLEService",
                code: central.state.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Perangkat tidak mendukung Bluetooth"]
            )
            discoveryContinuation?.resume(throwing: error)
            discoveryContinuation = nil
        default:
            print("[BLE] ℹ️ Status Bluetooth berubah ke: \(central.state.rawValue)")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "Tanpa Nama"
        print("[BLE] ✨ Ditemukan: '\(name)' | UUID: \(peripheral.identifier.uuidString) | RSSI: \(RSSI) dBm")

        central.stopScan()
        discoveredPeripheral = peripheral
        peripheral.delegate = self

        discoveryContinuation?.resume(returning: true)
        discoveryContinuation = nil
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "ESP32"
        print("[BLE] ✅ Sukses tersambung ke '\(name)'!")
        peripheral.delegate = self
        peripheral.discoverServices([Self.serviceUUID])
        connectionContinuation?.resume(returning: ())
        connectionContinuation = nil
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        let name = peripheral.name ?? "ESP32"
        let defaultError = NSError(
            domain: "BLEService",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Gagal terhubung"]
        )
        let err = error ?? defaultError
        print("[BLE] ❌ Gagal menyambung ke '\(name)': \(err.localizedDescription)")
        connectionContinuation?.resume(throwing: err)
        connectionContinuation = nil
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: (any Error)?) {
        let name = peripheral.name ?? "ESP32"
        print("[BLE] 🔌 Perangkat '\(name)' terputus.")
        discoveredPeripheral = nil
        measurementCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate

extension BLEDeviceConnectionService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            print("[BLE] ❌ Gagal menemukan service: \(error.localizedDescription)")
            characteristicContinuation?.resume(throwing: error)
            characteristicContinuation = nil
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            print("[BLE] 📦 Ditemukan service: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error {
            print("[BLE] ❌ Gagal menemukan characteristic: \(error.localizedDescription)")
            characteristicContinuation?.resume(throwing: error)
            characteristicContinuation = nil
            return
        }
        guard let characteristics = service.characteristics else {
            let error = NSError(
                domain: "BLEService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Characteristic sensor tidak ditemukan"]
            )
            characteristicContinuation?.resume(throwing: error)
            characteristicContinuation = nil
            return
        }
        for characteristic in characteristics {
            print("[BLE] 🔑 Ditemukan characteristic: \(characteristic.uuid.uuidString)")
            guard characteristic.uuid == Self.measurementCharacteristicUUID else { continue }
            measurementCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            characteristicContinuation?.resume(returning: ())
            characteristicContinuation = nil
        }
        if measurementCharacteristic == nil {
            let error = NSError(
                domain: "BLEService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Characteristic sensor tidak ditemukan"]
            )
            characteristicContinuation?.resume(throwing: error)
            characteristicContinuation = nil
        }
    }

    func peripheral(
        _: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard characteristic.uuid == Self.measurementCharacteristicUUID else { return }

        if let error {
            measurementContinuation?.resume(throwing: error)
            measurementContinuation = nil
            return
        }

        guard let data = characteristic.value else {
            let error = NSError(
                domain: "BLEService",
                code: 204,
                userInfo: [NSLocalizedDescriptionKey: "ESP32 mengirim payload kosong"]
            )
            measurementContinuation?.resume(throwing: error)
            measurementContinuation = nil
            return
        }

        let rawPayload = String(data: data, encoding: .utf8) ?? "<bukan UTF-8>"
        let hexPayload = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        print("[BLE] 📦 Payload diterima: \(rawPayload)")
        print("[BLE] 🔢 Bytes payload: \(hexPayload)")

        do {
            let measurement = try JSONDecoder().decode(ColorMeasurement.self, from: data)
            print(
                "[BLE] 🎨 AS7341 visibleAverage=\(measurement.visibleAverage), " +
                    "clear=\(measurement.clear), nir=\(measurement.nir)"
            )
            measurementStreamContinuation?.yield(measurement)
            measurementContinuation?.resume(returning: measurement)
        } catch {
            measurementContinuation?.resume(throwing: error)
        }
        measurementContinuation = nil
    }
}
