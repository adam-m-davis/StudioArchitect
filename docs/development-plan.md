# Studio Architect — Development Plan

## Phase 1: Project Foundation

### 1.1 Xcode Project Setup
- [ ] Create new macOS SwiftUI app in Xcode (`StudioArchitect`)
- [ ] Set deployment target to macOS 15
- [ ] Add GRDB via Swift Package Manager
- [ ] Set up folder structure: `App/`, `Database/`, `Features/`, `Shared/`
- [ ] Configure app bundle ID and **App Sandbox** entitlements: user-selected file access (read/write) + security-scoped bookmarks for SD cards / external drives (no full-disk-access entitlement under the sandbox)
- [ ] Add `.gitignore` for Xcode/Swift project

### 1.2 Database Layer
- [ ] Create `AppDatabase.swift` — initializes `DatabaseQueue`, runs migrations
- [ ] Write Migration 1: Create all core tables
  - `clients` (id, name, type, contact_info JSON, created_at, updated_at)
  - `sessions` (id, client_id, name, type, shoot_date, location, current_stage, source_path, created_at, updated_at)
  - `photo_files` (id, session_id, filename, path, file_type, status, exif_data JSON, checksum, created_at, updated_at) — model: `PhotoFile`
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
- [ ] Action buttons per stage ("Start Cull", "Mark as Culled", etc.) — all in-app, native
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

## Phase 4: Manual Stage Tracking & External-Editor Handoff

Studio Architect is fully independent — it does **not** launch or integrate the standalone apps. The only external tool in the workflow is the photographer's detail editor (Lightroom/Capture One), entered between the native Export and Deliver stages.

### 4.1 Manual Stage Overrides
- [ ] Allow the user to manually mark any stage complete (e.g. detail editing done in Lightroom)
- [ ] Stage history log stored in DB (stage, timestamp)

### 4.2 External Detail-Edit Handoff
- [ ] "Reveal in Finder" / open the session's working folder so the user can hand RAWs + XMP to their editor
- [ ] On return, let the user mark "Detail Edits" complete (manual toggle; optional folder re-scan to pick up new exports)

---

## Phase 5: Native Workflow Stages (The Core Build)

Every stage is built natively inside Studio Architect — no code is shared with the standalone apps; validated ideas are re-implemented in SwiftUI. Suggested order by workflow sequence and effort:

1. **Import** — Native SD-card ingest (user-selected volume + security-scoped bookmark), copy to work area, register files, extract EXIF via **ImageIO** (not exiftool), SHA checksums. (Incubated in TriPod.)
2. **Basic Edits** — Auto-adjustments (WB, exposure, color), write **XMP sidecars**. (Incubated in FirstPass; already SwiftUI, lowest-effort port.)
3. **Export** — Folder export + Pixieset integration (net new)
4. **Deliver** — Delivery tracking + client galleries via **integration** (Pixieset/Pic-Time/ShootProof): upload finals, share the client URL, track status. Print fulfillment comes free via the platform. (Own hosting is a separate, later, validate-first bet — see Phase 6.) (net new)
5. **Archive** — Move to backup locations, SHA verification, track 1-2-3 backup state. (Incubated in TriPod.)
6. **Cull** — Native ML-assisted culling via the **Vision framework** (no bundled inference runtime — see below), keeper/reject/maybe. (Incubated in CullSnap; full SwiftUI rebuild.)

### 5.1 Cull Stage — Vision-Native (resolved)

CullSnap has no proprietary model; its scoring is rules over generic signals + three public ONNX models, each of which has a superior native Vision equivalent. The SA cull is built on Vision (ANE-accelerated, sandbox-clean, zero bundled weights) plus ported heuristics.

- [ ] Decode pipeline (the real bottleneck): extract embedded RAW previews via ImageIO (`CGImageSourceCreateThumbnailAtIndex` + `kCGImageSourceThumbnailMaxPixelSize`), downscale, parallelize across cores, stream results to UI
- [ ] Face detection → `VNDetectFaceRectanglesRequest`
- [ ] Eyes open/closed → `VNDetectFaceLandmarksRequest` (eye landmarks → Eye Aspect Ratio, EAR < 0.20 = closed), or `VNDetectFaceCaptureQualityRequest`
- [ ] Aesthetic score → `VNCalculateImageAestheticsScoresRequest` (macOS 15) — replaces CullSnap's never-built NIMA placeholder
- [ ] Saliency/composition (optional) → `VNGenerateAttentionBasedSaliencyImageRequest`
- [ ] Port pure scoring functions from CullSnap `scoring.ts` to Swift: exposure histogram, Laplacian blur (recalibrate the threshold — CullSnap's was uncalibrated), star rating, accept/reject/review
- [ ] Do **not** add ONNX Runtime or convert models to Core ML — there is no custom model to preserve

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

- [ ] Client-gallery integration (Pixieset/Pic-Time/ShootProof): upload finals, share URL, track delivery — print fulfillment included via the platform
- [ ] SoloBiller integration (link sessions to invoices)
- [ ] Contracts (templates, e-signatures)
- [ ] Full CRM for clients

### Phase 6.1: Own Photo Hosting (only if integration validates demand)

A bigger bet that turns SA part-SaaS. Do **not** build until the V2 integration proves customers want delivery through SA.

- [ ] SA-hosted storage + client web gallery (view + download) + shareable URLs
- [ ] Access control per gallery (link/password/expiry)
- [ ] Optional **monthly subscription** billing (recurring revenue to cover recurring storage/bandwidth COGS)
- [ ] Resolve App Store billing path (Apple IAP vs. external service)
- [ ] Keep strictly opt-in — local-first default unchanged
- [ ] (Later) Print ordering via white-label lab API (WHCC/Bay Photo/Prodigi) + cart/checkout/payments/tax/shipping

---

## Open Technical Questions

1. **EXIF extraction** — confirm ImageIO (`CGImageSource`) reads all needed fields across RAW types (CR3/NEF/ARW). (Resolved direction: ImageIO, since the sandbox forbids an exiftool subprocess.)
2. **Lightroom return detection** — manual toggle vs. a file-system watcher on the working folder (sandbox-permitted within user-selected, bookmarked folders)
3. **SHA checksum implementation** — standardize a native checksum/verification routine in SA's DB layer
4. **Cull tuning** — calibrate blur/EAR/aesthetic thresholds against a labeled wedding set; confirm `VNCalculateImageAestheticsScoresRequest` quality on RAW-preview input

*Resolved: **ML cull = Vision-native, no bundled inference runtime** (see Phase 5.1). CullSnap exposed no proprietary model — its public ONNX models all have superior native Vision equivalents.*
