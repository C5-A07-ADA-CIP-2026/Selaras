//
//  HalamanTambahResep.swift
//  Selaras
//
//  Created by Dina on 21/10/26.
//

import SwiftData
import SwiftUI

struct HalamanTambahResep: View {
    @State private var viewModel: FormResepViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var gagalMenyimpan = false
    private let tampilSebagaiSheet: Bool
    
    init(resep: Resep? = nil, tampilSebagaiSheet: Bool = false) {
        self.tampilSebagaiSheet = tampilSebagaiSheet
        _viewModel = State(
            initialValue: resep.map { FormResepViewModel(resep: $0) } ?? FormResepViewModel()
        )
    }
    
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
        .navigationTitle(viewModel.sedangMengedit ? viewModel.namaWarna : "Tambah Warna")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarForm }
        .alert("Gagal menyimpan", isPresented: $gagalMenyimpan) {
            Button("Tutup", role: .cancel) {}
        }
    }
    
    private var bagianBahan: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Bahan")
                .font(.judulBold)
            
            DaftarBahan(
                judul: "Kode Pewarna Naphtol",
                labelTambah: "Tambah Pewarna",
                bahan: $viewModel.pewarna,
                pilihanTersedia: viewModel.daftarPilihanPewarna
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
                bahan: $viewModel.zatPembantu,
                pilihanTersedia: viewModel.daftarPilihanZatPembantu
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
            
            Text("""
            Nilai ini adalah batas minimum rekomendasi dan dapat Anda ubah kapan saja. \
            Notifikasi akan dikirim jika nilai turun di bawah batas ini
            """)
            .font(.caption)
            .italic()
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func simpan() {
        do {
            try viewModel.simpan(context: modelContext)
            if !viewModel.sedangMengedit { dismiss() }
        } catch {
            gagalMenyimpan = true
        }
    }

    @ToolbarContentBuilder
    private var toolbarForm: some ToolbarContent {
            if tampilSebagaiSheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    simpan()
                    if tampilSebagaiSheet { dismiss() }
                } label: {
                    Label("Simpan", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.bisaSimpan)
            }
        }
}


#Preview {
    NavigationStack {
        HalamanTambahResep()
    }
}
