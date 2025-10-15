//
//  Explorer.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 15/10/2025.
//

import SwiftUI
import SwiftData

struct ExplorerView: View {
    @Query(sort: \Court.city) private var courts: [Court]
    @State private var gov: Governorate? = nil
    @State private var kind: CourtKind? = nil
    @State private var onlyFavs = false

    var body: some View {
        NavigationStack {
            List(filtered) { c in
                HStack(spacing: 12) {
                    Image(systemName: c.kind == .half ? "rectangle.leadinghalf.inset.filled" : "rectangle.inset.filled")
                        .foregroundStyle(Color.andInk)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.name).fontWeight(.semibold)
                        Text("\(c.city) • \(c.governorate.rawValue)")
                            .font(.caption).foregroundStyle(Color.andMuted)
                        CourtAmenityIcons(court: c)

                            .padding(.top, 2)
                    }
                    Spacer()
                    Button {
                        FavoritesService.toggle(courtId: c.id)
                        Haptics.light()
                    } label: {
                        Image(systemName: FavoritesService.isFavorite(courtId: c.id) ? "star.fill" : "star")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.andOrange)
                    .accessibilityLabel("Favori")
                }
                .contentShape(Rectangle())
            }
            .navigationTitle("Explorer")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Tous") { gov = nil }
                        ForEach(Governorate.allCases, id: \.self) { g in Button(g.rawValue) { gov = g } }
                    } label: { Image(systemName: "globe.europe.africa.fill") }

                    Menu {
                        Button("Tous") { kind = nil }
                        Button("Demi") { kind = .half }
                        Button("Complet") { kind = .full }
                    } label: { Image(systemName: "rectangle.grid.2x2") }

                    Toggle(isOn: $onlyFavs) { Text("Mes courts") }
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private var filtered: [Court] {
        courts.filter { c in
            (gov == nil || c.governorate == gov) &&
            (kind == nil || c.kind == kind) &&
            (!onlyFavs || FavoritesService.isFavorite(courtId: c.id))
        }
    }
}
