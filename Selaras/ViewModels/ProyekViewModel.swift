//
//  ProyekViewModel.swift
//  Selaras
//

import Combine
import Foundation
import SwiftData

@MainActor
final class ProyekViewModel: ObservableObject {
    @Published private(set) var isDeviceConnected = false
    @Published private(set) var selectedResep: Resep?
    @Published private(set) var measurements: ProyekColorMeasurements?
    @Published private(set) var isDataScanned = false
    @Published var jumlahKain = 0
    @Published private(set) var colorMeasurementError: String?
    @Published private(set) var colorConcentrationWarning: String?
    @Published private(set) var waterPHWarning: String?
    @Published private(set) var projectSaved = false
    @Published private(set) var saveError: String?
    @Published private(set) var isScanning = false

    /// Latest streamed readings (concentration in percent of the baseline), kept for saving the project.
    private(set) var latestConcentration: Double?
    private(set) var latestWaterPH: Double?

    private let service: any ColorMeasurementSource
    private var measurementTask: Task<Void, Never>?
    private var initialVisibleAverage: Double?
    private var warningTracker = MeasurementWarningTracker()
    /// Identifies the scan that currently owns `isScanning`, so a superseded scan cannot clear it.
    private var activeScan: UUID?

    init(service: (any ColorMeasurementSource)? = nil) {
        self.service = service ?? DeviceConnectionServices.default
    }

    func markDeviceAsConnected() {
        isDeviceConnected = true
    }

    /// Selects a recipe and resets everything derived from a previous scan.
    /// `jumlahKain` is deliberately kept.
    func pilihResep(_ resep: Resep) {
        measurementTask?.cancel()
        measurementTask = nil
        endScanning()
        initialVisibleAverage = nil
        warningTracker.reset()
        isDataScanned = false
        colorMeasurementError = nil
        colorConcentrationWarning = nil
        waterPHWarning = nil
        latestConcentration = nil
        latestWaterPH = nil
        selectedResep = resep
        measurements = ProyekColorMeasurements(
            colorConcentrationLimit: resep.kepekatan,
            waterPHLimit: resep.batasPH
        )
    }

    /// Reads the baseline measurement for the selected recipe and starts streaming updates.
    /// Does nothing when no recipe is selected or a scan is already reading the device.
    func scanData() async {
        guard let resep = selectedResep, !isScanning else { return }
        let scan = UUID()
        activeScan = scan
        isScanning = true
        defer {
            // A newer scan (after the recipe changed) may own the flag by now.
            if activeScan == scan {
                endScanning()
            }
        }
        colorMeasurementError = nil
        do {
            let initial = try await service.readInitialColorMeasurement()
            // The recipe may have changed while the device was being read.
            guard selectedResep === resep else { return }
            beginMeasuring(from: initial, resep: resep)
        } catch is CancellationError {
            // A superseded or cancelled read is not a failure.
            return
        } catch {
            guard selectedResep === resep else { return }
            let message = "Gagal membaca data warna dari AS7341: \(error.localizedDescription)"
            colorMeasurementError = message
            print("[Proyek] ❌ \(message)")
        }
    }

    private func endScanning() {
        activeScan = nil
        isScanning = false
    }

    private func beginMeasuring(from initial: ColorMeasurement, resep: Resep) {
        initialVisibleAverage = initial.visibleAverage
        warningTracker.reset()
        measurements = ProyekColorMeasurements(
            colorConcentrationLimit: resep.kepekatan,
            waterPHLimit: resep.batasPH,
            initialWaterPH: initial.waterPH
        )
        isDataScanned = true

        measurementTask?.cancel()
        measurementTask = Task { [weak self] in
            guard let self else { return }
            for await measurement in service.measurementUpdates() {
                updateCurrentColorMeasurement(measurement)
            }
        }
    }

    private func updateCurrentColorMeasurement(_ measurement: ColorMeasurement) {
        guard let measurements, let initialVisibleAverage, initialVisibleAverage > 0 else { return }
        var updated = measurements.withCurrentConcentration(
            measurement,
            relativeTo: initialVisibleAverage
        )
        if let waterPH = measurement.waterPH {
            updated = updated.withCurrentWaterPH(waterPH)
            latestWaterPH = waterPH
        }
        self.measurements = updated

        guard let concentration = updated.concentration(
            for: measurement,
            relativeTo: initialVisibleAverage
        ) else { return }
        latestConcentration = concentration

        if let warning = warningTracker.concentrationWarning(
            for: concentration,
            limit: updated.colorConcentrationLimit
        ) {
            colorConcentrationWarning = warning
        }

        if let waterPH = measurement.waterPH {
            waterPHWarning = MeasurementWarningTracker.waterPHWarning(for: waterPH, limit: updated.waterPHLimit)
        }
    }

    /// Saves the scanned project as a `Proyek` and resets the form for the next one.
    /// Returns `false` and touches nothing when there is no recipe, no scan or no fabric;
    /// a second call right after a successful save therefore does nothing.
    /// Final readings are nil (never 0) when the sensor has not streamed them yet.
    @discardableResult
    func saveProject(in context: some ModelPersisting) -> Bool {
        guard let resep = selectedResep, isDataScanned, jumlahKain > 0 else { return false }

        let proyek = Proyek(
            resep: resep,
            jumlahKain: jumlahKain,
            kepekatanAkhir: latestConcentration,
            phAkhir: latestWaterPH
        )
        do {
            try context.insertAndSave(proyek)
        } catch {
            saveError = "Gagal menyimpan proyek: \(error.localizedDescription)"
            return false
        }

        resetForNextProject()
        projectSaved = true
        return true
    }

    private func resetForNextProject() {
        measurementTask?.cancel()
        measurementTask = nil
        endScanning()
        initialVisibleAverage = nil
        warningTracker.reset()
        selectedResep = nil
        measurements = nil
        isDataScanned = false
        jumlahKain = 0
        colorMeasurementError = nil
        colorConcentrationWarning = nil
        waterPHWarning = nil
        latestConcentration = nil
        latestWaterPH = nil
    }

    func clearProjectSaved() {
        projectSaved = false
    }

    func clearSaveError() {
        saveError = nil
    }

    func clearColorMeasurementError() {
        colorMeasurementError = nil
    }

    func clearColorConcentrationWarning() {
        colorConcentrationWarning = nil
    }

    func clearWaterPHWarning() {
        waterPHWarning = nil
    }
}

@MainActor
final class AddDeviceViewModel: ObservableObject {
    @Published private(set) var state: DeviceConnectionState

    private let service: any DeviceConnecting

    init(
        initialState: DeviceConnectionState = .searching,
        service: any DeviceConnecting = DeviceConnectionServices.default
    ) {
        state = initialState
        self.service = service
    }

    var isDeviceFound: Bool {
        switch state {
        case .found, .connecting, .connected:
            true
        case .searching, .failed:
            false
        }
    }

    var isConnecting: Bool {
        state == .connecting
    }

    func discoverDevice() async {
        guard state == .searching || state == .failed else { return }

        state = .searching

        do {
            if try await service.discoverDevice() {
                state = .found
            } else {
                state = .failed
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed
        }
    }

    func connectDevice() async {
        guard state == .found else { return }

        state = .connecting

        do {
            try await service.connectToDevice()
            state = .connected
        } catch is CancellationError {
            return
        } catch {
            state = .failed
        }
    }
}
