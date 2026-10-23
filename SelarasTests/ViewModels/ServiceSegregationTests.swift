//
//  ServiceSegregationTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

/// Conforms only to `DeviceConnecting`: it cannot read colors.
private struct ConnectingOnlyService: DeviceConnecting {
    var isDeviceFound = true

    func discoverDevice() async throws -> Bool {
        isDeviceFound
    }

    func connectToDevice() async throws {}
}

/// Conforms only to `ColorMeasurementSource`: it cannot connect.
private struct MeasurementOnlySource: ColorMeasurementSource {
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

@MainActor
struct ServiceSegregationTests {
    @Test("AddDeviceViewModel needs only a DeviceConnecting service")
    func addDeviceWorksWithConnectingOnlyService() async {
        let viewModel = AddDeviceViewModel(service: ConnectingOnlyService())

        await viewModel.discoverDevice()
        #expect(viewModel.state == .found)

        await viewModel.connectDevice()
        #expect(viewModel.state == .connected)
    }

    @Test("AddDeviceViewModel fails when the connecting-only service finds nothing")
    func addDeviceFailsWhenNothingFound() async {
        let viewModel = AddDeviceViewModel(service: ConnectingOnlyService(isDeviceFound: false))

        await viewModel.discoverDevice()

        #expect(viewModel.state == .failed)
    }

    @Test("ProyekViewModel needs only a ColorMeasurementSource")
    func proyekWorksWithMeasurementOnlySource() async {
        let viewModel = ProyekViewModel(service: MeasurementOnlySource())
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        await viewModel.scanData()
        let didStream = await waitUntil { viewModel.latestConcentration == 80 }

        #expect(viewModel.isDataScanned)
        #expect(didStream)
    }
}
