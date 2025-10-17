//
//  BootstrapService.swift.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import Foundation
import SwiftData

enum BootstrapService {
    private static let flagKey = "andone.seed_done_date"

    static func seedIfNeeded(context: ModelContext, force: Bool = false) {
        if !force, UserDefaults.standard.object(forKey: flagKey) != nil { return }
        Task { @MainActor in
            // Idempotence by (name + city)
            func ensureCourt(_ make: () -> Court) -> Court {
                let c = make()
                if let existing = try? context.fetch(FetchDescriptor<Court>()).first(where: { $0.name == c.name && $0.city == c.city }) {
                    return existing
                } else {
                    context.insert(c); return c
                }
            }
            func ensurePlayer(_ nickname: String, level: Int) -> Player {
                if let existing = try? context.fetch(FetchDescriptor<Player>()).first(where: { $0.nickname == nickname }) { return existing }
                let p = Player(nickname: nickname, level: level); context.insert(p); return p
            }

            // Courts
            let citeOlympique = ensureCourt { Court(name: "Cité Olympique", governorate: .tunis, city: "El Khadra", kind: .full, hoops: 2, hasLighting: true, hasLockerRoom: true, hasStands: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true, surface: .concrete, condition: .good) }
            let belvedere     = ensureCourt { Court(name: "Parc du Belvédère", governorate: .tunis, city: "Belvédère", kind: .half, hasLighting: true, hasStands: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true, surface: .asphalt, condition: .good) }
            _ = ensureCourt { Court(name: "Corniche Nabeul", governorate: .nabeul, city: "Nabeul", kind: .full, hasLighting: true, hasWaterPoint: true, hasParking: true, surface: .asphalt, condition: .medium) }
            let sahloulArena  = ensureCourt { Court(name: "Sahloul Arena", governorate: .sousse, city: "Sahloul", kind: .full, hasLighting: true, hasLockerRoom: true, hasStands: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true, surface: .concrete, condition: .good) }
            _ = ensureCourt { Court(name: "Monastir Marina Court", governorate: .monastir, city: "Centre", kind: .half, hasLighting: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true) }
            _ = ensureCourt { Court(name: "Bizerte Corniche", governorate: .bizerte, city: "Corniche", kind: .full, hasLighting: true, hasStands: true, hasWaterPoint: true, hasParking: true, surface: .asphalt, condition: .medium) }
            let sfaxTaparura  = ensureCourt { Court(name: "Sfax Taparura", governorate: .sfax, city: "Taparura", kind: .full, hasLighting: true, hasLockerRoom: true, hasStands: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true, surface: .concrete, condition: .good) }
            _   = ensureCourt { Court(name: "Mahdia Plage Court", governorate: .mahdia, city: "Touristique", kind: .half, hasWaterPoint: true, hasParking: true, surface: .asphalt, condition: .medium) }
            _    = ensureCourt { Court(name: "Gabès Oasis Court", governorate: .gabes, city: "Gabès-Ville", kind: .full, hasLighting: true, hasStands: true, hasWaterPoint: true, hasParking: true, isAccessiblePMR: true, surface: .concrete, condition: .good) }
            _ = ensureCourt { Court(name: "Kairouan Medina Court", governorate: .kairouan, city: "Médina", kind: .half, hasWaterPoint: true, surface: .other, condition: .bad) }

            // Players
            let yassine = ensurePlayer("Yassine", level: 4)
            let omar    = ensurePlayer("Omar", level: 3)
            let rami    = ensurePlayer("Rami", level: 3)
            let anis    = ensurePlayer("Anis", level: 2)
            let noura   = ensurePlayer("Noura", level: 4)
            let sana    = ensurePlayer("Sana", level: 3)
            let hedi    = ensurePlayer("Hedi", level: 2)
            let meriem  = ensurePlayer("Meriem", level: 4)

            // Games (idempotent light check by time + court + kind)
            func ensureGame(kind: GameKind, date: Date, court: Court, players: [Player]) {
                let all = (try? context.fetch(FetchDescriptor<Game>())) ?? []
                if all.contains(where: { Calendar.current.isDate($0.scheduledAt, equalTo: date, toGranularity: .minute) && $0.court.id == court.id && $0.kind == kind }) { return }
                let g = Game(kind: kind, scheduledAt: date, court: court, players: players, creatorId: players.first?.id ?? UUID())
                context.insert(g)
            }

            let now = Date()
            ensureGame(kind: .threeVthree, date: Calendar.current.date(byAdding: .day, value: 1, to: now)!.setting(hour: 18, minute: 0), court: sahloulArena, players: [yassine, noura, rami, sana])
            ensureGame(kind: .fiveVfive,  date: next(.saturday, atHour: 17, minute: 30, from: now), court: sfaxTaparura, players: [yassine, omar, rami, anis, noura, sana, hedi, meriem,
                                                                                                                                        Player(nickname: "Guest A", level: 3), Player(nickname: "Guest B", level: 3)])
            ensureGame(kind: .twoVtwo,    date: Calendar.current.date(byAdding: .hour, value: 3, to: now)!, court: belvedere, players: [omar, anis, hedi])
            ensureGame(kind: .oneVone,    date: Calendar.current.date(byAdding: .hour, value: 2, to: now)!, court: citeOlympique, players: [yassine])

            try? context.save()
            UserDefaults.standard.set(Date(), forKey: flagKey)
            AnalyticsService.log(.seedDone)
        }
    }

    // Helpers
    private static func next(_ weekday: Weekday, atHour h: Int, minute m: Int, from: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let target = weekday.rawValue
        let today = cal.component(.weekday, from: from)
        let add = (target - today + 7) % 7
        let base = cal.date(byAdding: .day, value: add == 0 ? 7 : add, to: from)!
        return base.setting(hour: h, minute: m)
    }

    private enum Weekday: Int { case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday }
}

private extension Date {
    func setting(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year,.month,.day], from: self)
        comps.hour = hour; comps.minute = minute
        return Calendar.current.date(from: comps) ?? self
    }
}
