# Studio Architect — Technical Foundation

## Overview

Studio Architect is a unified photography workflow application for hobbyist and beginning photographers. It provides a complete pipeline from SD card import to client delivery and archiving, with modular components that can be enabled or disabled based on user preference.

**Core Philosophy:** "Architect your own workflow" — use the pieces you want, skip the ones you don't, and it all still works together.

**Privacy-First Approach:** Files never leave the photographer's machine unless they explicitly choose to (backups, cloud delivery, etc.).

---

## Architecture

### Application Structure

- **Studio Architect** — Central hub/dashboard showing all sessions and their current stage
- **Modules** — Individual workflow steps that read/write to a shared database
- **V1:** Modules launch as separate apps (CullSnap, FirstPass, TriPod already built)
- **At Maturity:** All modules live inside one unified application with licensed components

### Database

- **Type:** SQLite (local, embedded)
- **Location:** `~/Library/Application Support/StudioArchitect/studio.db`
- **Rationale:** User doesn't need to see or manage this; keeps everything on their machine

### Existing Apps (To Be Integrated)

| App | Purpose | Current Status | Tech Stack |
|-----|---------|----------------|------------|
| CullSnap | Photo culling/selection | Beta | macOS native |
| FirstPass | Basic edits (WB, exposure, color) | Beta | macOS native |
| TriPod | SD card ingest + backup management | Beta ready | macOS native |
| SoloBiller | Invoicing | Production (web) | Node.js/Supabase |

*Note: Specific frameworks for macOS apps TBD — review git repos*

---

## Database Schema

### Core Tables

#### Clients
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | String | Client or corporation name |
| type | Enum | personal, corporate |
| contact_info | JSON | Email, phone, address (flexible) |
| created_at | Timestamp | |
| updated_at | Timestamp | |

#### Sessions
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| client_id | UUID | Foreign key to Clients |
| name | String | Session name (e.g., "Johnson Wedding") |
| type | Enum | wedding, portrait, event, corporate, etc. |
| shoot_date | Date | Date of the shoot |
| location | String | Optional |
| current_stage | Enum | See workflow stages below |
| source_path | String | Original folder path where files live |
| created_at | Timestamp | |
| updated_at | Timestamp | |

#### Files
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| session_id | UUID | Foreign key to Sessions |
| filename | String | Original filename |
| path | String | Current file location |
| file_type | String | RAW type (CR3, NEF, ARW, etc.) or JPEG |
| status | Enum | See file statuses below |
| exif_data | JSON | Camera, lens, focal length, aperture, shutter, ISO, datetime |
| checksum | String | SHA checksum for integrity verification |
| created_at | Timestamp | |
| updated_at | Timestamp | |

#### Team
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | String | Person's name |
| role | String | second_shooter, assistant, etc. |
| contact_info | JSON | Email, phone |
| payment_info | JSON | For tracking payments owed |
| created_at | Timestamp | |

#### SessionTeam (Junction Table)
| Field | Type | Description |
|-------|------|-------------|
| session_id | UUID | Foreign key to Sessions |
| team_id | UUID | Foreign key to Team |
| role | String | Role for this specific session |
| payment_amount | Decimal | Amount owed for this session |
| payment_status | Enum | pending, paid |

#### Backups
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| session_id | UUID | Foreign key to Sessions |
| location_type | Enum | work_area, local_backup, offsite |
| path | String | Folder path or cloud destination identifier |
| file_count | Integer | Number of files in this backup |
| checksum_verified | Boolean | Whether SHA verification passed |
| verified_at | Timestamp | When verification completed |
| created_at | Timestamp | |

---

## Enums

### Session Stages (current_stage)
```
imported        — Files ingested, untouched
culled          — Keepers selected
first_pass      — Basic edits applied
editing         — In external editor (Lightroom, etc.)
exported        — Finals created
delivered       — Sent to client
archived        — Backed up and complete
```

### File Statuses (status)
```
imported              — Just ingested, untouched
keeper                — Marked to keep in culling
reject                — Marked to reject in culling
maybe                 — Flagged for second look
first_pass_complete   — Basic edits applied
edited                — Detailed editing done (external)
exported              — Final version created
delivered             — Sent to client
archived              — Stored for long-term
```

### Backup Location Types (location_type)
```
work_area      — Fast working drive
local_backup   — Local external drive or NAS
offsite        — Cloud storage or other physical location
```

---

## V1 Workflow

### Steps (Inside Studio Architect)

| Step | Module | Function |
|------|--------|----------|
| 1. Import | TriPod | Ingest from SD cards to work area, create session, register files, extract EXIF |
| 2. Cull | CullSnap | Mark keepers/rejects in database, optionally move files |
| 3. Basic Edits | FirstPass | Apply auto-adjustments, output as XMP sidecars |
| 4. Detail Edits | External | Hand off to Lightroom/Capture One/etc. |
| 5. Export | Built-in | Manual folder export + Pixieset integration |
| 6. Deliver | Built-in | Track delivery status |
| 7. Archive | TriPod | Move to backup locations, verify checksums, confirm 1-2-3 backup rule |

### Module Independence

Each module is optional. The system handles skipped steps:
- Each step has its own input/output
- Database tracks file status regardless of which tool made the change
- User can mark stages complete manually if using external tools

### Edit Portability

- **FirstPass outputs XMP sidecars** alongside RAW files
- XMP is the industry standard for non-destructive edits
- Compatible with: Lightroom, Capture One, Bridge, Photo Mechanic, darktable, etc.
- Database tracks that FirstPass was applied, but actual edit data lives in XMP

---

## Integration Points

### Pixieset (V1)
- Export finals directly to Pixieset gallery
- API integration for upload
- Track delivery status in database

### Future Integrations (V2+)
- SmugMug
- Dropbox
- Google Drive
- Cloud backup services

### SoloBiller Integration (V2)
- Link sessions to invoices
- Support deposit + balance workflow
- Sync client data between apps

---

## Archive & Backup System

### 1-2-3 Backup Rule
1. Work area (fast drive)
2. Local backup (external drive/NAS)
3. Offsite backup (cloud or physical offsite)

### TriPod Responsibilities
- Track folder locations and file counts per backup destination
- SHA checksum verification after each copy
- Report backup status to Studio Architect dashboard
- Session marked "archived" only when all 3 locations verified

---

## Studio Architect Dashboard

### Session List View
- All active and archived sessions
- Client name, session type, shoot date
- Current stage with visual progress indicator
- Quick actions to launch next step

### Session Detail View
- Full session info (client, date, location, team)
- File counts by status (imported, keepers, rejects, etc.)
- Backup status (work area ✓, local ✓, offsite ✓)
- Timeline of completed steps with timestamps
- Launch buttons for each workflow module

---

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Database | SQLite | Local-first, embedded, no server needed |
| Database location | App sandbox | User doesn't need to see it |
| Edit format | XMP sidecars | Industry standard, works with any photo editor |
| Checksum | SHA | Already implemented in TriPod |
| EXIF extraction | Auto on import | Camera, lens, settings extracted from files |
| Module architecture | Shared database | All apps read/write same SQLite file |

---

## V2 Roadmap

### Business Operations
- **Customers** — Full CRM functionality
- **Contracts** — Templates, e-signatures, tracking
- **Invoicing** — SoloBiller integration with deposit/balance support

### V3 Roadmap

### Growth
- **Marketing** — Campaign tracking, lead sources
- **Social Media** — Post scheduling, gallery sharing

---

## Open Questions / To Be Determined

1. Confirm tech stack for each macOS app (Swift? SwiftUI? AppKit? Other frameworks?)
2. Define exact XMP fields FirstPass will write
3. Pixieset API integration details
4. How to handle "Detail Edits" stage — detect when user returns from Lightroom, or manual toggle?
5. App sandboxing implications for shared SQLite access across multiple apps
6. Migration path from standalone apps to unified Studio Architect app

---

## Next Steps

1. Review git repos for CullSnap, FirstPass, TriPod to confirm tech stacks
2. Design shared database access pattern that works across separate apps
3. Create detailed schema with actual SQL
4. Define API/interface each module exposes
5. Build Studio Architect hub app with session management
6. Integrate first module (likely TriPod as starting point of workflow)
