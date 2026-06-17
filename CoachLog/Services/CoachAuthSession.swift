import AuthenticationServices
import Foundation

enum CoachAuthKeys {
    static let isSignedIn = "coachAuthIsSignedIn"
    static let appleUserID = "coachAuthAppleUserID"
    static let displayName = "coachAuthDisplayName"
    static let email = "coachAuthEmail"
}

enum CoachAuthSession {
    @MainActor
    static func store(_ credential: ASAuthorizationAppleIDCredential, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: CoachAuthKeys.isSignedIn)
        defaults.set(credential.user, forKey: CoachAuthKeys.appleUserID)

        if let fullName = credential.fullName {
            let formattedName = PersonNameComponentsFormatter().string(from: fullName)
            if !formattedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                defaults.set(formattedName, forKey: CoachAuthKeys.displayName)
            }
        }

        if let email = credential.email, !email.isEmpty {
            defaults.set(email, forKey: CoachAuthKeys.email)
        }
    }

    #if DEBUG
    @MainActor
    static func storeSimulatorSession(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: CoachAuthKeys.isSignedIn)
        defaults.removeObject(forKey: CoachAuthKeys.appleUserID)
        defaults.set("Simulator Tester", forKey: CoachAuthKeys.displayName)
        defaults.set("Local simulator account", forKey: CoachAuthKeys.email)
    }
    #endif

    @MainActor
    static func signOut(defaults: UserDefaults = .standard) {
        defaults.set(false, forKey: CoachAuthKeys.isSignedIn)
        defaults.removeObject(forKey: CoachAuthKeys.appleUserID)
        defaults.removeObject(forKey: CoachAuthKeys.displayName)
        defaults.removeObject(forKey: CoachAuthKeys.email)
    }

    static func credentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }
}
