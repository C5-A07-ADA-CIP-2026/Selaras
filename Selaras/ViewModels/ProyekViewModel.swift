//
//  ProyekViewModel.swift
//  Selaras
//

import Combine

@MainActor
final class ProyekViewModel: ObservableObject {
    @Published private(set) var isDeviceConnected = false

    func markDeviceAsConnected() {
        isDeviceConnected = true
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
