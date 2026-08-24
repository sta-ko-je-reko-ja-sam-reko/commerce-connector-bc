# Next steps — commerce-connector-bc

Ordered. Each states what "done" means.

## 1. Test app

Nothing is unit-tested yet. The interfaces exist precisely so that they can be, and every day without tests makes the first ones harder to write.

- [ ] `test/app.json` — own id and id range, depending on this app plus the Microsoft test libraries (`Any`, `Library Assert`, `Test Runner`). Resolve their app ids from the artifact rather than typing them from memory.
- [ ] `test/src/codeunits/OrderIntakeTests.Codeunit.al` — inject a fake `CMC IOrderIntake` through `Define()` and assert the retry and abandon transitions with no database writes.
- [ ] `test/src/codeunits/CommerceSetupTests.Codeunit.al` — the page-size and line-cap validation boundaries.
- [ ] Add `-testFolders @('test')` to the build workflow and drop `-doNotRunTests`.

Done when: the build runs tests and fails on a red one.

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
