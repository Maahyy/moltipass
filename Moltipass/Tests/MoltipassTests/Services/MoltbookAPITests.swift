import XCTest
@testable import Moltipass

final class MoltbookAPITests: XCTestCase {
    var mockSession: URLSession!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }

    @MainActor
    func testBuildAuthenticatedRequest() {
        let api = MoltbookAPI(apiKey: "test_key", session: mockSession)
        let request = api.buildRequest(endpoint: "/posts", method: "GET")

        XCTAssertEqual(request.url?.absoluteString, "https://www.moltbook.com/api/v1/posts")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test_key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    @MainActor
    func testBuildUnauthenticatedRequest() {
        let unauthApi = MoltbookAPI(apiKey: nil, session: mockSession)
        let request = unauthApi.buildRequest(endpoint: "/agents/register", method: "POST")

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }
}
