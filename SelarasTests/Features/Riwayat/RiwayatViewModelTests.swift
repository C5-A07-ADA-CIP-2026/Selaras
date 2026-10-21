//
//  RiwayatViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct RiwayatViewModelTests {
    @Test func exposesModelMessage() {
        let model = RiwayatModel(message: "Custom Riwayat message")

        let viewModel = RiwayatViewModel(model: model)

        #expect(viewModel.message == model.message)
    }
}
