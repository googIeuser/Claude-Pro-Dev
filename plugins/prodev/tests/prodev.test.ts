import { test, expect } from 'claude-code/testing';

// Real plugin, real event chain. Only the engine's external work is substituted.
function setup(on, bashResult = { result: { stdout: 'ran', stderr: '', interrupted: false } }, registerCommand = () => ({ value: null })) {
  on('ui.invalidate', () => ({ value: null }));
  on('command.register', registerCommand);
  on('session.usage', () => ({ value: { context: { window: 200000 }, rateLimits: [] } }));
  on('session.start', ($, e) => ({ cwd: e.cwd }));
  on('tool.call', { tool: 'Bash' }, () => bashResult);
  on('tool.call', { tool: 'Read' }, () => ({ result: 'read happened' }));
  on('prompt.context', ($, e) => ({ blocks: e.blocks }));
  on('turn.complete', ($, e) => ({ text: e.answer }));
  on('session.measure', ($, e) => ({ changed: e.changed }));
  on('agent.spawn', () => ({ agentId: 'a1', model: 'sonnet' }));
  on('command.run', () => ({ text: 'unhandled' }));
}
async function start($, on, registerCommand) {
  setup(on, undefined, registerCommand);
  await $.session.start({ cwd: 'C:/repo', interactive: true });
}
function command($, args = '', name = 'prodev') {
  return $.command.run({ command: name, args, origin: { kind: 'composer' }, presentation: { fullscreen: false, columns: 100 } });
}

for (const shell of [
  'git reset --hard HEAD~1', 'git -C repo push origin main --force',
  'git push origin main -f', 'git clean -fd', 'rm -rf ./data',
  'Remove-Item -LiteralPath .\\data -Recurse -Force',
  'rmdir /s /q data', 'psql -c "DROP TABLE users"',
]) {
  test('guard refuses before executing: ' + shell, async ($, on) => {
    setup(on);
    const result = await $.tool.call({ tool: 'Bash', command: shell });
    expect(result.deny).toContain('Pro Dev');
  });
}
test('ordinary shell work is allowed', async ($, on) => {
  setup(on);
  const result = await $.tool.call({ tool: 'Bash', command: 'git status --short' });
  expect(result.result.stdout).toBe('ran');
});
test('secret files are refused before reading; templates are allowed', async ($, on) => {
  setup(on);
  expect((await $.tool.call({ tool: 'Read', file_path: 'C:\\repo\\.env.local' })).deny).toContain('secret');
  expect((await $.tool.call({ tool: 'Read', file_path: 'C:/repo/.env.example' })).result).toBe('read happened');
});
test('secret shell output is redacted before the model sees it', async ($, on) => {
  setup(on, { result: { stdout: 'API_KEY=super-secret-value\nAuthorization: Bearer token123456', stderr: '', interrupted: false }, ref: 51 });
  const result = await $.tool.call({ tool: 'Bash', command: 'echo test' });
  expect(result.result.stdout).not.toContain('super-secret-value');
  expect(result.result.stdout).not.toContain('token123456');
  expect(result.result.stdout).toContain('[REDACTED]');
  expect(result.ref).toBeUndefined();
});
test('filter keeps error evidence, bounds long logs and preserves exit metadata', async ($, on) => {
  const log = Array.from({ length: 5000 }, (_, i) => i === 2499 ? 'ERROR: important middle failure' : 'progress ' + i).join('\n');
  setup(on, { result: { stdout: log, stderr: 'failure detail', interrupted: false, exitCode: 7 }, text: log, ref: 32 });
  const result = await $.tool.call({ tool: 'Bash', command: 'npm test' });
  expect(result.result.stdout).toContain('ERROR: important middle failure');
  expect(result.result.stdout.length).toBeLessThan(13000);
  expect(result.result.stdout).toContain('omitted');
  expect(result.result.exitCode).toBe(7);
  expect(result.result.stderr).toBe('failure detail');
  expect(typeof result.text).toBe('undefined');
});
test('small results keep their engine reference and contents', async ($, on) => {
  setup(on, { result: { stdout: 'ok', stderr: '', interrupted: false }, ref: 8 });
  expect((await $.tool.call({ tool: 'Bash', command: 'npm test' })).ref).toBe(8);
});
test('core is stable and appended once without replacing project context', async ($, on) => {
  setup(on);
  const first = await $.prompt.context({ blocks: [{ name: 'claudeMd', text: 'Project rules' }] });
  const second = await $.prompt.context({ blocks: first.blocks });
  expect(second.blocks.length).toBe(2);
  expect(second.blocks[0].text).toBe('Project rules');
  expect(second.blocks[1].text).toContain('smallest correct change');
  expect(second.blocks[1].text).toBe(first.blocks[1].text);
});
test('queue adds without starting a model turn and removes explicitly', async ($, on) => {
  on('prompt.submit', () => { throw new Error('Queue must not submit automatically'); });
  await start($, on);
  expect((await command($, 'add Investigate failing test', 'prodev-queue')).text).toContain('#1');
  expect((await command($, 'list', 'prodev-queue')).text).toContain('Investigate failing test');
  expect((await command($, 'remove 1', 'prodev-queue')).text).toContain('removed');
  expect((await command($, 'list', 'prodev-queue')).text).toContain('empty');
});
test('queue drafts exactly the original prompt without submitting it', async ($, on) => {
  on('prompt.fill', ($, e) => { expect(e.text).toBe('Inspect the parser'); return { isFilled: true }; });
  on('prompt.submit', () => { throw new Error('Draft must not submit'); });
  await start($, on);
  await command($, 'add Inspect the parser', 'prodev-queue');
  expect((await command($, 'draft 1', 'prodev-queue')).text).toContain('press Enter');
  expect((await command($, 'list', 'prodev-queue')).text).toContain('Inspect the parser');
});
test('missing limit readings are never fabricated as zero', async ($, on) => {
  await start($, on);
  expect((await command($)).text).toContain('5h: unknown');
  expect((await command($)).text).toContain('7d: unknown');
});
test('HUD uses real quota readings, keeping quota separate from context', async ($, on) => {
  await start($, on);
  await $.session.measure({ context: { window: 200000, percent: 40 }, rateLimits: [{ kind: 'five_hour', percentUsed: 23.5 }, { kind: 'seven_day', percentUsed: 61 }], changed: ['context', 'rateLimits'] });
  const status = (await command($)).text;
  expect(status).toContain('5h: 23.5% used');
  expect(status).toContain('7d: 61% used');
  expect(status).toContain('context: 40%');
});
test('cache ratio uses cache reads divided by total observed input', async ($, on) => {
  await start($, on);
  await $.turn.complete({ turnId: 't1', answer: 'done', durationMs: 200, isAborted: false, reason: 'answer', usage: { model: 'sonnet', input_tokens: 100, output_tokens: 20, cache_creation_input_tokens: 100, cache_read_input_tokens: 800 } });
  expect((await command($)).text).toContain('cache: 80%');
});
test('flow observes an agent and completes it without spawning more agents', async ($, on) => {
  await start($, on);
  await $.agent.spawn({ tool_use_id: 'a', prompt: 'read', description: 'Inspect parser', subagentType: 'Explore', isAsync: true });
  expect((await command($, '', 'prodev-flow')).text).toContain('Inspect parser');
  await $.turn.complete({ agentId: 'a1', turnId: 't2', answer: 'done', durationMs: 200, isAborted: false, reason: 'answer' });
  expect((await command($, '', 'prodev-flow')).text).toContain('done');
});
for (const surface of ['terminal', 'desktop'] as const) {
  test('band draws status on ' + surface, async ($, on) => {
    on('ui.render', ($, e) => $.ui.resolve(e).Text({ children: 'other mod' }));
    await start($, on);
    const band = await $.ui.mount({ plugin: 'prodev', surface, component: 'AbovePrompt', props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 120 } });
    expect(await band.find({ type: 'Text', text: /Pro Dev/ })).toBeDefined();
    expect(await band.find({ type: 'Text', text: /other mod/ })).toBeDefined();
    await band.unmount();
  });
}

test('helpers register as immediate commands while Claude is working', async ($, on) => {
  const names = [];
  await start($, on, ($, e) => { expect(e.immediate).toBe(true); names.push(e.name); return { value: null }; });
  expect(names).toContain('prodev-queue');
  expect(names).toContain('prodev-next');
  expect(names.length).toBe(6);
});
test('turn usage is counted only once', async ($, on) => {
  await start($, on);
  const end = { turnId: 'dedup', answer: 'done', durationMs: 100, isAborted: false, reason: 'answer', usage: { model: 'sonnet', input_tokens: 100, output_tokens: 20, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 } };
  await $.turn.complete(end);
  await $.turn.complete(end);
  expect((await command($)).text).toContain('observed input: 100,');
});
test('disabling output filtering still redacts secrets', async ($, on) => {
  const log = 'progress\n'.repeat(2000) + 'PASSWORD=hidden-value';
  setup(on, { result: { stdout: log, stderr: '', interrupted: false } });
  await $.session.start({ cwd: 'C:/repo', interactive: true });
  await command($, 'off', 'prodev-filter');
  const result = await $.tool.call({ tool: 'Bash', command: 'npm test' });
  expect(result.result.stdout.length).toBeGreaterThan(15000);
  expect(result.result.stdout).not.toContain('hidden-value');
  expect(result.result.stdout).not.toContain('omitted');
});
test('disabling heuristic guard preserves downstream permission refusal', async ($, on) => {
  setup(on, { deny: 'permission denied by engine' });
  await $.session.start({ cwd: 'C:/repo', interactive: true });
  await command($, 'off', 'prodev-guard');
  expect((await $.tool.call({ tool: 'Bash', command: 'git reset --hard' })).deny).toBe('permission denied by engine');
});
test('MCP text is bounded while structured and image evidence stays intact', async ($, on) => {
  setup(on);
  on('tool.call', { tool: 'mcp__fixture__logs' }, () => ({ result: { content: [{ type: 'text', text: 'progress\n'.repeat(5000) }, { type: 'image', data: 'ZmFrZQ==', mimeType: 'image/png' }], structuredContent: { count: 5000, result: 'complete' } }, ref: 15 }));
  const result = await $.tool.call({ tool: 'mcp__fixture__logs' });
  expect(result.result.content[0].text.length).toBeLessThan(13000);
  expect(result.result.content[1].data).toBe('ZmFrZQ==');
  expect(result.result.structuredContent).toEqual({ count: 5000, result: 'complete' });
  expect(result.ref).toBeUndefined();
});
test('structured secret string fields are masked without dropping safe fields', async ($, on) => {
  setup(on);
  on('tool.call', { tool: 'mcp__fixture__credentials' }, () => ({ result: { content: [{ type: 'text', text: 'ok' }], structuredContent: { api_key: 'private-api-value', password: 'private-password', authorization: 'Bearer private-bearer', count: 3 } }, ref: 18 }));
  const result = await $.tool.call({ tool: 'mcp__fixture__credentials' });
  expect(result.result.structuredContent.api_key).toBe('[REDACTED]');
  expect(result.result.structuredContent.password).toBe('[REDACTED]');
  expect(result.result.structuredContent.authorization).toBe('[REDACTED]');
  expect(result.result.structuredContent.count).toBe(3);
  expect(result.ref).toBeUndefined();
});
test('failed shell text is bounded without losing the failure flag', async ($, on) => {
  const log = 'ERROR: failed line\n'.repeat(5000);
  setup(on, { isError: true, result: log, text: log, ref: 19 });
  const result = await $.tool.call({ tool: 'Bash', command: 'npm test' });
  expect(result.isError).toBe(true);
  expect(result.result.length).toBeLessThan(13000);
  expect(typeof result.text).toBe('undefined');
});
test('repeat read observation does not suppress genuine reads', async ($, on) => {
  await start($, on);
  await $.tool.call({ tool: 'Read', file_path: 'C:/repo/code.js' });
  expect((await $.tool.call({ tool: 'Read', file_path: 'C:/repo/code.js' })).result).toBe('read happened');
  expect((await command($)).text).toContain('repeat reads: 1');
  await $.tool.call({ tool: 'Bash', command: 'git status' });
  await $.tool.call({ tool: 'Read', file_path: 'C:/repo/code.js' });
  expect((await command($)).text).toContain('repeat reads: 1');
});
test('next steps require no extra model request', async ($, on) => {
  on('model.complete', () => { throw new Error('Must not spend a model request'); });
  await start($, on);
  const result = await command($, '', 'prodev-next');
  expect(result.text).toContain('1.');
  expect(result.text).toContain('2.');
  expect(result.text).toContain('narrow search');
});
