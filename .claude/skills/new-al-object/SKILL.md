---
name: new-al-object
description: Author a new AL object in this app to the project standards - namespace, affix, id, delegation pattern, permission set, API exposure and documentation. Use when adding any table, page, codeunit, query, enum, interface or permission set.
---

# Adding an AL object

## 1. Place it

`app/src/<Feature>/<plural object type>/`. Features are `Setup`, `Catalogue`, `Orders`, `Events`, `Pricing`, `Availability`, and `__General` for anything cross-cutting. A new feature gets a new folder and a new namespace.

## 2. Name and number it

- Affix `CMC`, then the name. Cap 30 characters — 20 for `permissionset`, `permissionsetextension` and `entitlement`, where the cap is a compiler error rather than a warning. Descriptive wording goes in the `Caption`.
- Next free id in **57100–57199**. Ids are unique per object type; the convention gate checks this.
- File name is the object name with the affix stripped and separators removed, then `.<Type>.al`. If you abbreviated the object name to fit the cap, the file name uses the **same** abbreviation — mismatching the two is the most common AA0215 trip-up.

## 3. Namespace it

First line `namespace CommerceConnector.<Feature>;`, then a `using` for every other namespace referenced, sorted alphabetically.

**Do not guess a Microsoft namespace.** Use Go-to-Definition or the symbol package — the base application's folder path is not the namespace. Confirmed for this app: `Microsoft.Inventory.Item` (Item, Item Variant, Item Unit of Measure, Item Category), `Microsoft.Foundation.UOM`, `Microsoft.Inventory.Location`, `Microsoft.Sales.Customer`, `Microsoft.Sales.Document`, `Microsoft.Foundation.NoSeries`, `System.Threading` (Job Queue), `System.Utilities` (Confirm Management), `System.Telemetry`.

Forgetting a `using` for one of **our own** namespaces produces `AL0185`, which the compiler reports with no file name attached. `scripts/check-al-conventions.mjs` catches it and names the file.

## 4. If it is a table

- `DataClassification` set. `Caption` and `ToolTip` on every field — author the ToolTip on the table field so it flows to every bound page control.
- Primary key named `PK`, `Clustered = true`.
- **No logic in a trigger or field validation.** Each delegates one line:
  ```al
  trigger OnValidate()
  begin
      Logic().Validate_<Field>(Rec);
  end;
  ```
  with a `CMC I<Entity>` interface, a `CMC <Entity> Logic` default implementation, a cached interface var, a lazily-defaulting `Logic()`, and a public `Define()` for injecting a fake. Copy the shape from `CMC Commerce Setup`.
- A uniqueness guarantee is a **unique key**, not an application check.
- Every persisted table gets an API page. A `TableType = Temporary` buffer gets neither an API page nor `tabledata` permission — only the `table` object permission.

## 5. If it is an API page or query

Own `APIPublisher = 'stakojerekojasamreko'`, `APIGroup = 'commerce'`, `APIVersion = 'v1.0'`. camelCase field names, each with a `Caption`. `ODataKeyFields = SystemId`. Never reuse `microsoft` or `v2.0`.

A feed the platform pages through must expose a change marker and a stable tie-break column, and order by both — `commerce-integration` resumes with a composite keyset predicate over exactly that ordering.

## 6. If it is an event subscriber

The subscriber codeunit is a pure proxy: `SingleInstance`, only `[EventSubscriber]` procedures, no globals, no labels, no local procedures. Each body is one line through `CMC Service Locator` to an interface. Use `true, true` for the license and permission flags so the subscriber skips rather than throwing for users without an entitlement.

**Do not add `[IntegrationEvent]` or `[BusinessEvent]` publishers.** `OnResolve…` in the service locator is the only justified publisher, and only to substitute an implementation.

## 7. Add it to the permission sets

`CMC Commerce - Edit` and, if readable, `CMC Commerce - Read`. An object in no permission set is inaccessible, and in the cloud is flagged as not included in any entitlement.

## 8. Verify

```bash
node scripts/check-al-conventions.mjs
```

Then let CI compile it. The gate takes seconds; the real compile needs a six-minute artifact download, so run the gate first and fix everything it finds before pushing.

## 9. Document it

Add the row to the Objects table in `app/docs/FEAT-001-CommerceFoundations/technical-documentation.md`, and update `docs/todo.md` if this closes an item.
