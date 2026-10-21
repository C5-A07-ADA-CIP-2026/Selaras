//
//  ProyekModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ProyekModelTests {
    @Test func defaultContentIsPlaceholder() {
        #expect(ProyekModel.defaultContent.message == "Halaman Proyek")
    }
}
