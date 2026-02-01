---
name: catchup
description: Deep dive into project history, direction, and implementation details
---

# Catchup: Understand the Project Deeply

Get up to speed with the entire project — history, direction, and details.

## Phase 1: Git History Analysis

### Recent Commits
```bash
git log --oneline -50
git log --oneline --since="1 week ago"
git log --oneline --since="1 month ago" --until="1 week ago"
```

### Commit Patterns
- What areas are being actively worked on?
- What types of changes dominate? (feat, fix, refactor, docs)
- Who are the contributors and what do they focus on?
- Are there any recurring issues being fixed?

### Recent Activity by Area
```bash
git log --oneline --all -- "src/components/*" | head -20
git log --oneline --all -- "src/api/*" | head -20
git log --oneline --all -- "src/lib/*" | head -20
```

## Phase 2: Development Direction

### Read Project Documentation
1. **PRODUCT.md** — Vision, goals, target users, success metrics
2. **ARCHITECTURE.md** — Tech decisions, patterns, system design
3. **CLAUDE.md** — Project-specific knowledge, commands, gotchas
4. **README.md** — Setup, usage, contribution guidelines
5. **CHANGELOG.md** — Release history, breaking changes

### Identify Current Focus
- What features are in progress?
- What's the roadmap or next milestones?
- Are there open issues or PRs that indicate direction?

```bash
gh issue list --state open --limit 20
gh pr list --state open --limit 10
```

### Business & Marketing Strategy
- What's the monetization model? Is it working?
- Who are the competitors? How does this differentiate?
- What's the go-to-market strategy?
- How are users being acquired? (SEO, social, paid, referral)
- What public-facing assets exist? (landing page, blog, socials)

### Branch Analysis
```bash
git branch -a
git log main..HEAD --oneline  # if on feature branch
```

## Phase 3: Deep Implementation Research

### Codebase Structure
```bash
tree -L 2 -d src/  # or relevant directories
```

### Key Files to Understand
- Entry points (main, index, app)
- Configuration files (config, env, settings)
- Core business logic
- Database schema and migrations
- API routes and handlers
- Shared utilities and helpers

### Dependency Analysis
- What are the major dependencies?
- Are there any custom abstractions worth understanding?
- What patterns are consistently used?

### Test Coverage
- Where are tests located?
- What's tested, what's not?
- What do test failures tell us about the system?

## Output

### Executive Summary
```
Project: [name]
Stage: [MVP / Growth / Mature]
Focus: [current development focus]
Health: [assessment based on commits, issues, code quality]
```

### Recent Activity (Last 2 Weeks)
| Date | Area | Changes | Impact |
|------|------|---------|--------|
| ...  | ...  | ...     | H/M/L  |

### Development Direction
- **Current sprint/focus:** ...
- **Next milestones:** ...
- **Technical debt:** ...
- **Opportunities:** ...

### Key Findings
1. ...
2. ...
3. ...

### Recommendations
- **Immediate:** ...
- **Short-term:** ...
- **Consider:** ...

## Mindset

* Be thorough — read everything, assume nothing
* Connect the dots — understand WHY decisions were made
* Think forward — where is this project heading?
* Be critical — identify risks, gaps, opportunities
* Document discoveries — update CLAUDE.md with important findings
