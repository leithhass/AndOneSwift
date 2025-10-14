import SwiftUI
import SwiftData

struct MatchCard: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]        // pour Join rapide
    @StateObject private var vm = GameViewModel()

    let game: Game
    var onJoined: ((Bool) -> Void)? = nil       // pour afficher un toast côté parent

    private var title: some View {
        HStack(alignment: .center, spacing: 10) {
            // Titre carte
            Text("\(game.kind.rawValue) · ")
                .font(.headline)
                .foregroundStyle(Color.andInk)
            // Pill état
            pill
            Spacer()
            // Heure chip
            Pill(text: game.scheduledAt.formatted(date: .omitted, time: .shortened),
                 icon: "clock",
                 fg: Color.andInk,
                 bg: Color.andOrangeSoft.opacity(0.5))
                .accessibilityLabel(Text("Heure \(game.scheduledAt.formatted(date: .omitted, time: .shortened))"))
        }
    }

    private var pill: some View {
        let filled = CGFloat(game.players.count) / CGFloat(game.capacity)
        switch game.status {
        case .open:
            return AnyView(
                HStack(spacing: 6) {
                    TinyProgressRing(progress: min(1, filled))
                    Text("Reste \(game.spotsLeft)").font(.caption).bold()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.andOrange.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.andOrange)
            )
        case .full:
            return AnyView(Pill(text: "Complet", icon: "xmark.circle", fg: Color.andMuted, bg: Color.andOrangeSoft.opacity(0.4)))
        case .inProgress:
            return AnyView(Pill(text: "En cours", icon: "bolt.fill", fg: Color.andInfo, bg: Color.andInfo.opacity(0.12)))
        case .finished:
            return AnyView(Pill(text: "Terminé", icon: "checkmark", fg: Color.andMuted, bg: Color.andOrangeSoft.opacity(0.3)))
        }
    }

    private var meta: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
            // Nom de court semibold + ville secondary
            (
                Text(game.court.name).fontWeight(.semibold)
                + Text(" — \(game.court.city)").foregroundStyle(Color.andMuted)
            )
            .lineLimit(1)
            Spacer()
            Image(systemName: "person.2.fill")
            Text("\(game.players.count)/\(game.capacity)")
        }
        .font(.subheadline)
        .foregroundStyle(Color.andInk)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lieu \(game.court.name), \(game.court.city). \(game.players.count) joueurs sur \(game.capacity)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            title
            meta
            CourtAmenityRow(court: game.court)
            // CTA Join / Voir
            HStack {
                if game.spotsLeft > 0 {
                    Button {
                        joinQuick()
                    } label: {
                        Label("Rejoindre", systemImage: "plus.circle.fill")
                            .font(.callout.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.andOrange)
                    .accessibilityLabel("Rejoindre le match")
                } else {
                    NavigationLink(value: game) {
                        Label("Voir", systemImage: "arrow.forward.circle")
                            .font(.callout.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .andCard()
        .buttonStyle(PressEffect())
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .contextMenu { // “swipe-like” actions dans ScrollView
            Button {
                joinQuick()
            } label: { Label("Rejoindre", systemImage: "plus") }
            Button(role: .none) {} label: { Label("Favori", systemImage: "star") } // placeholder
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Match \(game.kind.rawValue), \(game.spotsLeft) places restantes, \(game.court.name), \(game.scheduledAt.formatted(date: .omitted, time: .shortened))")
    }

    private func joinQuick() {
        guard game.spotsLeft > 0 else { Haptics.warning(); onJoined?(false); return }
        // Choisir un joueur dispo (le 1er non déjà inscrit), sinon le 1er de la liste
        let pick = players.first(where: { p in !game.players.contains(where: { $0.id == p.id }) }) ?? players.first
        guard let player = pick else { Haptics.warning(); onJoined?(false); return }
        do {
            try vm.join(game, player: player, context: context)
            Haptics.success()
            onJoined?(true)
        } catch {
            Haptics.error()
            onJoined?(false)
        }
    }
}
