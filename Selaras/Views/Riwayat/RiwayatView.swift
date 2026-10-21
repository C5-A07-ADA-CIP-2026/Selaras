//
//  RiwayatView.swift
//  Selaras
//

import SwiftUI

struct RiwayatView: View {
    var body: some View {
        Text("Halaman Riwayat")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Riwayat")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RiwayatView()
    }
}
