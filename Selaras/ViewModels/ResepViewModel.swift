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
    var namaCatatan = ""
    var ukuranAir = 0
    var kepekatan = 0.0
    var batasPH = 0.0
    var warnaDipilih: Color?
    var pewarna = [BahanInput()]
    var zatPembantu = [BahanInput()]

    var formLengkap: Bool {
        namaWarna.tidakKosong
            && namaCatatan.tidakKosong
            && warnaDipilih != nil
            && ukuranAir > 0
            && kepekatan > 0
            && batasPH > 0
            && pewarna.semuaTerisi
            && zatPembantu.semuaTerisi
    }

    /// Menyimpan form sebagai `Resep` baru. Tidak melakukan apa pun bila form belum lengkap.
    func simpan(context: some ModelPersisting) throws {
        guard formLengkap, let warna = warnaDipilih else { return }

        let resep = Resep(
            namaWarna: namaWarna,
            catatan: namaCatatan,
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
