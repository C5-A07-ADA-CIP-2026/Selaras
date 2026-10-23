//
//  ProyekView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftData
import SwiftUI

struct ProyekView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProyekViewModel()
    @State private var isShowingAddDeviceSheet = false
    @State private var isShowingPilihResep = false

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isDeviceConnected {
                ConnectedDeviceView(
                    selectedResep: viewModel.selectedResep,
                    measurements: viewModel.measurements,
                    isDataScanned: viewModel.isDataScanned,
                    isScanning: viewModel.isScanning,
                    jumlahKain: $viewModel.jumlahKain,
                    onPickColor: { isShowingPilihResep = true },
                    onScanData: {
                        Task { await viewModel.scanData() }
                    },
                    onSaveProject: {
                        viewModel.saveProject(in: modelContext)
                    }
                )
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
            }
            .presentationDetents([.medium])
            .presentationBackground(.background)
        }
        .sheet(isPresented: $isShowingPilihResep) {
            PilihResepSheetView {
                viewModel.pilihResep($0)
            }
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
        .alert(
            "Kepekatan Warna Kurang",
            isPresented: concentrationWarningIsPresented
        ) {
            Button("Mengerti", role: .cancel) {
                viewModel.clearColorConcentrationWarning()
            }
        } message: {
            Text(viewModel.colorConcentrationWarning ?? "")
        }
        .alert(
            "pH Air Kurang",
            isPresented: waterPHWarningIsPresented
        ) {
            Button("Mengerti", role: .cancel) {
                viewModel.clearWaterPHWarning()
            }
        } message: {
            Text(viewModel.waterPHWarning ?? "")
        }
        .alert(
            "Proyek tersimpan",
            isPresented: projectSavedIsPresented
        ) {
            Button("Mengerti", role: .cancel) {
                viewModel.clearProjectSaved()
            }
        } message: {
            Text("Proyek dapat dilihat di Riwayat, lewat tombol di kanan atas halaman Proyek.")
        }
        .alert(
            "Gagal menyimpan proyek",
            isPresented: saveErrorIsPresented,
            presenting: viewModel.saveError
        ) { _ in
            Button("Tutup") {
                viewModel.clearSaveError()
            }
        } message: { error in
            Text(error)
        }
    }

    private var projectSavedIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.projectSaved },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearProjectSaved()
                }
            }
        )
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.saveError != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearSaveError()
                }
            }
        )
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

    private var concentrationWarningIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.colorConcentrationWarning != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearColorConcentrationWarning()
                }
            }
        )
    }

    private var waterPHWarningIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.waterPHWarning != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearWaterPHWarning()
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
