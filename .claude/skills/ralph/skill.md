---
name: ralph
description: "Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json."
---

# Ralph PRD Converter

Converts existing PRDs to the prd.json format that Ralph uses for autonomous execution.

---

## What is Ralph?

Ralph is an autonomous agent loop that executes user stories one at a time:

1. Reads `prd.json` containing ordered user stories
2. Spawns a fresh Claude instance for each story (no memory between iterations)
3. Executes stories sequentially, updating `passes: true` when complete
4. Records issues or context in the `notes` field

**The key constraint:** Each story must fit in one context window because Ralph starts fresh each time.

---

## The Job

Take a PRD (markdown file or text) and convert it to `prd.json` in your ralph directory.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "category": "backend | ui",
      "steps": [
        "Step 1: What to do first",
        "Step 2: What to do next"
      ],
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Field Descriptions

- **category**: `"backend"` for schema/API/service changes, `"ui"` for frontend components
- **steps**: Explicit implementation steps Ralph should follow (actionable instructions)
- **acceptanceCriteria**: Verifiable criteria to confirm the story is complete
- **passes**: Always `false` initially; Ralph updates this when complete
- **notes**: Empty initially; Ralph records issues or context here

---

## Tracer Bullets: The First Story

**US-001 should be a tracer bullet** — a minimal end-to-end slice that touches all layers.

AI agents have a natural tendency to build complete horizontal layers in isolation. They'll build the entire database schema, then all the API endpoints, then all the UI. When something's wrong at the foundation, you don't discover it until you've built a mountain of code on top.

A tracer bullet validates your architecture immediately. If the database schema is wrong, Ralph finds out in US-001, not after completing five backend stories.

### Tracer bullet story characteristics:
- Touches database → API → UI in one small slice
- Is intentionally minimal — just enough to prove the path works
- Results in something you can actually see working

### After the tracer bullet:
Subsequent stories can expand horizontally. Add more fields, more endpoints, more UI components. You've already proven the vertical path works.

### Example transformation:

**Don't do this (horizontal layers):**
```
US-001: Add status field to database
US-002: Add status API endpoints
US-003: Display status in UI
US-004: Add status filter
```

**Do this (tracer bullet first):**
```
US-001: Add status field, display badge, allow toggle (tracer bullet)
US-002: Add status filter dropdown
US-003: Add status to edit modal
```

US-001 proves the entire vertical slice works. If something's broken, you know immediately.

---

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration (one context window).**

Ralph spawns a fresh instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column, display it, allow editing (tracer bullet)
- Add a UI component to an existing page
- Add a filter dropdown to a list
- Update a server action with new logic

### Too big (split these):
- "Build the entire dashboard" → Split into: tracer bullet, then individual widgets
- "Add authentication" → Split into: tracer bullet (login works), then registration, then password reset
- "Refactor the API" → Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it's too big.

---

## Story Ordering

Stories execute in array order. Earlier stories must not depend on later ones.

After the tracer bullet (which touches all layers), you can order remaining stories logically:

1. **US-001: Tracer bullet** — minimal end-to-end slice
2. **Expand backend** — additional schema, API endpoints
3. **Expand UI** — additional components, interactions
4. **Polish** — filters, edge cases, refinements

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include:
```
"Typecheck passes"
```

For stories with testable logic:
```
"Tests pass"
```

For UI stories:
```
"Verify in browser using dev-browser skill"
```

Frontend stories are NOT complete until visually verified.

---

## Conversion Rules

1. **US-001 is a tracer bullet** — minimal end-to-end vertical slice
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Category**: Use `"backend"` for schema/API/services, `"ui"` for frontend
4. **Steps**: Break down the work into explicit implementation steps
5. **All stories**: `passes: false` and empty `notes`
6. **branchName**: Derive from feature name, kebab-case, prefixed with `ralph/`
7. **Always add**: "Typecheck passes" to every story's acceptance criteria

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output prd.json:**
```json
{
  "project": "TaskApp",
  "branchName": "ralph/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field with badge display and toggle (tracer bullet)",
      "description": "As a user, I want to see and change task status so I can track progress.",
      "category": "ui",
      "steps": [
        "Add status field to tasks model: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration",
        "Create StatusBadge component with color variants (gray/blue/green)",
        "Add StatusBadge to TaskCard, wired to task.status",
        "Add onClick to badge that cycles status and calls update API"
      ],
      "acceptanceCriteria": [
        "Status column exists in database with correct enum values",
        "Each task card shows colored status badge",
        "Clicking badge cycles status: pending → in_progress → done → pending",
        "Status change persists after page refresh",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to focus on certain statuses.",
      "category": "ui",
      "steps": [
        "Add filter dropdown with options: All | Pending | In Progress | Done",
        "Persist filter selection in URL search params",
        "Filter task list based on selected status",
        "Add empty state message when no tasks match filter"
      ],
      "acceptanceCriteria": [
        "Filter dropdown shows all status options",
        "Selecting a filter updates the displayed tasks",
        "Filter persists in URL params across refresh",
        "Empty state shows when no tasks match",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add status to task edit modal",
      "description": "As a user, I want to change status from the edit modal for deliberate changes.",
      "category": "ui",
      "steps": [
        "Add status dropdown to task edit modal",
        "Pre-select current task status",
        "Include status in form submission"
      ],
      "acceptanceCriteria": [
        "Task edit modal has status dropdown",
        "Dropdown shows current status as selected",
        "Changing status and saving persists the change",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

Notice how US-001 is a tracer bullet: it adds the database field, creates the UI component, AND wires up the interaction — all in one story. This validates the entire vertical slice works before expanding.

---

## Archiving Previous Runs

**Before writing a new prd.json, check if there's an existing one from a different feature:**

1. Read the current `prd.json` if it exists
2. Check if `branchName` differs from the new feature's branch name
3. If different AND `progress.txt` has content beyond the header:
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.txt` to archive
   - Reset `progress.txt` with fresh header

**The ralph.sh script handles this automatically**, but if you're manually updating prd.json between runs, archive first.

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] **US-001 is a tracer bullet** (minimal end-to-end vertical slice)
- [ ] Each story is completable in one iteration (small enough)
- [ ] Each story has a `category` ("backend" or "ui")
- [ ] Each story has explicit `steps` (implementation instructions)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser using dev-browser skill" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] **Previous run archived** (if prd.json exists with different branchName)
