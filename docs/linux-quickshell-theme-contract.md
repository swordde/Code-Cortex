# Linux QuickShell Theme Contract

This contract keeps Linux QuickShell UI aligned with the Flutter dashboard visual language.

## Scope

Applies to:
- popup cards
- action buttons
- priority badge colors
- notification center panel
- wellbeing overlay panel

Does not change:
- popup content fields
- priority routing logic
- queue and auto-dismiss behavior

## Source of Truth

Flutter reference palette source:
- lib/screens/main_dashboard_screen.dart

QuickShell token source:
- platform/linux/quickshell/components/PopupTheme.js

QuickShell consumers:
- platform/linux/quickshell/components/NotificationPopup.qml
- platform/linux/quickshell/components/ActionBar.qml
- platform/linux/quickshell/components/PriorityBadge.qml
- platform/linux/quickshell/components/NotificationCenter.qml
- platform/linux/quickshell/components/WellbeingOverlay.qml
- platform/linux/quickshell/main.qml

## Active Preset

Use preset: projectCore

Set in:
- platform/linux/quickshell/main.qml via popupPreset

## Token Mapping (Flutter -> QuickShell)

### Priority card background mapping

- Emergency background: 0xFF462A2A -> popupBackground(projectCore, EMERGENCY)
- High background: 0xFF4A3D21 -> popupBackground(projectCore, HIGH)
- Medium background: 0xFF203A3A -> popupBackground(projectCore, MEDIUM)
- Low background: 0xFF2D3033 -> popupBackground(projectCore, LOW)

### Priority accent mapping

- Emergency accent: 0xFFFF8E86 -> popupBorder(projectCore, EMERGENCY), countColorByPriority(projectCore, EMERGENCY)
- High accent: 0xFFFFC45A -> popupBorder(projectCore, HIGH), countColorByPriority(projectCore, HIGH)
- Medium accent: 0xFF74D7D7 -> popupBorder(projectCore, MEDIUM), countColorByPriority(projectCore, MEDIUM)
- Low accent: 0xFFBCC2C7 -> popupBorder(projectCore, LOW), countColorByPriority(projectCore, LOW)

### Priority label color mapping

- Emergency label family: 0xFFBD3124 -> badgeColor(EMERGENCY, projectCore)
- High label family: 0xFFB56D00 -> badgeColor(HIGH, projectCore)
- Medium label family: 0xFF1A6666 -> badgeColor(MEDIUM, projectCore)
- Low label family: 0xFF767676 -> badgeColor(LOW, projectCore)

### Surface and typography mapping

- Main panel surface -> panelBackground(projectCore)
- Main panel border -> panelBorder(projectCore)
- Title text -> titleColor(projectCore)
- Subtitle text -> subtitleColor(projectCore)
- Body text -> bodyColor(projectCore)

### Action button mapping

- Button background -> buttonBackground(projectCore)
- Button hover -> buttonHoverBackground(projectCore)
- Button border -> buttonBorder(projectCore)
- Button text -> buttonText(projectCore)

## Responsive Contract (Desktop)

NotificationCenter width:
- 28 percent of host width
- min 300, max 420

Wellbeing width:
- 24 percent of host width
- min 280, max 380

Popup width:
- fixed 360 for current release

## Engineering Rules

1. No hardcoded UI colors in QuickShell components when a token exists.
2. All priority-dependent visuals must use the priority token functions.
3. If Flutter palette changes, only update PopupTheme.js projectCore tokens first.
4. Keep popup content structure unchanged while doing visual adjustments.
5. Validate both modes before merge:
- scripts/run_quickshell_mock.sh
- scripts/run_quickshell_live.sh

## Validation Checklist

- Popup colors match Flutter priority card family.
- Badge colors match Flutter priority semantics.
- NotificationCenter and Wellbeing use same projectCore surfaces.
- Desktop resize keeps panel widths within defined clamps.
- Popup queue and auto-dismiss behavior unchanged.

## Change Workflow

1. Update Flutter palette references if needed.
2. Update projectCore tokens in PopupTheme.js.
3. Run mock mode for visual check.
4. Run live mode for integration check.
5. Commit with message prefix: theme(linux).
