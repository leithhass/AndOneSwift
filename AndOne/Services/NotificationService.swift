//
//  NotificationService.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import UserNotifications

enum NotificationService {
    static func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleLocal(title: String, body: String, at date: Date, id: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
