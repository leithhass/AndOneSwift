import SwiftUI
import SwiftData

struct CreateGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var courts: [Court]
    @Query private var players: [Player]
    @State private var kind: GameKind = .threeVthree
    @State private var date = Calendar.current.date(byAdding: .hour, value: 2, to: .now)!
    @State private var court: Court?
    @State private var creator: Player?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type de match", selection: $kind) {
                    ForEach(GameKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Heure", selection: $date, displayedComponents: [.date, .hourAndMinute])

                Picker("Terrain", selection: $court) {
                    ForEach(courts) {
                        Text("\($0.name) — \($0.city) [\($0.kind.rawValue)]").tag(Optional($0))
                    }
                }
                Picker("Créateur", selection: $creator) {
                    ForEach(players) { Text($0.nickname).tag(Optional($0)) }
                }

                if let c = court { ruleHint(for: c) }
                if let e = error { Text(e).foregroundStyle(.red) }
            }
            .navigationTitle("Nouveau match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") { create() }.disabled(court == nil || creator == nil)
                }
            }
        }
    }

    @ViewBuilder private func ruleHint(for c: Court) -> some View {
        let comp: String = {
            switch kind.requiredCourt {
            case .any: "Demi ou Complet"
            case .halfOnly: "Demi seulement"
            case .fullOnly: "Complet obligatoire"
            }
        }()
        let ok = Game(kind: kind, scheduledAt: date, court: c, creatorId: UUID()).isCourtCompatible()
        HStack {
            Image(systemName: ok ? "checkmark.seal" : "xmark.octagon")
            Text("Capacité: \(kind.capacity) — Court requis: \(comp)")
        }
        .foregroundStyle(ok ? .green : .red)
    }

    private func create() {
        guard let court, let creator else { return }
        do {
            try GameViewModel().create(kind: kind, date: date, court: court, creator: creator, context: context)
            dismiss()
        } catch {
            self.error = "Terrain incompatible pour ce format."
        }
    }
}
