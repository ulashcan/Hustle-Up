import Foundation
import Testing
@testable import HustleUp

struct ContextGateTests {
    @Test func bareReplyIsInsufficient() {
        let result = ContextGate.assess("Should I reply?")
        #expect(!result.isSufficient)
        #expect(!result.missing.isEmpty)
    }

    @Test func fragmentIsInsufficient() {
        #expect(!ContextGate.assess("help").isSufficient)
        #expect(!ContextGate.assess("what do I do").isSufficient)
    }

    @Test func bossOfferIsEnoughToAsk() {
        #expect(ContextGate.assess("My boss made an offer").isSufficient)
    }

    @Test func clientDiscountIsEnough() {
        #expect(ContextGate.assess("Client wants a discount on the remaining work.").isSufficient)
    }

    @Test func raiseAskIsEnough() {
        #expect(ContextGate.assess("I want to ask my boss for a raise.").isSufficient)
    }

    @Test func twoWordFightIsInsufficient() {
        #expect(!ContextGate.assess("We're fighting").isSufficient)
    }

    @Test func pronounOnlySendQuestionIsInsufficient() {
        #expect(!ContextGate.assess("Should I send it to them?").isSufficient)
        #expect(!ContextGate.assess("What's the move here?").isSufficient)
    }
}

struct SituationInterpreterTests {
    @Test func insufficientReturnsUnknownAndNoInventedEdge() throws {
        let analysis = try SituationInterpreter.analyze("Should I reply?")
        #expect(analysis.needsMoreContext)
        #expect(analysis.evidenceStrength == .unknown)
        #expect(analysis.userEdge.isEmpty)
        let blob = analysis.situation.lowercased()
        #expect(!blob.contains("they came to you"))
    }

    @Test func doesNotInventTheyInitiated() throws {
        let analysis = try SituationInterpreter.analyze("I want to ask my boss for a raise next week after the review.")
        let joined = analysis.userEdge.joined(separator: " ").lowercased()
        #expect(!joined.contains("they initiated"))
        #expect(!joined.contains("they came to you"))
    }

    @Test func theyOfferedIsAStrongSignal() throws {
        let analysis = try SituationInterpreter.analyze("They offered 90k for the role. Should I take it or counter?")
        #expect(!analysis.needsMoreContext)
        #expect(analysis.move == .counter)
        #expect(analysis.userEdge.contains { $0.contains("STRONG SIGNAL") })
        #expect(analysis.unknowns.contains { $0.lowercased().contains("unknown") })
        #expect(!analysis.knownFacts.joined().lowercased().contains("market average"))
    }

    @Test func unansweredOfferOwnsTiming() throws {
        let analysis = try SituationInterpreter.analyze("My boss made an offer. 90k. I haven't answered.")
        #expect(analysis.move == .counter)
        #expect(analysis.userEdge.contains { $0.lowercased().contains("timing") || $0.lowercased().contains("haven't") })
    }

    @Test func alreadySentFollowUpDoesNotOwnTiming() throws {
        let analysis = try SituationInterpreter.analyze(
            "I already sent the reply to my boss about the 90k offer. Should I send a follow up?"
        )
        let joined = analysis.userEdge.joined(separator: " ").lowercased()
        #expect(!joined.contains("hasn't gone out"))
        #expect(!joined.contains("you still own timing"))
    }

    @Test func doubleTextWaits() throws {
        let analysis = try SituationInterpreter.analyze("They left me on read. I already wrote a double text. Should I send it?")
        #expect(analysis.move == .wait)
        #expect(analysis.moveReason.lowercased().contains("don't send another") || analysis.suggestedActions.joined().lowercased().contains("don't send another"))
    }

    @Test func uninterestedWalks() throws {
        let analysis = try SituationInterpreter.analyze("They said they're not interested and asked me not to contact them.")
        #expect(analysis.move == .walk)
    }

    @Test func interestedCanSend() throws {
        let analysis = try SituationInterpreter.analyze("They texted they're in and said let's hang out Friday.")
        #expect(analysis.move == .send)
        #expect(analysis.category == .reply)
    }

    @Test func lowballCounters() throws {
        let analysis = try SituationInterpreter.analyze("The client sent a lowball offer at half my rate and wants an answer today.")
        #expect(analysis.move == .counter)
        #expect(analysis.evidenceStrength != .unknown)
    }

    @Test func userOwnsTheMistakeThenSends() throws {
        let analysis = try SituationInterpreter.analyze("I yelled at my coworker in the meeting. I was wrong and I need to say something.")
        #expect(analysis.move == .send)
        #expect(analysis.category == .conflict)
    }

    @Test func neverShowsFakePercentCertaintyInCopy() throws {
        let analysis = try SituationInterpreter.analyze("Client wants a discount on the remaining work this quarter.")
        #expect(analysis.evidenceStrength != .unknown)
        #expect(analysis.confidence < 0.9)
    }

    @Test func ambiguousMaybeWaitsInsteadOfInventingInterest() throws {
        let analysis = try SituationInterpreter.analyze("They said maybe we should hang sometime this month.")
        #expect(analysis.move == .wait)
        #expect(analysis.evidenceStrength != .strongSignal)
        let blob = (analysis.userEdge + analysis.knownFacts + [analysis.situation]).joined(separator: " ").lowercased()
        #expect(!blob.contains("they're into you"))
        #expect(!blob.contains("74%"))
    }

    @Test func otherPersonWrongStillWaitsInAFight() throws {
        let analysis = try SituationInterpreter.analyze("They yelled at me in the meeting and everyone heard. I stayed quiet.")
        #expect(analysis.category == .conflict)
        #expect(analysis.move == .wait)
        #expect(!analysis.knownFacts.joined().lowercased().contains("you were right"))
    }

    @Test func freelanceLowballDoesNotInventAMarketRate() throws {
        let analysis = try SituationInterpreter.analyze("A client asked my freelance rate and offered 400 for the whole site. That's a lowball.")
        #expect(analysis.move == .counter)
        let blob = (analysis.knownFacts + analysis.unknowns + [analysis.situation]).joined(separator: " ").lowercased()
        #expect(blob.contains("unknown"))
        #expect(!blob.contains("market average"))
        #expect(!blob.contains("percentile"))
    }

    @Test func urgentBuyerDoesNotForceAYes() throws {
        let analysis = try SituationInterpreter.analyze("A buyer wants to close today at a steep discount on the remaining work.")
        #expect(analysis.move == .counter || analysis.move == .ask)
        #expect(analysis.move != .send)
    }
}

struct FumbleEngineTests {
    @Test func goodShortMessageSends() throws {
        let result = try FumbleEngine.check(
            message: "I'm at 12k, net 30.",
            context: FumbleContext(situationText: "invoice", recommendedMove: .send)
        )
        #expect(result.verdict == .sendIt)
    }

    @Test func selfNegotiationFumbles() throws {
        let result = try FumbleEngine.check(
            message: "Sorry I can go lower or whatever you think is fair whenever you want",
            context: FumbleContext(situationText: "rate", recommendedMove: .counter)
        )
        #expect(result.verdict == .fumble)
    }

    @Test func aggressiveFumbles() throws {
        let result = try FumbleEngine.check(
            message: "You better take this or else I'm walking.",
            context: FumbleContext(situationText: "deal", recommendedMove: .counter)
        )
        #expect(result.verdict == .fumble)
        #expect(result.headline.lowercased().contains("threat"))
    }

    @Test func desperateFumbles() throws {
        let result = try FumbleEngine.check(
            message: "Please please I'll do anything I really need this job.",
            context: FumbleContext(situationText: "job", recommendedMove: .ask)
        )
        #expect(result.verdict == .fumble)
    }

    @Test func contradictionFumbles() throws {
        let result = try FumbleEngine.check(
            message: "I can do Friday. I can't do Friday. Whatever works.",
            context: FumbleContext(situationText: "schedule", recommendedMove: .ask)
        )
        #expect(result.verdict == .fumble)
    }

    @Test func waitRecommendationBlocksTheSend() throws {
        let result = try FumbleEngine.check(
            message: "Sure, that works on my side.",
            context: FumbleContext(situationText: "hot fight", recommendedMove: .wait)
        )
        #expect(result.verdict == .fumble)
    }

    @Test func overExplainingFumbles() throws {
        let message = "Sorry I just wanted to say that maybe we could look at this again because I think there are a lot of factors and I don't want to upset anyone so whenever you have time we can talk through the history of how we got here and I can explain my side in more detail than anyone needs."
        let result = try FumbleEngine.check(
            message: message,
            context: FumbleContext(situationText: "rate", recommendedMove: .ask)
        )
        #expect(result.verdict == .fumble)
    }

    @Test func leakingPrivateFrameFumbles() throws {
        let result = try FumbleEngine.check(
            message: "Don't tell my boss. Between us I can do 90k.",
            context: FumbleContext(situationText: "offer", recommendedMove: .counter)
        )
        #expect(result.verdict == .fumble)
        #expect(result.headline.lowercased().contains("leverage"))
        #expect(!(result.improvedMessage ?? "").lowercased().contains("between us"))
    }

    @Test func adjustingDoesNotCountAsAJustHedge() throws {
        let result = try FumbleEngine.check(
            message: "I'm adjusting the timeline. I'm at 12k, net 30.",
            context: FumbleContext(situationText: "invoice", recommendedMove: .send)
        )
        #expect(result.verdict == .sendIt)
    }

    @Test func emptyThrows() {
        #expect(throws: AppError.emptyInput) {
            try FumbleEngine.check(message: "   ", context: FumbleContext(situationText: "", recommendedMove: nil))
        }
    }
}

struct PracticeEngineTests {
    @Test func salaryScriptDiffersFromConflict() throws {
        let salary = PracticeSession(id: UUID(), scenario: "I want to ask my boss for a raise.", otherPartyRole: "boss", turns: [], isComplete: false)
        let fight = PracticeSession(id: UUID(), scenario: "We're having an argument about last night.", otherPartyRole: "them", turns: [], isComplete: false)
        let a = try PracticeEngine.reply(session: salary, userMessage: "ask")
        let b = try PracticeEngine.reply(session: fight, userMessage: "ask")
        #expect(a.otherPartyReply != b.otherPartyReply)
        #expect(a.otherPartyReply.lowercased().contains("now") || a.otherPartyReply.lowercased().contains("budget") || a.otherPartyReply.lowercased().contains("listening"))
        #expect(a.shouldOfferToFinish == false)
    }

    @Test func hedgeGetsAHarderOpponentThanACleanAsk() throws {
        let session = PracticeSession(
            id: UUID(),
            scenario: "I want to ask my boss for a raise.",
            otherPartyRole: "boss",
            turns: [],
            isComplete: false
        )
        let clean = try PracticeEngine.reply(session: session, userMessage: "I'm asking for 15%.")
        let hedge = try PracticeEngine.reply(session: session, userMessage: "Sorry I just maybe need this raise.")
        #expect(clean.otherPartyReply != hedge.otherPartyReply)
        #expect(hedge.otherPartyReply.lowercased().contains("optional") || hedge.otherPartyReply.lowercased().contains("actual ask"))
    }

    @Test func adjustingDoesNotCountAsAPracticeHedge() throws {
        let session = PracticeSession(
            id: UUID(),
            scenario: "I want to ask my boss for a raise.",
            otherPartyRole: "boss",
            turns: [],
            isComplete: false
        )
        let clean = try PracticeEngine.reply(
            session: session,
            userMessage: "I'm asking for 15% because I shipped two extra teams."
        )
        let adjusting = try PracticeEngine.reply(
            session: session,
            userMessage: "I'm adjusting the start date. I'm asking for 15%."
        )
        #expect(clean.otherPartyReply == adjusting.otherPartyReply)

        let scoredClean = try PracticeEngine.score(
            PracticeSession(
                id: UUID(),
                scenario: "raise",
                otherPartyRole: "boss",
                turns: [PracticeTurn(id: UUID(), role: .user, text: "I'm asking for 15% because I shipped two extra teams.")],
                isComplete: false
            )
        )
        let scoredAdjust = try PracticeEngine.score(
            PracticeSession(
                id: UUID(),
                scenario: "raise",
                otherPartyRole: "boss",
                turns: [PracticeTurn(id: UUID(), role: .user, text: "I'm adjusting the start date. I'm asking for 15% because I shipped two extra teams.")],
                isComplete: false
            )
        )
        #expect(scoredAdjust.confidence >= scoredClean.confidence)
        #expect(!scoredAdjust.strongestMistake.lowercased().contains("optional"))
    }

    @Test func laterTurnsAdvanceTheScript() throws {
        var session = PracticeSession(id: UUID(), scenario: "I want to ask my boss for a raise.", otherPartyRole: "boss", turns: [], isComplete: false)
        let first = try PracticeEngine.reply(session: session, userMessage: "I'm asking for 15%.")
        session.turns.append(PracticeTurn(id: UUID(), role: .user, text: "I'm asking for 15%."))
        session.turns.append(PracticeTurn(id: UUID(), role: .other, text: first.otherPartyReply))
        let second = try PracticeEngine.reply(session: session, userMessage: "I shipped two extra teams.")
        #expect(first.otherPartyReply != second.otherPartyReply)
        #expect(second.shouldOfferToFinish)
    }

    @Test func scoringIsDeterministic() throws {
        let session = PracticeSession(id: UUID(), scenario: "raise", otherPartyRole: "boss", turns: [
            PracticeTurn(id: UUID(), role: .user, text: "I'm asking for 15% because I shipped two extra teams.")
        ], isComplete: false)
        let first = try PracticeEngine.score(session)
        let second = try PracticeEngine.score(session)
        #expect(first == second)
    }

    @Test func emptyPracticeWillNotScore() {
        let session = PracticeSession(id: UUID(), scenario: "raise", otherPartyRole: "boss", turns: [], isComplete: false)
        #expect(throws: AppError.emptyInput) {
            try PracticeEngine.score(session)
        }
    }
}

struct ProductCatalogTests {
    @Test func reservedIDsUnlockProFeatures() {
        #expect(ProductCatalog.unlocks(for: ProductCatalog.proMonthly).contains(.fumbleCheck))
        #expect(ProductCatalog.unlocks(for: "random").isEmpty)
    }

    @Test func unimplementedStoreFailsClosed() async {
        let store = UnimplementedStore()
        await #expect(throws: AppError.paywallRequired(.analysis)) {
            try await store.purchase(productID: ProductCatalog.proMonthly)
        }
        await #expect(throws: AppError.paywallRequired(.analysis)) {
            try await store.restore()
        }
    }
}

struct EvidenceStrengthTests {
    @Test func unknownWhenContextIsMissing() {
        #expect(EvidenceStrength.resolve(needsMoreContext: true, usedFallbackMove: false, confidence: 0.9) == .unknown)
    }

    @Test func doesNotPromoteFallbackToStrong() {
        #expect(EvidenceStrength.resolve(needsMoreContext: false, usedFallbackMove: true, confidence: 0.9) == .possible)
    }
}

struct SuggestedCopyTests {
    @Test func waitPlaceholderIsNotSendable() {
        #expect(!SuggestedCopy.isSendable("(Don't send.) If you must: I'll come back tomorrow."))
        #expect(SuggestedCopy.isSendable("Thanks for this. I'm looking for [X]."))
        #expect(SuggestedCopy.hasPlaceholder("Thanks for this. I'm looking for [X]."))
        #expect(!SuggestedCopy.hasPlaceholder("I'm at 12k, net 30."))
    }

    @Test func primarySendableSkipsDontSend() {
        let lines = [
            "(Don't send.) If you must: I need to think about this — I'll come back tomorrow.",
            "Thanks for this. I'm looking for [X]."
        ]
        #expect(SuggestedCopy.primarySendable(lines) == "Thanks for this. I'm looking for [X].")
        #expect(SuggestedCopy.primarySendable([lines[0]]) == nil)
        #expect(SuggestedCopy.holdLine([lines[0]]) == lines[0])
        #expect(SuggestedCopy.holdLine(lines) == nil)
    }
}
