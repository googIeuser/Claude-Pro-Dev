import { test, expect } from 'claude-code/testing';

function engine(on) {
  on('ui.invalidate', () => ({ value: null }));
  on('command.register', () => ({ value: null }));
  on('session.usage', () => ({ value: { context: {}, rateLimits: [] } }));
  on('session.start', ($, e) => ({ cwd: e.cwd }));
  on('command.run', () => ({ text: 'unhandled' }));
  on('skill.prompt', ($, e) => ({ text: e.text }));
}
const cmd = ($, args = '') => $.command.run({ command: 'prodev-model', args, origin: { kind: 'composer' }, presentation: { fullscreen: false, columns: 100 } });
const spawn = ($, type, model = undefined) => $.agent.spawn({ tool_use_id: 'fixture', prompt: 'Inspect parser', description: 'Inspect parser', subagentType: type, model, isAsync: true });

test('executor model choice reaches the actual spawn boundary without changing the advisor', async ($, on) => {
  engine(on);
  on('agent.spawn', ($, e) => ({ agentId: e.subagentType, model: e.model ?? 'definition-default' }));
  await cmd($, 'executor haiku low');
  expect((await spawn($, 'prodev:executor', 'sonnet')).model).toBe('haiku');
  expect((await spawn($, 'prodev:advisor', 'opus')).model).toBe('claude-opus-5-5');
});

test('full model ID reaches the spawn boundary and inherited model follows the parent', async ($, on) => {
  engine(on);
  on('agent.spawn', ($, e) => ({ agentId: 'one', model: e.model ?? 'default' }));
  await cmd($, 'advisor claude-sonnet-5-5 high');
  expect((await spawn($, 'prodev:advisor')).model).toBe('claude-sonnet-5-5');
  await cmd($, 'executor inherit');
  const r = await $.agent.spawn({ tool_use_id: 'inherit', prompt: 'read', description: 'read', subagentType: 'prodev:executor', parentModel: 'claude-sonnet-5-5', isAsync: true });
  expect(r.model).toBe('claude-sonnet-5-5');
});

test('chosen effort reaches the Agent tool; unrelated agents keep their own effort', async ($, on) => {
  engine(on);
  on('tool.call', ($, e) => ({ result: { effort: e.effort ?? 'unset', type: e.subagent_type } }));
  await cmd($, 'executor haiku low');
  const input = { tool: 'Agent', prompt: 'read', description: 'read', subagent_type: 'prodev:executor', effort: 'high' };
  expect((await $.tool.call(input)).result.effort).toBe('low');
  expect((await $.tool.call({ ...input, subagent_type: 'Explore' })).result.effort).toBe('high');
});

test('inherit effort preserves the caller setting and invalid choices do not change state', async ($, on) => {
  engine(on);
  on('tool.call', ($, e) => ({ result: { effort: e.effort ?? 'unset' } }));
  await cmd($, 'advisor opus high');
  expect((await cmd($, 'advisor haiku off')).text).toContain('Usage');
  const input = { tool: 'Agent', prompt: 'read', description: 'read', subagent_type: 'prodev:advisor', effort: 'medium' };
  expect((await $.tool.call(input)).result.effort).toBe('high');
  await cmd($, 'advisor opus inherit');
  expect((await $.tool.call(input)).result.effort).toBe('medium');
});

test('auto preserves task choices and reset releases explicit overrides', async ($, on) => {
  engine(on);
  on('agent.spawn', ($, e) => ({ agentId: 'one', model: e.model ?? 'default' }));
  await cmd($, 'executor auto medium');
  expect((await spawn($, 'prodev:executor', 'haiku')).model).toBe('haiku');
  expect((await spawn($, 'prodev:executor', 'sonnet')).model).toBe('sonnet');
  await cmd($, 'reset');
  expect((await spawn($, 'prodev:executor', 'haiku')).model).toBe('haiku');
});

test('only Pro Dev workflow prompts receive the current session choices', async ($, on) => {
  engine(on);
  await cmd($, 'executor haiku low');
  await cmd($, 'advisor sonnet high');
  const r = await $.skill.prompt({ skill: 'prodev:advisor', text: 'TASK_BODY', args: 'fix' });
  expect(r.text).toContain('TASK_BODY');
  expect(r.text).toContain('executor model: haiku; effort: low');
  expect(r.text).toContain('advisor model: sonnet; effort: high');
  expect((await $.skill.prompt({ skill: 'other:skill', text: 'UNCHANGED', args: '' })).text).toBe('UNCHANGED');
});

test('model helper does not submit prompts or make model requests', async ($, on) => {
  engine(on);
  on('model.complete', () => { throw new Error('Must not request a model'); });
  on('prompt.submit', () => { throw new Error('Must not submit'); });
  expect((await cmd($, 'executor auto')).text).toContain('auto');
  expect((await cmd($)).text).toContain('advisor');
});

test('unrelated agent spawns are not routed by Pro Dev settings', async ($, on) => {
  engine(on);
  on('agent.spawn', ($, e) => ({ agentId: 'one', model: e.model ?? 'default' }));
  await cmd($, 'executor haiku low');
  expect((await spawn($, 'Explore', 'opus')).model).toBe('opus');
});

for (const [role, family, expectedModel] of [
  ['executor', 'sonnet', 'claude-sonnet-5-5'],
  ['advisor', 'opus', 'claude-opus-5-5'],
]) {
  test(role + ' starts on its pinned 5.5 model with medium effort', async ($, on) => {
    engine(on);
    on('agent.spawn', ($, e) => ({ agentId: 'default', model: e.model ?? 'unset' }));
    on('tool.call', ($, e) => ({ result: { effort: e.effort ?? 'unset' } }));
    expect((await spawn($, 'prodev:' + role, family)).model).toBe(expectedModel);
    expect((await $.tool.call({ tool: 'Agent', subagent_type: 'prodev:' + role, prompt: 'Inspect', description: 'Inspect', effort: 'high' })).result.effort).toBe('medium');
  });
}

test('reset restores pinned role models and medium effort after user overrides', async ($, on) => {
  engine(on);
  on('agent.spawn', ($, e) => ({ agentId: 'reset', model: e.model ?? 'unset' }));
  on('tool.call', ($, e) => ({ result: { effort: e.effort ?? 'unset' } }));
  await cmd($, 'executor haiku low');
  await cmd($, 'advisor sonnet high');
  await cmd($, 'reset');
  expect((await spawn($, 'prodev:executor')).model).toBe('claude-sonnet-5-5');
  expect((await spawn($, 'prodev:advisor')).model).toBe('claude-opus-5-5');
  expect((await $.tool.call({ tool: 'Agent', subagent_type: 'prodev:executor', prompt: 'Inspect', description: 'Inspect', effort: 'low' })).result.effort).toBe('medium');
});

test('a model choice without effort uses medium while explicit inherit preserves caller effort', async ($, on) => {
  engine(on);
  on('tool.call', ($, e) => ({ result: { effort: e.effort ?? 'unset' } }));
  const input = { tool: 'Agent', subagent_type: 'prodev:executor', prompt: 'Inspect', description: 'Inspect', effort: 'high' };
  await cmd($, 'executor haiku');
  expect((await $.tool.call(input)).result.effort).toBe('medium');
  await cmd($, 'executor haiku inherit');
  expect((await $.tool.call(input)).result.effort).toBe('high');
});
