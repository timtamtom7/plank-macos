import Foundation

struct CleaningReport: Identifiable, Codable {
    let id: UUID
    let taskName: String
    let bytesCleared: UInt64
    let itemsCleared: Int
    let timestamp: Date
    let duration: TimeInterval
}

final class ReportManager {
    static let shared = ReportManager()

    private let reportsKey = "cleaningReports"
    private let maxReports = 100

    private init() {}

    func addReport(_ report: CleaningReport) {
        var reports = fetchReports()
        reports.append(report)

        if reports.count > maxReports {
            reports = Array(reports.suffix(maxReports))
        }

        saveReports(reports)
    }

    func fetchReports() -> [CleaningReport] {
        guard let data = UserDefaults.standard.data(forKey: reportsKey) else { return [] }
        do {
            return try JSONDecoder().decode([CleaningReport].self, from: data)
        } catch {
            return []
        }
    }

    func getTotalCleared() -> (bytes: UInt64, items: Int) {
        let reports = fetchReports()
        let totalBytes = reports.reduce(0) { $0 + $1.bytesCleared }
        let totalItems = reports.reduce(0) { $0 + $1.itemsCleared }
        return (totalBytes, totalItems)
    }

    func getReportsByTask(_ taskName: String) -> [CleaningReport] {
        fetchReports().filter { $0.taskName == taskName }
    }

    private func saveReports(_ reports: [CleaningReport]) {
        do {
            let data = try JSONEncoder().encode(reports)
            UserDefaults.standard.set(data, forKey: reportsKey)
        } catch {
            print("Failed to save reports: \(error)")
        }
    }
}
