//
//  ResepModel.swift
//  Selaras
//
//  Created by Dina on 21/10/26.
//

import Foundation
import SwiftData

@Model
class Resep {
    var namaWarna: String
    var catatan: String
    var warnaHex: String
    var air: Int
    var kepekatan: Double
    var batasPH: Double
    var pewarna: [Bahan]
    var zatPembantu: [Bahan]
    var dibuat: Date
    @Relationship(deleteRule: .nullify, inverse: \Proyek.resep) var proyekTersimpan: [Proyek] = []

    // swiftlint:disable opening_brace
    init(namaWarna: String, catatan: String, warnaHex: String,
         air: Int, kepekatan: Double, batasPH: Double,
         pewarna: [Bahan] = [], zatPembantu: [Bahan] = [], dibuat: Date = .now)
    {
        self.namaWarna = namaWarna
        self.catatan = catatan
        self.warnaHex = warnaHex
        self.air = air
        self.kepekatan = kepekatan
        self.batasPH = batasPH
        self.pewarna = pewarna
        self.zatPembantu = zatPembantu
        self.dibuat = dibuat
    }
    // swiftlint:enable opening_brace
}

struct Bahan: Codable, Hashable {
    var kode: String
    var gram: Double
}

struct BahanInput: Identifiable {
    let id = UUID()
    var kode = ""
    var gram: Double?

    var bahan: Bahan {
        Bahan(
            kode: kode.trimmingCharacters(in: .whitespaces),
            gram: gram ?? 0
        )
    }
}

extension BahanInput {
    var terisi: Bool {
        kode.tidakKosong && (gram ?? 0) > 0
    }
}

extension [BahanInput] {
    var semuaTerisi: Bool {
        allSatisfy(\.terisi)
    }
}
