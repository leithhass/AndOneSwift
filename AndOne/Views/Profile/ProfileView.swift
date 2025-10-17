import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Affichage court pour PlayerPosition (le modèle existe ailleurs)
private extension PlayerPosition {
    var shortLabel: String {
        switch self {
        case .pointGuard: return "PG"
        case .forward:    return "F"
        case .center:     return "C"
        }
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [Game]
    @Query private var courts: [Court]

    // Persistance locale
    @AppStorage("andone.nickname") private var nickname: String = "Guest"
    @AppStorage("andone.level")    private var level: Int = 3
    @AppStorage("andone.avatarHue") private var avatarHue: Double = 0.08
    @AppStorage("andone.avatarImageData") private var avatarImageData: Data?
    @AppStorage("andone.position") private var positionRaw: String = PlayerPosition.pointGuard.rawValue

    // Photos
    @State private var photoItem: PhotosPickerItem?

    // Reset
    @State private var showConfirmReset = false

    // Dérivées
    private var position: PlayerPosition { PlayerPosition(rawValue: positionRaw) ?? .pointGuard }
    private var upcomingCount: Int { games.filter { $0.scheduledAt >= Date() }.count }
    private var pastCount: Int { games.filter { $0.scheduledAt < Date() }.count }
    private var favoriteCourts: [Court] {
        let fav = FavoritesService.ids()
        return courts.filter { fav.contains($0.id) }.sorted { $0.city < $1.city }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    statsRow
                    favoritesSection
                    preferencesSection
                    adminSection
                }
                .padding(.top, 8)               // air sous la nav bar
                .padding(.horizontal, 16)       // <<< marges gauche/droite stables (iOS 15+)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: photoItem) { _, newValue in
                Task { await loadPhoto(from: newValue) }
            }
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                avatarView

                VStack(alignment: .leading, spacing: 8) {
                    // Nom dynamique
                    TextField("Pseudo", text: $nickname)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .font(.title3.bold())
                        .onSubmit { Haptics.light() }

                    // Poste + Niveau
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Poste").font(.caption).foregroundStyle(Color.andMuted)
                            Picker("", selection: Binding<String>(
                                get: { positionRaw },
                                set: { positionRaw = $0; Haptics.light() }
                            )) {
                                ForEach(PlayerPosition.allCases) { p in
                                    Text(p.shortLabel).tag(p.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 6) {
                            Text("Niveau \(level)")
                                .font(.caption)
                                .foregroundStyle(Color.andMuted)
                            Stepper(value: $level, in: 1...5) { EmptyView() }
                                .labelsHidden()
                        }
                        .frame(width: 120, alignment: .trailing)
                    }
                }

                // Menu avatar (photo / couleur)
                Menu {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label("Changer la photo", systemImage: "photo")
                    }
                    Button {
                        withAnimation(.spring) { avatarHue = Double.random(in: 0...1) }
                        Haptics.light()
                    } label: {
                        Label("Changer la couleur", systemImage: "paintpalette")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .padding(10)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Options avatar")
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // empêche tout débord
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // Avatar : photo si dispo, sinon initiales colorées
    private var avatarView: some View {
        Group {
            if let data = avatarImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                    .shadow(radius: 2)
            } else {
                let color = Color(hue: avatarHue, saturation: 0.85, brightness: 0.95)
                let initials = initialsFrom(nickname)
                ZStack {
                    Circle().fill(color.opacity(0.18))
                    Circle().stroke(color, lineWidth: 2)
                    Text(initials.isEmpty ? "G" : initials)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                }
                .frame(width: 64, height: 64)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(title: "À venir", value: "\(upcomingCount)", icon: "calendar.badge.clock")
            StatCard(title: "Passés", value: "\(pastCount)", icon: "clock.arrow.circlepath")
            StatCard(title: "Favoris", value: "\(favoriteCourts.count)", icon: "star.fill")
        }
    }

    // MARK: - Favoris
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Courts favoris")
                    .font(.headline)
                    .padding(.top, 2)
                Spacer()
                if !favoriteCourts.isEmpty {
                    NavigationLink { FavoritesListView(courts: favoriteCourts) } label: { Text("Tout voir") }
                }
            }

            if favoriteCourts.isEmpty {
                Text("Aucun favori pour le moment. Ajoute-en depuis Explorer ou depuis une carte de match.")
                    .font(.footnote)
                    .foregroundStyle(Color.andMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(favoriteCourts.prefix(3)) { c in
                    NavigationLink {
                        // Placeholder fiche court
                        Text(c.name).navigationTitle("Court")
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: c.kind == .half ? "rectangle.leadinghalf.inset.filled" : "rectangle.inset.filled")
                                .foregroundStyle(Color.andInk)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.name)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.andInk)   // force l’encre
                                Text("\(c.city) • \(c.governorate.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(Color.andMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.andMuted)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain) // évite la recoloration par .tint
                }
            }
        }
    }

    // MARK: - Préférences
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Préférences").font(.headline)

            Toggle(isOn: .constant(false)) { Text("Notifications de rappel (-30 min) · bientôt") }
                .tint(.andOrange)
                .disabled(true)

            Picker("Thème", selection: .constant(0)) {
                Text("Système").tag(0)
                Text("Clair").tag(1)
                Text("Sombre").tag(2)
            }
            .disabled(true)
            .pickerStyle(.menu)
        }
        .padding(.top, 6)
    }

    // MARK: - Admin
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Administration").font(.headline)

            NavigationLink("Dashboard Admin") { AdminDashboardView() }

            Button("Réinitialiser données de démo", role: .destructive) {
                showConfirmReset = true
            }
            .confirmationDialog("Supprimer toutes les données et recréer les exemples ?",
                                isPresented: $showConfirmReset, titleVisibility: .visible) {
                Button("Réinitialiser", role: .destructive) {
                    try? context.delete(model: Game.self)
                    try? context.delete(model: Player.self)
                    try? context.save()
                    UserDefaults.standard.removeObject(forKey: "andone.seed_done_date")
                    BootstrapService.seedIfNeeded(context: context, force: true)
                }
                Button("Annuler", role: .cancel) {}
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Helpers
    private func initialsFrom(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        let base = (first + last).uppercased()
        return base.isEmpty ? String(name.prefix(1)).uppercased() : base
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                self.avatarImageData = data
                Haptics.success()
            }
        } else {
            Haptics.warning()
        }
    }
}

// MARK: - Subviews

fileprivate struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 6) {
            HStack { Image(systemName: icon); Spacer() }
                .foregroundStyle(Color.andOrange)
            Text(value).font(.title2).bold()
            Text(title).font(.footnote).foregroundStyle(Color.andMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct FavoritesListView: View {
    let courts: [Court]
    var body: some View {
        List(courts) { c in
            HStack(spacing: 10) {
                Image(systemName: c.kind == .half ? "rectangle.leadinghalf.inset.filled" : "rectangle.inset.filled")
                    .foregroundStyle(Color.andInk)
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).fontWeight(.semibold).foregroundStyle(Color.andInk)
                    Text("\(c.city) • \(c.governorate.rawValue)")
                        .font(.caption).foregroundStyle(Color.andMuted)
                }
                Spacer()
                Image(systemName: "star.fill").foregroundStyle(Color.andOrange)
            }
        }
        .navigationTitle("Courts favoris")
        .listStyle(.insetGrouped)
    }
}

// MARK: - Utilities

private extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        let all = try self.fetch(FetchDescriptor<T>())
        for x in all { self.delete(x) }
    }
}
