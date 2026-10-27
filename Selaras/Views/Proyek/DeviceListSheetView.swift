//
//  DeviceListSheetView.swift
//  Selaras
//

import SwiftUI

/// "Tambahkan Perangkat": the Selaras devices nearby, each with a "Hubungkan" button.
struct DeviceListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DeviceListViewModel
    private let onConnected: (DiscoveredDevice) -> Void

    init(
        service: (any DeviceConnecting)? = nil,
        onConnected: @escaping (DiscoveredDevice) -> Void = { _ in }
    ) {
        _viewModel = State(wrappedValue: DeviceListViewModel(service: service))
        self.onConnected = onConnected
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tambahkan Perangkat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await viewModel.scan() }
                        } label: {
                            Label("Cari Ulang", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.isScanning || viewModel.connectingDevice != nil)
                    }
                }
        }
        .task {
            await viewModel.scan()
        }
        .onChange(of: viewModel.connectedDevice) { _, device in
            guard let device else { return }
            onConnected(device)
            dismiss()
        }
        .alert(
            viewModel.connectingDevice?.nama ?? "Perangkat",
            isPresented: connectingIsPresented
        ) {
            Button("Batalkan", role: .cancel) {
                viewModel.cancelConnecting()
            }
        } message: {
            Text("Menghubungkan…")
        }
        .alert(
            "Perangkat",
            isPresented: errorIsPresented,
            presenting: viewModel.errorMessage
        ) { _ in
            Button("Tutup", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.devices.isEmpty {
            if viewModel.isScanning {
                ProgressView("Mencari perangkat…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView {
                    Label("Perangkat tidak ditemukan", systemImage: "antenna.radiowaves.left.and.right.slash")
                } description: {
                    Text("Nyalakan perangkat dan Bluetooth, lalu cari ulang.")
                } actions: {
                    Button("Cari Ulang") {
                        Task { await viewModel.scan() }
                    }
                }
            }
        } else {
            List {
                Section {
                    ForEach(viewModel.devices) { device in
                        DeviceRow(device: device) {
                            Task { await viewModel.connect(device) }
                        }
                    }
                } footer: {
                    if viewModel.isScanning {
                        Label("Mencari perangkat…", systemImage: "dot.radiowaves.left.and.right")
                    }
                }
            }
        }
    }

    private var connectingIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.connectingDevice != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelConnecting()
                }
            }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }
}

private struct DeviceRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let device: DiscoveredDevice
    let onConnect: () -> Void

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        layout {
            Text(device.nama)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Button("Hubungkan", action: onConnect)
                .buttonStyle(.borderless)
                .accessibilityLabel("Hubungkan \(device.nama)")
        }
    }
}

#Preview("Mencari") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DeviceListSheetView(service: SimulatedDeviceConnectionService())
        }
}

#Preview("Accessibility 5") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DeviceListSheetView(service: SimulatedDeviceConnectionService(discoveryDelay: .milliseconds(100)))
        }
        .dynamicTypeSize(.accessibility5)
}
