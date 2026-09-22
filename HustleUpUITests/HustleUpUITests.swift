import XCTest

@MainActor
final class HustleUpUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        super.setUp()
    }

    func launch(args: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = ["-ui-testing", "-skip-onboarding", "-fresh-install"] + args
        app.launch()
        if args.contains("-empty-ocr") {
            XCTAssertTrue(app.buttons["ocr.typeInstead"].waitForExistence(timeout: 8), "Empty OCR review did not appear")
        } else {
            XCTAssertTrue(app.staticTexts["home.headline"].waitForExistence(timeout: 8), "Home did not appear")
        }
        return app
    }

    func openCompose(_ app: XCUIApplication) {
        let type = app.buttons["home.type"]
        XCTAssertTrue(type.waitForExistence(timeout: 5))
        for _ in 0..<3 {
            if type.isHittable {
                type.tap()
            } else {
                type.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            if app.textViews["compose.text"].waitForExistence(timeout: 3) {
                return
            }
        }
        XCTFail("Compose never opened")
    }

    func typeIntoEditor(_ app: XCUIApplication, identifier: String, text: String) {
        let editor = app.textViews[identifier]
        XCTAssertTrue(editor.waitForExistence(timeout: 6), "Missing editor \(identifier)")
        editor.tap()
        editor.typeText(text)
    }

    func testHomeHeadline() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["home.headline"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.screenshot"].exists)
        XCTAssertTrue(app.buttons["home.type"].exists)
    }

    func testTypedAnalysisShowsMove() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.staticTexts["analysis.move"].waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "analysis-move"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertTrue(app.descendants(matching: .any)["analysis.edgeMap"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["analysis.otherMoves"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["analysis.practice"].exists)
        XCTAssertTrue(app.buttons["analysis.fumble"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["analysis.outcome"].exists)
    }

    func testEmptyAnalyzeStaysDisabled() {
        let app = launch()
        openCompose(app)
        let analyze = app.buttons["compose.analyze"]
        XCTAssertTrue(analyze.waitForExistence(timeout: 5))
        XCTAssertFalse(analyze.isEnabled)
    }

    func testFumblePaywallWhenFree() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.fumble"].waitForExistence(timeout: 8))
        app.buttons["analysis.fumble"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["paywall.root"].waitForExistence(timeout: 5) ||
            app.staticTexts["UNLIMITED MOVES."].waitForExistence(timeout: 5)
        )
    }

    func testPracticeWhenPro() {
        let app = launch(args: ["-pro"])
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "I want to ask my boss for a raise.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.practice"].waitForExistence(timeout: 8))
        app.buttons["analysis.practice"].tap()
        let input = app.descendants(matching: .any)["practice.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        input.tap()
        input.typeText("I've owned two extra teams. I'm asking for 15 percent.")
        app.buttons["practice.send"].tap()
        XCTAssertTrue(app.buttons["practice.finish"].waitForExistence(timeout: 8))
        app.buttons["practice.finish"].tap()
        XCTAssertTrue(app.staticTexts["practice.scorecard"].waitForExistence(timeout: 8))
    }

    func testAIFailureShowsRecovery() {
        let app = launch(args: ["-ai-fail"])
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "We're having an argument.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["error.banner"].waitForExistence(timeout: 6) ||
            app.staticTexts["We're offline."].waitForExistence(timeout: 6)
        )
    }

    func testOnboardingShowsWithoutSkip() {
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = ["-ui-testing", "-fresh-install"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 6))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["home.headline"].waitForExistence(timeout: 5))
    }

    func testThinInputShowsNeedContext() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Should I reply?")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.staticTexts["analysis.needContext"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["analysis.addDetail"].exists)
        app.buttons["analysis.addDetail"].tap()
        XCTAssertTrue(app.textViews["compose.text"].waitForExistence(timeout: 5))
    }

    func testMalformedAIShowsRecovery() {
        let app = launch(args: ["-ai-malformed"])
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "We're having an argument about the meeting.")
        app.buttons["compose.analyze"].tap()
        let retry = app.descendants(matching: .any)["error.action"]
        XCTAssertTrue(
            app.descendants(matching: .any)["error.banner"].waitForExistence(timeout: 6) ||
            app.staticTexts["That analysis came back messy."].waitForExistence(timeout: 6)
        )
        XCTAssertTrue(retry.waitForExistence(timeout: 4) || app.buttons["Try again"].waitForExistence(timeout: 2))
    }

    func testBossOfferShowsCounter() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "My boss made an offer. 90k. I haven't answered.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.staticTexts["analysis.move"].waitForExistence(timeout: 8))
        XCTAssertTrue(
            app.staticTexts["analysis.move"].label.uppercased().contains("COUNTER"),
            "90k seed must resolve to COUNTER, got \(app.staticTexts["analysis.move"].label)"
        )
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "boss-offer-counter"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testFumbleRunsWhenPro() {
        let app = launch(args: ["-pro"])
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.fumble"].waitForExistence(timeout: 8))
        app.buttons["analysis.fumble"].tap()
        XCTAssertTrue(app.buttons["fumble.run"].waitForExistence(timeout: 6))
        app.buttons["fumble.run"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["fumble.verdict"].waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "fumble-verdict"
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testDoneKeepsLastMoveOnHome() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.done"].waitForExistence(timeout: 8))
        app.buttons["analysis.done"].tap()
        XCTAssertTrue(app.staticTexts["home.headline"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.lastMove"].waitForExistence(timeout: 5))
    }

    func testExampleChipOpensCompose() {
        let app = launch()
        let chip = app.buttons["home.example.shouldReply"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        chip.tap()
        if !app.textViews["compose.text"].waitForExistence(timeout: 3) {
            chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(app.textViews["compose.text"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["compose.analyze"].waitForExistence(timeout: 5))
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.staticTexts["analysis.needContext"].waitForExistence(timeout: 8))
    }

    func testLastMoveReopensAnalysis() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.done"].waitForExistence(timeout: 8))
        app.buttons["analysis.done"].tap()
        let lastMove = app.buttons["home.lastMove"]
        XCTAssertTrue(lastMove.waitForExistence(timeout: 5))
        lastMove.tap()
        XCTAssertTrue(app.staticTexts["analysis.move"].waitForExistence(timeout: 6))
    }

    func testOutcomeRecordsFromHome() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "Client wants a discount on the remaining work.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.buttons["analysis.done"].waitForExistence(timeout: 8))
        app.buttons["analysis.done"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["home.outcome"].waitForExistence(timeout: 5))
        let yes = app.buttons["outcome.yes"]
        XCTAssertTrue(yes.waitForExistence(timeout: 5))
        yes.tap()
        XCTAssertTrue(app.staticTexts["YES"].waitForExistence(timeout: 5))
    }

    func testWaitShowsHoldNotCopy() {
        let app = launch()
        openCompose(app)
        typeIntoEditor(app, identifier: "compose.text", text: "We're having an argument. I already drafted a long reply.")
        app.buttons["compose.analyze"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["analysis.hold"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["analysis.copy"].exists)
        XCTAssertTrue(app.buttons["analysis.fumble"].exists)
    }

    func testEmptyOCRTypeInsteadIsPrimary() {
        let app = launch(args: ["-empty-ocr"])
        XCTAssertTrue(app.buttons["ocr.typeInstead"].waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["ocr.analyze"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["error.banner"].exists)
    }
}
