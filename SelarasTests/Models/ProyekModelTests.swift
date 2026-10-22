//
//  ProyekModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@Suite("Proyek color measurements")
@MainActor
struct ProyekModelTests {
    @Test("Displays initial measurements before scanning")
    func displaysInitialMeasurementsBeforeScanning() {
        let measurements = ProyekColorMeasurements.selectedColor

        #expect(measurements.initial.map(\.title) == [
            "Kepekatan Warna Awal",
            "Batas Kepekatan Warna",
            "pH Air Awal",
            "Batas pH",
        ])
    }

    @Test("Displays current measurements before their initial values")
    func displaysCurrentMeasurementsBeforeInitialValues() {
        let measurements = ProyekColorMeasurements.selectedColor

        #expect(measurements.displayedMeasurements.map(\.title) == [
            "Kepekatan Warna Sekarang",
            "Kepekatan Warna Awal",
            "Batas Kepekatan Warna",
            "pH Air Sekarang",
            "pH Air Awal",
            "Batas pH",
        ])
    }

    @Test("Calculates current concentration relative to initial sensor reading")
    func calculatesCurrentConcentrationRelativeToInitialSensorReading() {
        let measurements = ProyekColorMeasurements.selectedColor
            .withCurrentConcentration(
                ColorMeasurement(visibleAverage: 735, clear: 1200, nir: 200),
                relativeTo: 1000
            )

        #expect(measurements.initial.first?.value == "100%")
        #expect(measurements.current.first?.value == "73.5%")
    }
}
