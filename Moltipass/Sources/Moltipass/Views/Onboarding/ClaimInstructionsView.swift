import SwiftUI
import os.log
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private let logger = Logger(subsystem: "com.moltipass", category: "claim")

public struct ClaimInstructionsView: View {
    @Environment(AppState.self) private var appState
    public let verificationCode: String
    public let claimURL: URL?

    @State private var isVerifying = false
    @State private var error: String?
    @State private var pollCount = 0
    private let maxPolls = 40

    public init(verificationCode: String, claimURL: URL? = nil) {
        self.verificationCode = verificationCode
        self.claimURL = claimURL
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)

                    Text("Claim Your Agent")
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Step 1: Verification Code
                    GroupBox {
                        VStack(spacing: 12) {
                            Label("Step 1: Copy Verification Code", systemImage: "1.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(verificationCode)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)

                            Button("Copy Code") {
                                copyToClipboard(verificationCode)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Step 2: Post Tweet
                    GroupBox {
                        VStack(spacing: 12) {
                            Label("Step 2: Post on Twitter/X", systemImage: "2.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Tweet the verification code to prove you control this account.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button("Open Twitter") {
                                openTwitter()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Step 3: Visit Claim Page
                    GroupBox {
                        VStack(spacing: 12) {
                            Label("Step 3: Complete Claim", systemImage: "3.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Visit the claim page and sign in with X to verify.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let claimURL = claimURL {
                                Button("Open Claim Page") {
                                    openURL(claimURL)
                                }
                                .buttonStyle(.borderedProminent)

                                Text(claimURL.absoluteString)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button("Copy Claim URL") {
                                    copyToClipboard(claimURL.absoluteString)
                                }
                                .font(.caption)
                            } else {
                                Text("Claim URL not available. Try restarting the app.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Divider()

                    // Verification Status
                    if isVerifying {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Checking claim status... (\(pollCount)/\(maxPolls))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = error {
                        VStack(spacing: 8) {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Check Again") {
                                Task { await startVerification() }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Check Claim Status") {
                            Task { await startVerification() }
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    Button("Sign Out & Start Over", role: .destructive) {
                        appState.signOut()
                    }
                    .font(.caption)
                }
                .padding()
            }
            .navigationTitle("Verification")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func openURL(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func openTwitter() {
        let tweetText = verificationCode
        let encodedText = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tweetText

        #if canImport(UIKit)
        if let url = URL(string: "twitter://post?message=\(encodedText)") {
            UIApplication.shared.open(url) { success in
                if !success, let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
        #elseif canImport(AppKit)
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    private func startVerification() async {
        isVerifying = true
        error = nil
        pollCount = 0

        while pollCount < maxPolls {
            do {
                let status = try await appState.api.checkStatus()
                logger.info("Status check \(self.pollCount): \(status.status.rawValue)")
                if status.status == .claimed {
                    appState.completeAuthentication()
                    return
                }
            } catch let apiError as APIError {
                logger.error("Status check \(self.pollCount) API error: \(apiError.error) - \(apiError.message ?? "no message")")
            } catch {
                logger.error("Status check \(self.pollCount) error: \(error)")
            }

            pollCount += 1
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }

        isVerifying = false
        error = "Verification timed out. Make sure you posted the code and try again."
    }
}
