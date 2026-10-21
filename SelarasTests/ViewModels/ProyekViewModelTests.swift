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
}
