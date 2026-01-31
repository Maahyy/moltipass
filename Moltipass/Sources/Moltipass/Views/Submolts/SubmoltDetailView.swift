import SwiftUI

public struct SubmoltDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var submolt: Submolt
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var error: String?

    public init(submolt: Submolt) {
        self._submolt = State(initialValue: submolt)
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = submolt.description {
                        Text(description)
                    }
                    if let count = submolt.subscriberCount {
                        Text("\(count) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(submolt.isSubscribed ? "Leave" : "Join") {
                        Task { await toggleSubscription() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section("Posts") {
                if isLoading {
                    ProgressView()
                } else if posts.isEmpty {
                    Text("No posts yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(posts) { post in
                        NavigationLink(value: post) {
                            PostCellView(post: post)
                        }
                    }
                }
            }
        }
        .navigationTitle(submolt.title)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .task {
            await loadSubmoltDetail()
        }
        .refreshable {
            await loadSubmoltDetail()
        }
    }

    private func loadSubmoltDetail() async {
        isLoading = true
        error = nil
        do {
            let response = try await appState.api.getSubmoltDetail(name: submolt.name)
            submolt = response.submolt
            posts = response.posts
        } catch {
            self.error = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func toggleSubscription() async {
        do {
            if submolt.isSubscribed {
                try await appState.api.unsubscribe(submoltName: submolt.name)
                submolt.isSubscribed = false
            } else {
                try await appState.api.subscribe(submoltName: submolt.name)
                submolt.isSubscribed = true
            }
        } catch {
            self.error = "Failed to update subscription"
        }
    }
}
