# Sunbreak Manual Testing Checklist

## Pre-Testing Setup

### Device Requirements
- [ ] iPhone with iOS 17.0+
- [ ] Physical device (Screen Time APIs don't work in simulator)
- [ ] TestFlight or development provisioning profile
- [ ] Family Controls entitlement approved by Apple

### Environment Setup
- [ ] Reset device Screen Time settings if needed
- [ ] Clear any existing Sunbreak data
- [ ] Enable location services for testing
- [ ] Ensure camera permissions can be granted

---

## 1. Initial Launch & Onboarding

### First Launch Experience
- [ ] App launches successfully
- [ ] Welcome screen appears with proper branding
- [ ] Progress indicator shows at top
- [ ] "Next" button is functional

### Step 1: Welcome Screen
- [ ] App icon displays correctly
- [ ] "Welcome to Sunbreak" title is visible
- [ ] Subtitle "Better mornings start with better nights" appears
- [ ] App description is readable and informative
- [ ] "Next" button advances to Screen Time authorization

### Step 2: Screen Time Authorization
- [ ] "Screen Time Access" title appears
- [ ] Explanation text is clear and accurate
- [ ] "Grant Access" button triggers system permission dialog
- [ ] Permission granted: Green checkmark and success message appear
- [ ] Permission denied: Error message explains impact, allows continuation
- [ ] "Next" button is enabled after handling permission

### Step 3: App Selection
- [ ] "Choose Apps to Limit" title appears
- [ ] "Select Apps" button opens FamilyActivityPicker
- [ ] Can select individual apps successfully
- [ ] Can select app categories successfully
- [ ] Can select web domains successfully
- [ ] Selected count updates correctly: "Apps Selected: X"
- [ ] Can proceed without selecting any apps
- [ ] "Next" button advances to schedule setup

### Step 4: Schedule Configuration
- [ ] "Set Your Schedule" title appears
- [ ] Bedtime picker defaults to 22:00 (10 PM)
- [ ] Wake time picker defaults to 07:00 (7 AM)
- [ ] Date pickers are functional and responsive
- [ ] Schedule summary calculates duration correctly
- [ ] Duration updates when times change
- [ ] "Next" button advances to location setup

### Step 5: Location Permission
- [ ] "Location for Sunrise" title appears
- [ ] Explanation mentions optional usage
- [ ] "Allow Location Access" triggers system permission
- [ ] Permission granted: Success message appears
- [ ] Permission denied: Can still continue with "Skip for Now"
- [ ] "Get Started" button completes onboarding

### Onboarding Completion
- [ ] Main app interface loads
- [ ] Tab bar appears with all 4 tabs
- [ ] User preferences are saved
- [ ] Selected apps are persisted
- [ ] Schedule is configured correctly

---

## 2. Main App Interface

### Tab Bar Navigation
- [ ] All 4 tabs are visible: Home, Schedule, Apps, Settings
- [ ] Tab icons are clear and appropriate
- [ ] Tapping each tab navigates correctly
- [ ] Tab selection state is maintained
- [ ] Accessibility labels are present for VoiceOver

### Home Tab
- [ ] "Sunbreak" navigation title appears
- [ ] Current status card displays appropriate state
- [ ] Status icon matches current mode (sun/moon)
- [ ] Status text is accurate for current time
- [ ] Quick stats section shows placeholder data
- [ ] UI adapts for different states (bedtime/day/unlocked)

### Schedule Tab
- [ ] "Schedule" navigation title appears
- [ ] Current bedtime displays correctly
- [ ] Current wake time displays correctly
- [ ] Time pickers are functional
- [ ] Schedule summary updates with changes
- [ ] "Save Changes" button appears when modified
- [ ] Changes persist after saving

### Apps Tab
- [ ] "Restricted Apps" navigation title appears
- [ ] "+" button in top right for adding apps
- [ ] Empty state shows when no apps selected
- [ ] "Select Apps" button opens FamilyActivityPicker
- [ ] Selected apps display in organized sections
- [ ] Apps count displays correctly
- [ ] Can modify selection and changes persist

### Settings Tab
- [ ] "Settings" navigation title appears
- [ ] All sections are visible: Subscription, Preferences, Permissions, About
- [ ] Toggle switches work correctly
- [ ] Permission status displays accurately
- [ ] All buttons navigate to appropriate screens

---

## 3. Core Functionality Testing

### Screen Time Integration
- [ ] Apps are restricted during bedtime window
- [ ] Shield appears when trying to open restricted apps
- [ ] Custom shield message displays correctly
- [ ] Shield UI matches app branding
- [ ] "Unlock with Daylight" button appears on shield
- [ ] Shield disappears when apps are unlocked

### Bedtime Mode Activation
**Setup:** Set bedtime to current time + 2 minutes
- [ ] Apps become restricted at designated bedtime
- [ ] Home screen shows "Bedtime Mode Active"
- [ ] Restricted apps show shields when launched
- [ ] Non-restricted apps remain accessible
- [ ] Status persists across app launches

### Daylight Verification Flow
**Prerequisites:** Must be after sunrise time
- [ ] "Start Day with Daylight" button appears during bedtime
- [ ] Tapping button opens camera verification flow
- [ ] Camera preview displays correctly
- [ ] Liveness indicator shows random angle prompt
- [ ] "Capture Daylight" button is functional

#### Successful Daylight Verification
- [ ] Bright outdoor photo with sky passes verification
- [ ] "Day Started!" success screen appears
- [ ] Apps are unlocked immediately
- [ ] Home screen shows "Apps Unlocked for Today"
- [ ] Shields are removed from restricted apps
- [ ] Unlock state persists until next bedtime

#### Failed Daylight Verification
- [ ] Dark indoor photo fails verification
- [ ] Photo without sky fails verification
- [ ] "Verification Failed" screen shows helpful tips
- [ ] Failure reason is specific and actionable
- [ ] "Try Again" button allows retry
- [ ] Apps remain restricted after failure

### Before Sunrise Testing
**Setup:** Set device time before sunrise OR test early in morning
- [ ] Unlock attempt shows "Too early" message
- [ ] Camera verification is blocked before sunrise
- [ ] Error message mentions waiting for sunrise
- [ ] Apps remain restricted regardless of photo quality

### Unlock Persistence
- [ ] Unlock status persists across app restarts
- [ ] Unlock status persists across device restarts
- [ ] Unlock expires at next bedtime boundary
- [ ] New bedtime cycle requires new verification

---

## 4. Subscription & Monetization

### Paywall Presentation
- [ ] "View Plans" button opens paywall
- [ ] Paywall displays both monthly and annual options
- [ ] Free trial information is prominent
- [ ] Product prices display correctly
- [ ] Feature list is compelling and accurate
- [ ] "Close" button dismisses paywall

### Purchase Flow (Sandbox Testing)
- [ ] Product selection updates UI correctly
- [ ] "Start 14-Day Free Trial" button is clear
- [ ] Purchase triggers StoreKit flow
- [ ] Successful purchase updates subscription status
- [ ] Failed purchase shows appropriate error
- [ ] "Restore Purchases" works correctly

### Trial & Subscription Status
- [ ] Free trial countdown displays correctly
- [ ] Active subscription shows "Active" status
- [ ] Expired subscription shows appropriate message
- [ ] Subscription status persists across launches

---

## 5. Settings & Configuration

### Preferences Management
- [ ] Notification toggle saves state correctly
- [ ] Haptic feedback toggle works immediately
- [ ] Settings persist across app launches

### Permission Status Display
- [ ] Screen Time permission status is accurate
- [ ] Camera permission reflects actual state
- [ ] Location permission shows correct status

### About & Support
- [ ] About screen shows app version
- [ ] App description is informative
- [ ] Privacy policy opens correctly
- [ ] Contact support opens email client

### Data Management
- [ ] "Reset All Settings" shows confirmation dialog
- [ ] Confirming reset clears all user data
- [ ] Reset triggers fresh onboarding experience
- [ ] Screen Time authorization is properly revoked

---

## 6. Edge Cases & Error Handling

### Permission Revocation
- [ ] Revoking Screen Time permission shows error state
- [ ] App gracefully handles permission loss
- [ ] Re-authorization flow works correctly
- [ ] Shields are cleared when permission lost

### Network Connectivity
- [ ] App works completely offline
- [ ] No network calls required for core functionality
- [ ] Subscription checks handle offline gracefully

### Memory & Performance
- [ ] App launches quickly (< 3 seconds)
- [ ] Camera preview is smooth
- [ ] No memory leaks during extended use
- [ ] Battery impact is minimal during normal use

### Time Zone Changes
- [ ] Sunrise/sunset times update with location changes
- [ ] Schedule works correctly across time zones
- [ ] Daylight verification adapts to new location

### Storage Issues
- [ ] App handles low storage gracefully
- [ ] SwiftData operations don't crash
- [ ] Corruption recovery works properly

---

## 7. Accessibility Testing

### VoiceOver Support
- [ ] All interactive elements have accessibility labels
- [ ] Navigation is logical with VoiceOver
- [ ] Tab bar announces correctly
- [ ] Form controls are properly labeled

### Dynamic Type
- [ ] Text scales correctly with system font size
- [ ] UI remains usable at largest text sizes
- [ ] Icons and buttons scale appropriately

### Color & Contrast
- [ ] App is usable with high contrast enabled
- [ ] Color is not the only way to convey information
- [ ] Dark mode support works correctly

### Motor Accessibility
- [ ] App works with Switch Control
- [ ] Tap targets are minimum 44pt
- [ ] Gestures have alternatives

---

## 8. Device Compatibility

### iPhone Models
- [ ] iPhone 15/15 Pro (latest)
- [ ] iPhone 14/14 Pro
- [ ] iPhone 13/13 Pro  
- [ ] iPhone 12/12 Pro
- [ ] iPhone 11/11 Pro
- [ ] iPhone XS/XR (minimum supported)

### iOS Versions
- [ ] iOS 17.4 (latest)
- [ ] iOS 17.0 (minimum)

### Regional Testing
- [ ] 12-hour time format (US)
- [ ] 24-hour time format (International)
- [ ] Different date formats
- [ ] Various language settings

---

## 9. Regression Testing

### After Code Changes
- [ ] Full onboarding flow still works
- [ ] Core unlock functionality works
- [ ] All navigation remains functional
- [ ] Subscription flow works
- [ ] Data persistence works correctly

### Before App Store Submission
- [ ] App builds and runs on multiple devices
- [ ] No crashes in critical flows
- [ ] All test cases pass
- [ ] Performance is acceptable
- [ ] Privacy policy is up to date

---

## 10. App Store Review Preparation

### Demo Scenarios
- [ ] Complete new user onboarding
- [ ] Show bedtime restriction in action
- [ ] Demonstrate daylight unlock process
- [ ] Show subscription purchase flow
- [ ] Demonstrate app's privacy approach

### Review Requirements
- [ ] Screen Time usage is clearly explained
- [ ] Privacy policy covers all data usage
- [ ] App functionality works as described
- [ ] No crashes or major bugs
- [ ] Family Controls entitlement justified

---

## Testing Notes Template

### Test Session Information
- **Date:** ___________
- **Tester:** ___________
- **Device:** ___________
- **iOS Version:** ___________
- **App Version:** ___________
- **Build Number:** ___________

### Issues Found
| Priority | Component | Description | Steps to Reproduce | Status |
|----------|-----------|-------------|-------------------|--------|
| High/Med/Low | Feature | Bug description | 1. Step one<br>2. Step two | Open/Fixed |

### Test Results Summary
- **Total Tests:** ___________
- **Passed:** ___________
- **Failed:** ___________
- **Blocked:** ___________
- **Overall Status:** Pass/Fail/Blocked

---

## Quick Smoke Test (Daily Testing)

For quick daily verification:

1. **Launch & Navigation (2 mins)**
   - [ ] App launches without crash
   - [ ] All tabs navigate correctly
   - [ ] Basic UI elements render properly

2. **Core Functionality (5 mins)**
   - [ ] Bedtime mode activates correctly
   - [ ] Shields appear on restricted apps
   - [ ] Daylight verification opens
   - [ ] Unlock process works

3. **Settings & Data (2 mins)**
   - [ ] Settings save correctly
   - [ ] Schedule changes persist
   - [ ] App selection works

**Total Time: ~10 minutes**

---

*This checklist should be updated as features are added or modified. Each major release should go through the complete checklist.*