import Foundation

struct ActiveWorkoutSnapshot: Codable, Hashable {
    var sessionID: UUID
    var workoutTitle: String
    var startedAt: Date
    var updatedAt: Date
    var exercises: [ActiveWorkoutExerciseSnapshot]

    var totalLoggedSetCount: Int {
        exercises.reduce(0) { $0 + $1.loggedSetCount }
    }
}

struct ActiveWorkoutExerciseSnapshot: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var targetSets: Int
    var targetRepRange: String
    var loggedSetCount: Int
    var latestWeight: Double
    var latestReps: Int
    var latestRIR: Int
    var showsWeight: Bool
}

struct WatchLogSetCommand: Codable, Hashable {
    var commandID: UUID
    var sessionID: UUID
    var exerciseID: UUID
    var exerciseName: String
    var weight: Double
    var reps: Int
    var rir: Int
    var timestamp: Date

    init(
        commandID: UUID = UUID(),
        sessionID: UUID,
        exerciseID: UUID,
        exerciseName: String,
        weight: Double,
        reps: Int,
        rir: Int,
        timestamp: Date = .now
    ) {
        self.commandID = commandID
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.timestamp = timestamp
    }
}

struct WatchUndoSetCommand: Codable, Hashable {
    var commandID: UUID
    var sessionID: UUID
    var exerciseID: UUID
    var timestamp: Date

    init(
        commandID: UUID = UUID(),
        sessionID: UUID,
        exerciseID: UUID,
        timestamp: Date = .now
    ) {
        self.commandID = commandID
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.timestamp = timestamp
    }
}

struct WatchClearActiveWorkoutMessage: Codable, Hashable {
    var sessionID: UUID?
    var timestamp: Date

    init(sessionID: UUID? = nil, timestamp: Date = .now) {
        self.sessionID = sessionID
        self.timestamp = timestamp
    }
}

enum WatchWorkoutPayloadKind: String {
    case activeSnapshot
    case clearActiveWorkout
    case logSet
    case undoSet
}

enum WatchWorkoutEnvelope {
    static let payloadTypeKey = "coachLogPayloadType"
    static let payloadDataKey = "coachLogPayloadData"

    static func makeMessage<T: Encodable>(
        kind: WatchWorkoutPayloadKind,
        payload: T
    ) throws -> [String: Any] {
        [
            payloadTypeKey: kind.rawValue,
            payloadDataKey: try JSONEncoder.watchWorkout.encode(payload)
        ]
    }

    static func payloadKind(in message: [String: Any]) -> WatchWorkoutPayloadKind? {
        guard let rawValue = message[payloadTypeKey] as? String else {
            return nil
        }

        return WatchWorkoutPayloadKind(rawValue: rawValue)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from message: [String: Any],
        expectedKind: WatchWorkoutPayloadKind
    ) throws -> T? {
        guard payloadKind(in: message) == expectedKind else {
            return nil
        }

        guard let data = message[payloadDataKey] as? Data else {
            return nil
        }

        return try JSONDecoder.watchWorkout.decode(type, from: data)
    }
}

private extension JSONEncoder {
    static var watchWorkout: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var watchWorkout: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
