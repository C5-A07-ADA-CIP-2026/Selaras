//
//  HalamanTambahResep.swift
//  Selaras
//
//  Created by Dina on 21/10/26.
//

import SwiftUI

struct HalamanTambahResep: View {
    @State private var namaWarna = ""
    @State private var namaCatatan = ""
    @State private var ukuranAir = 0
    @State private var kepekatan = 0.0
    @State private var batasPH = 0.0

    @State private var warnaDipilih: Color? = nil

    private var bindingWarna: Binding<Color> {
        Binding(
            get: { warnaDipilih ?? .blue },
            set: { warnaDipilih = $0 }
        )
    }

    @State private var pewarna: [BahanInput] = [BahanInput()]
    @State private var zatPembantu: [BahanInput] = [BahanInput()]

    @Environment(\.dismiss) private var dismiss

    private var pewarnaTerisi: Bool {
        pewarna.allSatisfy {
            !$0.kode.trimmingCharacters(in: .whitespaces).isEmpty && ($0.gram ?? 0) > 0
        }
    }

    private var zatPembantuTerisi: Bool {
        zatPembantu.allSatisfy {
            !$0.kode.trimmingCharacters(in: .whitespaces).isEmpty && ($0.gram ?? 0) > 0
        }
    }

    private var formLengkap: Bool {
        !namaWarna.trimmingCharacters(in: .whitespaces).isEmpty
            && !namaCatatan.trimmingCharacters(in: .whitespaces).isEmpty
            && warnaDipilih != nil
            && ukuranAir > 0
            && kepekatan > 0
            && batasPH > 0
            && pewarnaTerisi
            && zatPembantuTerisi
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nama Warna")
                        .font(.system(.headline, weight: .bold))
                    TextField("Cth: Merah Marun", text: $namaWarna)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Catatan")
                        .font(.system(.headline, weight: .bold))
                    TextField("Cth: Seragam Bu Dina", text: $namaCatatan)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Warna")
                        .font(.system(.headline, weight: .bold))

                    ZStack {
                        if let warna = warnaDipilih {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(warna)
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .allowsHitTesting(false)
                        } else {
                            Text("Pilih Warna")
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor, in: Capsule())
                                .allowsHitTesting(false)
                        }

                        ColorPicker("", selection: bindingWarna, supportsOpacity: false)
                            .labelsHidden()
                            .scaleEffect(x: 20, y: 3)
                            .opacity(0.02)

                        if warnaDipilih != nil {
                            Button {
                                warnaDipilih = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .black.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .topTrailing
                            )
                        }
                    }
                    .frame(height: warnaDipilih != nil ? 80 : nil)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: warnaDipilih != nil ? 12 : 25
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("Bahan")
                        .font(.system(.headline, weight: .bold))

                    Text("Kode Pewarna Naphtol")
                        .font(.system(.headline, weight: .bold))

                    ForEach($pewarna) { $bahan in
                        barisBahan(
                            kode: $bahan.kode,
                            gram: $bahan.gram
                        )
                    }

                    Button {
                        pewarna.append(BahanInput())
                    } label: {
                        Label("Tambah Pewarna", systemImage: "plus")
                            .font(.system(.headline, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!pewarnaTerisi)

                    HStack {
                        Text("Air")
                            .font(.system(.headline, weight: .bold))

                        Spacer()

                        TextField("0", value: $ukuranAir, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)

                        Text("ml")
                            .font(.system(.headline))
                            .frame(width: 30, alignment: .leading)
                    }

                    Text("Zat Pembantu")
                        .font(.system(.headline, weight: .bold))

                    ForEach($zatPembantu) { $bahan in
                        barisBahan(
                            kode: $bahan.kode,
                            gram: $bahan.gram
                        )
                    }

                    Button {
                        zatPembantu.append(BahanInput())

                    } label: {
                        Label("Tambah Zat Pembantu", systemImage: "plus")
                            .font(.system(.headline, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!zatPembantuTerisi)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("Batas")
                        .font(.system(.headline, weight: .bold))

                    HStack {
                        Text("Kepekatan Warna")
                            .font(.system(.headline))

                        Spacer()

                        TextField("0", value: $kepekatan, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .onChange(of: kepekatan) { _, baru in
                                kepekatan = min(max(baru, 0), 100)
                            }

                        Text("%")
                            .font(.system(.headline))
                            .frame(width: 30, alignment: .leading)
                    }

                    HStack {
                        Text("Batas pH")
                            .font(.system(.headline))

                        Spacer()

                        TextField("0", value: $batasPH, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .onChange(of: batasPH) { _, baru in
                                batasPH = min(max(baru, 0), 14)
                            }

                        Text("pH")
                            .font(.system(.headline))
                            .frame(width: 30, alignment: .leading)
                    }

                    Text("Nilai ini adalah batas minimum rekomendasi dan dapat Anda ubah kapan saja. Notifikasi akan dikirim jika nilai turun di bawah batas ini")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(15)
        }
        .navigationTitle("Tambah Warna")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                    // simpan nanti
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!formLengkap)
                .accessibilityLabel("Simpan")
            }
        }
    }
}

private func barisBahan(
    kode: Binding<String>,
    gram: Binding<Double?>
) -> some View {
    HStack(spacing: 8) {
        TextField("Kode / Nama Bahan", text: kode)
            .textFieldStyle(.roundedBorder)

        TextField("0", value: gram, format: .number)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(width: 60)

        Text("g")
            .frame(width: 30)
    }
}

#Preview {
    NavigationStack {
        HalamanTambahResep()
    }
}
