# Ralph: Autonomous AI Agent Loop

My personal setup for Ralph - an autonomous AI agent that repeatedly executes Claude Code until all product requirements are satisfied. Each iteration operates with fresh context, maintaining continuity through git history, `progress.txt`, and `prd.json`.

> The original Ralph concept is by [@GeoffreyHuntley](https://x.com/GeoffreyHuntley). The files in `ralph/` are based on [snarktank/ralph](https://github.com/snarktank/ralph). This is enhanced with some ideas from [Matt Pocock](https://x.com/mattpocockuk), in particular: [tracer bullets](https://www.aihero.dev/tracer-bullets) and [streaming](https://www.aihero.dev/heres-how-to-stream-claude-code-with-afk-ralph).

The core principle: don't overthink it. Let the agent decide what's important.

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

1. Word vomit your ideas into claude code, use subagents to explore the codebase, and get it to ask a tonne of clarifying questions.

> I want to implemnt [...] so that I can [...]. Please use up to 100 subagents to explore the codebase. You can ask me clarifying questions continuously about anything using the AskUserQuestionTool as long as the answers aren't obvious. The goal is to create a SPEC.md file that defines the ideal end state.

2. Get Claude Code to write this as a PRD.

> Read @SPEC.md and use the prd skill

3. Convert that PRD into a `prd.json` file.

(To be honest, I don't know if this is necessary; I think it is useful to encapsulate the human-readable PRD into individual units of work)

> Read @prd.json and use the ralph skill

4. Run the ralph loop

```bash
./ralph/run.sh
```

And watch ralph work!

### Installation

Run the following command in your project root:

```bash
curl -sL https://raw.githubusercontent.com/jckw/ralph/main/install.sh | bash
```

## Usage

```bash
# Run with default 10 iterations
./ralph/run.sh

# Run with custom iteration limit
./ralph/run.sh 20
```

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
