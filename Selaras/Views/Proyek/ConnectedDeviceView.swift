//
//  ConnectedDeviceView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 22/10/26.
//

import SwiftUI

struct ConnectedDeviceView: View {
    let measurements: ProyekColorMeasurements?

    @State private var fabricAmount = 0
    @State private var isColorSelected = false
    @State private var isDataScanned = false

    private let onScanData: () -> Void
    private let onSaveProject: () -> Void

    init(
        measurements: ProyekColorMeasurements? = nil,
        onScanData: @escaping () -> Void = {},
        onSaveProject: @escaping () -> Void = {}
    ) {
        self.measurements = measurements
        self.onScanData = onScanData
        self.onSaveProject = onSaveProject
    }

    var body: some View {
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

                if isColorSelected, let measurements {
                    SelectedColorView(
                        measurements: measurements,
                        isDataScanned: isDataScanned
                    )
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
                if isDataScanned {
                    onSaveProject()
                } else {
                    isDataScanned = true
                    onScanData()
                }
            } label: {
                Text(
                    isDataScanned ? "Simpan Proyek" : "Pindai Data"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

private struct SelectedColorView: View {
    let measurements: ProyekColorMeasurements
    let isDataScanned: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
    let measurement: ProyekMeasurement

    var body: some View {
        HStack {
            Text(measurement.title)

            Spacer()

            Text(measurement.value)
                .monospacedDigit()
        }
        .fontWeight(measurement.isCurrent ? .semibold : .regular)
    }
}

#Preview {
    ConnectedDeviceView(measurements: .preview)
}

#Preview("Accessibility size") {
    ConnectedDeviceView(measurements: .preview)
        .dynamicTypeSize(.accessibility5)
}

private extension ProyekColorMeasurements {
    static let preview = ProyekColorMeasurements(colorConcentrationLimit: 80, waterPHLimit: 7)
}
