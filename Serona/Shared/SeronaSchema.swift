//
//  SeronaSchema.swift
//  Serona
//

import SwiftData

enum SeronaSchema {
    static let models: [any PersistentModel.Type] = [Resep.self, Proyek.self]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }
}
