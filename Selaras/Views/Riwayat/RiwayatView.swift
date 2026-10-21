//
//  RiwayatView.swift
//  Selaras
//

import SwiftUI

struct RiwayatView: View {
    @Environment(\.dismiss) private var dismiss
    
    let riwayatList = [
        RiwayatProyek(hexColor: "#b50202", date: Date(), details: "Merah Marun (Pesanan Bu Siti)", colorTreshold: 95, phTreshold: 10),
        RiwayatProyek(hexColor: "#F4A9B4", date: Date(), details: "Pink (Pesanan Bu Siti)", colorTreshold: 90, phTreshold: 11)
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
