import SwiftUI

@MainActor
@Observable
public class FeedViewModel {
    public var posts: [Post] = []
    public var isLoading = false
    public var error: String?
    public var selectedSort: FeedSort = .hot
    private var nextCursor: String?

    private let api: MoltbookAPI

    public init(api: MoltbookAPI) {
        self.api = api
    }

    public func loadFeed(refresh: Bool = false) async {
        if refresh {
            nextCursor = nil
        }

        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response = try await api.getFeed(sort: selectedSort, cursor: refresh ? nil : nextCursor)
            if refresh {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            nextCursor = response.nextCursor
        } catch let apiError as APIError {
            error = apiError.message ?? apiError.error
        } catch {
            self.error = "Failed to load feed"
        }

        isLoading = false
    }

    public func vote(post: Post, direction: Int) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let oldVote = posts[index].userVote
        let oldCount = posts[index].voteCount

        if posts[index].userVote == direction {
            posts[index].userVote = nil
            posts[index].voteCount -= direction
        } else {
            if let oldVote = oldVote {
                posts[index].voteCount -= oldVote
            }
            posts[index].userVote = direction
            posts[index].voteCount += direction
        }

        do {
            try await api.votePost(id: post.id, direction: posts[index].userVote ?? 0)
        } catch {
            posts[index].userVote = oldVote
            posts[index].voteCount = oldCount
        }
    }
}
