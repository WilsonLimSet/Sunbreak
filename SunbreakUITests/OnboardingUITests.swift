import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Reset app state for testing
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testCompleteOnboardingFlow() throws {
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Sunbreak"].exists)
        XCTAssertTrue(app.staticTexts["Better mornings start with better nights"].exists)
        
        // Tap Next
        app.buttons["Next"].tap()
        
        // Screen Time Authorization screen
        XCTAssertTrue(app.staticTexts["Screen Time Access"].exists)
        
        // Note: In UI tests, we can't actually grant Screen Time permission
        // We'll mock this step or skip it for UI testing
        app.buttons["Next"].tap()
        
        // App Selection screen
        XCTAssertTrue(app.staticTexts["Choose Apps to Limit"].exists)
        XCTAssertTrue(app.buttons["Select Apps"].exists)
        
        app.buttons["Next"].tap()
        
        // Schedule screen
        XCTAssertTrue(app.staticTexts["Set Your Schedule"].exists)
        XCTAssertTrue(app.staticTexts["Bedtime"].exists)
        XCTAssertTrue(app.staticTexts["Wake Time"].exists)
        
        // Interact with time pickers
        let bedtimePicker = app.datePickers.firstMatch
        XCTAssertTrue(bedtimePicker.exists)
        
        app.buttons["Next"].tap()
        
        // Location screen
        XCTAssertTrue(app.staticTexts["Location for Sunrise"].exists)
        
        // Skip location for testing
        app.buttons["Skip for Now"].tap()
        
        // Final step
        app.buttons["Get Started"].tap()
        
        // Should now be in main app
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.buttons["Home"].exists)
    }
    
    func testOnboardingNavigation() throws {
        // Test back navigation
        app.buttons["Next"].tap() // Go to step 2
        
        XCTAssertTrue(app.buttons["Back"].exists)
        app.buttons["Back"].tap()
        
        // Should be back at welcome
        XCTAssertTrue(app.staticTexts["Welcome to Sunbreak"].exists)
    }
    
    func testOnboardingProgressIndicator() throws {
        // Check initial progress
        let progressBar = app.progressIndicators.firstMatch
        XCTAssertTrue(progressBar.exists)
        
        // Progress should increase as we move through steps
        let initialProgress = progressBar.value as? String ?? "0%"
        
        app.buttons["Next"].tap()
        
        let secondProgress = progressBar.value as? String ?? "0%"
        // Progress should have increased (exact values may vary)
        XCTAssertNotEqual(initialProgress, secondProgress)
    }
    
    func testScheduleTimePickers() throws {
        // Navigate to schedule screen
        app.buttons["Next"].tap() // Welcome -> Auth
        app.buttons["Next"].tap() // Auth -> Apps
        app.buttons["Next"].tap() // Apps -> Schedule
        
        XCTAssertTrue(app.staticTexts["Set Your Schedule"].exists)
        
        // Test bedtime picker
        let bedtimePicker = app.datePickers.element(boundBy: 0)
        XCTAssertTrue(bedtimePicker.exists)
        
        // Test wake time picker
        let waketimePicker = app.datePickers.element(boundBy: 1)
        XCTAssertTrue(waketimePicker.exists)
        
        // Test that we can interact with the pickers
        bedtimePicker.tap()
        // In a real app, you might adjust the picker values here
    }
    
    func testAppSelectionFlow() throws {
        // Navigate to app selection
        app.buttons["Next"].tap() // Welcome -> Auth
        app.buttons["Next"].tap() // Auth -> Apps
        
        XCTAssertTrue(app.staticTexts["Choose Apps to Limit"].exists)
        
        // Test select apps button
        let selectAppsButton = app.buttons["Select Apps"]
        XCTAssertTrue(selectAppsButton.exists)
        
        // Note: FamilyActivityPicker is a system component that can't be easily tested in UI tests
        // In a real test, you might mock this or test the state after selection
    }
}

final class MainAppUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch with completed onboarding
        app.launchArguments = ["--uitesting", "--onboarding-completed"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Test each tab
        let tabs = ["Home", "Schedule", "Apps", "Settings"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            XCTAssertTrue(tabButton.exists, "Tab \(tab) should exist")
            
            tabButton.tap()
            
            // Verify we're on the correct tab by checking for tab-specific content
            switch tab {
            case "Home":
                XCTAssertTrue(app.navigationBars["Sunbreak"].exists)
            case "Schedule":
                XCTAssertTrue(app.navigationBars["Schedule"].exists)
            case "Apps":
                XCTAssertTrue(app.navigationBars["Restricted Apps"].exists)
            case "Settings":
                XCTAssertTrue(app.navigationBars["Settings"].exists)
            default:
                break
            }
        }
    }
    
    func testHomeScreenElements() throws {
        // Should start on home tab
        let homeTab = app.tabBars.firstMatch.buttons["Home"]
        homeTab.tap()
        
        // Check for key home screen elements
        XCTAssertTrue(app.navigationBars["Sunbreak"].exists)
        
        // Look for status indicators (these may vary based on app state)
        let statusElements = ["Day Mode", "Bedtime Mode Active", "Day Started"]
        let hasStatusElement = statusElements.contains { element in
            app.staticTexts[element].exists
        }
        XCTAssertTrue(hasStatusElement, "Should display some status")
        
        // Check for unlock button or status
        let unlockElements = ["Start Day with Daylight", "Apps Unlocked for Today"]
        let hasUnlockElement = unlockElements.contains { element in
            app.buttons[element].exists || app.staticTexts[element].exists
        }
        XCTAssertTrue(hasUnlockElement, "Should show unlock status or button")
    }
    
    func testScheduleScreenFunctionality() throws {
        app.tabBars.firstMatch.buttons["Schedule"].tap()
        
        XCTAssertTrue(app.navigationBars["Schedule"].exists)
        
        // Check for time pickers
        XCTAssertTrue(app.staticTexts["Bedtime"].exists)
        XCTAssertTrue(app.staticTexts["Wake Time"].exists)
        
        // Look for date pickers
        let datePickers = app.datePickers
        XCTAssertGreaterThanOrEqual(datePickers.count, 2, "Should have bedtime and wake time pickers")
        
        // Test interaction with first picker
        let firstPicker = datePickers.firstMatch
        XCTAssertTrue(firstPicker.exists)
        firstPicker.tap()
        
        // After changing time, save button should appear
        // Note: This might require actual time changes to trigger
    }
    
    func testAppsSelectionScreen() throws {
        app.tabBars.firstMatch.buttons["Apps"].tap()
        
        XCTAssertTrue(app.navigationBars["Restricted Apps"].exists)
        
        // Should have a plus button to add apps
        XCTAssertTrue(app.navigationBars.firstMatch.buttons["+"].exists)
        
        // Content will vary based on whether apps are selected
        let possibleStates = [
            app.staticTexts["No Apps Selected"].exists,
            app.staticTexts["Apps"].exists // Section header when apps are selected
        ]
        
        XCTAssertTrue(possibleStates.contains(true), "Should show either empty state or selected apps")
    }
    
    func testSettingsScreen() throws {
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Check for main settings sections
        XCTAssertTrue(app.staticTexts["Subscription"].exists)
        XCTAssertTrue(app.staticTexts["Preferences"].exists)
        XCTAssertTrue(app.staticTexts["Permissions"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
        
        // Test subscription section
        XCTAssertTrue(app.staticTexts["Status"].exists)
        XCTAssertTrue(app.buttons["View Plans"].exists)
        
        // Test toggles in preferences
        let notificationToggle = app.switches["Notifications"]
        let hapticToggle = app.switches["Haptic Feedback"]
        
        if notificationToggle.exists {
            let initialState = notificationToggle.value as? String
            notificationToggle.tap()
            let newState = notificationToggle.value as? String
            XCTAssertNotEqual(initialState, newState, "Toggle should change state")
        }
    }
    
    // MARK: - Modal Presentation Tests
    
    func testPaywallPresentation() throws {
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        let viewPlansButton = app.buttons["View Plans"]
        XCTAssertTrue(viewPlansButton.exists)
        
        viewPlansButton.tap()
        
        // Check for paywall elements
        XCTAssertTrue(app.staticTexts["Unlock Sunbreak Premium"].exists)
        XCTAssertTrue(app.buttons["Close"].exists)
        
        // Close the modal
        app.buttons["Close"].tap()
        
        // Should be back to settings
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
    
    func testAboutScreenPresentation() throws {
        app.tabBars.firstMatch.buttons["Settings"].tap()
        
        let aboutButton = app.buttons["About Sunbreak"]
        XCTAssertTrue(aboutButton.exists)
        
        aboutButton.tap()
        
        // Check for about screen elements
        XCTAssertTrue(app.navigationBars["About"].exists)
        XCTAssertTrue(app.staticTexts["Sunbreak"].exists)
        XCTAssertTrue(app.buttons["Done"].exists)
        
        // Close the modal
        app.buttons["Done"].tap()
        
        // Should be back to settings
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Check that key elements have accessibility labels
        let homeTab = app.tabBars.firstMatch.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        XCTAssertNotNil(homeTab.label)
        
        // Navigate through tabs and check accessibility
        let tabs = ["Home", "Schedule", "Apps", "Settings"]
        
        for tab in tabs {
            let tabButton = app.tabBars.firstMatch.buttons[tab]
            XCTAssertTrue(tabButton.isAccessibilityElement, "\(tab) tab should be accessible")
            XCTAssertFalse(tabButton.label.isEmpty, "\(tab) tab should have a label")
        }
    }
    
    func testVoiceOverSupport() throws {
        // Enable VoiceOver for testing
        // Note: This requires special test setup and may not work in all environments
        
        app.tabBars.firstMatch.buttons["Home"].tap()
        
        // Check that main elements are accessible
        let mainElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        
        for element in mainElements {
            if element.exists && element.isAccessibilityElement {
                XCTAssertFalse(element.label.isEmpty, "Accessible element should have a label")
            }
        }
    }
}