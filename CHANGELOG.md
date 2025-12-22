## v0.3.0 (2025-12-22)

### New Features

- use makefile targets in pre-commit
- add clang-format and clang-tidy targets

### Bug Fixes

- use Linux stype for BreakBeforeBraces in clang-format
- **make**: correct indenting
- pass target to the clang-tidy
- **ci**: treat clang-tidy warnings as errors
- make clang-tidy happy
- add .clang-tidy config

## v0.2.3 (2025-12-20)

### Bug Fixes

- add os_init and os_exit function
- **make**: fix win manifest generation
- add init function

## v0.2.2 (2025-12-19)

### Bug Fixes

- **ci**: use install in a portable way

## v0.2.1 (2025-12-19)

### Bug Fixes

- **ci**: generate only tar.gz packages
- **make**: simplify package creation

## v0.2.0 (2025-12-19)

### New Features

- **ci**: build windows packages also with ucrt
- **make**: add makefile for downloading and enabling llvm-mingw
- **make**: add manifest for windows release

### Bug Fixes

- **ci**: add llvm-mignw into PATH before build
- **ci**: fix llvm-mingw toolchain installation
- **ci**: add correct release job dependencies
- **make**: corrent arch detection on macos
- **make**: fix typo DUMP -> DUMPMACHINE
- **ci**: just skip the actual release job if on workflow_dispatch
- **ci**: fix identifier used more than once
- **ci**: don't get version and changelog on workflow_dispatch
- **ci**: release -> dist
- **make**: add explicit targets for packages
- **make**: add deps on Makefile, CFLAGS and CC version
- **make**: compile for win also if dumpmachine contains windows string
- correct indentation in the Makefile

## v0.1.0 (2025-12-16)

### New Features

- initial implementation
