//
//  MeasurementWarningTracker.swift
//  Selaras
//

import Foundation

/// Decides when a reading deserves a warning and what it says.
nonisolated struct MeasurementWarningTracker {
    private var hasWarnedAboutLowConcentration = false

    /// The concentration warning is emitted once per dip; it re-arms when the concentration reaches the limit again.
    mutating func concentrationWarning(for concentration: Double, limit: Double) -> String? {
        guard concentration < limit else {
            hasWarnedAboutLowConcentration = false
            return nil
        }
        guard !hasWarnedAboutLowConcentration else { return nil }
        hasWarnedAboutLowConcentration = true
        return "Kepekatan warna saat ini di bawah \(Self.format(limit))%. "
            + "Tambahkan 10 gram pewarna untuk menjaga kualitas dan ketajaman warna batik."
    }

    /// The pH warning is repeated for every reading below the limit.
    static func waterPHWarning(for waterPH: Double, limit: Double) -> String? {
        guard waterPH < limit else { return nil }
        return "pH air saat ini di bawah \(format(limit)). "
            + "Tambahkan 10 gram soda abu untuk menjaga kualitas dan ketajaman warna batik."
    }

    /// Locale-independent, drops trailing zeros: 80 -> "80", 87.5 -> "87.5".
    private static func format(_ value: Double) -> String {
        String(format: "%g", value)
    }

    mutating func reset() {
        hasWarnedAboutLowConcentration = false
    }
}
