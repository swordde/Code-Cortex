# SNP Linux Audio Tap

This module hosts PipeWire monitor tap integration for wake-word audio capture.

## Scope

- Capture monitor audio frames from PipeWire as unprivileged user.
- Forward bounded audio chunks to local voice verification/enrollment service.
- Fail safely when device routes change.

## Constraints

- Monitor-only access.
- No audio injection.
- Respect user mode toggles before capture starts.
