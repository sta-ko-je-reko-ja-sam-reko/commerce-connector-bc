# Implementation plan — commerce-connector-bc

The master plan across all three repositories lives in [`commerce-platform/docs/implementation-plan.md`](https://github.com/sta-ko-je-reko-ja-sam-reko/commerce-platform/blob/main/docs/implementation-plan.md). This is the slice this repository owns.

## What this app is for

Business Central stays the system of record for money, stock and orders. This extension is how the outside world asks: an API surface shaped for the consumer, outbound change notification that survives a rollback, and transactional staging for inbound orders.

## Delivered

33 objects across seven feature namespaces, compiling clean against BC 27 with zero errors and zero warnings under the escalated ruleset.

| Feature | Objects | State |
|---|---|---|
| Setup | table, page, interface, logic codeunit | done |
| Catalogue | item delta API query, category API page | done |
| Orders | staging header and lines, intake, Job Queue, two API pages, operator list | done |
| Events | change outbox, API page, operator list, reactions, subscriber proxy | done |
| General | service locator, install, four enums, two permission sets | done |
| Pricing | `CMC IPriceResolver`, temporary request buffer | **interface only** |
| Availability | `CMC IAvailability` | **interface only** |

## Phase 1 — what the projection still needs

**Stock feed.** Band per item and location — never a quantity. Item inventory is a FlowField, so a query object cannot carry it directly; the shape is most likely an API query summing `Item Ledger Entry` by item and location, or an API page over `Item` with the band calculated. Decide by measuring, and confirm the namespace from symbols rather than assuming.

**Price list delta.** Cursor-friendly feed over the Price List model, ordered so the same keyset predicate works.

**Test app.** Delivered: `test/` holds unit tests that inject fakes through `Define()` and the service locator, and integration tests over the order intake, the outbox, the operator list and the delta query. `tools/build.ps1` compiles both projects with all four analyzers; `tools/test.ps1` runs the suite in a container. Running it in CI still needs a service tier the hosted runners cannot provide.

## Phase 2 — pricing, availability, credit

**`CMC IPriceResolver` implementation** over the Price List model. Use BC's own price calculation rather than reimplementing the waterfall; the resolved value has to match what the sales document would produce, because `CMC Order Intake` asserts exactly that and rejects a mismatch.

**`CMC IAvailability` implementation** — available-to-promise per location and requested date.

**Credit endpoint** — credit limit, balance, overdue, blocked status. A hard gate at checkout.

## Phase 3 — the write path hardening

Currently the intake creates a document and stops. Still to add: quote-to-order conversion, cancellation, and an outbound status feed so the platform learns the document number and the shipment and invoice states.

## Standing rules

Beyond the AL coding standards in `CLAUDE.md`:

- **No business logic in a trigger, a field validation or a subscriber body.** Each delegates one line to an interface. This is what makes the behaviour testable with an injected fake and replaceable by a dependent extension.
- **`OnResolve…` publishers are the only publishers in the app**, and exist solely to let a dependent app substitute an implementation.
- **A loop that `Get`s a second table is a join.** Write a query object. At catalogue scale the difference is one round trip versus tens of thousands.
- **Idempotency is a unique database key**, never an application-level existence check. Two concurrent retries can both pass an `if not exists`; they cannot both pass a unique index.
- **The agreed price is asserted, never applied.** Accepting a caller-supplied price moves pricing authority outside the ERP.
