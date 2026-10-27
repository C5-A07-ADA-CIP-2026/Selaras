//
//  ContentView.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage) {
                    NavigationStack {
                        view(for: tab)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
        case .resep: ResepView()
        case .proyek: ProyekListView()
        }
    }
}

#Preview {
    ContentView()
}
