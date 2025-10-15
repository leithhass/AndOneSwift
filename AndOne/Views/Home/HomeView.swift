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
    enum TimeScope: String, CaseIterable { case today = "Aujourd’hui", week = "Semaine" }
    @State private var timeScope: TimeScope = .today

    @State private var showCreate = false
    @State private var showToast: (text: String, icon: String, tint: Color)? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    if sections.isEmpty {
                        EmptyStateView(
                            title: "Aucun match à venir",
                            message: "Crée ton premier match ou ajuste les filtres.",
                            actionTitle: "Créer un match"
                        ) { showCreate = true }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(sections) { section in
                                Text(section.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.andMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 10)

                                ForEach(section.games) { g in
                                    NavigationLink(value: g) {
                                        MatchCard(game: g) { joined in
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                                if joined {
                                                    showToast = ("Ajouté au match ✅", "checkmark.circle.fill", .andSuccess)
                                                } else {
                                                    showToast = ("Impossible de rejoindre ❌", "xmark.octagon.fill", .andDanger)
                                                }
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                                withAnimation { showToast = nil }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .animation(.easeInOut, value: sections.map(\.id))
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("AndOne")
                .toolbar { toolbar }
                // FAB +
                Button {
                    Haptics.light()
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .padding(18)
                        .background(Color.andOrange, in: Circle())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                        .padding(.trailing, 20).padding(.bottom, 28)
                        .accessibilityLabel("Créer un match")
                }

                // Toast
                if let toast = showToast {
                    Toast(text: toast.text, systemName: toast.icon, tint: toast.tint)
                        .padding(.bottom, 94)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .top) { stickyFilters }
            .sheet(isPresented: $showCreate) {
                CreateGameView().presentationDetents([.medium, .large])
            }
            .navigationDestination(for: Game.self) { g in GameDetailView(game: g) }
        }
        .task { BootstrapService.seedIfNeeded(context: context) }
        .refreshable { /* pattern attendu */ }
    }

    // MARK: - Filtering
    private var filtered: [Game] {
        games.filter { g in
            guard g.scheduledAt >= Date() else { return false } // à venir
            let inScope: Bool = {
                switch timeScope {
                case .today:
                    return Calendar.current.isDateInToday(g.scheduledAt)
                case .week:
                    let end = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                    return g.scheduledAt < end
                }
            }()
            let govOK = selectedGov == nil || g.court.governorate == selectedGov
            let kindOK = vm.selectedKind == nil || g.kind == vm.selectedKind
            let courtOK = courtKind == nil || g.court.kind == courtKind
            let spotsOK = !onlyWithSpots || g.spotsLeft > 0
            let featOK =
                (!featureLighting || g.court.hasLighting) &&
                (!featureParking || g.court.hasParking) &&
                (!featureWater || g.court.hasWaterPoint)
            return inScope && govOK && kindOK && courtOK && spotsOK && featOK
        }
    }

    // Sections (group by day)
    private struct GameSection: Identifiable { var id: Date { date }; let date: Date; let games: [Game] }
    private var sections: [GameSection] {
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.scheduledAt) }
        let sortedDays = grouped.keys.sorted()
        return sortedDays.map { day in
            let dayGames = (grouped[day] ?? []).sorted { $0.scheduledAt < $1.scheduledAt }
            return GameSection(date: day, games: dayGames)
        }
    }

    // MARK: - Toolbar (icônes à droite)
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            // Gouvernorat
            Menu {
                Button("Tous") { selectedGov = nil }
                ForEach(Governorate.allCases, id: \.self) { g in
                    Button(g.rawValue) { selectedGov = g }
                }
            } label: {
                Image(systemName: "globe.europe.africa.fill")
            }

            // Type (1v1…5v5)
            Menu {
                Button("Tous") { vm.selectedKind = nil }
                ForEach(GameKind.allCases, id: \.self) { k in Button(k.rawValue) { vm.selectedKind = k } }
            } label: {
                Image(systemName: "person.2.square.stack.fill")
            }

            // Filtres avancés
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
    }

    // MARK: - Sticky filters (segmented + compteur)
    private var stickyFilters: some View {
        VStack(spacing: 10) {
            Picker("", selection: $timeScope) {
                ForEach(TimeScope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // compteur “X matchs aujourd’hui/7 jours”
            let count = filtered.count
            Text(timeScope == .today ? "\(count) matchs aujourd’hui" : "\(count) matchs à venir (7 jours)")
                .font(.footnote).foregroundStyle(Color.andMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
                .transition(.opacity)
        }
        .background(.thinMaterial)
    }
}
