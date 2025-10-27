# Variables
BPP := ./bpp
PETCAT := petcat
SRC_DIR := example
BPP_FILES := $(SRC_DIR)/example.bpp $(SRC_DIR)/test.bpp
BAS_FILES := $(BPP_FILES:.bpp=.bas)
PRG_FILES := $(BPP_FILES:.bpp=.prg)

# Default target
all: space $(BAS_FILES) $(PRG_FILES)


space:
	@printf "\n"

# Rule: BPP → BAS
$(SRC_DIR)/%.bas: $(SRC_DIR)/%.bpp

	@printf "* Preprocessing %s → %s\n" "$<" "$@"
	@cd $(SRC_DIR) && ../$(BPP) < $(notdir $<) > $(notdir $@) || (rm -f $(SRC_DIR)/$(notdir $@); exit 1)

# Rule: BAS → PRG
$(SRC_DIR)/%.prg: $(SRC_DIR)/%.bas
	@printf "* Compiling %s → %s\n" "$<" "$@"
	@$(PETCAT) -w2 < $< > $@

# Clean build artifacts (explicit)
clean:
	@printf "* Cleaning generated .bas and .prg files in $(SRC_DIR)/...\n"
	@rm -f $(SRC_DIR)/example.bas $(SRC_DIR)/test.bas $(SRC_DIR)/example.prg $(SRC_DIR)/test.prg
	@printf "Done.\n"

# Phony targets
.PHONY: all clean
