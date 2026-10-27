//
//  ResepViewModel.swift
//  Selaras
//
//  Created by Dina on 22/10/26.
//

import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class FormResepViewModel {
    var namaWarna = ""
    var ukuranAir = 0
    var kepekatan = 0.0
    var batasPH = 0.0
    var warnaDipilih: Color?
    var pewarna = [BahanInput()]
    var zatPembantu = [BahanInput()]
    
    /// Resep yang sedang dilihat. `nil` berarti mode tambah.
    private(set) var resepAsli: Resep?
    
    var sedangMengedit: Bool { resepAsli != nil }
    
    var formLengkap: Bool {
        namaWarna.tidakKosong
        && warnaDipilih != nil
        && ukuranAir > 0
        && kepekatan > 0
        && batasPH > 0
        && pewarna.semuaTerisi
        && zatPembantu.semuaTerisi
    }
    
    /// `true` kalau ada isian yang berbeda dari resep asli.
    var adaPerubahan: Bool {
        guard let asli = resepAsli, !asli.isDeleted else { return false }
        return namaWarna != asli.namaWarna
        || warnaDipilih?.hexString != asli.warnaHex
        || ukuranAir != asli.air
        || kepekatan != asli.kepekatan
        || batasPH != asli.batasPH
        || pewarna.map(\.bahan) != asli.pewarna
        || zatPembantu.map(\.bahan) != asli.zatPembantu
    }
    
    /// Tombol centang aktif (biru) hanya kalau form valid dan ada yang berubah.
    var bisaSimpan: Bool {
        sedangMengedit ? (formLengkap && adaPerubahan) : formLengkap
    }
    
    init() {}
    
    /// Mengisi form dari resep yang sudah tersimpan (untuk mode baca).
    init(resep: Resep) {
        resepAsli = resep
        namaWarna = resep.namaWarna
        warnaDipilih = Color(hex: resep.warnaHex)
        ukuranAir = resep.air
        kepekatan = resep.kepekatan
        batasPH = resep.batasPH
        pewarna = resep.pewarna.map { BahanInput(kode: $0.kode, gram: $0.gram) }
        zatPembantu = resep.zatPembantu.map { BahanInput(kode: $0.kode, gram: $0.gram) }
    }
    
    /// Menyimpan form sebagai `Resep` baru. Tidak melakukan apa pun bila form belum lengkap.
    func simpan(context: some ModelPersisting) throws {
        guard formLengkap, let warna = warnaDipilih else { return }
        
        if let resep = resepAsli {
            resep.namaWarna = namaWarna
            resep.warnaHex = warna.hexString
            resep.air = ukuranAir
            resep.kepekatan = kepekatan
            resep.batasPH = batasPH
            resep.pewarna = pewarna.map(\.bahan)
            resep.zatPembantu = zatPembantu.map(\.bahan)
            try context.save()
        } else {
            let resep = Resep(
                namaWarna: namaWarna,
                warnaHex: warna.hexString,
                air: ukuranAir,
                kepekatan: kepekatan,
                batasPH: batasPH,
                pewarna: pewarna.map(\.bahan),
                zatPembantu: zatPembantu.map(\.bahan)
            )
            try context.insertAndSave(resep)
        }
    }
    
    func hapus(context: some ModelPersisting) throws {
        guard let resep = resepAsli else { return }
        context.delete(resep)
        try context.save()
    }
}
