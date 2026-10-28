//
//  QualityAlertModel.swift
//  Selaras
//

import Foundation

/// What fell below its limit: the color concentration, the water pH, or both.
enum QualityIssue: Equatable {
    case kepekatan
    case phAir
    case keduanya
}

/// The "Kualitas Larutan Menurun" sheet: what is low and what to do about it.
struct QualityAlert: Equatable {
    let issue: QualityIssue
    let message: String
}
