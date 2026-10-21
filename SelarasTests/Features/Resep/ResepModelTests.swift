//
//  ResepModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ResepModelTests {
    @Test func defaultContentIsPlaceholder() {
        #expect(ResepModel.defaultContent.message == "Halaman Resep")
    }
}
