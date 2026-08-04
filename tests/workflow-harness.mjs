// Runs a workflow script's control flow without calling a model.
//
// A workflow script's only outside contacts are the injected globals, so stubbing them runs the
// real body: the args normalization, the argument guards and the gates that skip a phase. The
// error paths never run in a manual /sf: run, which is how a spec once landed in the wrong
// directory with "requirements not provided" in it.
//
// Usage: node tests/workflow-harness.mjs <workflow.js> <fixture.json>
//
// The fixture is { "args": <any>, "agents": { "<label>": <result> } }. `args` reaches the script
// verbatim, so a string there exercises the JSON-string path and an object the object path. A
// label the fixture omits resolves to null, which is what a dead subagent returns.
//
// Prints one JSON line: { result, agents, phases, logs }.

import { readFileSync } from 'node:fs'

const [file, fixturePath] = process.argv.slice(2)

if (!file || !fixturePath) {
  console.error('usage: node tests/workflow-harness.mjs <workflow.js> <fixture.json>')
  process.exit(2)
}

const fixture = JSON.parse(readFileSync(fixturePath, 'utf8'))
const results = fixture.agents ?? {}

const agents = []
const phases = []
const logs = []

const agent = async (_prompt, opts = {}) => {
  const label = opts.label ?? null
  agents.push(label)
  return label in results ? results[label] : null
}

const parallel = (thunks) => Promise.all(thunks.map((thunk) => thunk()))

const pipeline = (items, ...stages) => Promise.all(items.map(async (item, index) => {
  let value = item
  for (const stage of stages) {
    value = await stage(value, item, index)
  }
  return value
}))

const phase = (title) => phases.push(title)
const log = (message) => logs.push(message)

// The loader wraps the body in an async function, so top-level return and await are legal and the
// meta block loses its `export`. Same transform as scripts/check-workflow-scripts.sh.
const source = readFileSync(file, 'utf8').replace(/^export /, '')
const body = new Function(
  'agent', 'parallel', 'pipeline', 'phase', 'log', 'args',
  `return (async () => {\n${source}\n})()`,
)

let result
try {
  result = await body(agent, parallel, pipeline, phase, log, fixture.args)
} catch (error) {
  console.error(`${file} threw: ${error.message}`)
  process.exit(1)
}

console.log(JSON.stringify({ result, agents, phases, logs }))
