//
//  EmptyDeviceView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct EmptyDeviceView: View {
    var body: some View {
        VStack(spacing: 8) {
            DeviceSymbolView()

            Text("Belum ada perangkat")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Tambahkan perangkat untuk memulai")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
