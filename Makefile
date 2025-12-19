VERSION = 0.2.1
NAME := espfixdep

O ?= build
DIST ?= dist
STAGE ?= stage
CFLAGS ?= -Wall -Werror -std=c99 -pedantic
LDFLAGS ?=

CROSS_COMPILE := $(subst $(lastword $(subst -, ,$(CC))),,$(CC))
WINDRES := $(CROSS_COMPILE)windres

BUILD_CFLAGS := $(CFLAGS) $(CFLAGS_APPEND)
BUILD_LDFLAGS := $(LDFLAGS) $(LDFLAGS_APPEND)
BUILD_DEFINES := -DVERSION=\"$(VERSION)\"

COMPILER_VERSION := $(shell $(CC) --version)
CONTEXT := "$(COMPILER_VERSION) $(CFLAGS) $(LDFLAGS)"

DUMPMACHINE := $(shell $(CC) -dumpmachine)

ifneq ($(findstring x86_64,$(DUMPMACHINE)),)
    ARCH := x86_64
else ifneq ($(findstring i686,$(DUMPMACHINE)),)
    ARCH := x86
else ifneq ($(findstring aarch64,$(DUMPMACHINE)),)
    ARCH := arm64
else ifneq ($(findstring arm64,$(DUMPMACHINE)),)
    ARCH := arm64
else ifneq ($(findstring arm,$(DUMPMACHINE)),)
    # Check for Hard Float vs Soft Float
    ifneq ($(findstring gnueabihf,$(DUMPMACHINE)),)
        ARCH := armhf
    else
        ARCH := armel
    endif
endif

ifneq ($(findstring mingw,$(DUMPMACHINE)),)
	OS ?= win
else ifneq ($(findstring windows,$(DUMPMACHINE)),)
	OS ?= win
else ifneq ($(findstring apple,$(DUMPMACHINE)),)
	OS ?= macos
else
	OS ?= linux
endif

PKG_NAME := $(NAME)-$(VERSION)-$(OS)-$(ARCH)$(PKG_SUFFIX)

SRCS := espfixdep.c

ifeq ($(OS), win)

SRCS += win.c
BINARY := $(O)/$(NAME).exe

else

SRCS += posix.c
BINARY := $(O)/$(NAME)

endif

OBJS := $(SRCS:%.c=$(O)/%.o)
ifeq ($(OS), win)
	OBJS += $(O)/manifest.o
endif

all: $(BINARY)

define MANIFEST_XML
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity
    type="win32"
    name="$(NAME)"
    version="$(VERSION)"
    processorArchitecture="*"
  />
  <application>
    <windowsSettings>
      <activeCodePage xmlns="http://schemas.microsoft.com/SMI/2019/WindowsSettings">UTF-8</activeCodePage>
    </windowsSettings>
  </application>
</assembly>
endef

$(O)/manifest.xml: Makefile | $(O)
	$(file >$@,$(MANIFEST_XML))

$(O)/manifest.rc: $(O)/manifest.xml
	$(file >$@,1 RT_MANIFEST "$<")

$(O)/manifest.o: $(O)/manifest.rc $(O)/context
	$(WINDRES) --input=$< --output=$@

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

.PHONY: clean targz-pkg tarxz-pkg zip-pkg

FORCE:

targz-pkg: $(DIST)/$(PKG_NAME).tar.gz
tarxz-pkg: $(DIST)/$(PKG_NAME).tar.xz
zip-pkg: $(DIST)/$(PKG_NAME).zip

$(STAGE): $(BINARY)
	@rm -rf $@
	@install -d $@/$(NAME)-$(VERSION)/bin
	@install $(BINARY) $(STAGE)/$(NAME)-$(VERSION)/bin
	@touch $@

$(DIST)/$(PKG_NAME).tar.gz: $(STAGE) | $(DIST)
	cd $(STAGE) && tar -cvzf $(abspath $@) $(NAME)-$(VERSION)

$(DIST)/$(PKG_NAME).tar.xz: $(STAGE) | $(DIST)
	cd $(STAGE) && tar -cvJf $(abspath $@) $(NAME)-$(VERSION)

$(DIST)/$(PKG_NAME).zip: $(STAGE) | $(DIST)
	cd $(STAGE) && zip -r $(abspath $@) $(NAME)-$(VERSION)

clean:
	rm -rf $(O) $(DIST) $(STAGE)

-include $(O)/*.d
