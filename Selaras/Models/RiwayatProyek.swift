//
//  RiwayatProyek.swift
//  Selaras
//
//  Created by Steffany Florence on 21/10/26.
//

import SwiftData
import SwiftUI

struct RiwayatProyek: Identifiable {
    let id: UUID
    let hexColor: String
    var date: Date = .init()
    let details: String
    let colorTreshold: Double
    let phTreshold: Double

    var color: Color {
        Color(hex: hexColor)
    }

    var colorTresholdText: String {
        "\(Self.format(colorTreshold))%"
    }

    var phTresholdText: String {
        Self.format(phTreshold)
    }

    var formattedDate: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "id_ID")
        weekdayFormatter.dateFormat = "EEEE"
        let weekday = weekdayFormatter.string(from: date)

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "id_ID")
        monthFormatter.dateFormat = "MMMM"
        let month = monthFormatter.string(from: date)

        return "\(weekday), \(day) \(month)"
    }

    /// Locale-independent, drops trailing zeros: 10 -> "10", 7.5 -> "7.5".
    private static func format(_ value: Double) -> String {
        String(format: "%g", value)
    }
}

extension RiwayatProyek {
    init(proyek: Proyek) {
        let details = proyek.catatan.isEmpty
            ? proyek.namaWarna
            : "\(proyek.namaWarna) (\(proyek.catatan))"
        self.init(
            id: proyek.id,
            hexColor: proyek.warnaHex,
            date: proyek.tanggal,
            details: details,
            colorTreshold: proyek.batasKepekatan,
            phTreshold: proyek.batasPH
        )
    }
}

extension Proyek {
    /// Proyek tersimpan, yang terbaru di atas.
    static var terbaruDulu: FetchDescriptor<Proyek> {
        FetchDescriptor<Proyek>(sortBy: [SortDescriptor(\.tanggal, order: .reverse)])
    }
}
