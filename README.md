# Optimum – your personal sleep dashboard 🌙

A modern **SwiftUI** app (iOS 17-only, Swift 5.9) that infers your sleep from iPhone motion, blends optional HealthKit data, and gives you data-driven tips to improve your rest.

---

## ✨ Feature highlights

| Area | What Optimum does |
|------|------------------|
| **Motion-based detection** | Scans the last 48 h of **CMMotionActivity** and treats any merged stationary stretch ≥ **5 hours** (≤ 15 min gaps) as a sleep segment. |
| **HealthKit optional** | *Reads* **Step Count** to refine quality scoring and (if you allow) *writes* detected **Sleep Analysis** blocks. |
| **Daily dashboard** | • *Hours Slept* & *Bedtime* for “yesterday”<br>• Sleep-quality stars (1–5, remembered across relaunches)<br>• Tap-through detail screens. |
| **7-day trends** | Swift Charts for Bedtimes, Hours, Quality, and Steps – bars/points automatically adopt your accent colour. |
| **Quality algorithm** | Rule-based (duration vs goal, fragmentation, bedtime regularity, activity). User edits override the algorithm. |
| **Personalised cues** | **Local notifications** for caffeine cut-off (-6 h) & wind-down/melatonin (-1 h) relative to your target bedtime. |
| **Accent theme** | One-tap colour picker; charts, stars, and UI accents recolour instantly. |
| **Glassmorphic UI** | Frosted cards over a starry NightSky background – looks great in both light & dark mode. |
| **Splash screen** | 2-second star-field fade-in on launch. |

---

## Requirements

* Xcode 15.0 +  
* A **real** iPhone / iPod touch running **iOS 17.0 or later** (Core Motion is unavailable in the Simulator).

---

## Getting started

```bash
git clone https://github.com/your-username/optimum.git
cd optimum
open Optimum.xcodeproj
