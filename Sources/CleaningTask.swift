import Foundation

struct CleaningTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var category: String
    var isEnabled: Bool
    var lastRun: Date?
}

final class TaskManager {
    static let shared = TaskManager()

    private let tasksKey = "cleaningTasks"

    private init() {}

    func fetchTasks() -> [CleaningTask] {
        guard let data = UserDefaults.standard.data(forKey: tasksKey) else { return defaultTasks() }
        do {
            return try JSONDecoder().decode([CleaningTask].self, from: data)
        } catch {
            return defaultTasks()
        }
    }

    func saveTask(_ task: CleaningTask) {
        var tasks = fetchTasks()
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        saveTasks(tasks)
    }

    func deleteTask(_ id: UUID) {
        var tasks = fetchTasks()
        tasks.removeAll { $0.id == id }
        saveTasks(tasks)
    }

    func markAsRun(_ id: UUID) {
        var tasks = fetchTasks()
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            var task = tasks[index]
            task.lastRun = Date()
            tasks[index] = task
            saveTasks(tasks)
        }
    }

    private func saveTasks(_ tasks: [CleaningTask]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: tasksKey)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }

    private func defaultTasks() -> [CleaningTask] {
        [
            CleaningTask(id: UUID(), name: "Clear Browser Cache", description: "Clear browser caches", category: "Browser", isEnabled: true),
            CleaningTask(id: UUID(), name: "Empty Trash", description: "Empty the trash bin", category: "System", isEnabled: true),
            CleaningTask(id: UUID(), name: "Clear Logs", description: "Remove old system logs", category: "System", isEnabled: false),
        ]
    }
}
