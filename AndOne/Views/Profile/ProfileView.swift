import SwiftUI
import SwiftData
import PhotosUI

// Affichage court pour PlayerPosition (le modèle existe déjà dans Models)
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

    // Photo
    @State private var photoItem: PhotosPickerItem?
    @State private var showConfirmReset = false

    // Dérivées
    private var upcomingCount: Int { games.filter { $0.scheduledAt >= Date() }.count }
    private var pastCount: Int { games.filter { $0.scheduledAt < Date() }.count }
    private var favoriteCourts: [Court] {
        let fav = FavoritesService.ids()
        return courts.filter { fav.contains($0.id) }.sorted { $0.city < $1.city }
    }

    var body: some View {
        NavigationStack {
            List {
                // --- Header carte (marges/insets maîtrisés)
                Section {
                    profileHeaderCard
                }
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // --- Stats
                Section {
                    statsRow
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                // --- Favoris
                Section("Courts favoris") {
                    if favoriteCourts.isEmpty {
                        Text("Aucun favori pour le moment. Ajoute-en depuis Explorer ou depuis une carte de match.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(favoriteCourts.prefix(5)) { c in
                            NavigationLink {
                                Text(c.name).navigationTitle("Court")
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: c.kind == .half ? "rectangle.leadinghalf.inset.filled"
                                                                      : "rectangle.inset.filled")
                                        .foregroundStyle(.primary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.name).fontWeight(.semibold).foregroundStyle(.primary)
                                        Text("\(c.city) • \(c.governorate.rawValue)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // --- Préférences (placeholders)
                Section("Préférences") {
                    Toggle(isOn: .constant(false)) { Text("Notifications de rappel (−30 min) · bientôt") }
                        .tint(.andOrange)
                        .disabled(true)

                    Picker("Thème", selection: .constant(0)) {
                        Text("Système").tag(0); Text("Clair").tag(1); Text("Sombre").tag(2)
                    }
                    .disabled(true)
                }

                // --- Admin
                Section("Administration") {
                    NavigationLink("Dashboard Admin") { AdminDashboardView() }
                    Button("Réinitialiser données de démo", role: .destructive) { showConfirmReset = true }
                }
            }
            .listStyle(.insetGrouped)
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
            .onChange(of: photoItem) { _, newValue in
                Task { await loadPhoto(from: newValue) }
            }
        }
    }

    // MARK: - Header card (réarrangée)
    @ViewBuilder
    private var profileHeaderCard: some View {
        VStack(spacing: 14) {

            // Ligne 1 — Nom + actions
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Pseudo", text: $nickname)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .font(.title3.bold())
                        .padding(.leading, 2) // anti-clip du 1er glyph dans List
                        .onSubmit { Haptics.light() }

                    Text("@\(nickname.isEmpty ? "guest" : nickname.lowercased())")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "photo.on.rectangle")
                            .imageScale(.medium)
                            .frame(width: 40, height: 40)
                            .background(Color.andOrange.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Changer la photo de profil")

                    Button {
                        withAnimation(.spring) { avatarHue = Double.random(in: 0...1) }
                        Haptics.light()
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .imageScale(.medium)
                            .frame(width: 40, height: 40)
                            .background(Color.andOrange.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Changer la couleur de l’avatar")
                }
            }

            // Ligne 2 — Avatar à gauche / Contrôles à droite
            HStack(alignment: .center, spacing: 14) {
                // Avatar avec léger ring
                ZStack {
                    avatar.frame(width: 64, height: 64)
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        .frame(width: 68, height: 68)
                }

                // Contrôles
                VStack(alignment: .leading, spacing: 10) {
                    // Poste PG/F/C — segment large et “tap-friendly”
                    Picker("Poste", selection: Binding<String>(
                        get: { positionRaw },
                        set: { positionRaw = $0; Haptics.light() }
                    )) {
                        ForEach(PlayerPosition.allCases) { p in
                            Text(p.shortLabel).tag(p.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    // Niveau — clair et aligné
                    HStack(spacing: 12) {
                        Text("Niveau")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(width: 58, alignment: .leading)

                        HStack(spacing: 8) {
                            Button {
                                if level > 1 { level -= 1; Haptics.light() }
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.bordered)

                            Text("\(level)")
                                .font(.headline)
                                .frame(minWidth: 28)

                            Button {
                                if level < 5 { level += 1; Haptics.light() }
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    // MARK: - Avatar
    private var avatar: some View {
        Group {
            if let data = avatarImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
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
        .padding(.vertical, 4)
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
            Text(title).font(.footnote).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Utils
private extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        let all = try self.fetch(FetchDescriptor<T>())
        for x in all { self.delete(x) }
    }
}
