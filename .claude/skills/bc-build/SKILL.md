---
name: bc-build
description: Compile this AL app and interpret the result. Use when a change needs verifying against the compiler, when a build fails, or when adding the test project to the pipeline.
---

# Building and interpreting the result

## The two gates

**The convention gate** — `node scripts/check-al-conventions.mjs`. Seconds, no dependencies. Run it before every commit; it catches affix, id, naming, sorted `using`, missing imports for our own namespaces, inline comments and unresolved references.

**The compile** — `.github/workflows/build.yml`, on `windows-latest`. BcContainerHelper in compiler-folder mode: the AL compiler and platform symbols come from the published artifacts, no container, because GitHub-hosted Windows runners cannot run Windows containers. Around six minutes, most of it artifact download.

The target version is read from `app/app.json`, so the workflow and the manifest cannot drift.

## Reading a failure

```bash
gh run list --repo sta-ko-je-reko-ja-sam-reko/commerce-connector-bc --workflow Build --limit 1
gh run view <id> --log-failed | sed 's/\x1b\[[0-9;]*m//g' | grep -E "AL[0-9]{4}|AA[0-9]{4}"
```

Two failure shapes seen so far, both worth recognising:

**`AL1001` — a manifest problem.** Compilation stops at manifest validation *before reaching any source*, so one of these masks every code error behind it. Fix it and re-run before drawing conclusions about the code.

**`AL0185` — a missing `using` for one of our own namespaces.** Reported with no file name attached, which is tedious across 33 files. The convention gate now catches this and names the file, so it should never reach the compiler again.

## The test project

`test/` has its own `app.json` (ids 74000–74999) and an `AppSourceCop.json` carrying the same affixes as `app/`, which CodeCop reads even when the analyzer is off. The workflow compiles it in a second job, `compile-tests`, against the BC 29 artifacts (override with the repository variable `TEST_BC_VERSION`): against BC 27 its `Application Test Library` dependency does not resolve, because 27 ships that app as `Tests-TestLibraries`. Tests are not run in CI; that needs a service tier, which compiler-folder mode does not have.

Locally, `tools/build.ps1` compiles both projects with all four analyzers and fails on any warning, and `tools/test.ps1` publishes them to the dev container and runs the suite.

## Artifact

The compiled `.app` is uploaded as `commerce-connector-app`. Two things worth remembering about that step: `Run-AlPipeline` in compiler-folder mode writes to `.output`, not `.buildartifacts`; and `.output` is a dot-directory, so `upload-artifact` needs `include-hidden-files: true` or it silently matches nothing. `if-no-files-found` is set to `error` for exactly that reason — an earlier run uploaded nothing and still reported success.
