import Combine
import Foundation
import WatchConnectivity

final class WatchWorkoutSessionStore: NSObject, ObservableObject {
    @Published private(set) var snapshot: ActiveWorkoutSnapshot?
    @Published private(set) var pendingSyncCount = 0
    @Published private(set) var statusText = "Waiting for iPhone"

    private var clearedSessionIDs = Set<UUID>()

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else {
            updateStatus("Sync unavailable")
            return
        }

        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        session.activate()
        updatePendingSyncCount()
    }

    func logSet(
        exercise: ActiveWorkoutExerciseSnapshot,
        weight: Double,
        reps: Int,
        rir: Int
    ) {
        guard let snapshot else { return }

        let command = WatchLogSetCommand(
            sessionID: snapshot.sessionID,
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            weight: exercise.showsWeight ? weight : 0,
            reps: reps,
            rir: rir
        )
        send(kind: .logSet, payload: command)
    }

    func undoLastSet(exercise: ActiveWorkoutExerciseSnapshot) {
        guard let snapshot else { return }

        let command = WatchUndoSetCommand(
            sessionID: snapshot.sessionID,
            exerciseID: exercise.id
        )
        send(kind: .undoSet, payload: command)
    }

    private func send<T: Encodable>(
        kind: WatchWorkoutPayloadKind,
        payload: T
    ) {
        guard WCSession.isSupported() else {
            updateStatus("Sync unavailable")
            return
        }

        do {
            let message = try WatchWorkoutEnvelope.makeMessage(kind: kind, payload: payload)
            let session = WCSession.default

            guard session.activationState == .activated else {
                queue(message)
                return
            }

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { [weak self] _ in
                    self?.queue(message)
                }
                updateStatus("Sent")
            } else {
                queue(message)
            }
        } catch {
            updateStatus("Sync failed")
        }
    }

    private func queue(_ message: [String: Any]) {
        WCSession.default.transferUserInfo(message)
        updatePendingSyncCount()
    }

    private func handle(_ message: [String: Any]) {
        do {
            if let snapshot = try WatchWorkoutEnvelope.decode(
                ActiveWorkoutSnapshot.self,
                from: message,
                expectedKind: .activeSnapshot
            ) {
                guard shouldAccept(snapshot) else { return }

                updateOnMain {
                    self.snapshot = snapshot
                    self.statusText = self.pendingSyncCount > 0 ? "Pending sync" : "Synced"
                }
                return
            }

            if let clearMessage = try WatchWorkoutEnvelope.decode(
                WatchClearActiveWorkoutMessage.self,
                from: message,
                expectedKind: .clearActiveWorkout
            ) {
                if let sessionID = clearMessage.sessionID {
                    clearedSessionIDs.insert(sessionID)
                }

                guard clearMessage.sessionID == nil || snapshot?.sessionID == clearMessage.sessionID else {
                    return
                }

                updateOnMain {
                    self.snapshot = nil
                    self.statusText = self.pendingSyncCount > 0 ? "Pending sync" : "Waiting for iPhone"
                }
            }
        } catch {
            updateStatus("Sync failed")
        }
    }

    private func updatePendingSyncCount() {
        guard WCSession.isSupported() else { return }

        let count = WCSession.default.outstandingUserInfoTransfers.count
        updateOnMain {
            self.pendingSyncCount = count
            if count > 0 {
                self.statusText = "Pending sync"
            } else if self.snapshot == nil {
                self.statusText = "Waiting for iPhone"
            } else {
                self.statusText = "Synced"
            }
        }
    }

    private func updateStatus(_ status: String) {
        updateOnMain {
            self.statusText = status
        }
    }

    private func shouldAccept(_ newSnapshot: ActiveWorkoutSnapshot) -> Bool {
        guard !clearedSessionIDs.contains(newSnapshot.sessionID) else {
            return false
        }

        guard let currentSnapshot = snapshot else {
            return true
        }

        guard currentSnapshot.sessionID == newSnapshot.sessionID else {
            return newSnapshot.startedAt >= currentSnapshot.startedAt
        }

        return newSnapshot.updatedAt >= currentSnapshot.updatedAt
    }

    private func updateOnMain(_ update: @escaping () -> Void) {
        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async(execute: update)
        }
    }
}

extension WatchWorkoutSessionStore: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if error != nil {
            updateStatus("Sync failed")
        } else {
            updatePendingSyncCount()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handle(userInfo)
    }

    func session(
        _ session: WCSession,
        didFinish userInfoTransfer: WCSessionUserInfoTransfer,
        error: Error?
    ) {
        updatePendingSyncCount()
        if error != nil {
            updateStatus("Pending sync")
        }
    }
}
