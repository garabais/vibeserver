# C Webserver Library Makefile

CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -O2 -g -D_POSIX_C_SOURCE=200809L -pthread
LDFLAGS ?= -pthread
INCLUDES := -Ilib/webserver/include -Ilib/webserver/src

OBJDIR := build
LIB := $(OBJDIR)/libwebserver.a
BINDIR := $(OBJDIR)/bin
BIN := $(BINDIR)/webserver-demo

# Library sources (core, no app-specific handlers or main)
CORE := lib/webserver/src/server.c lib/webserver/src/router.c lib/webserver/src/http.c lib/webserver/src/util.c
LIBOBJ := $(patsubst %.c,$(OBJDIR)/%.o,$(CORE))

# Demo app sources
DEMO_SRC := examples/demo/main.c
DEMO_OBJ := $(patsubst %.c,$(OBJDIR)/%.o,$(DEMO_SRC))

.PHONY: all clean run-demo docs docs-public docs-internal

all: $(LIB) $(BIN)

# Static library build
$(LIB): $(LIBOBJ)
	@mkdir -p $(dir $@)
	ar rcs $@ $(LIBOBJ)

# Demo binary linking the library
$(BIN): $(DEMO_OBJ) $(LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $(DEMO_OBJ) $(LIB) $(LDFLAGS)

# Generic compile rule emitting objects under build/
$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

run-demo: $(BIN)
	./$(BIN) -p 8080

clean:
	rm -rf $(OBJDIR) $(BIN)

docs: docs-public docs-internal

docs-public:
	doxygen Doxyfile.public

docs-internal:
	doxygen Doxyfile.internal
