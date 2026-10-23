//
//  ProyekScanTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct ProyekScanTests {
    @Test("Overlapping scans issue only one device read and show no error")
    func overlappingScansReadTheDeviceOnce() async {
        let (readGate, releaseRead) = AsyncStream<Void>.makeStream()
        let (readStarted, signalReadStarted) = AsyncStream<Void>.makeStream()
        let service = StubDeviceConnectionService(
            readGate: readGate,
            onReadStarted: { signalReadStarted.yield() }
        )
        let viewModel = ProyekViewModel(service: service)
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        let first = Task { await viewModel.scanData() }
        for await _ in readStarted {
            break
        }
        let second = Task { await viewModel.scanData() }
        // Give a (wrongly) started second read the chance to reach the device.
        _ = await waitUntil(timeout: .milliseconds(100)) { service.readCounter.value > 1 }
        releaseRead.yield()
        releaseRead.finish()
        await first.value
        await second.value

        #expect(service.readCounter.value == 1)
        #expect(viewModel.colorMeasurementError == nil)
        #expect(viewModel.isDataScanned)
    }

    @Test("A cancelled (superseded) read is not an error")
    func cancelledReadShowsNoError() async {
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            readError: CancellationError()
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        await viewModel.scanData()

        #expect(viewModel.colorMeasurementError == nil)
        #expect(!viewModel.isDataScanned)
        #expect(!viewModel.isScanning)
    }

    @Test("A failed read shows the error and stops scanning")
    func failedReadShowsError() async {
        struct ReadFailure: Error {}
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            readError: ReadFailure()
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))

        await viewModel.scanData()

        #expect(viewModel.colorMeasurementError?.hasPrefix("Gagal membaca data warna") == true)
        #expect(!viewModel.isDataScanned)
        #expect(!viewModel.isScanning)
    }

    @Test("A failed read after the recipe changed shows no error")
    func failedReadAfterResepChangedShowsNoError() async {
        struct ReadFailure: Error {}
        let (readGate, releaseRead) = AsyncStream<Void>.makeStream()
        let (readStarted, signalReadStarted) = AsyncStream<Void>.makeStream()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            readGate: readGate,
            onReadStarted: { signalReadStarted.yield() },
            readError: ReadFailure()
        ))
        viewModel.pilihResep(.sample(namaWarna: "A", batasKepekatan: 90, batasPH: 7))

        let scan = Task { await viewModel.scanData() }
        for await _ in readStarted {
            break
        }
        viewModel.pilihResep(.sample(namaWarna: "B", batasKepekatan: 70, batasPH: 8))
        releaseRead.yield()
        releaseRead.finish()
        await scan.value

        #expect(viewModel.colorMeasurementError == nil)
        #expect(!viewModel.isScanning)
    }

    @Test("isScanning is true while the read is in flight and false afterwards")
    func isScanningTracksTheRead() async {
        let (readGate, releaseRead) = AsyncStream<Void>.makeStream()
        let (readStarted, signalReadStarted) = AsyncStream<Void>.makeStream()
        let viewModel = ProyekViewModel(service: StubDeviceConnectionService(
            readGate: readGate,
            onReadStarted: { signalReadStarted.yield() }
        ))
        viewModel.pilihResep(.sample(batasKepekatan: 90, batasPH: 7))
        #expect(!viewModel.isScanning)

        let scan = Task { await viewModel.scanData() }
        for await _ in readStarted {
            break
        }
        #expect(viewModel.isScanning)

        releaseRead.yield()
        releaseRead.finish()
        await scan.value

        #expect(!viewModel.isScanning)
        #expect(viewModel.isDataScanned)
    }

    @Test("Choosing a recipe during a scan clears isScanning and allows a new scan")
    func pilihResepResetsIsScanning() async {
        let (readGate, releaseRead) = AsyncStream<Void>.makeStream()
        let (readStarted, signalReadStarted) = AsyncStream<Void>.makeStream()
        let service = StubDeviceConnectionService(
            readGate: readGate,
            onReadStarted: { signalReadStarted.yield() }
        )
        let viewModel = ProyekViewModel(service: service)
        viewModel.pilihResep(.sample(namaWarna: "A", batasKepekatan: 90, batasPH: 7))

        let scan = Task { await viewModel.scanData() }
        for await _ in readStarted {
            break
        }
        #expect(viewModel.isScanning)

        viewModel.pilihResep(.sample(namaWarna: "B", batasKepekatan: 70, batasPH: 8))
        #expect(!viewModel.isScanning)

        releaseRead.yield()
        releaseRead.finish()
        await scan.value
        #expect(!viewModel.isScanning)
        #expect(!viewModel.isDataScanned)
    }
}
