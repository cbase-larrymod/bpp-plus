# BPP+ - BASIC v2 Preprocessor & Transpiler

**Modern toolchain for Commodore 64 BASIC v2 cross-development**

BPP+ is a source-to-source compiler that transpiles enhanced BASIC syntax into standard Commodore BASIC v2 bytecode. It implements a symbolic assembler-style workflow for BASIC development, providing label-based control flow, lexical scoping, modular compilation, and comprehensive static analysis. Extended from the [original BPP preprocessor](https://github.com/hbekel/bpp).

Part of the **C\*Base Larry Mod v3.1** development package.

```basic
; Source (.bpp) - Enhanced syntax with labels and scopes
main:
    gosub screen.init
    gosub game.loop

screen: {
    init: poke 53280,0: poke 53281,0: return
}

; Target (.bas) - Standard BASIC v2 with line numbers
1 gosub2
2 gosub3
3 poke53280,0:poke53281,0:return
```

---

## Table of contents

- [Technical overview](#technical-overview)
- [Installation](#installation)
- [Compilation pipeline](#compilation-pipeline)
- [Language specification](#language-specification)
  - [Lexical structure](#lexical-structure)
  - [Symbol resolution](#symbol-resolution)
  - [Scope hierarchies](#scope-hierarchies)
  - [Control flow](#control-flow)
  - [Statement chaining](#statement-chaining)
  - [Include directives](#include-directives)
  - [Blitz BASIC compiler directives](#blitz-compiler-directives)
- [Symbol resolution algorithm](#symbol-resolution-algorithm)
- [Static analysis & validation](#static-analysis--validation)
- [Debugging & diagnostics](#debugging--diagnostics)
- [Build integration](#build-integration)
- [Error handling](#error-handling)
- [API reference](#api-reference)
- [Contributing](#contributing)

---

## Technical overview

### Problem domain

BASIC v2 (Commodore BASIC 2.0) is a line-number-based interpreted language with severe limitations for modern development:

- **No symbolic addressing:** All control flow uses numeric line references
- **No scoping:** Single global namespace with no encapsulation
- **No modularity:** No include mechanism or separate compilation
- **Limited readability:** Minimal whitespace, single-statement-per-line constraint
- **Fragile refactoring:** Inserting lines requires manual renumbering of all references

### Solution architecture

BPP+ implements a preprocessing layer that:

1. **Tokenizes** enhanced BASIC syntax with symbolic labels
2. **Parses** hierarchical scope structures and include directives
3. **Resolves** label references to line numbers via static analysis
4. **Validates** symbol tables for duplicates and undefined references
5. **Transpiles** to standard BASIC v2 with automatically generated line numbers
6. **Maintains** source mapping for debugging compiled programs

The output is semantically equivalent standard BASIC v2 that can be tokenized by Petcat and executed on authentic C64 hardware or accurate emulators. For production use, the generated BASIC can be compiled with the Blitz! compiler for significantly faster execution.

### Design principles

- **Zero runtime overhead:** All preprocessing happens at compile time
- **Lossless compilation:** Transpiled code is functionally identical to hand-written line-numbered BASIC
- **Source fidelity:** Line mapping preserves debugging capability
- **Unix philosophy:** Composable tool that works with standard pipes and build systems
- **Deterministic output:** Same input always produces same output (no timestamp injection unless explicitly enabled)
- **Blitz compatibility:** Full support for Blitz! compiler directives and optimizations

---

## Installation

### Prerequisites

**Required:**
- Ruby >= 2.0 (Ruby 2.7+ recommended)
- VICE emulator >= 3.0 (provides `petcat` utility)

**Optional:**
- Make (for automated builds)
- Blitz! BASIC compiler (for compiled executables)
- C\*Base Larry Mod v3.1 Build system
- inotify-tools (for filesystem watching)

### Installation procedure

```bash
# Clone repository
git clone https://github.com/cbase-larrymod/bpp-plus.git
cd bpp-plus

# Set executable permissions
chmod +x bpp

# Verify installation
./bpp --version
```

### Verification

```bash
# Test basic functionality
echo 'main: print "test": end' | bpp
# Expected output:
# 1 print"test":end

# Test with petcat
echo 'main: print "test": end' | bpp | petcat -w2 -o test.prg --
# Should create test.prg without errors
```

---

## Compilation pipeline

### Standard workflow

```bash
# Stage 1: Preprocess .bpp to .bas
bpp source.bpp > output.bas

# Stage 2: Tokenize .bas to .prg
petcat -w2 -o program.prg -- output.bas

# Stage 3: Execute on target platform
x64 program.prg                    # VICE emulator
# OR transfer program.prg to real C64 hardware
```

### Blitz compiler workflow

For production builds requiring optimal performance, BPP+ output can be compiled with Blitz!:

```bash
# Stage 1: Preprocess with Blitz directives
bpp source.bpp > output.bas

# Stage 2: Compile with Blitz! compiler
# (Load output.bas in C64/emulator and run Blitz!)
# BLOAD "OUTPUT.BAS",8
# RUN

# Result: Compiled machine code executable
```

**Performance considerations:**

Blitz! compilation provides substantial speed improvements:
- **Typical speedup:** 10-30x faster than interpreted BASIC
- **Loop optimization:** Integer loops (FOR I%=...) are significantly faster
- **Direct execution:** Compiled to 6502 machine code
- **Memory efficiency:** Compiled code often smaller than tokenized BASIC

**Blitz-specific constraints:**

When writing BPP+ code intended for Blitz compilation:
- All multi-dimensional arrays **must** be explicitly dimensioned with DIM
- Integer variables (%) can be used in FOR-NEXT loops for additional speed
- Avoid using array name `z*%` (reserved by Blitz! internally)
- Runtime control directives (STOP key, INPUT control) preserved by BPP+

### Pipeline with character set conversion

Some systems require character encoding adjustments for PETSCII compatibility:

```bash
# bpp source.bpp | sed 's/OLD/NEW/g' > output.bas

bpp source.bpp | sed 's/£/\\/g;s/←/_/g' > output.bas
petcat -w2 -o program.prg -- output.bas
```

### Integrated build script

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

## Language specification

### Lexical structure

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
- **BASIC keywords:** All standard BASIC v2 keywords (preserved as-is)

#### Identifier syntax

```
identifier := [a-zA-Z_][a-zA-Z0-9_]*
```

**Constraints:**
- Must start with alphabetic character or underscore
- May contain alphanumeric characters and underscores
- Case-insensitive (normalized to lowercase internally)
- Cannot be BASIC v2 reserved keywords
- No hyphens or special characters permitted

**Valid identifiers:**
```
main
loop_1
_private
playerX
INIT_SCREEN
```

**Invalid identifiers:**
```
1main           ; starts with digit
player-x        ; contains hyphen
init$           ; contains special character
for             ; BASIC keyword
@label          ; starts with special character
```

#### Comments

Two comment syntaxes supported:

```basic
rem This is a BASIC comment (stripped from output)
; This is a BPP+ comment (stripped during preprocessing)
```

**Exception:** Special `rem **` directives for Blitz! compiler are preserved in output (see [Blitz compiler directives](#blitz-compiler-directives)).

Both standard comment types are removed during compilation to minimize output size.

---

### Symbol resolution

#### Label definition

Labels are defined by appending `:` to an identifier:

```basic
label_name: <statement>
```

Labels bind to the subsequent BASIC statement or scope block. Each label is assigned a unique line number during code generation.

#### Label reference

Labels can be referenced in GOTO, GOSUB, and THEN clauses:

```basic
goto <label>
gosub <label>
if <condition> then <label>
on <expression> goto <label>, <label>, ...
on <expression> gosub <label>, <label>, ...
```

#### Qualified references

References can be qualified with scope paths using dot notation:

```basic
<scope>.<label>
<scope>.<subscope>.<label>
global.<label>
```

**Examples:**
```basic
goto main.loop
gosub graphics.clear
on x goto menu.opt1, menu.opt2, menu.opt3
if flag then utils.exit
```

---

### Scope hierarchies

#### Scope declaration

Scopes create lexical namespaces using brace delimiters:

```basic
; Anonymous scope
{
    <statements>
}

; Named scope
<identifier>: {
    <statements>
}
```

#### Scope properties

- **Encapsulation:** Labels defined in scope are local to that scope
- **Nesting:** Scopes can contain nested scopes to arbitrary depth
- **Visibility:** Inner scopes can reference outer scope labels
- **Shadowing:** Local labels shadow identically-named labels in outer scopes

#### Scope chain example

```basic
global_label: print "global"

outer: {
    outer_label: print "outer"
    
    inner: {
        inner_label: print "inner"
        
        test:
            gosub inner_label       ; Resolves to inner.inner_label
            gosub outer_label       ; Resolves to outer.outer_label
            gosub global_label      ; Resolves to global scope
            return
    }
}
```

#### Global scope reference

The implicit global scope can be explicitly referenced:

```basic
done: return                    ; Global label

game: {
    done: return                ; Local label (shadows global)
    
    exit:
        gosub done              ; Calls local game.done
        gosub global.done       ; Explicitly calls global done
}
```

---

### Control flow

BPP+ labels can be used anywhere BASIC v2 accepts line numbers for control flow. During transpilation, labels are replaced with their corresponding line numbers.

**Performance consideration:** All branching operations (GOTO, GOSUB, IF...THEN with line numbers) require the BASIC interpreter to search through program lines to find the target. Forward jumps search from the current position, but backward jumps search from the beginning of the program, making them progressively slower as program size increases. FOR...NEXT loops are faster than backward GOTO loops because NEXT stores the exact return address on the stack instead of performing a line search.

#### Unconditional transfer

```basic
goto <label>                    ; Absolute jump
gosub <label>                   ; Subroutine call with return
return                          ; Return from subroutine
```

#### Conditional transfer

```basic
if <condition> then goto <label> ; Explicit GOTO - FASTER
if <condition> then <label>      ; Conditional jump (implicit GOTO) - SLOWER
if <condition> then <statement>  ; Conditional execution (standard BASIC)
```

**Important:** In BPP+ source, `if <condition> then <label>` is transpiled to `if <condition> then <line_number>`. In BASIC v2, when the THEN clause contains only a number, it's interpreted as an implicit GOTO to that line number.

**Performance:** The explicit form `IF...THEN GOTO <line>` is **faster** than the implicit `IF...THEN <line>` form. While the explicit GOTO adds an extra token, the BASIC interpreter processes it more efficiently.

**Transpilation example:**
```basic
; Source (.bpp)
if x=1 then done       ; Transpiles to slower implicit form
if x=1 then goto done  ; Transpiles to faster explicit form

done: print "finished"

; Output (.bas)
1 ifx=1then2           ; Implicit GOTO (slower)
2 ifx=1thengoto2       ; Explicit GOTO (faster)
```

**Performance consideration:** For optimal performance in speed-critical code, explicitly write `if <condition> then goto <label>` in BPP+ source to generate the faster explicit GOTO form. However, the implicit form saves one token byte (GOTO keyword), so it's slightly more memory-efficient if speed is not critical.

If you need a conditional subroutine call, use:
```basic
if <condition> then gosub <label>
```

#### Computed transfer

```basic
on <expression> goto <label1>, <label2>, ...
on <expression> gosub <label1>, <label2>, ...
```

**Note:** Expression evaluates to 1-based index. Out-of-range values fall through to next statement.

---

### Statement chaining

#### Syntax

Use backslash `\` for line continuation:

```basic
<statement>\
<statement>\
<statement>
```

#### Compilation

Chained statements are compiled to single-line BASIC with colon separators:

```basic
; Source
poke 53280,0\
poke 53281,0\
poke 646,1

; Output
poke53280,0:poke53281,0:poke646,1
```

#### Rationale

Statement chaining provides:
- **Source readability:** Break complex sequences into logical lines
- **Output efficiency:** Single-line execution is faster on C64
- **Space optimization:** Reduces line number overhead
- **Debugging:** Each source line maps to single output line

#### Constraints

- Continuation must be last character on line (no trailing spaces)
- Cannot chain across scope boundaries
- Cannot chain label definitions
- Final statement in chain must not have trailing `\`

---

### Include directives

#### Syntax

```basic
!include <type> "<filepath>"
```

**Types:**
- `source` - Include another .bpp source file
- `data` - Convert binary file to DATA statements

#### Source includes

```basic
!include source "utilities.bpp"
```

**Behavior:**
- File contents inserted verbatim at directive location
- Included file processed recursively
- Labels inherit current scope context
- Relative paths resolved from including file's directory

**Example:**

```basic
; main.bpp
screen: {
    !include source "screen-lib.bpp"
}

; screen-lib.bpp
clear: print "{clr}";: return
init: poke 53280,0: return

; Result: screen.clear and screen.init available
```

#### Data includes

```basic
!include data "charset.bin"
```

**Behavior:**
- Binary file read as byte array
- Generates BASIC DATA statements
- 16 bytes per DATA line for optimal loading
- Suitable for character sets, sprites, music data

**Generated output:**
```basic
data 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
data 24,36,66,66,126,66,66,0,0,0,0,0,0,0,0,0
; ... continues for entire file
```

**Usage pattern:**
```basic
charset: {
    !include data "myfont.bin"
}

load_charset:
    restore charset              ; Position data pointer
    for i = 0 to 2047
        read b
        poke charset_base + i, b
    next i
    return
```

#### Path resolution

**Relative paths:** Resolved relative to including file's directory

```basic
!include source "utils.bpp"              ; ./utils.bpp
!include source "lib/core.bpp"           ; ./lib/core.bpp
!include source "../shared/common.bpp"   ; ../shared/common.bpp
```

**Absolute paths:** Used directly

```basic
!include source "/usr/local/lib/c64/stdlib.bpp"
```

#### Recursive includes

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

---

### Blitz BASIC compiler directives

BPP+ provides full compatibility with the Blitz! BASIC compiler through special directives and syntax extensions. These directives control runtime behavior and compiler optimizations.
Blitz! was also released under other names, such as **AustroComp**, but is essentially the same program. The version [used in combination with](https://csdb.dk/release/?id=173267) BPP+ and the **C\*Base Larry Mod v3.1 development package** is written by **Daniel Kahlin**.

For an excellent overview and performance comparison, watch [The 8-Bit Theory - Blitz! BASIC Compiler (YouTube)](https://www.youtube.com/watch?v=5thXpk_hv54)

#### Directive syntax

Two equivalent syntaxes are supported:

**Native Blitz syntax (preserved verbatim):**
```basic
rem ** se              ; Enable STOP key
rem ** sa              ; Disable STOP key (default)
rem ** ie              ; Enable INPUT command
rem ** ia              ; Disable INPUT command (default)
rem ** sp [number]     ; Specify dongle number
rem ** ne              ; No extension listing
```

**BPP+ alternative syntax (converted to native form):**
```basic
!blitz se              ; Converted to: rem ** se
!blitz sa              ; Converted to: rem ** sa
!blitz ie              ; Converted to: rem ** ie
!blitz ia              ; Converted to: rem ** ia
!blitz sp 1234         ; Converted to: rem ** sp 1234
!blitz ne              ; Converted to: rem ** ne
```

#### Directive semantics

### Blitz directives reference

| #   | BASIC directive | BPP+ directive  | Purpose               |
| :-- | :-------------- | :-------------- | :-------------------- |
| 1   | `rem ** se`     | `!blitz se`     | Enable STOP key       |
| 2   | `rem ** sa`     | `!blitz sa`     | Disable STOP key      |
| 3   | `rem ** ie`     | `!blitz ie`     | Enable INPUT command  |
| 4   | `rem ** ia`     | `!blitz ia`     | Disable INPUT command |
| 5   | `rem ** sp [n]` | `!blitz sp [n]` | Check dongle          |
| 6   | `rem ** ne`     | `!blitz ne`     | No extension listing  |

---

### Directive details

**1. Enable STOP key (`rem ** se` / `!blitz se`)**
- Allows program to be interrupted with **RUN/STOP** key
- Useful during development and debugging
- Default state in interpreted BASIC (re-enabled by this directive)

**2. Disable STOP key (`rem ** sa` / `!blitz sa`)**
- Prevents program interruption with **RUN/STOP** key
- Recommended for production releases
- Default state after Blitz! compilation

**3. Enable INPUT command (`rem ** ie` / `!blitz ie`)**
- Allows runtime `INPUT` statements (if supported by Blitz! version)
- May increase compiled program size

**4. Disable INPUT command (`rem ** ia` / `!blitz ia`)**
- Removes `INPUT` command support from compiled program
- Reduces compiled program size
- Default state (INPUT not supported by default)

**5. Check dongle (`rem ** sp [number]` / `!blitz sp [number]`)**
- Verifies presence of copy protection dongle
- *number* = dongle ID  
- Program terminates if dongle not detected

**6. No extension listing (`rem ** ne` / `!blitz ne`)**
- Prevents program source listing (if supported by Blitz! version)  
- Used for copy-protection

#### Extension marker

The double-colon `::` marker forces a statement to be passed to the BASIC interpreter at runtime rather than being compiled:

```basic
:: sys 49152           ; SYS interpreted at runtime
:: poke 53280,0        ; POKE interpreted at runtime
:: for i=1 to x: print i: next i   ; Dynamic loop
```

**Use cases:**
- Self-modifying code that changes at runtime
- Dynamic calculations that cannot be compile-time resolved
- Interfacing with machine code routines
- Debugging statements in compiled code

**Performance note:** Extension marker bypasses Blitz! optimization. Use sparingly as interpreted statements are significantly slower than compiled code.

#### Practical examples

**Development configuration:**
```basic
!blitz se              ; Enable STOP key for debugging

main:
    gosub init
    gosub game_loop
    end

init:
    :: poke 53280,0    ; Debug statement (interpreted)
    poke 53281,0       ; Production statement (compiled)
    return
```

**Production configuration:**
```basic
rem ** sa              ; Disable STOP key
rem ** ne              ; No extension listing

main:
    gosub init
    gosub game_loop
    end

init:
    poke 53280,0       ; All compiled for maximum speed
    poke 53281,0
    return
```

#### Comment preservation

**Critical distinction:**

Standard BPP+ comment removal does **not** affect Blitz! directives:

```basic
; This comment is removed during preprocessing
rem Normal comment is also removed

rem ** se              ; This directive is PRESERVED
!blitz sa              ; Converted and PRESERVED as: rem ** sa
```

This ensures Blitz! compiler receives all necessary control directives while minimizing program size.

#### Blitz-specific constraints

When writing BPP+ code for Blitz! compilation:

**Array dimensioning:**
```basic
; REQUIRED for Blitz!
dim a(10)              ; Single-dimensional array
dim b(10,10)           ; Multi-dimensional array - MUST use DIM
dim c%(100)            ; Integer array

; All multi-dimensional arrays MUST be explicitly dimensioned
; Implicit arrays are not supported by Blitz!
```

**Integer optimization:**
```basic
; Standard FOR loop
for i=1 to 100: next i

; Optimized integer FOR loop (faster with Blitz!)
for i%=1 to 100: next i%

; Integer variables provide substantial speed improvement
; when compiled with Blitz!
```

**Reserved identifier:**
```basic
; AVOID: z*% is reserved by Blitz! internally
dim z*%(100)           ; ERROR: reserved array name

; Use alternative names:
dim z(100)             ; OK
dim zz%(100)           ; OK
```

#### Integration with BPP+ features

Blitz! directives work seamlessly with all BPP+ features:

```basic
game: {
    !blitz se          ; Enable STOP during development
    
    init:
        poke 53280,0
        gosub player.init
        return
    
    player: {
        init:
            dim px%(255)           ; Integer array
            for i%=0 to 255        ; Optimized loop
                px%(i%)=i%*2
            next i%
            return
    }
}
```

---

## Symbol resolution algorithm

### Resolution strategy

BPP+ implements a hierarchical symbol resolution algorithm with lexical scoping:

```
resolve(label_reference, current_scope):
    1. Search current scope for label
    2. If not found, search subscopes of current scope
    3. If not found, recursively search parent scope
    4. If not found at global scope, throw undefined reference error
```

### Detailed algorithm

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

### Resolution examples

```basic
init: return                ; Line 1 (global)

utils: {
    init: return            ; Line 2 (utils.init)
    
    helper:
        gosub init          ; Resolves to Line 2 (local precedence)
        gosub global.init   ; Resolves to Line 1 (explicit)
        return
}

main:
    gosub init              ; Resolves to Line 1 (global scope search)
    gosub utils.init        ; Resolves to Line 2 (qualified)
```

### Scope shadowing

Local labels shadow outer labels with same name:

```basic
done: return                ; Global done

task1: {
    done: return            ; Shadows global
    work: goto done         ; Jumps to task1.done
}

task2: {
    work: goto done         ; Jumps to global.done (no local shadow)
}
```

### Resolution failures

```basic
main:
    gosub undefined_label   ; ERROR: could not resolve label 'undefined_label'

scope1: {
    local: return
}

scope2: {
    test: gosub local       ; ERROR: 'local' not in scope2 or parents
}
```

---

## Static analysis & validation

### Label validation

#### Naming rules

Enforced constraints:
- Must match pattern: `[a-zA-Z_][a-zA-Z0-9_]*`
- Cannot be BASIC v2 keywords
- Case-insensitive uniqueness within scope

#### Validation messages

```
error: line 5: label cannot start with a number: '1main'
error: line 8: label must start with a letter or underscore: '@label'
error: line 12: hyphens not allowed in labels: 'my-label'
error: line 15: special characters not allowed in labels: 'var$name'
error: line 20: label 'init' already defined in scope
```

### Duplicate detection

Labels must be unique within their scope:

```basic
main:
    print "first"
main:               ; ERROR: line 4: label 'main' already defined in global scope
    print "second"
```

Duplicates across different scopes are permitted:

```basic
task1: {
    init: return    ; OK
}

task2: {
    init: return    ; OK (different scope)
}
```

### Reference validation

All label references must resolve to defined labels:

```basic
main:
    gosub undefined_routine     ; ERROR: could not resolve label 'undefined_routine'
```

### Scope structure validation

Scope delimiters must be balanced:

```basic
main: {
    print "test"
}}                  ; ERROR: unexpected '}' - no scope to close
```

```basic
main: {
    print "test"
; Missing closing brace
                    ; ERROR: unexpected end of file - unclosed scope
```

### Include validation

Include directives validated for:
- File existence
- File readability
- Type validity (`source` or `data` only)

```basic
!include source "missing.bpp"
; ERROR: line 1: include: file not found: 'missing.bpp'

!include invalid "file.bpp"
; ERROR: line 1: include: unknown type: 'invalid'
```

---

## Debugging & diagnostics

### Source mapping

BPP+ maintains bidirectional mapping between source and output line numbers:

```
source_map = {
    basic_line → (source_file, source_line)
}
```

### Line number lookup

Query source location for compiled line:

```bash
bpp -l <line_number> <source_file>
```

**Example workflow:**

```
; C64 runtime error
?SYNTAX ERROR IN 47
READY.

; Lookup source
$ bpp -l 47 game.bpp

BASIC line 47 corresponds to:
  Source file: game.bpp
  Source line: 23
```

### Cross-file debugging

Works across include boundaries:

```bash
$ bpp -l 89 main.bpp

BASIC line 89 corresponds to:
  Source file: lib/collision.bpp
  Source line: 15
```

### Error reporting

BPP+ provides detailed error messages with context:

```
error: line 23: could not resolve label 'player.shoot'
  in file: game.bpp
  context: gosub player.shoot
```

### Diagnostic verbosity

Standard error stream used for all diagnostics:

```bash
bpp source.bpp > output.bas 2> errors.log
```

Exit codes indicate compilation status:
- `0` - Success
- `1` - Compilation error
- `130` - Interrupted (SIGINT)

---

## Build integration

### Makefile integration

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

### Watch mode script

```bash
#!/bin/bash
# watch-build.sh - Auto-rebuild on file changes

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
---

## Error handling

### Error categories

#### Syntax errors
```
error: line 5: unexpected token: '}'
error: line 12: unterminated scope (missing '}')
error: line 18: invalid label syntax: '123invalid'
```

#### Semantic errors
```
error: line 23: label 'main' already defined in global scope
error: line 34: could not resolve label 'undefined_label'
error: line 45: circular include detected: a.bpp → b.bpp → a.bpp
```

#### File system errors
```
error: line 0: file not found: 'source.bpp'
error: line 0: not a file: '/dev/null'
error: line 7: include: file not found: 'missing.bpp'
error: line 12: include: permission denied: '/root/protected.bpp'
```

### Error output format

```
error: line <number>: <message>
  in file: <filename>
  context: <code_snippet>
```

### Exit codes

Standard Unix exit codes:

| Code | Meaning | Use Case                               |
| :--- | :------ | :------------------------------------- |
| 0    | Success | Compilation completed without errors   |
| 1    | Error   | Syntax, semantic, or file system error |
| 2    | Usage   | Invalid command line arguments         |
| 130  | SIGINT  | Interrupted by user (Ctrl+C)           |

### Error recovery

BPP+ implements fail-fast error handling:
- First error encountered halts compilation
- No attempt at error recovery or continuation
- Rationale: BASIC v2 programs are typically small; fix-and-retry is efficient

### Validation strategies

**Static validation at compile time:**
- All labels must be defined before use
- All scopes must be properly closed
- All includes must be resolvable
- No undefined references permitted

**No runtime validation:**
- Generated BASIC v2 assumed correct
- Invalid BASIC syntax may not be caught (passed through to Petcat)

---

## API reference

### Command line interface

```
bpp [options] [input_file]
```

#### Options

**`-h, --help`**
- Display comprehensive help message
- Includes usage examples and feature descriptions
- Exit code: 0

**`-v, --version`**
- Display version information
- Format: `BPP+ vX.Y.Z`
- Exit code: 0

**`-l LINE, --line LINE`**
- Debug mode: Lookup source line for compiled BASIC line
- Requires input file argument
- Output format: Source file and line number
- Exit code: 0 on success, 1 if line not found

#### Input methods

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

#### Output

- Standard output: Generated BASIC v2 code
- Standard error: Error messages and diagnostics
- Exit code: 0 on success, non-zero on error

### Integration patterns

#### Shell pipeline

```bash
# Preprocess and tokenize in one command
bpp source.bpp | petcat -w2 -o program.prg --

# With character set conversion
bpp source.bpp | iconv -f UTF-8 -t ASCII | petcat -w2 -o program.prg --

# With validation
bpp source.bpp | tee output.bas | wc -l
```

#### Error handling in scripts

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

#### Parallel builds

```bash
# Process multiple files in parallel
find src -name '*.bpp' | parallel bpp {} \> build/{/.}.bas
```

---

## Contributing

Issues and pull requests are welcome. Please maintain consistency with existing patterns when adding new features.

---

## Version history

### 1.0.4 (Current)
- **Added:** Full Blitz! compiler compatibility
- **Added:** `rem **` and `!blitz` directive syntax

### 1.0.3
- **Added:** Comprehensive error handling and validation
- **Added:** Command-line debugging with `-l` flag
- **Added:** Enhanced static analysis for label validation
- **Improved:** Error messages with context and file information
- **Improved:** Documentation with Blitz! integration guide
- **Fixed:** Edge cases in scope resolution
- **Documentation:** Complete technical specification

### 1.0.2
- **Added:** Statement chaining with `\` continuation operator
- **Improved:** Source code readability features
- **Fixed:** Line number mapping for multi-statement lines

See [CHANGELOG.md](CHANGELOG.md) for complete history.

---

## References

### Technical documentation

**Commodore BASIC v2 Specification:**
- [C64 BASIC v2 Manual](https://www.c64-wiki.com/wiki/BASIC)
- [BASIC v2 Token Reference](https://www.pagetable.com/c64ref/c64disasm/)

**Petcat Documentation:**
- [VICE Manual - Petcat](https://vice-emu.sourceforge.io/vice_16.html)

---

## License

See [LICENSE](LICENSE) file for details.

---

## Repository

**GitHub:** [cbase-larrymod/bpp-plus](https://github.com/cbase-larrymod/bpp-plus)  
**Original BPP:** [github.com/hbekel/bpp](https://github.com/hbekel/bpp)