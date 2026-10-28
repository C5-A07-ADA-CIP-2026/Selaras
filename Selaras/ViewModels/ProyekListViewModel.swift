//
//  ProyekListViewModel.swift
//  Selaras
//

import Foundation
import Observation

/// The Proyek list: deleting a finished project, after the user confirms it.
@MainActor
@Observable
final class ProyekListViewModel {
    private(set) var proyekAkanDihapus: Proyek?
    private(set) var deleteError: String?

    /// Asks for confirmation to delete `proyek`. Only inactive (finished) projects can be deleted.
    func mintaHapus(_ proyek: Proyek) {
        guard proyek.status == .nonaktif else { return }
        proyekAkanDihapus = proyek
    }

    func batalHapus() {
        proyekAkanDihapus = nil
    }

    /// Deletes the confirmed inactive project and saves. Returns `false` when it is not deletable or saving fails.
    @discardableResult
    func hapus(_ proyek: Proyek, in persistence: some ModelPersisting) -> Bool {
        proyekAkanDihapus = nil
        guard proyek.status == .nonaktif else { return false }
        persistence.delete(proyek)
        do {
            try persistence.save()
            return true
        } catch {
            deleteError = "Gagal menghapus proyek: \(error.localizedDescription)"
            return false
        }
    }

    func clearDeleteError() {
        deleteError = nil
    }
}
