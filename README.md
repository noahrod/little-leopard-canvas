# Little Leopard Canvas

Little Leopard Canvas is a Godot coloring app for a child and the Lowell
Elementary School classroom in Waukesha, Wisconsin. Its intended audience
includes 4K, 5K, and elementary-school children. The intended device is a
Fire tablet, used primarily with fingers, although a mouse can be used on a
desktop. The visual theme uses Lowell Leopards imagery and blue, yellow,
white, and orange-red.

## Current status

The app runs in the Godot editor and has an offline drawing canvas, local
profiles, signed PNG saves, and an in-app gallery. It is designed for a
landscape tablet, but the current project settings do **not** explicitly lock
the handheld orientation. An Android export preset exists, but an installed
Fire-tablet build and touch interaction have not been verified here. This is
not yet a finished distribution or sharing workflow.

## Run the project

1. Open this folder as a project in **Godot 4.7**. The project was tested with
   Godot 4.7.2; let the editor import the assets.
2. Press **Run Project** (F5). The configured main scene is
   [`main.tscn`](main.tscn).
3. Use a mouse on desktop or touch on a supported device. The layout is
   designed around a 1280 × 800 landscape viewport.

To try it on a Fire tablet, configure Godot's Android export environment and
export templates, review the **Android** preset in **Project → Export**, and
export an APK. The preset targets ARM64 and currently uses
`target/android/little-leopard-canvas.apk` as its local export path.
Installing an APK may require changing the Fire tablet's installation settings.
Device compatibility, signing, orientation, and touch behavior still need to
be tested on the actual tablet. A Web preset also exists, but the Web export
has not been validated as part of this work.

### Build a test APK with GitHub Actions

The manually triggered [Android APK workflow](.github/workflows/android-apk.yml)
imports the project with Godot 4.7.2, runs headless regression tests, exports
the Android preset, checks the APK signature, and uploads the APK both as a
workflow artifact and to a new **pre-release**. It uses Java 17 and Android
SDK tools on a GitHub-hosted Linux runner. The graphical signature test is not
run in this headless workflow.

1. Put the project in a GitHub repository and push the workflow and project
   files to the default branch. This workspace has not yet been connected to
   a Git repository.
2. Enable GitHub Actions and allow the repository's `GITHUB_TOKEN` to write
   repository contents and create releases. No signing secrets are needed.
3. In **Actions → Build Android APK → Run workflow**, select the branch or tag
   to build and enter a **new** version tag, such as `v1.0.0-test.1`. Existing
   tags are rejected; choose a different tag for each run. The new tag points
   at the selected source commit.
4. Download `little-leopard-canvas-debug.apk` from the resulting pre-release,
   or download the workflow artifact from the run. Install it on a compatible
   ARM64 Fire tablet and verify it there.

**Important: this is a debug-signed test build, not a production release.**
Every run generates a different temporary signing key, so Android normally
will not install a later APK as an update over an earlier one. Uninstalling
the earlier app or clearing its data may delete local artwork and profiles.
Back up data first; the app does not yet provide a built-in backup feature.
For reliable upgrades and distribution, configure a persistent release signing
key using secure GitHub Secrets and review the package identifier and version
settings before publishing. Do not commit keys or passwords to the repository.
A local debug APK export and signature check passed with Godot 4.7.2, but the
workflow itself has not yet been run on GitHub. Fire-tablet installation and
touch behavior remain unverified.

## How to use it

### Draw

- Choose a page at the bottom: **School**, **Lowell**, **Leopard**, **Paw**,
  **Art Club** (the app icon), or **Blank**. School opens first. Changing pages asks for confirmation and
  clears the current drawing and its undo history.
- Choose **Brush**, **Fill**, **Stamp**, or **Eraser** on the left. The eraser
  restores the original page under the erased area.
- Choose a palette color or use **More Colors** for additional light/dark
  shades and a color wheel. **Glitter** adds a static sparkle pattern to brush,
  fill, and stamp marks. Choose S, M, or L for brush and stamp size.
- Stamps include paw, star, heart, leopard head, sun, and flower. Tapping a
  stamp also selects the stamp tool.
- **Undo** keeps up to 12 changes. **Clear** asks for confirmation and can be
  undone until it falls out of the undo history.

Fill colors a connected region of similar color. The coloring pages were
derived from existing images, so small shapes or gaps in outlines can make
some areas difficult to fill or allow a fill to spread.

### Profiles and saved art

1. Tap **Profiles** and create or select an artist. Enter a name of up to
   32 characters and select 4K, 5K, or 1st through 5th grade. Multiple
   profiles can be stored on the same device.
2. Tap **Save Art**. A selected profile is required. The saved PNG gets a
   signature strip **below** the drawing showing the app icon and selected name and grade;
   the editable canvas itself is unchanged.
3. Tap **Gallery** to view saved pictures, newest first, using **Newer** and
   **Older**. The gallery includes older unsigned artwork and artwork from
   every profile on the device; it is not filtered by artist. Viewing a
   picture does not change the active canvas.

Profiles can be edited or deleted; deleting one does not delete or rename
existing pictures. Profile data and pictures are local to the app. A child's
name and grade appear in the saved image, so they will be visible to anyone
the picture is shared with. The app does not currently upload anything.

## Storage and limitations

Godot's `user://` is app-specific storage, not the tablet's photo gallery.
Its physical location depends on the platform and app installation. Uninstalling
the app or clearing its data may remove these files; make backups before doing
so. No built-in backup or export-to-photos flow exists yet.

| File in `user://` | Purpose |
| --- | --- |
| `profiles.json` | Local list of names/grades and selected profile index. |
| `artwork_<timestamp>_<ticks>.png` | Each current signed save; older versions may lack the ticks suffix or signature. |
| `last_art.png` | Latest signed PNG copy; not shown as a separate gallery item. |

The gallery discovers `artwork_*.png` files and sorts by file modification time,
with filename as a tie-breaker. It displays an error for an unreadable image and
still allows navigation. The latest-copy PNG is **not** an editable project or
an automatic resume mechanism.

**Not implemented:** reopening a saved image for editing, autosave/resume,
gallery filtering or deletion, Android share sheet, public photo-gallery
export, cloud sync, classroom server, or cross-device sharing. PNGs are flat
images rather than editable layered projects. Actual Fire-tablet performance,
layout, file persistence, rendering, and touch use need device testing.

## Project map for maintainers and AI assistants

| Path | Responsibility |
| --- | --- |
| [`project.godot`](project.godot) | Godot 4.7 project settings, main scene, viewport and mobile renderer. |
| [`export_presets.cfg`](export_presets.cfg) | Android and Web export presets; inspect in Godot before distributing. |
| [`.github/workflows/android-apk.yml`](.github/workflows/android-apk.yml) | Manually builds and publishes a debug-signed Android APK. |
| [`main.tscn`](main.tscn) | Root `Control`; most UI nodes are created in code. |
| [`scripts/main.gd`](scripts/main.gd) | Page list, theme/layout, tools, profiles UI, save flow, dialogs, and gallery entry point. |
| [`scripts/drawing_canvas.gd`](scripts/drawing_canvas.gd) | Input, 840 × 520 raster canvas, fill, brush, stamps, eraser, undo, and signed-image composition. |
| [`scripts/signature_footer.gd`](scripts/signature_footer.gd) | Draws the signature strip into a `SubViewport`; signed output is 840 × 600. |
| [`scripts/profile_store.gd`](scripts/profile_store.gd) | Profile validation, local JSON loading, and writes via a temporary file and rename. |
| [`scripts/art_gallery.gd`](scripts/art_gallery.gd) | Local PNG enumeration, preview, navigation, and errors. |
| [`assets/`](assets/) | Original school images, derived coloring pages, and UI icons. |
| [`tests/`](tests/) | Godot script-based regression tests. |
| [`addons/ai_copilot/`](addons/ai_copilot/) | Editor add-on, separate from the app's drawing features. |

The canvas maintains `base_image` (original page), `artwork` (visible pixels),
and `fill_image` (flat-color reference so glitter can be filled again).
Undo stores snapshots of both working images. When modifying drawing tools,
keep these images synchronized, and verify undo, eraser, fill, glitter, and
PNG output. Page selection resets the base and history. The canvas handles
one active touch index; its desktop mouse input is gated on touchscreen
availability.

The signed-save flow snapshots the artwork, renders a footer using the
rendering server, and writes both a timestamped PNG and `last_art.png`.
Treat user-facing save and profile errors explicitly; a failed profile load
disables profile changes rather than overwriting the existing file. Avoid
changing on-disk formats or deleting user artwork without a migration and an
explicit product decision.

### Assets

- The original school images in [`assets/`](assets/) are retained. Do not
  replace or delete them when adjusting coloring pages.
- Current pages are `assets/coloring/school_clean.png`,
  `banner_clean.png`, `mascot.png`, `pto.png`, and `app_icon_outline.png`;
  the sixth page is blank. The app icon outline source is
  `assets/coloring/app_icon_outline.svg`.
  Earlier `school.png` and `banner.png` conversions are retained.
- The original `assets/mascot.png` is a JPEG despite its `.png` extension and
  does not import correctly as a PNG in Godot. `mascot_converted.png` is a
  separate converted copy used to make the coloring page.
- `assets/ui/leopard_stamp.png` is a retained earlier asset. The current
  leopard stamp is a programmatic spotted head, not that image.
- [`assets/app_icon/little_leopard_canvas.png`](assets/app_icon/little_leopard_canvas.png)
  is the project icon. [`assets/app_icon/artwork.svg`](assets/app_icon/artwork.svg)
  contains its base illustration; the two title lines are rendered into the
  PNG separately. The folder also contains 192 × 192 legacy and 432 × 432
  adaptive foreground/background images, but the current Android preset's
  launcher-icon fields are empty. The old root `icon.svg` and original school
  assets remain unchanged. Launcher appearance still needs verification on
  the Fire tablet.
- Respect the intended young audience and school branding; use large touch
  targets, preserve the current artwork when opening dialogs, and avoid
  introducing networking or sharing of children's information by default.

## Tests and verification

Run these from the project directory with `godot` on `PATH`:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_canvas.gd
godot --headless --path . --script res://tests/test_profiles.gd
godot --headless --path . --script res://tests/test_gallery.gd
```

The gallery test intentionally opens a corrupt PNG to test error handling;
Godot logs warnings/errors for that expected case before reporting success.
The signature test needs a working graphical renderer:

```sh
godot --path . --script res://tests/test_signature.gd
```

The tests cover drawing operations, fill boundaries, undo, layout bounds,
profile validation and persistence, gallery navigation, and rendered
signatures. They do not replace hands-on tablet testing. Before distribution,
check the landscape layout and dialogs, touch drawing, fill speed, profile
keyboard/selection, save and gallery after an app restart, and Android export
and installation on the target Fire tablet.
