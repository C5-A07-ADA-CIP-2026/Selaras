//
//  ResepView.swift
//  Selaras
//

import SwiftUI

struct ResepView: View {
    let viewModel = ResepViewModel()

    var body: some View {
        Text(viewModel.message)
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
