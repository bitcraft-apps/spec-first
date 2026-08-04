export const meta = {
  name: 'sf-spec',
  description: 'Spec First: research scope, criteria and risks in parallel, then write spec.md',
  whenToUse: 'The /sf:spec skill calls this. Do not call it directly.',
  phases: [
    { title: 'Research', detail: 'scope, criteria and risks at the same time' },
    { title: 'Synthesis', detail: 'merge the research into spec.md' },
  ],
}

const RULES = 'Build the smallest thing that works. YAGNI, KISS, SRP. Do not read or write files.'

const SCOPE = {
  type: 'object',
  required: ['include', 'exclude'],
  properties: {
    include: { type: 'array', items: { type: 'string' }, description: 'What to build now' },
    exclude: { type: 'array', items: { type: 'string' }, description: 'What to leave out' },
  },
}

const CRITERIA = {
  type: 'object',
  required: ['criteria'],
  properties: {
    criteria: { type: 'array', items: { type: 'string' }, description: 'Testable pass/fail conditions' },
  },
}

const RISKS = {
  type: 'object',
  required: ['risks'],
  properties: {
    risks: { type: 'array', items: { type: 'string' }, description: 'Blockers, one per item' },
  },
}

// The caller is a model, so args may arrive as a JSON string instead of an object.
const input = typeof args === 'string' ? JSON.parse(args) : (args ?? {})
const requirements = input.requirements
const specPath = input.specPath
const templatePath = input.templatePath

if (!requirements || !specPath || !templatePath) {
  return { error: 'sf-spec needs requirements, specPath and templatePath in args.' }
}

phase('Research')

const [scope, criteria, risks] = await parallel([
  () => agent(
    `Define the narrowest viable scope for these requirements.\n\nRequirements: ${requirements}\n\n` +
    `${RULES}\nExclude everything that is not needed now. Challenge feature creep. If a ` +
    `requirement is unclear, exclude it.`,
    { label: 'scope', phase: 'Research', schema: SCOPE, model: 'haiku', effort: 'low' },
  ),
  () => agent(
    `Write the simplest testable pass/fail conditions for these requirements.\n\n` +
    `Requirements: ${requirements}\n\n${RULES}\nNo enterprise metrics unless the requirements ` +
    `ask for them. "It works" is better than "it is optimal".`,
    { label: 'criteria', phase: 'Research', schema: CRITERIA, model: 'haiku', effort: 'low' },
  ),
  () => agent(
    `Identify the blockers for these requirements.\n\nRequirements: ${requirements}\n\n` +
    `${RULES}\nBlockers only, not every possible risk. Challenge assumptions. Essential edge ` +
    `cases only.`,
    { label: 'risks', phase: 'Research', schema: RISKS, model: 'haiku', effort: 'low' },
  ),
])

if (!scope || !criteria || !risks) {
  return { error: 'Research incomplete. Rerun /sf:spec.' }
}

phase('Synthesis')

await agent(
  `Write a specification to ${specPath}.\n\n` +
  `Read ${templatePath} first and follow its structure.\n\n` +
  `Requirements: ${requirements}\n\n` +
  `Scope — build now: ${scope.include.join('; ')}\n` +
  `Scope — leave out: ${scope.exclude.join('; ')}\n` +
  `Acceptance criteria: ${criteria.criteria.join('; ')}\n` +
  `Blockers: ${risks.risks.join('; ')}\n\n` +
  `Keep the specification under 50 lines. State what to build, not how. Write every ` +
  `acceptance criterion as an unchecked checklist item. Add nothing the inputs do not state.`,
  { label: 'synthesize-spec', phase: 'Synthesis' },
)

return { specPath, criteria: criteria.criteria.length, risks: risks.risks.length }
