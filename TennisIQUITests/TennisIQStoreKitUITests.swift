import XCTest
import StoreKit
import StoreKitTest

/// Exercises the shipping UI and verified StoreKit transactions. No app-side entitlement overrides.
/// Run serially: Apple's local StoreKit environment is shared by all test sessions.
@MainActor
final class TennisIQStoreKitUITests: XCTestCase {
    private let productID = "com.srqtennis.TennisIQ.fullunlock"
    private var session: SKTestSession!
    private var app: XCUIApplication!

    private func launchFreshStore() throws {
        continueAfterFailure = false
        session = try SKTestSession(configurationFileNamed: "TennisIQ")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.storefront = "USA"
        session.locale = Locale(identifier: "en_US")
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["daily-rally"].waitForExistence(timeout: 15))
    }

    private func reveal(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        if !element.exists { _ = element.waitForExistence(timeout: 2) }
        for _ in 0..<8 {
            if element.exists && element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists, file: file, line: line)
        XCTAssertTrue(element.isHittable, "Element is not reachable: \(element)", file: file, line: line)
    }

    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        reveal(element, file: file, line: line)
        element.tap()
    }

    private func wait(_ predicate: String, on element: XCUIElement, timeout: TimeInterval = 15,
                      file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func goHome() {
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["daily-rally"].waitForExistence(timeout: 15))
    }

    func testDailyRallyIsFreeAndCanBeCompleted() throws {
        try launchFreshStore()
        capture("01-free-home")
        tap(app.buttons["daily-rally"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["paywall.purchase"].exists)
        capture("02-free-gameplay")
        for question in 0..<10 {
            tap(app.buttons["answer-0"])
            let next = app.buttons[question == 9 ? "finish-quiz" : "next-question"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            if question == 0 { capture("03-answer-explanation") }
            tap(next)
        }
        XCTAssertTrue(app.staticTexts["quiz-results"].waitForExistence(timeout: 10))
        capture("04-free-results")
        XCTAssertTrue(session.allTransactions().isEmpty)
        goHome()
        // Daily Rally remains available after completing a round and relaunching.
        tap(app.buttons["daily-rally"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["paywall.purchase"].exists)
    }

    func testEveryPremiumEntryIsLockedAndEmptyRestoreDoesNotUnlock() throws {
        try launchFreshStore()
        for entry in ["shot-clock", "practice", "library"] {
            tap(app.buttons[entry])
            let purchase = app.buttons["paywall.purchase"]
            XCTAssertTrue(purchase.waitForExistence(timeout: 10))
            wait("enabled == true", on: purchase)
            XCTAssertTrue(purchase.label.contains("9.99"), "Expected the configured US price: \(purchase.label)")
            XCTAssertFalse(app.staticTexts["quiz-question"].exists)
            XCTAssertFalse(app.buttons["start-practice"].exists)
            if entry == "shot-clock" { capture("05-local-storekit-paywall") }
            tap(app.buttons["paywall.close"])
        }
        tap(app.buttons["library"])
        tap(app.buttons["paywall.restore"])
        wait("label CONTAINS 'No full-game purchase'", on: app.staticTexts["paywall.message"])
        XCTAssertTrue(session.allTransactions().isEmpty)
        tap(app.buttons["paywall.close"])
        tap(app.buttons["shot-clock"])
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
    }

    func testCancelledStoreKitPurchaseKeepsPremiumLocked() async throws {
        try launchFreshStore()
        try await session.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)
        tap(app.buttons["library"])
        let purchase = app.buttons["paywall.purchase"]
        wait("enabled == true", on: purchase)
        tap(purchase)
        XCTAssertTrue(app.staticTexts["paywall.message"].waitForExistence(timeout: 10))
        wait("enabled == true", on: purchase)
        XCTAssertFalse(session.allTransactions().contains { $0.state == .purchased })
        capture("06-cancelled-purchase")
        try await session.setSimulatedError(nil, forAPI: .purchase)
        goHome()
        tap(app.buttons["library"])
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
    }

    func testPurchasePersistsRestoresAndRefundRemovesAccess() throws {
        try launchFreshStore()
        tap(app.buttons["shot-clock"])
        let purchase = app.buttons["paywall.purchase"]
        wait("enabled == true", on: purchase)
        tap(purchase)
        wait("exists == false", on: app.buttons["paywall.close"])
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == productID && $0.state == .purchased })
        tap(app.buttons["shot-clock"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["paywall.purchase"].exists)
        capture("07-unlocked-shot-clock")
        goHome()
        tap(app.buttons["library"])
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["paywall.purchase"].exists)
        capture("08-unlocked-library-after-relaunch")
        goHome()
        tap(app.buttons["practice"])
        XCTAssertTrue(app.buttons["start-practice"].waitForExistence(timeout: 10))
        tap(app.buttons["start-practice"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        goHome()
        tap(app.buttons["About, Support & Privacy"])
        tap(app.buttons["restore-purchases"])
        XCTAssertTrue(app.staticTexts["Your full game is restored."].waitForExistence(timeout: 15))
        capture("09-restored-purchase")
        goHome()
        try session.refundTransaction(identifier: transaction.identifier)
        // The real transaction listener must revoke access while the app remains alive.
        wait("label == 'Unlock'", on: app.buttons["shot-clock"])
        tap(app.buttons["library"])
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
        capture("10-refunded-access-locked")
        tap(app.buttons["paywall.close"])
        tap(app.buttons["daily-rally"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
    }
    func testFailedPurchaseCanRetryWithoutPrematureUnlock() async throws {
        try launchFreshStore()
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
        tap(app.buttons["library"])
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        tap(app.buttons["paywall.purchase"])
        wait("label CONTAINS 'complete the purchase'", on: app.staticTexts["paywall.message"])
        XCTAssertFalse(session.allTransactions().contains { $0.state == .purchased })
        capture("11-failed-purchase-retry")
        try await session.setSimulatedError(nil, forAPI: .purchase)
        tap(app.buttons["paywall.purchase"])
        wait("exists == false", on: app.buttons["paywall.close"])
        tap(app.buttons["library"])
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
    }

    func testPendingApprovalOnlyUnlocksAfterApproval() throws {
        try launchFreshStore()
        session.askToBuyEnabled = true
        tap(app.buttons["practice"])
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        tap(app.buttons["paywall.purchase"])
        wait("label CONTAINS 'pending approval'", on: app.staticTexts["paywall.message"])
        XCTAssertFalse(session.allTransactions().contains { $0.state == .purchased })
        let pending = try XCTUnwrap(session.allTransactions().first { $0.state == .deferred })
        capture("12-pending-approval-locked")
        tap(app.buttons["paywall.close"])
        tap(app.buttons["library"])
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        wait("exists == false", on: app.buttons["paywall.close"])
        tap(app.buttons["library"])
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
        capture("13-approved-purchase-library")
    }

    func testShotClockExpiresWhileBackgrounded() async throws {
        try launchFreshStore()
        tap(app.buttons["shot-clock"])
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        tap(app.buttons["paywall.purchase"])
        wait("exists == false", on: app.buttons["paywall.close"])
        tap(app.buttons["shot-clock"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        XCUIDevice.shared.press(.home)
        try await Task.sleep(nanoseconds: 22_000_000_000)
        app.activate()
        XCTAssertTrue(app.staticTexts["Time’s up"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["answer-0"].isEnabled)
        XCTAssertTrue(app.buttons["next-question"].exists)
        capture("14-background-timer-expired")
        tap(app.buttons["next-question"])
        XCTAssertTrue(app.buttons["answer-0"].isEnabled)
    }

    /// Compact visual acceptance pass used on both iPhone and iPad after UI-only edits.
    func testReleaseScreenshots() throws {
        try launchFreshStore()
        capture("release-01-free-home")
        tap(app.buttons["daily-rally"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        capture("release-02-free-gameplay")
        tap(app.buttons["answer-0"])
        XCTAssertTrue(app.buttons["next-question"].waitForExistence(timeout: 10))
        capture("release-03-answer-explanation")
        goHome()
        tap(app.buttons["library"])
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        XCTAssertTrue(app.buttons["paywall.purchase"].label.contains("9.99"))
        capture("release-04-paywall")
        tap(app.buttons["paywall.purchase"])
        wait("exists == false", on: app.buttons["paywall.close"])
        XCTAssertTrue(session.allTransactions().contains { $0.productIdentifier == productID && $0.state == .purchased })
        capture("release-05-unlocked-home")
        tap(app.buttons["library"])
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 10))
        capture("release-06-library")
        goHome()
        tap(app.buttons["practice"])
        XCTAssertTrue(app.buttons["start-practice"].waitForExistence(timeout: 10))
        capture("release-07-practice")
    }

    private func finishRound(questionCount: Int) {
        for index in 0..<questionCount {
            tap(app.buttons["answer-0"])
            tap(app.buttons[index == questionCount - 1 ? "finish-quiz" : "next-question"])
        }
        XCTAssertTrue(app.staticTexts["quiz-results"].waitForExistence(timeout: 10))
    }

    private func buyFullGame() {
        tap(app.buttons["library"])
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        tap(app.buttons["paywall.purchase"])
        wait("exists == false", on: app.buttons["paywall.close"])
    }

    func testNewProgressPlacementShareAndPersistence() throws {
        try launchFreshStore()
        capture("progress-00-free-home")
        for entry in ["progress", "challenge"] {
            tap(app.buttons[entry])
            XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
            if entry == "progress" { capture("progress-00-paid-gate") }
            tap(app.buttons["paywall.close"])
        }
        tap(app.buttons["daily-rally"])
        finishRound(questionCount: 10)
        XCTAssertFalse(app.buttons["share-result-card"].exists)
        goHome()
        buyFullGame()
        tap(app.buttons["progress"])
        XCTAssertTrue(app.staticTexts["rated-question-count"].waitForExistence(timeout: 10))
        let initialCount = Int(app.staticTexts["rated-question-count"].label.split(separator: " ")[0]) ?? 0
        XCTAssertGreaterThanOrEqual(initialCount, 10)
        let badge = app.descendants(matching: .any)["badge-first-round"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 10))
        XCTAssertTrue(badge.label.contains("Earned"))
        capture("progress-01-saved-free-round")
        tap(app.buttons["take-placement"])
        tap(app.buttons["start-placement"])
        finishRound(questionCount: 30)
        XCTAssertTrue(app.staticTexts["result-rating"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["result-rating"].label.contains("Provisional"))
        let share = app.buttons["share-result-card"]
        XCTAssertTrue(share.waitForExistence(timeout: 10))
        for _ in 0..<6 where !share.isHittable { app.swipeUp() }
        capture("progress-02-placement-share-card")
        tap(share)
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 10))
        capture("progress-03-system-share-sheet")
        if app.buttons["Close"].firstMatch.exists {
            app.buttons["Close"].firstMatch.tap()
        } else {
            let dismiss = app.otherElements["PopoverDismissRegion"]
            XCTAssertTrue(dismiss.exists)
            dismiss.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.1)).tap()
        }
        wait("exists == false", on: app.otherElements["ActivityListView"])
        goHome()
        tap(app.buttons["progress"])
        let rating = app.staticTexts["knowledge-rating"].label
        let count = app.staticTexts["rated-question-count"].label
        XCTAssertGreaterThanOrEqual(Int(count.split(separator: " ")[0]) ?? 0, 30)
        capture("progress-04-completed-placement")
        goHome()
        tap(app.buttons["progress"])
        XCTAssertEqual(app.staticTexts["knowledge-rating"].label, rating)
        XCTAssertEqual(app.staticTexts["rated-question-count"].label, count)
    }

    func testNewChallengeCreateInvalidPasteAndDeepLink() throws {
        try launchFreshStore()
        buyFullGame()
        tap(app.buttons["challenge"])
        tap(app.buttons["create-challenge"])
        reveal(app.staticTexts["challenge-first-question"])
        let expectedQuestion = app.staticTexts["challenge-first-question"].label
        let input = app.textFields["challenge-link-input"].exists ? app.textFields["challenge-link-input"] : app.textViews["challenge-link-input"]
        let link = try XCTUnwrap(input.value as? String)
        XCTAssertTrue(link.hasPrefix("tennisiq://"))
        capture("challenge-01-created-link")
        tap(app.buttons["play-challenge"])
        XCTAssertTrue(app.staticTexts["quiz-question"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["quiz-question"].label, expectedQuestion)
        session.clearTransactions()
        goHome()
        app.open(try XCTUnwrap(URL(string: link)))
        XCTAssertTrue(app.buttons["paywall.purchase"].waitForExistence(timeout: 10))
        capture("challenge-02-locked-inbound-link")
        wait("enabled == true", on: app.buttons["paywall.purchase"])
        tap(app.buttons["paywall.purchase"])
        wait("exists == false", on: app.buttons["paywall.purchase"])
        reveal(app.staticTexts["challenge-first-question"])
        XCTAssertEqual(app.staticTexts["challenge-first-question"].label, expectedQuestion)
        capture("challenge-02-opened-deep-link")
        tap(app.buttons["play-challenge"])
        XCTAssertEqual(app.staticTexts["quiz-question"].label, expectedQuestion)
        goHome()
        tap(app.buttons["challenge"])
        let invalidInput = app.textFields["challenge-link-input"].exists ? app.textFields["challenge-link-input"] : app.textViews["challenge-link-input"]
        tap(invalidInput)
        invalidInput.typeText("https://example.invalid/not-a-challenge")
        tap(app.buttons["validate-challenge"])
        XCTAssertTrue(app.staticTexts["challenge-message"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["play-challenge"].exists)
        capture("challenge-03-invalid-link")
    }

}
