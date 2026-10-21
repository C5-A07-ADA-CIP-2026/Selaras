//
//  ResepView.swift
//  Selaras
//

import SwiftUI

struct ResepView: View {
    var body: some View {
        Text("Halaman Resep")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Resep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        RiwayatView()
                    } label: {
                        Label("Riwayat", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        ResepView()
    }
}
