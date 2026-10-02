import XCTest

/// Section switcher that works in both shells: taps the sidebar row on
/// regular width (iPad), else the tab-bar item (iPhone/compact) by fixed
/// index — home, chapters, search, kids, settings.
@MainActor
func goToSection(_ app: XCUIApplication, _ id: String) {
    let row = app.descendants(matching: .any)
        .matching(NSPredicate(format: "identifier == %@", "nav-\(id)"))
        .firstMatch
    if row.waitForExistence(timeout: 6) {
        row.tap()
        return
    }
    let order = ["home", "chapters", "search", "kids", "settings"]
    if let idx = order.firstIndex(of: id) {
        app.tabBars.buttons.element(boundBy: idx).tap()
    }
}

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

    /// Home renders after the live feed fetch. On a slow CI runner the first
    /// launch on a fresh simulator has taken ~55s, so allow 90s (as the tvOS
    /// tests do); a passing run returns as soon as Home appears.
    private let homeTimeout: TimeInterval = 90

    /// Horizontal middle of the screen. On a busy CI simulator the window
    /// snapshot can time out and report an unresolved (infinite) frame, so
    /// retry, then fall back to the app element's own frame.
    private func screenMidX(_ app: XCUIApplication) -> CGFloat {
        for _ in 0..<3 {
            let mid = app.windows.firstMatch.frame.midX
            if mid.isFinite { return mid }
            sleep(2)
        }
        return app.frame.midX
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

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: homeTimeout))
    }

    // MARK: RTL smoke — Arabic mirrors the layout

    func testArabicRTLLayout() throws {
        let app = XCUIApplication()
        launch(app, lang: "ar")
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: homeTimeout))

        let screenMid = screenMidX(app)
        XCTAssertTrue(screenMid.isFinite, "could not read the screen frame")
        let sidebar = el(app, "sidebar")
        if sidebar.waitForExistence(timeout: 8) {
            // In RTL the sidebar sits at the trailing (right) edge.
            XCTAssertGreaterThan(sidebar.frame.midX, screenMid,
                                 "RTL: sidebar should sit on the right half")
        } else {
            // Compact shell (iPhone): the tab bar mirrors — Home moves right.
            let firstTab = app.tabBars.buttons.element(boundBy: 0)
            XCTAssertTrue(firstTab.waitForExistence(timeout: 8))
            XCTAssertGreaterThan(firstTab.frame.midX, screenMid,
                                 "RTL: first tab should sit on the right half")
        }
    }

    // MARK: kids flow end-to-end

    func testKidsFlowEndToEnd() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: homeTimeout))
        goToSection(app, "kids")

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

        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: homeTimeout))
        goToSection(app, "search")

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
