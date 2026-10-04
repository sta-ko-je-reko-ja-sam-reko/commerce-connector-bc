# commerce-connector-bc

AL extension for **Microsoft Dynamics 365 Business Central** that turns BC into a first-class commerce back end: the API surface, the outbound events and the transactional staging a storefront needs.

Companion to [commerce-platform](https://github.com/sta-ko-je-reko-ja-sam-reko/commerce-platform) and [commerce-integration](https://github.com/sta-ko-je-reko-ja-sam-reko/commerce-integration). BC stays the system of record for money, stock and orders; this extension is how the outside world asks.

## What it provides

| Area | Objects |
|---|---|
| Catalogue | API pages and API queries for items, variants, units of measure, attributes, assortment |
| Pricing | Bound action resolving customer-specific price, contract price and volume breaks for a basket |
| Availability | Bound action returning available-to-promise per location and requested date |
| Credit | Bound action returning credit standing and blocked status as a checkout gate |
| Order intake | Staging tables plus a Job Queue processor that creates sales quotes and orders idempotently |
| Events | A transactional change outbox written in the same transaction as the change, collected over its own API |
| Telemetry | `Session.LogMessage` with correlation IDs flowing through to Application Insights |

## Design rules

- **Aggregate entities, not raw tables.** API pages are shaped for the consumer; table exposure is not an API.
- **Outbound work leaves the transaction.** The posting transaction writes intent to a staging table; a Job Queue session ships it. No `HttpClient` while locks are held.
- **Idempotency is explicit.** A correlation table means a replayed message cannot post twice.
- **Least privilege per consumer.** One Entra app registration per caller, each with its own permission set.
- **Retry is data, not hope.** Staging rows carry `Status`, `Attempts`, `LastError` and `NextRetryAt`.
- **The contract is pinned.** CI validates the API surface against a versioned spec from `commerce-integration`, so a breaking change fails the build rather than the storefront.

## Conventions

- Object prefix `CMC`, dedicated object ID range
- Files named `ObjectName.ObjectType.al`
- Labels as `Label` variables in source, translations via `.xlf`
- No inline comments in procedure bodies; `///` summaries on global procedures only
- `SetLoadFields` on read-only records; query objects instead of nested record lookups

## Build

Compiled in CI against Business Central 27 on every push and pull request, using BcContainerHelper in compiler-folder mode: the AL compiler and platform symbols come from the published artifacts, with no container. The app and its test app compile with zero errors and zero warnings under the escalated ruleset and all four code analyzers. The `.app` packages are published as a build artifact.

Locally, `tools/build.ps1` compiles both projects against the BC artifact cache and fails on any warning; `tools/test.ps1` publishes them to a BC container and runs the test suite.

A second job runs a convention gate — affix, object id range and uniqueness, name length caps, file naming, sorted `using` statements, missing imports for our own namespaces, no inline comments — in seconds, before the artifact download the real compile needs.

## Layout

```
app/
├── app.json, AppSourceCop.json          affix CMC, ID range 70000-73999
├── docs/FEAT-001-CommerceFoundations/   technical documentation
└── src/
    ├── __General/    service locator, install, enums, permission sets
    ├── Setup/        commerce setup singleton
    ├── Catalogue/    item delta query, category API
    ├── Orders/       staging tables, intake, Job Queue, APIs, operator list
    ├── Events/       change outbox and subscriber proxies
    ├── Pricing/      contract only, implementation pending
    └── Availability/ contract only, implementation pending
test/                 unit tests with injected fakes, integration tests over the base application
tools/                build.ps1 and test.ps1
```

## Status

First slice implemented: setup, catalogue delta, category API, order staging and intake, change outbox, service locator, install and permission sets. Pricing, availability and credit are defined as interfaces and implemented next.

Compiles clean, with unit and integration tests in `test/`. Remaining gaps are listed under *Known Limitations* in the feature documentation.

## Licence

MIT
