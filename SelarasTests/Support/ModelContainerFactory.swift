//
//  ModelContainerFactory.swift
//  SelarasTests
//

@testable import Selaras
import SwiftData

@MainActor
func makeTestContext() throws -> ModelContext {
    try ModelContext(SelarasSchema.makeContainer(inMemory: true))
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
            catatan: "Catatan \(namaWarna)",
            warnaHex: warnaHex,
            air: 1000,
            kepekatan: batasKepekatan,
            batasPH: batasPH
        )
    }
}
