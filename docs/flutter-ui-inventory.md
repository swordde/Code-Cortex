# Flutter UI Inventory

This file captures the current Flutter UI implemented in this repository.

## App Shell

- Entry point: [lib/main.dart](lib/main.dart)
- Root app widget: [lib/app.dart](lib/app.dart)
- Theme mode: system (light and dark)
- Seed color: `#1F6F68`
- Home screen: `MainDashboardScreen`

## Screens

### 1) Main Dashboard

- File: [lib/screens/main_dashboard_screen.dart](lib/screens/main_dashboard_screen.dart)
- Type: Stateful, simulated live updates every 5 seconds
- Primary sections:
  - AppBar with profile action
  - Quick filter icon row
  - Today's notification summary card
  - 4 priority cards (Emergency, High, Medium, Low)
  - Wellbeing section summary
  - Center FAB for AI quick action
- Navigation:
  - Profile button -> Profile screen
  - Long press body -> Custom Mode screen
  - Priority card tap -> Category notification list
- Priority scoring:
  - Emergency >= 90
  - High >= 70
  - Medium >= 45
  - Low < 45

### 2) Notification List Screen

- File: [lib/screens/notification_list_screen.dart](lib/screens/notification_list_screen.dart)
- Type: Stateless
- Behavior:
  - Shows title based on selected category
  - Empty state text when list is empty
  - Card list with source and computed score

### 3) Profile Screen

- File: [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart)
- Type: Stateful
- UI blocks:
  - Profile header area with avatar and user details
  - Add account/integration CTA
  - Connected integrations list (sample: WhatsApp, Gmail)
  - Settings toggles (Cortex Mode, Auto-Reply)
  - Custom bottom icon strip visual

### 4) Custom Mode Screen

- File: [lib/screens/custom_mode_screen.dart](lib/screens/custom_mode_screen.dart)
- Status: Placeholder UI

### 5) Wellbeing Screen

- File: [lib/screens/wellbeing_screen.dart](lib/screens/wellbeing_screen.dart)
- Status: Placeholder UI

## Shared Widgets

### Priority Card

- File: [lib/widgets/priority_card.dart](lib/widgets/priority_card.dart)
- Purpose: reusable priority tile with count and subtitle

### Quick Filter Dot

- File: [lib/widgets/quick_filter_dot.dart](lib/widgets/quick_filter_dot.dart)
- Purpose: small circular icon chip for filter shortcuts

### Today's Notification Card

- File: [lib/widgets/today_notification_card.dart](lib/widgets/today_notification_card.dart)
- Purpose: top summary card with attention count and circular focus indicator

### Wellbeing Section

- File: [lib/widgets/wellbeing_section.dart](lib/widgets/wellbeing_section.dart)
- Purpose: analytics panel with mini weekly visuals and stats

## Data Model

- File: [lib/models/app_notification.dart](lib/models/app_notification.dart)
- Contains:
  - NotificationCategory enum
  - AppNotification model (title, source, urgency, rule boost, timestamp)

## Visual Theme Summary

- Core accent family: teal + warm amber support
- Priority palette pattern:
  - Emergency: red family
  - High: amber family
  - Medium: teal/cyan family
  - Low: neutral gray family
- Card-heavy dashboard design with rounded surfaces and soft contrast

## Current Completeness

- Implemented and visually active:
  - Main dashboard
  - Notification list
  - Profile screen
  - Shared widget system
- Placeholder only:
  - Custom mode screen
  - Wellbeing screen
