# HomeKit Helper - Concept

## The Problem

HomeKit's native UI (Home app on iOS/macOS) is painful for bulk operations:
- Renaming accessories one-by-one is tedious
- No way to preview/plan name changes before applying them
- Scene creation requires tapping through each accessory individually
- No export/backup of your home configuration
- No way for LLMs or external tools to interact with HomeKit data
- Apple locks HomeKit data behind TCC - no config files, no database access, no AppleScript

## The Solution

A two-part system:

### 1. Native Bridge App (Swift / Mac Catalyst)
- **Only job**: Read from and write to HomeKit via Apple's framework
- Exports full home config as structured JSON
- Imports a "change set" JSON to apply renames, room moves, and new scenes
- Requires HomeKit entitlement and user permission

### 2. Web App (Svelte 5 / Vercel)
- **The actual UX**: Nice interface for planning changes
- Reads the exported JSON
- Provides bulk rename UI with Siri-optimised name suggestions
- Scene builder with drag-and-drop accessory selection
- Room management and zone planning
- LLM-friendly: structured data that Claude can reason about
- Generates an import JSON that the native app consumes

## Data Flow

```
Native Bridge App          Web App (Svelte 5)         LLM / Claude
(Swift / HomeKit)          (Vercel)
      |                         |                         |
      |--- JSON export -------->|                         |
      |                         |--- paste config ------->|
      |                         |<-- name suggestions ----|
      |                         |<-- scene plans ---------|
      |                         |                         |
      |<-- JSON import ---------|                         |
      |                         |                         |
      | (applies renames,       |                         |
      |  creates scenes,        |                         |
      |  moves rooms)           |                         |
```

## Transfer Mechanism Options

1. **Clipboard** - simplest. Export copies to clipboard, paste into web app
2. **File share** - export to iCloud Drive / Files, web app reads via file picker
3. **Local server** - native app runs a tiny HTTP server, web app fetches from localhost
4. **Share sheet** - iOS share extension to push directly to web app URL

**Recommended**: Start with clipboard (v1), add local server (v2).

## Siri Naming Best Practices (built into web app)

The web app should enforce/suggest these rules:
- **Short names** (2-3 words max): "Kitchen Light" not "Kitchen Ceiling Pendant Light"
- **No duplicate first words**: Don't have "Kitchen Light" and "Kitchen Lamp"
- **Room prefix only when needed**: If accessory is assigned to a room, Siri knows the room
- **Avoid filler words**: No "the", "my", "a" in names
- **No special characters**: Stick to plain English words
- **Distinct sounds**: "Light" vs "Lamp" is fine, "Light" vs "Lite" is not
- **Verb-friendly**: Names should work with "Hey Siri, turn on [name]"

## Scene Templates (built into web app)

Pre-built templates users can customise:
- **Kids Wake Up** - bedroom lights on gentle, hallway on, bathroom on
- **Kids Bedtime** - bedroom lights dim warm, hallway night light, other rooms off
- **Guest Night** - guest room lights, bathroom, hallway night mode
- **Sunny Day** - all blinds open, lights off
- **Dark Day** - key room lights on low
- **Movie Night** - living room lights off/dim, TV bias lighting
- **Away** - random light cycling, cameras armed
- **Morning Routine** - kitchen lights, coffee area, hallway
- **Leaving Home** - everything off, cameras on, locks engaged

## Tech Stack

### Native App
- **Language**: Swift
- **Framework**: HomeKit (via Mac Catalyst on macOS)
- **UI**: SwiftUI (minimal - just export/import buttons and status)
- **Target**: macOS 14+ / iOS 17+
- **Signing**: Requires Apple Developer account with HomeKit entitlement

### Web App
- **Framework**: Svelte 5
- **Hosting**: Vercel
- **Package manager**: bun
- **Styling**: Tailwind CSS
- **State**: Svelte 5 runes ($state, $derived)
- **No backend needed** - all data is in the JSON, no server storage

## Files in This Concept

| File | Purpose |
|------|---------|
| `HomeKitBridge.swift` | Complete Swift source - export + import logic |
| `CONCEPT.md` | This file |
| `schema-export.json` | Example export JSON structure |
| `schema-import.json` | Example import JSON structure |
| `HomeKitMapper.entitlements` | Required entitlements plist |
| `Info.plist` | Required app metadata plist |

## Xcode Project Setup

1. Create new Xcode project: **App** -> Mac Catalyst
2. Bundle ID: `com.nmvc.homekithelper`
3. Add capability: **HomeKit** (requires Apple Developer portal config)
4. Add `HomeKitBridge.swift` to the project
5. Add `HomeKitMapper.entitlements` - ensure `com.apple.developer.homekit` = YES
6. Add `NSHomeKitUsageDescription` to Info.plist
7. Build target: **My Mac (Mac Catalyst)**
8. Run -> accept HomeKit permission dialog -> JSON appears on Desktop

### Compile from CLI (alternative)

```bash
swiftc HomeKitBridge.swift \
  -o HomeKitHelper \
  -target arm64-apple-ios17.0-macabi \
  -Fsystem $(xcrun --show-sdk-path)/System/iOSSupport/System/Library/Frameworks \
  -framework HomeKit -framework Foundation
```

Then sign:
```bash
codesign --force --sign - --entitlements HomeKitMapper.entitlements HomeKitHelper
```

**Note**: CLI-compiled Catalyst binaries may not launch properly without a full app bundle. Xcode project is the reliable path.

## MVP Scope

### v0.1 - Export Only
- Native app exports JSON to clipboard/file
- Paste into web app
- Web app displays accessories by room
- Manual rename in web app
- Copy import JSON from web app

### v0.2 - Import + Rename
- Native app reads import JSON
- Applies renames via HomeKit API
- Success/failure log

### v0.3 - Scenes
- Web app scene builder
- Template scenes
- Import creates scenes in HomeKit

### v1.0 - Polish
- Local HTTP server for seamless sync
- LLM integration (paste config, get name suggestions)
- Automation rule builder
- Backup/restore home configs
