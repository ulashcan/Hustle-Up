import Foundation
import Testing
@testable import HustleUp

struct MoveVerbTests {
    @Test(arguments: [
        ("COUNTER", MoveVerb.counter),
        ("counter.", MoveVerb.counter),
        ("SEND IT", MoveVerb.send),
        ("wait", MoveVerb.wait),
        ("WALK AWAY", MoveVerb.walk),
        ("ASK", MoveVerb.ask)
    ])
    func parsesKnownMoves(raw: String, expected: MoveVerb) {
        #expect(MoveVerb.parse(raw) == expected)
    }

    @Test func unknownMoveIsNil() {
        #expect(MoveVerb.parse("vibes") == nil)
    }
}

struct AIResponseParserTests {
    @Test func parsesCompleteAnalysis() throws {
        let json = """
        {
          "situation": "They lowballed you.",
          "userEdge": ["You can walk"],
          "otherSideEdge": ["They hold budget"],
          "risks": ["Anchoring low"],
          "knownFacts": ["An offer exists"],
          "assumptions": ["They can move"],
          "unknowns": ["Ceiling unknown"],
          "move": "COUNTER",
          "moveReason": "Don't accept their frame.",
          "suggestedActions": ["Name a number"],
          "suggestedResponses": ["I'm looking for X."],
          "confidence": 0.8,
          "category": "negotiation"
        }
        """.data(using: .utf8)!
        let analysis = try AIResponseParser.parseAnalysis(json)
        #expect(analysis.move == .counter)
        #expect(analysis.category == .negotiation)
        #expect(analysis.userEdge == ["You can walk"])
        #expect(analysis.unknowns.contains("Ceiling unknown"))
    }

    @Test func wrappedJSONAndSnakeCaseStillParse() throws {
        let json = """
        {
          "analysis": {
            "situation": "A reply is pending.",
            "user_edge": ["You haven't sent it"],
            "other_side_edge": ["They set the tempo"],
            "risks": ["Speed reads as anxiety"],
            "known_facts": ["A message arrived"],
            "move": "WAIT",
            "move_reason": "Let it cool.",
            "suggested_actions": ["Draft, don't send"],
            "suggested_responses": ["(Don't send.)"],
            "confidence": 0.66,
            "category": "reply"
          }
        }
        """.data(using: .utf8)!
        let analysis = try AIResponseParser.parseAnalysis(json)
        #expect(analysis.move == .wait)
        #expect(analysis.userEdge == ["You haven't sent it"])
    }

    @Test func missingMoveFallsBackToAskAndDropsConfidence() throws {
        let json = """
        { "situation": "Something is happening.", "move": "VIBES", "confidence": 0.9 }
        """.data(using: .utf8)!
        let analysis = try AIResponseParser.parseAnalysis(json)
        #expect(analysis.move == .ask)
        #expect(analysis.usedFallbackMove)
        #expect(analysis.confidence <= 0.4)
    }

    @Test func emptySituationIsMalformed() {
        let json = """
        { "situation": "   ", "move": "ASK" }
        """.data(using: .utf8)!
        #expect(throws: AppError.malformedAIResponse) {
            try AIResponseParser.parseAnalysis(json)
        }
    }

    @Test func garbageJSONIsMalformed() {
        let json = Data("not-json".utf8)
        #expect(throws: AppError.malformedAIResponse) {
            try AIResponseParser.parseAnalysis(json)
        }
    }

    @Test func emptyBodyIsMalformed() {
        #expect(throws: AppError.malformedAIResponse) {
            try AIResponseParser.parseAnalysis(Data())
        }
        #expect(throws: AppError.malformedAIResponse) {
            try AIResponseParser.parseFumble(Data())
        }
    }

    @Test func fumbleUnknownVerdictTightens() throws {
        let json = Data(#"{ "verdict": "vibes", "headline": "Hmm.", "reason": "Not a known call." }"#.utf8)
        let result = try AIResponseParser.parseFumble(json)
        #expect(result.verdict == .tighten)
    }

    @Test func fumbleParsesSendIt() throws {
        let json = """
        { "verdict": "SEND IT", "headline": "Strong and clear.", "reason": "No leak." }
        """.data(using: .utf8)!
        let result = try AIResponseParser.parseFumble(json)
        #expect(result.verdict == .sendIt)
        #expect(result.improvedMessage == nil)
    }

    @Test func scorecardClampsAndRequiresCopy() {
        let json = """
        { "confidence": 99, "clarity": 0, "persuasion": 5, "strategicPositioning": 5,
          "strongestMistake": "", "suggestedImprovement": "Be shorter." }
        """.data(using: .utf8)!
        #expect(throws: AppError.malformedAIResponse) {
            try AIResponseParser.parseScorecard(json)
        }
    }
}
