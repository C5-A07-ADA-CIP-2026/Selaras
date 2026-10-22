//
//  ProyekModel.swift
//  Selaras
//

struct ProyekMeasurement: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let isCurrent: Bool
}

struct ProyekColorMeasurements {
    let initial: [ProyekMeasurement]
    let current: [ProyekMeasurement]

    static let selectedColor = ProyekColorMeasurements(
        initial: [
            ProyekMeasurement(
                id: "initial-color-concentration",
                title: "Kepekatan Warna Awal",
                value: "100%",
                isCurrent: false
            ),
            ProyekMeasurement(
                id: "color-concentration-limit",
                title: "Batas Kepekatan Warna",
                value: "95%",
                isCurrent: false
            ),
            ProyekMeasurement(
                id: "initial-water-ph",
                title: "pH Air Awal",
                value: "12",
                isCurrent: false
            ),
            ProyekMeasurement(
                id: "water-ph-limit",
                title: "Batas pH",
                value: "10",
                isCurrent: false
            ),
        ],
        current: [
            ProyekMeasurement(
                id: "current-color-concentration",
                title: "Kepekatan Warna Sekarang",
                value: "93%",
                isCurrent: true
            ),
            ProyekMeasurement(
                id: "current-water-ph",
                title: "pH Air Sekarang",
                value: "11",
                isCurrent: true
            ),
        ]
    )

    var displayedMeasurements: [ProyekMeasurement] {
        guard current.count >= 2, initial.count >= 4 else {
            return initial
        }

        return [
            current[0],
            initial[0],
            initial[1],
            current[1],
            initial[2],
            initial[3],
        ]
    }
}
