//
//  RiwayatModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct RiwayatModelTests {
    @Test func defaultContentIsPlaceholder() {
        #expect(RiwayatModel.defaultContent.message == "Halaman Riwayat")
    }
}
