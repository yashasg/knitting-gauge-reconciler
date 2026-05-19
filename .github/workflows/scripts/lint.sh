#!/usr/bin/env bash
# Run swift-format lint in strict mode over the app sources and tests.
set -euo pipefail

xcrun swift-format lint \
  --configuration .swift-format \
  --recursive \
  --parallel \
  --strict \
  app/Sources \
  app/Tests
