//
//  ConnectedDeviceView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 22/10/26.
//

import SwiftUI

struct ConnectedDeviceView: View {
    @State private var fabricAmount = 0
    @State private var isColorSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Perangkat")
                    .font(.title3.weight(.semibold))

                HStack {
                    Text(Image(systemName: "wifi"))
                    Text("ESP 32")
                }
                .fontWeight(.semibold)
                .foregroundStyle(.blue)

                Divider()
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Warna")
                    .font(.title3.weight(.semibold))

                if isColorSelected {
                    // pilih resep
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ungu")
                            .italic()
                            .font(.headline)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(.indigo)
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .accessibilityLabel("Warna indigo")
                    }

                    VStack(spacing: 16) {
                        HStack {
                            Text("Kepekatan Warna Awal")

                            Spacer()

                            Text("100%")
                        }
                        HStack {
                            Text("Batas Kepekatan Warna")

                            Spacer()

                            Text("95%")
                        }
                        HStack {
                            Text("pH Air Awal")

                            Spacer()

                            Text("12")
                        }
                        HStack {
                            Text("Batas pH")

                            Spacer()

                            Text("10")
                        }
                    }
                } else {
                    Button {
                        isColorSelected = true
                    } label: {
                        Label("Pilih Warna", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            HStack {
                Text("Jumlah Kain")
                    .font(.title3.weight(.semibold))

                Spacer()

                Stepper(value: $fabricAmount, in: 0 ... Int.max, step: 1) {
                    Text("\(fabricAmount)")
                        .monospacedDigit()
                        .accessibilityLabel("Jumlah kain")
                }
                .accessibilityValue("\(fabricAmount)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()
        if isColorSelected, fabricAmount > 0 {
            Button {
                // TODO: Pindai data di ESP32.
            } label: {
                Text("Pindai Data")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

#Preview {
    ConnectedDeviceView()
}
