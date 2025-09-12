# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Fixed
### Removed

## [1.0.1] - 2025-09-11
### Added
- Bugfixes from [Larry/ROLE](https://github.com/cbmbas) to handle Commodore BASIC v2 and C\*BASE extensions
- CHANGELOG.md
- `@@buildControls` for handling build date stamping in Larry C*Base.
  - **Development (default):** outputs `Dev: YYYY-MM-DD, HH:MM    Larry Mod v3.1`
  - **Release:** outputs `Release: YYYY-MM-DD       Larry Mod v3.1`

### Fixed
- Parser now correctly recognizes `GET#` as a valid keyword in addition to `GET`.
- Parser now recognizes BASIC time variables `TI$` and `TI` as valid keywords.
- Empty quoted strings (`""`) in `.bpp` files were not recognized correctly.
- `IF ... THEN` statements without `GOTO`/`GOSUB` were incorrectly parsed as jump commands.
- Parser correctly recognizes `::` as a separator instead of misinterpreting colons as part of code tokens.
- Corrected color keyword spelling from **GREY** to **GRAY** to match Commodore BASIC v2 conventions (e.g., `GRAY1`, `GRAY2`, `GRAY3`).
- `GOSUB`/`GOTO` regex corrected: removed the trailing `+` from `[\w\s,.]+` to avoid capturing multiple label groups incorrectly.
  - **Before:** `^(?<code>go(sub|to))\s*(?<labels>[\w\s,.]+)+`
  - **After:**  `^(?<code>go(sub|to))\s*(?<labels>[\w\s,.]+)`

### Changed
- BASIC line numbering now **starts at 1** instead of the previous 0.

### Removed
- Unwanted spaces in code

## [1.0.0] - 2025-09-11
### Forked
- From https://github.com/hbekel/bpp
