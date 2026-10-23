//
//  ResepRowView.swift
//  Selaras
//

import SwiftUI

struct ResepRowView: View {
    let resep: Resep

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: resep.warnaHex))
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(resep.namaWarna)
                    .font(.headline)
                Text(resep.catatan)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ResepRowView(
        resep: Resep(
            namaWarna: "Merah Marun",
            catatan: "Untuk kain katun",
            warnaHex: "#B50202",
            air: 1000,
            kepekatan: 80,
            batasPH: 7
        )
    )
    .padding()
}

#Preview("Accessibility 5") {
    ResepRowView(
        resep: Resep(
            namaWarna: "Merah Marun",
            catatan: "Untuk kain katun",
            warnaHex: "#B50202",
            air: 1000,
            kepekatan: 80,
            batasPH: 7
        )
    )
    .padding()
    .dynamicTypeSize(.accessibility5)
}
