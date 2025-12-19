VERSION = 0.2.0
NAME := espfixdep

O ?= build
DIST ?= dist
STAGE ?= stage
CFLAGS ?= -Wall -Werror -std=c99 -pedantic
LDFLAGS ?=

CROSS_COMPILE := $(subst $(lastword $(subst -, ,$(CC))),,$(CC))
WINDRES := $(CROSS_COMPILE)windres

O := $(abspath $(O))
DIST := $(abspath $(DIST))
STAGE := $(abspath $(STAGE))
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
