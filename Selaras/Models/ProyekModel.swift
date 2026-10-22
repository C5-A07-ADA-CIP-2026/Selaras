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

    func withCurrentConcentration(
        _ measurement: ColorMeasurement,
        relativeTo baseline: Double
    ) -> ProyekColorMeasurements {
        var updatedCurrent = current
        guard let index = updatedCurrent.firstIndex(where: { $0.id == "current-color-concentration" }) else {
            return self
        }

        updatedCurrent[index] = ProyekMeasurement(
            id: updatedCurrent[index].id,
            title: updatedCurrent[index].title,
            value: measurement.formattedConcentration(relativeTo: baseline),
            isCurrent: updatedCurrent[index].isCurrent
        )
        return ProyekColorMeasurements(initial: initial, current: updatedCurrent)
    }

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
