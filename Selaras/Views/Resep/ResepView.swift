//
//  ResepView.swift
//  Selaras
//

import SwiftData
import SwiftUI

struct ResepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Resep.dibuat, order: .reverse) private var daftar: [Resep]
    @State private var showModal = false
    @State private var teksCari = ""
    @ScaledMetric(relativeTo: .largeTitle) private var ukuranIkon = 100.0

    private var hasilCari: [Resep] {
        daftar.cari(teksCari)
    }

    var body: some View {
        content
            .navigationTitle("Warna Saya")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $teksCari, prompt: "Cari Warna")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showModal = true
                    } label: {
                        Label("Tambah Warna", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showModal) {
                NavigationStack {
                    HalamanTambahResep()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if daftar.isEmpty {
            emptyState
        } else if hasilCari.isEmpty {
            ContentUnavailableView.search(text: teksCari)
        } else {
            List {
                ForEach(hasilCari) { resep in
                    ResepRowView(resep: resep)
                }
                .onDelete(perform: hapus)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book")
                .resizable()
                .scaledToFit()
                .frame(width: ukuranIkon, height: ukuranIkon)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Belum ada warna")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Tekan + untuk menambah warna")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hapus(at offsets: IndexSet) {
        let target = hasilCari
        for index in offsets {
            modelContext.delete(target[index])
        }
    }
}

#Preview("Kosong") {
    NavigationStack {
        ResepView()
    }
    .modelContainer(for: SelarasSchema.models, inMemory: true)
}

#Preview("Berisi") {
    NavigationStack {
        ResepView()
    }
    .modelContainer(previewContainer)
}

#Preview("Accessibility 5") {
    NavigationStack {
        ResepView()
    }
    .modelContainer(previewContainer)
    .dynamicTypeSize(.accessibility5)
}

#Preview("Kosong Accessibility 5") {
    NavigationStack {
        ResepView()
    }
    .modelContainer(for: SelarasSchema.models, inMemory: true)
    .dynamicTypeSize(.accessibility5)
}

@MainActor
private let previewContainer: ModelContainer = {
    // swiftlint:disable:next force_try
    let container = try! SelarasSchema.makeContainer(inMemory: true)
    container.mainContext.insert(Resep(
        namaWarna: "Merah Marun", catatan: "Seragam Bu Dina", warnaHex: "#B50202",
        air: 1000, kepekatan: 80, batasPH: 7
    ))
    container.mainContext.insert(Resep(
        namaWarna: "Biru Laut", catatan: "Untuk kain katun", warnaHex: "#0044AA",
        air: 1000, kepekatan: 80, batasPH: 7
    ))
    return container
}()
