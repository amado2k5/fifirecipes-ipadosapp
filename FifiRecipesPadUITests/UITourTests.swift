import XCTest

/// Manual-QA tour: navigates every screen in several languages and captures
/// named screenshots for visual review (overlap, clipping, contrast, RTL).
/// Run with:
///   xcodebuild test -only-testing:FifiRecipesPadUITests/UITourTests \
///     -resultBundlePath tour.xcresult
///   xcrun xcresulttool export attachments --path tour.xcresult \
///     --output-path /tmp/tour
@MainActor
final class UITourTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // iOS can overlay the app with "Enable Dictation?" (and similar)
        // system prompts after first-responder events; they live outside the
        // app hierarchy, so dismiss them via an interruption monitor.
        addUIInterruptionMonitor(withDescription: "System dialog") { alert in
            for label in ["Not Now", "Cancel", "Don't Enable", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    private func launch(_ app: XCUIApplication, lang: String, sizeCategory: String? = nil) {
        var args = ["-fifi.language", lang]
        if let sizeCategory { args += ["-FifiSizeCategory", sizeCategory] }
        app.launchArguments = args
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 45))
        dismissSystemDialogs(app)
        sleep(3)
    }

    private func openFirstRecipe(_ app: XCUIApplication) -> Bool {
        let home = el(app, "homeScreen")
        guard home.waitForExistence(timeout: 15) else { return false }
        // The hero can sit partially off-screen after rotation (its tap
        // doesn't activate), and cards carry .draggable — scroll to the top,
        // then tap the first fully-hittable card.
        home.swipeDown()
        sleep(1)
        let buttons = home.descendants(matching: .button)
        for idx in 0..<4 {
            let card = buttons.element(boundBy: idx)
            guard card.exists, card.isHittable else { continue }
            for _ in 0..<2 {
                card.tap()
                if el(app, "recipeDetail").waitForExistence(timeout: 15) {
                    sleep(2)
                    return true
                }
            }
        }
        return false
    }

    private func goBack(_ app: XCUIApplication) {
        // Two nav bars exist (sidebar + detail) — skip the split-view's
        // "Hide Sidebar" toggle and tap the pushed screen's back button.
        let buttons = app.navigationBars.buttons.matching(NSPredicate(
            format: "NOT (label BEGINSWITH 'Hide Sidebar' OR label BEGINSWITH 'Show Sidebar')"))
        buttons.firstMatch.tap()
    }

    /// Taps "Not Now"/"Cancel" on iOS system prompts (dictation, keyboards)
    /// that can overlay the app after typing into a search field.
    private func dismissSystemDialogs(_ app: XCUIApplication) {
        let labels = ["Not Now", "Continue", "Cancel", "Don't Enable", "OK"]
        for label in labels {
            let btn = app.buttons[label]
            if btn.exists { btn.tap(); return }
        }
        // Dictation/keyboard prompts are hosted by InputUI or SpringBoard,
        // outside the app under test's accessibility hierarchy.
        for host in ["com.apple.InputUI", "com.apple.springboard"] {
            let hostApp = XCUIApplication(bundleIdentifier: host)
            // Querying a process with no AX server (e.g. keyboard not up)
            // throws kAXErrorServerNotFound — skip unless it's running.
            guard hostApp.state == .runningForeground else { continue }
            for label in labels {
                let btn = hostApp.buttons[label]
                if btn.exists { btn.tap(); return }
            }
        }
        if app.alerts.firstMatch.exists {
            app.alerts.firstMatch.buttons["Not Now"].tap()
        }
    }

    // MARK: - English full tour

    func testEnglishTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")
        snap("tour-home-en-top")

        app.swipeUp(); sleep(1)
        snap("tour-home-en-mid")
        app.swipeUp(); sleep(1)
        snap("tour-home-en-bottom")

        // Recipe detail: top → ingredients → steps
        if openFirstRecipe(app) {
            snap("tour-recipe-en-top")
            app.swipeUp(); sleep(1)
            snap("tour-recipe-en-mid")
            app.swipeUp(); sleep(1)
            app.swipeUp(); sleep(1)
            snap("tour-recipe-en-bottom")
            goBack(app)
            XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 15))
        }

        // Chapters list + detail
        el(app, "nav-chapters").tap()
        XCTAssertTrue(el(app, "chaptersScreen").waitForExistence(timeout: 20))
        sleep(2)
        snap("tour-chapters-en")
        let ch = el(app, "chaptersScreen").descendants(matching: .button).element(boundBy: 0)
        if ch.waitForExistence(timeout: 10) {
            ch.tap()
            XCTAssertTrue(el(app, "chapterDetail").waitForExistence(timeout: 20))
            sleep(2)
            snap("tour-chapterdetail-en")
            goBack(app)
        }

        // Search
        el(app, "nav-search").tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap(); field.typeText("rice")
        sleep(3)
        dismissSystemDialogs(app)
        snap("tour-search-en")

        // Settings — dismiss keyboard/system dialog first so the nav tap lands
        dismissSystemDialogs(app)
        if app.keyboards.firstMatch.exists {
            field.typeText("\n") // submit — resigns first responder
            sleep(1)
        }
        if app.keyboards.firstMatch.exists {
            el(app, "searchScreen").swipeDown() // scrollDismissesKeyboard(.interactively)
            sleep(1)
        }
        dismissSystemDialogs(app)
        for _ in 0..<4 {
            el(app, "nav-settings").tap()
            if el(app, "settingsScreen").waitForExistence(timeout: 8) { break }
            dismissSystemDialogs(app)
        }
        XCTAssertTrue(el(app, "settingsScreen").waitForExistence(timeout: 20))
        sleep(1)
        snap("tour-settings-en")
    }

    // MARK: - Kids flow tour

    func testKidsTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")
        el(app, "nav-kids").tap()
        XCTAssertTrue(el(app, "kidsScreen").waitForExistence(timeout: 30))
        sleep(2)
        snap("tour-kids-top")
        app.swipeUp(); sleep(1)
        snap("tour-kids-bottom")

        let grid = el(app, "kidsScreen")
        let card = grid.descendants(matching: .button)
            .matching(NSPredicate(format: "NOT (identifier BEGINSWITH 'kidsFilter-')"))
            .element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.tap()
        XCTAssertTrue(el(app, "kidsReady").waitForExistence(timeout: 30))
        sleep(2)
        snap("tour-kidsready-top")
        app.swipeUp(); sleep(1)
        snap("tour-kidsready-bottom")

        let cook = app.buttons["kidsStartCooking"]
        XCTAssertTrue(cook.waitForExistence(timeout: 15))
        cook.tap()
        XCTAssertTrue(el(app, "kidsSteps").waitForExistence(timeout: 30))
        sleep(2)
        snap("tour-kidsstep1")

        let next = app.buttons["kidsStepNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.tap(); sleep(1)
        snap("tour-kidsstep2")
        for _ in 0..<25 where !el(app, "kidsDone").exists { next.tap(); usleep(400_000) }
        XCTAssertTrue(el(app, "kidsDone").waitForExistence(timeout: 10))
        sleep(2)
        snap("tour-kidsdone")
    }

    // MARK: - RTL tour (Arabic)

    func testArabicTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "ar")
        snap("tour-home-ar")
        app.swipeUp(); sleep(1)
        snap("tour-home-ar-mid")

        if openFirstRecipe(app) {
            snap("tour-recipe-ar-top")
            app.swipeUp(); sleep(1)
            snap("tour-recipe-ar-mid")
            goBack(app)
        }
        el(app, "nav-kids").tap() // Kids section
        XCTAssertTrue(el(app, "kidsScreen").waitForExistence(timeout: 30))
        sleep(2)
        snap("tour-kids-ar")
    }

    // MARK: - Script-specific font checks

    func testUrduTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "ur")
        snap("tour-home-ur") // Noto Nastaliq — tall glyphs, watch for clipping
        if openFirstRecipe(app) {
            snap("tour-recipe-ur")
            goBack(app)
        }
    }

    func testPersianTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "fa")
        snap("tour-home-fa")
    }

    func testHebrewTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "he")
        snap("tour-home-he")
    }

    func testJapaneseTour() throws {
        let app = XCUIApplication()
        launch(app, lang: "ja")
        snap("tour-home-ja")
    }

    // MARK: - Accessibility + orientation

    func testAccessibility3() throws {
        let app = XCUIApplication()
        launch(app, lang: "en", sizeCategory: "AX3")
        snap("tour-home-ax3")
        if openFirstRecipe(app) {
            snap("tour-recipe-ax3")
            app.swipeUp(); sleep(1)
            snap("tour-recipe-ax3-mid")
            goBack(app)
        }
        el(app, "nav-kids").tap()
        XCTAssertTrue(el(app, "kidsScreen").waitForExistence(timeout: 30))
        sleep(2)
        snap("tour-kids-ax3")
    }

    func testLandscape() throws {
        let app = XCUIApplication()
        launch(app, lang: "en")
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        snap("tour-home-landscape")
        XCTAssertTrue(openFirstRecipe(app))
        snap("tour-recipe-landscape")
        XCUIDevice.shared.orientation = .portrait
    }
}
