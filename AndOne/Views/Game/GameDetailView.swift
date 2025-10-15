import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]
    @StateObject private var vm = GameViewModel()

    var game: Game

    @State private var selected: Player?
    @State private var error: String?
    @State private var didInitSelection = false

    // Un joueur sélectionné est-il déjà inscrit à ce match ?
    private var isSelectedAlreadyInGame: Bool {
        guard let selected else { return false }
        return game.players.contains(where: { $0.id == selected.id })
    }

    var body: some View {
        Form {
            Section("Infos") {
                LabeledContent("Type", value: game.kind.rawValue)
                LabeledContent(
                    "Terrain",
                    value: "\(game.court.name) — \(game.court.city) [\(game.court.kind.rawValue)]"
                )
                LabeledContent(
                    "Heure",
                    value: game.scheduledAt.formatted(date: .abbreviated, time: .shortened)
                )
                LabeledContent(
                    "Places",
                    value: "\(game.players.count)/\(game.capacity) (reste \(game.spotsLeft))"
                )
            }

            Section("Joueurs") {
                ForEach(game.players) { p in
                    Text(p.nickname)
                }

                Picker("Rejoindre en tant que", selection: $selected) {
                    ForEach(players) { p in
                        Text(p.nickname).tag(Optional(p))
                    }
                }

                HStack(spacing: 16) {
                    Button("Rejoindre") { tryJoin() }
                        .buttonStyle(.borderedProminent)
                        .tint(.andOrange)
                        .disabled(
                            selected == nil ||
                            game.spotsLeft == 0 ||
                            isSelectedAlreadyInGame
                        )

                    Button("Quitter") { tryLeave() }
                        .buttonStyle(.bordered)
                        .disabled(
                            selected == nil ||
                            !isSelectedAlreadyInGame
                        )
                }

                if let e = error {
                    Text(e).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Match \(game.kind.rawValue)")
        .onAppear {
            guard !didInitSelection else { return }
            // Pré-sélectionner un joueur non inscrit si possible, sinon le premier
            if let someone = players.first(where: { p in
                !game.players.contains(where: { $0.id == p.id })
            }) {
                selected = someone
            } else {
                selected = players.first
            }
            didInitSelection = true
        }
    }

    private func tryJoin() {
        guard let selected else { return }

        // Empêche le double-join
        guard !game.players.contains(where: { $0.id == selected.id }) else {
            error = "\(selected.nickname) est déjà inscrit."
            Haptics.warning()
            return
        }

        // Empêche de rejoindre si plein
        guard game.spotsLeft > 0 else {
            error = "Le match est complet."
            Haptics.warning()
            return
        }

        do {
            try vm.join(game, player: selected, context: context)
            self.error = nil
            Haptics.success()
        } catch let err {
            self.error = err.localizedDescription
            Haptics.error()
        }
    }

    private func tryLeave() {
        guard let selected else { return }

        // Ne peut quitter que s'il est inscrit
        guard game.players.contains(where: { $0.id == selected.id }) else {
            error = "\(selected.nickname) n’est pas inscrit."
            Haptics.warning()
            return
        }

        do {
            try vm.leave(game, player: selected, context: context)
            self.error = nil
            Haptics.success()
        } catch let err {
            self.error = err.localizedDescription
            Haptics.error()
        }
    }
}
