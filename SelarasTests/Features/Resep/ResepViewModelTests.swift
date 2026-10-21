//
//  ResepViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ResepViewModelTests {
    @Test func exposesModelMessage() {
        let model = ResepModel(message: "Custom Resep message")

        let viewModel = ResepViewModel(model: model)

        #expect(viewModel.message == model.message)
    }
}
