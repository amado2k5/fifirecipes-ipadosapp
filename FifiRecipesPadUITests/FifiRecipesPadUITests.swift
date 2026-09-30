import XCTest

/// UI tests run against the live fifi.cooking API (the product is
/// online-only); the offline test points the client at a dead origin via
/// the -fifi.apiOrigin launch override.
@MainActor
final class FifiRecipesPadUITests: XCTestCase {

    private func launch(
        _ app: XCUIApplication, lang: String? = nil, apiOrigin: String? = nil
    ) {
        app.launchArguments += ["-fifi.reset", "1"]
        if let lang { app.launchArguments += ["-fifi.language", lang] }
        if let apiOrigin { app.launchArguments += ["-fifi.apiOrigin", apiOrigin] }
        app.launch()
    }

    /// Identifiers are placed on ScrollViews and container views, so query
    /// every element type rather than just `otherElements`.
    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    // MARK: first-run picker → home

    func testFirstRunLanguagePickerThenHome() throws {
        let app = XCUIApplication()
        launch(app)

        let picker = el(app, "languagePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 30))

        let english = app.buttons["lang-en"]
        XCTAssertTrue(english.waitForExistence(timeout: 10))
        english.tap()

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 30))
    }

    // MARK: RTL smoke — Arabic mirrors the layout

    func testArabicRTLLayout() throws {
        let app = XCUIApplication()
        launch(app, lang: "ar")
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 30))

        // In RTL the sidebar sits at the trailing (right) edge — its x
        // position should be right of center, not left.
        let sidebar = el(app, "sidebar")
        XCTAssertTrue(sidebar.waitForExistence(timeout: 10))
        let screenMid = app.windows.firstMatch.frame.midX
        XCTAssertGreaterThan(sidebar.frame.midX, screenMid,
                             "RTL: sidebar should sit on the right half")
        XCTAssertTrue(el(app, "nav-home").waitForExistence(timeout: 10))
    }

    // MARK: kids flow end-to-end

    func testKidsFlowEndToEnd() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 30))
        el(app, "nav-kids").tap()

        let kidsGrid = el(app, "kidsScreen")
        XCTAssertTrue(kidsGrid.waitForExistence(timeout: 30))

        // Group filter chips exist under the kids screen.
        let filter = kidsGrid.descendants(matching: .button)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "kidsFilter-"))
            .element(boundBy: 0)
        XCTAssertTrue(filter.waitForExistence(timeout: 15))
        // First actual card: any button that is not a filter chip.
        let cards = kidsGrid.descendants(matching: .button).matching(
            NSPredicate(format: "NOT (identifier BEGINSWITH 'kidsFilter-')"))
        let card = cards.element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.tap()

        XCTAssertTrue(el(app, "kidsReady").waitForExistence(timeout: 30))

        let startButton = app.buttons["kidsStartCooking"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 15))
        startButton.tap()

        XCTAssertTrue(el(app, "kidsSteps").waitForExistence(timeout: 30))

        let next = app.buttons["kidsStepNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        // Walk through the steps until the celebration screen appears.
        for _ in 0..<20 where !el(app, "kidsDone").exists {
            next.tap()
        }
        XCTAssertTrue(el(app, "kidsDone").waitForExistence(timeout: 10))
    }

    // MARK: search

    func testSearchTypeAndOpenResult() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 30))
        el(app, "nav-search").tap()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap()
        field.typeText("rice")

        // Give live filtering a beat, then open the first result card.
        sleep(3)
        let results = el(app, "searchScreen")
        XCTAssertTrue(results.exists)
        let firstCard = results.descendants(matching: .button).element(boundBy: 0)
        if firstCard.waitForExistence(timeout: 15) {
            firstCard.tap()
            XCTAssertTrue(el(app, "recipeDetail").waitForExistence(timeout: 30))
        }
    }

    // MARK: offline → retry

    func testOfflineShowsErrorWithRetry() throws {
        let app = XCUIApplication()
        launch(app, apiOrigin: "http://127.0.0.1:1")
        let error = el(app, "errorScreen")
        XCTAssertTrue(error.waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["retryButton"].exists)
    }
}
