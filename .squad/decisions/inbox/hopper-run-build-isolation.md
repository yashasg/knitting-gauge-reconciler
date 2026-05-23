### 2026-05-22T21:00:32-07:00: Hopper decision — isolate app/run.sh build workspace
**By:** Hopper
**What:** `app/run.sh` continues to delegate compilation to `app/build.sh`, but it does so with its own `.build/run-build` workspace and `COMPILER_INDEX_STORE_ENABLE=NO`.

**Why:** The shared `.build/derived-data` tree had accumulated an enormous Xcode index store (`Index.noindex/DataStore/v5` with 65535 entries), so the next `./app/run.sh` appeared broken because it spent minutes deleting DerivedData before any visible output. A dedicated run workspace preserves the architecture Tesla asked for (`run.sh` calls `build.sh`) without reusing the bloated shared cleanup target.

**Operational note:** Verify `app/run.sh` with two back-to-back launches after tooling changes; the second run is the one that catches DerivedData/index-store cleanup regressions.
