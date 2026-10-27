//
//  Color.swift
//  Selaras
//
//  Created by Steffany Florence on 21/10/26.
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

    /// `#RRGGBB` (huruf besar) dari warna ini di color space sRGB.
    ///
    /// Komponen di luar gamut sRGB (misalnya pilihan Display-P3) dijepit ke 0...1.
    /// Bila warna tidak bisa diuraikan menjadi RGB sama sekali, hasilnya `#000000`.
    var hexString: String {
        let components = Self.srgbComponents(of: UIColor(self))
        return "#" + components.map(Self.hexByte).joined()
    }

    private static func srgbComponents(of color: UIColor) -> [CGFloat] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return [red, green, blue]
        }

        // Fallback untuk color space yang tidak langsung RGB.
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)
        let converted = srgb.flatMap { color.cgColor.converted(to: $0, intent: .defaultIntent, options: nil) }
        guard let values = converted?.components, values.count >= 3 else { return [0, 0, 0] }
        return Array(values.prefix(3))
    }

    private static func hexByte(_ component: CGFloat) -> String {
        let clamped = min(max(component, 0), 1)
        let byte = UInt8((clamped * 255).rounded())
        let digits = String(byte, radix: 16, uppercase: true)
        return digits.count == 1 ? "0" + digits : digits
    }
}
