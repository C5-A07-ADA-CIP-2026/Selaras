//
//  ProyekListView.swift
//  Selaras
//

import SwiftData
import SwiftUI

/// The Proyek tab: active projects first, then inactive (finished) ones.
struct ProyekListView: View {
    @Query(sort: \Proyek.tanggal, order: .reverse) private var semuaProyek: [Proyek]
    @State private var isShowingTambah = false

    private var daftar: ProyekDaftar {
        ProyekDaftar(semuaProyek)
    }

    var body: some View {
        content
            .navigationTitle("Proyek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingTambah = true
                    } label: {
                        Label("Tambah Proyek", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $isShowingTambah) {
                TambahProyekView()
            }
    }

    @ViewBuilder
    private var content: some View {
        let daftar = daftar
        if daftar.isEmpty {
            ContentUnavailableView(
                "Belum ada proyek",
                systemImage: "folder",
                description: Text("Tekan + untuk menambah proyek.")
            )
        } else {
            List {
                bagian("Aktif", proyek: daftar.aktif)
                bagian("Nonaktif", proyek: daftar.nonaktif)
            }
        }
    }

    @ViewBuilder
    private func bagian(_ judul: String, proyek: [Proyek]) -> some View {
        if !proyek.isEmpty {
            Section(judul) {
                ForEach(proyek) { item in
                    NavigationLink {
                        ProyekDetailView(proyek: item)
                    } label: {
                        ProyekRowView(proyek: item)
                    }
                }
            }
        }
    }
}

#Preview("Kosong") {
    NavigationStack {
        ProyekListView()
    }
    .modelContainer(for: SelarasSchema.models, inMemory: true)
}

#Preview("Berisi") {
    NavigationStack {
        ProyekListView()
    }
    .modelContainer(previewContainer)
}

#Preview("Accessibility 5") {
    NavigationStack {
        ProyekListView()
    }
    .modelContainer(previewContainer)
    .dynamicTypeSize(.accessibility5)
}

@MainActor
private let previewContainer: ModelContainer = {
    // swiftlint:disable:next force_try
    let container = try! SelarasSchema.makeContainer(inMemory: true)
    let resep = Resep(
        namaWarna: "Merah Marun", warnaHex: "#B50202",
        air: 1000, kepekatan: 80, batasPH: 7
    )
    container.mainContext.insert(Proyek(nama: "Seragam RT 5", perangkatNama: "ESP 32", resep: resep, jumlahKain: 2))
    container.mainContext.insert(Proyek(
        nama: "Taplak Meja", perangkatNama: "ESP 32", resep: resep, jumlahKain: 1,
        tanggal: .now.addingTimeInterval(-86400 * 3)
    ))
    let selesai = Proyek(
        nama: "Kain Panjang", perangkatNama: "ESP 32", resep: resep, jumlahKain: 3,
        tanggal: .now.addingTimeInterval(-86400 * 9)
    )
    selesai.selesaikan(kepekatanAkhir: 94, phAkhir: 9)
    container.mainContext.insert(selesai)
    return container
}()
