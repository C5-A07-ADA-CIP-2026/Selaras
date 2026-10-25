//
//  ProyekSaveTests.swift
//  SelarasTests
//

@testable import Selaras
import SwiftData
import Testing

@MainActor
struct ProyekSaveTests {
    @Test("Saving stores a snapshot of the recipe and the final readings")
    func saveInsertsProyekSnapshot() async throws {
        let context = try makeTestContext()
        let resep = Resep.sample(namaWarna: "Merah Marun", batasKepekatan: 80, batasPH: 7)
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200, waterPH: 6.5)]
        ))
        viewModel.pilihResep(resep)
        viewModel.jumlahKain = 3
        await viewModel.scanData()
        let didStream = await waitUntil { viewModel.latestConcentration != nil }
        #expect(didStream)

        let didSave = viewModel.saveProject(in: context)

        #expect(didSave)
        let saved = try context.fetch(FetchDescriptor<Proyek>())
        #expect(saved.count == 1)
        let proyek = try #require(saved.first)
        #expect(proyek.namaWarna == "Merah Marun")
        #expect(proyek.batasKepekatan == 80)
        #expect(proyek.batasPH == 7)
        #expect(proyek.jumlahKain == 3)
        #expect(proyek.kepekatanAkhir == 85)
        #expect(proyek.phAkhir == 6.5)
        #expect(proyek.resep === resep)
        #expect(viewModel.saveError == nil)
    }

    @Test("Saving is refused until the data has been scanned")
    func saveRefusesWithoutScan() throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 3

        let didSave = viewModel.saveProject(in: context)

        #expect(!didSave)
        #expect(try context.fetch(FetchDescriptor<Proyek>()).isEmpty)
        #expect(!viewModel.projectSaved)
        #expect(viewModel.selectedResep != nil)
        #expect(viewModel.jumlahKain == 3)
    }

    @Test("Saving is refused without fabric")
    func saveRefusesWithZeroFabric() async throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.pilihResep(.sample())
        await viewModel.scanData()
        #expect(viewModel.isDataScanned)
        #expect(viewModel.jumlahKain == 0)

        let didSave = viewModel.saveProject(in: context)

        #expect(!didSave)
        #expect(try context.fetch(FetchDescriptor<Proyek>()).isEmpty)
        #expect(!viewModel.projectSaved)
        #expect(viewModel.isDataScanned)
    }

    @Test("Saving is refused without a recipe")
    func saveRefusesWithoutResep() throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.jumlahKain = 3

        let didSave = viewModel.saveProject(in: context)

        #expect(!didSave)
        #expect(try context.fetch(FetchDescriptor<Proyek>()).isEmpty)
        #expect(!viewModel.projectSaved)
    }

    @Test("Saving before any reading streamed stores no final values, not zero")
    func saveWithoutLiveReadingStoresNilFinalValues() async throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 2
        await viewModel.scanData()

        #expect(viewModel.saveProject(in: context))

        let proyek = try #require(context.fetch(FetchDescriptor<Proyek>()).first)
        #expect(proyek.kepekatanAkhir == nil)
        #expect(proyek.phAkhir == nil)
    }

    @Test("A sensor without pH stores a nil final pH, not zero")
    func saveWithoutPHReadingStoresNilPH() async throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200)]
        ))
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 2
        await viewModel.scanData()
        let didStream = await waitUntil { viewModel.latestConcentration != nil }
        #expect(didStream)

        #expect(viewModel.saveProject(in: context))

        let proyek = try #require(context.fetch(FetchDescriptor<Proyek>()).first)
        #expect(proyek.kepekatanAkhir == 85)
        #expect(proyek.phAkhir == nil)
    }

    @Test("After saving the form is ready for the next project and a second save does nothing")
    func saveResetsForNextProject() async throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200, waterPH: 6.5)]
        ))
        viewModel.markDeviceAsConnected()
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))
        viewModel.jumlahKain = 3
        await viewModel.scanData()
        let didWarn = await waitUntil {
            viewModel.colorConcentrationWarning != nil && viewModel.waterPHWarning != nil
        }
        #expect(didWarn)

        #expect(viewModel.saveProject(in: context))

        #expect(viewModel.projectSaved)
        #expect(viewModel.selectedResep == nil)
        #expect(viewModel.measurements == nil)
        #expect(viewModel.jumlahKain == 0)
        #expect(!viewModel.isDataScanned)
        #expect(viewModel.isDeviceConnected)
        #expect(viewModel.latestConcentration == nil)
        #expect(viewModel.latestWaterPH == nil)
        #expect(viewModel.colorConcentrationWarning == nil)
        #expect(viewModel.waterPHWarning == nil)

        // Double tap on "Simpan Proyek": nothing left to save.
        #expect(!viewModel.saveProject(in: context))
        #expect(try context.fetch(FetchDescriptor<Proyek>()).count == 1)
    }

    @Test("Readings arriving after saving cannot leak into the next project")
    func saveStopsTheMeasurementStream() async throws {
        let context = try makeTestContext()
        let (updates, liveReadings) = AsyncStream<ColorMeasurement>.makeStream()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(liveUpdates: updates))
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 1
        await viewModel.scanData()
        liveReadings.yield(ColorMeasurement(visibleAverage: 950, clear: 1200, nir: 200, waterPH: 7))
        let isStreaming = await waitUntil { viewModel.latestConcentration == 95 }
        #expect(isStreaming)
        #expect(viewModel.saveProject(in: context))

        liveReadings.yield(ColorMeasurement(visibleAverage: 500, clear: 1200, nir: 200, waterPH: 1))
        let didChange = await waitUntil(timeout: .milliseconds(300)) {
            viewModel.latestConcentration != nil
                || viewModel.latestWaterPH != nil
                || viewModel.measurements != nil
                || viewModel.colorConcentrationWarning != nil
                || viewModel.waterPHWarning != nil
        }

        #expect(!didChange)
    }

    @Test("Dismissing the confirmation clears the saved flag")
    func clearProjectSavedResetsFlag() async throws {
        let context = try makeTestContext()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 1
        await viewModel.scanData()
        #expect(viewModel.saveProject(in: context))
        #expect(viewModel.projectSaved)

        viewModel.clearProjectSaved()

        #expect(!viewModel.projectSaved)
    }

    @Test("A failed save reports the error, keeps the form and removes the inserted Proyek")
    func saveFailureKeepsFormAndDeletesProyek() async throws {
        let persistence = RecordingModelPersistence()
        persistence.saveError = StubSaveError()
        let resep = Resep.sample(batasKepekatan: 80, batasPH: 7)
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200, waterPH: 6.5)]
        ))
        viewModel.markDeviceAsConnected()
        viewModel.pilihResep(resep)
        viewModel.jumlahKain = 3
        await viewModel.scanData()
        let didStream = await waitUntil { viewModel.latestConcentration != nil }
        #expect(didStream)

        let didSave = viewModel.saveProject(in: persistence)

        #expect(!didSave)
        #expect(viewModel.saveError == "Gagal menyimpan proyek: disk penuh")
        #expect(!viewModel.projectSaved)
        #expect(viewModel.selectedResep === resep)
        #expect(viewModel.isDataScanned)
        #expect(viewModel.isDeviceConnected)
        #expect(viewModel.jumlahKain == 3)
        #expect(viewModel.measurements != nil)
        #expect(viewModel.latestConcentration == 85)
        #expect(viewModel.latestWaterPH == 6.5)
        #expect(persistence.events == [.insert, .save, .delete])
        let inserted = try #require(persistence.insertedModels.first as? Proyek)
        #expect(inserted.namaWarna == resep.namaWarna)
        #expect(inserted.jumlahKain == 3)
        #expect(isSameModel(persistence.deletedModels[0], inserted))
    }

    @Test("After a failed save a retry can succeed")
    func saveRetryAfterFailureSucceeds() async {
        let persistence = RecordingModelPersistence()
        persistence.saveError = StubSaveError()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        viewModel.pilihResep(.sample())
        viewModel.jumlahKain = 1
        await viewModel.scanData()
        #expect(!viewModel.saveProject(in: persistence))

        persistence.saveError = nil
        viewModel.clearSaveError()

        #expect(viewModel.saveProject(in: persistence))
        #expect(viewModel.saveError == nil)
        #expect(viewModel.projectSaved)
        #expect(viewModel.selectedResep == nil)
    }
}
