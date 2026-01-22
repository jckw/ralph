---
name: prd
description: "Generate a Product Requirements Document (PRD) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

# PRD Generator

Create detailed Product Requirements Documents that are clear, actionable, and suitable for implementation by developers or AI agents.

---

## The Job

1. Receive a feature description from the user
2. Ask 3-5 essential clarifying questions (with lettered options)
3. Generate a structured PRD based on answers
4. Save to `tasks/prd-[feature-name].md`

**Important:** Do NOT start implementing. Just create the PRD.

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core Functionality:** What are the key actions?
- **Scope/Boundaries:** What should it NOT do?
- **Success Criteria:** How do we know it's done?

### Format Questions Like This:

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI
```

This lets users respond with "1A, 2C, 3B" for quick iteration.

---

## Step 2: PRD Structure

Generate the PRD with these sections:

### 1. Introduction/Overview
Brief description of the feature and the problem it solves.

### 2. Goals
Specific, measurable objectives (bullet list).

### 3. User Stories

User stories define the work to be done. Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist of what "done" means

#### Tracer Bullets: The First Story

The first user story should be a **tracer bullet** — a minimal end-to-end slice that touches all layers of the system.

**Why?** AI agents (and developers) have a tendency to build complete horizontal layers in isolation. They'll build the entire database schema, then all the API endpoints, then all the UI — without ever validating that the pieces fit together. When something's wrong at the foundation, you don't discover it until you've built a mountain of code on top.

A tracer bullet validates your architecture immediately. If the database schema is wrong, you find out in US-001, not after you've built five more stories on a broken foundation.

**Tracer bullet stories:**
- Touch database, API, and UI in one small slice
- Are intentionally minimal — just enough to prove the path works
- Give you a working feature (however small) you can actually use

**After the tracer bullet**, subsequent stories can expand horizontally — add more fields, more UI components, more API endpoints — because you've already proven the vertical path works.

#### Story Format

```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck passes
- [ ] **[UI stories only]** Verify in browser using dev-browser skill
```

#### Story Guidelines

- **Size:** Each story should be completable in one focused session
- **Criteria:** Must be verifiable, not vague. "Works correctly" is bad. "Button shows confirmation dialog before deleting" is good.
- **UI stories:** Always include "Verify in browser using dev-browser skill" as acceptance criteria.

### 4. Functional Requirements
Numbered list of specific functionalities:
- "FR-1: The system must allow users to..."
- "FR-2: When a user clicks X, the system must..."

Be explicit and unambiguous.

### 5. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope.

### 6. Design Considerations (Optional)
- UI/UX requirements
- Link to mockups if available
- Relevant existing components to reuse

### 7. Technical Considerations (Optional)
- Known constraints or dependencies
- Integration points with existing systems
- Performance requirements

### 8. Success Metrics
How will success be measured?
- "Reduce time to complete X by 50%"
- "Increase conversion rate by 10%"

### 9. Open Questions
Remaining questions or areas needing clarification.

---

## Writing for AI Agents

The PRD reader may be a junior developer or AI agent. Therefore:

- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field and display on task cards (tracer bullet)
**Description:** As a user, I want to see and set task priority so I know what needs attention.

**Acceptance Criteria:**
- [ ] Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Priority badge displays on task cards (red=high, yellow=medium, gray=low)
- [ ] Clicking badge cycles through priority values and saves
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

*This is the tracer bullet. It touches database (schema), API (save), and UI (display + interaction) in one minimal slice. Once this works, we know the foundation is solid.*

### US-002: Add priority selector to task edit modal
**Description:** As a user, I want to change priority from the edit modal for more deliberate changes.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves on form submit
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-003: Filter tasks by priority
**Description:** As a user, I want to filter the task list to focus on high-priority items.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: Add `priority` field to tasks table ('high' | 'medium' | 'low', default 'medium')
- FR-2: Display colored priority badge on each task card
- FR-3: Allow changing priority via badge click (quick) or edit modal (deliberate)
- FR-4: Add priority filter dropdown to task list header

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks
- No sorting by priority (just filtering)

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params

## Success Metrics

- Users can see and change priority in under 2 clicks
- Filter allows focusing on high-priority work

## Open Questions

- Should we add keyboard shortcuts for priority changes?
```

---

## Checklist

Before saving the PRD:

- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] **First user story is a tracer bullet** (end-to-end vertical slice)
- [ ] User stories are small and specific
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Saved to `tasks/prd-[feature-name].md`
