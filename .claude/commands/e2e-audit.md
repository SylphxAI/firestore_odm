---
name: e2e-audit
description: Browser-based audit for business logic and product correctness
---

# E2E Audit: Browser-Based Product Validation

Open a browser, walk through the product, find business logic and UX issues.

**This is NOT about code correctness — code can be "correct" but business logic can be WRONG.**

## Why E2E Audit?

Static code analysis can't catch:
- User selects "Hong Kong" but sees China's "五險三金"
- Calendar showing Monday as week start for US users
- Currency conversion using stale rates
- Tax calculations wrong for specific regions
- Permissions that make no business sense
- Data inconsistency across related features

## Process

### 1. Launch Browser
```
mcp__playwright__browser_navigate - Go to product URL
mcp__playwright__browser_snapshot - Get current page state
```

### 2. Walk Through User Journeys

**Authentication:**
- [ ] Signup flow (all fields, validations, error messages)
- [ ] Login flow (remember me, forgot password)
- [ ] Logout and session handling

**Core Features:**
- [ ] Primary user workflow end-to-end
- [ ] Secondary features
- [ ] Settings and configuration
- [ ] Profile management

**Edge Cases:**
- [ ] Empty states
- [ ] Error states
- [ ] Boundary values (min/max)
- [ ] Invalid inputs

**Public-Facing Pages:**
- [ ] Landing/home page — value prop clear? CTA works?
- [ ] Pricing page — accurate? Links work?
- [ ] Docs/help — accessible? Search works?
- [ ] Social sharing — OG previews correct? Links work?

### 3. Test Business Logic

**Region/Locale Consistency:**
- Change user region → verify ALL related data updates
- Currency, date format, language, legal requirements
- Region-specific features show/hide correctly

**Data Consistency:**
- Related fields stay in sync
- Calculations produce business-correct results
- Aggregates match detail records

**Business Rules:**
- Permissions enforced correctly
- Workflow states valid
- Business constraints respected

### 4. Document Issues

For each issue found:
```bash
mcp__playwright__browser_take_screenshot  # Capture evidence
```

## Issue Categories

### Business Logic Errors
- Data doesn't match business expectations
- Rules applied incorrectly for context
- Cross-feature data inconsistency

### UX Issues
- Confusing user flows
- Missing feedback
- Unclear error messages
- Accessibility problems

### Visual Issues
- Layout broken
- Responsive issues
- Inconsistent styling

### Modern UI Patterns (Test for)
- Can you edit inline or must open modal/page?
- Can you drag & drop to reorder?
- Is there undo after destructive actions?
- Does it auto-save or require manual save?
- Do keyboard shortcuts work (⌘K, ⌘S, etc.)?
- Are loading states smooth (skeleton) or jarring (spinner)?
- Are transitions animated or instant jumps?
- Do inputs have search/autocomplete where useful?

## Browser Tools Reference

```
mcp__playwright__browser_navigate    - Go to URL
mcp__playwright__browser_snapshot    - Get page state (use this frequently)
mcp__playwright__browser_click       - Click elements
mcp__playwright__browser_fill_form   - Fill forms
mcp__playwright__browser_type        - Type text
mcp__playwright__browser_select_option - Select dropdown
mcp__playwright__browser_take_screenshot - Capture evidence
mcp__playwright__browser_press_key   - Keyboard input
```

## Output

### Issues Found
| # | Type | Description | Severity | Screenshot |
|---|------|-------------|----------|------------|
| 1 | Business Logic | HK user sees CN insurance | High | screenshot_1.png |
| 2 | UX | No loading state on submit | Medium | screenshot_2.png |

### Open GitHub Issues
```bash
gh issue create --title "[E2E] Brief description" --body "..." --label "e2e-audit"
```

## Mindset

* **Code-correct ≠ Business-correct** — always verify business logic
* Think like a real user, not a developer
* Test the unhappy paths
* Question every assumption
* If something feels wrong, it probably is
