// Optional maintainer benchmark (Node 24 tested); never run by the plugin.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';

const repo = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, '..'));
const policyPath = path.join(repo, 'plugins/prodev/hooks/policy.js');
const registerPath = path.join(repo, 'plugins/prodev/hooks/register.js');
const { filterResult, CORE_RULES } = await import(pathToFileURL(policyPath));
const { register } = await import(pathToFileURL(registerPath));
// Capture the actual skill transform; external host work is not benchmarked.
const handlers = new Map();
register((event, ...args) => { handlers.set(event, args.at(-1)); return { catch() {} }; });
const skill = fs.readFileSync(path.join(repo, 'plugins/prodev/skills/advisor/SKILL.md'), 'utf8').replace(/^---[\s\S]*?---\r?\n/, '').replace('$ARGUMENTS', 'Fix the signed integer parser and run its checks.');
const prompt = await handlers.get('skill.prompt')({}, { skill: 'prodev:advisor' }, async () => ({ text: skill }));
const mcpInput = { content: Array.from({ length: 20 }, (_, i) => ({ type: 'text', text: (`block ${i}: ` + 'x'.repeat(90) + '\n').repeat(30) })) };
mcpInput.content[19].text = 'ERROR: late parser failure\n    at parse (parser.js:91)\n' + mcpInput.content[19].text;
const shellInput = { stdout: ('progress ' + 'x'.repeat(90) + '\n').repeat(100), stderr: ('detail ' + 'y'.repeat(90) + '\n').repeat(100) + 'ERROR: stderr failure\n    at parse (parser.js:91)', exitCode: 7 };
const mcp = filterResult('mcp__fixture__logs', mcpInput);
const shell = filterResult('Bash', shellInput);
const hash = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const summary = {
  pluginVersion: JSON.parse(fs.readFileSync(path.join(repo, 'plugins/prodev/.claude-plugin/plugin.json'), 'utf8')).version,
  unit: 'JavaScript string characters; not model tokens or subscription allowance',
  policySha256: hash(policyPath), registerSha256: hash(registerPath),
  coreCharacters: CORE_RULES.length,
  advisorSkillCharacters: skill.length,
  injectedChoiceCharacters: prompt.text.length - skill.length,
  corePlusAdvisorPromptCharacters: CORE_RULES.length + prompt.text.length,
  mcpText: { input: mcpInput.content.reduce((n,b)=>n+b.text.length,0), output: mcp.content.reduce((n,b)=>n+b.text.length,0), lateFailureRetained: mcp.content.some(b=>b.text.includes('ERROR: late parser failure') && b.text.includes('parser.js:91')) },
  shellText: { input: shellInput.stdout.length + shellInput.stderr.length, output: shell.stdout.length + shell.stderr.length, failureRetained: shell.stderr.includes('ERROR: stderr failure') && shell.stderr.includes('parser.js:91'), exitCode: shell.exitCode }
};
const json = JSON.stringify(summary, null, 2) + '\n';
if (process.argv[3]) fs.writeFileSync(path.resolve(process.argv[3]), json);
process.stdout.write(json);
