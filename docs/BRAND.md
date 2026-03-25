# Plank — Brand Guidelines

## App Overview
Plank is a native macOS bookmark manager that helps users organize, tag, and revisit web links across browsers. Clean, focused, fast.

---

## Icon Concept

**Visual:** A wooden plank/board with a browser bookmark clipped to it — minimal, flat style.
- A horizontal rounded rectangle (the "plank") in warm wood tone
- A stylized bookmark shape in accent blue, clipped to the top edge
- Clean negative space, single focal point
- Sizes: 16, 32, 64, 128, 256, 512, 1024 (standard macOS icon set)

**Alternative concept (if not wood):** A minimal bookmark silhouette with a subtle 3D fold, floating on a soft circular background.

---

## Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Primary Blue | `#2563EB` | Active states, selected items, CTAs |
| Deep Blue | `#1D4ED8` | Pressed states, dark mode accent |
| Wood Warm | `#D97706` | Icon accent, highlights |
| Background Light | `#F8FAFC` | Main background (light mode) |
| Background Dark | `#0F172A` | Main background (dark mode) |
| Surface Light | `#FFFFFF` | Cards, panels (light) |
| Surface Dark | `#1E293B` | Cards, panels (dark) |
| Text Primary Light | `#0F172A` | Headings, main text (light) |
| Text Primary Dark | `#F1F5F9` | Headings, main text (dark) |
| Text Secondary | `#64748B` | Subtitles, metadata |
| Border Light | `#E2E8F0` | Dividers, borders (light) |
| Border Dark | `#334155` | Dividers, borders (dark) |
| Success | `#10B981` | Visit confirmed, saved |
| Warning | `#F59E0B` | Expiring bookmarks |
| Destructive | `#EF4444` | Delete, danger actions |

---

## Typography

- **Display / App Name:** SF Pro Display, Bold — 24px
- **Headings (Section titles):** SF Pro Text, Semibold — 16px
- **Body (Bookmark titles):** SF Pro Text, Regular — 14px
- **Metadata (URL, date):** SF Pro Text, Regular — 12px, `#64748B`
- **Tags:** SF Pro Text, Medium — 11px

**Font Stack (CSS/Web equivalents):**
```
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", sans-serif;
```

---

## Visual Motif

**Theme:** "Organized Wood" — warm, tactile, analog organization meets digital precision.

- **Sidebar:** Warm neutral background, bookmark tree with folder icons
- **Tag pills:** Rounded rectangles with user-assigned colors
- **Visit indicators:** Small dot/circle showing recent visits
- **Empty states:** Friendly line illustrations of a bookmark on a wooden board
- **Scrollbar:** Thin, matching the surface color

**Spatial rhythm:** 8pt grid. Sidebar 220px fixed. Content area fluid. Card padding 12px.

---

## macOS-Specific Behavior

- **Window:** Standard `NSWindow` with toolbar. Minimum size 800×500.
- **Menu Bar:** No persistent menu bar icon — uses Dock icon + window.
- **Sidebar:** `NSSplitViewController` with source list style.
- **Tags:** Inline color chips, alphabetically sorted.
- **Dark Mode:** Full support via `NSColor` system colors.
- **Keyboard shortcuts:** `⌘B` new bookmark, `⌘F` search, `⌘⇧B` open bookmark.

---

## Sizes & Behavior

| Element | Default | Compact (Sidebar) |
|---------|---------|-------------------|
| Row height | 44px | 28px |
| Icon size | 16×16 | 14×14 |
| Font size | 14px | 12px |
| Padding | 12px | 8px |

Window is resizable. Sidebar can be collapsed. Content area adapts with masonry or list layout toggle.
