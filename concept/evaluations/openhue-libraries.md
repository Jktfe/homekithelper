# Evaluation: OpenHue Libraries

**Date:** 2026-03-19
**Repositories:**
- https://github.com/openhue/openhue-cli
- https://github.com/openhue/openhue-api

## Summary

Neither library is adopted. HomekitHelper's vendor-neutral HomeKit abstraction
makes Hue-specific tooling unnecessary for current goals. The OpenAPI spec is
bookmarked for potential future use.

## openhue-cli

**What:** Go CLI for controlling Philips Hue lights via the bridge REST API.
Includes an MCP server for AI assistant integration.

**Decision: Skip.**

- Written in Go — no code reuse with our Swift + Svelte/TypeScript stack.
- Bypasses HomeKit entirely, talking directly to the Hue bridge.
- Duplicates functionality HomeKit already provides, but only for Hue devices.
- MCP server feature is interesting but orthogonal to our bulk-configuration
  management goal.

## openhue-api

**What:** OpenAPI specification (YAML) for the Philips Hue CLIP v2 REST API.
Can generate typed clients in any language.

**Decision: Bookmark for later.**

The Hue v2 API exposes data HomeKit does not surface:
- Entertainment zones (Hue Sync, gradient segments)
- Motion sensor sensitivity tuning
- Firmware update management
- Bridge diagnostics

If we add a "vendor extras" or "power user" panel, we could generate a
TypeScript client from this spec and call the Hue bridge directly from the
web app (local network REST API). This would save significant
reverse-engineering effort.

## Why not adopt now

1. Breaks the vendor-neutral design — HomeKit is our abstraction layer.
2. Adds complexity for one brand only.
3. Requires separate Hue bridge authentication flow.
4. Current roadmap priorities (import, scenes, local HTTP sync) don't need it.
