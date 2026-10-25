//
//  AppTabTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct AppTabTests {
    @Test func resepIsTheFirstTab() {
        #expect(AppTab.allCases.first == .resep)
    }

    @Test func proyekFollowsResep() {
        #expect(AppTab.allCases == [.resep, .proyek])
    }

    @Test func tabsHaveTitles() {
        #expect(AppTab.resep.title == "Warna")
        #expect(AppTab.proyek.title == "Proyek")
    }

    @Test func tabsHaveIcons() {
        #expect(AppTab.resep.systemImage == "book")
        #expect(AppTab.proyek.systemImage == "folder")
    }
}
