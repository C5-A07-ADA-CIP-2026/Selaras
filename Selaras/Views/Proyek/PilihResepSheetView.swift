//
//  PilihResepSheetView.swift
//  Selaras
//

import SwiftData
import SwiftUI

struct PilihResepSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Resep.dibuat, order: .reverse) private var daftar: [Resep]

    let onSelect: (Resep) -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pilih Warna")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Tutup", systemImage: "xmark")
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if daftar.isEmpty {
            ContentUnavailableView(
                "Belum ada warna",
                systemImage: "book",
                description: Text("Tambahkan warna di tab Resep dulu.")
            )
        } else {
            List(daftar) { resep in
                Button {
                    onSelect(resep)
                    dismiss()
                } label: {
                    ResepRowView(resep: resep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Berisi") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PilihResepSheetView { _ in }
        }
        .modelContainer(previewContainer)
}

#Preview("Kosong") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PilihResepSheetView { _ in }
        }
        .modelContainer(for: SelarasSchema.models, inMemory: true)
}

#Preview("Accessibility 5") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PilihResepSheetView { _ in }
        }
        .modelContainer(previewContainer)
        .dynamicTypeSize(.accessibility5)
}

#Preview("Kosong Accessibility 5") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PilihResepSheetView { _ in }
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
