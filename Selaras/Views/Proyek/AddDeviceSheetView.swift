//
//  AddDeviceSheetView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct AddDeviceSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddDeviceViewModel
    private let onConnected: () -> Void

    init(
        initialState: DeviceConnectionState = .searching,
        service: any DeviceConnectionService = SimulatedDeviceConnectionService(),
        onConnected: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: AddDeviceViewModel(
                initialState: initialState,
                service: service
            )
        )
        self.onConnected = onConnected
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack {
                    Text(statusText)
                        .font(.subheadline.weight(.semibold))
                    Text("ESP 32 - A")
                        .font(.largeTitle.weight(.bold))
                }

                if viewModel.isDeviceFound {
                    Image("ESP32C3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                        .accessibilityLabel("Perangkat ESP32-C3")
                } else if viewModel.state == .failed {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Perangkat tidak ditemukan")
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .accessibilityLabel("Mencari perangkat")
                }

                Spacer()

                Button {
                    if viewModel.state == .connected {
                        onConnected()
                        dismiss()
                    } else if viewModel.state == .failed {
                        Task {
                            await viewModel.discoverDevice()
                        }
                    } else {
                        Task {
                            await viewModel.connectDevice()
                        }
                    }
                } label: {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isConnecting || (!viewModel.isDeviceFound && viewModel.state != .failed))
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                await viewModel.discoverDevice()
            }
            .navigationTitle("Sambungkan Perangkat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Tutup")
                }
            }
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .connected:
            "Perangkat telah tersambung"
        case .connecting:
            "Menyambungkan perangkat…"
        case .failed:
            "Perangkat tidak ditemukan"
        case .found:
            "Perangkat ditemukan."
        case .searching:
            "Mencari perangkat..."
        }
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .connected:
            "Selesai"
        case .failed:
            "Coba Lagi"
        default:
            "Sambungkan"
        }
    }
}
