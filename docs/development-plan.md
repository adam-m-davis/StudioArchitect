# Studio Architect — Development Plan

## Phase 1: Project Foundation

### 1.1 Xcode Project Setup
- [ ] Create new macOS SwiftUI app in Xcode (`StudioArchitect`)
- [ ] Set deployment target to macOS 15
- [ ] Add GRDB via Swift Package Manager
- [ ] Set up folder structure: `App/`, `Database/`, `Features/`, `Shared/`
- [ ] Configure app bundle ID and entitlements for full disk access (SD cards, external drives)
- [ ] Add `.gitignore` for Xcode/Swift project

### 1.2 Database Layer
- [ ] Create `AppDatabase.swift` — initializes `DatabaseQueue`, runs migrations
- [ ] Write Migration 1: Create all core tables
  - `clients` (id, name, type, contact_info JSON, created_at, updated_at)
  - `sessions` (id, client_id, name, type, shoot_date, location, current_stage, source_path, created_at, updated_at)
  - `files` (id, session_id, filename, path, file_type, status, exif_data JSON, checksum, created_at, updated_at)
  - `team` (id, name, role, contact_info JSON, payment_info JSON, created_at)
  - `session_team` (session_id, team_id, role, payment_amount, payment_status)
  - `backups` (id, session_id, location_type, path, file_count, checksum_verified, verified_at, created_at)
- [ ] Create GRDB record types for each table (conforming to `FetchableRecord`, `PersistableRecord`, `Codable`)
- [ ] Write database access layer / repository methods for each model

---

## Phase 2: Hub Dashboard

### 2.1 App Shell
- [ ] Main window layout with sidebar navigation
- [ ] Navigation destinations: Sessions (default), Clients, Team
- [ ] App toolbar with global actions (New Session, Settings)

### 2.2 Session List View
- [ ] List all sessions, ordered by shoot_date descending
- [ ] Each row shows: client name, session name, session type, shoot date
- [ ] Visual workflow stage indicator (progress bar or step pills: Import → Cull → Edit → Export → Deliver → Archive)
- [ ] Filter/search bar (by client, stage, date range)
- [ ] Active vs. archived session toggle
- [ ] Empty state for new users

### 2.3 Session Detail View
- [ ] Header: session name, client, date, location, type
- [ ] File counts by status (imported, keepers, rejects, maybe, edited, exported)
- [ ] Backup status row: Work Area ✓ / Local Backup ✓ / Offsite ✓
- [ ] Workflow timeline — completed steps with timestamps
- [ ] Action buttons per stage ("Launch CullSnap", "Mark as Culled", etc.)
- [ ] Team section: who was assigned, their role, payment status
- [ ] Edit session info inline

### 2.4 New Session Flow
- [ ] Modal/sheet: select or create client, session name, type, shoot date, location
- [ ] Creates session record in DB at stage `imported`

---

## Phase 3: Client & Team Management

### 3.1 Client Management
- [ ] Client list view (name, type, number of sessions)
- [ ] Client detail: contact info, full session history
- [ ] Add / edit / archive client

### 3.2 Team Management
- [ ] Team member list
- [ ] Add / edit team member (name, role, contact, payment info)
- [ ] Payment tracking per session (pending / paid)

---

## Phase 4: Electron App Integration (Transition)

### 4.1 Launch Existing Apps
- [ ] "Launch in CullSnap" button — opens CullSnap via `NSWorkspace`
- [ ] "Launch in FirstPass" button — opens FirstPass via `NSWorkspace`
- [ ] "Launch in TriPod" button — opens TriPod via `NSWorkspace`
- [ ] Studio Architect detects when it regains focus (user returned from another app) and refreshes session data from DB

### 4.2 Manual Stage Overrides
- [ ] Allow user to manually mark any stage as complete (for external tool users, e.g. Lightroom)
- [ ] Stage history log stored in DB

---

## Phase 5: Module Migrations (Per App, As They Stabilize)

Each app gets rebuilt natively inside Studio Architect. Suggested order based on workflow sequence and migration effort:

1. **FirstPass (Basic Edits)** — Already SwiftUI + macOS 15, lowest effort migration
2. **TriPod (Import/Archive)** — Native Swift, port UI to SwiftUI, add SD card ingest + backup verification
3. **Export** — Folder export + Pixieset integration (net new)
4. **Deliver** — Delivery tracking (net new)
5. **CullSnap (Cull)** — Highest effort, full rewrite from Electron + React to SwiftUI (includes ML model, ONNX runtime, exiftool)

---

## UI / Design Polish (Ongoing)

- [ ] Define a design language — typography, color palette, spacing system
- [ ] Replace default List styling with custom session cards
- [ ] Design the stage progress indicator (currently basic capsule pills)
- [ ] Toolbar and sidebar styling
- [ ] Empty states with better illustrations or iconography
- [ ] Consider a dark-mode-first or adaptive color scheme that fits a professional photography tool
- [ ] Animations and transitions between views

---

## Phase 6: V2 Features (Post-Unification)

- [ ] Pixieset API integration (upload finals, track delivery)
- [ ] SoloBiller integration (link sessions to invoices)
- [ ] Contracts (templates, e-signatures)
- [ ] Full CRM for clients

---

## Open Technical Questions

1. **EXIF extraction library** — which Swift library for reading RAW file EXIF data? (ExifTool via subprocess, or native ImageIO framework)
2. **URL scheme handoff** — define `studioarchitect://` and `cullsnap://` schemes when CullSnap is ready for deep linking
3. **Lightroom return detection** — how to detect user returned from external editor (NSWorkspace notifications + file system watcher?)
4. **SHA checksum implementation** — reuse TriPod's existing approach or standardize in shared DB layer
