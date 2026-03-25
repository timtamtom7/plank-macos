import Foundation

struct CleaningSchedule: Identifiable, Codable {
    let id: UUID
    var taskId: UUID
    var interval: ScheduleInterval
    var nextRun: Date
    var isEnabled: Bool
}

enum ScheduleInterval: String, Codable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly

    var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}

final class ScheduleManager {
    static let shared = ScheduleManager()

    private let schedulesKey = "cleaningSchedules"

    private init() {}

    func fetchSchedules() -> [CleaningSchedule] {
        guard let data = UserDefaults.standard.data(forKey: schedulesKey) else { return [] }
        do {
            return try JSONDecoder().decode([CleaningSchedule].self, from: data)
        } catch {
            return []
        }
    }

    func saveSchedule(_ schedule: CleaningSchedule) {
        var schedules = fetchSchedules()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }
        saveSchedules(schedules)
    }

    func deleteSchedule(_ id: UUID) {
        var schedules = fetchSchedules()
        schedules.removeAll { $0.id == id }
        saveSchedules(schedules)
    }

    func getDueSchedules() -> [CleaningSchedule] {
        let now = Date()
        return fetchSchedules().filter { $0.isEnabled && $0.nextRun <= now }
    }

    func updateNextRun(for schedule: CleaningSchedule) -> CleaningSchedule {
        var updated = schedule
        updated.nextRun = Calendar.current.date(byAdding: .day, value: schedule.interval.days, to: Date()) ?? Date()
        return updated
    }

    private func saveSchedules(_ schedules: [CleaningSchedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: schedulesKey)
        } catch {
            print("Failed to save schedules: \(error)")
        }
    }
}
