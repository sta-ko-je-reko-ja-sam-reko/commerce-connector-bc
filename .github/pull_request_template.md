## What changed

<!-- One paragraph. What this does, not how. -->

## Checks

- [ ] `node scripts/check-al-conventions.mjs` passes
- [ ] Every new object is in a permission set — an object in none is inaccessible
- [ ] No business logic in a trigger, a field validation or a subscriber body; each delegates one line to an interface
- [ ] A loop that `Get`s a second table has been rewritten as a query, or the reason it cannot be is stated
- [ ] New API surface matches the pinned contract in `commerce-platform`
- [ ] No customer names, customer data or client-specific business rules
