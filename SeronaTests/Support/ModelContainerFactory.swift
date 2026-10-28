//
//  ModelContainerFactory.swift
//  SeronaTests
//

@testable import Serona
import SwiftData

/// Containers must outlive their contexts: a `ModelContext` does not retain its container,
/// and using one after the container is released traps. Tests are short-lived and the
/// containers are in-memory, so they are simply kept for the whole test process.
@MainActor private var retainedContainers: [ModelContainer] = []

@MainActor
func makeTestContext() throws -> ModelContext {
    let container = try SeronaSchema.makeContainer(inMemory: true)
    retainedContainers.append(container)
    return ModelContext(container)
}

extension Resep {
    static func sample(
        namaWarna: String = "Ungu",
        warnaHex: String = "#4B0082",
        batasKepekatan: Double = 80,
        batasPH: Double = 7
    ) -> Resep {
        Resep(
            namaWarna: namaWarna,
            warnaHex: warnaHex,
            air: 1000,
            kepekatan: batasKepekatan,
            batasPH: batasPH
        )
    }
}
