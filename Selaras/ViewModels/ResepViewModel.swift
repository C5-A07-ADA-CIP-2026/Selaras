//
//  ResepViewModel.swift
//  Selaras
//
//  Created by Dina on 22/10/26.
//

import Observation
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
 
    // Tempat logika simpan nanti (SwiftData), supaya View tidak ikut mengurusnya.
    func simpan() {}
}
