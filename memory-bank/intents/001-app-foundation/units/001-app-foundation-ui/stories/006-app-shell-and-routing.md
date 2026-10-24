---
id: 006-app-shell-and-routing
unit: 001-app-foundation-ui
intent: 001-app-foundation
status: complete
priority: must
created: 2026-10-23T22:22:46Z
assigned_bolt: 002-app-foundation-ui
implemented: true
---

# Story: 006-app-shell-and-routing

## User Story

**As a** listener
**I want** a bottom navigation bar with Home, Search, Library and Contribute
**So that** I can move between the main areas of the app

## Acceptance Criteria

- [ ] **Given** the app is open, **When** I tap each of the four tabs, **Then** that tab's screen shows and the tab is highlighted (`primaryText`, bold; others `muted`)
- [ ] **Given** I scrolled on a tab, **When** I switch away and back, **Then** its scroll position and state are preserved
- [ ] **Given** I'm on a non-Home tab root, **When** I press Android back, **Then** I go to Home; **When** I press back on Home, **Then** the app exits
- [ ] **Given** routes `/home`, `/search`, `/library`, `/contribute`, `/settings`, **When** navigated to, **Then** the right screen opens; `/settings` opens above the shell from a gear icon in the Home header
- [ ] **Given** an unknown route, **When** navigated to, **Then** the C07 error state shows instead of a crash
- [ ] **Given** TalkBack, **When** focusing nav items and the gear icon, **Then** each has a localized label and a ≥ 44×44 target
- [ ] **Given** the root widget, **When** the app starts, **Then** it is wrapped in a Riverpod `ProviderScope`

## Technical Notes

- `StatefulShellRoute.indexedStack` with one branch per tab; router exposed as a Riverpod provider.
- Screens: `features/{home,search,library,contribute}/presentation/*_screen.dart`.
- Use Material 3 `NavigationBar` themed from `ZemaColors`, or a custom bar if needed to match the canvas.

## Dependencies

### Requires
- 003-theme-tokens-and-palettes, 005-localization-and-initial-locale

### Enables
- 007 (tab content), 008 (settings route)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Re-tapping the active tab | Pops that tab to its root |
| Very long translated labels | Labels ellipsize; bar height unchanged |

## Out of Scope

- Mini player above the bar (002), deep links from outside the app
