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

private struct ConnectedDeviceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Perangkat")
                .font(.title2.weight(.semibold))

            HStack(spacing: 16) {
                Image("ESP32C3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .accessibilityLabel("Perangkat ESP32-C3")

                VStack(alignment: .leading, spacing: 4) {
                    Text("ESP 32")
                        .font(.headline)

                    Label("Tersambung", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }

                Spacer()
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
