# HomeKit Helper - Project Logic

## Architecture Overview

Two-part system: Native Swift bridge app + Svelte 5 web app.
The native app is the ONLY component that talks to HomeKit (Apple's TCC prevents any other access).
The web app provides the UX for planning bulk changes.

## Data Flow

```
User's HomeKit → Native App (export) → JSON → Web App (plan changes) → JSON → Native App (import) → HomeKit
```

## Models

### Export Models (Sources/Models/ExportModels.swift)
- `HomeExport` — top-level wrapper with date, version, array of homes
- `HomeData` — single home with rooms, accessories, scenes, zones
- `AccessoryData` — device with name, room, category, manufacturer, services
- `ServiceData` — HAP service (lightbulb, sensor, etc.) with characteristics
- `CharacteristicData` — individual controllable property (power, brightness, etc.)

### Import Models (Sources/Models/ImportModels.swift)
- `HomeImport` — change set targeting a specific home
- `RenameAction` — accessoryId + currentName + newName
- `RoomAssignment` — move accessory to different room
- `NewScene` — scene name + array of SceneActions
- `NewRoom` — room name + optional zone assignment

### Log (Sources/Models/LogEntry.swift)
- `LogEntry` — tracks success/failure/skipped for each import operation

## Bridge Logic (Sources/Bridge/HomeKitBridge.swift)

```
We use HMHomeManager to discover all HomeKit homes
→ homeManagerDidUpdateHomes fires when data is ready
→ exportAll() maps HMHome objects into our Codable structs
→ exportJSON() encodes to pretty-printed JSON string

For import:
→ applyChanges(from:) decodes JSON into HomeImport
→ Creates rooms first (other ops may reference them)
→ Then renames, room assignments, scenes in order
→ Each operation logged to importLog array
```

## Views

- `ContentView` — TabView with Export, Import, Log tabs
- `ExportTab` — Shows home summary cards + export button + JSON output
- `ImportTab` — JSON text input + preview of parsed changes + apply button with confirmation
- `LogTab` — List of LogEntry items with status icons

## Key Decisions

- **Clipboard transfer for v1** — simplest possible data transfer mechanism
- **No backend/database** — all data lives in the JSON, no server storage needed
- **@Observable pattern** — modern SwiftUI data flow, no ObservableObject/Published boilerplate
- **Async/await for HomeKit calls** — cleaner than nested completion handlers
- **Mac Catalyst** — required because HomeKit is an iOS-origin framework
