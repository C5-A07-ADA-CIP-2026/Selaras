# Selaras

Aplikasi iOS yang dikerjakan oleh tim 3 orang. Halamannya:

- **Resep**: halaman utama (tab pertama), daftar resep warna.
- **Proyek**: tab kedua. Tombol di kanan atas membuka **Riwayat**.
- **Riwayat**: dibuka dari Proyek, bukan tab sendiri.

## Tim

| Area | Owner | Branch |
|------|-------|--------|
| Resep | Dina | `feat/resep` |
| Proyek | Hana | `feat/proyek` |
| Riwayat, dan test untuk Proyek | Fany | `feat/riwayat` |

## Setup

Butuh Xcode 27 dan iOS 27.

```bash
brew bundle
open Selaras.xcodeproj
```

`brew bundle` memasang SwiftLint dan SwiftFormat dari `Brewfile`.

## Struktur

```
Selaras/
├── SelarasApp.swift                 ModelContainer SwiftData
├── ContentView.swift                TabView (Resep, Proyek)
├── AppTab.swift
├── Extensions/                      Color+hex, String
├── Shared/                          SelarasSchema (entitas SwiftData), ResepRowView
├── Views/
│   ├── Components/                  komponen form bersama
│   ├── Resep/                       ResepView, HalamanTambahResep
│   ├── Proyek/                      ProyekView, sheet perangkat dan pilih resep
│   └── Riwayat/RiwayatView.swift
├── ViewModels/                      ResepViewModel, ProyekViewModel
└── Models/                          Resep, Proyek, RiwayatProyek, koneksi perangkat BLE
SelarasTests/
├── ViewModels/                      tes ViewModel
├── Models/                          tes Model
└── Support/                         helper tes (container in-memory, stub perangkat)
```

### Alur data: Resep → Proyek → Riwayat

Ketiga halaman berbagi satu penyimpanan SwiftData (`Selaras/Shared/SelarasSchema.swift`, entitas `Resep` dan `Proyek`). Resep disimpan lewat form "Tambah Warna" di tab Resep. Di tab Proyek, pengguna memilih satu Resep dan batas kepekatan serta pH-nya dipakai proyek. "Pindai Data" mengambil pembacaan sensor sebagai baseline 100%, lalu "Simpan Proyek" menyimpan snapshot `Proyek`. Riwayat menampilkan `Proyek` yang tersimpan, terbaru di atas. Karena snapshot, entri Riwayat tetap ada walau Resep-nya dihapus.

Arsitektur MVVM satu folder per layer, test-first dengan Swift Testing: tulis tes dulu, lalu ViewModel dan Model-nya. Komponen yang dipakai bersama taruh di `Selaras/Shared/`. Detail aturan ada di [AGENTS.md](AGENTS.md).

## Branch dan PR

- `main` (default, rilis TestFlight), `staging`, `dev` (integrasi).
- Kerja di branch fitur masing-masing, lalu buka PR ke `dev`.
- Commit pakai Conventional Commits: `feat(resep): add recipe list`.
- Judul PR: `<type>(KAN-12): Nama singkat`. Tiket Jira ada di <https://mariabelenn2405.atlassian.net/browse/KAN>.
- Sertakan screenshot untuk perubahan UI.

## Kualitas kode

Sebelum PR, **build harus succeed** dan dua perintah ini harus lolos:

```bash
swiftformat --lint --swift-version 6.0 --language-mode 6 .
swiftlint lint --strict
```

Lint dan format juga dijalankan Xcode Cloud pada setiap PR lewat `ci_scripts/ci_post_clone.sh`. Build dan test dijalankan oleh action Test di workflow PR checks.

Aturan UI (lengkap di `.agents/skills/hig-compliance/SKILL.md`):

- **Dynamic Type**: pakai Text Style (`.body`, `.headline`, dst.) sejak awal, bukan ukuran font statis seperti `.font(.system(size: 17))`. Cek preview di `.dynamicTypeSize(.accessibility5)`.
- **Color contrast**: minimal 4.5:1 untuk teks kecil, 3:1 untuk teks besar/bold, di Light, Dark, dan Increase Contrast.

## ESP32 dan AS7341

Sketch Arduino ada di [selaras_esp32_connectble/selaras_esp32_connectble.ino](selaras_esp32_connectble/selaras_esp32_connectble.ino).

1. Pasang library **Adafruit AS7341** melalui Arduino Library Manager. Library ini akan memasang dependency I2C yang dibutuhkan.
2. Untuk **ESP32C3 Dev Module** pada sketch ini, hubungkan:

   ```text
   AS7341 VCC → ESP32 3V3
   AS7341 GND → ESP32 GND
   AS7341 SDA → ESP32 GPIO6
   AS7341 SCL → ESP32 GPIO7
   ```

   Pin tersebut diatur eksplisit melalui `Wire.begin(6, 7)`.
3. Upload sketch ke ESP32. Sketch membaca delapan kanal visible AS7341 setiap 500 ms dan mengirim JSON melalui characteristic BLE yang sama dengan aplikasi:

   ```json
   {"visibleAverage":735.0,"clear":1200,"nir":200}
   ```

Saat perangkat tersambung, pembacaan pertama disimpan sebagai baseline dan ditampilkan sebagai **100%**. Setiap notification berikutnya menghitung kepekatan relatif dengan rumus:

```text
kepekatan sekarang = (visibleAverage sekarang / visibleAverage awal) × 100
```

Nilai **Kepekatan Warna Sekarang** diperbarui secara streaming melalui BLE notification, sehingga berubah mengikuti pembacaan AS7341. Jika pembacaan gagal, aplikasi menampilkan error dan tidak menganggap nilai sensor berhasil terbaca.

Batas kepekatan warna adalah **80%**. Jika nilai turun di bawah 80%, aplikasi menampilkan peringatan untuk menambahkan 10 gram pewarna. Aplikasi juga menerima field JSON opsional `ph`; jika nilainya di bawah **7**, aplikasi menampilkan peringatan untuk menambahkan 10 gram soda abu. Sketch ESP32 perlu mengirim field tersebut setelah sensor pH tersedia.

## CI dan TestFlight (Xcode Cloud)

Script dan shared scheme sudah ada di repo. Workflow dibuat manual di Xcode (Product → Xcode Cloud):

1. **PR checks**: start condition pull request ke `dev`, `staging`, dan `main`. Action: Test scheme `Selaras`.
2. **TestFlight**: start condition perubahan pada branch rilis. Action: Archive, lalu post-action TestFlight (Internal Testing).
