NASM ?= nasm
CC ?= cc
PKG_CONFIG ?= pkg-config

CPPFLAGS += -Iinclude $(shell $(PKG_CONFIG) --cflags libwebsockets libcjson openssl libcurl)
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -Werror -O2
NASMFLAGS ?= -f elf64 -Wall -Werror -Iinclude/ -Iasm/ -g -F dwarf
# --fatal-warnings gates DT_TEXTREL and friends; keep pointer tables in .data.rel.ro.
LDFLAGS ?= -pie -Wl,-z,relro,-z,now,-z,noexecstack -Wl,--fatal-warnings
LDLIBS += $(shell $(PKG_CONFIG) --libs libwebsockets libcjson openssl libcurl) -lcrypt

BUILD := build
OBJ := $(BUILD)/obj
BIN := $(BUILD)/hollow-grid-asm

ASM_SRC := \
	asm/main.asm \
	asm/combat.asm \
	asm/social.asm \
	asm/social_ledger.asm \
	asm/social_grid.asm \
	asm/actions.asm \
	asm/grid_local.asm \
	asm/grid_policy.asm \
	asm/content.asm \
	asm/event.asm \
	asm/rooms.asm \
	asm/session.asm \
	asm/store.asm \
	asm/world.asm
C_SRC := ffi/lws_shim.c ffi/grid_hub.c ffi/format.c ffi/auth.c

ASM_OBJ := $(ASM_SRC:%=$(OBJ)/%.o)
C_OBJ := $(C_SRC:%=$(OBJ)/%.o)
OBJS := $(ASM_OBJ) $(C_OBJ)

.PHONY: all check smoke clean

all: $(BIN)

$(OBJ)/%.asm.o: %.asm
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) -o $@ $<

$(OBJ)/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIE -c -o $@ $<

$(BIN): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(LDLIBS)

check: $(BIN)
	./$(BIN) --help >/dev/null
	./tests/foundation.sh ./$(BIN)
	python3 ./tests/ws_remote_federation.py ./$(BIN)
	python3 ./tests/ws_localhub_soak.py ./$(BIN)
	python3 ./tests/ws_remote_hub_resilience.py ./$(BIN)

# Blocking upstream smoke.mjs (Phase 12 SKIP when DUSTFALL_URL unreachable).
smoke: $(BIN)
	chmod +x ./tests/smoke.sh
	./tests/smoke.sh ./$(BIN)

clean:
	rm -rf $(BUILD)

