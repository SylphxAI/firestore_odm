---
name: issues
description: Process and clear GitHub Issues - review, fix, close
---

# Issues: GitHub Issue Processing

Process all open GitHub Issues until the list is clear.

## Process

### Phase 1: List Issues

```bash
gh issue list --state open
```

### Phase 2: For Each Issue

1. Read the issue details: `gh issue view <number>`
2. Understand the problem — what is being reported?
3. Investigate the codebase — find the root cause
4. Fix the issue — address root cause, not symptom
5. Write tests to prevent regression
6. Commit with reference: `fix: description (closes #<number>)`
7. Push immediately

### Phase 3: Close and Report

After fix is pushed:
1. Comment on the issue with solution summary
2. Close the issue: `gh issue close <number>`
3. Move to next issue

## Rules

* Every issue must be addressed — no omissions
* Fix root cause, not symptoms
* Scan for similar issues after each fix
* Write tests for every fix
* Commit atomically with issue reference
* Push immediately after each fix

## Exit Condition

All open issues are closed.
