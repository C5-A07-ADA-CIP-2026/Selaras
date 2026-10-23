//
//  RiwayatProyekTests.swift
//  SelarasTests
//

import Foundation
@testable import Selaras
import SwiftData
import Testing

@Suite("RiwayatProyek")
@MainActor
struct RiwayatProyekTests {
    private func makeProyek(
        namaWarna: String = "Merah Marun",
        catatan: String = "Pesanan Bu Siti",
        warnaHex: String = "#b50202",
        kepekatan: Double = 95,
        batasPH: Double = 10,
        tanggal: Date = .now
    ) -> Proyek {
        let resep = Resep(
            namaWarna: namaWarna, catatan: catatan, warnaHex: warnaHex,
            air: 1000, kepekatan: kepekatan, batasPH: batasPH
        )
        return Proyek(resep: resep, jumlahKain: 2, kepekatanAkhir: 90, phAkhir: 7, tanggal: tanggal)
    }

    @Test("Maps a saved project to a display row")
    func mapsProyekToRow() {
        let proyek = makeProyek()

        let row = RiwayatProyek(proyek: proyek)

        #expect(row.details == "Merah Marun (Pesanan Bu Siti)")
        #expect(row.colorTresholdText == "95%")
        #expect(row.phTresholdText == "10")
        #expect(row.hexColor == "#b50202")
        #expect(row.id == proyek.id)
    }

    @Test("Shows only the color name when the note is empty")
    func omitsEmptyCatatan() {
        let row = RiwayatProyek(proyek: makeProyek(catatan: ""))

        #expect(row.details == "Merah Marun")
    }

    @Test("Formats a fractional pH threshold without trailing zeros")
    func formatsFractionalPHThreshold() {
        let row = RiwayatProyek(proyek: makeProyek(batasPH: 7.5))

        #expect(row.phTresholdText == "7.5")
    }

    @Test("Formats the date in Indonesian")
    func formatsDateInIndonesian() throws {
        let components = DateComponents(year: 2026, month: 10, day: 22, hour: 12)
        let tanggal = try #require(Calendar.current.date(from: components))

        let row = RiwayatProyek(proyek: makeProyek(tanggal: tanggal))

        #expect(row.formattedDate == "Kamis, 22 Oktober")
    }

    @Test("Fetches the newest project first")
    func terbaruDuluOrdersNewestFirst() throws {
        let context = try makeTestContext()
        let now = Date.now
        let lama = now.addingTimeInterval(-86400 * 2)
        let tengah = now.addingTimeInterval(-86400)
        for tanggal in [tengah, now, lama] {
            context.insert(makeProyek(tanggal: tanggal))
        }
        try context.save()

        let hasil = try context.fetch(Proyek.terbaruDulu)

        #expect(hasil.map(\.tanggal) == [now, tengah, lama])
    }
}
