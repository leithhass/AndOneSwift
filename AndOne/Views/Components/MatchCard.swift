import SwiftUI
import SwiftData

struct MatchCard: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]
    @StateObject private var vm = GameViewModel()

    let game: Game
    var onJoined: ((Bool) -> Void)? = nil

    private var titleRow: some View {
        HStack(spacing: 10) {
            // Titre + pill état
            Text("\(game.kind.rawValue) ·")
                .font(.headline)
                .foregroundStyle(Color.andInk)

            pill

            Spacer()

            // Heure chip (ink sur fond soft)
            Pill(
                text: game.scheduledAt.formatted(date: .omitted, time: .shortened),
                icon: "clock",
                fg: Color.andInk,
                bg: Color.andOrangeSoft.opacity(0.5)
            )
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

    private var metaRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
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
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow
            metaRow
            CourtAmenityIcons(court: game.court)                // ← icônes mono-ligne
                .padding(.top, 2)

            // CTA
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
                    Pill(text: "Complet", icon: "xmark.circle", fg: Color.andMuted, bg: Color.andOrangeSoft.opacity(0.4))
                }
                Spacer()
                NavigationLink(value: game) {
                    Text("Voir").font(.callout.weight(.semibold))
                }.buttonStyle(.bordered) // action neutre
            }
            .padding(.top, 2)
        }
        .andCard()
        .buttonStyle(PressEffect())
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .contextMenu {
                   if game.spotsLeft > 0 {
                        Button { joinQuick() } label: { Label("Rejoindre", systemImage: "plus") }
                    }
                    Button {
                        FavoritesService.toggle(courtId: game.court.id)
                    } label: {
                        Label(
                            FavoritesService.isFavorite(courtId: game.court.id) ? "Retirer favori" : "Ajouter favori",
                            systemImage: "star"
                        )
                   }
               }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Match \(game.kind.rawValue), \(game.spotsLeft) places restantes, \(game.court.name), \(game.scheduledAt.formatted(date: .omitted, time: .shortened))")
    }

    private func joinQuick() {
        guard game.spotsLeft > 0 else { Haptics.warning(); onJoined?(false); return }
        // Choisir un joueur qui n’est pas déjà dans le match
        let pick = players.first(where: { p in !game.players.contains(where: { $0.id == p.id }) }) ?? players.first
        guard let player = pick, !game.players.contains(where: { $0.id == player.id }) else {
            Haptics.warning(); onJoined?(false); return
        }
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
