# iOS work loop — build gate fix

**Owner:** Hopper / Curie  
**Goal:** Goals 1 and 5  
**Status:** local pass; external GitLab gate still blocked

Current cycle result:

- `app/build.sh` keeps the `iPhone 17 Pro` default simulator.
- The script now recognizes the Xcode 26.4 IOHIDLib post-test infrastructure diagnostic as benign only after all Swift unit/UI tests pass and no failed suites or test cases are present.
- `bash -n app/build.sh` exits 0.
- `node prototype/tests/gauge-math.test.js` exits 0 with 77 passed, 0 failed, 0 pending.
- `./app/build.sh test` exits 0 on the iPhone 17 Pro simulator.

The product goals remain locally satisfied, but merge remains blocked because GitLab project/pipeline/MR APIs are inaccessible from this environment without a `GITLAB_TOKEN`.
