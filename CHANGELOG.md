# Changelog
All notable changes to this project will be documented in this file.


## [1.0.2] - 2025-09-13
### Added
- Support for statement chaining with `\` in `.bpp` files.

**Examples:**
  ```basic
  'BPP+'v
  poke 53281,0\
  poke 53280,0\
  print "Hello BPP+";

  'Will outout normal BASIC v2'
  poke 53281,0:poke 53280,0print "Hello BPP+";
  ```

## [1.0.1] - 2025-09-12
### Added
- `@@buildControls` for handling build date stamping in Larry C\*Base.
  - **Development (default):** outputs `Dev: YYYY-MM-DD, HH:MM    Larry Mod v3.1`
  - **Release:** outputs `Release: YYYY-MM-DD       Larry Mod v3.1`
  - Use `{buildstamp}` in your `.bpp` file to insert the current build type, date and time. The time is included for _Development_ builds, but not for _Release_ builds.

  **Examples:**
  ```basic
  print "{buildstamp}"

  'Default mode in C*Base Larry Mod v3.1 - Build system'
  Outputs: Dev: 2025-09-12, 14:35    Larry Mod v3.1

  'Release mode in C*Base Larry Mod v3.1 - Build system'
  Outputs: Release: 2025-09-12       Larry Mod v3.1
  ```
- Preprocessor now supports **recursive paths** when including source files.  
  You can include files in the same directory or in a sub-directory using relative paths.

  **Examples:**
    ```basic
    {!include source "filename.bpp"}                     # include a file in the same directory
    {!include source "sub-directory/filename.bpp"}       # include a file in a sub-directory
    {!include source "../sub-directory/filename.bpp"}    # include a file in a sub-directory using parent path
    ```

- Bugfixes from [Larry/ROLE](https://github.com/cbmbas) to handle Commodore BASIC v2 and C\*Base extensions
- CHANGELOG.md

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
- Labels now support **hyphens** and **camelCase** in addition to letters, digits, and underscores.  
  Labels must start with a letter or underscore and **cannot** be a reserved keyword.

  **Examples:**
  ```basic
  label:
  _label:

  longLabel:
  _longLabel:

  long-label:
  _long-label:
  ```

- BASIC line numbering now **starts at 1** instead of the previous 0.

### Removed
- Unwanted spaces in code

## [1.0.0] - 2025-09-11
### Forked
- From https://github.com/hbekel/bpp

---

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

```
### [Unreleased]
### Added
### Changed
### Fixed
### Removed
```