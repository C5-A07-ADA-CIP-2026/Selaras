//
//  ProyekView.swift
//  Selaras
//

import SwiftUI

struct ProyekView: View {
    let viewModel = ProyekViewModel()

    var body: some View {
        Text(viewModel.message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Proyek")
    }
}

#Preview {
    NavigationStack {
        ProyekView()
    }
}
