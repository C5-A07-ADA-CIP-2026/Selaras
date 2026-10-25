//
//  FormResepViewModelTests.swift
//  SelarasTests
//

import Foundation
@testable import Selaras
import SwiftData
import SwiftUI
import Testing

@Suite("FormResepViewModel simpan")
@MainActor
struct FormResepViewModelTests {
    @Test("Inserts a Resep from the completed form")
    func simpanInsertsResepFromForm() throws {
        let context = try makeTestContext()
        let viewModel = FormResepViewModel()
        viewModel.namaWarna = "Merah Marun"
        viewModel.namaCatatan = "Seragam Bu Dina"
        viewModel.warnaDipilih = Color(hex: "#B50202")
        viewModel.ukuranAir = 200
        viewModel.kepekatan = 80
        viewModel.batasPH = 7
        viewModel.pewarna = [BahanInput(kode: "N-1", gram: 5)]
        viewModel.zatPembantu = [BahanInput(kode: "Kostik", gram: 2)]

        try viewModel.simpan(context: context)

        let hasil = try context.fetch(FetchDescriptor<Resep>())
        #expect(hasil.count == 1)
        let resep = try #require(hasil.first)
        #expect(resep.namaWarna == "Merah Marun")
        #expect(resep.catatan == "Seragam Bu Dina")
        #expect(resep.warnaHex == "#B50202")
        #expect(resep.air == 200)
        #expect(resep.kepekatan == 80)
        #expect(resep.batasPH == 7)
        #expect(resep.pewarna == [Bahan(kode: "N-1", gram: 5)])
        #expect(resep.zatPembantu == [Bahan(kode: "Kostik", gram: 2)])
    }

    @Test("Does nothing when the form is incomplete")
    func simpanDoesNothingWhenFormIncomplete() throws {
        let context = try makeTestContext()
        let viewModel = FormResepViewModel()

        try viewModel.simpan(context: context)

        let hasil = try context.fetch(FetchDescriptor<Resep>())
        #expect(hasil.count == 0)
    }

    @Test("A failed save rethrows and removes the inserted Resep")
    func simpanRethrowsAndDeletesResepOnSaveFailure() throws {
        let persistence = RecordingModelPersistence()
        persistence.saveError = StubSaveError()
        let viewModel = FormResepViewModel()
        viewModel.namaWarna = "Merah Marun"
        viewModel.namaCatatan = "Seragam Bu Dina"
        viewModel.warnaDipilih = Color(hex: "#B50202")
        viewModel.ukuranAir = 200
        viewModel.kepekatan = 80
        viewModel.batasPH = 7
        viewModel.pewarna = [BahanInput(kode: "N-1", gram: 5)]
        viewModel.zatPembantu = [BahanInput(kode: "Kostik", gram: 2)]

        #expect(throws: StubSaveError.self) {
            try viewModel.simpan(context: persistence)
        }

        #expect(persistence.events == [.insert, .save, .delete])
        let inserted = try #require(persistence.insertedModels.first as? Resep)
        #expect(inserted.namaWarna == "Merah Marun")
        #expect(isSameModel(persistence.deletedModels[0], inserted))
    }

    @Test("An incomplete form touches nothing in the persistence")
    func simpanIncompleteFormDoesNotTouchPersistence() throws {
        let persistence = RecordingModelPersistence()

        try FormResepViewModel().simpan(context: persistence)

        #expect(persistence.events.isEmpty)
    }
}
