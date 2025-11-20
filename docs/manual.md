# BPP+ Preprocessor

**Modern toolchain for Commodore 64 BASIC v2 cross-development**

BPP+ is a source-to-source compiler that transpiles enhanced BASIC syntax into standard Commodore BASIC v2. It provides label-based control flow, lexical scoping, modular compilation, and comprehensive static analysis.

Extended from the [original BPP preprocessor](https://github.com/hbekel/bpp) by Henning Liebenau.

Part of the **C\*Base Larry Mod v3.1** development package.

> **Note:** This manual is also available on the [C\*Base Reference Guide](https://cbasereferenceguide.github.io/development/bpp-plus-preprocessor/) website with additional navigation features.

## Table of Contents

- [BPP+ Preprocessor](#bpp-preprocessor)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
    - [Quick Example](#quick-example)
    - [Technical Overview](#technical-overview)
      - [Problem Domain](#problem-domain)
      - [Solution Architecture](#solution-architecture)
      - [Design Principles](#design-principles)
  - [Getting Started](#getting-started)
    - [Installation](#installation)
      - [Prerequisites](#prerequisites)
      - [Installation Procedure](#installation-procedure)
      - [Verification](#verification)
    - [Compilation Pipeline](#compilation-pipeline)
      - [Standard Workflow](#standard-workflow)
      - [Automatic Line Numbering](#automatic-line-numbering)
      - [Blitz! BASIC Compiler Workflow](#blitz-basic-compiler-workflow)
      - [Pipeline with Character Set Conversion](#pipeline-with-character-set-conversion)
      - [Integrated Build Script](#integrated-build-script)
  - [Language Specification](#language-specification)
    - [Lexical Structure](#lexical-structure)
      - [Tokens](#tokens)
      - [Identifier Syntax](#identifier-syntax)
      - [Comments](#comments)
      - [Build Tokens](#build-tokens)
      - [Reserved Keywords](#reserved-keywords)
      - [String Literals](#string-literals)
      - [Statement Separator: Single vs Double Colon](#statement-separator-single-vs-double-colon)
    - [Include Directives](#include-directives)
      - [Syntax](#syntax)
      - [Source Includes](#source-includes)
      - [Data Includes](#data-includes)
      - [Path Resolution](#path-resolution)
      - [Recursive Includes](#recursive-includes)
    - [Symbol Resolution](#symbol-resolution)
      - [Label Definition](#label-definition)
      - [Label Reference](#label-reference)
      - [Qualified References](#qualified-references)
      - [Case-Insensitive Matching](#case-insensitive-matching)
    - [Scope Hierarchies](#scope-hierarchies)
      - [Scope Declaration](#scope-declaration)
      - [Scope Properties](#scope-properties)
      - [Scope Chain Example](#scope-chain-example)
      - [Shadowing and Explicit Scope Reference](#shadowing-and-explicit-scope-reference)
    - [Control Flow](#control-flow)
      - [Unconditional Transfer](#unconditional-transfer)
      - [Conditional Transfer](#conditional-transfer)
      - [Computed Transfer](#computed-transfer)
      - [Performance Considerations](#performance-considerations)
    - [Statement Chaining](#statement-chaining)
      - [Syntax](#syntax-1)
      - [Compilation](#compilation)
      - [Advantages](#advantages)
      - [Constraints](#constraints)
      - [Comments and Line Continuation](#comments-and-line-continuation)
      - [Line-Length and String Limits](#line-length-and-string-limits)
    - [PETSCII Control Codes](#petscii-control-codes)
      - [Colors](#colors)
      - [Screen Control](#screen-control)
      - [Function Keys](#function-keys)
      - [Special Characters](#special-characters)
      - [Control Characters (Low-level)](#control-characters-low-level)
      - [Usage Examples](#usage-examples)
      - [Case Insensitivity](#case-insensitivity)
      - [Alternative Names](#alternative-names)
      - [Technical Notes](#technical-notes)
    - [Blitz! BASIC Compiler](#blitz-basic-compiler)
      - [Almost Full Speed Ahead!](#almost-full-speed-ahead)
      - [Directive Syntax](#directive-syntax)
      - [Blitz! Directives Reference](#blitz-directives-reference)
      - [Directive Details](#directive-details)
      - [Practical Examples](#practical-examples)
      - [Comment Preservation](#comment-preservation)
      - [Blitz-Specific Constraints](#blitz-specific-constraints)
      - [Integration with BPP+ Features](#integration-with-bpp-features)
  - [Advanced Topics](#advanced-topics)
    - [Symbol Resolution Algorithm](#symbol-resolution-algorithm)
      - [Resolution Strategy](#resolution-strategy)
      - [Detailed Algorithm](#detailed-algorithm)
      - [Resolution Examples](#resolution-examples)
    - [Debugging \& Diagnostics](#debugging--diagnostics)
      - [Source Mapping](#source-mapping)
      - [Line Number Lookup](#line-number-lookup)
      - [Cross-File Debugging](#cross-file-debugging)
      - [Error Reporting](#error-reporting)
      - [Diagnostic Verbosity](#diagnostic-verbosity)
    - [Static Analysis \& Validation](#static-analysis--validation)
      - [Label Validation](#label-validation)
      - [Duplicate Detection](#duplicate-detection)
      - [Reference Validation](#reference-validation)
      - [Scope Structure Validation](#scope-structure-validation)
      - [Include Validation](#include-validation)
  - [Reference](#reference)
    - [API Reference](#api-reference)
      - [Command Line Interface](#command-line-interface)
      - [Integration Patterns](#integration-patterns)
    - [Build Integration](#build-integration)
      - [Makefile Integration](#makefile-integration)
      - [Watch Mode Script](#watch-mode-script)
    - [Error Handling](#error-handling)
      - [Error Categories](#error-categories)
      - [Error Output Format](#error-output-format)
      - [Exit Codes](#exit-codes)
      - [Error Recovery](#error-recovery)
      - [Validation Strategies](#validation-strategies)
  - [GitHub Repository](#github-repository)

---

## Introduction

### Quick Example

**Source** - Enhanced syntax with labels, scopes and statement chaining (`.bpp`)

```cbmbas
screen: {
    init:
        poke 53280,0\
        poke 53281,0\
        return
}

screen: {
    welcome:
        print "hello bpp+"\
        return
}

main:
    gosub screen.init
    gosub screen.welcome
```

**Target** - Standard BASIC v2 with line numbers (`.bas`)

```cbmbas
1 poke53280,0:poke53281,0:return
2 print"hello bpp+":return
3 gosub1
4 gosub2
```

### Technical Overview

#### Problem Domain

BASIC v2 (Commodore BASIC 2.0) is a line-number-based interpreted language with these limitations:

- **No symbolic addressing:** All control flow uses numeric line references
- **No scoping:** Single global namespace with no encapsulation
- **No modularity:** No include mechanism or separate compilation
- **Limited readability:** Minimal whitespace, single-statement-per-line constraint
- **Fragile refactoring:** Inserting lines requires manual renumbering of all references

#### Solution Architecture

BPP+ implements a preprocessing layer that:

1. **Tokenizes** enhanced BASIC syntax with symbolic labels
2. **Parses** hierarchical scope structures and include directives
3. **Resolves** label references to line numbers via static analysis
4. **Validates** symbol tables for duplicates and undefined references
5. **Transpiles** to standard BASIC v2 with generated line numbers
6. **Maintains** source mapping for debugging compiled programs

The output is standard BASIC v2 that can be tokenized by Petcat and executed on C64 hardware or emulators. For production use, compile the generated BASIC with the Blitz! compiler for 4x faster execution.

#### Design Principles

- **Zero runtime overhead:** All preprocessing happens at compile time
- **Lossless compilation:** Transpiled code is functionally identical to hand-written line-numbered BASIC
- **Source fidelity:** Line mapping preserves debugging capability
- **Unix philosophy:** Composable tool that works with standard pipes and build systems
- **Blitz compatibility:** Full support for Blitz! compiler directives and optimizations

---

## Getting Started

### Installation

#### Prerequisites

**Required**

- [Ruby](https://www.ruby-lang.org/) v2.0 or later (Ruby 2.7+ recommended)
- [VICE emulator](https://vice-emu.sourceforge.io/) v3.6.1 or later (includes the `petcat` utility)

**Optional**

- Make (for automated builds)
- [Blitz! BASIC Compiler](https://csdb.dk/release/?id=173267) by Daniel Kahlin
- Filesystem watching via [inotify-tools](https://github.com/inotify-tools/inotify-tools)

#### Installation Procedure

```bash
# Clone repository
git clone https://github.com/cbase-larrymod/bpp-plus.git
cd bpp-plus

# Set executable permissions
chmod +x bpp

# Verify installation
./bpp --version
```

#### Verification

```bash
# Test basic functionality
echo 'main: print "test": end' | bpp
# Expected output:
# 1 print"test":end

# Test with petcat
echo 'main: print "test": end' | bpp | petcat -w2 -o test.prg --
# Should create test.prg without errors
```

### Compilation Pipeline

#### Standard Workflow

```bash
# Stage 1: Preprocess .bpp to .bas
bpp source.bpp > output.bas

# Stage 2: Tokenize .bas to .prg
petcat -w2 -o program.prg -- output.bas

# Stage 3: Execute on target platform
x64 program.prg
```

#### Automatic Line Numbering

BPP+ assigns line numbers during preprocessing:

- First line receives line number `1`
- Each subsequent line increments by `1` (2, 3, 4, ...)
- No gaps in numbering
- No customization or renumbering needed

**Source (.bpp)**

```cbmbas
main:
    print "hello"
    gosub helper
    end

helper:
    print "world"
    return
```

**Output (.bas)**

```cbmbas
1 print"hello"
2 gosub4
3 end
4 print"world"
5 return
```

This eliminates the need for manual line number management in BASIC v2 programs.

#### Blitz! BASIC Compiler Workflow

For production builds requiring better performance, add Blitz! compilation to your pipeline. Blitz! is a BASIC compiler that translates tokenized programs into faster-executing P-Code, delivering 3-5x performance improvements while reducing program size to 60-70% of the original.

```bash
# Stage 1: Preprocess with Blitz directives
bpp source.bpp > output.bas

# Stage 2: Tokenize .bas to .prg
petcat -w2 -o program.prg -- output.bas

# Stage 3: Compile with Blitz!
blitz -c <type> -o blitzed.prg program.prg

# Stage 4: Execute on target platform
x64 blitzed.prg
```

Blitz! compilation offers significant advantages: programs run 3-5x faster through optimizations like pre-stored variable locations, pre-converted constants, and true integer arithmetic. Compiled code is typically smaller than the original, syntax errors are caught at compile-time, and compiled programs cannot be listed (providing automatic protection).

BPP+ preserves all Blitz! directives during preprocessing and handles multi-dimensional array constraints automatically. For complete details, see the [Blitz! BASIC Compiler](#blitz-basic-compiler) section.

#### Pipeline with Character Set Conversion

Some systems require character encoding adjustments for PETSCII compatibility:

```bash
# Syntax:
# bpp source.bpp | sed 's/OLD/NEW/g' > output.bas

# Example:
bpp source.bpp | sed 's/£/\\/g;s/←/_/g' > output.bas
```

#### Integrated Build Script

```bash
#!/bin/bash
set -euo pipefail

SRC="src/main.bpp"
BAS="build/main.bas"
PRG="build/main.prg"

# Create build directory
mkdir -p build

# Stage 1: Preprocess
bpp "${SRC}" > "${BAS}" || {
    echo "ERROR: BPP+ preprocessing failed" >&2
    exit 1
}

# Stage 2: Tokenize
petcat -w2 -o "${PRG}" -- "${BAS}" || {
    echo "ERROR: Petcat tokenization failed" >&2
    exit 1
}

# Stage 3: Verify output
if [[ ! -f "${PRG}" ]]; then
    echo "ERROR: Build failed to produce ${PRG}" >&2
    exit 1
fi

echo "Build successful: ${PRG}"
ls -lh "${PRG}"
```

---

## Language Specification

### Lexical Structure

#### Tokens

BPP+ recognizes the following token types:

- **Label definitions:** `<identifier>:`
- **Label references:** `<identifier>` or `<scope-path>.<identifier>`
- **Scope delimiters:** `{` `}`
- **Statement separator:** `:`
- **Line continuation:** `\`
- **Comments:** `rem <text>` or `; <text>`
- **Directives:** `!include <type> "<path>"` or `!blitz <directive>`
- **Extension marker:** `::` (Blitz! runtime interpretation)
- **Build tokens:** `{builddate}`, `{buildtime}`, `{buildstamp}`
- **String literals:** Quoted text including empty strings `""`
- **BASIC keywords:** All standard BASIC v2 keywords (preserved as-is)

#### Identifier Syntax

```
identifier := [a-zA-Z_][a-zA-Z0-9_]*
```

**Constraints**

- Must start with alphabetic character or underscore
- May contain alphanumeric characters and underscores
- Case-insensitive (normalized to lowercase internally)
- Cannot be BASIC v2 reserved keywords
- No hyphens or special characters permitted

**Valid identifiers**

```cbmbas
main
loop_1
_private
playerX
INIT_SCREEN
```

**Invalid identifiers**

```cbmbas
1main                       rem starts with digit
player-x                    rem contains hyphen
init$                       rem contains special character
for                         rem BASIC keyword
@label                      rem starts with special character
```

#### Comments

Two comment syntaxes supported:

```cbmbas
rem This is a BASIC comment (stripped from output)
; This is a BPP+ comment (stripped during preprocessing)
```

**Comment Syntax Rules**

**REM comments**

- Must match pattern: `rem` followed by space, then comment text
- `rem foo` → removed from output
- `rem **` → preserved (Blitz! directive, requires space before `**`)
- `rem  **` → preserved (multiple spaces OK)
- `rem**` → removed (no space before `**`)

**Semicolon comments**

- Start with `;` character
- Always removed during preprocessing
- No exceptions (cannot be preserved like Blitz! directives)

**Comment Placement**

Both REM and `;` comments can only appear as separate statements, not inline after code:

```cbmbas
rem CORRECT: Comment as separate statement
poke 53280,0
gosub main

rem CORRECT: Comment on its own line with colon separator
poke 53280,0:               rem set border color

rem WRONG: This causes a SYNTAX ERROR in BASIC v2!
poke 53280,0                rem this will fail

rem WRONG: Semicolon also cannot be inline
poke 53280,0                ; this will also fail
```

**Why the colon works**

In BASIC v2, the colon (`:`) is a statement separator. So `poke 53280,0: rem comment` is actually two statements: `poke 53280,0` and `rem comment`.

**BPP+ preprocessing**

BPP+ removes both `rem` and `;` comments during preprocessing (except Blitz! `rem **` directives), so they never appear in the final `.bas` output.

> **Warning:** Do NOT use REM or `;` comments with line continuation (`\`). This causes unexpected behavior.

**Exception**

Special `rem **` directives for Blitz! compiler are preserved in output (see [Blitz! BASIC Compiler](#blitz-basic-compiler)). Both standard comment types are removed during compilation to minimize output size.

#### Build Tokens

BPP+ replaces three build token types during preprocessing:

- `{builddate}` - Current date in YYYY-MM-DD format
- `{buildtime}` - Current time in HH:MM format (24-hour)
- `{buildstamp}` - Full timestamp in YYYY-MM-DD HH:MM format

BPP+ replaces these tokens at preprocessing time with the actual build date and time. Your build script can optionally add mode-specific prefixes (like "Release:", "Beta:" or "Dev:") based on the build configuration.

**Token Format**

- Case-insensitive: `{builddate}`, `{BUILDDATE}`, `{BuildDate}` all work
- 24-hour time format without seconds
- BPP+ replaces these before BASIC parsing, so they work anywhere in your code

**Usage in source**

```cbmbas
main:
    print "{clr}BPP+ Program v1.0"
    print "Build: {builddate}"
    end
```

**BPP+ output**

```cbmbas
1 print"{clr}BPP+ Program v1.0"
2 print"Build: 2025-10-31"
3 end
```

**Build script processing (optional)**

Examples of modification via a Bash build script:

```bash
# For Release builds: Add "Release:" prefix and remove time
sed -i 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) [0-9]\{2\}:[0-9]\{2\}/\1/g' output.bas
sed -i "s/\([^a-zA-Z:]\)\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)/\1Release: \2/g" output.bas

# For Dev builds: Add "Dev:" prefix, keep time
sed -i "s/\([^a-zA-Z:]\)\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[^0-9]*[0-9]\{2\}:[0-9]\{2\}\)/\1Dev: \2/g" output.bas
```

#### Reserved Keywords

The following BASIC v2 keywords cannot be used as label identifiers:

```
end      for      next     data     input#   input    dim      read
let      goto     run      if       restore  gosub    return   rem
stop     on       wait     load     save     verify   def      poke
print#   print    cont     list     clr      cmd      sys      open
close    get      get#     new      tab(     to       fn       spc(
then     not      step     +        -        *        /        ^
and      or       >        =        <        sgn      int      abs
usr      fre      pos      sqr      rnd      log      exp      cos
sin      tan      atn      peek     len      str$     val      asc
chr$     left$    right$   mid$     ti$      ti       st       go
π
```

If you use a keyword as a label, BPP+ will not recognize it as a label. It will pass it through as BASIC code, which causes a syntax error in Petcat.

**Example of what NOT to do**

```cbmbas
for:
    print "hello"           rem ERROR: 'for' is a keyword

goto:
    return                  rem ERROR: 'goto' is a keyword
```

BPP+ will generate:

```cbmbas
1 for:print"hello"
2 goto:return
```

Petcat will then reject this with a syntax error because `for:` and `goto:` are invalid BASIC statements.

#### String Literals

String literals are enclosed in double quotes:

```cbmbas
print "hello world"
a$ = "test"
print ""                    rem Empty string is valid
```

**Empty strings are supported**

```cbmbas
if a$="" then print "empty"
```

#### Statement Separator: Single vs Double Colon

**Single colon (`:`)** - Used as a statement separator in BASIC:

```cbmbas
poke 53280,0:poke 53281,0:print "done"
```

BPP+ recognizes `:` as a delimiter between statements.

**Double colon (`::`)** - Reserved for Blitz! compiler extension marker:

```cbmbas
:: sys 49152                rem Interpreted at runtime, not compiled
```

The parser treats `::` specially to avoid conflicts with single colon parsing.

### Include Directives

#### Syntax

```cbmbas
!include <type> "<filepath>"
```

**Exact syntax rules**

The include directive must match this pattern:

- Start with `!include`
- One or more spaces
- Type name (`source` or `data`)
- One or more spaces
- Double-quoted file path

**Valid**

```cbmbas
!include source "file.bpp"
!include  source  "file.bpp"        rem Multiple spaces OK
!include data "charset.bin"
```

**Invalid**

```cbmbas
!include source file.bpp            rem Missing quotes
!include source 'file.bpp'          rem Single quotes not supported
!includesource "file.bpp"           rem Missing space after !include
```

**Types**

- `source` - Include another .bpp source file
- `data` - Convert binary file to DATA statements

#### Source Includes

```cbmbas
!include source "utilities.bpp"
```

**Behavior**

- File contents inserted verbatim at directive location
- Included file processed recursively
- Labels inherit current scope context
- Relative paths resolved from including file's directory

**Example**

**screen-lib.bpp:**
```cbmbas
clear:
    print "{clr}";
    return

init:
    poke 53280,0
    return
```

**main.bpp:**
```cbmbas
screen: {
    !include source "screen-lib.bpp"
}

gosub screen.clear
gosub screen.init
```

#### Data Includes

```cbmbas
!include data "charset.bin"
```

**Behavior**

- Binary file read as byte array
- Generates BASIC DATA statements
- 16 bytes per DATA line for optimal loading (last line may contain fewer bytes)
- Suitable for character sets, sprites, music data

**Generated output**

```cbmbas
data 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
data 24,36,66,66,126,66,66,0,0,0,0,0,0,0,0,0
data ...
```

**Usage pattern**

```cbmbas
charset: {
    !include data "myfont.bin"
}

load_charset:
    restore charset                             rem Position data pointer
    for i = 0 to 2047
        read b
        poke charset_base + i, b
    next i
    return
```

#### Path Resolution

**Relative paths** - Resolved relative to including file's directory

```cbmbas
!include source "utils.bpp"                     rem ./utils.bpp
!include source "lib/core.bpp"                  rem ./lib/core.bpp
!include source "../shared/common.bpp"          rem ../shared/common.bpp
```

**Absolute paths** - Used directly

```cbmbas
!include source "/usr/local/lib/c64/stdlib.bpp"
```

**Special case: stdin**

When processing input from stdin (piped input), relative includes cannot be resolved since there is no source file directory:

```bash
# This will fail if main.bpp contains relative includes
cat main.bpp | bpp

# Workaround: Use file input instead
bpp main.bpp
```

If you need to process from stdin and use includes, only absolute paths will work:

```cbmbas
rem This works from stdin
!include source "/absolute/path/to/lib.bpp"

rem This will fail from stdin
!include source "lib.bpp"
```

#### Recursive Includes

Includes can nest to arbitrary depth:

```bash
main.bpp
  → includes lib/screen.bpp
      → includes lib/colors.bpp
      → includes lib/petscii.bpp
  → includes lib/sound.bpp
      → includes lib/sid-registers.bpp
```

BPP+ tracks include stack to detect circular dependencies (though not explicitly validated in current implementation - will cause stack overflow).

### Symbol Resolution

This section covers the syntax and rules for defining and referencing labels in BPP+. For the internal algorithm that resolves label references, see [Symbol Resolution Algorithm](#symbol-resolution-algorithm). For organizing labels into scopes, see [Scope Hierarchies](#scope-hierarchies).

#### Label Definition

Labels are defined by appending `:` to an identifier:

```cbmbas
label_name: <statement>
```

Labels bind to the subsequent BASIC statement or scope block. BPP+ assigns each label a unique line number during code generation.

#### Label Reference

Labels can be referenced in GOTO, GOSUB, and THEN clauses:

```cbmbas
goto <label>
gosub <label>
if <condition> then <label>
on <expression> goto <label>, <label>, ...
on <expression> gosub <label>, <label>, ...
```

#### Qualified References

References can be qualified with scope paths using dot notation:

```cbmbas
<scope>.<label>
<scope>.<subscope>.<label>
global.<label>
```

**Examples**

```cbmbas
goto main.loop
gosub graphics.clear
on x goto menu.opt1, menu.opt2, menu.opt3
if a$<>"" then gosub utils.exit
```

#### Case-Insensitive Matching

Label names are case-insensitive. All of these refer to the same label:

```cbmbas
main:
    print "entry point"

gosub main          rem Matches
gosub Main          rem Matches
gosub MAIN          rem Matches
gosub MaIn          rem Matches
```

This applies to:

- Label definitions
- Label references
- Scope names
- Qualified paths

**Implication**

Choose a consistent casing style for readability, even though BPP+ treats all variations as identical. You cannot have labels that differ only in case:

```cbmbas
init:
    return          rem First definition

Init:
    return          rem ERROR: 'init' already defined
```

### Scope Hierarchies

This section covers organizing labels using scope blocks for encapsulation and namespace management. For label definition and reference syntax, see [Symbol Resolution](#symbol-resolution). For the internal resolution algorithm, see [Symbol Resolution Algorithm](#symbol-resolution-algorithm).

#### Scope Declaration

Scopes create lexical namespaces using brace delimiters:

```cbmbas
rem Anonymous scope

{
    <statements>
}

rem Named scope

<identifier>: {
    <statements>
}
```

#### Scope Properties

- **Encapsulation:** Labels defined in scope are local to that scope
- **Nesting:** Scopes can contain nested scopes to arbitrary depth
- **Visibility:** Inner scopes can reference outer scope labels
- **Shadowing:** Local labels shadow identically-named labels in outer scopes

#### Scope Chain Example

```cbmbas
global_label:
    print "global"

outer: {
    outer_label:
        print "outer"

    inner: {
        inner_label:
            print "inner"

        test:
            gosub inner_label       rem Resolves to inner.inner_label
            gosub outer_label       rem Resolves to outer.outer_label
            gosub global_label      rem Resolves to global scope
            return
    }
}
```

#### Shadowing and Explicit Scope Reference

When a local label has the same name as a label in an outer scope, the local label **shadows** (hides) the outer one. The implicit global scope can be explicitly referenced using the `global.` prefix to access shadowed labels:

```cbmbas
done:
    print "global done"
    return                          rem Global label

outer: {
    done:
        print "outer done"
        return                      rem Local label (shadows global)

    exit:
        gosub done                  rem Calls local outer.done
        gosub global.done           rem Explicitly calls global done
        return
}
```

From within `outer.exit`, an unqualified reference to `done` resolves to the local label. To explicitly access the shadowed `done` label in global scope, use the qualified reference `global.done`.

More in depth information can be found in the [Symbol Resolution Algorithm](#symbol-resolution-algorithm) section.

### Control Flow

BPP+ labels can be used anywhere BASIC v2 accepts line numbers for control flow. During transpilation, labels are replaced with their corresponding line numbers.

#### Unconditional Transfer

```cbmbas
goto <label>            rem Absolute jump
gosub <label>           rem Subroutine call with return
return                  rem Return from subroutine
```

#### Conditional Transfer

```cbmbas
if <condition> then goto <label>    rem Explicit GOTO
if <condition> then <label>         rem Implicit GOTO (just the label)
if <condition> then <statement>     rem Conditional execution (standard BASIC)
if <condition> then gosub <label>   rem Conditional subroutine call
```

**Implicit vs explicit GOTO**

In BPP+ source, `if <condition> then <label>` transpiles to `if <condition> then <line_number>`. In BASIC v2, when the THEN clause contains only a number, BASIC interprets it as an implicit GOTO to that line number.

**Transpilation example**

```cbmbas
rem Source (.bpp)

if x=1 then done                rem Implicit GOTO
if x=1 then goto done           rem Explicit GOTO

done:
    print "finished"

rem Output (.bas)

1 ifx=1then3                    rem Implicit form
2 ifx=1thengoto3                rem Explicit form
3 print"finished"
```

**Performance trade-off**

The explicit form `if <condition> then goto <label>` is **faster** to execute, though it uses one extra token byte (the GOTO keyword). The implicit form `if <condition> then <label>` is more memory-efficient but slightly slower. Choose based on whether speed or memory is more critical for your application.

#### Computed Transfer

```cbmbas
on <expression> goto <label1>, <label2>, ...
on <expression> gosub <label1>, <label2>, ...
```

Expression evaluates to 1-based index. Out-of-range values fall through to next statement.

**Scope-qualified labels in ON statements**

ON statements support fully-qualified label paths:

```cbmbas
menu: {
    opt1:
        print "option 1":return

    opt2:
        print "option 2":return

    opt3:
        print "option 3":return
}

main:
    input "choice (1-3)"; choice
    on choice gosub menu.opt1, menu.opt2, menu.opt3
    end
```

This transpiles to line numbers like any other label reference:

```cbmbas
1 input"choice (1-3)";choice
2 onchoicegosub3,4,5
3 end
4 print"option 1":return
5 print"option 2":return
6 print"option 3":return
```

#### Performance Considerations

**Branching overhead**

All branching operations (GOTO, GOSUB, IF...THEN with line numbers) require the BASIC interpreter to search through program lines to find the target:

- **Forward jumps** search from the current position.
- **Backward jumps** search from the beginning of the program, making them progressively slower as program size increases.

**Loop performance**

FOR...NEXT loops are faster than backward GOTO loops because NEXT stores the exact return address on the stack instead of performing a line search. When possible, prefer FOR...NEXT over GOTO-based loops.

### Statement Chaining

#### Syntax

Use backslash `\` for line continuation:

```cbmbas
<statement>\
<statement>\
<statement>
```

#### Compilation

Chained statements are compiled to single-line BASIC with colon separators:

```cbmbas
rem Source
poke 53280,0\
poke 53281,0\
poke 646,1

rem Output
poke53280,0:poke53281,0:poke646,1
```

#### Advantages

- **Source readability:** Break complex sequences into logical lines
- **Output efficiency:** Single-line execution is faster on C64
- **Space optimization:** Reduces line number overhead
- **Debugging:** Each source line maps to single output line

#### Constraints

- Continuation must be last character on line (trailing spaces after `\` are automatically removed)
- Cannot chain across scope boundaries
- Cannot chain label definitions
- Final statement in chain must **not** have trailing `\`
- Cannot include REM or `;` comments in chains - see warning below

**Automatic whitespace trimming**

BPP+ automatically removes trailing whitespace before processing line continuation:

```cbmbas
poke 53280,0  \         rem Spaces after \ are automatically removed
poke 53281,0
```

Result: `poke 53280,0:poke 53281,0`

This means you don't need to worry about accidental trailing spaces breaking your line continuations.

#### Comments and Line Continuation

> **Warning:** Comments (REM and `;`) should NOT be used with line continuation (`\`). This creates either removal of the entire chain or code that doesn't execute. Always place comments before or after the chain, never inside.

#### Line-Length and String Limits

- **Native editor limit:** BASIC lines longer than ~80 characters may be truncated or become uneditable
- **String limit:** A single string literal (e.g., in print) can be up to 255 characters
- **Chaining impact:** Since chained statements compile into a single BASIC line, long chains or large print strings can exceed the editor limit. Keep chains reasonably short

### PETSCII Control Codes

BPP+ supports PETSCII control codes using curly-brace notation `{code}` for screen control, colors, and special characters. These codes are automatically converted during preprocessing.

#### Colors

**Text colors**

| Code                        | Description      | Example                     |
| :-------------------------- | :--------------- | :-------------------------- |
| `{wht}` or `{white}`        | White            | `print "{wht}white text"`   |
| `{red}`                     | Red              | `print "{red}red text"`     |
| `{grn}` or `{green}`        | Green            | `print "{grn}green text"`   |
| `{blu}` or `{blue}`         | Blue             | `print "{blu}blue text"`    |
| `{blk}` or `{black}`        | Black            | `print "{blk}black text"`   |
| `{orng}` or `{orange}`      | Orange           | `print "{orng}orange text"` |
| `{brn}` or `{brown}`        | Brown            | `print "{brn}brown text"`   |
| `{lred}` or `{pink}`        | Light Red / Pink | `print "{lred}pink text"`   |
| `{gry1}` or `{dark gray}`   | Dark Gray        | `print "{gry1}dark gray"`   |
| `{gry2}` or `{gray}`        | Gray             | `print "{gry2}gray text"`   |
| `{lgrn}` or `{light green}` | Light Green      | `print "{lgrn}light green"` |
| `{lblu}` or `{light blue}`  | Light Blue       | `print "{lblu}light blue"`  |
| `{gry3}` or `{light gray}`  | Light Gray       | `print "{gry3}light gray"`  |
| `{pur}` or `{purple}`       | Purple           | `print "{pur}purple text"`  |
| `{yel}` or `{yellow}`       | Yellow           | `print "{yel}yellow text"`  |
| `{cyn}` or `{cyan}`         | Cyan             | `print "{cyn}cyan text"`    |

#### Screen Control

**Cursor movement**

| Code                  | Description                             | Example          |
| :-------------------- | :-------------------------------------- | :--------------- |
| `{home}`              | Move cursor to home position (top-left) | `print "{home}"` |
| `{clr}` or `{clear}`  | Clear screen                            | `print "{clr}"`  |
| `{up}`                | Cursor up                               | `print "{up}"`   |
| `{down}`              | Cursor down                             | `print "{down}"` |
| `{left}`              | Cursor left                             | `print "{left}"` |
| `{rght}` or `{right}` | Cursor right                            | `print "{rght}"` |

**Repetition syntax**

Certain PETSCII control codes can be repeated using a numeric prefix or suffix:

```cbmbas
print "{3 right}"       rem Same as {right}{right}{right}
print "{right*3}"       rem Same as above (alternative syntax)
print "{5 down}"        rem Same as {down}{down}{down}{down}{down}
print "{10 space}"      rem 10 spaces
print "{space*10}"      rem Same as above
```

Patterns: `{number code}` or `{code*number}`

Both formats produce identical output. Use whichever format you find more readable.

> **Important limitation:** The repetition syntax ONLY works with predefined PETSCII control codes listed in this document. It does NOT work with regular keyboard characters like letters, numbers, or basic punctuation.

```cbmbas
rem WORKS: Repeating control codes (both syntaxes)
print "{40 space}"      rem 40 spaces
print "{space*40}"      rem Same as above
print "{20 down}"       rem Move down 20 lines
print "{down*20}"       rem Same as above
print "{home}{25 down}" rem Position cursor at line 25

rem WORKS: PETSCII graphic characters (CBM + key combinations)
print "{40 cbm-t}"      rem 40 horizontal line characters
print "{cbm-t*40}"      rem Same as above
print "{20 cbm-q}"      rem 20 vertical line characters
print "{10 shift-*}"    rem 10 filled circle characters

rem DOES NOT WORK: Regular keyboard characters
print "{20 *}"          rem ERROR: Plain * is not a control code
print "{10 a}"          rem ERROR: Plain letters don't work
print "{40 -}"          rem ERROR: Plain hyphen doesn't work
```

**Display control**

| Code                                      | Description       | Example                   |
| :---------------------------------------- | :---------------- | :------------------------ |
| `{rvson}` or `{reverse on}`               | Reverse video on  | `print "{rvson}reversed"` |
| `{rvof}` or `{rvsoff}` or `{reverse off}` | Reverse video off | `print "{rvof}normal"`    |
| `{inst}` or `{insert}`                    | Insert character  | `print "{inst}"`          |
| `{del}` or `{delete}`                     | Delete character  | `print "{del}"`           |

**Character set control**

| Code                       | Description                       | Example          |
| :------------------------- | :-------------------------------- | :--------------- |
| `{swlc}` or `{lower case}` | Switch to lowercase character set | `print "{swlc}"` |
| `{swuc}` or `{upper case}` | Switch to uppercase character set | `print "{swuc}"` |
| `{dish}`                   | Disable SHIFT+Commodore           | `print "{dish}"` |
| `{ensh}`                   | Enable SHIFT+Commodore            | `print "{ensh}"` |

#### Function Keys

| Code   | Description     | Example        |
| :----- | :-------------- | :------------- |
| `{f1}` | Function key F1 | `print "{f1}"` |
| `{f2}` | Function key F2 | `print "{f2}"` |
| `{f3}` | Function key F3 | `print "{f3}"` |
| `{f4}` | Function key F4 | `print "{f4}"` |
| `{f5}` | Function key F5 | `print "{f5}"` |
| `{f6}` | Function key F6 | `print "{f6}"` |
| `{f7}` | Function key F7 | `print "{f7}"` |
| `{f8}` | Function key F8 | `print "{f8}"` |

#### Special Characters

| Code                         | Description      | Example                      |
| :--------------------------- | :--------------- | :--------------------------- |
| `{space}`                    | Space character  | `print "word{space}word"`    |
| `{return}`                   | Return character | `print "line1{return}line2"` |
| `{sret}` or `{shift return}` | Shift+Return     | `print "{sret}"`             |
| `{stop}`                     | STOP key         | `print "{stop}"`             |
| `{esc}`                      | ESC key          | `print "{esc}"`              |

#### Control Characters (Low-level)

**CTRL sequences**

BPP+ supports direct CTRL key combinations:

| Code                               | Description                   |
| :--------------------------------- | :---------------------------- |
| `{ctrl-a}` through `{ctrl-z}`      | Control + letter combinations |
| `{ctrl-3}`, `{ctrl-6}`, `{ctrl-7}` | Control + number combinations |

**CBM (Commodore) key sequences**

| Code Pattern   | Description                                         |
| :------------- | :-------------------------------------------------- |
| `{cbm-letter}` | Commodore key + letter (e.g., `{cbm-a}`, `{cbm-z}`) |
| `{cbm-symbol}` | Commodore key + symbol (e.g., `{cbm-*}`, `{cbm-+}`) |

**SHIFT sequences**

| Code Pattern     | Description                                     |
| :--------------- | :---------------------------------------------- |
| `{shift-letter}` | Shift + letter (e.g., `{shift-a}`, `{shift-z}`) |
| `{shift-symbol}` | Shift + symbol (e.g., `{shift-*}`, `{shift-@}`) |
| `{shift-space}`  | Shifted space                                   |

**Raw hex values**

For direct character codes, use hex notation:

```cbmbas
print "{$00}"    rem Character code 0
print "{$1f}"    rem Character code 31
print "{$ff}"    rem Character code 255
```

#### Usage Examples

**Clear screen and set colors**

```cbmbas
init:
    print "{clr}{blu}"              rem Clear screen, blue text
    print "{home}WELCOME{return}"   rem Title at top
    return
```

**Menu with colors**

```cbmbas
menu:
    print "{clr}"
    print "{yel}MAIN MENU{wht}"
    print
    print "{grn}1.{wht} START GAME"
    print "{grn}2.{wht} OPTIONS"
    print "{grn}3.{wht} QUIT"
    return
```

**Reverse video highlight**

```cbmbas
highlight:
    print "{rvson}>>> SELECTED <<<{rvof}"
    return
```

**Cursor positioning with repetition**

```cbmbas
status:
    print "{home}{3 down}"           rem Move to line 4
    print "{5 right}"                rem Move 5 columns right
    print "SCORE: ";$sc
    return
```

**Character set switching**

```cbmbas
init_screen:
    print "{clr}{swlc}"              rem Clear and switch to lowercase
    print "Mixed CASE text"
    print "{swuc}"                   rem Back to uppercase
    return
```

**Drawing patterns with PETSCII graphics**

```cbmbas
border:
    print "{home}{40 cbm-t}"             rem Top border with repetition
    print "{home}{23 down}{40 cbm-t}"    rem Bottom border
    return

box:
    print "{home}{cbm-@}";               rem Top-left corner
    for i=1 to 38: print "{cbm-t}";: next i
    print "{cbm-i}"                      rem Top-right corner
    return
```

Common line drawing characters: `{cbm-t}` (horizontal), `{cbm-q}` (vertical), `{cbm-@}`, `{cbm-i}`, `{cbm-k}`, `{cbm-j}` (corners)

#### Case Insensitivity

Control codes are case-insensitive. These are equivalent:

```cbmbas
print "{clr}"     rem lowercase
print "{CLR}"     rem uppercase
print "{Clr}"     rem mixed case
```

#### Alternative Names

Many control codes have multiple aliases:

```cbmbas
{clr} = {clear}
{rvson} = {reverse on}
{wht} = {white}
{rght} = {right}
{del} = {delete}
```

Use whichever form is most readable in your code.

#### Technical Notes

**Internal processing**

Control codes are processed during the preprocessing stage:

1. Codes are temporarily escaped to `~code~` format during parsing
2. Label resolution and line generation occurs
3. Codes are unescaped back to `{code}` format in output
4. Petcat converts them to actual PETSCII bytes during tokenization

**Conflicting with BASIC code**

Control codes in string literals are safe:

```cbmbas
rem CORRECT: In strings
print "{clr}HELLO"

rem WRONG: Not in strings - will cause parse errors
a={clr}
```

Control codes should only appear in string literals, not in BASIC expressions.

### Blitz! BASIC Compiler

BPP+ provides full compatibility with the Blitz! BASIC Compiler through special directives and syntax extensions. These directives control runtime behavior and compiler optimizations.

#### Almost Full Speed Ahead!

**Blitz!** is a BASIC compiler for the Commodore 64 that translates BASIC programs into faster-executing P-Code. Originally developed by Skyles Electric Works and later enhanced by Commodore Buromaschinen GmbH (as Austro-Comp) and Daniel Kahlin.

**BPP+** and **C\*Base Larry Mod v3.1 development package** uses the Blitz!/Austro-Comp compiler v0.1 by Daniel Kahlin as the default compiler. The table below lists multiple compiler variants and tools available for different development environments and workflows.

- **Video overview:** [The 8-Bit Theory - Blitz! BASIC Compiler](https://www.youtube.com/watch?v=5thXpk_hv54) (YouTube)

**Compilers and tools**

| Name                           | Version | Description                                                        | Link                                                                                |
| :----------------------------- | :------ | :----------------------------------------------------------------- | :---------------------------------------------------------------------------------- |
| Blitz!/Austro-Comp compiler    | v0.1    | Cross-compiler by Daniel Kahlin (default for BPP+/C\*Base)         | [CSDB](https://csdb.dk/release/?id=173267)                                          |
| Blitz!/Austro-Speed decompiler | v0.1    | Decompiler for Blitz!-compiled programs back to BASIC              | [CSDB](https://csdb.dk/release/?id=165744)                                          |
| Reblitz64                      | -       | JavaScript port of Blitz! compiler (extremely fast, browser-based) | [GitHub](https://github.com/c1570/Reblitz64)                                        |
| BC64                           | -       | Cross-compiler with C128-style forced integer support              | [GitHub](https://github.com/mvr70702/BC64-Blitz-crosscompiler-for-the-Commodore-64) |

Authors: Skyles Electric Works, Commodore Buromaschinen GmbH and Daniel Kahlin

**Why use Blitz! compilation?**

Blitz! compilation provides significant advantages over interpreted BASIC:

**Performance improvements**

- Provides 3-5x performance improvements over interpreted BASIC
- Pre-stored variable and array locations (no runtime searching)
- Pre-stored line number destinations for GOTO/GOSUB (no runtime searching)
- Pre-converted numeric constants (no runtime conversion)
- Compilation-time syntax checking (no runtime checking)
- True integer arithmetic for integer expressions
- Optimized expression evaluation with minimal intermediate storage

**Code size benefits**

- Compiled P-Code typically reduces program size to **60-70%** of the original
- Runtime routines add overhead, but programs 30KB+ usually become smaller overall
- More efficient memory usage for larger programs

**Development benefits**

- Syntax errors caught at compile-time, not runtime
- Better performance for production releases
- Copy protection options (STOP key disable, dongle support)
- Compiled programs cannot be listed (automatic protection)

#### Directive Syntax

Two equivalent syntaxes are supported in BPP+:

**Native Blitz! syntax (preserved verbatim)**

```cbmbas
rem ** se                   rem Enable STOP key
rem ** sa                   rem Disable STOP key (default)
rem ** ie                   rem Enable INPUT command
rem ** ia                   rem Disable INPUT command (default)
rem ** sp [number]          rem Specify dongle number
rem ** ne                   rem No extension listing
```

**BPP+ alternative syntax (converted to native form)**

```cbmbas
!blitz se                   rem Converted to: rem ** se
!blitz sa                   rem Converted to: rem ** sa
!blitz ie                   rem Converted to: rem ** ie
!blitz ia                   rem Converted to: rem ** ia
!blitz sp 1234              rem Converted to: rem ** sp 1234
!blitz ne                   rem Converted to: rem ** ne
```

#### Blitz! Directives Reference

| #   | BASIC directive | BPP+ directive  | Purpose               |
| :-- | :-------------- | :-------------- | :-------------------- |
| 1   | `rem ** se`     | `!blitz se`     | Enable STOP key       |
| 2   | `rem ** sa`     | `!blitz sa`     | Disable STOP key      |
| 3   | `rem ** ie`     | `!blitz ie`     | Enable INPUT command  |
| 4   | `rem ** ia`     | `!blitz ia`     | Disable INPUT command |
| 5   | `rem ** sp [n]` | `!blitz sp [n]` | Check dongle          |
| 6   | `rem ** ne`     | `!blitz ne`     | No extension listing  |
| 7   | `::`            | `::`            | Extension marker      |

#### Directive Details

**1. Enable STOP key**

Allows program to be interrupted with **RUN/STOP** key.

- **Directive:** `rem ** se` / `!blitz se`
- **Use cases:** Development and debugging, testing compiled programs, allowing user to exit long-running operations
- **Default state:** Interpreted BASIC has STOP key enabled; compiled programs have it disabled (must use this directive to re-enable)

```cbmbas
!blitz se                   rem Enable STOP key for debugging

main:
    gosub test_routine
    print "tests complete"
    end

test_routine:
    rem User can press STOP to interrupt during testing
    for i=1 to 10000
        print i
    next i
    return
```

**2. Disable STOP key**

Prevents program interruption with **RUN/STOP** key.

- **Directive:** `rem ** sa` / `!blitz sa`
- **Use cases:** Production releases, copy protection, preventing user interruption during critical operations, kiosk or demo programs
- **Default state:** Compiled programs have STOP key disabled by default; this directive explicitly documents the behavior

```cbmbas
rem ** sa                   rem Disable STOP key (production)

main:
    gosub init
    gosub game_loop
    end
```

**3. Enable INPUT command**

Allows runtime `INPUT` statements if supported by Blitz! version.

- **Directive:** `rem ** ie` / `!blitz ie`
- **Trade-offs:** Increases compiled program size, adds INPUT command support to runtime routines
- **Use cases:** Programs requiring user text input, interactive applications, data entry programs

```cbmbas
!blitz ie                   rem Enable INPUT command

main:
    print "enter your name:"
    input nm$
    print "hello, ";nm$
    end
```

**4. Disable INPUT command**

Removes `INPUT` command support from compiled program.

- **Directive:** `rem ** ia` / `!blitz ia`
- **Benefits:** Reduces compiled program size, removes unused runtime code
- **Default state:** INPUT command not supported by default (must explicitly enable with `rem ** ie`)
- **Use cases:** Programs that don't need INPUT, size-optimized programs, games and demos using GET instead of INPUT

```cbmbas
rem ** ia                   rem Disable INPUT (default, explicit)

main:
    gosub get_keypress      rem Use GET instead of INPUT
    end

get_keypress:
    get k$
    if k$="" then get_keypress
    return
```

**5. Check dongle**

Verifies presence of copy protection dongle.

- **Directive:** `rem ** sp [number]` / `!blitz sp [number]`
- **Parameters:** `number` = Dongle ID (specific hardware identifier)
- **Behavior:** Program terminates if specified dongle not detected; used for commercial software copy protection

```cbmbas
!blitz sp 1234              rem Require dongle #1234

main:
    rem Program only runs with correct dongle present
    gosub game_loop
    end
```

**6. No extension listing**

Suppresses line number output during compilation. Compiled programs cannot be listed anyway - attempting to LIST will only show `SYS` address or "compiled by blitz" message.

- **Directive:** `rem ** ne` / `!blitz ne`
- **Use cases:** Cleaner compilation output (no line numbers printed), faster compilation (skips line number display), quieter build process

```cbmbas
rem ** ne                   rem Suppress line numbers during compilation

main:
    gosub main_loop
    end
```

**7. Extension marker**

Forces statement to be passed to the BASIC interpreter at runtime rather than being compiled. Allows non-BASIC V2 commands (BASIC extensions) to be used without causing syntax errors during compilation.

- **Directive:** `::`
- **Syntax:** `:: statement` (single statement) or `:: statement1: statement2` (multiple statements up to next line)

**Use cases:**

- **BASIC extensions** - Commands from Plum's Extensions, Simon's BASIC, JiffyDOS, etc.
- **Kernal enhancements** - Extended commands provided by ML routines
- **Non-standard commands** - Any command not recognized by Blitz! compiler
- Machine code routine calls (SYS)
- Self-modifying code that changes at runtime
- Dynamic calculations that cannot be compile-time resolved
- Debugging statements in compiled code
- Intentional delay loops that should not be optimized

**Why use extension marker?**

Without `::`, the compiler will throw a **SYNTAX ERROR** when encountering commands it doesn't recognize (anything beyond standard BASIC V2). The extension marker tells Blitz! to skip compilation and pass the command to the BASIC interpreter at runtime, where ML-based extensions can handle it.

> **Important note:** If a BASIC command is treated as extension, all related commands must also be extensions. For example: `FOR-NEXT` pairs must both be extensions or both be compiled; `OPEN-PRINT#-CLOSE` groups should all be extensions or all compiled.

```cbmbas
main:
    :: @                    rem JiffyDOS directory command (extension)
    :: dload"file",8        rem JiffyDOS fast load (extension)
    :: sys 49152            rem Machine code call (extension)
    poke 53281,0            rem Standard BASIC (compiled - faster)
    return

dynamic_loop:
    rem Runtime-calculated loop (cannot optimize)
    :: for i=1 to x: print i: next i
    return
```

**Performance impact:** Extension marker bypasses Blitz! optimization. Interpreted statements execute at normal BASIC speed (much slower than compiled P-Code). Use sparingly to maintain performance benefits. Extensions handled by ML routines may still be fast despite interpretation.

#### Practical Examples

**Development vs production configuration**

**Development build:**
```cbmbas
!blitz se                   rem Enable STOP key for debugging
!blitz ie                   rem Enable INPUT for testing

main:
    :: poke 53280,0         rem Debug statement (interpreted)
    input "continue (y/n)";a$
    end
```

**Production build:**
```cbmbas
rem ** sa                   rem Disable STOP key
rem ** ia                   rem Disable INPUT (smaller size)
rem ** ne                   rem No extension listing

main:
    poke 53280,0            rem All compiled for maximum speed
    get k$                  rem Use GET instead of INPUT
    end
```

**Integer optimization**

```cbmbas
rem Standard floating point (slower)
for i=1 to 100
    poke 1024+i,i
next i

rem Optimized with integers (faster)
for i%=1 to 100
    poke 1024+i%,i%
next i%
```

**Extension marker usage**

```cbmbas
main:
    poke 53280,0            rem Compiled (fast)
    :: sys 49152            rem Extension (interpreted at runtime)
    :: for i=1 to x: next i rem Dynamic loop (runtime only)
    end
```

#### Comment Preservation

Standard BPP+ comment removal does **not** affect Blitz! directives. This ensures the compiler receives all necessary control directives while minimizing program size.

**Comment handling:**
```cbmbas
; This BPP+ comment is REMOVED during preprocessing
rem This regular comment is REMOVED

rem ** se           rem This directive is PRESERVED
!blitz sa           rem Converted and PRESERVED as: rem ** sa
```

**Result after preprocessing:**
```cbmbas
rem ** se
rem ** sa
```

This behavior ensures:

- Blitz! compiler receives all directives
- Program size minimized by removing unnecessary comments
- Source code remains clean and maintainable

#### Blitz-Specific Constraints

When writing BPP+ code for Blitz! compilation, observe these requirements:

**Array dimensioning**

All multi-dimensional arrays **must** be explicitly dimensioned with DIM statements.

**Rules:**
- Single-dimensional arrays: DIM optional (defaults to 11 elements)
- Multi-dimensional arrays: DIM required (compilation fails without it)
- Integer arrays: Use `%` suffix for better performance

```cbmbas
rem Single-dimensional arrays
dim a(10)               rem Explicit dimension (recommended)
a(5)=100                rem Without DIM, defaults to DIM a(10)

rem Multi-dimensional arrays - DIM REQUIRED
dim b(10,10)            rem Must use DIM
dim c(5,5,5)            rem Must use DIM

rem Integer arrays for performance
dim px%(255)            rem Integer array (faster)
dim py%(255)            rem Integer array (faster)
```

**Error example:**
```cbmbas
rem ERROR: Multi-dimensional array without DIM
b(5,5)=100              rem Compilation fails - missing DIM statement

rem CORRECT: Use DIM first
dim b(10,10)
b(5,5)=100              rem OK
```

**Integer optimization**

Integer variables provide significant speed improvement in compiled programs.

**Benefits:**
- True integer arithmetic (no float conversion)
- Faster FOR-NEXT loops
- Reduced memory overhead
- Better performance in array indexing

```cbmbas
rem Standard floating point loop (slower)
for i=1 to 100
    print i
next i

rem Optimized integer loop (faster with Blitz!)
for i%=1 to 100
    print i%
next i%

rem Integer variables in calculations
x%=10
y%=20
z%=x%*y%                rem Integer arithmetic (fast)

rem Mixing types (avoid for best performance)
x%=10
y=20
z=x%*y                  rem Mixed types (slower due to conversion)
```

**Best practices:**
- Use integer variables for loop counters
- Use integer variables for array indices
- Use integer variables for simple calculations
- Use floating point only when decimals needed

**Reserved identifier**

The array name `z*%` is reserved by Blitz! internally and must be avoided.

**Forbidden:**
```cbmbas
dim z*%(100)            rem ERROR: reserved array name
```

**Alternatives:**
```cbmbas
dim z(100)              rem OK: standard array
dim zz%(100)            rem OK: integer array
dim za%(100)            rem OK: different name
dim arr_z%(100)         rem OK: prefixed name
```

**Performance optimization guidelines**

**Compile these for maximum speed:**
- Simple POKE/PEEK operations
- FOR-NEXT loops (especially with integer variables)
- Arithmetic calculations
- Array access
- GOSUB/GOTO branching
- Variable assignments

**Use extensions (::) for:**
- SYS calls to machine code
- Self-modifying code
- Dynamic runtime calculations
- Commands not recognized by compiler
- Debugging statements
- Intentional delays that shouldn't be optimized

**Example showing optimal compilation strategy:**
```cbmbas
main:
    rem Compiled statements (fast)
    for i%=1 to 1000
        poke 1024+i%,i%
    next i%

    rem Extension for machine code call
    :: sys 49152

    rem Compiled statements (fast)
    for i%=1 to 1000
        poke 55296+i%,1
    next i%

    end
```

#### Integration with BPP+ Features

Blitz! directives work seamlessly with all BPP+ features:

```cbmbas
game: {
    !blitz se                       rem Enable STOP during development

    init:
        dim px%(255), py%(255)      rem Integer arrays for speed
        for i%=0 to 255
            px%(i%)=i%*2
        next i%
        :: sys 49152                rem Extension for sprite routine
        return
}
```

---

## Advanced Topics

### Symbol Resolution Algorithm

This section details the internal algorithm BPP+ uses to resolve label references with hierarchical scoping. For basic label syntax and reference rules, see [Symbol Resolution](#symbol-resolution). For scope organization concepts, see [Scope Hierarchies](#scope-hierarchies).

#### Resolution Strategy

BPP+ implements a hierarchical symbol resolution algorithm with lexical scoping:

```
resolve(label_reference, current_scope):
    1. Search current scope for label
    2. If not found, search subscopes of current scope
    3. If not found, recursively search parent scope
    4. If not found at global scope, throw undefined reference error
```

#### Detailed Algorithm

```
function resolve_label(reference, scope):
    // Split qualified reference
    path_components = reference.split('.')

    if path_components.length > 1:
        // Qualified reference: navigate scope chain
        target_scope = resolve_scope(path_components[0..-2], scope)
        label_name = path_components[-1]
        return lookup_in_scope(label_name, target_scope)
    else:
        // Unqualified reference: hierarchical search
        label_name = reference

        // Check current scope
        if label_exists_in(label_name, scope):
            return get_label(label_name, scope)

        // Check subscopes
        for each subscope in scope.subscopes:
            if label_exists_in(label_name, subscope):
                return get_label(label_name, subscope)

        // Recursively check parent scopes
        if scope.parent != null:
            return resolve_label(reference, scope.parent)

        // Not found
        throw UndefinedReferenceError(reference)
```

#### Resolution Examples

```cbmbas
init: return                        rem Line 1 (global)

utils: {
    init: return                    rem Line 2 (utils.init)

    helper:
        gosub init                  rem Resolves to Line 2 (local precedence)
        gosub global.init           rem Resolves to Line 1 (explicit)
        return
}

main:
    gosub init                      rem Resolves to Line 1 (global scope search)
    gosub utils.init                rem Resolves to Line 2 (qualified)
```

**Scope shadowing**

Local labels shadow outer labels with same name.

```cbmbas
done: return                rem Global done

task1: {
    done: return            rem Shadows global
    work: goto done         rem Jumps to task1.done
}

task2: {
    work: goto done         rem Jumps to global.done (no local shadow)
}
```

**Resolution failures**

```cbmbas
main:
    gosub undefined_label           rem ERROR: could not resolve label 'undefined_label'

scope1: {
    local: return
}

scope2: {
    test: gosub local               rem ERROR: 'local' not in scope2 or parents
}
```

### Debugging & Diagnostics

#### Source Mapping

BPP+ maintains bidirectional mapping between source and output line numbers:

```
source_map = {
    basic_line → (source_file, source_line)
}
```

#### Line Number Lookup

Query source location for compiled line:

```bash
bpp -l <line_number> <source_file>
```

**Example workflow:**

```bash
rem C64 runtime error
?SYNTAX ERROR IN 47
READY.
```

```bash
; Source lookup
$ bpp -l 47 game.bpp

BASIC line 47 corresponds to:
  Source file: game.bpp
  Source line: 23
```

**Line not found:**

If the requested line number doesn't exist in the compiled output:

```bash
$ bpp -l 999 game.bpp

BASIC line 999 not found in compiled output
```

This typically means the line number is outside the range of your program, or the program didn't compile successfully.

#### Cross-File Debugging

Works across include boundaries:

```bash
$ bpp -l 89 main.bpp

BASIC line 89 corresponds to:
  Source file: lib/collision.bpp
  Source line: 15
```

#### Error Reporting

BPP+ provides detailed error messages with context:

```
error: line 23: could not resolve label 'player.shoot'
  in file: game.bpp
  context: gosub player.shoot
```

#### Diagnostic Verbosity

Standard error stream used for all diagnostics:

```bash
bpp source.bpp > output.bas 2> errors.log
```

### Static Analysis & Validation

#### Label Validation

**Naming rules:**

- Must match pattern: `[a-zA-Z_][a-zA-Z0-9_]*`
- Cannot be BASIC v2 keywords
- Case-insensitive uniqueness within scope

**Validation messages:**

```
error: line 5: label cannot start with a number: '1main'
error: line 8: label must start with a letter or underscore: '@label'
error: line 12: hyphens not allowed in labels: 'my-label'
error: line 15: special characters not allowed in labels: 'var$name'
error: line 20: label 'init' already defined in global scope
```

#### Duplicate Detection

Labels must be unique within their scope:

```cbmbas
init:
    print "first"
    return

init:
    print "second"
    return
```

**Validation message:**
```
error: line 4: label 'init' already defined in global scope
```

Duplicates across different scopes are permitted:

```cbmbas
task1: {
    init:
        print "first"
        return
}

task2: {
    init:
        print "second"
        return
}
```

#### Reference Validation

All label references must resolve to defined labels:

```cbmbas
main:
    gosub undefined_routine
```

**Validation message:**
```
error: could not resolve label 'undefined_routine'
```

**Label must be followed by code**

Referenced labels must have BASIC code on the following line:

```cbmbas
main:
    gosub helper

helper:
    rem Label exists but no code follows
```

**Validation message:**
```
error: line 4: referenced label 'helper' not followed by basic code
```

This error occurs when a label is defined and referenced, but has no executable BASIC statement after it. Labels must point to actual code, not just comments or other labels.

#### Scope Structure Validation

**Too many closing braces**

Attempting to close a scope that doesn't exist:

```cbmbas
main: {
    print "test"
}}
```

**Validation message:**
```
error: unexpected '}' - no scope to close
```

> **Warning:** BPP+ currently does **not** validate for missing closing braces at end of file. If you omit a closing brace, the parser may produce unexpected output or fail silently. Always ensure scopes are properly closed:
> ```cbmbas
> main: {
>     print "test"
> }    rem Always close your scopes!
> ```

#### Include Validation

Include directives validated for:

- File existence
- File readability
- Type validity (`source` or `data` only)

```cbmbas
!include source "missing.bpp"
```

**Validation message:**
```
error: line 1: include: file not found: 'missing.bpp'
```

```cbmbas
!include invalid "file.bpp"
```

**Validation message:**
```
error: line 1: include: unknown type: 'invalid'
```

---

## Reference

### API Reference

#### Command Line Interface

```
bpp [options] [input_file]
```

**Options:**

`-h, --help`
- Display help message
- Includes usage examples and feature descriptions

`-v, --version`
- Display version information

`-l <line_number>, --line <line_number>`
- **Debug mode:** Lookup source line for compiled BASIC line
- **Requires:** Input file argument
- **Output format:** Source file and line number
- **Exit code:** 0 on success, 1 if line not found

**Input methods:**

**File input:**
```bash
bpp program.bpp
```

**Standard input:**
```bash
cat program.bpp | bpp
echo 'main: print "test"' | bpp
```

**Process substitution:**
```bash
bpp <(curl -s https://example.com/program.bpp)
```

**Output:**

- **Standard output:** Generated BASIC v2 code
- **Standard error:** Error messages and diagnostics
- **Exit code:** 0 on success, non-zero on error

#### Integration Patterns

**Shell pipeline:**

```bash
# Preprocess and tokenize in one command
bpp source.bpp | petcat -w2 -o program.prg --

# With character set conversion
bpp source.bpp | iconv -f UTF-8 -t ASCII | petcat -w2 -o program.prg --

# With validation
bpp source.bpp | tee output.bas | wc -l
```

**Error handling in scripts:**

```bash
#!/bin/bash

if bpp source.bpp > output.bas 2> errors.log; then
    echo "Compilation successful"
    petcat -w2 -o program.prg -- output.bas
else
    echo "Compilation failed:"
    cat errors.log
    exit 1
fi
```

**Parallel builds:**

```bash
# Process multiple files in parallel
find src -name '*.bpp' | parallel bpp {} \> build/{/.}.bas
```

### Build Integration

#### Makefile Integration

```makefile
# Variables
BPP := ./bpp
PETCAT := petcat
SRC_DIR := src
BUILD_DIR := build
SRC_FILES := $(wildcard $(SRC_DIR)/*.bpp)
BAS_FILES := $(patsubst $(SRC_DIR)/%.bpp,$(BUILD_DIR)/%.bas,$(SRC_FILES))
PRG_FILES := $(patsubst $(SRC_DIR)/%.bpp,$(BUILD_DIR)/%.prg,$(SRC_FILES))

# Default target
all: $(PRG_FILES)

# Preprocessing rule
$(BUILD_DIR)/%.bas: $(SRC_DIR)/%.bpp | $(BUILD_DIR)
	@echo "Preprocessing $<"
	$(BPP) $< > $@ || (rm -f $@; exit 1)

# Tokenization rule
$(BUILD_DIR)/%.prg: $(BUILD_DIR)/%.bas
	@echo "Tokenizing $<"
	$(PETCAT) -w2 -o $@ -- $<

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Phony targets
.PHONY: all clean

# Dependencies (force rebuild on include changes)
$(BUILD_DIR)/main.bas: $(SRC_DIR)/main.bpp \
                       $(wildcard $(SRC_DIR)/lib/*.bpp) \
                       $(wildcard $(SRC_DIR)/assets/*.bin)
```

#### Watch Mode Script

```bash
#!/bin/bash
# Auto-rebuild on file changes

BPP="./bpp"
SRC_DIR="src"
BUILD_DIR="build"

echo "Watching $SRC_DIR for changes..."

while true; do
    inotifywait -r -e modify,create,delete \
        --exclude '.*\.swp' \
        "${SRC_DIR}"

    echo "[$(date '+%H:%M:%S')] Change detected, rebuilding..."

    if make all 2>&1 | tee build.log; then
        echo "✓ Build successful"
    else
        echo "✗ Build failed"
        tail -n 20 build.log
    fi

    echo "---"
done
```

### Error Handling

#### Error Categories

**Syntax errors:**

```
error: line 5: unexpected token: '}'
error: line 12: unterminated scope (missing '}')
error: line 18: invalid label syntax: '123invalid'
```

**Semantic errors:**

```
error: line 23: label 'main' already defined in global scope
error: line 34: could not resolve label 'undefined_label'
error: line 45: circular include detected: a.bpp → b.bpp → a.bpp
```

**File system errors:**

```
error: line 0: file not found: 'source.bpp'
error: line 0: not a file: '/etc'
error: line 7: include: file not found: 'missing.bpp'
error: line 12: include: permission denied: '/root/protected.bpp'
```

#### Error Output Format

```
error: line <number>: <message>
  in file: <filename>
  context: <code_snippet>
```

#### Exit Codes

Standard Unix exit codes:

| Code | Meaning | Use Case                               |
| :--- | :------ | :------------------------------------- |
| 0    | Success | Compilation completed without errors   |
| 1    | Error   | Syntax, semantic, or file system error |
| 130  | SIGINT  | Interrupted by user (Ctrl+C)           |

**Note:** Invalid command line arguments are handled by Ruby's OptionParser, which displays usage information and exits automatically.

#### Error Recovery

**BPP+ implements fail-fast error handling:**

- BPP+ halts compilation when it encounters the first error
- No attempt at error recovery or continuation
- Rationale: BASIC v2 programs are typically small; fix-and-retry is efficient

#### Validation Strategies

**Static validation at compile time:**

- All labels must be defined before use
- All scopes must be properly closed
- All includes must be resolvable
- No undefined references permitted

**No runtime validation:**

- BPP+ assumes generated BASIC v2 is correct
- BPP+ may not catch invalid BASIC syntax (it passes it through to Petcat)

---

## GitHub Repository

The BPP+ source code, issue tracking, and release packages are available on [GitHub](https://github.com/cbase-larrymod/bpp-plus).
