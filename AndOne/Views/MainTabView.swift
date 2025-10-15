//
//  MainTabView.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 15/10/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "sportscourt")
                    Text("Matchs")
                }

            ExplorerView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Explorer")
                }

            MyMatchesView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Mes matchs")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profil")
                }
        }
    }
}
