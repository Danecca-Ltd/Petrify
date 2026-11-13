# Petrify

Fusion add-in with buttons in **Solid → Modify**. Version 2.0.1.

*Called **Shrinkwrap** until v2.0.0 — see [Renamed from Shrinkwrap](#renamed-from-shrinkwrap).*

- **Petrify** turns the open part or assembly into one solid body in a new internal
  component, with the same mass and a marker at the original center of mass. On a design
  with a single visible body it fills that body's cavities in place instead (see
  *Single-body mode*).
- **Ordain Mass** gives the selected bodies an exact total mass by adjusting their
  material's density.
- **Petrify Updates** checks GitHub for a newer version and installs it (see *Updates*).

## Petrify dialog

- **Fill**
  - *Sealed cavities only*: fills cavities that are completely closed off. Any path to
    the outside, even a hairline clearance around a bolt or connector, leaves the inside
    hollow (the summary says so).
  - *Envelope (fill all internals)*: casts a grid of rays along X, Y and Z. Each ray only
    needs its first and last hit; everything more than one **wall thickness** inside
    them is filled, and the three axes are intersected. Small gaps and leaks don't
    matter. The outer skin is never touched: holes and pockets shallower than the wall
    thickness stay exactly as they are, deeper ones get a floor at that depth, and
    exterior pockets and the spaces between protruding parts stay open.
- **Wall thickness** (Envelope only, default 3 mm): set it to the enclosure's wall
  thickness or a little less. Too large leaves a hollow gap inside the walls; smaller is
  safe (the fill just overlaps the walls).
- **Detail** (Envelope only): ray grid, *Coarse* (default) = 50 cells along the longest
  side, *Normal* = 100, *Fine* = 200. Each step up is about 4× the rays and time. The fill
  reaches the walls at any setting; finer detail only follows small exterior features
  (like gaps between protruding parts) more closely.
- **Copy center of mass** (on by default, assembly mode only): add the "Center of mass"
  point.
- **Mass**: *Inherit from model* uses the original bodies' total mass (single-body mode:
  the body's current mass). *Set manually* lets you type a mass (kg by default; other units
  such as `500 g` or `25 lbmass` are converted); the material density is worked out from it.

The dialog remembers your last choices until Fusion is restarted. The summary ends with the
total time and a per-step breakdown.

The dialog also reminds you: **if Fusion freezes, restart it and run Petrify again**
(save first) — the part that caused the freeze is skipped automatically (see *Logs*).

## Assembly mode (what Petrify does)

1. Takes every **visible solid body** in the design, including bodies in sub-assemblies
   and referenced components. Hidden bodies and surface bodies are ignored. Components
   made by an earlier run (including Shrinkwrap runs) are ignored too.
2. Unites them into one solid. Faces where parts touch, and parts buried inside other
   parts, disappear.
3. Fills sealed internal cavities, and with Fill = Envelope everything enclosed.
4. Creates a new component `<name> petrified` holding the body (also named
   `<name> petrified`). In a parametric design it's one Base Feature in the timeline.
5. Copies the default material to `<name> material` and tunes its density so the
   petrified body's mass equals the original bodies' total mass, or the manual mass.
6. Optionally adds a construction point **Center of mass** at the original bodies'
   mass-weighted center of mass. This is the *original* center of mass; the petrified
   body's own center of mass (uniform density) will usually differ.

`<name>` is the document name without its version suffix. The source design is not
changed.

## Single-body mode

When the design has exactly one visible solid body — a petrified body with its source
parts hidden, or a one-body part — Petrify fills that body's cavities **in place** (the OK
button reads *Fill cavities*) and re-tunes the density so its mass stays the same, or
matches a manual mass. Use it as a second pass: hide the sources and run it on the
petrified body with a different wall thickness, or on any single-body part to
"de-swiss-cheese" it.

- A Petrify output in a parametric design has its Base Feature updated, so the timeline
  doesn't grow.
- Any other body is replaced by a new Base Feature plus a Remove feature for the old body.
  Anything that referenced the old body's faces (joints, sketches) will need re-linking.

## Ordain Mass

Select one or more solid bodies (the only visible body is preselected), type the total
mass, *Ordain mass*. The bodies get a material of their own — a copy of their current
material named `<component> material` (`<design> material` for root bodies), or the
existing one if it already has that name or was made by Petrify — and its density is
tuned so the selection weighs exactly that. Other bodies sharing the original material
are unaffected.

## Logs

Every Petrify and Ordain Mass run writes a log to `Documents\Petrify logs\` (the newest 30
are kept; the summary shows the file name). Each line is written to disk immediately, so
if Fusion freezes or crashes the log still ends with the step it was on — for example
`Union 57/58: "Sub / Bracket:1" (412 faces, ...)` with no `united` line after it means
Fusion got stuck uniting that body. Errors are logged with their full traceback.

**Freeze recovery.** Fusion's geometry engine can hang for good on some unions (typically
a nut whose bore sits exactly on a thread cylinder), and an add-in can't interrupt it.
So Petrify names each body in `union in progress.json` before uniting it and removes
the file afterwards. If Fusion dies mid-union, the next run finds the file, adds that body
to `problem bodies.json` for that design, and skips it from then on — the summary lists
skipped bodies, which are missing from the shape but still count towards the mass. One
freeze per problem body, never a repeat. To retry a body, delete its entry (or the whole
file); both files are in the log folder.

## Limits

- If Fusion can't unite a body (e.g. bad imported geometry), it's left out of the shape
  and listed in the summary; its mass still counts.
- Mass and center of mass come from the same visible bodies used for the geometry.
- Bodies in externally referenced components can't be refilled or have their mass set;
  open the referenced design instead.
- Every run is a single undo step and can be cancelled from the progress dialog.

## Install

Run `Deploy.bat`, then restart Fusion. It installs to
`%APPDATA%\Autodesk\ApplicationPlugins\Petrify.bundle` and removes an old
`Shrinkwrap.bundle` if there is one.

## Updates

The add-in updates itself from this GitHub repo (`petrify_updater.py`, following section
19 of the Fusion Plugin Development Guide):

- **At startup** it checks GitHub in the background (30 s after Fusion loads, so it never
  slows start-up). If a newer release exists it asks once per release: *Download and
  install it now?* Offline or any error: it stays silent.
- **Solid → Modify → Petrify Updates** checks on demand and offers to install.
- Installing downloads the release, checks it (complete bundle, version matches the
  tag), copies it next to the live bundle and swaps the two folders, restoring the old
  one if the swap fails. Restart Fusion to use the new version.
- The repo is public, so no GitHub login and no Git install are needed. A token already
  cached by Git Credential Manager is used if present (higher GitHub rate limit), but
  you're never prompted.

## Renamed from Shrinkwrap

Until v2.0.0 this add-in was **Shrinkwrap** (repo `Danecca-Ltd/Shrinkwrap`, which now
redirects here; buttons Shrinkwrap / Set Mass / Shrinkwrap Updates).

- **Existing installs move over by themselves.** Their updater only installs
  `Shrinkwrap.bundle`, so this repo keeps a small migration stub under that name. Old
  installs update into it; on the next Fusion start the stub installs Petrify, removes
  itself and asks for a restart. Keep the stub until no pre-2.0 installs are left.
- Petrify also removes a leftover full `Shrinkwrap.bundle` at startup (both share button
  IDs, so every click would run twice) and asks for a restart.
- Kept on purpose: the button IDs (`DaneccaShrinkwrapCmd`, ...), so toolbar
  customisations survive; and the hidden output marker (attribute group `Shrinkwrap`),
  so components made by Shrinkwrap are still recognised. Earlier outputs keep their
  `<name> shrinkwrap` names.
- The freeze skip list is copied from `Documents\Shrinkwrap logs` to `Documents\Petrify logs`.

## Releasing

1. `.\bump_version.ps1 X.Y.Z` — sets the version everywhere: Petrify's
   `PackageContents.xml` (×2), `Petrify.manifest` and `PETRIFY_VERSION`; the migration
   stub's files and its `SHRINKWRAP_VERSION` (pre-2.0 updaters refuse a release whose
   stub version differs from the tag); and this README. It also refreshes the stub's copy
   of the updater.
2. Commit and push.
3. Tag the commit `vX.Y.Z` and push the tag: `git tag vX.Y.Z; git push origin vX.Y.Z`.

Users get the update offered at their next Fusion start. An untagged commit is never
offered.
