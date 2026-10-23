//
//  AppTab.swift
//  Selaras
//

/// Top-level sections shown in the tab bar. `Riwayat` is not a tab: it is pushed from `Proyek`.
enum AppTab: CaseIterable {
    case resep
    case proyek

    var title: String {
        switch self {
        case .resep: "Resep"
        case .proyek: "Proyek"
        }
    }

    var systemImage: String {
        switch self {
        case .resep: "fork.knife"
        case .proyek: "folder"
        }
    }
}
