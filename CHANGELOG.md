# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-25

First tagged release. A MATLAB satellite simulation suite: Keplerian orbit propagation
with ECI/ECEF/LLA transforms, ground tracks for a LEO and a GEO satellite, UAV localization
by image matching with a location encoder (Equal Earth projection and random Fourier
features), edge-based wavelet super-resolution, an interactive dashboard, and eight
`mcp_*` functions meant to be called from a MATLAB MCP server.

### Added
- Test suite in `tests/` (orbital mechanics, coordinate transforms, location encoder,
  satellite registry) run in CI on every push and pull request with base MATLAB R2025b.
- CI, CodeQL (workflows), OpenSSF Scorecard and a tag-triggered release workflow with build
  provenance; Dependabot for GitHub Actions.
- `SECURITY.md`, `CONTRIBUTING.md`, this changelog and a `VERSION` file.
- README badges, a Requirements section and a Development section.

### Fixed
- `location_encoder` returned `NaN` on the equator (0/0 in the Equal Earth denominator) and
  used the wrong polynomial terms for the projection's x coordinate; it now matches the
  published Equal Earth values.
- README quick start loaded `'LEO_1'`, which is not a satellite name; it now uses `'leo'`.

[Unreleased]: https://github.com/sergiudanstan/satellite-mcp-matlab/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/sergiudanstan/satellite-mcp-matlab/releases/tag/v0.1.0
