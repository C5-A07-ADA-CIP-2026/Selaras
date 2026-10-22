//
//  HalamanTambahResep.swift
//  Selaras
//
//  Created by Dina on 21/10/26.
//

import SwiftUI

struct HalamanTambahResep: View {
    @State private var viewModel = FormResepViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                KolomTeks(
                    judul: "Nama Warna",
                    placeholder: "Cth: Merah Marun",
                    teks: $viewModel.namaWarna
                )
                KolomTeks(
                    judul: "Catatan",
                    placeholder: "Cth: Seragam Bu Dina",
                    teks: $viewModel.namaCatatan
                )
                PemilihWarna(warna: $viewModel.warnaDipilih)
                bagianBahan
                bagianBatas
            }
            .padding(15)
        }
        .navigationTitle("Tambah Warna")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarForm }
    }
    
    private var bagianBahan: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Bahan")
                .font(.judulBold)
            
            DaftarBahan(
                judul: "Kode Pewarna Naphtol",
                labelTambah: "Tambah Pewarna",
                bahan: $viewModel.pewarna
            )
            
            BarisIsian(label: "Air", satuan: "ml", labelTebal: true) {
                TextField("0", value: $viewModel.ukuranAir, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
            
            DaftarBahan(
                judul: "Zat Pembantu",
                labelTambah: "Tambah Zat Pembantu",
                bahan: $viewModel.zatPembantu
            )
        }
    }
    
    private var bagianBatas: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Batas")
                .font(.judulBold)
            
            BarisBatas(
                label: "Kepekatan Warna",
                satuan: "%",
                nilai: $viewModel.kepekatan,
                rentang: 0 ... 100
            )
            BarisBatas(
                label: "Batas pH",
                satuan: "pH",
                nilai: $viewModel.batasPH,
                rentang: 0 ... 14
            )
            
            Text("Nilai ini adalah batas minimum rekomendasi dan dapat Anda ubah kapan saja. Notifikasi akan dikirim jika nilai turun di bawah batas ini")
                .font(.caption)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarForm: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Batal")
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.simpan()
                dismiss()
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.formLengkap)
            .accessibilityLabel("Simpan")
        }
    }
}

#Preview {
    NavigationStack {
        HalamanTambahResep()
    }
}
