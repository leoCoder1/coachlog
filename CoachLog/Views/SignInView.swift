import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @AppStorage(CoachAuthKeys.isSignedIn) private var isSignedIn = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            CoachScreenBackground()

            VStack(spacing: 18) {
                Spacer(minLength: 28)

                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(CoachGradient.accent)
                            .frame(width: 58, height: 58)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.86))
                    }

                    Text("AI Trainer Log")
                        .font(.largeTitle.weight(.bold))

                    Text("Sign in with your Apple ID to keep your training, recovery, and measurements tied to your account.")
                        .font(.subheadline)
                        .foregroundStyle(Color.coachSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                CoachCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Private by default", systemImage: "lock.shield")
                            .font(.headline)

                        Text("AI Trainer Log uses Apple sign-in for account identity. Workout data stays on this device until cloud sync is added.")
                            .font(.subheadline)
                            .foregroundStyle(Color.coachSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAuthorization(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        #if DEBUG && targetEnvironment(simulator)
                        Button {
                            CoachAuthSession.storeSimulatorSession()
                            errorMessage = nil
                            isSignedIn = true
                        } label: {
                            Label("Continue in Simulator", systemImage: "iphone.gen3")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(CoachSecondaryButtonStyle())

                        Text("Local testing only. TestFlight and device release builds still use Apple sign-in.")
                            .font(.caption)
                            .foregroundStyle(Color.coachSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        #endif

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.coachWarm)
                                .transition(CoachMotion.cardTransition)
                        }
                    }
                }

                Spacer(minLength: 28)
            }
            .padding(22)
            .frame(maxWidth: 480)
        }
        .tint(Color.coachAccent)
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .animation(CoachMotion.content, value: errorMessage)
    }

    private func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple did not return a valid account credential."
                return
            }

            CoachAuthSession.store(credential)
            errorMessage = nil
            isSignedIn = true

        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            errorMessage = "Apple sign-in failed. Please try again."
        }
    }
}
