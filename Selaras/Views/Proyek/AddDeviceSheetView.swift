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
    @State private var isConnecting = false
    @State private var isConnected = false

    init(isDeviceFound: Bool = false) {
        _isDeviceFound = State(initialValue: isDeviceFound)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack {
                    Text(statusText)
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

                Button {
                    if isConnected {
                        dismiss()
                        return
                    }

                    isConnecting = true

                    Task {
                        // MARK: Placeholder connection delay

                        do {
                            try await Task.sleep(for: .seconds(2))
                            isConnecting = false
                            isConnected = true
                        } catch is CancellationError {
                            return
                        } catch {
                            return
                        }
                    }
                } label: {
                    Label(isConnected ? "Selesai" : "Sambungkan", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isDeviceFound || isConnecting)
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

    private var statusText: String {
        if isConnected {
            return "Perangkat telah tersambung"
        }

        if isConnecting {
            return "Menyambungkan perangkat…"
        }

        return isDeviceFound ? "Perangkat ditemukan." : "Mencari perangkat..."
    }
}
