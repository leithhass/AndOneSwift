//
//  ProfileView.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 15/10/2025.
//
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [Game]
    @Query private var courts: [Court]

    @State private var showConfirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Stats (local)") {
                    LabeledContent("Matchs à venir", value: "\(games.filter { $0.scheduledAt >= Date() }.count)")
                    LabeledContent("Matchs passés", value: "\(games.filter { $0.scheduledAt < Date() }.count)")
                    LabeledContent("Courts favoris", value: "\(FavoritesService.ids().count)")
                }

                Section("Préférences") {
                    Toggle(isOn: .constant(true)) { Text("Notifications de rappel") }  // à brancher si besoin
                        .disabled(true)
                    Picker("Thème", selection: .constant(0)) { Text("Système").tag(0); Text("Clair").tag(1); Text("Sombre").tag(2) }
                        .disabled(true)
                }

                Section("Administration") {
                    NavigationLink("Dashboard Admin", destination: AdminDashboardView())
                    Button("Réinitialiser données de démo", role: .destructive) { showConfirmReset = true }
                }
            }
            .navigationTitle("Profil")
            .confirmationDialog("Supprimer toutes les données et recréer les exemples ?",
                                isPresented: $showConfirmReset, titleVisibility: .visible) {
                Button("Réinitialiser", role: .destructive) {
                    try? context.delete(model: Game.self)
                    try? context.delete(model: Player.self)
                    try? context.delete(model: Court.self)
                    try? context.save()
                    UserDefaults.standard.removeObject(forKey: "andone.seed_done_date")
                    BootstrapService.seedIfNeeded(context: context, force: true)
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }
}

private extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        let all = try self.fetch(FetchDescriptor<T>())
        for x in all { self.delete(x) }
    }
}

