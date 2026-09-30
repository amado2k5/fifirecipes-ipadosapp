import XCTest

/// Captures App Store / marketing screenshots and attaches them to the test
/// result so they can be exported from the .xcresult bundle:
///
///   xcodebuild test -only-testing:FifiRecipesPadUITests/ScreenshotTests \
///     -resultBundlePath shots.xcresult
///   xcrun xcresulttool export attachments --path shots.xcresult \
///     --output-path docs/screenshots
///
/// Output names match site/index.html: home-en, recipe-en, kids-en, home-ar,
/// recipe-xxxl (Dynamic Type proof).
@MainActor
final class ScreenshotTests: XCTestCase {

    private func snap(_ app: XCUIApplication, _ name: String) {
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

    func testCaptureScreenshots() throws {
        // — English home —
        let app = XCUIApplication()
        app.launchArguments = ["-fifi.language", "en"]
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
        sleep(3) // let the first images settle
        snap(app, "home-en")

        // — English recipe detail —
        let home = el(app, "homeScreen")
        let card = home.descendants(matching: .button).element(boundBy: 0)
        if card.waitForExistence(timeout: 15) {
            card.tap()
            if el(app, "recipeDetail").waitForExistence(timeout: 30) {
                sleep(2)
                snap(app, "recipe-en")
            }
            app.navigationBars.buttons.matching(NSPredicate(
                format: "NOT (label BEGINSWITH 'Hide Sidebar' OR label BEGINSWITH 'Show Sidebar')"
            )).firstMatch.tap() // back
            XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 15))
        }

        // — Kids —
        goToSection(app, "kids")
        XCTAssertTrue(el(app, "kidsScreen").waitForExistence(timeout: 30))
        sleep(2)
        snap(app, "kids-en")
    }

    func testCaptureRTL() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-fifi.language", "ar"]
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
        sleep(3)
        snap(app, "home-ar")
    }

    func testCaptureAccessibility3() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-fifi.language", "en", "-FifiSizeCategory", "AX3"]
        app.launch()
        XCTAssertTrue(el(app, "homeScreen").waitForExistence(timeout: 40))
        sleep(3)
        snap(app, "home-ax3")
    }
}
