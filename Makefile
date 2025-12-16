VERSION = 0.1.0
NAME := espfixdep
DUMPMACHINE := $(shell $(CC) -dumpmachine)
ARCHIVE_NAME := $(NAME)-$(VERSION)-$(DUMPMACHINE)

O ?= $(abspath build/$(DUMPMACHINE))
RELEASE ?= $(abspath release)
CFLAGS ?= -Wall -Werror -std=c99 -pedantic
LDFLAGS ?=
BUILD_CFLAGS := $(CFLAGS) $(CFLAGS_APPEND)
BUILD_LDFLAGS := $(LDFLAGS) $(LDFLAGS_APPEND)
BUILD_DEFINES := -DVERSION=\"$(VERSION)\"

ifneq (,$(findstring mingw,$(DUMPMACHINE)))
	OS := win
else
	OS := posix
endif

SRCS := espfixdep.c

ifeq ($(OS), posix)

SRCS += posix.c
BINARY := $(O)/$(NAME)
ARCHIVE := $(RELEASE)/$(NAME)-$(VERSION)-$(DUMPMACHINE).tar.gz

else ifeq ($(OS), win)

SRCS += win.c
BINARY := $(O)/$(NAME).exe
ARCHIVE := $(RELEASE)/$(NAME)-$(VERSION)-$(DUMPMACHINE).zip

endif

OBJS := $(SRCS:%.c=$(O)/%.o)

all: $(BINARY)

$(O):
	mkdir -p $@

$(RELEASE):
	mkdir -p $@

$(O)/%.o: %.c | $(O)
		$(CC) $(BUILD_DEFINES) $(BUILD_CFLAGS) -MD -MP -o $@ -c $<

$(BINARY): $(OBJS) | $(O)
		$(CC) $(BUILD_LDFLAGS) -o $@ $^

.PHONY: clean archive

archive: $(ARCHIVE)

%.tar.gz: $(BINARY) | $(RELEASE)
		mkdir -p $(O)/$(NAME)-$(VERSION)/bin
		cp $(BINARY) $(O)/$(NAME)-$(VERSION)/bin/
		cd $(O) && tar -cvzf $@ $(NAME)-$(VERSION)
		rm -rf $(O)/$(NAME)-$(VERSION)

%.zip: $(BINARY) | $(RELEASE)
		mkdir -p $(O)/$(NAME)-$(VERSION)/bin
		cp $(BINARY) $(O)/$(NAME)-$(VERSION)/bin/
		cd $(O) && zip -r $@ $(NAME)-$(VERSION)
		rm -rf $(O)/$(NAME)-$(VERSION)

clean:
		rm -rf $(O) $(ARCHIVE)

-include $(O)/*.d
