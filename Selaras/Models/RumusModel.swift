//
//  RumusModel.swift
//  Selaras
//
//  Created by Steffany Florence on 22/10/26.
//

import Foundation

// MARK: - Input Resep per 1 Kain

struct BahanPewarna: Identifiable, Equatable {
    let id = UUID()
    var jenisPewarna: String
    var gramPewarna: Double
}

struct ZatPembantu: Identifiable, Equatable {
    let id = UUID()
    var jenisZatPembantu: String
    var gramZatPembantu: Double
}

// MARK: - Initial Value yang Diketahui

struct Resep {
    var pewarna: [BahanPewarna]
    var zatPembantu: [ZatPembantu]
    var resepAir: Int
    var jumlahKain: Int
    var thresholdPh: Double
    var thresholdKain: Double
    
    var jumlahAir: Int {
        return resepAir * jumlahKain
    }
    
    var literAir: Double {
        return Double(jumlahAir) / 1000.0
    }
    
    // 1 resep warna bisa > 1 warna
    var totalBeratPewarnaPerKain: Double {
        var total: Double = 0.0
        for warna in pewarna {
            total += warna.gramPewarna
        }
        return total
    }
    
    // total berat pewarna untuk seluruh jumlah kain
    var totalPewarna: Double {
        return totalBeratPewarnaPerKain * Double(jumlahKain)
    }
    
    var totalBeratZatPembantuPerKain: Double {
        var total: Double = 0.0
        for zatpembantu in zatPembantu {
            total += zatpembantu.gramZatPembantu
        }
        return total
    }
    
    var totalZatPembantu: Double {
        return totalBeratZatPembantuPerKain * Double(jumlahKain)
    }
    
    var targetKonsentrasiPewarna: Double {
        guard literAir > 0 else { return 0.0 }
        return totalPewarna / literAir
    }
    
    var targetPh: Double {
        guard literAir > 0 else { return 0.0 }
        return totalZatPembantu / literAir
    }
}

// MARK: - Pembacaan AS7341 6-Channel

struct PembacaanAS7341 {
    let channelAirPewarna: [Double] // 6 color channel pada air pewarna
    let channelAirBersih: [Double]  // 6 color channel pada air bersih
    
    // Hitung masing-masing T
    var transmitansiChannel: [Double] {
        guard channelAirPewarna.count == 6, channelAirBersih.count == 6 else { return [] }
        var transmitansi: [Double] = []
        for i in 0..<6 {
            let iN = channelAirPewarna[i]
            let i0 = channelAirBersih[i]
            let t = i0 > 0 ? (iN / i0) : 1.0
            transmitansi.append(t)
        }
        return transmitansi
    }
    
    // Delta T = T max - T min
    var deltaT: Double {
        let tValues = transmitansiChannel
        guard let tMin = tValues.min(), let tMax = tValues.max() else { return 0.0 }
        return tMax - tMin
    }
    
    // Hitung T akhir based on Delta T < 0.08
    var transmitansiEfektif: Double {
        let tValues = transmitansiChannel
        guard let tMin = tValues.min(), !tValues.isEmpty else { return 1.0 }
        
        if deltaT < 0.08 {
            var sum: Double = 0.0
            for t in tValues {
                sum += t
            }
            return sum / Double(tValues.count)
        } else {
            return tMin
        }
    }
    
    var absorbansi: Double {
        let t = transmitansiEfektif
        guard t > 0 else { return 0.0 }
        return -log10(t)
    }
}

// MARK: - Data Perhitungan Penambahan Bahan

struct DataKalibrasi {
    var slopeA: Double            // parameter a
    let interceptB: Double = 0.0  // parameter b
}

struct PenambahanBahan: Identifiable, Equatable {
    let id = UUID()
    let jenisBahan: String
    let gramPenambahan: Double
}

struct PerhitunganSoda: Equatable {
    let volumeAirDigunakan: Double  // V_usage -> vol air setelah pencelupan
    let volumeAirSaatIni: Double    // V2 -> vol air setelah penambahan
    let konsentrasiSoda1: Double    // C1 (g/L)
    let konsentrasiSoda2: Double    // C2 (g/L) -> setelah penambahan air
    let sodaPerluDitambah: Double   // Delta m NaOH (g)
    let breakdownPenambahanBahan: [PenambahanBahan]
}

struct PerhitunganPewarna: Equatable {
    let konsentrasiPewarnaSekarang: Double  // C_bak (g/L)
    let totalPenambahanPewarna: Double      // Delta m Pewarna (g)
    let breakdownPenambahanPewarna: [PenambahanBahan]
}

// MARK: - Perhitungan Rumus

struct Rumus {
    
    static func hitungKonsentrasiSoda(from pH: Double) -> Double {
        let pOH = 14.0 - pH
        let molarityOH = pow(10.0, -pOH)
        return molarityOH * 40.0
    }
    
    // C_bak = (A - b) / a
    static func hitungKonsentrasiPewarna(absorbansi: Double, kalibrasi: DataKalibrasi) -> Double {
        guard kalibrasi.slopeA > 0 else { return 0.0 }
        let kons = (absorbansi - kalibrasi.interceptB) / kalibrasi.slopeA
        return max(0.0, kons)
    }
    
    static func hitungPersentaseKepekatan(initialA: Double, currentA: Double) -> Double {
        guard initialA > 0 else { return 0.0 }
        return (currentA / initialA) * 100.0
    }
    
    static func hitungPenambahanSoda(
        pH1: Double,
        pH2: Double,
        airDitambahkan: Int,
        resep: Resep
    ) -> PerhitunganSoda? {
        let literAirDitambahkan = Double(airDitambahkan) / 1000.0
        
        let C1 = hitungKonsentrasiSoda(from: pH1)
        let C2 = hitungKonsentrasiSoda(from: pH2)
        
        guard C1 > C2, (C1 - C2) > 0.0001 else { return nil }
        
        let vDigunakan = (C2 * literAirDitambahkan) / (C1 - C2)
        let v2 = vDigunakan + literAirDitambahkan
        
        let targetKonsentrasiSoda = resep.targetPh
        let totalSodaDiperlukan = max(0.0, (targetKonsentrasiSoda - C2) * v2)
        
        var penambahanBahan: [PenambahanBahan] = []
        let totalZatPembantuPerKain = resep.totalBeratZatPembantuPerKain
        
        for zat in resep.zatPembantu {
            let rasio = totalZatPembantuPerKain > 0 ? (zat.gramZatPembantu / totalZatPembantuPerKain) : 0.0
            let penambahanBahanDiperlukan = PenambahanBahan(
                jenisBahan: zat.jenisZatPembantu,
                gramPenambahan: totalSodaDiperlukan * rasio
            )
            penambahanBahan.append(penambahanBahanDiperlukan)
        }
        
        return PerhitunganSoda(
            volumeAirDigunakan: vDigunakan,
            volumeAirSaatIni: v2,
            konsentrasiSoda1: C1,
            konsentrasiSoda2: C2,
            sodaPerluDitambah: totalSodaDiperlukan,
            breakdownPenambahanBahan: penambahanBahan
        )
    }
    
    static func hitungPenambahanPewarna(
        absorbansi3: Double,
        totalVolumeLiter: Double,
        resep: Resep,
        kalibrasi: DataKalibrasi
    ) -> PerhitunganPewarna {
        let cPewarnaSaatIni = hitungKonsentrasiPewarna(absorbansi: absorbansi3, kalibrasi: kalibrasi)
        let targetKonsentrasiPewarna = resep.targetKonsentrasiPewarna
        let totalPewarnaDiperlukan = max(0.0, (targetKonsentrasiPewarna - cPewarnaSaatIni) * totalVolumeLiter)
        
        var penambahanPewarna: [PenambahanBahan] = []
        let totalBeratPewarnaPerKain = resep.totalBeratPewarnaPerKain
        
        for pewarna in resep.pewarna {
            let rasio = totalBeratPewarnaPerKain > 0 ? (pewarna.gramPewarna / totalBeratPewarnaPerKain) : 0.0
            let penambahanBahanPewarna = PenambahanBahan(
                jenisBahan: pewarna.jenisPewarna,
                gramPenambahan: totalPewarnaDiperlukan * rasio
            )
            penambahanPewarna.append(penambahanBahanPewarna)
        }
        
        return PerhitunganPewarna(
            konsentrasiPewarnaSekarang: cPewarnaSaatIni,
            totalPenambahanPewarna: totalPewarnaDiperlukan,
            breakdownPenambahanPewarna: penambahanPewarna
        )
    }
}
