import { CORE_RULES, riskyCommand, secretPath, redact, redactValue, filterResult } from './policy.js';

const refresh = $ => $.ui.invalidate('ui.render');

export function register(on) {
  // Session-only state; queue prompts and tool output are never saved to disk.
  let usage = { context: {}, rateLimits: [] };
  let tokens = { input: 0, output: 0, read: 0, write: 0 };
  let observedUsage = false;
  let guard = true;
  let filtering = true;
  let calls = 0, repeated = 0, blocked = 0, shortened = 0, edits = 0;
  let lastFailed = false;
  let nextId = 1;
  let queue = [];
  const agents = new Map();
  const reads = new Set();
  const finishedTurns = new Set();

  const cache = () => {
    const total = tokens.input + tokens.read + tokens.write;
    return !observedUsage || total === 0 ? 'unknown' : Math.round(tokens.read / total * 100) + '%';
  };
  const windowText = kind => {
    const item = usage.rateLimits.find(r => r.kind === kind && Number.isFinite(r.percentUsed));
    return item ? item.percentUsed + '% used' : 'unknown';
  };
  const headline = () => `Pro Dev | 5h: ${windowText('five_hour')} | 7d: ${windowText('seven_day')} | cache: ${cache()} | context: ${usage.context.percent ?? 'unknown'}${usage.context.percent === undefined ? '' : '%'}`;
  const counters = () => `tools: ${calls} | repeat reads: ${repeated} | agents: ${[...agents.values()].filter(a => a.state === 'running').length} | queue: ${queue.length} | filtered: ${shortened} | blocked: ${blocked}`;
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
    for (const [name, description, argumentHint] of [
      ['prodev', 'Show usage, counters and helper commands', ''],
      ['prodev-queue', 'Manage a session queue without automatic execution', 'add <text> | list | remove <id> | draft <id> | clear'],
      ['prodev-flow', 'Show observed agent activity', '[mermaid]'],
      ['prodev-next', 'Show local next-step suggestions without a model call', ''],
      ['prodev-guard', 'Enable or disable the session destructive-command guard', 'on | off'],
      ['prodev-filter', 'Enable or disable long-output filtering', 'on | off'],
    ]) await $.command.register({ name, description, argumentHint, immediate: true });
    // No token-count API, HTTP, timers or background agents.
    try { usage = await $.session.usage(); } catch { /* No reading yet. */ }
    return next(e);
  });

  on('prompt.context', ($, e, next) => next({
    ...e,
    blocks: e.blocks.some(b => b.name === 'prodevCore') ? e.blocks : [...e.blocks, { name: 'prodevCore', text: CORE_RULES }],
  }));

  on('session.measure', ($, e, next) => {
    usage = { context: e.context, rateLimits: e.rateLimits, cost: e.cost };
    refresh($);
    return next(e);
  });

  on('tool.call', async ($, e, next) => {
    calls++;
    const reason = guard && e.tool === 'Bash' ? riskyCommand(e.command) : null;
    const paths = [e.file_path, e.path];
    if (reason || paths.some(p => p && secretPath(p))) {
      blocked++;
      refresh($);
      return { deny: reason ? `Pro Dev guard: ${reason}. Ask the user for authorization; an explicitly chosen /prodev-guard off disables this heuristic for this session.` : 'Pro Dev secret guard: known secret file path. Use a sanitized example or inspect locally.' };
    }
    const readKey = ['Read', 'Grep', 'Glob'].includes(e.tool)
      ? JSON.stringify([e.tool, e.agentId ?? 'main', e.file_path, e.path, e.pattern, e.glob, e.offset, e.limit, e.output_mode, e.head_limit, e.type, e['-A'], e['-B'], e['-C'], e['-i'], e['-n'], e.multiline]) : null;
    if (readKey && reads.has(readKey)) repeated++;
    if (['Write', 'Edit', 'MultiEdit', 'Bash'].includes(e.tool)) reads.clear();
    refresh($);
    const result = await next(e); // Keeps Claude Code's permission checks.
    if (result.deny !== undefined) return result;
    if (readKey && !result.isError) { reads.add(readKey); if (reads.size > 256) reads.delete(reads.values().next().value); }
    if (['Write', 'Edit', 'MultiEdit'].includes(e.tool) && !result.isError) edits++;
    if (e.tool === 'Bash') lastFailed = !!result.isError || Number(result.result?.exitCode ?? 0) !== 0 || /\b(?:error|failed|fatal)\b/i.test(result.result?.stderr ?? '');
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
  }).catch(($, e, next) => next.called ? next(e) : ({ deny: 'Pro Dev guard could not inspect this tool call; retry after checking the plugin.' }));

  on('agent.spawn', async ($, e, next) => {
    const result = await next(e);
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
    const turnKey = `${e.agentId ?? 'main'}:${e.turnId}`;
    if (e.usage && !finishedTurns.has(turnKey)) {
      tokens.input += e.usage.input_tokens ?? 0;
      tokens.output += e.usage.output_tokens ?? 0;
      tokens.read += e.usage.cache_read_input_tokens ?? 0;
      tokens.write += e.usage.cache_creation_input_tokens ?? 0;
      observedUsage = true;
      finishedTurns.add(turnKey);
      if (finishedTurns.size > 512) finishedTurns.delete(finishedTurns.values().next().value);
    }
    if (e.agentId && agents.has(e.agentId)) agents.get(e.agentId).state = e.isAborted ? 'aborted' : e.reason === 'error' ? 'error' : 'done';
    refresh($);
    return next(e);
  });

  on('command.run', { command: 'prodev' }, () => ({ text: [headline(), counters(), `observed input: ${tokens.input}, cache read: ${tokens.read}, cache write: ${tokens.write}, output: ${tokens.output}`, `guard: ${guard ? 'on' : 'off'} | filter: ${filtering ? 'on' : 'off'}`, 'Helpers: /prodev-queue, /prodev-flow [mermaid], /prodev-next, /prodev-guard on|off, /prodev-filter on|off'].join('\n') }));
  on('command.run', { command: 'prodev-flow' }, ($, e) => ({ text: flow(e.args.trim() === 'mermaid') }));
  on('command.run', { command: 'prodev-next' }, () => ({ text: suggestions().map((s, i) => `${i + 1}. ${s}`).join('\n') }));
  on('command.run', { command: ['prodev-guard', 'prodev-filter'] }, ($, e) => {
    const value = e.args.trim();
    if (!['on', 'off'].includes(value)) return { text: `Usage: /${e.command} on|off` };
    if (e.command === 'prodev-guard') guard = value === 'on'; else filtering = value === 'on';
    refresh($);
    return { text: `${e.command}: ${value} for this session. Secret path checks and output redaction remain active.` };
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
