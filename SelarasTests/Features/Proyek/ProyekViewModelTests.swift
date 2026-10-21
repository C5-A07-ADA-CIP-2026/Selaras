//
//  ProyekViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ProyekViewModelTests {
    @Test func exposesModelMessage() {
        let model = ProyekModel(message: "Custom Proyek message")

        let viewModel = ProyekViewModel(model: model)

        #expect(viewModel.message == model.message)
    }
}
