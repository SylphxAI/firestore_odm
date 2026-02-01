---
name: sweep
description: Find and fix all similar patterns across the project
---

# Sweep: Propagate Excellence Across the Codebase

You just did something — fixed a bug, improved code, optimized something, or established a pattern.

Now **sweep** through the entire project and apply the same improvement everywhere it's relevant.

## Mindset

> "If I fixed this here, where else does the same issue exist?"
> "If I improved this pattern, where else should it be applied?"
> "Don't just fix the symptom — eliminate the entire class of problems."

**Proactive, not reactive.** One fix should trigger a comprehensive sweep.

## Process

### 1. Identify What Was Just Done
- What did you fix, improve, or create?
- What pattern or principle does it represent?
- What was wrong with the old approach?

### 2. Define the Search Pattern
- What does "similar" look like?
- What code patterns indicate the same issue?
- What files/modules are likely affected?

### 3. Sweep the Codebase
Search systematically:
```
- Same file type (*.tsx, *.ts, etc.)
- Same directory/module
- Same pattern (hooks, components, utils, etc.)
- Same anti-pattern being fixed
```

### 4. Apply the Improvement Everywhere
For each similar case found:
- Apply the same fix/improvement
- Ensure consistency with the original
- Adapt as needed for context

### 5. Verify Completeness
- Did you catch everything?
- Run one more search to confirm
- No stragglers left behind

## Examples

### Code Pattern Sweep
```
Fixed: Null check missing in UserProfile
Sweep: Find all components accessing user data without null checks
Result: Fixed 12 similar issues across 8 files
```

### Type Safety Sweep
```
Fixed: Added proper TypeScript types to API response
Sweep: Find all `any` types in API layer
Result: Added proper types to 15 API functions
```

### Business Logic Sweep
```
Fixed: HK user was seeing CN tax options
Sweep: Find all region-dependent logic, verify correctness
Result: Fixed 5 similar locale issues across settings, billing, reports
```

### UX Pattern Sweep
```
Improved: Added loading state to save button
Sweep: Find all async actions without loading feedback
Result: Added loading states to 8 similar interactions
```

### Error Handling Sweep
```
Created: Reusable ErrorBoundary with retry
Sweep: Find all ad-hoc error handling in components
Result: Standardized error handling across 12 components
```

### Public-Facing Sweep
```
Fixed: Missing OG tags on product page
Sweep: Find all public pages missing proper meta tags
Result: Added OG/Twitter cards to 6 pages
```

## Output

### Sweep Summary
```
Original Work: [what was done]
Pattern Identified: [what to look for]
Files Scanned: [count]
Similar Cases Found: [count]
Cases Fixed: [count]
```

### Changes Made
| File | Change | Status |
|------|--------|--------|
| ... | ... | ✅ Fixed |

### Verification
- [ ] All similar patterns addressed
- [ ] No regressions introduced
- [ ] Consistency maintained

## Remember

* **One fix = comprehensive sweep** — never leave similar issues behind
* **Think in patterns** — what class of problem did you just solve?
* **Sweep all dimensions** — code, business logic, UX, public-facing
* **Be thorough** — check everywhere: code, tests, docs, marketing pages
* **Maintain consistency** — similar things should look and work similarly
* **This is how you reach State of the Art** — excellence everywhere, not just in spots
