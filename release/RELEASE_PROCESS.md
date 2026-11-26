# Release preferences

- CurseForge automatic publishing was confirmed working by Derek after the v1.0.4 tag push on November 25, 2026.
- Starting with the next release, use `PaladinTankKit-<version>.zip` as the CurseForge file's displayed name, matching the archive name, rather than displaying only a version tag such as `v1.0.4`.
- Leave the existing 1.0.4 release and tag unchanged. Check how the configured CurseForge packager derives the displayed name before the next release and apply the naming preference through the appropriate release setting or tag convention.
- Keep the TOC version, release notes, archive version and release tag consistent for each new release.
- For 1.0.5, publish the annotated tag `PaladinTankKit-1.0.5.zip` with `release/RELEASE_NOTES.md` as its message. CurseForge displayed the previous tag verbatim; use the archive-style tag name for the requested display name. Do not also push a second 1.0.5 tag, which could create a duplicate release.
