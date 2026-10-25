//
//  TambahProyekView.swift
//  Selaras
//

import SwiftData
import SwiftUI

/// "Tambahkan Proyek": name, device, color and amount of fabric of a new project.
struct TambahProyekView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TambahProyekViewModel()
    @State private var isShowingDeviceList = false
    @State private var isShowingPilihResep = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    namaField
                    perangkatSection
                    warnaSection
                    JumlahKainBaris(jumlahKain: $viewModel.jumlahKain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Tambahkan Proyek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.simpan(in: modelContext) != nil {
                            dismiss()
                        }
                    } label: {
                        Label("Simpan Proyek", systemImage: "arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
        .sheet(isPresented: $isShowingDeviceList) {
            DeviceListSheetView { viewModel.pilihPerangkat($0) }
        }
        .sheet(isPresented: $isShowingPilihResep) {
            PilihResepSheetView { viewModel.pilihResep($0) }
        }
        .alert(
            "Gagal menyimpan proyek",
            isPresented: saveErrorIsPresented,
            presenting: viewModel.saveError
        ) { _ in
            Button("Tutup", role: .cancel) {
                viewModel.clearSaveError()
            }
        } message: { error in
            Text(error)
        }
    }

    private var namaField: some View {
        VStack(alignment: .leading, spacing: 8) {
            JudulBagian(teks: "Nama Proyek")
            TextField("Cth: Seragam RT 5", text: $viewModel.nama)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
    }

    private var perangkatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let perangkat = viewModel.perangkat {
                PerangkatBaris(nama: perangkat.nama)
            } else {
                JudulBagian(teks: "Perangkat")
            }

            Button {
                isShowingDeviceList = true
            } label: {
                Label(
                    viewModel.perangkat == nil ? "Tambah Perangkat" : "Ganti Perangkat",
                    systemImage: viewModel.perangkat == nil ? "plus" : "arrow.triangle.2.circlepath"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var warnaSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            JudulBagian(teks: "Warna")

            if let resep = viewModel.resep {
                WarnaSwatchView(namaWarna: resep.namaWarna, warnaHex: resep.warnaHex) {
                    viewModel.hapusResep()
                }
                ResepWarnaView(pewarna: resep.pewarna, zatPembantu: resep.zatPembantu)
            } else {
                Button {
                    isShowingPilihResep = true
                } label: {
                    Label("Tambah Warna", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
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
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TambahProyekView()
        }
        .modelContainer(for: SelarasSchema.models, inMemory: true)
}

#Preview("Accessibility 5") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TambahProyekView()
        }
        .modelContainer(for: SelarasSchema.models, inMemory: true)
        .dynamicTypeSize(.accessibility5)
}
