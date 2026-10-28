//
//  AppTab.swift
//  Serona
//

/// Top-level sections shown in the tab bar. Proyek comes first; the recipe list is shown to users as "Warna".
enum AppTab: CaseIterable {
    case proyek
    case resep

    var title: String {
        switch self {
        case .resep: "Warna"
        case .proyek: "Proyek"
        }
    }

    var systemImage: String {
        switch self {
        case .resep: "book"
        case .proyek: "folder"
        }
    }
}
