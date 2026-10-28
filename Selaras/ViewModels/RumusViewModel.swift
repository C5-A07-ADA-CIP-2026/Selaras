//
//  RumusViewModel.swift
//  Selaras
//
//  Created by Steffany Florence on 26/10/26.
//

import Foundation
import Combine

enum StatusProses: Equatable {
    case initialSetup
    case monitoring                                                // Real-time IoT monitoring
    case thresholdTerlewati(pH1: Double, absorbansi1: Double)      // Checkpoint 1
    case airDitambahkan                                            // Menunggu bacaan setelah tambah 1L air
    case sodaDihitung(PerhitunganSoda)                             // Perhitungan soda selesai
    case sodaDitambahkan(PerhitunganSoda)                          // Menunggu bacaan setelah tambah soda
    case pewarnaDihitung(PerhitunganSoda, PerhitunganPewarna)      // Perhitungan pewarna selesai
}

@MainActor
class RumusViewModel: ObservableObject {
    @Published var statusProses: StatusProses = .initialSetup
    
    // Real-Time IoT Values
    @Published var livePh: Double = 0.0
    @Published var liveAbsorbansi: Double = 0.0
    @Published var liveDeltaT: Double = 0.0
    
    // Checkpoint Baseline
    @Published var pHAwal: Double = 0.0
    @Published var absorbansiAwal: Double = 0.0
    
    private var checkpoint1Ph: Double?
    private var checkpoint1Absorbansi: Double?
    private var checkpoint2Ph: Double?
    private var checkpoint2Absorbansi: Double?
    private var checkpoint3Ph: Double?
    private var checkpoint3Absorbansi: Double?
    
    // User Resep State
    @Published var resep = ResepKalkulasi(
        pewarna: [
            BahanPewarna(jenisPewarna: "Merah", gramPewarna: 5.0),
            BahanPewarna(jenisPewarna: "Biru", gramPewarna: 10.0)
        ],
        zatPembantu: [
            ZatPembantu(jenisZatPembantu: "Soda Kostik", gramZatPembantu: 30.0)
        ],
        resepAir: 1000,           // 1000 mL per kain
        jumlahKain: 10,           // 10 kain
        thresholdPh: 10.0,        // Batas penurunan pH
        thresholdWarna: 90.0       // Batas penurunan kepekatan warna (%)
    )
    
    @Published var kalibrasi = DataKalibrasi(slopeA: 0.0)
    @Published var airDitambahkanMl: Int = 1000 // Default 1000 mL (1 L)
    
    // Baseline setup & hitung slopeA (nilai awal pada air pewarna)
    func captureInitialBaseline(directPh: Double, channelAirPewarna: [Double], channelAirBersih: [Double]) {
        let pembacaanWarna = PembacaanAS7341(
            channelAirPewarna: channelAirPewarna,
            channelAirBersih: channelAirBersih
        )
        
        self.pHAwal = directPh
        self.absorbansiAwal = pembacaanWarna.absorbansi
        
        let targetKonsentrasi = resep.targetKonsentrasiPewarna
        if targetKonsentrasi > 0 {
            self.kalibrasi.slopeA = self.absorbansiAwal / targetKonsentrasi
        }
        
        self.statusProses = .monitoring
    }
    
    // Handle real-time data dari IoT
    func prosesLiveIoTData(directPh: Double, channelAirPewarna: [Double], channelAirBersih: [Double]) {
        let pembacaanWarna = PembacaanAS7341(
            channelAirPewarna: channelAirPewarna,
            channelAirBersih: channelAirBersih
        )
        
        self.livePh = directPh
        self.liveAbsorbansi = pembacaanWarna.absorbansi
        self.liveDeltaT = pembacaanWarna.deltaT
        
        switch statusProses {
        case .monitoring:
            evaluasiThreshold(phSaatIni: directPh, absorbansiSaatIni: pembacaanWarna.absorbansi)
            
        case .airDitambahkan:
            hitungSoda(ph2: directPh, absorbansi2: pembacaanWarna.absorbansi)
            
        case .sodaDitambahkan(let hasilSoda):
            hitungPewarna(ph3: directPh, absorbansi3: pembacaanWarna.absorbansi, hasilSoda: hasilSoda)
            
        default:
            break
        }
    }
    
    // Alert muncul jika ph/kepekatan warna turun dibawah threshold
    private func evaluasiThreshold(phSaatIni: Double, absorbansiSaatIni: Double) {
        let persentaseKepekatan = Rumus.hitungPersentaseKepekatan(
            initialA: absorbansiAwal,
            currentA: absorbansiSaatIni
        )
        
        if phSaatIni < resep.thresholdPh || persentaseKepekatan < resep.thresholdWarna {
            self.checkpoint1Ph = phSaatIni
            self.checkpoint1Absorbansi = absorbansiSaatIni
            self.statusProses = .thresholdTerlewati(pH1: phSaatIni, absorbansi1: absorbansiSaatIni)
        }
    }
    
    // User konfirmasi telah menambah air
    func userKonfirmasiMenambahAir(jumlahML: Int = 1000) {
        self.airDitambahkanMl = jumlahML
        self.statusProses = .airDitambahkan
    }
    
    private func hitungSoda(ph2: Double, absorbansi2: Double) {
        guard let ph1 = checkpoint1Ph else { return }
        self.checkpoint2Ph = ph2
        self.checkpoint2Absorbansi = absorbansi2
        
        if let hasilSoda = Rumus.hitungPenambahanSoda(
            pH1: ph1,
            pH2: ph2,
            airDitambahkan: airDitambahkanMl,
            resep: resep
        ) {
            self.statusProses = .sodaDihitung(hasilSoda)
        }
    }
    
    // User konfirmasi telah menambahkan soda
    func userKonfirmasiTambahSoda() {
        if case .sodaDihitung(let hasilSoda) = statusProses {
            self.statusProses = .sodaDitambahkan(hasilSoda)
        }
    }
    
    private func hitungPewarna(ph3: Double, absorbansi3: Double, hasilSoda: PerhitunganSoda) {
        self.checkpoint3Ph = ph3
        self.checkpoint3Absorbansi = absorbansi3
        
        let hasilPewarna = Rumus.hitungPenambahanPewarna(
            absorbansi3: absorbansi3,
            totalVolumeLiter: hasilSoda.volumeAirSaatIni,
            resep: resep,
            kalibrasi: kalibrasi
        )
        
        self.statusProses = .pewarnaDihitung(hasilSoda, hasilPewarna)
    }
    
    func resetKeMonitoring() {
        self.checkpoint1Ph = nil
        self.checkpoint1Absorbansi = nil
        self.checkpoint2Ph = nil
        self.checkpoint2Absorbansi = nil
        self.checkpoint3Ph = nil
        self.checkpoint3Absorbansi = nil
        self.statusProses = .monitoring
    }
}
