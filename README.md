# Little Leopard Canvas

Little Leopard Canvas is a Godot coloring app for a child and the Lowell
Elementary School classroom in Waukesha, Wisconsin. Its intended audience
includes 4K, 5K, and elementary-school children. The intended device is a
Fire tablet, used primarily with fingers, although a mouse can be used on a
desktop. The visual theme uses Lowell Leopards imagery and blue, yellow,
white, and orange-red.

## Current status

The app runs in the Godot editor and has an offline drawing canvas, local
profiles, English and Spanish settings, a first-time setup wizard, signed PNG
saves, an in-app gallery, and user-initiated picture export. It is designed
for a landscape tablet, but the current project settings do **not**
explicitly lock the handheld orientation. The app has been tested by the
family on a Fire tablet; the latest changes still need device verification.
This is not yet a finished distribution or sharing workflow.

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
be tested on the actual tablet.

### Publish the web app with GitHub Pages

The [Web App workflow](.github/workflows/pages.yml) exports the Web preset
with Godot 4.7.2 and deploys it to GitHub Pages on pushes to `main`. It can
also be started manually from **Actions → Publish Web App → Run workflow**
on `main`.

1. Push the workflow and project changes to GitHub.
2. In the repository's **Settings → Pages**, set **Build and deployment →
   Source** to **GitHub Actions**. Enable Actions if needed.
3. Check the workflow run under **Actions**. After a successful deployment,
   the expected address for this repository is
   `https://noahrod.github.io/little-leopard-canvas/`. The deployment job
   also displays the actual URL.

The Web export uses the Compatibility renderer and has thread support and
extension support disabled, so it does not require cross-origin isolation
headers that GitHub Pages cannot configure. The on-screen keyboard option is
experimental; check profile name entry on the target tablet. Browser graphics
and touch support, save persistence, and performance must be tested on the
target Fire tablet. Web profiles and artwork are stored in the browser's
site-specific storage, separately from the Android app; clearing site data,
private browsing, or browser storage eviction may remove them. Pictures can
be downloaded individually from the gallery; there is no bulk backup, sync,
or direct share sheet. This Web build is not configured for offline use.

### Build a test APK with GitHub Actions

The manually triggered [Android APK workflow](.github/workflows/android-apk.yml)
imports the project with Godot 4.7.2, runs headless regression tests, exports
the Android preset, checks the APK signature, and uploads the APK both as a
workflow artifact and to a new **pre-release**. It uses Java 17 and Android
SDK tools on a GitHub-hosted Linux runner. The graphical signature test is not
run in this headless workflow.

1. Push the workflow and project files to the default branch of the GitHub
   repository.
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
Export pictures first where supported; the app does not provide a bulk backup
or profile export.
For reliable upgrades and distribution, configure a persistent release signing
key using secure GitHub Secrets and review the package identifier and version
settings before publishing. Do not commit keys or passwords to the repository.
A local debug APK export and signature check passed with Godot 4.7.2. Verify
the latest workflow changes, installation, and touch behavior on the target
Fire tablet.

## How to use it

### Draw

- Tap **New** to choose **School**, **Lowell**, **Leopard**, **Paw**,
  **Art Club** (the app icon), or **Blank**. Use the arrows to see more pages.
  School opens first. Starting a page asks for confirmation and clears the
  current drawing and its undo history, even when choosing the same page.
- Choose **Brush**, **Fill**, **Stamp**, **Eraser**, **Text**, or **Zoom** using the
  icons on the left. The eraser restores the original page under the erased
  area. For text, type words, tap **Place Words**, then tap the canvas to
  place them. Choose a color before preparing the text. Undo removes a
  placement.
- Dark outlines from the original page stay visible when drawing, filling,
  stamping, adding text, or erasing. Lighter antialiased edges may be colored.
  The Blank page remains completely drawable.
- Choose a palette color or use **More Colors** for additional light/dark
  shades and a color wheel. **Glitter** adds a static sparkle pattern to brush,
  fill, and stamp marks. The narrow three-column palette leaves more space for
  the page while keeping larger color and stamp touch targets. Choose S, M,
  or L for brush and stamp size.
- Stamps include paw, star, heart, leopard head, sun, and flower. Tapping a
  stamp also selects the stamp tool.
- Tap the magnifying glass, then tap the canvas to zoom in (up to 4×); drag
  the canvas to move around. Tap the **minus** button to zoom out. Select
  another tool to draw or fill while zoomed. A new page resets the zoom;
  saved pictures always include the entire page.
- The curved-arrow **Undo** button keeps up to 12 changes. **Clear** asks for confirmation and can be
  undone until it falls out of the undo history. Undo and Clear are separated
  in the header to reduce accidental taps.

Fill colors a connected region of similar color. The coloring pages were
derived from existing images, so small shapes or gaps in outlines can make
some areas difficult to fill or allow a fill to spread.

### Setup, language, and saved art

On a new installation, a welcome wizard displays the app icon, asks for
English or Spanish, and requires an artist name and grade before drawing.
An existing installation with profiles or saved artwork skips the wizard and
keeps its data. If setup was interrupted after a profile was saved, select
that artist to finish.

1. Tap **Settings** to choose English or Spanish. Under **Manage artists**,
   select an artist, or tap **New Artist** to reveal
   the creation form. Enter a name of up to 32 characters and select 4K, 5K,
   or 1st through 5th grade. Selecting an existing artist also shows their
   details for editing. The new-artist fields stay hidden until **New Artist**
   is tapped. Multiple profiles can be stored on the same device.
2. Tap **Save Art**. A selected profile is required. The saved PNG gets a
   signature strip **below** the drawing showing the app icon and selected name and grade;
   the editable canvas itself is unchanged. A large confirmation appears after
   saving. Repeated taps without a new edit, artist, or language change reopen the
   confirmation instead of creating another copy during that app session.
   The signature text uses the chosen language.
3. Tap **Gallery** to view saved pictures, newest first, using **Newer** and
   **Older**. The gallery includes older unsigned artwork and artwork from
   every profile on the device; it is not filtered by artist. Viewing a
   picture does not change the active canvas.
4. To share a picture outside the app, select it in Gallery and tap **Export**.
   On Android 10 or later this requests a copy in
   `DCIM/Camera`, intended to make it easier to find in the camera roll;
   open the device's Photos, gallery, or Files app to share it. Older Android
   versions report that this export is unsupported.
   On the Web, Export requests a PNG download; on desktop, it asks where to
   save a copy. Export now shows a prominent success or error message. The
   cause of the reported missing pictures is not yet confirmed, and Android
   export and Fire tablet gallery visibility still need testing on the device.

Profiles can be edited or deleted; deleting one does not delete or rename
existing pictures. Profile data and pictures are local to the app. A child's
name and grade appear in the saved image, so they will be visible to anyone
the picture is shared with. The app does not currently upload anything.
Settings and Gallery use larger close buttons and action buttons for touch.

## Storage and limitations

Save Art writes to Godot's app-specific `user://`, not directly to the
tablet's photo gallery; use **Gallery → Export** for a separate copy.
Its physical location depends on the platform and app installation. Uninstalling
the app or clearing its data may remove these files; make backups before doing
so. Export individual pictures before uninstalling if your device supports it;
there is no bulk backup or profile export.

| File in `user://` | Purpose |
| --- | --- |
| `profiles.json` | Local list of names/grades and selected profile index. |
| `settings.cfg` | Selected language and first-time setup completion. |
| `artwork_<timestamp>_<ticks>.png` | Each current signed save; older versions may lack the ticks suffix or signature. |
| `last_art.png` | Latest signed PNG copy; not shown as a separate gallery item. |

The gallery discovers `artwork_*.png` files and sorts by file modification time,
with filename as a tie-breaker. It displays an error for an unreadable image and
still allows navigation. The latest-copy PNG is **not** an editable project or
an automatic resume mechanism.

**Not implemented:** reopening a saved image for editing, autosave/resume,
gallery filtering or deletion, Android share sheet, cloud sync, classroom
server, or automatic cross-device sharing. PNGs are flat
images rather than editable layered projects. Actual Fire-tablet performance,
layout, file persistence, rendering, and touch use need device testing.

## Project map for maintainers and AI assistants

| Path | Responsibility |
| --- | --- |
| [`project.godot`](project.godot) | Godot 4.7 project settings, main scene, viewport and mobile renderer. |
| [`export_presets.cfg`](export_presets.cfg) | Android and Web export presets; inspect in Godot before distributing. |
| [`.github/workflows/android-apk.yml`](.github/workflows/android-apk.yml) | Manually builds and publishes a debug-signed Android APK. |
| [`.github/workflows/pages.yml`](.github/workflows/pages.yml) | Builds and deploys the Web export to GitHub Pages. |
| [`main.tscn`](main.tscn) | Root `Control`; most UI nodes are created in code. |
| [`scripts/main.gd`](scripts/main.gd) | Page list, theme/layout, tools, profiles UI, save flow, dialogs, and gallery entry point. |
| [`scripts/drawing_canvas.gd`](scripts/drawing_canvas.gd) | Input, 840 × 520 raster canvas, fill, brush, stamps, eraser, undo, and signed-image composition. |
| [`scripts/signature_footer.gd`](scripts/signature_footer.gd) | Draws the signature strip into a `SubViewport`; signed output is 840 × 600. |
| [`scripts/profile_store.gd`](scripts/profile_store.gd) | Profile validation, local JSON loading, and writes via a temporary file and rename. |
| [`scripts/settings_store.gd`](scripts/settings_store.gd) | Language and setup state, validated and written through a temporary file. |
| [`assets/translations.csv`](assets/translations.csv) | English/Spanish strings imported by Godot into translation resources. |
| [`scripts/art_gallery.gd`](scripts/art_gallery.gd) | Local PNG enumeration, preview, navigation, and errors. |
| [`scripts/art_export.gd`](scripts/art_export.gd) | Android 10+ MediaStore copy to the public pictures library. |
| [`scripts/touch_dialog.gd`](scripts/touch_dialog.gd) | Larger embedded-window close icons and dialog action buttons. |
| [`assets/`](assets/) | Original school images, derived coloring pages, and UI icons. |
| [`tests/`](tests/) | Godot script-based regression tests. |
| [`addons/ai_copilot/`](addons/ai_copilot/) | Editor add-on, separate from the app's drawing features. |

Godot imports the CSV into generated `.translation` resources, which are
ignored by Git. After a fresh checkout, import the project before running tests
or exporting; edit the CSV rather than the generated translations. Profile
grades remain stored using their original English identifiers and are
translated for display, preserving existing profiles.

The canvas maintains `base_image` (original page), `outline_mask` (immutable
dark page pixels), `artwork` (visible pixels), and `fill_image` (flat-color
reference so glitter can be filled again). Every tool preserves masked pixels;
fill treats them as barriers, including when a child taps directly on one.
Undo stores snapshots of both working images. When modifying drawing tools,
keep these images synchronized, and verify undo, eraser, fill, glitter, and
PNG output. Page selection resets the base and history. The canvas handles
one active touch index; its desktop mouse input is gated on touchscreen
availability. Zoom changes only the rendered source rectangle and input
mapping, not the underlying image or saved output.

The signed-save flow snapshots the artwork, renders a footer using the
rendering server, and writes both a timestamped PNG and `last_art.png`.
The UI tracks the saved artwork revision, profile, and language to prevent repeated
unchanged saves in the same session; signing snapshots the image and revision
before awaiting the rendering server.
Treat user-facing save and profile errors explicitly; a failed profile load
disables profile changes rather than overwriting the existing file. Avoid
changing on-disk formats or deleting user artwork without a migration and an
explicit product decision.

### Assets

- The header title uses the rounded Fredoka typeface at bold weight. The
  bundled font in [`assets/fonts/`](assets/fonts/) is licensed under the
  [SIL Open Font License](assets/fonts/Fredoka-OFL.txt).
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
  PNG separately. The same icon and school-blue background are used for the
  Godot boot splash and Web loading screen. The Android system splash uses
  the padded `android_foreground.png` on the same blue background; its exact
  appearance depends on the device. The Android preset also uses the blue
  adaptive launcher background, which supplies the system splash background
  in the standard APK export. Its other launcher-icon fields remain empty.
  The old root `icon.svg` and original school
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
godot --headless --path . --script res://tests/test_settings.gd
```

The gallery test intentionally opens a corrupt PNG to test error handling;
Godot logs warnings/errors for that expected case before reporting success.
The signature test needs a working graphical renderer:

```sh
godot --path . --script res://tests/test_signature.gd
godot --path . --script res://tests/test_text.gd
godot --path . --script res://tests/test_save.gd
```

The save and settings tests intentionally attempt writes to missing folders to
verify error handling. The tests cover drawing operations, fill boundaries,
zoom, undo, layout bounds, first-time setup and language persistence, profile
validation, gallery navigation and export, text placement, and rendered
signatures. They do not replace hands-on tablet testing. Before distribution,
check setup and both languages, the landscape layout and dialogs, touch
drawing, fill speed, profile keyboard/selection, save and gallery after an app
restart, and Android export and installation on the target Fire tablet.
