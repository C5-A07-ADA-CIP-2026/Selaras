//
//  ProyekViewModel.swift
//  Selaras
//

struct ProyekViewModel {
    private let model: ProyekModel

    init(model: ProyekModel = .defaultContent) {
        self.model = model
    }

    var message: String {
        model.message
    }
}
