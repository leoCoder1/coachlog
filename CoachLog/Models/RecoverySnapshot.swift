import Foundation
import SwiftData

enum RecoverySnapshotSource {
    static let healthKit = "HealthKit"
    static let partialHealthKit = "Partial HealthKit"
    static let fallback = "Fallback"
    static let sample = "Sample"
}

enum RecoveryMetricKey: String, CaseIterable {
    case sleep
    case restingHeartRate
    case hrv
}

@Model
final class RecoverySnapshot {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sleepHours: Double
    var restingHeartRate: Double
    var hrv: Double
    var readinessScore: Int
    var source: String?
    var importedMetricKeys: String?
    var importNote: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sleepHours: Double,
        restingHeartRate: Double,
        hrv: Double,
        readinessScore: Int,
        source: String? = nil,
        importedMetricKeys: String? = nil,
        importNote: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.readinessScore = readinessScore
        self.source = source
        self.importedMetricKeys = importedMetricKeys
        self.importNote = importNote
    }

    static var mock: RecoverySnapshot {
        RecoverySnapshot(
            sleepHours: 7.2,
            restingHeartRate: 58,
            hrv: 62,
            readinessScore: 78,
            source: RecoverySnapshotSource.fallback
        )
    }

    var importedMetricSet: Set<String> {
        Set(
            (importedMetricKeys ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
    }

    var isHealthKitBacked: Bool {
        source == RecoverySnapshotSource.healthKit || source == RecoverySnapshotSource.partialHealthKit
    }

    func displaysMetric(_ key: RecoveryMetricKey) -> Bool {
        guard isHealthKitBacked else { return true }
        return importedMetricSet.contains(key.rawValue)
    }

    var displaysReadiness: Bool {
        guard isHealthKitBacked else { return true }
        return importedMetricSet.count >= 2
    }
}
