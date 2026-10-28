//
//  SelarasApp.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftData
import SwiftUI

@main
struct SelarasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SelarasSchema.models)
    }
}
