//
//  ProyekDetailView.swift
//  Selaras
//

import SwiftData
import SwiftUI

/// One project: its device, color and recipe, and the scan that finishes it.
struct ProyekDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ProyekDetailViewModel
    @Bindable private var proyek: Proyek
    @State private var isShowingDeviceList = false

    init(proyek: Proyek, service: (any ColorMeasurementSource)? = nil) {
        self.proyek = proyek
        _viewModel = StateObject(wrappedValue: ProyekDetailViewModel(proyek: proyek, service: service))
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                details
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if proyek.status == .aktif {
                primaryButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .navigationTitle(proyek.nama)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.berhenti()
        }
        .sheet(isPresented: $isShowingDeviceList) {
            DeviceListSheetView()
        }
        .alert(
            "Data warna tidak tersedia",
            isPresented: isPresented(viewModel.colorMeasurementError, clear: viewModel.clearColorMeasurementError),
            presenting: viewModel.colorMeasurementError
        ) { _ in
            Button("Sambungkan Ulang") {
                viewModel.clearColorMeasurementError()
                isShowingDeviceList = true
            }
            Button("Tutup", role: .cancel) {
                viewModel.clearColorMeasurementError()
            }
        } message: { error in
            Text(error)
        }
        .alert(
            "Kepekatan Warna Kurang",
            isPresented: isPresented(
                viewModel.colorConcentrationWarning,
                clear: viewModel.clearColorConcentrationWarning
            )
        ) {
            Button("Mengerti", role: .cancel) {
                viewModel.clearColorConcentrationWarning()
            }
        } message: {
            Text(viewModel.colorConcentrationWarning ?? "")
        }
        .alert(
            "pH Air Kurang",
            isPresented: isPresented(viewModel.waterPHWarning, clear: viewModel.clearWaterPHWarning)
        ) {
            Button("Mengerti", role: .cancel) {
                viewModel.clearWaterPHWarning()
            }
        } message: {
            Text(viewModel.waterPHWarning ?? "")
        }
        .alert(
            "Gagal menyimpan proyek",
            isPresented: isPresented(viewModel.saveError, clear: viewModel.clearSaveError),
            presenting: viewModel.saveError
        ) { _ in
            Button("Tutup", role: .cancel) {
                viewModel.clearSaveError()
            }
        } message: { error in
            Text(error)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            PerangkatBaris(nama: proyek.perangkatNama)

            VStack(alignment: .leading, spacing: 24) {
                JudulBagian(teks: "Warna")
                WarnaSwatchView(namaWarna: proyek.namaWarna, warnaHex: proyek.warnaHex)
                ResepWarnaView(pewarna: proyek.pewarna, zatPembantu: proyek.zatPembantu)
            }

            if proyek.status == .aktif {
                JumlahKainBaris(jumlahKain: $proyek.jumlahKain, minimum: 1)
            } else {
                BarisInfo(judul: "Jumlah Kain", nilai: "\(proyek.jumlahKain)", tebal: true)
            }

            if proyek.status == .nonaktif {
                hasilAkhir
            } else if viewModel.isDataScanned {
                pengukuran
            }
        }
    }

    private var pengukuran: some View {
        VStack(alignment: .leading, spacing: 16) {
            JudulBagian(teks: "Pengukuran")
            ForEach(viewModel.measurements.displayedMeasurements) { measurement in
                BarisInfo(judul: measurement.title, nilai: measurement.value, tebal: measurement.isCurrent)
            }
        }
    }

    private var hasilAkhir: some View {
        VStack(alignment: .leading, spacing: 16) {
            JudulBagian(teks: "Hasil Akhir")
            BarisInfo(
                judul: "Kepekatan Warna Akhir",
                nilai: proyek.kepekatanAkhir.map(Self.persen) ?? "—",
                tebal: true
            )
            BarisInfo(
                judul: "Batas Kepekatan Warna",
                nilai: "\(ProyekColorMeasurements.format(proyek.batasKepekatan))%"
            )
            BarisInfo(
                judul: "pH Air Akhir",
                nilai: proyek.phAkhir.map { ProyekColorMeasurements.format($0) } ?? "—",
                tebal: true
            )
            BarisInfo(judul: "Batas pH", nilai: ProyekColorMeasurements.format(proyek.batasPH))
        }
    }

    private var primaryButton: some View {
        Button {
            if viewModel.isDataScanned {
                viewModel.selesaikan(in: modelContext)
            } else {
                Task { await viewModel.mulaiPindai() }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else if !viewModel.isDataScanned {
                    Image(systemName: "plus")
                }
                Text(primaryButtonTitle)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.isScanning ? "Memindai data" : primaryButtonTitle)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isScanning)
    }

    private static func persen(_ value: Double) -> String {
        String(format: "%.1f%%", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private var primaryButtonTitle: String {
        viewModel.isDataScanned ? "Selesaikan Proyek" : "Mulai Pindai"
    }

    private func isPresented(_ message: String?, clear: @escaping () -> Void) -> Binding<Bool> {
        Binding(
            get: { message != nil },
            set: { isPresented in
                if !isPresented {
                    clear()
                }
            }
        )
    }
}

#Preview("Aktif") {
    NavigationStack {
        ProyekDetailView(proyek: .previewSample, service: SimulatedDeviceConnectionService())
    }
}

#Preview("Accessibility size") {
    NavigationStack {
        ProyekDetailView(proyek: .previewSample, service: SimulatedDeviceConnectionService())
    }
    .dynamicTypeSize(.accessibility5)
}

#Preview("Nonaktif") {
    let proyek = Proyek.previewSample
    proyek.selesaikan(kepekatanAkhir: 94.04, phAkhir: 9)
    return NavigationStack {
        ProyekDetailView(proyek: proyek, service: SimulatedDeviceConnectionService())
    }
}
