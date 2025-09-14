# Sunbreak Testing Guide

## Overview

This guide provides comprehensive instructions for testing the Sunbreak iOS app. The testing suite includes unit tests, UI tests, integration tests, performance tests, and manual testing procedures.

---

## Testing Architecture

### Test Targets
- **SunbreakTests**: Unit tests and integration tests
- **SunbreakUITests**: User interface automation tests
- **Manual Testing**: Comprehensive manual test checklists

### Test Structure
```
SunbreakTests/
├── ScheduleManagerTests.swift          # Core scheduling logic
├── DaylightVerificationTests.swift     # Camera and daylight detection
├── SubscriptionManagerTests.swift      # StoreKit integration
├── SwiftDataModelTests.swift          # Data persistence
├── ScreenTimeIntegrationTests.swift   # Screen Time API integration
├── PerformanceTests.swift             # Performance benchmarks
├── EdgeCaseTests.swift                # Edge cases and error handling
└── TestUtilities.swift                # Shared test utilities and mocks

SunbreakUITests/
└── OnboardingUITests.swift            # UI automation tests

Manual Testing/
└── MANUAL_TESTING_CHECKLIST.md        # Comprehensive manual test procedures
```

---

## Running Tests

### Prerequisites

#### Device Requirements
- Physical iPhone (iOS 17.0+) - **Required for Screen Time API tests**
- Simulator support for unit tests only
- TestFlight or development build

#### Permissions Setup
- Family Controls entitlement approved by Apple
- Screen Time permission granted (for integration tests)
- Camera permission available (for daylight verification tests)

### Running Unit Tests

#### From Xcode
1. Open `Sunbreak.xcodeproj`
2. Select the `SunbreakTests` scheme
3. Press `Cmd+U` to run all unit tests
4. View results in the Test Navigator

#### From Command Line
```bash
# Run all unit tests
xcodebuild test -project Sunbreak.xcodeproj -scheme SunbreakTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project Sunbreak.xcodeproj -scheme SunbreakTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SunbreakTests/ScheduleManagerTests

# Run specific test method
xcodebuild test -project Sunbreak.xcodeproj -scheme SunbreakTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SunbreakTests/ScheduleManagerTests/testBedtimeWindowCalculation
```

### Running UI Tests

#### Prerequisites
- Physical device recommended (Screen Time features require it)
- App installed on device with proper entitlements

#### From Xcode
1. Select the `SunbreakUITests` scheme
2. Press `Cmd+U` to run UI tests
3. Watch the automated interactions on device/simulator

#### From Command Line
```bash
# Run all UI tests on device
xcodebuild test -project Sunbreak.xcodeproj -scheme SunbreakUITests -destination 'platform=iOS,name=Your iPhone'
```

### Running Performance Tests

Performance tests are part of the main test suite but can be run separately:

```bash
# Run only performance tests
xcodebuild test -project Sunbreak.xcodeproj -scheme SunbreakTests -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SunbreakTests/PerformanceTests
```

---

## Test Categories

### 1. Unit Tests

#### Core Business Logic (`ScheduleManagerTests.swift`)
- ✅ Bedtime window calculations
- ✅ Day unlock persistence
- ✅ Schedule setup and validation
- ✅ State transitions

**Key Test Cases:**
```swift
func testBedtimeWindowCalculation()     // Tests 10PM-7AM schedule logic
func testDayUnlockPersistence()         // Tests unlock state saving
func testDayUnlockExpiry()              // Tests unlock expiration
```

#### Daylight Verification (`DaylightVerificationTests.swift`)
- ✅ Sunrise time validation
- ✅ Image brightness analysis
- ✅ Blue sky detection algorithms
- ✅ Confidence scoring

**Key Test Cases:**
```swift
func testSunriseTimeValidation()        // Before/after sunrise logic
func testBrightnessCalculation()        // Image brightness analysis
func testBlueSkyDetection()             // Sky detection algorithm
```

#### Data Models (`SwiftDataModelTests.swift`)
- ✅ Model creation and defaults
- ✅ Data persistence and fetching
- ✅ Model relationships
- ✅ Data validation

#### Subscription Management (`SubscriptionManagerTests.swift`)
- ✅ Product loading
- ✅ Purchase flow simulation
- ✅ Subscription status tracking
- ✅ Trial eligibility

### 2. Integration Tests

#### Screen Time API Integration (`ScreenTimeIntegrationTests.swift`)
- ✅ Authorization flow testing
- ✅ Family Activity Selection serialization
- ✅ Managed Settings Store operations
- ✅ Device Activity monitoring
- ✅ App Group data sharing

**Important Notes:**
- Requires physical device
- Requires Screen Time permission
- Some tests require manual user interaction

### 3. UI Tests

#### Onboarding Flow (`OnboardingUITests.swift`)
- ✅ Complete onboarding process
- ✅ Navigation between steps
- ✅ Form interactions
- ✅ Permission flows

#### Main App UI (`MainAppUITests.swift`)
- ✅ Tab navigation
- ✅ Screen content verification
- ✅ Modal presentations
- ✅ Accessibility features

### 4. Performance Tests

#### Benchmarks (`PerformanceTests.swift`)
- ✅ App launch performance
- ✅ Image processing speed
- ✅ Data operation performance
- ✅ Memory usage tracking

**Performance Targets:**
- App launch: < 3 seconds
- Image analysis: < 2 seconds
- Data queries: < 100ms
- Memory usage: < 50MB baseline

### 5. Edge Case Tests

#### Robustness (`EdgeCaseTests.swift`)
- ✅ Time zone changes
- ✅ Data corruption handling
- ✅ Memory pressure scenarios
- ✅ Permission revocation
- ✅ Extreme values

---

## Test Data and Mocks

### Test Utilities (`TestUtilities.swift`)

#### Data Factories
```swift
TestDataFactory.createUserPreferences()    // Creates test preferences
TestDataFactory.createSelectionRecord()    // Creates test app selection
TestDataFactory.createDaylightImage()      // Creates bright test image
TestDataFactory.createDarkImage()          // Creates dark test image
```

#### Test Helpers
```swift
TestHelpers.clearAppGroupDefaults()        // Cleans shared data
TestHelpers.setUnlockDate()               // Sets test unlock state
TestHelpers.createInMemoryContainer()      // SwiftData test container
```

#### Mock Objects
- `MockScreenTimeAuthManager`: Simulates Screen Time authorization
- `MockSubscriptionManager`: Simulates StoreKit operations
- `MockDaylightVerificationManager`: Simulates camera verification

### Using Mocks in Tests

```swift
func testWithMockAuth() {
    let mockAuth = MockScreenTimeAuthManager()
    mockAuth.setMockAuthorizationResult(true)
    
    // Test authorized state
    XCTAssertTrue(mockAuth.isAuthorized)
}
```

---

## Test Configuration

### Environment Variables

Set these in your test scheme for specific behaviors:

```
--uitesting                    # Enables UI testing mode
--reset-onboarding            # Resets onboarding state
--onboarding-completed        # Skips onboarding
--mock-subscription-active    # Enables premium features
```

### Test Scheme Configuration

In Xcode scheme editor:
1. **Test tab** → **Arguments** → **Environment Variables**
2. Add variables as needed for different test scenarios

### Device Setup for Testing

#### For Screen Time API Tests:
1. Reset Screen Time settings: Settings → Screen Time → Turn Off → Turn On
2. Ensure no existing restrictions conflict with tests
3. Grant Screen Time permission to app during test

#### For Camera Tests:
1. Ensure camera permission can be granted
2. Test in various lighting conditions
3. Have both indoor and outdoor photos available

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project Sunbreak.xcodeproj \
            -scheme SunbreakTests \
            -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Reporting

Tests generate standard Xcode test reports. For CI/CD:

```bash
# Generate test report
xcodebuild test \
  -project Sunbreak.xcodeproj \
  -scheme SunbreakTests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -resultBundlePath TestResults.xcresult

# Convert to JUnit format (if needed)
xcparse --output-format junit TestResults.xcresult output.xml
```

---

## Manual Testing

### When to Perform Manual Testing

1. **Before major releases**
2. **After significant feature changes**
3. **When automated tests can't cover the scenario**
4. **For App Store submission preparation**

### Manual Testing Process

1. **Review the checklist**: `MANUAL_TESTING_CHECKLIST.md`
2. **Set up test environment**: Clean device, proper permissions
3. **Execute test scenarios**: Follow checklist step-by-step
4. **Document findings**: Record bugs and issues
5. **Verify fixes**: Re-test after bug fixes

### Critical Manual Test Scenarios

1. **Complete new user flow**: Fresh install through first unlock
2. **Permission handling**: Grant/deny various permissions
3. **Bedtime activation**: Real-time shield activation
4. **Daylight verification**: Actual camera usage in various conditions
5. **Subscription flow**: Real StoreKit purchase (in sandbox)

---

## Debugging Tests

### Common Issues and Solutions

#### Screen Time Permission Issues
```
Error: "Screen Time authorization denied"
Solution: Ensure app has Family Controls entitlement and user grants permission
```

#### SwiftData Context Issues
```
Error: "No persistent stores found"
Solution: Use in-memory store for tests: TestHelpers.createInMemoryContainer()
```

#### Image Processing Failures
```
Error: "Failed to process image"
Solution: Use TestDataFactory.createTestImage() for consistent test images
```

### Debug Test Execution

```swift
// Add debug prints in tests
func testSomething() {
    print("Test starting with data: \(testData)")
    // Test logic here
    print("Test completed with result: \(result)")
}

// Use breakpoints for step-by-step debugging
func testComplexFlow() {
    let step1 = performStep1() // Set breakpoint here
    let step2 = performStep2(step1) // And here
    XCTAssertTrue(step2.isValid)
}
```

### Test Performance Debugging

```swift
// Measure specific operations
func testSlowOperation() {
    measure {
        performExpensiveOperation()
    }
}

// Profile memory usage
func testMemoryUsage() {
    measureMetrics([.wallClockTime, .peakMemoryUsage]) {
        createManyObjects()
    }
}
```

---

## Best Practices

### Writing Good Tests

1. **Clear Test Names**: Use descriptive names that explain what's being tested
   ```swift
   func testBedtimeWindowCalculationWithMidnightCrossover() // Good
   func testSchedule() // Bad
   ```

2. **Arrange-Act-Assert Pattern**:
   ```swift
   func testExample() {
       // Arrange
       let input = createTestInput()
       let sut = SystemUnderTest()
       
       // Act
       let result = sut.process(input)
       
       // Assert
       XCTAssertEqual(result.value, expectedValue)
   }
   ```

3. **Independent Tests**: Each test should be able to run alone
4. **Cleanup**: Use setUp/tearDown to ensure clean state
5. **Mock External Dependencies**: Don't rely on network, file system, etc.

### Test Maintenance

1. **Update tests with feature changes**
2. **Remove obsolete tests**
3. **Keep test data realistic but minimal**
4. **Review test coverage regularly**

### Performance Testing Guidelines

1. **Set baseline performance targets**
2. **Test on representative devices**
3. **Monitor memory usage and leaks**
4. **Profile in release configuration**

---

## Troubleshooting

### Test Failures

#### Flaky Tests
- Add proper wait conditions for async operations
- Use expectations for async testing
- Ensure proper test isolation

#### Device-Specific Issues
- Test on multiple device models
- Account for different screen sizes
- Consider device capabilities (camera quality, etc.)

#### Permission-Related Failures
- Reset device permissions between test runs
- Use mock objects when permissions can't be reliably granted
- Document manual permission setup steps

### Getting Help

1. **Check test logs**: Look for specific error messages
2. **Review documentation**: Ensure proper test setup
3. **Run tests individually**: Isolate failing tests
4. **Check device state**: Ensure clean test environment

---

## Test Coverage

### Current Coverage Targets

- **Unit Tests**: > 80% code coverage
- **Critical Paths**: 100% coverage (onboarding, unlock flow)
- **Edge Cases**: All identified edge cases tested
- **Performance**: All critical operations benchmarked

### Measuring Coverage

In Xcode:
1. Edit scheme → Test tab
2. Check "Code Coverage" checkbox
3. Run tests
4. View coverage in Report Navigator

From command line:
```bash
xcodebuild test \
  -project Sunbreak.xcodeproj \
  -scheme SunbreakTests \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

---

## Release Testing Checklist

Before each App Store release:

- [ ] All automated tests pass
- [ ] Manual testing checklist completed
- [ ] Performance benchmarks meet targets
- [ ] Edge cases validated
- [ ] Accessibility features tested
- [ ] Multiple device types tested
- [ ] Both new and upgrade scenarios tested
- [ ] Subscription flow verified in sandbox
- [ ] Privacy policy compliance verified

---

*This testing guide should be updated as new features are added and testing processes evolve.*