//
//  ProyekView.swift
//  Selaras
//

import SwiftUI

struct ProyekView: View {
    var body: some View {
        Text("Halaman Proyek")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Proyek")
    }
}

#Preview {
    NavigationStack {
        ProyekView()
    }
}
