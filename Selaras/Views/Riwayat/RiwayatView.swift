//
//  RiwayatView.swift
//  Selaras
//

import SwiftData
import SwiftUI

struct RiwayatView: View {
    @Query(Proyek.terbaruDulu) private var daftarProyek: [Proyek]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var ukuranSwatch = 24.0

    private var riwayatList: [RiwayatProyek] {
        daftarProyek.map(RiwayatProyek.init(proyek:))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Riwayat")
    }

    @ViewBuilder
    private var content: some View {
        if riwayatList.isEmpty {
            ContentUnavailableView(
                "Belum ada riwayat",
                systemImage: "clock.arrow.circlepath",
                description: Text("Proyek yang disimpan akan muncul di sini.")
            )
        } else {
            List {
                Section {
                    ForEach(riwayatList) { item in
                        row(for: item)
                    }
                } header: {
                    Text("Riwayat Proyek")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 4)
                }
            }
        }
    }

    private func row(for item: RiwayatProyek) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                batasRow(title: "Batas Kepekatan Warna", value: item.colorTresholdText)

                Divider()

                batasRow(title: "Batas pH", value: item.phTresholdText)
            }
        } label: {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                RoundedRectangle(cornerRadius: 6)
                    .fill(item.color)
                    .frame(width: ukuranSwatch, height: ukuranSwatch)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(item.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Side by side at regular sizes, stacked at accessibility sizes so long titles do not wrap mid-word.
    private func batasRow(title: String, value: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        return layout {
            Text(title)
                .foregroundStyle(.primary)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

#Preview("Kosong") {
    NavigationStack {
        RiwayatView()
    }
    .modelContainer(for: SelarasSchema.models, inMemory: true)
}

#Preview("Berisi") {
    NavigationStack {
        RiwayatView()
    }
    .modelContainer(previewContainer)
}

#Preview("Accessibility 5") {
    NavigationStack {
        RiwayatView()
    }
    .modelContainer(previewContainer)
    .dynamicTypeSize(.accessibility5)
}

#Preview("Kosong Accessibility 5") {
    NavigationStack {
        RiwayatView()
    }
    .modelContainer(for: SelarasSchema.models, inMemory: true)
    .dynamicTypeSize(.accessibility5)
}

@MainActor
private let previewContainer: ModelContainer = {
    // swiftlint:disable:next force_try
    let container = try! SelarasSchema.makeContainer(inMemory: true)
    let marun = Resep(
        namaWarna: "Merah Marun", catatan: "Pesanan Bu Siti", warnaHex: "#B50202",
        air: 1000, kepekatan: 95, batasPH: 10
    )
    let pink = Resep(
        namaWarna: "Pink", catatan: "", warnaHex: "#F4A9B4",
        air: 1000, kepekatan: 90, batasPH: 7.5
    )
    container.mainContext.insert(Proyek(
        resep: marun, jumlahKain: 2, kepekatanAkhir: 94, phAkhir: 9, tanggal: .now
    ))
    container.mainContext.insert(Proyek(
        resep: pink, jumlahKain: 1, kepekatanAkhir: 88, phAkhir: 7,
        tanggal: .now.addingTimeInterval(-86400 * 3)
    ))
    return container
}()
