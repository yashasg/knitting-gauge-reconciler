fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Sync certificates and provisioning profiles

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Build and test with scheme-defined scope (CI)

### ios build

```sh
[bundle exec] fastlane ios build
```

Build without distribution

### ios test

```sh
[bundle exec] fastlane ios test
```

Run scheme-defined XCTest suite without distribution (CD gate: UI tests excluded; see issue #45)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight. Optional: bump:patch|minor|major

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit to App Store. Optional: bump:patch|minor|major

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
