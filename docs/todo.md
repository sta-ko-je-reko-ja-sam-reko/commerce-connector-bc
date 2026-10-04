# Next steps — commerce-connector-bc

Ordered. Each states what "done" means.

## 1. Test app

- [x] `test/app.json` — ids 74000–74999, depending on this app plus `Library Assert`, `Any`, `Library Variable Storage`, `Test Runner` and `Application Test Library`.
- [x] Unit tests with injected fakes for setup, staging, the intake retry and abandon transitions, the Job Queue entry point and the service locator; integration tests for staged order to sales document, the price assertion, the queue, idempotency, the operator list, the change outbox and the item delta query.
- [x] `tools/build.ps1` (all four analyzers, zero warnings) and `tools/test.ps1` (publish and run in the dev container).
- [x] The build workflow compiles the test app.
- [ ] Run the tests in CI. GitHub-hosted runners cannot host a BC service tier, so this needs a self-hosted runner or a hosted sandbox; until then `tools/test.ps1` is the gate.

## 2. Stock feed

- [ ] Decide the shape. `Item.Inventory` is a FlowField, so a query object cannot carry it directly. Most likely an API query summing `Item Ledger Entry` by item and location.
- [ ] **Confirm the `Item Ledger Entry` namespace from symbols** — `Microsoft.Inventory.Ledger` is the working assumption from other repositories, not a verified fact for this one.
- [ ] Publish a band using the configured `Low Stock Threshold`, never a quantity.

Done when: the feed returns a band per item and location, and the convention gate and compile are both clean.

## 3. Price list delta feed

- [ ] Cursor-friendly feed over the Price List model, ordered so the same `(changedAt, key)` keyset predicate works as for items.

## 4. `CMC IPriceResolver` implementation

- [ ] Resolve through BC's own price calculation rather than reimplementing the waterfall. The value must match what a sales line would produce, because `CMC Order Intake` asserts exactly that and rejects a mismatch — an independent implementation would make every order fail.
- [ ] Populate the existing temporary `CMC Price Request Line` buffer.
- [ ] Register the implementation in the service locator with an `OnResolve…` publisher.

## 5. `CMC IAvailability` implementation

- [ ] Available-to-promise per location and requested date.

## 6. Credit endpoint

- [ ] Credit limit, balance, overdue balance, blocked status. Read-only.

## Known gaps carried forward

- **Order status is not published.** The platform learns nothing after the document is created — no document number feed, no shipment or invoice state. Phase 3.
- **No quote-to-order conversion, no cancellation.**
- **Nothing is deployed.** The app compiles and produces an artifact; it has never been published to an environment.
