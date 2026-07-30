# `scripts/` — local dev tooling

Nothing here is served. The site stays plain static HTML + CSS with no build step; this directory is
tooling that runs on a developer's machine only. See `CLAUDE.md` → "Don't".

## Session coordination

Several Claude Code sessions usually work this repo at once, in sibling worktrees under
`.claude/worktrees/`. Three files enforce that they don't trip over each other:

| File | Runs as | Does |
| --- | --- | --- |
| `worktree/session-context.ps1` | `SessionStart` hook | Prints who is live in this repo and what files they're changing, into the new chat's starting context. Silent when there's nothing to say. |
| `hooks/collision_gate.ps1` | `PreToolUse` hook on `Edit\|Write\|MultiEdit\|NotebookEdit` | **Denies** an edit to a file another live session is already changing. Fails open on any error. |
| `coord/lib.ps1` | dot-sourced by both | Reads the session registry, fences each record for liveness, maps live sessions to the files they're changing. |

`coord/sessions.ps1` is the same data on demand:

```bash
pwsh -NoProfile -File scripts/coord/sessions.ps1
```

### Where the wiring lives

**Not in this repo.** The two hooks are registered once per machine in
`~/.claude/settings.json` (marker `mefor-coord`), as shims that resolve
`scripts/worktree/session-context.ps1` and `scripts/hooks/collision_gate.ps1` from whichever repo the
session is in. User level is deliberate: `/.claude/` isn't delivered by git, so project-level hooks
never reach a worktree created outside the harness.

The consequence: **those two paths are load-bearing.** Rename or move either one and coordination
stops — silently, because the shim exits 0 when it resolves nothing. That is exactly the state this
repo was in until 2026-07-30: the hooks were installed and looked installed, but found no scripts
here, across four worktrees and two live sessions.

Check the wiring is present:

```bash
pwsh -NoProfile -Command "(Get-Content ~/.claude/settings.json -Raw | Select-String 'mefor-coord' -AllMatches).Matches.Count"
```

Expect `2` (one SessionStart, one PreToolUse). The shim prefers the **primary checkout** over the
current worktree, so every session runs the same version of the protocol whatever branch it's on —
meaning changes here only take full effect once merged to `main`.

### Why it reads the registry instead of `ccd_session_mgmt`

Hooks are shell commands and cannot call MCP tools at all. And `ccd_session_mgmt`'s `list_sessions`
enumerates only desktop-spawned sessions — verified on 2026-07-30, it returned 4 while
`~/.claude*/sessions/*.json` held 6, the extras being a VS Code session and the caller. A gate blind
to a whole surface isn't a gate.

So the split is: **hooks read the registry** (every surface, deterministic, can block), and the model
uses `ccd_session_mgmt` for what only it can do — reading a peer's transcript and messaging it. The
model-side rules are in `CLAUDE.md` → "Parallel sessions".

Liveness is not a bare pid check: pids get reused and these records outlive their process, so
`lib.ps1` compares each process's start time against the recorded session start. Only `LIVE` and
`UNVERIFIED` block.
