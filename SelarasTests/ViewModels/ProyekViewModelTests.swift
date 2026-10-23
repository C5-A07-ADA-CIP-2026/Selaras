//
//  ProyekViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ProyekViewModelTests {
    @Test func markingDeviceAsConnectedUpdatesProjectState() {
        let viewModel = ProyekViewModel()

        viewModel.markDeviceAsConnected()

        #expect(viewModel.isDeviceConnected)
    }

    @Test("Initial color measurement comes from the connection service")
    func readsInitialColorMeasurement() async {
        let viewModel = ProyekViewModel(service: ImmediateDeviceConnectionService())

        await viewModel.readInitialColorMeasurement()
        try? await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.initialColorMeasurements.initial.first?.value == "100%")
        #expect(viewModel.initialColorMeasurements.current.first?.value == "73.5%")
        #expect(viewModel.colorConcentrationWarning != nil)
    }

    @Test("Warns when streaming color concentration falls below 80 percent")
    func warnsBelowColorConcentrationLimit() async {
        let viewModel = ProyekViewModel(service: LowConcentrationDeviceConnectionService())

        await viewModel.readInitialColorMeasurement()
        try? await Task.sleep(for: .milliseconds(10))

        #expect(
            viewModel.colorConcentrationWarning
                == "Kepekatan warna saat ini di bawah 80%. Tambahkan 10 gram pewarna untuk "
                + "menjaga kualitas dan ketajaman warna batik."
        )
    }

    @Test("Does not warn at exactly 80 percent")
    func doesNotWarnAtColorConcentrationLimit() async {
        let viewModel = ProyekViewModel(service: AtLimitDeviceConnectionService())

        await viewModel.readInitialColorMeasurement()
        try? await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.colorConcentrationWarning == nil)
    }

    @Test("Warns when water pH falls below 7")
    func warnsBelowWaterPHLimit() async {
        let viewModel = ProyekViewModel(service: LowWaterPHDeviceConnectionService())

        await viewModel.readInitialColorMeasurement()
        try? await Task.sleep(for: .milliseconds(10))

        #expect(
            viewModel.waterPHWarning
                == "pH air saat ini di bawah 7. Tambahkan 10 gram soda abu untuk menjaga kualitas dan "
                + "ketajaman warna batik."
        )
    }

    @Test func discoveryMovesViewModelToFoundState() async {
        let viewModel = AddDeviceViewModel(service: ImmediateDeviceConnectionService())

        await viewModel.discoverDevice()

        #expect(viewModel.state == .found)
        #expect(viewModel.isDeviceFound)
    }

    @Test func connectingMovesViewModelToConnectedState() async {
        let viewModel = AddDeviceViewModel(
            initialState: .found,
            service: ImmediateDeviceConnectionService()
        )

        await viewModel.connectDevice()

        #expect(viewModel.state == .connected)
    }
}

private struct ImmediateDeviceConnectionService: DeviceConnectionService {
    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            continuation.yield(ColorMeasurement(visibleAverage: 735, clear: 1200, nir: 200))
            continuation.finish()
        }
    }
}

private struct LowConcentrationDeviceConnectionService: DeviceConnectionService {
    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            continuation.yield(ColorMeasurement(visibleAverage: 699, clear: 1200, nir: 200))
            continuation.finish()
        }
    }
}

private struct AtLimitDeviceConnectionService: DeviceConnectionService {
    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            continuation.yield(ColorMeasurement(visibleAverage: 800, clear: 1200, nir: 200))
            continuation.finish()
        }
    }
}

private struct LowWaterPHDeviceConnectionService: DeviceConnectionService {
    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        AsyncStream { continuation in
            continuation.yield(
                ColorMeasurement(
                    visibleAverage: 1000,
                    clear: 1200,
                    nir: 200,
                    waterPH: 6.9
                )
            )
            continuation.finish()
        }
    }
}
