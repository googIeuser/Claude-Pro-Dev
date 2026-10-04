import { test, expect } from 'claude-code/testing';

// External work is substituted; policy runs in Claude's native Mods engine.
function engine(on, shell = { result: { stdout: 'ok', stderr: '', interrupted: false } }) {
  on('clock.now', () => ({ value: 100 }));
  on('ui.invalidate', () => ({ value: null }));
  on('command.register', () => ({ value: null }));
  on('session.usage', () => ({ value: { context: { window: 200000 }, rateLimits: [] } }));
  on('session.start', ($, e) => ({ cwd: e.cwd }));
  on('tool.call', () => shell);
  on('command.run', () => ({ text: 'unhandled' }));
  on('prompt.context', ($, e) => ({ blocks: e.blocks }));
  on('turn.complete', ($, e) => ({ text: e.answer }));
}
const cmd = ($, name, args = '') => $.command.run({ command: name, args, origin: { kind: 'composer' }, presentation: { fullscreen: false, columns: 100 } });
const boot = $ => $.session.start({ cwd: 'C:/fixture', interactive: true });
const profile = { version: 1, checks: [{ name: 'unit', argv: ['node', '--test'] }] };
function files(on, text = JSON.stringify(profile)) {
  on('fs.stat', () => ({ value: { kind: 'file', size: text.length, isLink: false } }));
  on('fs.read', () => ({ value: text }));
}

test('PowerShell guard denies recursive deletion before engine execution', async ($, on) => {
  engine(on);
  const r = await $.tool.call({ tool: 'PowerShell', command: 'Remove-Item .\\data -Recurse -Force' });
  expect(r.deny).toContain('recursive deletion');
});

for (const shell of ['Bash', 'PowerShell'] as const) {
  test(shell + ' filtering protects middle stack evidence from huge head/tail lines', async ($, on) => {
    const lines = Array.from({ length: 1000 }, (_, i) => 'noise ' + i + 'x'.repeat(500));
    lines[499] = 'ERROR: parser exploded'; lines[500] = '    at parse (parser.js:91)'; lines[501] = 'Expected 42, received 0';
    engine(on, { result: { stdout: lines.join('\n'), stderr: '', interrupted: false, exitCode: 2 }, ref: 18 });
    const r = await $.tool.call({ tool: shell, command: 'node --test' });
    expect(r.result.stdout).toContain('ERROR: parser exploded');
    expect(r.result.stdout).toContain('parser.js:91');
    expect(r.result.stdout).toContain('Expected 42');
    expect(r.result.stdout.length).toBeLessThan(12001);
    expect(r.result.stdout).toContain('omitted');
    expect(r.result.exitCode).toBe(2);
    expect(r.ref).toBeUndefined();
  });
}

test('doctor distinguishes loaded hooks from events not observed yet', async ($, on) => {
  engine(on); await boot($);
  const first = (await cmd($, 'prodev-doctor')).text;
  expect(first).toContain('session.start: observed');
  expect(first).toContain('prompt.context: not observed');
  expect(first).toContain('quota: unknown');
  await $.prompt.context({ blocks: [] });
  expect((await cmd($, 'prodev-doctor')).text).toContain('prompt.context: observed');
});

test('a command collision is reported while remaining helpers and usage still load', async ($, on) => {
  on('command.register', ($, e) => { if (e.name === 'prodev-queue') throw new Error('Name taken'); return { value: null }; });
  on('ui.invalidate', () => ({ value: null }));
  on('session.usage', () => ({ value: { context: { window: 100000 }, rateLimits: [{ kind: 'five_hour', percentUsed: 17 }] } }));
  on('session.start', ($, e) => ({ cwd: e.cwd }));
  on('command.run', () => ({ text: 'unhandled' }));
  await boot($);
  expect((await cmd($, 'prodev-doctor')).text).toContain('prodev-queue: registration failed');
  expect((await cmd($, 'prodev')).text).toContain('5h: 17% used');
});

test('profile checks run only on explicit command, record exit code, and become stale after edits', async ($, on) => {
  let runs = 0;
  engine(on); files(on);
  on('process.run', ($, e) => { runs++; expect(e.argv.join(' ')).toBe('node --test'); return { value: { exitCode: 0, stdout: 'API_KEY=synthetic-private-value', stderr: '' } }; });
  await boot($);
  await cmd($, 'prodev-checks');
  expect(runs).toBe(0);
  const r = await cmd($, 'prodev-checks', 'run unit');
  expect(r.text).toContain('PASS'); expect(r.text).toContain('exit 0'); expect(r.text).not.toContain('synthetic-private-value');
  await $.tool.call({ tool: 'Edit', file_path: 'C:/fixture/code.js', old_string: 'a', new_string: 'b' });
  expect((await cmd($, 'prodev-checks')).text).toContain('stale');
});

test('absent exit evidence is unknown, never a successful verification receipt', async ($, on) => {
  engine(on); await boot($);
  await $.tool.call({ tool: 'PowerShell', command: 'npm test' });
  const r = (await cmd($, 'prodev-checks')).text;
  expect(r).toContain('UNKNOWN'); expect(r).not.toContain('PASS');
});

test('failure evidence is recorded while harmless stderr cannot turn explicit exit zero into a failure', async ($, on) => {
  let n = 0;
  engine(on); files(on);
  on('process.run', () => ({ value: { exitCode: n++ === 0 ? 3 : 0, stdout: '', stderr: '0 errors; deprecated option warning' } }));
  await boot($);
  expect((await cmd($, 'prodev-checks', 'run unit')).text).toContain('FAIL');
  expect((await cmd($, 'prodev-checks', 'run unit')).text).toContain('PASS');
});

test('invalid, secret-bearing and recognizable destructive profiles never execute', async ($, on) => {
  const bad = { version: 1, checks: [{ name: 'unit', argv: ['git', 'reset', '--hard'] }] };
  engine(on); files(on, JSON.stringify(bad));
  on('process.run', () => { throw new Error('Must not execute'); });
  await boot($);
  expect((await cmd($, 'prodev-checks', 'run unit')).text).toContain('refused');
});

test('oversized profiles are refused before reading the file', async ($, on) => {
  engine(on);
  on('fs.stat', () => ({ value: { kind: 'file', size: 20000, isLink: false } }));
  on('fs.read', () => { throw new Error('Must not read'); });
  await boot($);
  expect((await cmd($, 'prodev-checks', 'run unit')).text).toContain('16 KiB');
});

test('session reports include counters and receipts without prompts, paths or output', async ($, on) => {
  engine(on, { result: { stdout: 'PRIVATE_TOOL_BODY', stderr: '', interrupted: false, exitCode: 0 } });
  await boot($);
  await cmd($, 'prodev-queue', 'add PRIVATE_QUEUE_PROMPT');
  await $.tool.call({ tool: 'PowerShell', command: 'npm test --private-argument', file_path: 'C:/private-project/code.js' });
  await $.turn.complete({ turnId: 'one', answer: 'PRIVATE_ANSWER', durationMs: 99, isAborted: false, reason: 'answer' });
  const r = JSON.parse((await cmd($, 'prodev-report')).text);
  expect(r.counters.tools).toBe(1);
  expect(r.turns.completed).toBe(1);
  expect(r.receipts[0].status).toBe('pass');
  expect(JSON.stringify(r)).not.toContain('PRIVATE');
  expect(JSON.stringify(r)).not.toContain('private-project');
  expect(JSON.stringify(r)).not.toContain('private-argument');
});

test('an edit while a shell check runs makes its receipt stale', async ($, on) => {
  let begin, finish;
  const began = new Promise(resolve => { begin = resolve; });
  const pending = new Promise(resolve => { finish = resolve; });
  on('ui.invalidate', () => ({ value: null }));
  on('command.run', () => ({ text: 'unhandled' }));
  on('tool.call', ($, e) => {
    if (e.tool === 'Bash') { begin(); return pending; }
    return { result: { stdout: 'ok', stderr: '', interrupted: false, exitCode: 0 } };
  });
  const running = $.tool.call({ tool: 'Bash', command: 'npm test' });
  await began;
  await $.tool.call({ tool: 'Edit', file_path: 'C:/fixture/code.js', old_string: 'a', new_string: 'b' });
  finish({ result: { stdout: 'ok', stderr: '', interrupted: false, exitCode: 0 } });
  await running;
  const report = JSON.parse((await cmd($, 'prodev-report')).text);
  expect(report.receipts[0].status).toBe('pass');
  expect(report.receipts[0].stale).toBe(true);
});

for (const value of [
  { version: 2, checks: [] },
  { version: 1, checks: [{ name: 'unit', argv: ['echo', 'API_KEY=synthetic-value'] }] },
  { version: 1, checks: [{ name: 'unit', argv: ['cat', '.env'] }] },
  { version: 1, checks: [{ name: 'unit', argv: ['node', 42] }] },
]) {
  test('invalid profile is refused: ' + JSON.stringify(value), async ($, on) => {
    engine(on); files(on, JSON.stringify(value));
    on('process.run', () => { throw new Error('Must not execute'); });
    await boot($);
    expect((await cmd($, 'prodev-checks', 'run unit')).text).toContain('refused');
  });
}

test('background shell with an apparent exit zero remains unknown', async ($, on) => {
  engine(on, { result: { stdout: 'started', stderr: '', exitCode: 0, backgroundTaskId: 'job' } });
  await boot($);
  await $.tool.call({ tool: 'PowerShell', command: 'npm test', run_in_background: true });
  expect((await cmd($, 'prodev-checks')).text).toContain('UNKNOWN');
});
