//
//  ResepViewModel.swift
//  Selaras
//

struct ResepViewModel {
    private let model: ResepModel

    init(model: ResepModel = .defaultContent) {
        self.model = model
    }

    var message: String {
        model.message
    }
}
