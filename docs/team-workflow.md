# Team Workflow

How a team uses Spec First when the shared record of a change is a ticket, not a file in the
repository.

## The spec is not the shared record

`/sf:spec` writes `.sf/spec.md` on your machine. That directory stays out of the repository. The
setup script adds `.sf/` to your `.gitignore` on the first run. Your teammate never gets your spec.
Your next run replaces it or archives it.

Treat the spec as scratch. Your ticket holds the shared record of the change.

## Start from the ticket

Give the ticket description to the command:

```
/sf:spec Rate limit the API gateway. Return 429 after 100 requests per minute per key.
```

Write more than 15 words, or the command asks you questions first.

Read `.sf/spec.md` and correct it. [Read the spec before you go
on](getting-started.md#read-the-spec-before-you-go-on) lists what to check in each section.

## Put the spec back in the ticket

The spec now says more than the ticket. Ask your agent to update the ticket from the spec:

```
Update ticket API-482 from .sf/spec.md. Use the Scope and Acceptance Criteria sections.
```

Scope tells your team which files the change touches, and which work waits. Acceptance Criteria
gives your team the conditions to test. Your reviewer reads both before you write code.

Do this again each time you change the spec. The ticket is the record, so keep it current.

## Where review happens

| Point | What the reviewer reads | What it catches |
|-------|-------------------------|-----------------|
| The ticket, after `/sf:spec` | Scope and acceptance criteria | Wrong scope, missing conditions |
| The pull request, after `/sf:implement` | The diff | Wrong code |

The first point is the cheap one. A wrong scope costs one more `/sf:spec` run. The same mistake in a
pull request costs the whole change.

Check off each acceptance criterion in `.sf/spec.md` as you finish it. The implementation check
counts the criteria that stay unchecked, and it fails while any remain. Link the ticket from the
pull request.

## Work at the same time

Take one ticket each. One ticket gives one spec, one branch, one implementation.

Two checkouts never share `.sf/`, because each checkout has its own project root. A git worktree
counts as a project root, so a worktree gets its own `.sf/`. To put the artifacts somewhere else,
set `$SF_DIR`. [Artifact directory](technical-reference.md#artifact-directory) gives the rules.

On Claude Code, `/sf:implement --isolate` runs the implementation in a separate worktree. Use it to
keep the change off your working tree until you read it.

For one ticket that needs two people, split the ticket first. Then list the other person's files in
the `Out` part of Scope. Each spec then keeps the agent off the other person's work.

## Next steps

- [Getting Started](getting-started.md) — your first run, from install to updated docs.
- [Technical Reference](technical-reference.md) — `$SF_DIR`, the scripts and the schemas.
