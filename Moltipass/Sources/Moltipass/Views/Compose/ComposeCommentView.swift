import SwiftUI

public struct ComposeCommentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    public let postId: String
    public var parentId: String?

    @State private var content = ""
    @State private var isSubmitting = false
    @State private var error: String?

    public init(postId: String, parentId: String? = nil) {
        self.postId = postId
        self.parentId = parentId
    }

    private var canSubmit: Bool {
        !content.isEmpty && !isSubmitting
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Write a comment...", text: $content, axis: .vertical)
                        .lineLimit(3...10)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(parentId != nil ? "Reply" : "Comment")
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
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil

        do {
            _ = try await appState.api.createComment(postId: postId, content: content, parentId: parentId)
            dismiss()
        } catch let apiError as APIError {
            if apiError.error == "rate_limited" {
                error = "Comment rate limit reached. Please wait."
            } else {
                error = apiError.message ?? apiError.error
            }
        } catch {
            self.error = "Failed to post comment"
        }

        isSubmitting = false
    }
}
