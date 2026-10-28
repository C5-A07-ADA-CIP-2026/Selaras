//
//  SeronaApp.swift
//  Serona
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftData
import SwiftUI

@main
struct SeronaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SeronaSchema.models)
    }
}
