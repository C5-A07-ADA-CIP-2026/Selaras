//
//  ResepView.swift
//  Selaras
//

import SwiftUI

struct ResepView: View {
    @State private var showModal = false
    @State private var teksCari = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book")
                .font(.system(size: 100)) //pr: dynamic
                .foregroundStyle(.secondary)
            
            Text("Belum ada warna")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Tekan + untuk menambah warna")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Warna Saya")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $teksCari, prompt: "Cari Warna")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showModal = true
                } label: {
                    Label("AddWarna", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showModal) {
            NavigationStack {
                HalamanTambahResep()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResepView()
    }
}
