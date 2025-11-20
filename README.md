# BPP+ Preprocessor

**Modern toolchain for Commodore 64 BASIC v2 cross-development**

BPP+ is a source-to-source compiler that transpiles enhanced BASIC syntax into standard Commodore BASIC v2. It provides label-based control flow, lexical scoping, modular compilation, and comprehensive static analysis.

Extended from the [original BPP preprocessor](https://github.com/hbekel/bpp) by Henning Liebenau.

Part of the **C\*Base Larry Mod v3.1** development package.

## Quick Example

**Source** - Enhanced syntax with labels, scopes and statement chaining (`.bpp`)

```basic
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

```basic
1 poke53280,0:poke53281,0:return
2 print"hello bpp+":return
3 gosub1
4 gosub2
```

## Documentation

Complete documentation is available on **[C*Base Reference Guide - BPP+ Preprocessor](https://cbasereferenceguide.github.io/development/bpp-plus-preprocessor)**

## Quick start

```bash
# Install
git clone https://github.com/cbase-larrymod/bpp-plus.git
cd bpp-plus
chmod +x bpp

# Use
bpp source.bpp > output.bas
petcat -w2 -o program.prg -- output.bas
x64 program.prg
```

See the **[Installation](https://cbasereferenceguide.github.io/development/bpp-plus-preprocessor/getting-started/installation/)** page for detailed setup instructions.

## Contributing

Issues and pull requests are welcome. Please maintain consistency with existing patterns when adding new features.

## Version history

### [1.0.5] - 2025-11-19 (Current)
#### Added

##### Build Placeholder Enhancements

- **New build placeholders** for flexible timestamping
  - `{builddate}` - Current date in YYYY-MM-DD format
  - `{buildtime}` - Current time in HH:MM format
  - Complements existing `{buildstamp}` for more granular control

##### Documentation

- **C\*Base Reference Guide** integration
  - Complete documentation now in `docs/manual.md`
  - Mirrors C\*Base Reference Guide
  - Comprehensive examples and usage patterns
  - Installation and compilation instructions

#### Changed

- **`{buildstamp}` format updated**
  - Now includes both date and time in YYYY-MM-DD HH:MM format
  - Consistent timestamp format across all build modes

- **Help message improvements**
  - Updated `--help` / `-h` output for clarity

- **Documentation restructuring**
  - Primary documentation moved from GitHub Wiki to C\*Base Reference Guide

See [CHANGELOG.md](CHANGELOG.md) for complete history.

## References

### Technical documentation

**Commodore BASIC v2 Specification:**
- [C64 BASIC v2 Manual](https://www.c64-wiki.com/wiki/BASIC)
- [BASIC v2 Token Reference](https://www.pagetable.com/c64ref/c64disasm/)

**Petcat Documentation:**
- [VICE Manual - Petcat](https://vice-emu.sourceforge.io/vice_16.html)

## License

See [LICENSE](LICENSE) file for details.

## Repository

**GitHub:** [cbase-larrymod/bpp-plus](https://github.com/cbase-larrymod/bpp-plus)  
**Original BPP:** [github.com/hbekel/bpp](https://github.com/hbekel/bpp)