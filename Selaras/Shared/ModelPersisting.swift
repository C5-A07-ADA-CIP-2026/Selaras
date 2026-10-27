//
//  ModelPersisting.swift
//  Selaras
//

import SwiftData

/// The slice of `ModelContext` that view models need to save a model, so tests can substitute a double.
protocol ModelPersisting {
    func insert(_ model: some PersistentModel)
    func delete(_ model: some PersistentModel)
    func save() throws
}

extension ModelPersisting {
    /// Inserts and saves `model`. A failed save removes it again (a retry would otherwise duplicate it) and rethrows.
    func insertAndSave(_ model: some PersistentModel) throws {
        insert(model)
        do {
            try save()
        } catch {
            delete(model)
            throw error
        }
    }
}

extension ModelContext: ModelPersisting {}
