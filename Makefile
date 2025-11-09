# C Webserver Library Makefile

CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -O2 -g -D_POSIX_C_SOURCE=200809L -pthread
LDFLAGS ?= -pthread
INCLUDES := -Ilib/webserver/include -Ilib/webserver/src

OBJDIR := build/obj
LIBDIR := build/lib
BINDIR := build/bin
LIB := $(LIBDIR)/libwebserver.a
BIN := $(BINDIR)/webserver-demo

# Library sources (core, no app-specific handlers or main)
CORE := lib/webserver/src/server.c lib/webserver/src/router.c lib/webserver/src/http.c lib/webserver/src/util.c
LIBOBJ := $(patsubst %.c,$(OBJDIR)/%.o,$(CORE))

# Demo app sources (build directly, do not generate example .o files)

.PHONY: all clean run-demo docs docs-public docs-internal

all: $(LIB) $(BIN)

# Static library build
$(LIB): $(LIBOBJ)
	@mkdir -p $(dir $@)
	ar rcs $@ $(LIBOBJ)

# Demo binary linking the library (build directly, no example .o files)
$(BIN): examples/demo/main.c $(LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ examples/demo/main.c $(LIB) $(LDFLAGS)

# Generic compile rule emitting objects under build/
$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

run-demo: $(BIN)
	./$(BIN) -p 8080

clean:
	rm -rf build

docs: docs-public docs-internal

docs-public:
	doxygen Doxyfile.public

docs-internal:
	doxygen Doxyfile.internal
