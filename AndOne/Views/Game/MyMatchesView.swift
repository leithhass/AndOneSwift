//
//  MyMatchesView.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 15/10/2025.
//

import SwiftUI
import SwiftData

struct MyMatchesView: View {
    @Query(sort: \Game.scheduledAt) private var games: [Game]
    @State private var scope: Scope = .upcoming

    enum Scope: String, CaseIterable { case upcoming = "À venir", past = "Passés" }

    var body: some View {
        NavigationStack {
            List(current) { g in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(g.kind.rawValue).font(.headline)
                        Spacer()
                        Text(g.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(Color.andMuted)
                    }
                    Text("\(g.court.name) — \(g.court.city)")
                        .font(.subheadline)
                        .foregroundStyle(Color.andInk)

                    HStack(spacing: 12) {
                        Label("\(g.players.count)/\(g.capacity)", systemImage: "person.2.fill")
                        if g.status == .full { Label("Complet", systemImage: "xmark.circle") }
                    }
                    .font(.footnote).foregroundStyle(Color.andMuted)

                    if scope == .upcoming {
                        HStack(spacing: 12) {
                            Button {
                                NotificationService.request()
                                NotificationService.scheduleLocal(
                                    title: "Rappel match \(g.kind.rawValue)",
                                    body: "\(g.court.name) à \(g.scheduledAt.formatted(date: .omitted, time: .shortened))",
                                    at: Calendar.current.date(byAdding: .minute, value: -30, to: g.scheduledAt) ?? g.scheduledAt
                                )
                                Haptics.success()
                            } label: {
                                Label("Rappel -30min", systemImage: "bell")
                            }
                            .buttonStyle(.bordered)

                            // Waitlist si FULL
                            Button {
                                let k = WaitlistService.keyFor(courtId: g.court.id, date: g.scheduledAt)
                                WaitlistService.toggle(k)
                                Haptics.light()
                            } label: {
                                let k = WaitlistService.keyFor(courtId: g.court.id, date: g.scheduledAt)
                                Label(WaitlistService.isWatching(k) ? "Surveillé" : "Waitlist", systemImage: "eye")
                            }
                            .buttonStyle(.bordered)
                            .disabled(g.status != .full)
                        }
                        .font(.footnote)
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Mes matchs")
            .safeAreaInset(edge: .top) {
                Picker("", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 6).padding(.bottom, 8)
                .background(.thinMaterial)
            }
        }
    }

    private var current: [Game] {
        let now = Date()
        switch scope {
        case .upcoming: return games.filter { $0.scheduledAt >= now }
        case .past:     return games.filter { $0.scheduledAt <  now }.reversed()
        }
    }
}
