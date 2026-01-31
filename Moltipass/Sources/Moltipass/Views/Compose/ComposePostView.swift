import SwiftUI

public struct ComposePostView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var url = ""
    @State private var isLinkPost = false
    @State private var selectedSubmolt: Submolt?
    @State private var submolts: [Submolt] = []
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var error: String?

    public init() {}

    private var canSubmit: Bool {
        !title.isEmpty && selectedSubmolt != nil && !isSubmitting
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Post Type") {
                    Picker("Type", selection: $isLinkPost) {
                        Text("Text").tag(false)
                        Text("Link").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Content") {
                    TextField("Title", text: $title)

                    if isLinkPost {
                        TextField("URL", text: $url)
                            #if os(iOS)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            #endif
                    } else {
                        TextField("Body (optional)", text: $content, axis: .vertical)
                            .lineLimit(5...10)
                    }
                }

                Section("Community") {
                    if isLoading {
                        ProgressView()
                    } else {
                        Picker("Submolt", selection: $selectedSubmolt) {
                            Text("Select a community").tag(nil as Submolt?)
                            ForEach(submolts) { submolt in
                                Text(submolt.name).tag(submolt as Submolt?)
                            }
                        }
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Post")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                }
            }
            .task {
                await loadSubmolts()
            }
        }
    }

    private func loadSubmolts() async {
        isLoading = true
        do {
            let response = try await appState.api.getSubscribedSubmolts()
            submolts = response.submolts
        } catch {
            self.error = "Failed to load communities"
        }
        isLoading = false
    }

    private func submit() async {
        guard let submolt = selectedSubmolt else { return }

        isSubmitting = true
        error = nil

        do {
            _ = try await appState.api.createPost(
                title: title,
                content: isLinkPost ? nil : (content.isEmpty ? nil : content),
                url: isLinkPost ? url : nil,
                submolt: submolt.name
            )
            dismiss()
        } catch let apiError as APIError {
            if apiError.error == "rate_limited", let minutes = apiError.retryAfterMinutes {
                error = "You can post again in \(minutes) minutes"
            } else {
                error = apiError.message ?? apiError.error
            }
        } catch {
            self.error = "Failed to create post"
        }

        isSubmitting = false
    }
}
