//
//  RiwayatView.swift
//  Selaras
//

import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct ProjectHistory: Identifiable {
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

struct RiwayatView: View {
    @Environment(\.dismiss) private var dismiss
    
    let riwayatList = [
        ProjectHistory(hexColor: "#b50202", date: Date(), details: "Merah Marun (Pesanan Bu Siti)", colorTreshold: 95, phTreshold: 10),
        ProjectHistory(hexColor: "#F4A9B4", date: Date(), details: "Pink (Pesanan Bu Siti)", colorTreshold: 90, phTreshold: 11)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Riwayat Proyek")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4))
                {
                        
                    ForEach(riwayatList) { item in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Batas Kepekatan Warna")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(item.colorTreshold)%")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                                
                                Divider()
                                
                                HStack {
                                    Text("Batas pH")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(item.phTreshold)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(item.color)
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.formattedDate)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(item.details)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Riwayat")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RiwayatView()
    }
}
