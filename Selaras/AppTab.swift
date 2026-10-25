//
//  AppTab.swift
//  Selaras
//

/// Top-level sections shown in the tab bar. The recipe list is shown to users as "Warna".
enum AppTab: CaseIterable {
    case resep
    case proyek

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
