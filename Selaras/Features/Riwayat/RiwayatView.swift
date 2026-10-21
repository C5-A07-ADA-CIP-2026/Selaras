//
//  RiwayatView.swift
//  Selaras
//

import SwiftUI

struct RiwayatView: View {
    let viewModel = RiwayatViewModel()

    var body: some View {
        Text(viewModel.message)
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
