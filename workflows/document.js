export const meta = {
  name: 'sf-document',
  description: 'Spec First: analyze the change, draft minimal docs, then integrate them',
  whenToUse: 'The /sf:document skill calls this. Do not call it directly.',
  phases: [
    { title: 'Analysis', detail: 'artifacts, implementation and existing docs at the same time' },
    { title: 'Drafting', detail: 'technical and user documents at the same time' },
    { title: 'Integration', detail: 'merge the drafts into the existing docs' },
  ],
}

const WEIGHT = 'Match doc weight to change weight. Skip any section that does not apply. ' +
  'No speculative content, no invented terms, no rationale unless the design is surprising.'

const ARTIFACTS = {
  type: 'object',
  required: ['requirements', 'outcomes'],
  properties: {
    requirements: { type: 'array', items: { type: 'string' } },
    outcomes: { type: 'array', items: { type: 'string' } },
  },
}

const IMPLEMENTATION = {
  type: 'object',
  required: ['files', 'interfaces'],
  properties: {
    files: { type: 'array', items: { type: 'string' }, description: 'Main implementation files' },
    interfaces: { type: 'array', items: { type: 'string' }, description: 'Changed public interfaces' },
    notes: { type: 'string', description: 'Naming and organization conventions worth keeping' },
  },
}

const INVENTORY = {
  type: 'object',
  required: ['docs'],
  properties: {
    docs: {
      type: 'array',
      items: {
        type: 'object',
        required: ['path', 'topic'],
        properties: { path: { type: 'string' }, topic: { type: 'string' } },
      },
    },
  },
}

const DRAFT = {
  type: 'object',
  required: ['markdown'],
  properties: {
    markdown: { type: 'string', description: 'The document, or an empty string when none is needed' },
  },
}

const INTEGRATION = {
  type: 'object',
  required: ['changed'],
  properties: {
    changed: { type: 'array', items: { type: 'string' }, description: 'Files written or edited' },
  },
}

// The caller is a model, so args may arrive as a JSON string instead of an object.
const input = typeof args === 'string' ? JSON.parse(args) : (args ?? {})
const specPath = input.specPath
const implementationPath = input.implementationPath

if (!specPath && !implementationPath) {
  return { error: 'sf-document needs specPath or implementationPath in args.' }
}

const sources = [specPath, implementationPath].filter(Boolean).join(' and ')

phase('Analysis')

// Both drafts need all three analyses, so this barrier is the point of the phase.
const [artifacts, implementation, inventory] = await parallel([
  () => agent(
    `Read ${sources}. Extract the requirements and the outcomes they state. Read only what ` +
    `exists. Assume nothing about a missing file. Extract text; do not analyze.`,
    { label: 'artifacts', phase: 'Analysis', schema: ARTIFACTS, effort: 'low' },
  ),
  () => agent(
    `Find the real structure of the change described in ${sources}. Report the main ` +
    `implementation files, the public interfaces that changed, and the naming conventions. ` +
    `Stay technology agnostic.`,
    { label: 'implementation', phase: 'Analysis', schema: IMPLEMENTATION, effort: 'low' },
  ),
  () => agent(
    `Inventory the existing documentation. Glob \`*.md\` in the project root and \`docs/**/*.md\`, ` +
    `at most 3 levels deep. For each file, read the first 20 lines only and report its path and ` +
    `primary topic. Never read a whole file.`,
    { label: 'inventory', phase: 'Analysis', schema: INVENTORY, effort: 'low' },
  ),
])

if (!artifacts || !implementation || !inventory) {
  return { error: 'Analysis incomplete. Rerun /sf:document.' }
}

const context = `Requirements: ${artifacts.requirements.join('; ')}\n` +
  `Outcomes: ${artifacts.outcomes.join('; ')}\n` +
  `Files: ${implementation.files.join('; ')}\n` +
  `Changed interfaces: ${implementation.interfaces.join('; ')}\n` +
  `Existing docs: ${inventory.docs.map((d) => `${d.path} | ${d.topic}`).join('\n')}`

phase('Drafting')

const [technical, user] = await parallel([
  () => agent(
    `Draft the developer documentation for this change.\n\n${context}\n\n${WEIGHT}\n` +
    `Include an overview only for a new feature or an architectural change. Include an API ` +
    `reference only for a changed public interface. Include setup only when a prerequisite ` +
    `changed. Where an existing doc already covers the topic, write the update for that doc. ` +
    `Return an empty string when the change needs no developer documentation.`,
    { label: 'technical-docs', phase: 'Drafting', schema: DRAFT },
  ),
  () => agent(
    `Draft the user documentation for this change.\n\n${context}\n\n${WEIGHT}\n` +
    `Document only what the user must do differently. Skip anything automatic or invisible. ` +
    `No glossary, no version sections, no internals. Troubleshooting only for a problem users ` +
    `have hit. Return an empty string when the change needs no user documentation.`,
    { label: 'user-docs', phase: 'Drafting', schema: DRAFT },
  ),
])

if (!technical || !user) {
  return { error: 'Drafting incomplete. Rerun /sf:document.' }
}

// Gate: a draft with a placeholder marker is not finished work. A marker shape, not a bare
// word - "placeholder" in a props table is prose, and a code span quotes a marker.
const MARKER = /(TODO|TBD)\s*:|[[<](TODO|TBD|PLACEHOLDER|INSERT)/i
const marked = [['technical', technical], ['user', user]]
  .filter(([, draft]) => MARKER.test(draft.markdown.replace(/`[^`]*`/g, '')))
  .map(([name]) => name)

if (marked.length > 0) {
  return { error: `Draft contains a placeholder marker: ${marked.join(', ')}. Nothing integrated.` }
}

if (!technical.markdown.trim() && !user.markdown.trim()) {
  return { changed: [], note: 'The change needs no documentation.' }
}

phase('Integration')

const integration = await agent(
  `Integrate these drafts into the existing documentation.\n\n` +
  `Existing docs:\n${inventory.docs.map((d) => `${d.path} | ${d.topic}`).join('\n')}\n\n` +
  `Developer draft:\n${technical.markdown}\n\nUser draft:\n${user.markdown}\n\n` +
  `Edit the existing file whose topic matches. Write a new file only when none fits. Cut ` +
  `duplicate content: where both drafts cover one topic, keep the better version. Add no ` +
  `metadata headers and no cross-reference links. Report every file you changed.`,
  { label: 'integrate-docs', phase: 'Integration', schema: INTEGRATION },
)

return { changed: integration ? integration.changed : [] }
