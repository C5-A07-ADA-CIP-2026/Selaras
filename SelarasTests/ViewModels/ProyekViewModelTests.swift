//
//  ProyekViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ProyekViewModelTests {
    @Test func markingDeviceAsConnectedUpdatesProjectState() {
        let viewModel = ProyekViewModel()

        viewModel.markDeviceAsConnected()

        #expect(viewModel.isDeviceConnected)
    }

    @Test("Choosing a recipe takes its limits")
    func pilihResepSetsLimitsFromResep() {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())
        let resep = Resep.sample(batasKepekatan: 90, batasPH: 7.5)

        viewModel.pilihResep(resep)

        #expect(viewModel.selectedResep === resep)
        #expect(viewModel.measurements?.colorConcentrationLimit == 90)
        #expect(viewModel.measurements?.waterPHLimit == 7.5)
        #expect(!viewModel.isDataScanned)
    }

    @Test("Nothing is measured until a recipe is chosen")
    func startsWithoutRecipe() {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService())

        #expect(viewModel.selectedResep == nil)
        #expect(viewModel.measurements == nil)
        #expect(!viewModel.isDataScanned)
        #expect(viewModel.jumlahKain == 0)
    }

    @Test("Scanning reads the initial measurement and streams current values")
    func scanDataStreamsCurrentValues() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            initial: ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200, waterPH: 11),
            updates: [ColorMeasurement(visibleAverage: 735, clear: 1200, nir: 200, waterPH: 10.5)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 80, batasPH: 7))

        await viewModel.scanData()
        let didUpdate = await waitUntil { viewModel.measurements?.current.first?.value == "73.5%" }

        #expect(didUpdate)
        #expect(viewModel.isDataScanned)
        #expect(viewModel.measurements?.initial[0].value == "100%")
        #expect(viewModel.measurements?.initial[2].value == "11")
        #expect(viewModel.measurements?.current[1].value == "10.5")
        #expect(viewModel.latestConcentration == 73.5)
        #expect(viewModel.latestWaterPH == 10.5)
    }

    @Test("Warns when streaming concentration falls below the recipe limit")
    func warnsBelowRecipeConcentrationLimit() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        await viewModel.scanData()
        let didWarn = await waitUntil { viewModel.colorConcentrationWarning != nil }

        #expect(didWarn)
        #expect(
            viewModel.colorConcentrationWarning
                == "Kepekatan warna saat ini di bawah 90%. Tambahkan 10 gram pewarna untuk "
                + "menjaga kualitas dan ketajaman warna batik."
        )
    }

    @Test("Does not warn at exactly the recipe concentration limit")
    func doesNotWarnAtExactlyRecipeLimit() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 900, clear: 1200, nir: 200)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        await viewModel.scanData()
        let didConsume = await waitUntil { viewModel.measurements?.current.first?.value == "90.0%" }

        #expect(didConsume)
        #expect(viewModel.colorConcentrationWarning == nil)
    }

    @Test("Warns when water pH falls below the recipe limit")
    func warnsBelowRecipePHLimit() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200, waterPH: 7.4)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 80, batasPH: 7.5))

        await viewModel.scanData()
        let didWarn = await waitUntil { viewModel.waterPHWarning != nil }

        #expect(didWarn)
        #expect(
            viewModel.waterPHWarning
                == "pH air saat ini di bawah 7.5. Tambahkan 10 gram soda abu untuk menjaga kualitas dan "
                + "ketajaman warna batik."
        )
    }

    @Test("Does not warn when water pH equals the recipe limit")
    func doesNotWarnAtExactlyRecipePHLimit() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200, waterPH: 7.5)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 80, batasPH: 7.5))

        await viewModel.scanData()
        let didConsume = await waitUntil { viewModel.measurements?.current[1].value == "7.5" }

        #expect(didConsume)
        #expect(viewModel.waterPHWarning == nil)
    }

    @Test("Choosing another recipe resets the scan state")
    func changingResepResetsScanState() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            initial: ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200, waterPH: 11),
            updates: [ColorMeasurement(visibleAverage: 850, clear: 1200, nir: 200, waterPH: 6.5)]
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))
        viewModel.jumlahKain = 3
        await viewModel.scanData()
        let didWarn = await waitUntil {
            viewModel.colorConcentrationWarning != nil && viewModel.waterPHWarning != nil
        }
        #expect(didWarn)
        #expect(viewModel.isDataScanned)

        let other = Resep.sample(namaWarna: "Merah", batasKepekatan: 70, batasPH: 8)
        viewModel.pilihResep(other)

        #expect(viewModel.selectedResep === other)
        #expect(!viewModel.isDataScanned)
        #expect(viewModel.colorConcentrationWarning == nil)
        #expect(viewModel.waterPHWarning == nil)
        #expect(viewModel.measurements?.colorConcentrationLimit == 70)
        #expect(viewModel.measurements?.waterPHLimit == 8)
        #expect(viewModel.measurements?.current.map(\.value) == ["—", "—"])
        #expect(viewModel.measurements?.initial[2].value == "—")
        #expect(viewModel.latestConcentration == nil)
        #expect(viewModel.latestWaterPH == nil)
        #expect(viewModel.jumlahKain == 3)
    }

    @Test("Scanning without a recipe does nothing")
    func ignoresReadingsWhenNoResepSelected() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            updates: [ColorMeasurement(visibleAverage: 100, clear: 1200, nir: 200, waterPH: 1)]
        ))

        await viewModel.scanData()

        #expect(!viewModel.isDataScanned)
        #expect(viewModel.colorConcentrationWarning == nil)
        #expect(viewModel.waterPHWarning == nil)
        #expect(viewModel.measurements == nil)
        #expect(viewModel.colorMeasurementError == nil)
    }

    @Test("A read that finishes after the recipe changed is discarded")
    func scanDataDiscardsResultWhenResepChangedDuringRead() async {
        let (readGate, releaseRead) = AsyncStream<Void>.makeStream()
        let (readStarted, signalReadStarted) = AsyncStream<Void>.makeStream()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            initial: ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200, waterPH: 11),
            readGate: readGate,
            onReadStarted: { signalReadStarted.yield() }
        ))
        viewModel.pilihResep(.sample(namaWarna: "A", batasKepekatan: 90, batasPH: 7))

        let scan = Task { await viewModel.scanData() }
        for await _ in readStarted {
            break
        }
        let other = Resep.sample(namaWarna: "B", batasKepekatan: 70, batasPH: 8)
        viewModel.pilihResep(other)
        releaseRead.yield()
        releaseRead.finish()
        await scan.value

        #expect(viewModel.selectedResep === other)
        #expect(!viewModel.isDataScanned)
        #expect(viewModel.measurements?.colorConcentrationLimit == 70)
        #expect(viewModel.measurements?.initial[2].value == "—")
        #expect(viewModel.colorMeasurementError == nil)
    }

    @Test("Readings of a previous recipe cannot change the new recipe")
    func staleStreamCannotMutateNewRecipeState() async {
        let (updates, liveReadings) = AsyncStream<ColorMeasurement>.makeStream()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(liveUpdates: updates))
        viewModel.pilihResep(.sample(namaWarna: "A", batasKepekatan: 90, batasPH: 7))
        await viewModel.scanData()
        liveReadings.yield(ColorMeasurement(visibleAverage: 950, clear: 1200, nir: 200))
        let isStreaming = await waitUntil { viewModel.measurements?.current.first?.value == "95.0%" }
        #expect(isStreaming)

        viewModel.pilihResep(.sample(namaWarna: "B", batasKepekatan: 90, batasPH: 7))
        liveReadings.yield(ColorMeasurement(visibleAverage: 500, clear: 1200, nir: 200, waterPH: 1))
        let didChange = await waitUntil(timeout: .milliseconds(300)) {
            viewModel.measurements?.current.map(\.value) != ["—", "—"]
                || viewModel.colorConcentrationWarning != nil
                || viewModel.waterPHWarning != nil
        }

        #expect(!didChange)
        #expect(viewModel.measurements?.current.map(\.value) == ["—", "—"])
        #expect(viewModel.colorConcentrationWarning == nil)
        #expect(viewModel.waterPHWarning == nil)
        #expect(viewModel.latestConcentration == nil)
        #expect(viewModel.latestWaterPH == nil)
    }

    @Test func discoveryMovesViewModelToFoundState() async {
        let viewModel = AddDeviceViewModel(service: StubDeviceConnectionService())

        await viewModel.discoverDevice()

        #expect(viewModel.state == .found)
        #expect(viewModel.isDeviceFound)
    }

    @Test func connectingMovesViewModelToConnectedState() async {
        let viewModel = AddDeviceViewModel(
            initialState: .found,
            service: StubDeviceConnectionService()
        )

        await viewModel.connectDevice()

        #expect(viewModel.state == .connected)
    }
}

private struct StubDeviceConnectionService: DeviceConnectionService {
    var initial = ColorMeasurement(visibleAverage: 1000, clear: 1200, nir: 200)
    var updates: [ColorMeasurement] = []
    /// When set, `readInitialColorMeasurement` suspends until this stream yields or finishes.
    var readGate: AsyncStream<Void>?
    var onReadStarted: (@Sendable () -> Void)?
    /// When set, `measurementUpdates` returns this stream instead of `updates`.
    var liveUpdates: AsyncStream<ColorMeasurement>?

    func discoverDevice() async throws -> Bool {
        true
    }

    func connectToDevice() async throws {}

    func readInitialColorMeasurement() async throws -> ColorMeasurement {
        onReadStarted?()
        if let readGate {
            for await _ in readGate {
                break
            }
        }
        return initial
    }

    func measurementUpdates() -> AsyncStream<ColorMeasurement> {
        if let liveUpdates {
            return liveUpdates
        }
        let updates = updates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}
