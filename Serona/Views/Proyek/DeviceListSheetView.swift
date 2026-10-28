//
//  DeviceListSheetView.swift
//  Serona
//

import SwiftUI

/// "Tambahkan Perangkat": the Serona devices nearby, each with a "Hubungkan" button.
struct DeviceListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DeviceListViewModel
    private let onConnected: (DiscoveredDevice) -> Void
    private let onDisconnected: (DiscoveredDevice) -> Void

    init(
        service: (any DeviceConnecting)? = nil,
        onConnected: @escaping (DiscoveredDevice) -> Void = { _ in },
        onDisconnected: @escaping (DiscoveredDevice) -> Void = { _ in }
    ) {
        _viewModel = State(wrappedValue: DeviceListViewModel(service: service))
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
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
                            Label("Cari Ulang", systemImage: "arrow.triangle.2.circlepath")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
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
        if viewModel.devices.isEmpty, viewModel.connectedDevice == nil {
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
                    if let connected = viewModel.connectedDevice {
                        ConnectedDeviceRow(device: connected) {
                            Task {
                                await viewModel.disconnect()
                                onDisconnected(connected)
                            }
                        }
                    }
                    ForEach(viewModel.devices.filter { $0.id != viewModel.connectedDevice?.id }) { device in
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
            .listStyle(.plain)
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

private struct ConnectedDeviceRow: View {
    let device: DiscoveredDevice
    let onDisconnect: () -> Void

    var body: some View {
        HStack {
            Label(device.nama, systemImage: "wifi")
                .foregroundStyle(.tint)

            Spacer()

            Button(action: onDisconnect) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Putuskan \(device.nama)")
        }
        .padding(.vertical, 4)
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
            Label(device.nama, systemImage: "wifi")
                .foregroundStyle(.primary)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Button(action: onConnect) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Hubungkan")
                }
                .font(.footnote)
                .fixedSize()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .accessibilityLabel("Hubungkan \(device.nama)")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DeviceListSheetView(service: SimulatedDeviceConnectionService(discoveryDelay: .milliseconds(200)))
        }
}
