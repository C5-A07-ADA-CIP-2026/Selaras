//
//  RiwayatProyek.swift
//  Selaras
//
//  Created by Steffany Florence on 21/10/26.
//

import SwiftUI

struct RiwayatProyek: Identifiable {
    let id = UUID()
    let hexColor: String
    var date: Date = Date()
    let details: String
    let colorTreshold: Int
    let phTreshold: Int
    
    var color: Color {
        return Color(hex: hexColor)
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
}
