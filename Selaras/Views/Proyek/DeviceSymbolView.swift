//
//  DeviceSymbolView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct DeviceSymbolView: View {
    var body: some View {
        Image(systemName: "sensor.radiowaves.left.and.right")
            .font(.largeTitle.weight(.bold))
            .accessibilityHidden(true)
    }
}
