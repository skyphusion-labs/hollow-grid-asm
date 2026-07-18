NASM ?= nasm
CC ?= cc
PKG_CONFIG ?= pkg-config

CPPFLAGS += $(shell $(PKG_CONFIG) --cflags libwebsockets libcjson openssl libcurl)
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -Werror -O2
NASMFLAGS ?= -f elf64 -Wall -Werror -Iinclude/ -g -F dwarf
LDFLAGS ?= -pie -Wl,-z,relro,-z,now,-z,noexecstack
LDLIBS += $(shell $(PKG_CONFIG) --libs libwebsockets libcjson openssl libcurl)

BUILD := build
OBJ := $(BUILD)/obj
BIN := $(BUILD)/hollow-grid-asm

ASM_SRC := \
	asm/main.asm \
	asm/content.asm \
	asm/event.asm \
	asm/session.asm \
	asm/world.asm
C_SRC := ffi/lws_shim.c

ASM_OBJ := $(ASM_SRC:%=$(OBJ)/%.o)
C_OBJ := $(C_SRC:%=$(OBJ)/%.o)
OBJS := $(ASM_OBJ) $(C_OBJ)

.PHONY: all check clean

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

clean:
	rm -rf $(BUILD)

