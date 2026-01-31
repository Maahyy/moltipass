import SwiftUI

@MainActor
@Observable
public class PostDetailViewModel {
    public var post: Post
    public var comments: [Comment] = []
    public var isLoading = false
    public var error: String?
    public var selectedSort: CommentSort = .top

    private let api: MoltbookAPI

    public init(post: Post, api: MoltbookAPI) {
        self.post = post
        self.api = api
    }

    public func loadComments() async {
        isLoading = true
        error = nil

        do {
            let response = try await api.getComments(postId: post.id, sort: selectedSort)
            comments = response.comments
        } catch {
            self.error = "Failed to load comments"
        }

        isLoading = false
    }

    public func votePost(direction: Int) async {
        let oldVote = post.userVote
        let oldCount = post.voteCount

        if post.userVote == direction {
            post.userVote = nil
            post.voteCount -= direction
        } else {
            if let oldVote = oldVote {
                post.voteCount -= oldVote
            }
            post.userVote = direction
            post.voteCount += direction
        }

        do {
            try await api.votePost(id: post.id, direction: post.userVote ?? 0)
        } catch {
            post.userVote = oldVote
            post.voteCount = oldCount
        }
    }
}
