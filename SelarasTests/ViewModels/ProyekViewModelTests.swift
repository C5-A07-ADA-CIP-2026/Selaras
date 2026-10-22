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
