import Foundation
import Testing
@testable import HustleUp

@Suite(.serialized)
struct LiveAIServiceTests {
    private func service() -> LiveAIService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return LiveAIService(
            endpoint: URL(string: "https://hustleup.test/v1")!,
            apiKey: nil,
            session: URLSession(configuration: config),
            timeout: 2
        )
    }

    @Test func emptyHTTP200IsMalformed() async {
        StubURLProtocol.requestHandler = { request in
            (Self.response(request, 200), Data())
        }
        await #expect(throws: AppError.malformedAIResponse) {
            try await service().analyze(input: AnalysisRequest(source: .typed, text: "Client wants a discount."))
        }
    }

    @Test func http429IsRateLimited() async {
        StubURLProtocol.requestHandler = { request in
            (Self.response(request, 429), Data("slow down".utf8))
        }
        await #expect(throws: AppError.rateLimited) {
            try await service().analyze(input: AnalysisRequest(source: .typed, text: "Client wants a discount."))
        }
    }

    @Test func http401IsUnavailable() async {
        StubURLProtocol.requestHandler = { request in
            (Self.response(request, 401), Data("nope".utf8))
        }
        await #expect(throws: AppError.modelUnavailable) {
            try await service().analyze(input: AnalysisRequest(source: .typed, text: "Client wants a discount."))
        }
    }

    @Test func wrappedJSONSucceeds() async throws {
        let body = Data("""
        {"analysis":{"situation":"They asked for a discount.","move":"COUNTER","move_reason":"Counter once.","confidence":0.6,"category":"negotiation","user_edge":["LIKELY. You can name a number."],"unknowns":["UNKNOWN. Their ceiling."]}}
        """.utf8)
        StubURLProtocol.requestHandler = { request in
            (Self.response(request, 200), body)
        }
        let analysis = try await service().analyze(input: AnalysisRequest(source: .typed, text: "Client wants a discount."))
        #expect(analysis.move == .counter)
        #expect(analysis.evidenceStrength != .unknown)
    }

    @Test func transportErrorIsOffline() async {
        StubURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        await #expect(throws: AppError.networkUnavailable) {
            try await service().analyze(input: AnalysisRequest(source: .typed, text: "Client wants a discount."))
        }
    }

    private static func response(_ request: URLRequest, _ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url ?? URL(string: "https://hustleup.test/v1")!, statusCode: code, httpVersion: nil, headerFields: nil)!
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
