//
//  DeviceConnectionServices.swift
//  Serona
//

/// The one place that decides which device service the app uses.
enum DeviceConnectionServices {
    /// A simulated device in the simulator (it has no Bluetooth), the real BLE device otherwise.
    static var `default`: any DeviceConnectionService {
        #if targetEnvironment(simulator)
            SimulatedDeviceConnectionService()
        #else
            BLEDeviceConnectionService.shared
        #endif
    }
}
