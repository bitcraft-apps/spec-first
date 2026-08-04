#!/bin/bash

# Verifies every workflows/*.js script stays under the AGENTS.md size limit and can be
# loaded by the Claude Code workflow loader.
# `claude plugin validate --strict` ignores workflows/ entirely, and a script the loader
# rejects only warns at load time — the failure surfaces later as `Workflow "x" not found`.
# Must be run from the repository root.

set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
    echo "FAIL: node is required to validate workflow scripts"
    exit 1
fi

if [ ! -d "./workflows" ]; then
    echo "FAIL: workflows/ directory not found (run from the repository root)"
    exit 1
fi

# Parses the meta block and prints its name. The loader needs a pure object literal, so this
# evaluates the block in an empty sandbox: a variable, a call or an interpolated identifier
# throws ReferenceError there. Backticks and spreads survive that, so they are rejected by hand.
# Then compares meta.phases[].title against the phase titles the body uses: the loader matches
# them by exact string, and a divergence only shows up as a stray progress group at run time.
# The literal-only rule makes that a string-set diff — the body is never evaluated.
# shellcheck disable=SC2016 # JavaScript, not shell: the $ belongs to a regex character class
READ_META='
import { readFileSync } from "node:fs"
import vm from "node:vm"

const file = process.argv[1]
const src = readFileSync(file, "utf8")
const fail = (msg) => { console.error(msg); process.exit(1) }

const match = src.match(/^export const meta = (\{[\s\S]*?\n\})\n/)
if (!match) fail("meta block not found (its closing brace must be a line of its own)")
const meta = match[1]

if (meta.includes("`")) fail("meta must be a pure literal: template strings are not allowed")
if (meta.includes("...")) fail("meta must be a pure literal: spreads are not allowed")

let value
try {
    value = vm.runInNewContext("(" + meta + ")", Object.create(null), { timeout: 1000 })
} catch (error) {
    fail("meta must be a pure literal: " + error.message)
}

if (typeof value.name !== "string") fail("meta.name is missing or not a string")
if (!/^sf-[a-z0-9-]+$/.test(value.name)) {
    fail("meta.name must match ^sf-[a-z0-9-]+$ so it cannot take a built-in name: " + value.name)
}

const declared = []
if (value.phases !== undefined) {
    if (!Array.isArray(value.phases)) fail("meta.phases is not an array")
    for (const entry of value.phases) {
        if (!entry || typeof entry.title !== "string") fail("every meta.phases entry needs a string title")
        declared.push(entry.title)
    }
}

// Titles a phase() call enters. A computed argument cannot be matched to meta, so it is rejected.
const body = src.slice(match[0].length)
const called = new Set()
for (const call of body.matchAll(/(^|[^\w.$])phase\(([^)]*)\)/g)) {
    const arg = call[2].trim()
    const literal = arg.match(/^([\x27"])([^\x27"]*)\1$/)
    if (!literal) fail("phase() needs a string literal to match meta.phases: phase(" + arg + ")")
    called.add(literal[2])
}

// An agent opts `phase:` enters a group too, so a title used only there is still entered.
const opts = new Set()
for (const opt of body.matchAll(/[{,]\s*phase:\s*([\x27"])([^\x27"]*)\1/g)) opts.add(opt[2])
const entered = new Set([...called, ...opts])

const problems = []
for (const title of called) {
    if (!declared.includes(title)) problems.push("phase(" + JSON.stringify(title) + ") has no meta.phases entry")
}
for (const title of opts) {
    if (!declared.includes(title) && !called.has(title)) {
        problems.push("an agent opts phase " + JSON.stringify(title) + " has no meta.phases entry")
    }
}
for (const title of declared) {
    if (!entered.has(title)) problems.push("meta.phases declares " + JSON.stringify(title) + " but nothing enters it")
}
if (problems.length > 0) fail(problems.join("; "))

console.log(value.name)
'

failed=0
names=""

for wf in ./workflows/*.js; do
    [ -f "$wf" ] || continue
    base=$(basename "$wf")

    # AGENTS.md caps a workflow script at 200 lines. The agent cap cannot apply unchanged:
    # one script holds several prompts plus their schemas.
    lines=$(awk 'END { print NR }' "$wf")
    if [ "$lines" -gt 200 ]; then
        echo "FAIL: $base has $lines lines (max 200)"
        failed=1
        continue
    fi

    # The loader skips any file that is not .js, and the parser needs meta first.
    if ! head -1 "$wf" | grep -q '^export const meta = {$'; then
        echo "FAIL: $base must start with 'export const meta = {'"
        failed=1
        continue
    fi

    # `node --check <file>` silently passes any file with module syntax, so parse via stdin.
    # The loader wraps the body in an async function, hence top-level return and await are
    # legal here and the meta block loses its `export` — the wrapper stays on line 1 so the
    # reported line numbers match the file.
    if ! CHECK_OUTPUT=$({ printf 'async function __check() {'; sed '1s/^export //' "$wf"; printf '}\n'; } | node --input-type=module --check 2>&1); then
        echo "FAIL: $base is not parseable JavaScript"
        echo "$CHECK_OUTPUT"
        failed=1
        continue
    fi

    if ! name=$(node --input-type=module -e "$READ_META" "$wf" 2>&1); then
        echo "FAIL: $base — $name"
        failed=1
        continue
    fi

    if echo "$names" | grep -q "^$name "; then
        other=$(echo "$names" | grep "^$name " | cut -d' ' -f2)
        echo "FAIL: $base and $other both use the name '$name'"
        failed=1
        continue
    fi

    names="$names$name $base
"
done

if [ "$failed" -eq 1 ]; then
    exit 1
fi

count=$(printf '%s' "$names" | grep -c . || true)
echo "PASS: $count workflow script(s) load"
