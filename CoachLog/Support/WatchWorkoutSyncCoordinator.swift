import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class ActiveWorkoutStore {
    static let shared = ActiveWorkoutStore()

    private(set) var snapshot: ActiveWorkoutSnapshot?
    private(set) var lastSyncError: String?

    @ObservationIgnored private var handledCommandIDs = Set<UUID>()
    @ObservationIgnored private var logSetHandler: ((WatchLogSetCommand) -> ActiveWorkoutSnapshot?)?
    @ObservationIgnored private var undoSetHandler: ((WatchUndoSetCommand) -> ActiveWorkoutSnapshot?)?
    @ObservationIgnored private let connectivity = WatchWorkoutSyncCoordinator.shared

    private init() {}

    func activateConnectivity() {
        connectivity.activate()
    }

    func recordSyncError(_ message: String) {
        lastSyncError = message
    }

    func beginWorkout(
        snapshot: ActiveWorkoutSnapshot,
        onLogSet: @escaping (WatchLogSetCommand) -> ActiveWorkoutSnapshot?,
        onUndoSet: @escaping (WatchUndoSetCommand) -> ActiveWorkoutSnapshot?
    ) {
        handledCommandIDs.removeAll()
        logSetHandler = onLogSet
        undoSetHandler = onUndoSet
        publish(snapshot)
    }

    func refreshWorkout(snapshot: ActiveWorkoutSnapshot) {
        guard self.snapshot?.sessionID == snapshot.sessionID else {
            beginWorkout(
                snapshot: snapshot,
                onLogSet: logSetHandler ?? { _ in nil },
                onUndoSet: undoSetHandler ?? { _ in nil }
            )
            return
        }

        publish(snapshot)
    }

    func finishWorkout() {
        let sessionID = snapshot?.sessionID
        snapshot = nil
        logSetHandler = nil
        undoSetHandler = nil
        handledCommandIDs.removeAll()
        connectivity.sendClearActiveWorkout(sessionID: sessionID)
    }

    func receive(_ command: WatchLogSetCommand) {
        guard accepts(commandID: command.commandID, sessionID: command.sessionID),
              let updatedSnapshot = logSetHandler?(command) else {
            return
        }

        handledCommandIDs.insert(command.commandID)
        publish(updatedSnapshot)
    }

    func receive(_ command: WatchUndoSetCommand) {
        guard accepts(commandID: command.commandID, sessionID: command.sessionID),
              let updatedSnapshot = undoSetHandler?(command) else {
            return
        }

        handledCommandIDs.insert(command.commandID)
        publish(updatedSnapshot)
    }

    private func accepts(commandID: UUID, sessionID: UUID) -> Bool {
        guard snapshot?.sessionID == sessionID else {
            return false
        }

        return !handledCommandIDs.contains(commandID)
    }

    private func publish(_ snapshot: ActiveWorkoutSnapshot) {
        self.snapshot = snapshot
        do {
            try connectivity.send(snapshot)
            lastSyncError = nil
        } catch {
            recordSyncError(error.localizedDescription)
        }
    }
}

final class WatchWorkoutSyncCoordinator: NSObject {
    static let shared = WatchWorkoutSyncCoordinator()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }

        session.activate()
    }

    func send(_ snapshot: ActiveWorkoutSnapshot) throws {
        try send(kind: .activeSnapshot, payload: snapshot)
    }

    func sendClearActiveWorkout(sessionID: UUID?) {
        do {
            try send(
                kind: .clearActiveWorkout,
                payload: WatchClearActiveWorkoutMessage(sessionID: sessionID)
            )
        } catch {
            Task { @MainActor in
                ActiveWorkoutStore.shared.recordSyncError(error.localizedDescription)
            }
        }
    }

    private func send<T: Encodable>(
        kind: WatchWorkoutPayloadKind,
        payload: T
    ) throws {
        guard WCSession.isSupported() else { return }

        let message = try WatchWorkoutEnvelope.makeMessage(kind: kind, payload: payload)
        let session = WCSession.default

        guard session.activationState == .activated else {
            session.transferUserInfo(message)
            return
        }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                session.transferUserInfo(message)
            }
        } else {
            session.transferUserInfo(message)
        }
    }

    private func receive(_ message: [String: Any]) {
        do {
            if let command = try WatchWorkoutEnvelope.decode(
                WatchLogSetCommand.self,
                from: message,
                expectedKind: .logSet
            ) {
                Task { @MainActor in
                    ActiveWorkoutStore.shared.receive(command)
                }
                return
            }

            if let command = try WatchWorkoutEnvelope.decode(
                WatchUndoSetCommand.self,
                from: message,
                expectedKind: .undoSet
            ) {
                Task { @MainActor in
                    ActiveWorkoutStore.shared.receive(command)
                }
            }
        } catch {
            Task { @MainActor in
                ActiveWorkoutStore.shared.recordSyncError(error.localizedDescription)
            }
        }
    }
}

extension WatchWorkoutSyncCoordinator: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            Task { @MainActor in
                ActiveWorkoutStore.shared.recordSyncError(error.localizedDescription)
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receive(userInfo)
    }
}
