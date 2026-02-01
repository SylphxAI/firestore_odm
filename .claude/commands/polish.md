---
name: polish
description: Elevate UI from functional to delightful - modern patterns and interactions
---

# Polish: Elevate UI to Modern Excellence

Transform functional UI into delightful, state-of-the-art interfaces. This is not about fixing bugs — it's about raising the bar from "it works" to "it's a joy to use".

## Philosophy

> **"Reduce user thinking, increase system intelligence."**

Modern UI is:
- **Direct** — interact with the thing itself, not a separate control
- **Responsive** — immediate feedback, never leave users wondering
- **Forgiving** — undo everywhere, mistakes are recoverable
- **Smart** — anticipate needs, reduce manual input
- **Fluid** — smooth transitions, not jarring jumps

## Upgrade Dimensions

### 1. Direct Manipulation

**Before → After:**
- Upload button → Click avatar/image to change
- Edit button → Click text to edit inline
- Reorder with arrows → Drag & drop
- Separate settings page → Contextual controls where needed

**Principle:** Users should manipulate the object itself, not a proxy control.

### 2. Rich Feedback

**Before → After:**
- Spinner → Skeleton/shimmer loading
- Submit and wait → Optimistic update (instant, sync in background)
- Alert box → Toast notification (non-blocking)
- Page reload → Smooth transition/animation
- Binary states → Progress indicators with context

**Principle:** Every action should have immediate, visible response.

### 3. Modern Input Patterns

**Before → After:**
- Text field for tags → Chip/tag input with autocomplete
- Dropdown select → Combobox with search and create
- File upload button → Drag & drop zone + paste support
- Date text input → Visual picker + natural language ("next monday")
- Manual everything → Smart defaults + auto-complete

**Principle:** Inputs should be as intelligent as possible.

### 4. Information Architecture

**Before → After:**
- All fields visible → Progressive disclosure (show when needed)
- Fixed layout → Adaptive layout based on content/task
- Pagination → Infinite scroll with virtualization
- Menu diving → Command palette (⌘K) for quick access
- Nested menus → Flat structure + contextual actions

**Principle:** Show the right information at the right time.

### 5. Trust & Control

**Before → After:**
- "Are you sure?" dialogs → Undo everywhere (Gmail style)
- Save button → Auto-save with visible status
- Silent operations → Visible system status (syncing, saved, offline)
- Error = dead end → Recovery suggestions + retry options
- Single version → Version history + restore

**Principle:** Users should feel safe to explore and experiment.

### 6. Visual Polish

**Before → After:**
- Flat/harsh shadows → Subtle depth (light shadows, blur)
- Color as decoration → Color as information (status, priority)
- Uniform text → Clear typography hierarchy
- Cramped layout → Consistent spacing system (breathing room)
- Static states → Purposeful motion (guide attention, show relationships)

**Principle:** Visual design should reduce cognitive load, not add to it.

### 7. Power User Enablement

**Before → After:**
- Mouse only → Keyboard shortcuts for common actions
- One item at a time → Bulk selection and actions
- Fixed views → Customizable columns/layouts
- No way out → Export/import data
- Hidden features → Discoverable via command palette

**Principle:** Reward expertise without punishing beginners.

### 8. Mobile & Touch

**Before → After:**
- Desktop-only design → Responsive from the start
- Click targets → Touch-friendly tap targets (44px+)
- Hover states only → Touch gestures (swipe, long-press)
- Desktop modals → Bottom sheets on mobile
- Mouse precision → Finger-friendly spacing

**Principle:** Touch is not a degraded experience — it's a different one.

## Process

### 1. Audit Current State
Walk through the UI as a user:
- Where do I have to click too many times?
- Where am I waiting without feedback?
- Where do I feel friction or annoyance?
- What feels dated compared to best-in-class apps?

### 2. Prioritize by Impact
Focus on:
- High-frequency interactions (used daily)
- Pain points (users complain or work around)
- First impressions (onboarding, landing)

### 3. Apply Modern Patterns
For each area:
- Identify the current pattern
- Choose the modern equivalent
- Implement with smooth transitions
- Ensure accessibility is maintained

### 4. Verify Quality
- Interactions feel snappy (< 100ms feedback)
- Animations are smooth (60fps)
- Works with keyboard navigation
- Responsive across screen sizes
- Accessible (screen readers, contrast)

## Reference: Best-in-Class Examples

| Pattern | See How It's Done |
|---------|-------------------|
| Command Palette | Linear, Raycast, VS Code (⌘K) |
| Inline Editing | Notion, Airtable |
| Drag & Drop | Trello, Figma |
| Optimistic UI | Twitter/X likes, Gmail send |
| Skeleton Loading | Facebook, LinkedIn |
| Tag Input | GitHub labels, Notion tags |
| Auto-save | Google Docs, Figma |

## Accessibility is Non-Negotiable

Modern ≠ Inaccessible. Every polish must maintain:
- **Keyboard navigation** — all interactions work without mouse
- **Screen reader support** — proper ARIA labels, announcements
- **Reduced motion** — respect `prefers-reduced-motion`
- **Color contrast** — WCAG AA minimum (4.5:1 text, 3:1 UI)
- **Focus indicators** — visible, clear focus states

## Remember

* **Polish is not decoration** — it's reducing friction
* **Motion with purpose** — guide attention, show relationships
* **Accessibility first** — modern doesn't mean inaccessible
* **Performance is UX** — slow animations are worse than none
* **Consistency compounds** — one pattern, used everywhere
* **Steal from the best** — Linear, Figma, Notion set the bar
