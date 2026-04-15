# Godot Web Export Requirements

**Source:** Sprint 0 (Patch, S0-001)

## Problem
Godot web exports fail or produce broken builds if the renderer isn't set correctly.

## Solution
- Use `gl_compatibility` renderer in `project.godot` (`renderer/rendering_method="gl_compatibility"`)
- Vulkan (default) does NOT work for HTML5/web exports
- Export preset must target "Web" platform with `variant/thread_support=false` for broadest browser compatibility

## Also
- Headless browsers (CI) lack WebGL — Godot stays in loading state. This is expected, not a bug.
- Godot's HTML shell hides `<body>` until WASM engine loads. Test for canvas presence in DOM, not body visibility.
