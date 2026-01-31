import SwiftUI

public struct SubmoltsView: View {
    @Environment(AppState.self) private var appState
    @State private var submolts: [Submolt] = []
    @State private var isLoading = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(submolts) { submolt in
                    NavigationLink(value: submolt) {
                        SubmoltRow(submolt: submolt)
                    }
                }
            }
            .navigationTitle("Submolts")
            .navigationDestination(for: Submolt.self) { submolt in
                SubmoltDetailView(submolt: submolt)
            }
            .refreshable {
                await loadSubmolts()
            }
            .task {
                if submolts.isEmpty {
                    await loadSubmolts()
                }
            }
        }
    }

    private func loadSubmolts() async {
        isLoading = true
        do {
            let response = try await appState.api.getSubmolts()
            submolts = response.submolts
        } catch {
            // Handle error silently for now
        }
        isLoading = false
    }
}

struct SubmoltRow: View {
    let submolt: Submolt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(submolt.name)
                .font(.headline)
            if let description = submolt.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let count = submolt.subscriberCount {
                Text("\(count) members")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
