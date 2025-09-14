# Sunbreak - iOS App

A mindful app that helps you build healthier sleep habits by restricting selected apps during bedtime and encouraging you to start your day with natural daylight.

## Features

- 🌙 **Smart Bedtime Mode**: Automatically restrict distracting apps during your sleep schedule
- ☀️ **Daylight Verification**: Start your day by capturing natural light with your camera
- 📱 **App Selection**: Choose exactly which apps to restrict during bedtime
- ⏰ **Custom Schedule**: Set your own bedtime and wake time
- 🔒 **Privacy First**: All data stays on your device - we never see your Screen Time data
- 💰 **14-Day Free Trial**: Try all features before subscribing

## Requirements

- iOS 17.0+
- Xcode 15.0+
- iPhone (required for Screen Time APIs)
- Camera access (for daylight verification)
- Screen Time permission (for app restrictions)

## Architecture

The app is built using:
- SwiftUI for the user interface
- SwiftData for local persistence
- FamilyControls framework for Screen Time integration
- DeviceActivity framework for monitoring and shields
- AVFoundation for camera functionality
- StoreKit 2 for subscriptions
- CoreLocation for sunrise/sunset calculations

## Project Structure

```
Sunbreak/
├── Sunbreak/                    # Main app target
│   ├── Views/                   # SwiftUI views
│   ├── Services/                # Business logic
│   └── SunbreakApp.swift       # App entry point
├── SunbreakMonitor/            # DeviceActivityMonitor extension
├── Shared/                     # Shared code and models
│   └── Models/                 # SwiftData models
└── SUNBREAK_SPEC.md           # Technical specification
```

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/WilsonLimSet/SunBreak.git
   cd SunBreak
   ```

2. **Open in Xcode**
   ```bash
   open Sunbreak.xcodeproj
   ```

3. **Configure App Groups**
   - In Xcode, select your main app target
   - Go to Signing & Capabilities
   - Add App Groups capability
   - Create/use group: `group.com.sunbreak.shared`
   - Repeat for the DeviceActivityMonitor extension

4. **Configure Family Controls Entitlement**
   - Request Family Controls entitlement from Apple Developer portal
   - Add `com.apple.developer.family-controls` to both targets
   - This requires approval from Apple for App Store distribution

5. **Set up Bundle Identifiers**
   - Main app: `com.yourteam.sunbreak`
   - Monitor extension: `com.yourteam.sunbreak.monitor`

6. **Configure StoreKit Products**
   - Create subscription products in App Store Connect:
     - `com.sunbreak.monthly` (Monthly subscription with 14-day trial)
     - `com.sunbreak.annual` (Annual subscription with 14-day trial)

7. **Build and Run**
   - Select your target device (must be physical iPhone for Screen Time APIs)
   - Build and run the project

## Testing

The app requires testing on a physical device since the Screen Time APIs don't work in the simulator.

### Test Scenarios

1. **Onboarding Flow**
   - Complete all onboarding steps
   - Grant Screen Time permission
   - Select apps to restrict
   - Set bedtime schedule

2. **Bedtime Mode**
   - Wait for or manually trigger bedtime
   - Try to open restricted apps
   - Verify shield appears with custom message

3. **Daylight Unlock**
   - Attempt unlock before sunrise (should fail)
   - Attempt unlock after sunrise with good lighting (should succeed)
   - Verify apps remain unlocked until next bedtime

4. **Subscription Flow**
   - Test paywall presentation
   - Test free trial eligibility
   - Test purchase flow (use Sandbox)

## Deployment

1. **App Store Review**
   - Family Controls entitlement requires approval
   - Provide clear explanation of app functionality
   - Include demo video showing daylight verification

2. **Privacy Policy**
   - Update privacy policy with actual contact information
   - Host at your domain for App Store review

3. **Subscription Setup**
   - Configure products in App Store Connect
   - Set up introductory offers (14-day free trial)
   - Configure subscription groups

## Known Limitations

- Requires iOS 17+ for latest Screen Time APIs
- Family Controls entitlement needed for App Store
- Some Screen Time data only available in extensions
- Camera-based daylight detection works best outdoors
- Location permission required for accurate sunrise times

## Support

For questions or issues, please open a GitHub issue or contact support@sunbreak.app.

## License

[Add your license information here]