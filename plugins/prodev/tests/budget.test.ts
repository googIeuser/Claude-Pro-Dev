import { test, expect } from 'claude-code/testing';

// The external tool is controlled; the plugin's native result transformation is real.
function engine(on, result) {
  on('ui.invalidate', () => ({ value: null }));
  on('command.run', () => ({ text: 'unhandled' }));
  on('tool.call', () => result);
}
const filter = ($, args) => $.command.run({ command: 'prodev-filter', args, origin: { kind: 'composer' }, presentation: { fullscreen: false, columns: 100 } });

test('MCP text shares one budget across blocks and retains a late failure', async ($, on) => {
  const content = Array.from({ length: 20 }, (_, i) => ({ type: 'text', text: ('progress ' + 'x'.repeat(90) + '\n').repeat(30), annotation: i }));
  content[19].text = 'ERROR: late parser failure\n    at parse (parser.js:91)\n' + content[19].text;
  const image = { type: 'image', data: 'ZmFrZQ==', mimeType: 'image/png' };
  const original = { content: [...content, image], structuredContent: { total: 20 }, isError: true };
  engine(on, { result: original, ref: 99 });
  const r = await $.tool.call({ tool: 'mcp__fixture__logs' });
  const text = r.result.content.filter(b => b.type === 'text').map(b => b.text).join('');
  expect(text.length).toBeLessThan(12001);
  expect(text).toContain('ERROR: late parser failure');
  expect(text).toContain('parser.js:91');
  expect(text).toContain('omitted');
  expect(r.result.content[19].annotation).toBe(19);
  expect(r.result.content[20]).toEqual(image);
  expect(r.result.structuredContent).toEqual({ total: 20 });
  expect(r.result.isError).toBe(true);
  expect(original.content[0].text.length).toBe(3000);
  expect(r.ref).toBeUndefined();
});

test('stdout and stderr share the budget without losing stderr failure evidence or exit status', async ($, on) => {
  const stdout = ('progress ' + 'x'.repeat(90) + '\n').repeat(100);
  const stderr = ('detail ' + 'y'.repeat(90) + '\n').repeat(100) + 'ERROR: stderr failure\n    at parse (parser.js:91)';
  engine(on, { result: { stdout, stderr, exitCode: 7, interrupted: false }, ref: 98 });
  const r = await $.tool.call({ tool: 'Bash', command: 'npm test' });
  expect(r.result.stdout.length + r.result.stderr.length).toBeLessThan(12001);
  expect(r.result.stderr).toContain('ERROR: stderr failure');
  expect(r.result.stderr).toContain('parser.js:91');
  expect(r.result.exitCode).toBe(7);
  expect((await $.command.run({ command: 'prodev-checks', args: '', origin: { kind: 'composer' }, presentation: { fullscreen: false, columns: 100 } })).text).toContain('FAIL');
  expect(r.ref).toBeUndefined();
});

test('many omitted text blocks cannot multiply omission notices beyond the shared budget', async ($, on) => {
  const content = Array.from({ length: 500 }, () => ({ type: 'text', text: 'noise '.repeat(100) }));
  engine(on, { result: { content } });
  const r = await $.tool.call({ tool: 'mcp__fixture__logs' });
  expect(r.result.content.map(b => b.text).join('').length).toBeLessThan(12001);
  expect(r.result.content.length).toBe(500);
});

test('small multi-block MCP results keep content and engine reference', async ($, on) => {
  const result = { content: [{ type: 'text', text: 'one' }, { type: 'text', text: 'two' }], structuredContent: { ok: true } };
  engine(on, { result, ref: 97 });
  const r = await $.tool.call({ tool: 'mcp__fixture__logs' });
  expect(r.result).toEqual(result);
  expect(r.ref).toBe(97);
});

test('filter off preserves full multi-block output while redacting secrets', async ($, on) => {
  engine(on, { result: { content: Array.from({ length: 20 }, () => ({ type: 'text', text: 'noise '.repeat(500) + 'PASSWORD=synthetic-private-value' })) } });
  await filter($, 'off');
  const r = await $.tool.call({ tool: 'mcp__fixture__logs' });
  const text = r.result.content.map(b => b.text).join('');
  expect(text.length).toBeGreaterThan(60000);
  expect(text).not.toContain('synthetic-private-value');
  expect(text).toContain('[REDACTED]');
  expect(text).not.toContain('omitted');
});
