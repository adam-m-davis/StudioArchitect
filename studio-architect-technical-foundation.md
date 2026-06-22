# Studio Architect — Technical Foundation

## Overview

Studio Architect is a single, self-contained photography workflow application for hobbyist and beginning photographers. It provides a complete native pipeline from SD card import to client delivery and archiving. Each stage is optional — the user can use the steps they want and skip the rest — but every stage lives inside the one app (there are no separate modules or companion apps to install).

**Core Philosophy:** "Architect your own workflow" — use the pieces you want, skip the ones you don't, and it all still works together.

**Privacy-First Approach:** Files never leave the photographer's machine unless they explicitly choose to (backups, cloud delivery, etc.).

---

## Architecture

### Application Structure

- **Studio Architect** — A single, self-contained macOS application. It is **not** a launcher or hub for other apps; every workflow stage is built natively inside it.
- **No external dependencies at runtime** — Studio Architect does not launch, read from, or write to any other app. There is no shared database and no handoff contract.
- **Build approach:** Stages are implemented natively over time. Simple/net-new stages (session management, export, deliver, manual stage tracking) come first; the harder image-processing stages (advanced cull, basic edits) are built natively as they're ready.

### Database

- **Type:** SQLite (local, embedded), owned solely by Studio Architect
- **Location:** `~/Library/Application Support/StudioArchitect/studio.db`
- **Rationale:** Local-first; user doesn't need to see or manage it; keeps everything on their machine

### Standalone Apps (Feature Incubators — Not Integrated)

These are **separate products with no integration into Studio Architect**. They are used to trial features cheaply with real users before those features are **re-implemented natively** in Studio Architect (code is rebuilt, not shared). The apps are wound down as Studio Architect matures. This is a transition tactic; once the apps retire, feature trialing happens inside Studio Architect (beta builds / feature flags).

| App | Purpose | Current Status | Tech Stack |
|-----|---------|----------------|------------|
| CullSnap | Photo culling/selection | Beta | Electron + TypeScript + React |
| FirstPass | Basic edits (WB, exposure, color) | Beta | SwiftUI (macOS 15) |
| TriPod | SD card ingest + backup management | Beta ready | Swift + SPM (macOS 13+) |
| SoloBiller | Invoicing | Production (web) | Node.js/Supabase |

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

#### photo_files *(GRDB model: `PhotoFile`)*
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

All stages are native features of Studio Architect (the standalone-app names below indicate where the capability is *incubated*, not a tool that Studio Architect launches).

| Step | Stage (native in SA) | Incubated in | Function |
|------|----------------------|--------------|----------|
| 1. Import | Import | TriPod | Ingest from SD cards to work area, create session, register files, extract EXIF |
| 2. Cull | Cull | CullSnap | Mark keepers/rejects, optionally move files |
| 3. Basic Edits | Basic Edits | FirstPass | Apply auto-adjustments, output as XMP sidecars |
| 4. Detail Edits | (external editor) | — | Hand off to Lightroom/Capture One/etc. |
| 5. Export | Export | net-new | Manual folder export + Pixieset integration |
| 6. Deliver | Deliver | net-new | Track delivery status |
| 7. Archive | Archive | TriPod | Move to backup locations, verify checksums, confirm 1-2-3 backup rule |

### Stage Independence

Each stage is optional. Studio Architect handles skipped steps:
- Each stage has its own input/output
- The database tracks session/file status natively
- The user can mark stages complete manually if they used an external tool (e.g. Lightroom) for that step

### Edit Portability

- **FirstPass outputs XMP sidecars** alongside RAW files
- XMP is the industry standard for non-destructive edits
- Compatible with: Lightroom, Capture One, Bridge, Photo Mechanic, darktable, etc.
- Database tracks that FirstPass was applied, but actual edit data lives in XMP

---

## Integration Points

### Delivery & Client Galleries — Photo Hosting (Phased)

Optional client-facing photo hosting: the photographer uploads finals, gets a shareable URL, and the client views + downloads. **Approach is phased — integrate first, build our own later only if demand is proven.**

**V1 — Integrate an existing platform (Pixieset / Pic-Time / ShootProof).**
- Export finals directly to a gallery on the chosen platform via its API
- Share the client URL; track delivery status in SA's database
- **Print fulfillment comes for free** — these platforms have built-in print stores/labs, which answers the "where do we do prints?" question with zero extra work
- No infrastructure, no recurring COGS for us; goal is to validate that customers want delivery through SA

**V2+ — Build our own hosting (only if V1 validates demand).**
- SA-hosted storage + client web gallery + shareable URLs (view + download)
- **Monetized as an optional monthly subscription** — the recurring storage/bandwidth COGS justify recurring revenue, and being optional preserves the "no subscription guilt" promise of the core app
- This makes SA part-SaaS: storage, CDN, access control, uptime, security, support are all now in scope
- Print ordering would be a bolt-on white-label lab API (e.g. WHCC / Bay Photo / Prodigi) plus cart/checkout/payments/tax/shipping — a real e-commerce layer, deferred until the model is proven
- **Privacy:** hosting is strictly opt-in; the local-first, "your files, your machine" default is unchanged. Upload only happens when the photographer chooses it
- **App Store note:** confirm how the subscription is billed (Apple IAP vs. external service) before committing — Apple is aggressive about in-app-unlocked subscriptions

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
| Distribution | Mac App Store (sandboxed) | Built-in payments + discovery; accept sandbox constraints below |
| Database | SQLite | Local-first, embedded, no server needed |
| Database location | App sandbox container | Sandbox redirects to `~/Library/Containers/<bundle-id>/Data/...`; user doesn't manage it |
| File access | User-selected + security-scoped bookmarks | Sandbox: no full-disk entitlement; user grants SD card / drive access once, persisted via bookmark |
| Edit format | XMP sidecars | Industry standard, works with any photo editor |
| Checksum | SHA | Backup integrity verification |
| EXIF extraction | ImageIO (`CGImageSource`) on import | Sandbox forbids an `exiftool` subprocess; use Apple's native framework |
| ML cull | Vision framework (no bundled runtime) | No proprietary model exists; native Vision requests beat the off-the-shelf ONNX models, ANE-accelerated, zero weights |
| App architecture | Single self-contained app | No shared DB, no app launching, no handoff — SA is fully independent |

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

## Cull Stage — Vision-Native (Resolved)

**Decision: the native Cull stage uses Apple's Vision framework. Bundle no inference runtime — no ONNX Runtime, no Core ML conversion.**

The CullSnap incubator revealed there is **no proprietary model** to preserve: its "AI" is a rule-based scoring system over generic signals, backed by three off-the-shelf public ONNX models. Every neural piece maps to a native Vision request that is ANE-accelerated, ships zero weights, is sandbox-clean, and is Apple-maintained. The remaining logic is classic CV math and ~200 lines of pure scoring heuristics, ported directly to Swift.

| CullSnap signal | CullSnap implementation | Native replacement in SA |
|---|---|---|
| Face detection | Ultra-Light-Fast-Generic-Face-Detector (public ONNX, ~1 MB) | `VNDetectFaceRectanglesRequest` |
| Eyes open/closed | 106-pt InsightFace landmarks (public ONNX) → Eye Aspect Ratio, EAR < 0.20 = closed | `VNDetectFaceLandmarksRequest` (eye landmarks → same EAR), or `VNDetectFaceCaptureQualityRequest` for a holistic per-face "good shot" score |
| Composition / saliency | u2netp (public ONNX), optional, often disabled | `VNGenerateAttentionBasedSaliencyImageRequest` |
| Aesthetic score | Exposure proxy only — the real model (NIMA) was never built | `VNCalculateImageAestheticsScoresRequest` (**macOS 15**) — native aesthetics, for free |
| Exposure | Luminance-histogram math (no model) | Port pure function to Swift (vImage/Accelerate) |
| Blur / focus | Laplacian variance, p90 threshold (no model; CullSnap's threshold is uncalibrated) | Port to Swift (vImage Laplacian); Vision face-capture-quality also covers faces |
| Star rating + accept/reject/review | Pure functions in `scoring.ts` | Port verbatim to Swift |

**Implications:**
- The on-device ANE handles all inference via Vision; no third-party ML dependency, smallest App Store footprint.
- The true bottleneck is **not** inference but **decode/I/O at scale** (thousands of RAWs). Use ImageIO to extract the **embedded JPEG preview** (`CGImageSourceCreateThumbnailAtIndex`, `kCGImageSourceThumbnailMaxPixelSize`) and run requests on the downscaled image; parallelize across cores; stream results into the UI.
- SA's cull can exceed CullSnap on day one: Vision's `faceCaptureQuality` and `aesthetics` cover CullSnap's two weakest spots (uncalibrated blur, never-built aesthetic model).

---

## Open Questions / To Be Determined

1. Define exact XMP fields the native Basic Edits stage will write
2. Pixieset API integration details
3. How to handle the "Detail Edits" stage — detect when the user returns from Lightroom, or manual toggle?
4. Pricing model for a single complete app (marketing-doc numbers are a placeholder — revisit)

*Resolved: distribution is the **Mac App Store (sandboxed)** — EXIF via ImageIO (no exiftool), SD/drive access via security-scoped bookmarks, DB in the app container. Cross-app shared-SQLite sandboxing and the standalone-app migration path are moot — Studio Architect has no runtime tie to the other apps. **ML cull = Vision-native, no bundled inference runtime** (see "Cull Stage" above).*

---

## Next Steps

1. Finalize the SQLite schema in `AppDatabase.swift` (clients, sessions, files, team, session_team, backups)
2. Build Studio Architect's core: session management, client/team management, dashboard
3. Implement the first native workflow stage end-to-end (Import is the natural starting point)
4. Add the remaining native stages in workflow order, pulling validated ideas from the incubator apps
5. Lock App Store sandbox entitlements early (user-selected files + security-scoped bookmarks) so file-access UX is designed around them from the start
