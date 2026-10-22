//
//  Resep.swift
//  Selaras
//
//  Created by Dina on 21/10/26.
//

import SwiftData
import Foundation

@Model
class Resep {
    var namaWarna: String
    var catatan: String
    var warnaHex: String
    var air: Int
    var kepekatan: Double
    var batasPH: Double

    init(namaWarna: String, catatan: String, warnaHex: String,
         air: Int, kepekatan: Double, batasPH: Double) {
        self.namaWarna = namaWarna
        self.catatan = catatan
        self.warnaHex = warnaHex
        self.air = air
        self.kepekatan = kepekatan
        self.batasPH = batasPH
    }
    
}

struct Bahan: Codable, Hashable {
    var kode: String
    var gram: Double
}

struct BahanInput: Identifiable {
    let id = UUID()
    var kode = ""
    var gram: Double? = nil
    
    var bahan: Bahan {
        Bahan(
            kode: kode.trimmingCharacters(in: .whitespaces),
            gram: gram ?? 0
        )
    }
}

