# Optimum

*Your personal sleep dashboard for iOS*

Optimum is a SwiftUI app that tracks your sleep using phone motion (and optionally HealthKit) and provides daily insights, personalized recommendations, and visualizations of your sleep patterns.

## Features

* **Automatic Sleep Detection**: Uses Core Motion to detect stationary periods ≥3 hours in a 48‑hour window and splits them by calendar day.
* **HealthKit Integration (Optional)**: Reads `Sleep Analysis` samples for higher‑precision sleep data when authorized.
* **Daily Breakdown**: Displays *Hours Slept* and *Bedtimes* for “yesterday” with support for multiple sleep blocks (e.g., naps).
* **7‑Day Charts**: Visualize bedtime, total hours slept, and sleep quality over the last 7 days.
* **Sleep Quality Rating**: Rate your sleep on a 1–5 star scale, with timed advice for caffeine cutoff and melatonin.
* **Personalized Notifications**: Schedule alerts for melatonin intake and caffeine cutoff based on your target bedtime.
* **Customizable Theme**: Pick an accent color that persists across app launches.
* **Minimal Splash Screen**: A starry‑sky launch UI that auto‑dismisses after 2 seconds.

## Requirements

* Xcode 15 or later
* iOS 16.0+ deployment target
* Swift 5.9+

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/optimum.git
   cd optimum
   ```

2. Open the Xcode project:

   ```bash
   open Optimum.xcodeproj
   ```

3. Build and run on a physical device (Core Motion requires a real device).

## Configuration

### Capabilities

In **Signing & Capabilities** for the `optimum` target:

* **Background Modes**: Enable *Background Fetch*.
* **HealthKit**: Add and under **Types** include *Sleep Analysis* (Read).

### Entitlements

Ensure a single `optimum.entitlements` file is configured:

```xml
<key>com.apple.developer.healthkit</key>
<dict>
  <key>HKReadTypes</key>
  <array>
    <string>HKCategoryTypeIdentifierSleepAnalysis</string>
  </array>
</dict>
```

In Build Settings → **Code Signing Entitlements**, both Debug and Release should point to `optimum.entitlements`.

### Info.plist

Add the following Privacy Usage Description keys:

* `Privacy - Motion Usage Description`: "Optimum uses motion data to estimate your sleep."
* `Privacy - Health Share Usage Description`: "Optimum reads your sleep logs to draw charts."
* `Privacy - Health Update Usage Description`: "Optimum does not write any data."

## Project Structure

```
Optimum/
├── ContentView.swift        # Dashboard UI
├── SleepEntry.swift         # Data model
├── SleepManager.swift       # Motion & HealthKit detector
├── SleepStore.swift         # Persistence & 7-day buffer
├── NotificationManager.swift# Schedules melatonin/caffeine alerts
├── ThemeManager.swift       # Persisted theme color
├── QualityDetailView.swift  # Sleep quality form & advice
├── Last7DaysView.swift      # Charts of last 7 days
├── BedtimeDetailView.swift  # List of bedtimes
├── SplashView.swift         # 2-second starry‑sky splash UI
├── optimumApp.swift         # App entry point
├── Assets.xcassets/
│   ├── AppIcon.appiconset   # App icons
│   └── SplashBackground     # 2072×4608 night-sky asset
├── optimum.entitlements     # HealthKit entitlements
└── Info.plist
```

## Usage

1. **Launch** the app → see the starry‑sky splash for 2 seconds.
2. **Dashboard**: view *Hours Slept yesterday* and *Bedtimes*, tap through for details.
3. **Set your target bedtime** and tap *Save* to schedule notification reminders.
4. **Rate** your sleep quality via the *Quality* tile; stars and advice for caffeine/melatonin.
5. **Customize** the accent color under the *Theme* tile.

## License

This project is open source. [MIT License](LICENSE)
