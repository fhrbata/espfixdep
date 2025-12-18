VERSION = 0.1.0
NAME := espfixdep
DUMPMACHINE := $(shell $(CC) -dumpmachine)
PKG_NAME := $(NAME)-$(VERSION)-$(DUMPMACHINE)

O ?= build
DIST ?= dist
STAGE ?= stage
CFLAGS ?= -Wall -Werror -std=c99 -pedantic
LDFLAGS ?=

O := $(abspath $(O))
DIST := $(abspath $(DIST))
STAGE := $(abspath $(STAGE))
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

else ifeq ($(OS), win)

SRCS += win.c
BINARY := $(O)/$(NAME).exe

endif

OBJS := $(SRCS:%.c=$(O)/%.o)

all: $(BINARY)

$(O):
	mkdir -p $@

$(DIST):
	mkdir -p $@

$(STAGE):
	mkdir -p $@

$(O)/context: FORCE | $(O)
	@echo $(CONTEXT) | md5sum | cmp -s - $@ || echo $(CONTEXT) | md5sum > $@

$(O)/%.o: %.c Makefile $(O)/context | $(O)
	$(CC) $(BUILD_DEFINES) $(BUILD_CFLAGS) -MD -MP -o $@ -c $<

$(BINARY): $(OBJS) | $(O)
	$(CC) $(BUILD_LDFLAGS) -o $@ $^

.PHONY: clean targz-pkg tarxz-pkg zip-pkg

FORCE:

targz-pkg: $(DIST)/$(PKG_NAME).tar.gz
tarxz-pkg: $(DIST)/$(PKG_NAME).tar.xz
zip-pkg: $(DIST)/$(PKG_NAME).zip

$(DIST)/$(PKG_NAME).tar.gz: $(BINARY) | $(DIST) $(STAGE)
	rm -rf $(STAGE)/targz
	mkdir -p $(STAGE)/targz/$(NAME)-$(VERSION)/bin
	cp $(BINARY) $(STAGE)/targz/$(NAME)-$(VERSION)/bin/
	cd $(STAGE)/targz && tar -cvzf $@ $(NAME)-$(VERSION)

$(DIST)/$(PKG_NAME).tar.xz: $(BINARY) | $(DIST) $(STAGE)
	rm -rf $(STAGE)/tarxz
	mkdir -p $(STAGE)/tarxz/$(NAME)-$(VERSION)/bin
	cp $(BINARY) $(STAGE)/tarxz/$(NAME)-$(VERSION)/bin/
	cd $(STAGE)/tarxz && tar -cvJf $@ $(NAME)-$(VERSION)

$(DIST)/$(PKG_NAME).zip: $(BINARY) | $(DIST) $(STAGE)
	rm -rf $(STAGE)/zip
	mkdir -p $(STAGE)/zip/$(NAME)-$(VERSION)/bin
	cp $(BINARY) $(STAGE)/zip/$(NAME)-$(VERSION)/bin/
	cd $(STAGE)/zip && zip -r $@ $(NAME)-$(VERSION)

clean:
	rm -rf $(O) $(DIST) $(STAGE)

-include $(O)/*.d
