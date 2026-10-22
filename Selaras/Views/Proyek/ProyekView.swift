//
//  ProyekView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct ProyekView: View {
    @StateObject private var viewModel = ProyekViewModel()
    @State private var isShowingAddDeviceSheet = false

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isDeviceConnected {
                ConnectedDeviceView()
            } else {
                EmptyDeviceView()

                Button {
                    isShowingAddDeviceSheet = true
                } label: {
                    Label("Tambah Perangkat", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .navigationTitle("Proyek")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RiwayatView()
                } label: {
                    Label(
                        "Riwayat",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
            }
        }
        .sheet(isPresented: $isShowingAddDeviceSheet) {
            AddDeviceSheetView {
                viewModel.markDeviceAsConnected()
            }
            .presentationDetents([.medium])
            .presentationBackground(.background)
        }
    }
}

#Preview {
    NavigationStack {
        ProyekView()
    }
}

#Preview("Accessibility size") {
    NavigationStack {
        ProyekView()
    }
    .dynamicTypeSize(.accessibility5)
}
