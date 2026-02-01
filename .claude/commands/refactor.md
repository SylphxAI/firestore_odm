---
name: refactor
description: Deep refactoring - modularity, deduplication, cleanup
---

# Refactor: Deep Codebase Improvement

Systematically refactor the codebase toward excellence. The goal is not just clean code, but code that is a joy to work with — maintainable, understandable, and extensible.

## Why Refactor?

> "Any fool can write code that a computer can understand. Good programmers write code that humans can understand." — Martin Fowler

Refactoring is about:
- **Future velocity** — clean code is faster to change
- **Bug prevention** — simple code has fewer hiding places for bugs
- **Onboarding** — new contributors can understand and contribute faster
- **Pride** — code you'd be proud to show anyone

## Targets

1. **Dead code** — if it's not used, it's noise
2. **Duplication** — DRY violations are bug factories
3. **Complexity** — if it's hard to understand, it's wrong
4. **Naming** — code should read like well-written prose
5. **Types** — weak types are hidden bugs waiting to happen
6. **Structure** — logical organization reduces cognitive load
7. **Dependencies** — unused deps are attack surface and bloat

## Process

### Phase 1: Understand
- What is the code trying to do?
- Why was it written this way?
- What are the dependencies and side effects?

### Phase 2: Refactor
For each improvement:
1. Understand the context first
2. Make one logical change
3. Verify behavior unchanged (tests, manual check)
4. Commit atomically: `refactor: description`

### Phase 3: Verify
- Tests pass
- Types check
- Linter happy
- Build succeeds
- Behavior unchanged

## Principles

* **Understand before changing** — never refactor blindly
* **One change at a time** — atomic commits, easy to revert
* **Behavior unchanged** — refactor ≠ rewrite
* **Tests are your safety net** — if no tests, add them first
* **When in doubt, simplify** — less code is usually better

## Exit Condition

The codebase should feel **clean, consistent, and comprehensible**.
