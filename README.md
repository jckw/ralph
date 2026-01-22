# Ralph: Autonomous AI Agent Loop

My personal setup for Ralph - an autonomous AI agent that repeatedly executes Claude Code until all product requirements are satisfied. Each iteration operates with fresh context, maintaining continuity through git history, `progress.txt`, and `prd.json`.

> The original Ralph concept is by [@GrantSlatton](https://x.com/GrantSlatton/status/1908209426498691452). The files in `ralph/` are based on [snarktank/ralph](https://github.com/snarktank/ralph).

## Features

### Streaming Output
Real-time streaming of Claude's responses using `--output-format stream-json` with jq filtering. See exactly what the agent is thinking as it works, rather than waiting for each iteration to complete.

### Automatic Archiving
When you switch to a new PRD (different `branchName`), the previous `prd.json` and `progress.txt` are automatically archived to `archive/{date}-{branch-name}/`. This preserves the history of past Ralph runs without manual cleanup.

### Fresh Context Per Iteration
Each iteration spawns a new Claude Code instance with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

## How It Works

1. Read the PRD and check out the feature branch
2. Select highest-priority incomplete story (`passes: false`)
3. Implement that single story
4. Execute quality checks (typecheck, lint, tests)
5. Commit successful changes
6. Mark story complete in `prd.json`
7. Append learnings to `progress.txt`
8. Loop until all stories pass or iteration limit reached

## Setup

### Requirements
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` command-line JSON processor
- Git repository

### Installation

Copy the `ralph/` directory into your project (typically at the root or in a `plans/` folder):

```bash
cp -r ralph/ /path/to/your/project/plans/
```

### Configuration

1. Create your `prd.json` based on `references/prd.json.example`
2. Set the `branchName` for your feature
3. Define user stories with acceptance criteria

## Usage

```bash
# Run with default 10 iterations
./ralph/run.sh

# Run with custom iteration limit
./ralph/run.sh 20
```

## Key Files

| File | Purpose |
|------|---------|
| `run.sh` | Main execution loop |
| `PROMPT.md` | Agent instructions |
| `prd.json` | User stories with completion status |
| `progress.txt` | Persistent learning log (created on first run) |
| `archive/` | Auto-archived previous runs |

## PRD Format

```json
{
  "project": "MyApp",
  "branchName": "ralph/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "category": "backend|ui",
      "steps": ["Step 1", "Step 2"],
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Critical Success Factors

**Task Sizing**: Stories must fit within one context window. Good examples:
- Add a database column with migration
- Create a UI component
- Add an API endpoint

Bad examples (too large):
- "Build the entire dashboard"
- "Add authentication"

**Quality Gates**: Success depends on active typechecking, automated tests, and green CI. Broken code compounds across iterations.

**Browser Verification**: Frontend features should include "Verify in browser using dev-browser skill" in acceptance criteria.

## License

MIT
