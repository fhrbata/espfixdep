VERSION = 0.1.0
NAME := espfixdep
DUMPMACHINE := $(shell $(CC) -dumpmachine)
ARCHIVE_NAME := $(NAME)-$(VERSION)-$(DUMPMACHINE)

O ?= build
DIST ?= dist
CFLAGS ?= -Wall -Werror -std=c99 -pedantic
LDFLAGS ?=

O := $(abspath $(O))
DIST := $(abspath $(DIST))
BUILD_CFLAGS := $(CFLAGS) $(CFLAGS_APPEND)
BUILD_LDFLAGS := $(LDFLAGS) $(LDFLAGS_APPEND)
BUILD_DEFINES := -DVERSION=\"$(VERSION)\"

COMPILER_VERSION := $(shell $(CC) --version)
CONTEXT := "$(COMPILER_VERSION) $(CFLAGS) $(LDFLAGS)"

ifneq (,$(or \
	$(findstring mingw,$(DUMPMACHINE)), \
	$(findstring windows,$(DUMPMACHINE))))
	OS ?= win
else
	OS ?= posix
endif

SRCS := espfixdep.c

ifeq ($(OS), posix)

SRCS += posix.c
BINARY := $(O)/$(NAME)
ARCHIVE := $(DIST)/$(NAME)-$(VERSION)-$(DUMPMACHINE).tar.gz

else ifeq ($(OS), win)

SRCS += win.c
BINARY := $(O)/$(NAME).exe
ARCHIVE := $(DIST)/$(NAME)-$(VERSION)-$(DUMPMACHINE).zip

endif

OBJS := $(SRCS:%.c=$(O)/%.o)

all: $(BINARY)

$(O):
	mkdir -p $@

$(DIST):
	mkdir -p $@

$(O)/context: FORCE | $(O)
	@echo $(CONTEXT) | md5sum | cmp -s - $@ || echo $(CONTEXT) | md5sum > $@

$(O)/%.o: %.c Makefile $(O)/context | $(O)
	$(CC) $(BUILD_DEFINES) $(BUILD_CFLAGS) -MD -MP -o $@ -c $<

$(BINARY): $(OBJS) | $(O)
	$(CC) $(BUILD_LDFLAGS) -o $@ $^

.PHONY: clean archive

FORCE:

archive: $(ARCHIVE)

%.tar.gz: $(BINARY) | $(DIST)
	mkdir -p $(O)/$(NAME)-$(VERSION)/bin
	cp $(BINARY) $(O)/$(NAME)-$(VERSION)/bin/
	cd $(O) && tar -cvzf $@ $(NAME)-$(VERSION)
	rm -rf $(O)/$(NAME)-$(VERSION)

%.zip: $(BINARY) | $(DIST)
	mkdir -p $(O)/$(NAME)-$(VERSION)/bin
	cp $(BINARY) $(O)/$(NAME)-$(VERSION)/bin/
	cd $(O) && zip -r $@ $(NAME)-$(VERSION)
	rm -rf $(O)/$(NAME)-$(VERSION)

clean:
	rm -rf $(O) $(ARCHIVE)

-include $(O)/*.d
