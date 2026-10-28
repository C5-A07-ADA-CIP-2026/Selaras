//
//  PerbaikiLarutanViewModel.swift
//  Selaras
//

import Foundation
import Observation

/// One step of the "Perbaiki Larutan" guide.
enum PerbaikiStep: Equatable {
    case air
    case phAir
    case kepekatan
}

/// Walks the user through the steps that bring the solution back above its limits, one at a time.
@MainActor
@Observable
final class PerbaikiLarutanViewModel {
    static let gramSodaAbu = 10
    static let gramPewarna = 10

    let steps: [PerbaikiStep]
    var jumlahAir = 7
    private(set) var isFinished = false
    private var activeIndex = 0

    init(issue: QualityIssue) {
        steps = switch issue {
        case .kepekatan: [.air, .kepekatan]
        case .phAir: [.air, .phAir]
        case .keduanya: [.air, .phAir, .kepekatan]
        }
    }

    func isActive(_ step: PerbaikiStep) -> Bool {
        !isFinished && steps[activeIndex] == step
    }

    func isDone(_ step: PerbaikiStep) -> Bool {
        guard let index = steps.firstIndex(of: step) else { return false }
        return isFinished || index < activeIndex
    }

    func buttonTitle(for step: PerbaikiStep) -> String {
        step == steps.last ? "Selesai" : "Selanjutnya"
    }

    /// Completes the active step and activates the next one; the last step finishes the guide.
    func lanjut() {
        guard !isFinished else { return }
        if activeIndex == steps.count - 1 {
            isFinished = true
        } else {
            activeIndex += 1
        }
    }
}
