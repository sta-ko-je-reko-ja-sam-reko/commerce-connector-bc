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
| Events | `[ExternalBusinessEvent]` publishers for catalogue, price, stock, shipment and invoice changes |
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

Built with the AL Language extension and **AL-Go for GitHub** — build, version stamping and artefact publishing run in CI.

## Status

Early design. Object model and API contracts land before implementation.

## Licence

MIT
