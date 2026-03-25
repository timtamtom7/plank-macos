import Foundation

struct PlankExport: Codable {
    let version: String
    let exportDate: Date
    let tasks: [CleaningTask]
    let schedules: [CleaningSchedule]
    let reports: [CleaningReport]
}

final class PlankExportManager {
    static let shared = PlankExportManager()

    private init() {}

    func exportToJSON() -> Data? {
        let export = PlankExport(
            version: "R10",
            exportDate: Date(),
            tasks: TaskManager.shared.fetchTasks(),
            schedules: ScheduleManager.shared.fetchSchedules(),
            reports: ReportManager.shared.fetchReports()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func importFrom(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(PlankExport.self, from: data)

            for task in export.tasks {
                TaskManager.shared.saveTask(task)
            }

            for schedule in export.schedules {
                ScheduleManager.shared.saveSchedule(schedule)
            }

            return true
        } catch {
            print("Failed to import: \(error)")
            return false
        }
    }

    func saveExportToFile() -> URL? {
        guard let data = exportToJSON() else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Plank-Backup-\(dateFormatter.string(from: Date())).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}
