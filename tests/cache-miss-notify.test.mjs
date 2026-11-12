import { test } from 'node:test';
import assert from 'node:assert/strict';
import extension from '../pi-extensions/cache-miss-notify/index.ts';
import { previousRequest, scanPrevious, detectMiss, formatMiss } from '../pi-extensions/cache-miss-notify/detection.ts';

const request = (input = 1000, cacheRead = 9000, cacheWrite = 0, extra = {}) => ({
  role: 'assistant', provider: 'test', model: 'model', api: 'openai-completions',
  timestamp: 100000, stopReason: 'stop',
  usage: { input, cacheRead, cacheWrite, cost: { input: input * 3e-6, cacheRead: cacheRead * .3e-6, cacheWrite: cacheWrite * 3.75e-6 } },
  ...extra,
});
const entry = message => ({ type: 'message', message });
const prev = previousRequest(request());

test('Pi min(previous prompt, current prompt) minus cacheRead, not zero-cache warning', () => {
  const m = request(6000, 4000);
  const miss = detectMiss(prev, m, .3);
  assert.equal(miss.missedTokens, 6000);
  assert.ok(Math.abs(miss.extraCost - .0162) < 1e-10);
  assert.equal(formatMiss(miss), 'Cache miss: 6.0k tokens re-billed (~$0.02)');
  assert.equal(detectMiss(prev, request(1024, 8976)), undefined);
  assert.equal(detectMiss(prev, request(1025, 8975)).missedTokens, 1025);
  assert.equal(detectMiss(prev, request(0, 12000)), undefined);
  assert.equal(detectMiss(prev, request(2000, 3000)).missedTokens, 2000);
});
test('notification matches Pi TUI compact token and cost formatting', () => {
  const base = detectMiss(prev, request(6000,4000));
  for (const [missedTokens, label] of [[999,'999'],[1025,'1.0k'],[9999,'10.0k'],[10000,'10k'],[114956,'115k'],[1000000,'1.0M'],[10000000,'10M']])
    assert.equal(formatMiss({...base, missedTokens, extraCost:.2184}), `Cache miss: ${label} tokens re-billed (~$0.22)`);
  for (const extraCost of [undefined, 0, .009])
    assert.equal(formatMiss({...base, extraCost}), 'Cache miss: 6.0k tokens re-billed');
  assert.equal(formatMiss({...base, idleMs:300000}), 'Cache miss after 5m idle: 6.0k tokens re-billed (~$0.02)');
});
test('Anthropic cache writes count in prompt and paid tokens, output is irrelevant', () => {
  const m = request(100, 2000, 7900);
  m.usage.output = 100000;
  assert.equal(detectMiss(prev, m).missedTokens, 8000);
  assert.ok(detectMiss(prev, m).extraCost > .02);
});
test('expected cold starts, unsupported caching, errors and malformed usage are quiet', () => {
  assert.equal(detectMiss(undefined, request(10000, 0, 0)), undefined);
  assert.equal(detectMiss(previousRequest(request(10000, 0)), request(10000, 0)), undefined);
  for (const extra of [{model:'other'}, {provider:'other'}, {timestamp:99999}, {stopReason:'error'}, {stopReason:'aborted'}])
    assert.equal(detectMiss(prev, request(10000, 0, 0, extra)), undefined);
  assert.equal(detectMiss(prev, request(NaN, 0)), undefined);
  assert.equal(detectMiss(prev, request(-1, 0)), undefined);
});
test('long-idle misses are detected and use Pi elapsed-minute wording', () => {
  for (const [idleMs, label] of [[299999,'Cache miss'],[300000,'Cache miss after 5m idle'],[300001,'Cache miss after 5m idle'],[750000,'Cache miss after 13m idle'],[86400000,'Cache miss after 1440m idle']]) {
    const miss = detectMiss(prev, request(10000,0,0,{timestamp:100000+idleMs}), .3);
    assert.ok(miss);
    assert.equal(miss.idleMs,idleMs);
    assert.equal(formatMiss(miss), `${label}: 10k tokens re-billed (~$0.03)`);
  }
});
test('zero cached tokens needs known read pricing to estimate cost; zero pricing omitted', () => {
  assert.equal(detectMiss(prev, request(10000, 0)).extraCost, undefined);
  assert.ok(detectMiss(prev, request(10000, 0), .3).extraCost > 0);
  const m = request(10000, 0); m.usage.cost.input = 0;
  assert.equal(detectMiss(prev, m, 0).extraCost, undefined);
});
test('branch scan resets compaction/summary and model evidence; handles warming', () => {
  for (const type of ['compaction','branch_summary','model_change'])
    assert.equal(scanPrevious([entry(request()), {type}]), undefined);
  const warm = {type:'usage', kind:'cache_warm', provider:'test', model:'model', api:'openai-completions', timestamp:new Date(200000).toISOString(), usage:request().usage};
  assert.equal(scanPrevious([warm]).timestamp, 200000);
  assert.equal(scanPrevious([entry(request()), entry(request(10000,0,0,{model:'other'}))]).reportedCache, false);
  assert.equal(scanPrevious([entry(request()),entry(request(0,0,0,{stopReason:'error'}))]).promptTokens,10000);
});
function harness(hasUI = true, mode = 'rpc') {
  const handlers = {}, notices = [], commands = {}, audit = [];
  extension({on:(name,fn)=>handlers[name]=fn,registerCommand:(name,c)=>commands[name]=c,
    appendEntry:(customType,data)=>audit.push({customType,data})});
  let branch = [entry(request())];
  const ctx = { hasUI, mode, ui:{notify:(...args)=>notices.push(args)}, sessionManager:{getBranch:()=>branch}, modelRegistry:{find:()=>({cost:{cacheRead:.3}})}};
  return {handlers,notices,commands,audit,ctx, setBranch:b=>branch=b,
    response(m) { handlers.turn_start({},ctx); handlers.message_end({message:m},ctx); } };
}
test('notifies on finalized response while active, not agent_end; dedupes episodes and ignores other roles', () => {
  const h = harness();
  h.handlers.turn_start({}, h.ctx);
  h.handlers.message_end({message:{role:'toolResult'}},h.ctx);
  h.handlers.message_end({message:request(10000,0)},h.ctx);
  assert.equal(h.notices.length,1);
  assert.equal(h.notices[0][1],'warning');
  h.response(request(10000,0));
  assert.equal(h.notices.length,1);
  assert.equal(h.audit[1].data.suppressed,'episode');
  assert.equal(h.audit[1].data.notified,false);
  h.handlers.session_compact(); h.setBranch([]); h.response(request(10000,0));
  assert.equal(h.notices.length,1);
});
test('same-model reselection after resume preserves the overnight baseline', () => {
  const h = harness();
  h.setBranch([entry(request()), {type:'model_change', provider:'test', modelId:'model'}]);
  h.handlers.model_select?.({model:{provider:'test',id:'model'}, previousModel:{provider:'test',id:'model'}}, h.ctx);
  h.response(request(10000,0,0,{timestamp:100000+2*86400000}));
  assert.deepEqual(h.notices, [['Cache miss after 2880m idle: 10k tokens re-billed (~$0.03)', 'warning']]);
});
test('genuine model changes, including switching away and back without requests, remain cold starts', () => {
  for (const changes of [
    [{type:'model_change',provider:'test',modelId:'other'}],
    [{type:'model_change',provider:'test',modelId:'other'}, {type:'model_change',provider:'test',modelId:'model'}],
  ]) {
    assert.equal(scanPrevious([entry(request()), ...changes]), undefined);
  }
});
test('separate overnight miss is not suppressed by the previous miss episode', () => {
  const h = harness();
  h.response(request(10000,0));
  h.handlers.agent_settled();
  const original = Date.now;
  Date.now = () => original()+2*86400000;
  try {
    h.setBranch([entry(request()),entry(request(10000,0))]);
    h.response(request(10000,0,0,{timestamp:100000+2*86400000}));
    assert.equal(h.notices.length,2);
    assert.match(h.notices[1][0],/^Cache miss after 2880m idle:/);
  } finally { Date.now = original; }
});
test('recorded overnight miss reproduces correct warning across redundant model_change', () => {
  const h = harness();
  const before = request(57,143488,0,{provider:'openai',model:'gpt-6.1-sol',timestamp:1794160385714});
  const after = request(146276,0,0,{provider:'openai',model:'gpt-6.1-sol',timestamp:1794332733716});
  after.usage.cost.input = after.usage.input*2e-6;
  h.ctx.modelRegistry.find = () => ({cost:{cacheRead:.1}});
  h.setBranch([entry(before),{type:'model_change',provider:'openai',modelId:'gpt-6.1-sol'}]);
  h.handlers.session_start({reason:'resume'}, h.ctx);
  h.response(after);
  assert.deepEqual(h.notices,[['Cache miss after 2872m idle: 144k tokens re-billed (~$0.27)','warning']]);
  assert.equal(h.audit[0].data.kind,'loaded');
  assert.equal(h.audit[1].data.notified,true);
  assert.equal(h.audit[1].data.previousTimestamp,before.timestamp);
});
test('invalid warming entry cannot establish cache support or replace a healthy baseline', () => {
  const before = request(10000,0);
  const warm = {type:'usage',kind:'cache_warm',provider:'test',model:'model',timestamp:'invalid',usage:before.usage};
  const baseline = scanPrevious([entry(before),warm]);
  assert.equal(baseline.reportedCache,false);
  assert.equal(baseline.timestamp,before.timestamp);
  assert.equal(detectMiss(baseline,request(10000,0)),undefined);
});
test('RPC handler emits the long-idle warning', () => {
  const h = harness();
  h.response(request(10000,0,0,{timestamp:100000+12*60000}));
  assert.deepEqual(h.notices, [['Cache miss after 12m idle: 10k tokens re-billed (~$0.03)', 'warning']]);
});
test('recovery rearms episodes but cooldown prevents flapping; cold boundaries skip one response', () => {
  const original = Date.now;
  let now = 1000000;
  Date.now = () => now;
  try {
    const h = harness();
    h.response(request(10000,0)); assert.equal(h.notices.length,1);
    h.response(request()); // recovery
    now += 1000;
    h.response(request(10000,0)); assert.equal(h.notices.length,1); // cooldown
    h.response(request());
    now += 60000;
    h.response(request(10000,0)); assert.equal(h.notices.length,2);
    for (const boundary of ['session_tree','session_compact']) {
      h.handlers[boundary]();
      h.response(request(10000,0)); assert.equal(h.notices.length,2);
      h.response(request(10000,0)); assert.equal(h.notices.length,3);
      h.notices.pop();
    }
    h.handlers.session_start({reason:'reload'}, h.ctx); // reload reconstructs prior usage without historical notifications
    h.response(request(10000,0)); assert.equal(h.notices.length,3);
  } finally { Date.now = original; }
});
test('TUI, print and JSON modes neither inspect history nor emit notifications', () => {
  for (const mode of ['tui', 'print', 'json']) {
    const h = harness(mode === 'tui', mode);
    h.ctx.sessionManager.getBranch = () => { throw new Error('must not inspect history outside RPC'); };
    h.handlers.session_start({reason:'startup'}, h.ctx);
    h.response(request(10000,0));
    assert.equal(h.notices.length, 0);
    assert.equal(h.audit.length, 0);
  }
});
test('extension registers no commands or context/payload rewriting hooks', () => {
  const h = harness();
  assert.deepEqual(h.commands, {});
  for (const name of ['context', 'context_with_system', 'before_agent_start', 'before_provider_request'])
    assert.equal(h.handlers[name], undefined);
});
test('no UI means no notifications', () => {
  const h = harness(false); h.response(request(10000,0)); assert.equal(h.notices.length,0);
});
