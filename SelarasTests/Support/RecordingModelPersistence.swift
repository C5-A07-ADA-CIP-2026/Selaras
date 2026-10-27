//
//  RecordingModelPersistence.swift
//  SelarasTests
//

import Foundation
@testable import Selaras
import SwiftData

struct StubSaveError: LocalizedError {
    var errorDescription: String? {
        "disk penuh"
    }
}

/// A `ModelPersisting` test double that records every call and can fail on `save()`.
final class RecordingModelPersistence: ModelPersisting {
    enum Event: Equatable {
        case insert
        case delete
        case save
    }

    private(set) var events: [Event] = []
    private(set) var insertedModels: [any PersistentModel] = []
    private(set) var deletedModels: [any PersistentModel] = []
    var saveError: (any Error)?

    func insert(_ model: some PersistentModel) {
        events.append(.insert)
        insertedModels.append(model)
    }

    func delete(_ model: some PersistentModel) {
        events.append(.delete)
        deletedModels.append(model)
    }

    func save() throws {
        events.append(.save)
        if let saveError {
            throw saveError
        }
    }
}

/// Identity comparison for models. Written out here because `(model as AnyObject) === other` inside `#expect`
/// crashes the Swift 6.4 compiler.
func isSameModel(_ recorded: any PersistentModel, _ expected: any PersistentModel) -> Bool {
    ObjectIdentifier(recorded as AnyObject) == ObjectIdentifier(expected as AnyObject)
}
