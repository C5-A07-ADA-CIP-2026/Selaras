# Selaras

Aplikasi iOS yang dikerjakan oleh tim 3 orang. Halamannya:

- **Resep**: halaman utama (tab pertama). Tombol di kanan atas membuka **Riwayat**.
- **Proyek**: tab kedua.
- **Riwayat**: dibuka dari Resep, bukan tab sendiri.

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
├── SelarasApp.swift
├── ContentView.swift        TabView (Resep, Proyek)
├── AppTab.swift
└── Features/
    ├── Resep/               ResepView, ResepViewModel, ResepModel
    ├── Proyek/              ProyekView, ProyekViewModel, ProyekModel
    └── Riwayat/             RiwayatView, RiwayatViewModel, RiwayatModel
SelarasTests/                mirror dari struktur di atas
```

Arsitektur MVVM, test-first dengan Swift Testing. Komponen yang dipakai bersama taruh di `Selaras/Shared/`. Detail aturan ada di [AGENTS.md](AGENTS.md).

## Branch dan PR

- `main` (default, rilis TestFlight), `staging`, `dev` (integrasi).
- Kerja di branch fitur masing-masing, lalu buka PR ke `dev`.
- Commit pakai Conventional Commits: `feat(resep): add recipe list`.
- Judul PR: `<type>(KAN-12): Nama singkat`. Tiket Jira ada di <https://mariabelenn2405.atlassian.net/browse/KAN>.
- Sertakan screenshot untuk perubahan UI.

## Kualitas kode

Sebelum PR, dua perintah ini harus lolos:

```bash
swiftformat --lint --swift-version 6.0 --language-mode 6 .
swiftlint lint --strict
```

Keduanya juga dijalankan Xcode Cloud pada setiap PR lewat `ci_scripts/ci_post_clone.sh`.

## CI dan TestFlight (Xcode Cloud)

Script dan shared scheme sudah ada di repo. Workflow dibuat manual di Xcode (Product → Xcode Cloud):

1. **PR checks**: start condition pull request ke `dev`, `staging`, dan `main`. Action: Test scheme `Selaras`.
2. **TestFlight**: start condition perubahan pada branch rilis. Action: Archive, lalu post-action TestFlight (Internal Testing).
