//
//  PerbaikiLarutanViewModelTests.swift
//  SelarasTests
//

@testable import Selaras
import Testing

@MainActor
struct PerbaikiLarutanViewModelTests {
    @Test("Both readings low give the water, pH and concentration steps in that order")
    func stepsForBoth() {
        let viewModel = PerbaikiLarutanViewModel(issue: .keduanya)

        #expect(viewModel.steps == [.air, .phAir, .kepekatan])
    }

    @Test("A low pH alone skips the concentration step")
    func stepsForPH() {
        #expect(PerbaikiLarutanViewModel(issue: .phAir).steps == [.air, .phAir])
    }

    @Test("A low concentration alone skips the pH step")
    func stepsForKepekatan() {
        #expect(PerbaikiLarutanViewModel(issue: .kepekatan).steps == [.air, .kepekatan])
    }

    @Test("Starts on the first step with the default amount of water")
    func startsOnFirstStep() {
        let viewModel = PerbaikiLarutanViewModel(issue: .keduanya)

        #expect(viewModel.isActive(.air))
        #expect(!viewModel.isActive(.phAir))
        #expect(!viewModel.isDone(.air))
        #expect(viewModel.jumlahAir == 7)
        #expect(!viewModel.isFinished)
    }

    @Test("Next completes the current step and activates the following one")
    func nextAdvances() {
        let viewModel = PerbaikiLarutanViewModel(issue: .keduanya)

        viewModel.lanjut()

        #expect(viewModel.isDone(.air))
        #expect(viewModel.isActive(.phAir))
        #expect(!viewModel.isActive(.kepekatan))
        #expect(!viewModel.isFinished)
    }

    @Test("The last step finishes the guide and is labelled Selesai")
    func lastStepFinishes() {
        let viewModel = PerbaikiLarutanViewModel(issue: .phAir)
        #expect(viewModel.buttonTitle(for: .air) == "Selanjutnya")
        #expect(viewModel.buttonTitle(for: .phAir) == "Selesai")

        viewModel.lanjut()
        viewModel.lanjut()

        #expect(viewModel.isDone(.phAir))
        #expect(viewModel.isFinished)
    }

    @Test("Next after finishing does nothing")
    func nextAfterFinishing() {
        let viewModel = PerbaikiLarutanViewModel(issue: .kepekatan)
        viewModel.lanjut()
        viewModel.lanjut()

        viewModel.lanjut()

        #expect(viewModel.isFinished)
        #expect(viewModel.isDone(.kepekatan))
    }
}
