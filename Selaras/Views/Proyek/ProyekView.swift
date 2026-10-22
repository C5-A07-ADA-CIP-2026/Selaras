//
//  ProyekView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct ProyekView: View {
    @StateObject private var viewModel = ProyekViewModel()
    @State private var isShowingAddDeviceSheet = false

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isDeviceConnected {
                ConnectedDeviceView(measurements: viewModel.initialColorMeasurements)
            } else {
                EmptyDeviceView()

                Button {
                    isShowingAddDeviceSheet = true
                } label: {
                    Label("Tambah Perangkat", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .navigationTitle("Proyek")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RiwayatView()
                } label: {
                    Label(
                        "Riwayat",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
            }
        }
        .sheet(isPresented: $isShowingAddDeviceSheet) {
            AddDeviceSheetView {
                viewModel.markDeviceAsConnected()
                Task {
                    await viewModel.readInitialColorMeasurement()
                }
            }
            .presentationDetents([.medium])
            .presentationBackground(.background)
        }
        .alert(
            "Data warna tidak tersedia",
            isPresented: errorAlertIsPresented,
            presenting: viewModel.colorMeasurementError
        ) { _ in
            Button("Tutup") {
                viewModel.clearColorMeasurementError()
            }
        } message: { error in
            Text(error)
        }
    }

    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.colorMeasurementError != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearColorMeasurementError()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        ProyekView()
    }
}

#Preview("Accessibility size") {
    NavigationStack {
        ProyekView()
    }
    .dynamicTypeSize(.accessibility5)
}
