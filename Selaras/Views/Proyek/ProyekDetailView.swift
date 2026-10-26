//
//  ProyekDetailView.swift
//  Selaras
//

import SwiftData
import SwiftUI

/// One project: its device, color and recipe, and the scan that finishes it.
struct ProyekDetailView: View {
    @State private var isShowingKonfirmasiSelesai = false
    @State private var isMemulai = false
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
        .overlay {
            if isMemulai {
                loadingOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isMemulai)
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
                isShowingDeviceList = true
            }
            Button("Tutup", role: .cancel) {
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
            }
        } message: {
            Text(viewModel.colorConcentrationWarning ?? "")
        }
        .alert(
            "pH Air Kurang",
            isPresented: isPresented(viewModel.waterPHWarning, clear: viewModel.clearWaterPHWarning)
        ) {
            Button("Mengerti", role: .cancel) {
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
            }
        } message: { error in
            Text(error)
        }
        .alert("Selesaikan Proyek?", isPresented: $isShowingKonfirmasiSelesai) {
            Button("Batal", role: .cancel) {}
            Button("Selesaikan") {
                viewModel.selesaikan(in: modelContext)
            }
        } message: {
            Text("Setelah selesai, proyek tidak bisa dipindai atau diubah lagi.")
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

            BarisInfo(judul: "Jumlah Kain", nilai: "\(proyek.jumlahKain)", tebal: true)

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
    
    private func mulai() {
        guard !isMemulai else { return }
        isMemulai = true
        Task {
            async let minimum: Void = Task.sleep(for: .seconds(1.5))
            await viewModel.mulaiPindai()
            try? await minimum
            isMemulai = false
        }
    }

    private var primaryButton: some View {
        Button {
            if viewModel.isDataScanned {
                isShowingKonfirmasiSelesai = true
            } else {
                mulai()
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
                    DispatchQueue.main.async { clear() }
                }
            }
        )
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)

                Text("Memulai pemindaian…")
                    .font(.headline)

                Text("Pastikan perangkat tetap menyala dan terhubung.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .combine)
        }
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
