import { CORE_RULES, redact, redactValue, filterResult, filterText, isShell, checkKind, checkStatus, parseProfile } from './policy.js';

const refresh = $ => $.ui.invalidate('ui.render');
async function loadProfile($) {
  const info = await $.fs.stat('.prodev.json');
  if (info.kind !== 'file' || info.size > 16384 || info.isLink) throw new Error('Profile must be a regular file of at most 16 KiB.');
  return parseProfile(await $.fs.read('.prodev.json'));
}

export function register(on) {
  // Session-only state; queue prompts and tool output are never saved to disk.
  let usage = { context: {}, rateLimits: [] };
  let tokens = { input: 0, output: 0, read: 0, write: 0 };
  let observedUsage = false;
  let filtering = true;
  let calls = 0, repeated = 0, shortened = 0, edits = 0;
  let lastFailed = false;
  let nextId = 1;
  let queue = [];
  const agents = new Map();
  const defaultChoices = () => ({ executor: { model: 'claude-sonnet-5-5', effort: 'medium' }, advisor: { model: 'claude-opus-5-5', effort: 'medium' } });
  let modelChoices = defaultChoices();
  const explicitModels = new Set();
  const agentRole = type => type === 'prodev:executor' ? 'executor' : type === 'prodev:advisor' ? 'advisor' : null;
  const choicesText = () => Object.entries(modelChoices).map(([role, c]) => `${role} model: ${c.model}; effort: ${c.effort}`).join('\n');
  const reads = new Set();
  const finishedTurns = new Set();
  let revision = 0, receiptId = 0, completed = 0, durationMs = 0;
  const receipts = [];
  const busyChecks = new Set();
  const observed = { 'session.start': 0, 'prompt.context': 0, 'session.measure': 0, 'tool.call': 0, 'turn.complete': 0 };
  const registered = new Set(), collisions = new Set();
  const receipt = (name, source, result, atRevision, elapsed = null) => {
    const item = { id: ++receiptId, name, source, ...checkStatus(result), revision: atRevision, durationMs: elapsed };
    receipts.push(item); if (receipts.length > 50) receipts.shift();
    lastFailed = item.status === 'fail';
    return item;
  };
  const receiptText = item => `${item.name}: ${item.status.toUpperCase()} | exit ${item.exitCode ?? 'unknown'} | ${item.revision === revision ? 'current observed revision' : 'stale after observed activity'}`;
  const checksText = () => receipts.length ? receipts.map(receiptText).join('\n') : 'No checks observed. /prodev-checks profile lists configured checks; /prodev-checks run <name> explicitly runs one.';

  const cache = () => {
    const total = tokens.input + tokens.read + tokens.write;
    return !observedUsage || total === 0 ? 'unknown' : Math.round(tokens.read / total * 100) + '%';
  };
  const windowText = kind => {
    const item = usage.rateLimits.find(r => r.kind === kind && Number.isFinite(r.percentUsed));
    return item ? item.percentUsed + '% used' : 'unknown';
  };
  const headline = () => `Pro Dev | 5h: ${windowText('five_hour')} | 7d: ${windowText('seven_day')} | cache: ${cache()} | context: ${usage.context.percent ?? 'unknown'}${usage.context.percent === undefined ? '' : '%'}`;
  const counters = () => `tools: ${calls} | repeat reads: ${repeated} | agents: ${[...agents.values()].filter(a => a.state === 'running').length} | queue: ${queue.length} | filtered: ${shortened} | checks: ${receipts.filter(r => r.status === 'pass' && r.revision === revision).length} current pass`;
  const suggestions = () => [
    ...(lastFailed ? ['Investigate the last failed check using a targeted error log.'] : []),
    ...(edits ? ['Review the diff and run the smallest relevant verification.'] : ['Identify the relevant files with one narrow search.']),
    ...(queue.length ? ['Review the pending Pro Dev queue; draft only the intended item.'] : ['Summarize the result and remaining limitations briefly.']),
  ].slice(0, 3);
  const flow = (mermaid = false) => {
    const rows = [...agents.entries()];
    if (!mermaid) return ['main', ...rows.map(([id, a]) => `  ${a.parent ?? 'main'} -> ${id}: ${redact(a.label)} [${a.state}]`)].join('\n');
    const ids = new Map(rows.map(([id], i) => [id, 'a' + i]));
    const safe = text => redact(text).replace(/["\r\n<>\[\]`]/g, ' ').slice(0, 100);
    return ['```mermaid', 'flowchart TD', '  main["Main"]', ...rows.map(([id, a]) => `  ${ids.get(a.parent) ?? 'main'} --> ${ids.get(id)}["${safe(a.label)}: ${a.state}"]`), '```'].join('\n');
  };

  on('session.start', async ($, e, next) => {
    observed['session.start']++;
    // No token-count API, HTTP, timers or background agents.
    try { usage = await $.session.usage(); } catch { /* No reading yet. */ }
    for (const [name, description, argumentHint] of [
      ['prodev', 'Show usage, counters and helper commands', ''],
      ['prodev-queue', 'Manage a session queue without automatic execution', 'add <text> | list | remove <id> | draft <id> | clear'],
      ['prodev-flow', 'Show observed agent activity', '[mermaid]'],
      ['prodev-next', 'Show local next-step suggestions without a model call', ''],
      ['prodev-filter', 'Enable or disable long-output filtering', 'on | off'],
      ['prodev-doctor', 'Diagnose loaded hooks, command conflicts and missing readings', ''],
      ['prodev-checks', 'Verification receipts; explicitly run a trusted project check', 'profile | run <name>'],
      ['prodev-report', 'Print session metrics JSON without prompts or tool bodies', ''],
      ['prodev-model', 'Choose model and effort for new Pro Dev agents in this session', '[executor|advisor <model> [effort] | reset]'],
    ]) {
      try { await $.command.register({ name, description, argumentHint, immediate: true }); registered.add(name); }
      catch { collisions.add(name); }
    }
    return next(e);
  });

  on('prompt.context', ($, e, next) => {
    observed['prompt.context']++;
    return next({ ...e, blocks: e.blocks.some(b => b.name === 'prodevCore') ? e.blocks : [...e.blocks, { name: 'prodevCore', text: CORE_RULES }] });
  });

  on('skill.prompt', { skill: ['prodev:advisor', 'prodev:team'] }, async ($, e, next) => {
    const result = await next(e);
    // Stable delegation rules live in each skill. Append only session choices,
    // avoiding a second copy of alias, auto, inheritance, and permission rules.
    return { ...result, text: result.text + '\n\nPro Dev session choices (requested; subject to host availability):\n' + choicesText() };
  });

  on('session.measure', ($, e, next) => {
    observed['session.measure']++;
    usage = { context: e.context, rateLimits: e.rateLimits };
    refresh($);
    return next(e);
  });

  on('tool.call', async ($, e, next) => {
    calls++;
    observed['tool.call']++;
    const readKey = ['Read', 'Grep', 'Glob'].includes(e.tool)
      ? JSON.stringify([e.tool, e.agentId ?? 'main', e.file_path, e.path, e.pattern, e.glob, e.offset, e.limit, e.output_mode, e.head_limit, e.type, e['-A'], e['-B'], e['-C'], e['-i'], e['-n'], e.multiline]) : null;
    if (readKey && reads.has(readKey)) repeated++;
    if (['Write', 'Edit', 'MultiEdit', 'NotebookEdit'].includes(e.tool) || isShell(e.tool) || e.tool.startsWith('mcp__')) { reads.clear(); revision++; }
    const atRevision = revision;
    refresh($);
    const role = e.tool === 'Agent' ? agentRole(e.subagent_type) : null;
    const effort = role ? modelChoices[role].effort : 'inherit';
    const result = await next(effort === 'inherit' ? e : { ...e, effort }); // Keeps Claude Code's permission checks.
    if (result.deny !== undefined) return result;
    if (readKey && !result.isError) { reads.add(readKey); if (reads.size > 256) reads.delete(reads.values().next().value); }
    if (['Write', 'Edit', 'MultiEdit'].includes(e.tool) && !result.isError) edits++;
    if (isShell(e.tool)) {
      lastFailed = checkStatus(result).status === 'fail';
      const kind = checkKind(e.command);
      if (kind) receipt(kind, e.tool, result, atRevision);
    }
    let clean = redactValue(result.result);
    if (filtering) {
      const bounded = filterResult(e.tool, clean);
      if (bounded !== clean) shortened++;
      clean = bounded;
    }
    const safeText = typeof result.text === 'string' ? redact(result.text) : result.text;
    refresh($);
    if (clean === result.result && safeText === result.text) return result;
    // ref would replay the original unsanitized engine result. Removing it makes
    // the engine validate/remap the sanitized result for the model/transcript.
    const { ref, text, ...rest } = result;
    return { ...rest, result: clean };
  }).catch(($, e, next) => next(e));

  on('agent.spawn', async ($, e, next) => {
    const role = agentRole(e.subagentType);
    // Pin the default family to 5.5, while allowing a caller's different model
    // unless the user explicitly selected an override through /prodev-model.
    const family = role === 'executor' ? 'sonnet' : 'opus';
    const model = role && (explicitModels.has(role) || e.model == null || e.model === family) ? modelChoices[role].model : 'auto';
    const result = await next(model === 'auto' ? e : { ...e, model: model === 'inherit' ? e.parentModel ?? 'inherit' : model });
    if (result.agentId) {
      if (agents.size >= 128) {
        const finished = [...agents].find(([, a]) => a.state !== 'running');
        if (finished) agents.delete(finished[0]);
      }
      if (agents.size < 128) agents.set(result.agentId, { label: String(e.description ?? e.subagentType ?? 'agent').slice(0, 160), parent: e.parentAgentId, state: 'running' });
      refresh($);
    }
    return result;
  });

  on('turn.complete', ($, e, next) => {
    observed['turn.complete']++;
    const turnKey = `${e.agentId ?? 'main'}:${e.turnId}`;
    if (!finishedTurns.has(turnKey)) {
      completed++; durationMs += e.durationMs ?? 0;
      if (e.usage) {
        tokens.input += e.usage.input_tokens ?? 0;
        tokens.output += e.usage.output_tokens ?? 0;
        tokens.read += e.usage.cache_read_input_tokens ?? 0;
        tokens.write += e.usage.cache_creation_input_tokens ?? 0;
        observedUsage = true;
      }
      finishedTurns.add(turnKey);
      if (finishedTurns.size > 512) finishedTurns.delete(finishedTurns.values().next().value);
    }
    if (e.agentId && agents.has(e.agentId)) agents.get(e.agentId).state = e.isAborted ? 'aborted' : e.reason === 'error' ? 'error' : 'done';
    refresh($);
    return next(e);
  });

  on('command.run', { command: 'prodev' }, () => ({ text: [headline(), counters(), `observed input: ${tokens.input}, cache read: ${tokens.read}, cache write: ${tokens.write}, output: ${tokens.output}`, `filter: ${filtering ? 'on' : 'off'} | permissions: Claude Code`, choicesText(), 'Local helpers: /prodev-doctor, /prodev-checks, /prodev-report, /prodev-model, /prodev-queue, /prodev-flow [mermaid], /prodev-next, /prodev-filter on|off', 'Model workflows: /prodev:advisor <task>, /prodev:team <task> (subscription usage applies)'].join('\n') }));
  on('command.run', { command: 'prodev-model' }, ($, e) => {
    const parts = e.args.trim().split(/\s+/);
    if (!e.args.trim()) return { text: choicesText() + '\nSession-only choices for new Pro Dev agents; host/model/plan restrictions still apply. /prodev-model executor auto enables task-based selection.' };
    if (parts.length === 1 && parts[0] === 'reset') {
      modelChoices = defaultChoices();
      explicitModels.clear();
      return { text: 'Model choices reset.\n' + choicesText() };
    }
    const [role, model, effort = 'medium'] = parts;
    const models = ['sonnet', 'haiku', 'opus', 'inherit', 'claude-sonnet-5-5', 'claude-haiku-5-5', 'claude-opus-5-5'];
    if (parts.length < 2 || parts.length > 3 || !['executor', 'advisor'].includes(role) || !(models.includes(model) || role === 'executor' && model === 'auto') || !['inherit', 'low', 'medium', 'high', 'xhigh', 'max'].includes(effort)) {
      return { text: 'Usage: /prodev-model [executor|advisor <sonnet|haiku|opus|inherit|full-5.5-model-id> [inherit|low|medium|high|xhigh|max] | reset]. executor also accepts auto. Thinking off is not an effort level.' };
    }
    modelChoices[role] = { model, effort };
    explicitModels.add(role);
    refresh($);
    return { text: choicesText() + '\nApplied to future Pro Dev agents in this session; running agents keep their settings. Haiku 5.5 requires Claude Code 2.1.293+. Check actual model/effort in /tasks; host limits and environment overrides may take precedence.' };
  });
  on('command.run', { command: 'prodev-doctor' }, () => ({ text: [
    'Pro Dev 0.3.3 doctor (this session; not an installation or security certificate)',
    ...Object.entries(observed).map(([name, n]) => `${name}: ${n ? 'observed (' + n + ')' : 'not observed'}`),
    ...[...collisions].map(name => `${name}: registration failed; inspect other mods with /plugin`),
    `helpers registered: ${registered.size} | quota: ${usage.rateLimits.some(r => Number.isFinite(r.percentUsed)) ? 'host reading available' : 'unknown'}`,
    `permissions: Claude Code | filtering: ${filtering ? 'on' : 'off'} | output redaction: active`,
    'Unknown/stale receipts are not passes. Shell aliases/encoded commands and external edits are not fully observed.',
    'If this command is unavailable, run the installed scripts/doctor.ps1 outside Claude.',
  ].join('\n') }));
  on('command.run', { command: 'prodev-report' }, () => ({ text: JSON.stringify({
    schemaVersion: 2, version: '0.3.3', scope: 'session-only', modelChoices,
    counters: { tools: calls, repeatedReads: repeated, filtered: shortened, edits, queue: queue.length, agents: agents.size },
    turns: { completed, durationMs }, tokens: observedUsage ? tokens : null,
    rateLimits: usage.rateLimits.map(r => ({ kind: r.kind, percentUsed: r.percentUsed ?? null })),
    receipts: receipts.map(r => ({ ...r, stale: r.revision !== revision })),
    limitations: ['Only observed activity; no filesystem content verification', 'Token totals are not subscription quota savings'],
  }, null, 2) }));
  on('command.run', { command: 'prodev-checks' }, async ($, e) => {
    const args = e.args.trim();
    if (!args) return { text: checksText() };
    if (args !== 'profile' && !/^run [a-z][a-z0-9-]{0,31}$/.test(args)) return { text: 'Usage: /prodev-checks [profile | run <name>]' };
    let checks;
    try { checks = await loadProfile($); }
    catch (error) { return { text: 'Project check refused or unavailable. ' + redact(String(error.message)).slice(0, 300) }; }
    if (args === 'profile') return { text: checks.length ? checks.map(c => `${c.name}: ${redact(c.argv.join(' '))} (timeout ${c.timeoutMs}ms)`).join('\n') + '\nReview .prodev.json first. run <name> executes that program as your Windows user, without a shell.' : 'No configured checks.' };
    const check = checks.find(c => c.name === args.slice(4));
    if (!check) return { text: 'Unknown check; use /prodev-checks profile.' };
    if (busyChecks.size) return { text: 'A project check is already running; wait for its receipt.' };
    busyChecks.add(check.name); reads.clear(); revision++;
    const atRevision = revision;
    try {
      const began = await $.clock.now();
      const result = await $.process.run(check.argv, { timeoutMs: check.timeoutMs });
      const item = receipt(check.name, 'profile', result, atRevision, Math.max(0, await $.clock.now() - began));
      refresh($);
      return { text: receiptText(item) + '\n' + filterText(redact((result.stdout ?? '') + '\n' + (result.stderr ?? '')), 6000, 80) };
    } catch {
      const item = receipt(check.name, 'profile', {}, atRevision);
      return { text: receiptText(item) + '\nProcess did not produce an exit code (start failure, refusal or timeout). Inspect the selected program locally.' };
    } finally { busyChecks.delete(check.name); }
  });
  on('command.run', { command: 'prodev-flow' }, ($, e) => ({ text: flow(e.args.trim() === 'mermaid') }));
  on('command.run', { command: 'prodev-next' }, () => ({ text: suggestions().map((s, i) => `${i + 1}. ${s}`).join('\n') }));
  on('command.run', { command: 'prodev-filter' }, ($, e) => {
    const value = e.args.trim();
    if (!['on', 'off'].includes(value)) return { text: `Usage: /${e.command} on|off` };
    filtering = value === 'on';
    refresh($);
    return { text: `${e.command}: ${value} for this session. Output redaction remains active.` };
  });

  on('command.run', { command: 'prodev-queue' }, async ($, e) => {
    const args = e.args.trim();
    const cut = args.indexOf(' ');
    const action = cut < 0 ? args || 'list' : args.slice(0, cut);
    const payload = cut < 0 ? '' : args.slice(cut + 1).trim();
    if (action === 'list') return { text: queue.length ? queue.map(item => `#${item.id} ${redact(item.text)}`).join('\n') : 'Queue empty.' };
    if (action === 'add') {
      if (!payload || payload.length > 4000 || queue.length >= 20) return { text: 'Queue add needs 1-4000 characters; maximum 20 items.' };
      const item = { id: nextId++, text: payload };
      queue.push(item);
      refresh($);
      return { text: `Queued #${item.id}; nothing started.` };
    }
    if (action === 'clear') { queue = []; refresh($); return { text: 'Queue cleared.' }; }
    const id = /^\d+$/.test(payload) ? Number(payload) : NaN;
    const item = queue.find(q => q.id === id);
    if (!item) return { text: 'Usage: /prodev-queue add <text> | list | remove <id> | draft <id> | clear' };
    if (action === 'remove') { queue = queue.filter(q => q.id !== id); refresh($); return { text: `Queue #${id} removed.` }; }
    if (action === 'draft') {
      const result = await $.prompt.fill({ text: item.text });
      return { text: result.isFilled ? `Queue #${id} copied into the prompt; press Enter to send.` : 'No editable prompt here; item retained.' };
    }
    return { text: 'Unknown queue action.' };
  });

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (!['terminal', 'desktop'].includes(e.surface) || e.props.hasSurvey || e.props.maxRows < 1) return next(e);
    const { Box, Text } = $.ui.resolve(e);
    const other = await next(e);
    return Box({ flexDirection: 'column', children: [
      Text({ children: headline(), dimColor: true, wrap: 'truncate' }),
      ...(e.props.maxRows >= 2 ? [Text({ children: counters(), dimColor: true, wrap: 'truncate' })] : []),
      other,
    ] });
  });
}
