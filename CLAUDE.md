# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Studio Architect is a native macOS photography workflow hub. It is the central dashboard that manages sessions from SD card import through client delivery and archiving. The architecture is **hub + modules**: Studio Architect owns the database and UI shell; individual workflow modules (Import, Cull, Edit, Export, Deliver, Archive) are built into the app over time.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Target:** macOS 15 (Sequoia) minimum
- **Database:** SQLite via GRDB
- **Distribution:** Direct download (no App Store sandboxing constraints)

## Build Commands

```bash
# Open in Xcode
open StudioArchitect.xcodeproj

# Build from CLI
xcodebuild -scheme StudioArchitect -configuration Debug build

# Run tests
xcodebuild -scheme StudioArchitect -configuration Debug test
```

## Architecture

### App Structure

```
StudioArchitect/
├── App/                    # App entry point, scene setup
├── Database/               # GRDB setup, migrations, record types
│   ├── AppDatabase.swift   # Database initialization and migrations
│   └── Models/             # GRDB record types (Client, Session, File, etc.)
├── Features/               # One folder per major feature/screen
│   ├── Hub/                # Dashboard / session list
│   ├── Session/            # Session detail view
│   ├── Clients/            # Client management
│   └── Team/               # Team member management
└── Shared/                 # Reusable views, extensions, utilities
```

### Database

- Location: `~/Library/Application Support/StudioArchitect/studio.db`
- Migrations live in `AppDatabase.swift` — always add new migrations, never modify existing ones
- All database access goes through GRDB's `DatabaseQueue`

### Module Integration (Transition Period)

The existing apps read/write the same SQLite database. Studio Architect launches them via `NSWorkspace`. Eventually each module will be rebuilt natively inside Studio Architect and the apps retired.

| App | Stack | Migration Effort |
|-----|-------|-----------------|
| CullSnap | Electron + TypeScript + React | Full rewrite in SwiftUI |
| FirstPass | SwiftUI (macOS 15) | Low — already native SwiftUI |
| TriPod | Swift + SPM (macOS 13+) | Medium — port to SwiftUI |

## Key Decisions

| Decision | Choice |
|----------|--------|
| Distribution | Direct download |
| Database | GRDB / SQLite |
| DB location | `~/Library/Application Support/StudioArchitect/` |
| Edit format | XMP sidecars (written by FirstPass, readable by Lightroom etc.) |
| Checksum | SHA for backup verification |
| Module hand-off | Shared SQLite for now; URL scheme integration planned |

## Session Workflow Stages

`imported` → `culled` → `first_pass` → `editing` → `exported` → `delivered` → `archived`

## File Statuses

`imported` → `keeper` / `reject` / `maybe` → `first_pass_complete` → `edited` → `exported` → `delivered` → `archived`

---

## CommandCenter Status

This project uses a `.claude/status.json` file to track its status for CommandCenter.
Keep this file up to date as work progresses. Update it whenever:
- The project status or stage changes
- A new blocker is identified or resolved
- The most important next action changes

The file should always reflect the current reality of the project.
