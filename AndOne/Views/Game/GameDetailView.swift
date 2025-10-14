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

    var body: some View {
        Form {
            Section("Infos") {
                LabeledContent("Type", value: game.kind.rawValue)
                LabeledContent("Terrain", value: "\(game.court.name) — \(game.court.city) [\(game.court.kind.rawValue)]")
                LabeledContent("Heure", value: game.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Places", value: "\(game.players.count)/\(game.capacity) (reste \(game.spotsLeft))")
            }
            Section("Joueurs") {
                ForEach(game.players) { p in Text(p.nickname) }
                Picker("Rejoindre en tant que", selection: $selected) {
                    ForEach(players) { p in Text(p.nickname).tag(Optional(p)) }
                }
                HStack {
                    Button("Rejoindre") { tryJoin() }.disabled(selected == nil || game.spotsLeft == 0)
                    Button("Quitter") { tryLeave() }.disabled(selected == nil)
                }
                if let e = error { Text(e).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Match \(game.kind.rawValue)")
        .onAppear {
            guard !didInitSelection else { return }
            if let someone = players.first(where: { p in !game.players.contains(where: { $0.id == p.id }) }) {
                selected = someone
            } else {
                selected = players.first
            }
            didInitSelection = true
        }
    }

    private func tryJoin() {
        guard let selected else { return }
        do {
            try vm.join(game, player: selected, context: context)
            self.error = nil
        } catch let err {
            self.error = err.localizedDescription
        }
    }

    private func tryLeave() {
        guard let selected else { return }
        do {
            try vm.leave(game, player: selected, context: context)
            self.error = nil
        } catch let err {
            self.error = err.localizedDescription
        }
    }
}
