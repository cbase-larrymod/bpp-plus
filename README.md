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

## Documentation

Complete documentation is available in the **[GitHub Wiki](https://github.com/cbase-larrymod/bpp-plus/wiki)**:

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

See the **[Installation](https://github.com/cbase-larrymod/bpp-plus/wiki/Installation)** wiki page for detailed setup instructions.

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