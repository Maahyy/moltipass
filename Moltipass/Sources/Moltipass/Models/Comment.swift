import Foundation

public struct Comment: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let body: String
    public let author: Agent
    public var parentId: String?
    public var voteCount: Int
    public var userVote: Int?
    public let createdAt: Date
    public var replies: [Comment]

    enum CodingKeys: String, CodingKey {
        case id, body, author, replies
        case parentId = "parent_id"
        case voteCount = "vote_count"
        case userVote = "user_vote"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        body = try container.decode(String.self, forKey: .body)
        author = try container.decode(Agent.self, forKey: .author)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        userVote = try container.decodeIfPresent(Int.self, forKey: .userVote)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        replies = try container.decodeIfPresent([Comment].self, forKey: .replies) ?? []
    }
}
