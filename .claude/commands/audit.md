---
name: audit
description: Find all problems in the project - design, code, UX - and open issues
---

# Audit: Comprehensive Problem Discovery

Scan the entire project for issues. Find problems, don't fix them. Open GitHub issues for everything found.

**Rule: DO NOT fix anything. Only discover and document.**

## Scan Areas

### 1. Code Quality
- Dead code, unused imports, unreachable code
- TODOs, FIXMEs, HACKs left in code
- Weak typing (`any`, missing types, unsafe casts)
- Hardcoded values that should be config
- Debug artifacts in production (console.logs, commented code)
- Copy-paste duplication (DRY violations)
- Overly complex functions/files (hard to understand at a glance)
- Missing or inconsistent error handling
- Naming that doesn't convey intent
- Outdated or vulnerable dependencies

### 2. Business Logic Correctness

**Code-correct ≠ Business-correct. Review business rules in the code.**

- Region/locale logic: Does HK user see HK-specific data? (not China's 五險三金)
- Currency handling: Correct currency for user's region?
- Date/time: Timezone handling, week start day, date formats
- Tax/legal: Region-specific rules applied correctly?
- Permissions: Do access rules make business sense?
- Calculations: Business formulas correct? (not just mathematically)
- State machines: Valid business state transitions only?
- Validation rules: Match real-world business constraints?
- Default values: Sensible for the business context?
- Edge cases: Business-impossible states prevented?

### 3. Architecture
- Circular dependencies
- God objects/files doing too much
- Tight coupling between modules
- Missing abstractions
- Leaky abstractions
- Single points of failure
- Missing SSOT (multiple sources of truth)
- Inconsistent patterns across codebase

### 4. UI/UX Issues
- Confusing user flows
- Missing loading states (use skeleton, not spinner)
- Missing error states (with recovery actions)
- Missing empty states (with guidance)
- Inconsistent spacing/typography
- Non-responsive layouts
- Accessibility violations (contrast, keyboard nav, screen reader)
- Missing feedback on user actions
- Unclear CTAs or labels
- Information overload

### 5. Modern UI Patterns (Lack of)
- No inline editing (everything requires modal/page)
- No drag & drop where it makes sense
- No undo capability (destructive actions are permanent)
- No auto-save (users must remember to save)
- No keyboard shortcuts for power users
- No command palette (⌘K) for quick navigation
- Outdated inputs (dropdowns instead of combobox with search)
- No optimistic UI (waiting for server on every action)
- Jarring transitions (no smooth state changes)

### 6. Product Design
- Unclear value proposition
- Friction in core user journey
- Missing onboarding guidance
- Features that don't serve business goals
- Confusing navigation structure
- Missing progressive disclosure
- Power user needs unmet
- Beginner barriers too high

### 7. Performance
- Slow page loads
- Unnecessary re-renders
- Large bundle sizes
- Missing lazy loading
- N+1 queries
- Missing caching opportunities
- Unoptimized images/assets

### 8. Security
- Exposed secrets or credentials
- Missing input validation
- XSS vulnerabilities
- CSRF vulnerabilities
- Insecure dependencies
- Missing rate limiting
- Overly permissive CORS

### 9. Developer Experience
- Missing or outdated documentation
- Unclear setup instructions
- Flaky or missing tests
- Slow CI/CD pipeline
- Missing type definitions
- Confusing folder structure

### 10. Public-Facing & Exposure
- **SEO**: Missing/poor title tags, meta descriptions, structured data
- **Social Sharing**: Missing OG tags, Twitter cards, poor share previews
- **Landing/Home**: Unclear value prop above the fold, weak CTAs
- **README**: Missing badges, unclear quick start, no screenshots
- **Docs**: Incomplete, outdated, hard to navigate
- **Analytics**: Missing tracking, no conversion funnels
- **Branding**: Inconsistent voice, visuals, messaging

## Process

1. **Scan** each area systematically
2. **Document** every issue found with:
   - Clear description of the problem
   - Location (file, line, or area)
   - Impact (High/Medium/Low)
   - Category label
3. **DO NOT** attempt any fixes
4. **Open GitHub issues** for each problem found

## Issue Format

```bash
gh issue create --title "[Category] Brief description" --body "$(cat <<'EOF'
## Problem
What is wrong and where.

## Impact
Why this matters. What could go wrong.

## Evidence
Code snippets, screenshots, or specific locations.

## Suggested Category
- [ ] Bug
- [ ] Tech Debt
- [ ] UX Issue
- [ ] Performance
- [ ] Security
- [ ] Documentation
EOF
)" --label "audit"
```

## Output

After scanning, report:

### Summary
| Category | Issues Found | High | Medium | Low |
|----------|--------------|------|--------|-----|
| Code     | ...          | ...  | ...    | ... |
| UI/UX    | ...          | ...  | ...    | ... |
| ...      | ...          | ...  | ...    | ... |

### Issues Created
- #123 [Code] Description...
- #124 [UX] Description...
- ...

### Critical Issues (need immediate attention)
- ...

## Mindset

* Be thorough, not selective
* No issue is too small to document
* Assume nothing is perfect
* Fresh eyes find more problems
* The goal is awareness, not judgment
* Better to over-report than miss something
