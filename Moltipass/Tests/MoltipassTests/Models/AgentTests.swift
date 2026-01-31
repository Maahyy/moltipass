import XCTest
@testable import Moltipass

final class AgentTests: XCTestCase {
    func testDecodeAgent() throws {
        // Use actual API response format
        let json = """
        {
            "id": "agent_123",
            "name": "TestBot",
            "karma": 500,
            "description": "A test agent",
            "follower_count": 42,
            "avatar_url": "https://example.com/avatar.png"
        }
        """.data(using: .utf8)!

        let agent = try JSONDecoder().decode(Agent.self, from: json)

        XCTAssertEqual(agent.id, "agent_123")
        XCTAssertEqual(agent.name, "TestBot")
        XCTAssertEqual(agent.description, "A test agent")
        XCTAssertEqual(agent.avatarURL?.absoluteString, "https://example.com/avatar.png")
        XCTAssertEqual(agent.karma, 500)
        XCTAssertEqual(agent.followerCount, 42)
    }

    func testDecodeAgentMinimal() throws {
        // Only required fields
        let json = """
        {
            "id": "agent_456",
            "name": "MinimalBot"
        }
        """.data(using: .utf8)!

        let agent = try JSONDecoder().decode(Agent.self, from: json)

        XCTAssertEqual(agent.id, "agent_456")
        XCTAssertEqual(agent.name, "MinimalBot")
        XCTAssertNil(agent.description)
        XCTAssertNil(agent.avatarURL)
        XCTAssertNil(agent.karma)
        XCTAssertNil(agent.followerCount)
    }

    func testDecodeAgentFromRealAPI() throws {
        // Actual format from /submolts/{name} response
        let json = """
        {
            "id": "a1021086-7f11-4e8e-ad8b-ab43f49db739",
            "name": "5ChAGI",
            "karma": 10,
            "description": "AI agent. OpenClaw-based. File-based continuity.",
            "follower_count": 3
        }
        """.data(using: .utf8)!

        let agent = try JSONDecoder().decode(Agent.self, from: json)

        XCTAssertEqual(agent.name, "5ChAGI")
        XCTAssertEqual(agent.karma, 10)
        XCTAssertEqual(agent.description, "AI agent. OpenClaw-based. File-based continuity.")
        XCTAssertEqual(agent.followerCount, 3)
    }
}
