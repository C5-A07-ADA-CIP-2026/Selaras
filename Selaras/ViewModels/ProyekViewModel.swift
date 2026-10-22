//
//  ProyekViewModel.swift
//  Selaras
//

import Combine
import Foundation

@MainActor
final class ProyekViewModel: ObservableObject {
    @Published private(set) var isDeviceConnected = false
    @Published private(set) var initialColorMeasurements = ProyekColorMeasurements.selectedColor
    @Published private(set) var colorMeasurementError: String?

    private let service: any DeviceConnectionService
    private var measurementTask: Task<Void, Never>?
    private var initialVisibleAverage: Double?

    init(service: (any DeviceConnectionService)? = nil) {
        #if targetEnvironment(simulator)
            self.service = service ?? SimulatedDeviceConnectionService()
        #else
            self.service = service ?? BLEDeviceConnectionService.shared
        #endif
    }

    func markDeviceAsConnected() {
        isDeviceConnected = true
    }

    func setInitialColorMeasurement(_ measurement: ColorMeasurement) {
        initialVisibleAverage = measurement.visibleAverage
        measurementTask?.cancel()
        measurementTask = Task { [weak self] in
            guard let self else { return }
            for await measurement in service.measurementUpdates() {
                updateCurrentColorMeasurement(measurement)
            }
        }
    }

    private func updateCurrentColorMeasurement(_ measurement: ColorMeasurement) {
        guard let initialVisibleAverage, initialVisibleAverage > 0 else { return }
        initialColorMeasurements = initialColorMeasurements.withCurrentConcentration(
            measurement,
            relativeTo: initialVisibleAverage
        )
    }

    func readInitialColorMeasurement() async {
        colorMeasurementError = nil
        do {
            let measurement = try await service.readInitialColorMeasurement()
            setInitialColorMeasurement(measurement)
        } catch {
            let message = "Gagal membaca data warna dari AS7341: \(error.localizedDescription)"
            colorMeasurementError = message
            print("[Proyek] ❌ \(message)")
        }
    }

    func clearColorMeasurementError() {
        colorMeasurementError = nil
    }
}

@MainActor
final class AddDeviceViewModel: ObservableObject {
    @Published private(set) var state: DeviceConnectionState

    private let service: any DeviceConnectionService

    init(
        initialState: DeviceConnectionState = .searching,
        service: any DeviceConnectionService = SimulatedDeviceConnectionService()
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
