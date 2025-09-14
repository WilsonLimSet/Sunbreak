# Setup Shield Configuration Extension in Xcode

I've created the necessary files for the Shield Configuration extension. Now you need to add it as a new target in Xcode:

## Steps to Complete Setup:

1. **Open your project in Xcode**

2. **Add New Target:**
   - Click on your project in the navigator
   - Click the "+" button at the bottom of the targets list
   - Search for "App Extension"
   - Select "App Extension" and click Next
   - Name it: `SunbreakShield`
   - Bundle ID: `com.sunbreak.app.SunbreakShield`
   - Click Finish

3. **Configure the New Target:**
   - Select the new `SunbreakShield` target
   - Go to Build Settings
   - Set "Product Module Name" to `SunbreakShield`
   - Set iOS Deployment Target to match your main app (18.5)

4. **Replace Auto-Generated Files:**
   - Delete the auto-generated files in the new target
   - Right-click on the `SunbreakShield` folder in Xcode
   - Select "Add Files to Sunbreak..."
   - Navigate to `/Users/wilsonlimsetiawan/SunBreak/SunbreakShield/`
   - Select:
     - `ShieldConfigurationExtension.swift`
     - `Info.plist`
     - `SunbreakShield.entitlements`
   - Make sure "SunbreakShield" target is checked
   - Click Add

5. **Set Entitlements:**
   - Select the `SunbreakShield` target
   - Go to "Signing & Capabilities"
   - Under "Code Signing Entitlements", set: `SunbreakShield/SunbreakShield.entitlements`

6. **Embed Extension in Main App:**
   - Select your main `Sunbreak` target
   - Go to "General" tab
   - In "Frameworks, Libraries, and Embedded Content"
   - You should see `SunbreakShield.appex` - make sure it's set to "Embed & Sign"

7. **Clean and Rebuild:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)

## Files Already Created:
- ✅ `/Users/wilsonlimsetiawan/SunBreak/SunbreakShield/ShieldConfigurationExtension.swift` - Your custom shield UI code
- ✅ `/Users/wilsonlimsetiawan/SunBreak/SunbreakShield/Info.plist` - Extension configuration
- ✅ `/Users/wilsonlimsetiawan/SunBreak/SunbreakShield/SunbreakShield.entitlements` - Required permissions

## What This Fixes:
- Separates DeviceActivityMonitor and Shield Configuration into proper distinct extensions
- Uses correct `NSExtensionPointIdentifier` for shield configuration
- Properly registers your custom shield UI with the system

After completing these steps, delete and reinstall the app on your device. Your custom shield message "Good night 🌙" should now appear instead of the default iOS message.