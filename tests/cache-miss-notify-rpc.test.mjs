// Exercises the installed Pi binary, actual OpenAI usage normalization and RPC transport.
// No credentials or external provider calls: only a loopback SSE fixture.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

const binary = process.env.PI_TEST_BINARY ?? '/home/crpier/.local/share/mise/installs/pi/1.5.2/pi/pi';
const extension = fileURLToPath(new URL('../pi-extensions/cache-miss-notify/index.ts', import.meta.url));
for (const scenario of [
  {name:'ordinary requests',idleMs:0},
  {name:'overnight idle',idleMs:2*86400000},
  {name:'overnight + reload + same-model reselection',idleMs:2*86400000,reload:true},
  {name:'overnight + process restart/resume + same-model reselection',idleMs:2*86400000,restart:true},
]) test(`real Pi warning before settlement: ${scenario.name}`, {timeout:30000}, async () => {
  let calls = 0;
  const payloads = [];
  const server = createServer(async (req,res) => {
    let body = '';
    for await (const part of req) body += part;
    payloads.push(JSON.parse(body));
    calls++;
    res.writeHead(200, {'content-type':'text/event-stream'});
    const chunk = value => res.write(`data: ${JSON.stringify({id:'fixture',object:'chat.completion.chunk',created:1,model:'fixture',...value})}\n\n`);
    chunk({choices:[{index:0,delta:{role:'assistant',content:'fixture response'},finish_reason:null}]});
    chunk({choices:[{index:0,delta:{},finish_reason:'stop'}]});
    chunk({choices:[],usage:{prompt_tokens:10000,completion_tokens:2,total_tokens:10002,prompt_tokens_details:{cached_tokens:calls === 1 ? 9000 : 0}}});
    res.end('data: [DONE]\n\n');
  });
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  const dir = await mkdtemp(join(tmpdir(),'pi-cache-notify-'));
  const fixture = join(dir,'provider.ts');
  await writeFile(fixture, `export default function(pi) { pi.registerProvider('cache-fixture', {
    baseUrl:'http://127.0.0.1:${server.address().port}/v1',apiKey:'not-a-secret',api:'openai-completions',
    models:[{id:'fixture',name:'Fixture',reasoning:false,input:['text'],contextWindow:100000,maxTokens:100,
      cost:{input:3,output:15,cacheRead:.3,cacheWrite:3.75}}] });
    // Simulate elapsed idle time without sleeping or changing process clocks.
    pi.on('message_end', (event,ctx) => {
      if (event.message.role === 'assistant' && !ctx.sessionManager.getBranch().some(e=>e.type==='message' && e.message.role==='assistant'))
        return {message:{...event.message,timestamp:event.message.timestamp-${scenario.idleMs}}};
    });
    pi.registerCommand('fixture-reload', {handler:async (_args,ctx)=>{await ctx.reload();}});
  }`);
  const env = {...process.env, PI_CODING_AGENT_DIR:dir, PI_OFFLINE:'1'};
  for (const name of ['PI_SESSION_ID','PI_SESSION_FILE','PI_PROVIDER','PI_MODEL']) delete env[name];
  // Keep history out of agentDir's root: Pi migrates root-level .jsonl files on startup.
  const sessionFile = join(await mkdtemp(join(dir,'history-')),'session.jsonl');
  const events = []; let stderr = '', child, lines;
  const start = () => {
    child = spawn(binary, ['--mode','rpc','--session',sessionFile,'--no-extensions','--no-skills','--no-prompt-templates','--no-context-files','--no-tools','--offline','-e',fixture,'-e',extension,'--model','cache-fixture/fixture'], {cwd:dir,env,stdio:['pipe','pipe','pipe']});
    child.stderr.on('data',d=>stderr+=d);
    lines = createInterface({input:child.stdout});
    lines.on('line',line=>{try { events.push(JSON.parse(line)); } catch {}});
  };
  const stop = async () => {
    child.kill('SIGTERM');
    await new Promise(r=>child.exitCode !== null ? r() : child.once('exit',r));
    lines.close();
  };
  start();
  const wait = async predicate => {
    const deadline = Date.now()+15000;
    while (!predicate()) {
      if (child.exitCode !== null || Date.now()>deadline) throw new Error(`Pi failed/timed out: ${stderr}\n${JSON.stringify(events)}`);
      await new Promise(r=>setTimeout(r,10));
    }
  };
  try {
    for (let i=1;i<=3;i++) {
      if (i === 2 && (scenario.reload || scenario.restart)) {
        if (scenario.restart) {
          const saved = (await readFile(sessionFile,'utf8')).trim().split('\n').map(JSON.parse);
          assert.ok(saved.some(e=>e.type==='message' && e.message.role==='assistant'));
          await stop(); start();
          child.stdin.write(JSON.stringify({id:'restored',type:'get_messages'})+'\n');
          await wait(()=>events.some(e=>e.type==='response' && e.id==='restored'));
          assert.ok(events.find(e=>e.id==='restored').data.messages.some(m=>m.role==='assistant'),'restart must restore persisted conversation');
        }
        else {
          child.stdin.write(JSON.stringify({id:'reload',type:'prompt',message:'/fixture-reload'})+'\n');
          await wait(()=>events.some(e=>e.type==='response' && e.id==='reload'));
        }
        child.stdin.write(JSON.stringify({id:'reselect',type:'set_model',provider:'cache-fixture',modelId:'fixture'})+'\n');
        await wait(()=>events.some(e=>e.type==='response' && e.id==='reselect'));
        assert.equal(events.find(e=>e.type==='response' && e.id==='reselect').success,true);
      }
      child.stdin.write(JSON.stringify({id:`p${i}`,type:'prompt',message:'fixture'})+'\n');
      await wait(()=>events.filter(e=>e.type==='agent_settled').length>=i);
      // Prompt acknowledgment follows settlement; avoid sending while RPC dispatch unwinds.
      await wait(()=>events.some(e=>e.type==='response' && e.id===`p${i}`));
    }
    const notices = events.filter(e=>e.type==='extension_ui_request' && e.method==='notify' && e.notifyType==='warning');
    assert.equal(calls,3);
    const text = p => {
      const content = p.messages[0].content;
      return typeof content === 'string' ? content : content.map(c=>c.text ?? '').join('');
    };
    const original = text(payloads[0]);
    assert.ok(!original.startsWith('Cache diagnostic marker:'));
    assert.equal(text(payloads[1]),original,'extension must not rewrite the system prompt');
    assert.equal(text(payloads[2]),original,'extension must not rewrite subsequent system prompts');
    assert.deepEqual(payloads[1].tools,payloads[0].tools,'tool declarations must be preserved');
    assert.equal(notices.length,1,JSON.stringify({events,stderr}));
    assert.equal(notices[0].notifyType,'warning');
    assert.equal(notices[0].message,scenario.idleMs ? 'Cache miss after 2880m idle: 10k tokens re-billed (~$0.03)' : 'Cache miss: 10k tokens re-billed (~$0.03)');
    const index = events.indexOf(notices[0]);
    assert.equal(events.slice(0,index).filter(e=>e.type==='agent_settled').length,1);
    assert.equal(events[index+1]?.type === 'agent_settled' || events.slice(index+1).some(e=>e.type==='agent_settled'),true);
    assert.equal(events.some(e=>e.type==='extension_error'),false);
    const entries = (await readFile(sessionFile,'utf8')).trim().split('\n').map(JSON.parse);
    const audit = entries.filter(e=>e.type==='custom' && e.customType==='cache-miss-notify').map(e=>e.data);
    assert.ok(audit.some(e=>e.kind==='loaded' && e.revision==='2026-11-10.1'));
    assert.equal(audit.filter(e=>e.kind==='miss' && e.notified).length,1);
    assert.ok(audit.some(e=>e.kind==='miss' && e.suppressed==='episode'));
    console.log(`Verified ${scenario.name}: normalized usage -> warning RPC event before settlement; hidden audit persisted.`);
  } finally {
    await stop(); server.closeAllConnections(); await new Promise(r=>server.close(r));
    await rm(dir,{recursive:true,force:true});
  }
});
