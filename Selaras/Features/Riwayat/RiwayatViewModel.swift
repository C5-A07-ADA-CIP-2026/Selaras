//
//  RiwayatViewModel.swift
//  Selaras
//

struct RiwayatViewModel {
    private let model: RiwayatModel

    init(model: RiwayatModel = .defaultContent) {
        self.model = model
    }

    var message: String {
        model.message
    }
}
