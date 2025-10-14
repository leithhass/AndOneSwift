import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.scheduledAt) private var games: [Game]
    @StateObject private var vm = GameViewModel()

    // Filtres
    @State private var selectedGov: Governorate? = nil
    @State private var onlyWithSpots = true
    @State private var courtKind: CourtKind? = nil
    @State private var featureLighting = false
    @State private var featureParking = false
    @State private var featureWater = false

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(
                        title: "Aucun match",
                        message: "Crée ton premier match ou ajuste les filtres.",
                        actionTitle: "Créer un match"
                    ) { vm.query = ""; /* open sheet via toolbar button below */ }
                } else {
                    List {
                        ForEach(groupedByDate.keys.sorted(), id: \.self) { day in
                            Section(day.formatted(date: .abbreviated, time: .omitted)) {
                                ForEach(groupedByDate[day]!) { g in
                                    NavigationLink(value: g) {
                                        HStack {
                                            Text(g.kind.rawValue).font(.headline)
                                            Spacer()
                                            Text(g.court.name).lineLimit(1)
                                            Label("\(g.spotsLeft)", systemImage: "person.2.fill")
                                                .labelStyle(.titleAndIcon)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("AndOne")
            .toolbar { toolbar }
            .navigationDestination(for: Game.self) { g in GameDetailView(game: g) }
        }
        .task { BootstrapService.seedIfNeeded(context: context) } // exécuté 1 seule fois
    }

    // MARK: - Filtering
    private var filtered: [Game] {
        games.filter { g in
            let govOK = selectedGov == nil || g.court.governorate == selectedGov
            let kindOK = vm.selectedKind == nil || g.kind == vm.selectedKind
            let courtOK = courtKind == nil || g.court.kind == courtKind
            let spotsOK = !onlyWithSpots || g.spotsLeft > 0
            let featOK =
                (!featureLighting || g.court.hasLighting) &&
                (!featureParking || g.court.hasParking) &&
                (!featureWater || g.court.hasWaterPoint)
            return govOK && kindOK && courtOK && spotsOK && featOK
        }
    }

    private var groupedByDate: [Date: [Game]] {
        Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.scheduledAt) }
            .mapValues { $0.sorted { $0.scheduledAt < $1.scheduledAt } }
    }

    // MARK: - UI
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu(selectedGov?.rawValue ?? "Tous les gouvernorats") {
                Button("Tous") { selectedGov = nil }
                ForEach(Governorate.allCases, id: \.self) { g in
                    Button(g.rawValue) { selectedGov = g }
                }
            }
        }
        ToolbarItem(placement: .principal) {
            Menu(vm.selectedKind?.rawValue ?? "Type") {
                Button("Tous") { vm.selectedKind = nil }
                ForEach(GameKind.allCases, id: \.self) { k in
                    Button(k.rawValue) { vm.selectedKind = k }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Toggle("Places dispo", isOn: $onlyWithSpots)
                Menu("Type de court") {
                    Button("Tous") { courtKind = nil }
                    Button("Demi") { courtKind = .half }
                    Button("Complet") { courtKind = .full }
                }
                Toggle("Éclairage", isOn: $featureLighting)
                Toggle("Parking", isOn: $featureParking)
                Toggle("Point d’eau", isOn: $featureWater)
                Button("Réinitialiser filtres", role: .destructive) {
                    selectedGov = nil; vm.selectedKind = nil; onlyWithSpots = true
                    courtKind = nil; featureLighting = false; featureParking = false; featureWater = false
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        ToolbarItem(placement: .bottomBar) {
            NavigationLink("Admin", destination: AdminDashboardView())
        }
    }
}
