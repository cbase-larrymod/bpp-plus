# Changelog

All notable changes to this project will be documented in this file.

## [1.0.5] - 2025-11-19

### Added

#### Build Placeholder Enhancements
- **New build placeholders** for flexible timestamping
  - `{builddate}` - Current date in YYYY-MM-DD format
  - `{buildtime}` - Current time in HH:MM format
  - Complements existing `{buildstamp}` for more granular control

  **Examples:**
  ```basic
  print "Build Date: {builddate}"
  print "Build Time: {buildtime}"
  
  ; Output:
  Build Date: 2025-11-18
  Build Time: 14:30
  ```

#### Documentation
- **C\*Base Reference Guide** integration
  - Complete documentation now in `docs/manual.md`
  - Mirrors C\*Base Reference Guide
  - Comprehensive examples and usage patterns
  - Installation and compilation instructions

### Changed

- **`{buildstamp}` format updated**
  - Now includes both date and time in YYYY-MM-DD HH:MM format
  - Consistent timestamp format across all build modes

- **Help message improvements**
  - Updated `--help` / `-h` output for clarity

- **Documentation restructuring**
  - Primary documentation moved from GitHub Wiki to C\*Base Reference Guide

## [1.0.4] - 2025-10-27

### Added

#### Blitz! Compiler Support
- **Full Blitz! compiler compatibility**
  - Native `rem **` directive syntax (preserved in output)
  - Alternative `!blitz` directive syntax (converted to `rem **` format)
  - Extension marker `::` for runtime interpretation (only noted, already supported in `Original BPP`)
  - All Blitz! directives preserved for compiler (se, sa, ie, ia, sp, ne)

#### Documentation
- **Blitz! compiler integration guide** added to README
  - Complete directive reference and usage examples
  - Compilation pipeline workflow
  - Performance considerations and constraints

### Changed
- **Comment preservation logic** updated
  - Standard comments (`rem`, `;`) still removed for size optimization
  - Special `rem **` directives now preserved for Blitz! compiler

## [1.0.3] - 2025-10-25

### Added

#### Error Handling & Validation
- **Comprehensive error handling** with proper Unix exit codes
  - File not found errors with clear messages
  - Permission denied errors  
  - Invalid label validation errors
  - Duplicate label detection within scopes
  - Unclosed scope validation (prevents unmatched `}`)
  - Label resolution errors for undefined references
  - Include path errors with detailed diagnostics
  - Interrupt handling (Ctrl+C exits cleanly with status 130)
  - All errors exit with status 1 for bash script integration
  - Consistent `error: line <num>: <message>` format to STDERR

#### CLI Enhancements
- **Improved command-line interface**
  - `--help` / `-h` flag with comprehensive usage documentation
  - `--version` / `-v` flag showing version and description
  - Brief usage message when run without arguments
  - Detailed examples in help text
  - Real-world debugging scenarios in documentation

#### Debugging Features
- **Enhanced line lookup** (`-l` option)
  - Clearer output format: "BASIC line X corresponds to: Source file / Source line"
  - Works across included files
  - "Line not found" message when lookup fails
  - Essential for debugging compiled programs

#### File Validation
- **Robust file handling**
  - Validates file existence before attempting to open
  - Checks if path is actually a file (not a directory)
  - Validates data file existence in `!include data` directives
  - Proper STDIN handling (doesn't close STDIN when reading from pipe)
  - Root scope checking before closing scopes

#### Label Validation
- **Hyphen validation** in labels
  - Added `has_hyphen?` method to String class
  - Added `validate_no_hyphens!` method to Label class
  - Validates both label name and full qualified path
  - Catches nested labels with hyphens
  - Clear error messages: `hyphens not allowed in labels: 'label-name'`

#### Documentation
- **YARD/RDoc-style documentation** throughout codebase
  - Full parameter and return value documentation
  - Inline comments explaining complex logic
  - Clear section headers for maintainability
  - Production-ready code standards

### Changed

- **Label hyphen support removed** (reverted from v1.0.1)
  - Hyphens in labels are no longer allowed
  - Labels must use underscores instead: `long_label:` not `long-label:`
  - Enforced for better compatibility and consistency
  - Clear validation error when hyphens detected

- **Improved `buildstamp` handling**
  - Corrected casing from `buildStamp` to `buildstamp` for consistency
  - Better integration with C\*Base Larry Mod v3.1 build system

- **Enhanced error message format**
  - Consistent format for all error types
  - All errors output to STDERR
  - Compatible with bash error handling: `bpp file.bpp || handle_error`

### Fixed

- **Label regex validation** improvements
  - Pattern now: `/^[a-zA-Z_][\w]*$/` (no hyphens)
  - Proper keyword checking prevents reserved words as labels
  - Single-letter labels (e.g., `a:`) now work correctly
  - Prevents invalid strings from being treated as labels

- **Parser file handling** improvements
  - Static `parse_file` method validates before opening
  - Better error messages for file-related issues
  - Proper pathname expansion and existence checking
  - Prevents confusing errors from invalid paths

- **Include directive path resolution**
  - Resolves relative paths relative to including file (not working directory)
  - Absolute paths used as-is
  - Clear error message with line number when file not found
  - No more mysterious "file not found" errors

### Technical Notes

- **Bash Script Integration:** All error handling designed for seamless bash integration with `||` error trapping
- **Exit Codes:** Strict Unix conventions (0 = success, 1 = error, 130 = interrupted)
- **Backward Compatibility:** Maintains all v1.0.2 functionality while adding robustness
- **Production Ready:** Comprehensive error handling and validation suitable for automated build systems

## [1.0.2] - 2025-09-13

### Added

- **Statement chaining** with backslash `\` continuation
  - Break long BASIC statements across multiple source lines
  - Improves source readability while maintaining efficient output
  - Compiled to single-line BASIC with colon separators

  **Example:**
  ```basic
  ; Source (.bpp)
  poke 53281,0\
  poke 53280,0\
  print "{clr}Hello BPP+";

  ; Output (.bas)
  poke53281,0:poke53280,0:print"{clr}Hello BPP+";
  ```

### Technical Details

- **Implementation:** Line continuation character must be last on line (no trailing spaces)
- **Constraints:** Cannot chain across scope boundaries or label definitions
- **Performance:** Single-line execution is faster on C64 than multiple lines
- **Debugging:** Source line mapping preserved for each statement chain

## [1.0.1] - 2025-09-12

### Added

#### Build Stamping Support
- **Build stamping** for C\*Base Larry Mod v3.1
  - `{buildstamp}` placeholder in `.bpp` files
  - **Development mode:** `Dev: YYYY-MM-DD, HH:MM    Larry Mod v3.1`
  - **Release mode:** `Release: YYYY-MM-DD       Larry Mod v3.1`
  - Time included for development builds, omitted for release builds

  **Examples:**
  ```basic
  print "{buildstamp}"

  ; Development mode output:
  Dev: 2025-09-12, 14:35    Larry Mod v3.1

  ; Release mode output:
  Release: 2025-09-12       Larry Mod v3.1
  ```

#### Include Path Improvements
- **Recursive path support** for include directives
  - Relative paths resolved from including file's directory
  - Supports same directory, subdirectories, and parent navigation
  - Absolute paths work as-is

  **Examples:**
  ```basic
  !include source "filename.bpp"                     ; same directory
  !include source "sub-directory/filename.bpp"       ; subdirectory
  !include source "../sub-directory/filename.bpp"    ; parent navigation
  !include source "/usr/local/lib/c64/stdlib.bpp"   ; absolute path
  ```

#### BASIC v2 Compatibility
- **Extended BASIC v2 compatibility**
  - Bugfixes from [Larry/ROLE](https://github.com/cbmbas)
  - Improved Commodore BASIC v2 keyword recognition
  - C\*Base extension support

- **Initial CHANGELOG.md** for version tracking

### Fixed

#### Keyword Recognition
- **`GET#` token recognition** - Parser now recognizes `GET#` as valid keyword in addition to `GET`
- **Time variables** - Parser recognizes `TI$` and `TI` as valid BASIC keywords
- **Empty strings** - Empty quoted strings (`""`) now recognized correctly in `.bpp` files

#### Statement Parsing
- **`IF...THEN` parsing** - Statements without `GOTO`/`GOSUB` no longer incorrectly parsed as jump commands
  - Fixed: `if x=1 then print "yes"` now correctly parsed as conditional execution
  - Preserved: `if x=1 then 100` still works as implicit GOTO

- **Colon separator** - Parser correctly recognizes `::` as statement separator
  - Fixed: Colons no longer misinterpreted as part of code tokens
  - Enables: Multiple statements properly separated

#### Keyword Corrections
- **Color keyword spelling** - Corrected from **GREY** to **GRAY** per Commodore BASIC v2 conventions
  - Fixed: `GRAY1`, `GRAY2`, `GRAY3` now recognized correctly
  - Compatibility: Matches authentic C64 BASIC v2 keywords

#### Regex Improvements
- **`GOSUB`/`GOTO` regex** - Removed trailing `+` from label capture group
  - **Before:** `^(?<code>go(sub|to))\s*(?<labels>[\w\s,.]+)+`
  - **After:** `^(?<code>go(sub|to))\s*(?<labels>[\w\s,.]+)`
  - Fixed: Multiple label groups no longer captured incorrectly
  - Impact: `on x goto 100,200,300` now parses correctly

### Changed

- **Label naming rules expanded** - Added support for **hyphens** in label names
  - Previously: Only letters, digits, and underscores allowed
  - v1.0.1 change: Hyphens now allowed within label names
  - Must still start with letter or underscore
  - Cannot be BASIC v2 reserved keywords
  - **Note:** This was reverted in v1.0.3 - hyphens no longer allowed

  **What changed in v1.0.1:**
  ```basic
  ; These were ALWAYS valid (no change):
  label:
  _label:
  longLabel:       ; camelCase always supported
  _longLabel:
  long_label:      ; underscores always supported
  
  ; These became VALID in v1.0.1 (NEW):
  long-label:      ; hyphen support added
  _long-label:     ; hyphen support added
  player-x-pos:    ; multiple hyphens allowed
  ```
  
  **Important:** The only actual change was hyphen support. Mixed case (camelCase) and underscores were always supported from v1.0.0.

- **Line numbering** - BASIC output now **starts at line 1** (previously started at 0)
  - More intuitive for debugging
  - Matches standard BASIC programming conventions

### Removed

- **Code cleanup** - Removed unwanted spaces and formatting inconsistencies

## [1.0.0] - 2025-09-11

### Forked
- Initial fork from [hbekel/bpp](https://github.com/hbekel/bpp)
- Base functionality inherited from original BPP preprocessor:
  - Label-based programming (replace line numbers with names)
  - Nested scopes with `{ }` blocks
  - File includes with `!include` directives
  - BASIC v2 output generation

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