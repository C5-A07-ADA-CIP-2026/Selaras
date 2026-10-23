//
//  ConnectedDeviceView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 22/10/26.
//

import SwiftUI

struct ConnectedDeviceView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let selectedResep: Resep?
    let measurements: ProyekColorMeasurements?
    let isDataScanned: Bool
    let isScanning: Bool
    @Binding var jumlahKain: Int

    private let onPickColor: () -> Void
    private let onScanData: () -> Void
    private let onSaveProject: () -> Void

    init(
        selectedResep: Resep? = nil,
        measurements: ProyekColorMeasurements? = nil,
        isDataScanned: Bool = false,
        isScanning: Bool = false,
        jumlahKain: Binding<Int>,
        onPickColor: @escaping () -> Void = {},
        onScanData: @escaping () -> Void = {},
        onSaveProject: @escaping () -> Void = {}
    ) {
        self.selectedResep = selectedResep
        self.measurements = measurements
        self.isDataScanned = isDataScanned
        self.isScanning = isScanning
        _jumlahKain = jumlahKain
        self.onPickColor = onPickColor
        self.onScanData = onScanData
        self.onSaveProject = onSaveProject
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                details
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if selectedResep != nil, jumlahKain > 0 {
                Button {
                    if isDataScanned {
                        onSaveProject()
                    } else {
                        onScanData()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isScanning {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(primaryButtonTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(isScanning ? "Memindai data" : primaryButtonTitle)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isScanning)
            }
        }
    }

    private var primaryButtonTitle: String {
        isDataScanned ? "Simpan Proyek" : "Pindai Data"
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Perangkat")
                    .font(.title3.weight(.semibold))

                Label("ESP 32", systemImage: "wifi")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)

                Divider()
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Warna")
                    .font(.title3.weight(.semibold))

                if let selectedResep, let measurements {
                    SelectedColorView(
                        resep: selectedResep,
                        measurements: measurements,
                        isDataScanned: isDataScanned,
                        onPickColor: onPickColor
                    )
                } else {
                    Button(action: onPickColor) {
                        Label("Pilih Warna", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            jumlahKainRow
        }
    }

    private var jumlahKainRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        return layout {
            Text("Jumlah Kain")
                .font(.title3.weight(.semibold))

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Stepper(value: $jumlahKain, in: 0 ... Int.max, step: 1) {
                Text("\(jumlahKain)")
                    .monospacedDigit()
                    .accessibilityLabel("Jumlah kain")
            }
            .accessibilityValue("\(jumlahKain)")
        }
    }
}

private struct SelectedColorView: View {
    let resep: Resep
    let measurements: ProyekColorMeasurements
    let isDataScanned: Bool
    let onPickColor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(resep.namaWarna)
                    .font(.headline)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: resep.warnaHex))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .accessibilityElement()
                    .accessibilityLabel("Warna \(resep.namaWarna)")

                Button("Ganti Warna", action: onPickColor)
                    .buttonStyle(.bordered)
            }

            VStack(spacing: 16) {
                ForEach(displayedMeasurements) { measurement in
                    MeasurementRow(measurement: measurement)
                }
            }
        }
    }

    private var displayedMeasurements: [ProyekMeasurement] {
        if isDataScanned {
            return measurements.displayedMeasurements
        }

        return measurements.initial
    }
}

private struct MeasurementRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let measurement: ProyekMeasurement

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        layout {
            Text(measurement.title)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Text(measurement.value)
                .monospacedDigit()
        }
        .fontWeight(measurement.isCurrent ? .semibold : .regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Belum pilih warna") {
    ConnectedDeviceView(jumlahKain: .constant(0))
        .padding(.horizontal, 24)
}

#Preview("Sebelum pindai") {
    ConnectedDeviceView(
        selectedResep: .previewSample,
        measurements: .preview,
        jumlahKain: .constant(2)
    )
    .padding(.horizontal, 24)
}

#Preview("Setelah pindai") {
    ConnectedDeviceView(
        selectedResep: .previewSample,
        measurements: .preview,
        isDataScanned: true,
        jumlahKain: .constant(2)
    )
    .padding(.horizontal, 24)
}

#Preview("Memindai") {
    ConnectedDeviceView(
        selectedResep: .previewSample,
        measurements: .preview,
        isScanning: true,
        jumlahKain: .constant(2)
    )
    .padding(.horizontal, 24)
}

#Preview("Memindai accessibility size") {
    ConnectedDeviceView(
        selectedResep: .previewSample,
        measurements: .preview,
        isScanning: true,
        jumlahKain: .constant(2)
    )
    .padding(.horizontal, 24)
    .dynamicTypeSize(.accessibility5)
}

#Preview("Accessibility size") {
    ConnectedDeviceView(
        selectedResep: .previewSample,
        measurements: .preview,
        isDataScanned: true,
        jumlahKain: .constant(2)
    )
    .padding(.horizontal, 24)
    .dynamicTypeSize(.accessibility5)
}

private extension ProyekColorMeasurements {
    static let preview = ProyekColorMeasurements(colorConcentrationLimit: 80, waterPHLimit: 7)
}

private extension Resep {
    static var previewSample: Resep {
        Resep(
            namaWarna: "Merah Marun", catatan: "Seragam Bu Dina", warnaHex: "#B50202",
            air: 1000, kepekatan: 80, batasPH: 7
        )
    }
}
