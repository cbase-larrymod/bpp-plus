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

### Fixed
- Parser now correctly recognizes `GET#` as a valid keyword in addition to `GET`.
- Parser now recognizes BASIC time variables `TI$` and `TI` as valid keywords.
- Empty quoted strings (`""`) in `.bpp` files were not recognized correctly.
- `IF ... THEN` statements without `GOTO`/`GOSUB` were incorrectly parsed as jump commands.
- Parser correctly recognizes `::` as a separator instead of misinterpreting colons as part of code tokens.

### Removed
- Unwanted spaces in code

## [1.0.0] - 2025-09-11
### Forked
- From https://github.com/hbekel/bpp
