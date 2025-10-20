import SwiftUI
import SwiftData

struct ExplorerView: View {
    @Query(sort: \Court.city) private var courts: [Court]

    @State private var gov: Governorate? = nil
    @State private var kind: CourtKind? = nil
    @State private var onlyFavs = false

    // Cache local des favoris pour un rendu instantané
    @State private var favs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(filtered) { c in
                CourtRow(
                    court: c,
                    isFavorite: favs.contains(c.id),
                    onToggleFavorite: { nowFav in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            FavoritesService.toggle(courtId: c.id)
                            if nowFav {
                                favs.insert(c.id)
                            } else {
                                favs.remove(c.id)
                            }
                        }
                    }
                )
                // Si on est en mode "Mes courts", enlève la ligne quand on retire le favori
                .opacity(!onlyFavs || favs.contains(c.id) ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: favs)
            }
            .navigationTitle("Explorer")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Tous") { gov = nil }
                        ForEach(Governorate.allCases, id: \.self) { g in
                            Button(g.rawValue) { gov = g }
                        }
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
            .onAppear {
                // Sync initial avec le service
                favs = Set(FavoritesService.ids())
            }
        }
    }

    private var filtered: [Court] {
        courts.filter { c in
            (gov == nil || c.governorate == gov) &&
            (kind == nil || c.kind == kind) &&
            (!onlyFavs || favs.contains(c.id))
        }
    }
}

// MARK: - Row

private struct CourtRow: View {
    let court: Court
    let isFavorite: Bool
    let onToggleFavorite: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: court.kind == .half ? "rectangle.leadinghalf.inset.filled" : "rectangle.inset.filled")
                .foregroundStyle(Color.andInk)

            VStack(alignment: .leading, spacing: 2) {
                Text(court.name).fontWeight(.semibold).foregroundStyle(Color.andInk)
                Text("\(court.city) • \(court.governorate.rawValue)")
                    .font(.caption).foregroundStyle(Color.andMuted)
                CourtAmenityIcons(court: court)
                    .padding(.top, 2)
            }

            Spacer()

            Button {
                onToggleFavorite(!isFavorite)
                Haptics.light()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isFavorite ? Color.andOrange : Color.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
            .symbolEffect(.bounce, value: isFavorite) // petite vie à l’icône
        }
        .contentShape(Rectangle())
    }
}
