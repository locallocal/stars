# Changelog

All notable user-visible changes to Stars are documented here. The format is
based on Keep a Changelog, and the project uses semantic versioning.

## [Unreleased]

### Added

- GitHub Actions quality gates for locked dependency resolution, localization
  generation, formatting, analysis, architecture/database tests, the complete
  test suite, and a Linux release build.
- Public security, contribution, conduct, and licensing policies.
- Localization key/placeholder parity checks and a smoke test for every
  supported locale.

### Changed

- Delayed the Linux window until Flutter renders its first frame, preventing
  startup key events from producing invalid framework-response JSON warnings.
- Isolated databases, conversation files, and recovery snapshots under the
  app-specific `Documents/Stars` directory. On first launch, Stars now migrates
  a valid legacy database or recovers its own validated backup when another
  application has replaced the old shared `Documents/app.db` file.
- Fixed Bot creation with bundled system Skills by allowing their bindings and
  conversation pins without creating editable installation records.
- Fixed system Skill runs by exempting Stars' read-only Skill/MCP inventory
  queries from approval and omitting empty failed responses from model history.
- Moved compact Add Bot error alerts above the footer action surface so they
  remain visually separate and cannot resize the footer actions.
- Relicensed Stars from the MIT License to the GNU Affero General Public
  License v3.0 only (`AGPL-3.0-only`).
- Unified the application identifier as `io.github.locallocal.stars` on all
  release platforms and added migration reads for legacy Apple secure-storage
  namespaces.
- Standardized localization generation on `intl_utils` and the Italian catalog
  name on `intl_it_IT.arb`.
- Removed unused direct dependencies identified by the engineering audit.

### Documentation

- Updated desktop architecture, quality commands, release conventions, and
  local/CI cache guidance to match the current implementation.

[Unreleased]: https://github.com/locallocal/stars/commits/main
