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
