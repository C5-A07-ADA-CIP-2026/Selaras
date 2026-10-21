//
//  AddDeviceSheetView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct AddDeviceSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isDeviceFound: Bool

    init(isDeviceFound: Bool = false) {
        _isDeviceFound = State(initialValue: isDeviceFound)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack {
                    Text(isDeviceFound ? "Perangkat ditemukan." : "Mencari perangkat...")
                        .font(.subheadline.weight(.semibold))
                    Text("ESP 32 - A")
                        .font(.largeTitle.weight(.bold))
                }

                if isDeviceFound {
                    Image("ESP32C3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                        .accessibilityLabel("Perangkat ESP32-C3")
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .accessibilityLabel("Mencari perangkat")
                }

                Spacer()

                Button {} label: {
                    Label("Sambungkan", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isDeviceFound)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                guard !isDeviceFound else { return }

                // MARK: Placeholder delay

                do {
                    try await Task.sleep(for: .seconds(2))
                    isDeviceFound = true
                } catch is CancellationError {
                    return
                } catch {
                    return
                }
            }
            .navigationTitle("Sambungkan Perangkat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Tutup")
                }
            }
        }
    }
}
