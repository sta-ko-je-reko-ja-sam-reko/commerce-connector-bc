# commerce-connector-bc

AL extension turning Business Central into a commerce back end. Affix `CMC`, object id range **70000–73999** (a future test app gets **74000–74999**; this is the app's block in the PTE range shared by all the owner's apps, which must install side by side, so never use ids outside it — registry: bc-dev-templates), target application **27.0.0.0**, runtime **16.0**.

## Orientation

1. [`docs/implementation-plan.md`](docs/implementation-plan.md) — what this app owns and what is delivered
2. [`docs/todo.md`](docs/todo.md) — the next actions, ordered, each with a definition of done
3. [`app/docs/FEAT-001-CommerceFoundations/technical-documentation.md`](app/docs/FEAT-001-CommerceFoundations/technical-documentation.md) — the object inventory and the design decisions behind it
4. The master plan and the architecture decisions live in [`commerce-platform`](https://github.com/sta-ko-je-reko-ja-sam-reko/commerce-platform)

## Working here

```bash
node scripts/check-al-conventions.mjs     # seconds; run before every commit
```

The real compile runs in CI against BC 27 artifacts. Locally, use the AL Language extension with `AL: Download Symbols`; the ruleset path in `app/.vscode/settings.json` expects the shared conventions wired in at `.bc-conventions/`, which is not vendored here.

## AL conventions

These come from the shared BC development standards. Treat a violation in a diff as a defect, not a style preference — `scripts/check-al-conventions.mjs` enforces most of them.

- **Affix `CMC`** on every object name and every field added to a standard table.
- **`namespace CommerceConnector.<Feature>;` on the first line**, then a `using` for every other namespace referenced, **sorted** (AA0477). Once a file declares a namespace the global lookup is gone — a sibling-feature reference without a `using` fails as `AL0185`, which the compiler reports with no file name attached.
- **File name = object name, affix stripped, separators removed**, then `.<Type>.al` (AA0215 / LC0015).
- **Names cap at 30 characters; permission sets, permission set extensions and entitlements cap at 20** — the descriptive wording goes in the `Caption`.
- **No inline `//` comments anywhere.** `///` summaries on public and internal procedures only, never on `local procedure` — the sole exception being an `OnResolve…` publisher, which is a documented extension point.
- **`Caption` and `ToolTip` on every field**; author the ToolTip on the table field so it flows to every bound page control.
- **Labels, never inline strings**, in `Error`, `Message` and `StrSubstNo`. Suffix by purpose: `Msg`, `Err`, `Qst`, `Txt`, `Lbl`.
- **`ConfirmManagement.GetResponseOrDefault`**, never a bare `Confirm`.
- **`DataClassification` on every table.** Primary key named `PK`, `Clustered = true`.
- **`begin..end` only around compound statements.**
- **Hardcoded values go in a local procedure returning the value**, not scattered as literals.
- **`Round(Amount)` with no precision for money** — it honours the configured rounding. A hardcoded `0.01` overrides it and is wrong for currencies that round differently.
- **Every new object goes into a permission set as it is created.** An object in none is inaccessible.

## The patterns that matter more than the conventions

**No business logic in a trigger, a field validation or a subscriber body.** Each delegates exactly one line to an interface resolved through a lazily-defaulting `Logic()`, or through the `CMC Service Locator`. The interface is what makes the behaviour unit-testable with an injected fake and replaceable by a dependent extension. See `CMC Order Staging` and `CMC Commerce Setup` for the shape.

**No event publishers except `OnResolve…`.** Extension is provided by swapping an implementation, not by participating in a flow. A publisher that lets someone join a flow rather than replace an implementation gives dependent apps two competing ways to change the same behaviour, and the event path bypasses the interface contract that makes the logic testable.

**A loop that `Get`s a second table is a join.** Write a query object with a linked DataItem. This will not occur to you while writing the loop, so check every loop in a diff for it. At catalogue scale it is one round trip against tens of thousands.

**`SetLoadFields` on records that are read and never written.** If the record is later modified, BC re-reads the whole row before the write anyway, so the partial load costs an extra SELECT instead of saving one.

**Idempotency is a unique database key**, never an application-level existence check. Two concurrent retries can both pass an `if not exists`; they cannot both pass a unique index.

**Never resolve a Microsoft namespace by guessing.** Use Go-to-Definition or the symbol package. The folder path in the base application is not the namespace.

## This is a public portfolio repository

No customer names, customer data, client-specific business rules, or material from client projects. The affix is `CMC` and the object names are generic by design.
