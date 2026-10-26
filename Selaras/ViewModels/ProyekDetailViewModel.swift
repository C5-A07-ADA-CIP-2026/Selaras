//
//  ProyekDetailViewModel.swift
//  Selaras
//

import Combine
import Foundation

/// Scans the color of one project and finishes it. The limits come from the project, not from the recipe it copied.
@MainActor
final class ProyekDetailViewModel: ObservableObject {
    let proyek: Proyek

    @Published private(set) var measurements: ProyekColorMeasurements
    @Published private(set) var isDataScanned = false
    @Published private(set) var isScanning = false
    @Published private(set) var colorMeasurementError: String?
    @Published private(set) var colorConcentrationWarning: String?
    @Published private(set) var waterPHWarning: String?
    @Published private(set) var saveError: String?

    /// Latest streamed readings (concentration in percent of the baseline), kept for finishing the project.
    private(set) var latestConcentration: Double?
    private(set) var latestWaterPH: Double?

    private let service: any ColorMeasurementSource
    private var measurementTask: Task<Void, Never>?
    private var initialVisibleAverage: Double?
    private var warningTracker = MeasurementWarningTracker()

    init(proyek: Proyek, service: (any ColorMeasurementSource)? = nil) {
        self.proyek = proyek
        self.service = service ?? DeviceConnectionServices.default
        measurements = ProyekColorMeasurements(
            colorConcentrationLimit: proyek.batasKepekatan,
            waterPHLimit: proyek.batasPH
        )
    }

    /// Reads the baseline measurement and starts streaming updates.
    /// Does nothing for a finished project or while a scan is already reading the device.
    func mulaiPindai() async {
        guard proyek.status == .aktif, !isScanning else { return }
        isScanning = true
        defer { isScanning = false }
        colorMeasurementError = nil
        do {
            let initial = try await service.readInitialColorMeasurement()
            beginMeasuring(from: initial)
        } catch is CancellationError {
            // A cancelled read is not a failure.
            return
        } catch {
            let message = "Gagal membaca data warna dari AS7341: \(error.localizedDescription)"
            colorMeasurementError = message
            print("[Proyek] ❌ \(message)")
        }
    }

    /// Ends the live stream (when leaving the screen or finishing).
    func berhenti() {
        measurementTask?.cancel()
        measurementTask = nil
    }

    private func beginMeasuring(from initial: ColorMeasurement) {
        initialVisibleAverage = initial.visibleAverage
        warningTracker.reset()
        measurements = ProyekColorMeasurements(
            colorConcentrationLimit: proyek.batasKepekatan,
            waterPHLimit: proyek.batasPH,
            initialWaterPH: initial.waterPH
        )
        isDataScanned = true

        measurementTask?.cancel()
        measurementTask = Task { [weak self] in
            guard let self else { return }
            for await measurement in service.measurementUpdates() {
                // A reading buffered before `berhenti()` must not be applied afterwards.
                if Task.isCancelled {
                    break
                }
                updateCurrentColorMeasurement(measurement)
            }
        }
    }

    private func updateCurrentColorMeasurement(_ measurement: ColorMeasurement) {
        guard let initialVisibleAverage, initialVisibleAverage > 0 else { return }
        var updated = measurements.withCurrentConcentration(
            measurement,
            relativeTo: initialVisibleAverage
        )
        if let waterPH = measurement.waterPH {
            updated = updated.withCurrentWaterPH(waterPH)
            latestWaterPH = waterPH
        }
        measurements = updated

        guard let concentration = measurement.concentration(relativeTo: initialVisibleAverage) else { return }
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

    /// Finishes the scanned project: stores the final readings and moves it to the inactive list.
    /// Returns `false` and changes nothing when the project is not active, was not scanned yet, or the save fails.
    /// Final readings are nil (never 0) when the sensor has not streamed them yet.
    @discardableResult
    func selesaikan(in persistence: some ModelPersisting) -> Bool {
        guard proyek.status == .aktif, isDataScanned else { return false }

        proyek.selesaikan(kepekatanAkhir: latestConcentration, phAkhir: latestWaterPH)
        do {
            try persistence.save()
        } catch {
            proyek.batalkanSelesai()
            saveError = "Gagal menyimpan proyek: \(error.localizedDescription)"
            return false
        }
        berhenti()
        return true
    }

    func clearSaveError() {
        guard saveError != nil else { return }
        saveError = nil
    }

    func clearColorMeasurementError() {
        guard colorMeasurementError != nil else { return }
        colorMeasurementError = nil
    }

    func clearColorConcentrationWarning() {
        guard colorConcentrationWarning != nil else { return }
        colorConcentrationWarning = nil
    }

    func clearWaterPHWarning() {
        guard waterPHWarning != nil else { return }
        waterPHWarning = nil
    }
}
