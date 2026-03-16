# HomeKit Helper

Bulk-manage your HomeKit accessories without tapping through Apple's Home app one-by-one.

## The Problem

HomeKit's native UI is painful for bulk operations — renaming accessories one-by-one, creating scenes by tapping through each device, no export/backup, and no way for external tools (including LLMs) to reason about your home configuration.

## The Solution

A two-part system:

### 1. Native Bridge App (Swift / Mac Catalyst)
A lightweight macOS/iOS app whose only job is reading from and writing to HomeKit. Exports your full home configuration as structured JSON, and imports "change sets" to apply renames, room moves, and new scenes.

### 2. Web App (Svelte 5 / Vercel) — *coming soon*
The actual UX for planning changes: bulk rename with Siri-optimised name suggestions, scene builder with templates, room management, and LLM-friendly structured data.

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
```

## Getting Started

### Prerequisites
- macOS 14+ with Xcode 16+
- Apple Developer account with HomeKit capability enabled
- At least one home configured in the Home app
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for generating the Xcode project)

### Build & Run

```bash
# Generate the Xcode project
cd HomeKitHelper
xcodegen generate

# Open in Xcode
open HomeKitHelper.xcodeproj

# Select "My Mac (Mac Catalyst)" as the run destination
# Build & Run (Cmd+R)
# Accept the HomeKit permission dialog
```

### First Export
1. Launch the app
2. Tap **Export Configuration**
3. Copy the JSON to clipboard or save to Desktop
4. Paste into the web app (or hand to Claude for analysis)

### Applying Changes
1. Prepare a change set JSON in the web app
2. Copy it to clipboard
3. In the native app, go to the **Import** tab
4. Paste and tap **Apply Changes**
5. Review the operation log

## JSON Schemas

See `concept/schema-export.json` and `concept/schema-import.json` for the full structure.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Native App | Swift, SwiftUI, HomeKit, Mac Catalyst |
| Web App | Svelte 5, Tailwind CSS, Vercel |
| Package Manager | bun (web), xcodegen (native) |
| Transfer | Clipboard (v1), local HTTP server (planned) |

## Roadmap

- [x] v0.1 — Export configuration as JSON
- [ ] v0.2 — Import change sets (renames, room moves)
- [ ] v0.3 — Scene builder and templates
- [ ] v1.0 — Local HTTP server sync, LLM integration, automation rules

## Licence

MIT

---

*Built by [@Jktfe](https://github.com/Jktfe) guided by Claude Code*
