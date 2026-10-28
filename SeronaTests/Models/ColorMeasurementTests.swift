//
//  ColorMeasurementTests.swift
//  SeronaTests
//

@testable import Serona
import Testing

@Suite("Color measurement concentration")
@MainActor
struct ColorMeasurementTests {
    private let measurement = ColorMeasurement(visibleAverage: 735, clear: 1200, nir: 200)

    @Test("Concentration is the percentage of the baseline")
    func concentrationRelativeToBaseline() {
        #expect(measurement.concentration(relativeTo: 1000) == 73.5)
    }

    @Test("Concentration is nil without a positive baseline")
    func concentrationNeedsPositiveBaseline() {
        #expect(measurement.concentration(relativeTo: 0) == nil)
        #expect(measurement.concentration(relativeTo: -5) == nil)
    }

    @Test("Formatted concentration uses one decimal and falls back to 0.0%")
    func formattedConcentration() {
        #expect(measurement.formattedConcentration(relativeTo: 1000) == "73.5%")
        #expect(measurement.formattedConcentration(relativeTo: 735) == "100.0%")
        #expect(measurement.formattedConcentration(relativeTo: 0) == "0.0%")
    }
}
