//
//  PerbaikiLarutanViewModel.swift
//  Serona
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

    private(set) var issue: QualityIssue
    private(set) var steps: [PerbaikiStep]
    var jumlahAir: Double = 1.0
    private(set) var isFinished = false
    private(set) var activeIndex = 0

    init(issue: QualityIssue) {
        self.issue = issue
        self.steps = Self.calculateSteps(for: issue, existingSteps: [])
    }
    
    // Merge new issues and append necessary steps without loosing active progress
    func updateIssue(_ newIssue: QualityIssue) {
        guard newIssue != issue else { return }
        let combined = issue.combining(with: newIssue)
        self.issue = combined
        self.steps = Self.calculateSteps(for: combined, existingSteps: steps)
    }
    
    private static func calculateSteps(for issue: QualityIssue, existingSteps: [PerbaikiStep]) -> [PerbaikiStep] {
        let canonicalOrder: [PerbaikiStep] = [.air, .phAir, .kepekatan]
        let requiredSteps: Set<PerbaikiStep> = switch issue {
        case .kepekatan: [.air, .kepekatan]
        case .phAir: [.air, .phAir]
        case .keduanya: [.air, .phAir, .kepekatan]
        }
        
        var updated: [PerbaikiStep] = []
        for step in canonicalOrder {
            if existingSteps.contains(step) || requiredSteps.contains(step) {
                updated.append(step)
            }
        }
        return updated
    }
    
    var jumlahAirFormatted: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: jumlahAir)) ?? "\(jumlahAir)"
    }

    func isActive(_ step: PerbaikiStep) -> Bool {
        !isFinished && activeIndex < steps.count && steps[activeIndex] == step
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
