import SwiftUI
import SwiftData

struct AdminDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Court.city) private var courts: [Court]
    @Query(sort: \Player.nickname) private var players: [Player]
    @StateObject private var vm = AdminViewModel()

    // Court form
    @State private var name = ""
    @State private var governorate: Governorate = .tunis
    @State private var city = ""
    @State private var kind: CourtKind = .full
    @State private var hoops = 2
    @State private var hasLighting = true
    @State private var hasLocker = false
    @State private var hasStands = false
    @State private var hasWater = true
    @State private var hasParking = true
    @State private var isPMR = true
    @State private var surface: SurfaceType = .concrete
    @State private var condition: GroundCondition = .good

    // Player form
    @State private var nickname = ""
    @State private var level = 3

    // Debug
    @State private var showConfirmReset = false
    private var seededDate: Date? {
        UserDefaults.standard.object(forKey: "andone.seed_done_date") as? Date
    }

    var body: some View {
        Form {
            Section("Nouveau terrain") {
                Picker("Gouvernorat", selection: $governorate) {
                    ForEach(Governorate.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Ville", text: $city)
                TextField("Nom", text: $name)
                Picker("Type", selection: $kind) { Text("Demi").tag(CourtKind.half); Text("Complet").tag(CourtKind.full) }
                Stepper("Paniers: \(hoops)", value: $hoops, in: 1...4)

                Toggle("Éclairage", isOn: $hasLighting)
                Toggle("Vestiaires", isOn: $hasLocker)
                Toggle("Gradins", isOn: $hasStands)
                Toggle("Point d’eau", isOn: $hasWater)
                Toggle("Parking", isOn: $hasParking)
                Toggle("Accessible PMR", isOn: $isPMR)

                Picker("Revêtement", selection: $surface) {
                    ForEach(SurfaceType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("État du sol", selection: $condition) {
                    ForEach(GroundCondition.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }

                Button("Ajouter le terrain") {
                    let c = Court(
                        name: name, governorate: governorate, city: city, kind: kind, hoops: hoops,
                        hasLighting: hasLighting, hasLockerRoom: hasLocker, hasStands: hasStands,
                        hasWaterPoint: hasWater, hasParking: hasParking, isAccessiblePMR: isPMR,
                        surface: surface, condition: condition
                    )
                    context.insert(c); try? context.save()
                    name = ""; city = ""
                }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section("Terrains") {
                if courts.isEmpty {
                    EmptyStateView(title: "Aucun terrain", message: "Ajoute ton premier terrain ci-dessus.")
                } else {
                    ForEach(courts) { c in
                        Text("\(c.name) — \(c.city) [\(c.kind.rawValue)] • \(c.governorate.rawValue)")
                    }
                }
            }

            Section("Nouveau joueur") {
                TextField("Pseudo", text: $nickname)
                Stepper("Niveau: \(level)", value: $level, in: 1...5)
                Button("Ajouter le joueur") {
                    vm.addPlayer(nickname: nickname, level: level, context: context); nickname = ""
                }.disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section("Joueurs") {
                if players.isEmpty {
                    EmptyStateView(title: "Aucun joueur", message: "Ajoute au moins un joueur pour créer des matchs.")
                } else {
                    ForEach(players) { Text("\($0.nickname) (\($0.level))") }
                }
            }

            Section("Debug") {
                if let seededDate {
                    Text("Seeds: \(seededDate.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Seeds: non initialisés").foregroundStyle(.secondary)
                }
                Button("Réinitialiser les données de démo", role: .destructive) {
                    showConfirmReset = true
                }
            }
        }
        .navigationTitle("Admin")
        .confirmationDialog("Supprimer toutes les données et recréer les exemples ?",
                            isPresented: $showConfirmReset, titleVisibility: .visible) {
            Button("Réinitialiser", role: .destructive) {
                // wipe all and reseed
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

// Helper to delete all rows of a model
private extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        let all = try self.fetch(FetchDescriptor<T>())
        for x in all { self.delete(x) }
    }
}
