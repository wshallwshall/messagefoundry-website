# `scripts/` — local dev tooling

Tooling that runs on a developer's machine. It is not part of the site, not linked from any page, and
adds no build step or dependency — the site stays plain static HTML + CSS. See `CLAUDE.md` → "Don't".

**But it is publicly reachable.** Pages publishes the whole repo root, so these files will answer at
`https://messagefoundry.org/scripts/…` once merged. That is already true of `README.md`, `CLAUDE.md`
and `docs/` today (all return `200`). Nothing here holds a secret, but write it as though a stranger
will read it: no credentials, no customer names, no internal hostnames.

## Session coordination

Several Claude Code sessions usually work this repo at once, in sibling worktrees under
`.claude/worktrees/`. Three files enforce that they don't trip over each other:

| File | Runs as | Does |
| --- | --- | --- |
| `worktree/session-context.ps1` | `SessionStart` hook | Prints who is live in this repo and what files they're changing, into the new chat's starting context. Silent when there's nothing to say. |
| `hooks/collision_gate.ps1` | `PreToolUse` hook on `Edit\|Write\|MultiEdit\|NotebookEdit` | **Denies** an edit to a file another live session is already changing. Fails open on any error. |
| `hooks/announce.ps1` | `UserPromptSubmit` hook | On a session's **first** prompt, tells it to announce itself to the other sessions **in this repo**. Once per session; silent when there are no peers. |
| `coord/lib.ps1` | dot-sourced by all three | Reads the session registry, fences each record for liveness, maps live sessions to the files they're changing. |

`coord/sessions.ps1` is the same data on demand:

```bash
pwsh -NoProfile -File scripts/coord/sessions.ps1
```

Run the regression tests from a linked worktree after touching any of it — every check in there marks
a defect that actually shipped, and all of them were caught by running the scripts, not reading them:

```bash
pwsh -NoProfile -File scripts/tests/coord.tests.ps1
```

### Where the wiring lives

**Not in this repo.** All three hooks are registered once per machine in `~/.claude/settings.json`, as
shims that resolve the script from whichever repo the session is in. User level is deliberate:
`/.claude/` isn't delivered by git, so project-level hooks never reach a worktree created outside the
harness. In a repo without these scripts the shim resolves nothing and exits 0, so the wiring is inert
everywhere else on the machine.

Two markers, on purpose:

- `mefor-coord` — SessionStart + PreToolUse. Installed by the **engine** repo's
  `scripts/coord/install-coordination.ps1`, shared with it.
- `mefor-web-announce` — UserPromptSubmit. Ours alone, installed by
  `coord/install-announce.ps1`. It gets its own marker because the engine's installer strips every
  `mefor-coord` entry for the events it manages before re-adding its own; sharing the marker would put
  this hook one re-install away from silent deletion.

The consequence: **those three script paths are load-bearing.** Rename or move one and that piece
stops — silently, because the shim exits 0 when it resolves nothing. That is exactly the state this
repo was in until 2026-07-30: the hooks were installed and looked installed, but found no scripts
here, across four worktrees and two live sessions.

Check the wiring:

```bash
pwsh -NoProfile -File scripts/coord/install-announce.ps1 -Status
```

```bash
pwsh -NoProfile -Command "(Get-Content ~/.claude/settings.json -Raw | Select-String 'mefor-coord' -AllMatches).Matches.Count"
```

Expect `2` for `mefor-coord` (one SessionStart, one PreToolUse). Each shim prefers the **primary
checkout** over the current worktree, so every session runs the same version of the protocol whatever
branch it's on — meaning changes here only take full effect once merged to `main`.

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

### The two ids are not the same id

The registry `sessionId` and the `ccd_session_mgmt` session id refer to the same session by **different
UUIDs**. Measured 2026-07-30 on one session in `trusting-borg-314ffc`: registry
`933195b8-43c1-4023-9573-ebed0fc4c78e`, MCP `local_938641cd-fe12-426c-9d4e-a0cce6e0e4ae`. They even
share a `93` prefix, so a glance suggests they match.

Everything this tooling prints is a **registry** id. Passing one to `send_message` or `list_events`
will not find the session. Resolve a peer by matching its **worktree path** against `cwd` in
`list_sessions`, which is why every banner and deny message prints the worktree.
