"""服务端管理网页。

为什么要有它：手机屏幕小、网速也不如电脑，而模型动辄几百 MB。有了这个页面，
在 Mac 上就能看状态、选模型、把下载地址复制到迅雷/aria2 之类的加速器里去下，
下完再从浏览器拖回来——不用什么都绕手机一趟。

单文件内联，不引任何 CDN：这台机器很可能正是因为下不动东西才要用加速器。
"""

INDEX = """<!doctype html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>repeat-ai</title>
<style>
:root{--bg:#faf9f7;--fg:#1a1a19;--dim:#6b6a67;--line:#e3e1dd;--card:#fff;--soft:#f2f0ed;
      --ok:#1a7f4b;--warn:#b4541a;--accent:#3b5bdb}
@media (prefers-color-scheme:dark){:root{--bg:#141413;--fg:#eeedeb;--dim:#a3a29e;--line:#2f2e2c;
      --card:#1c1b1a;--soft:#232221;--ok:#4ade80;--warn:#fb923c;--accent:#8da2fb}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);
     font:15px/1.6 -apple-system,BlinkMacSystemFont,"Helvetica Neue",sans-serif}
.wrap{max-width:860px;margin:0 auto;padding:0 18px 64px}

header{position:sticky;top:0;background:var(--bg);padding-top:20px;z-index:5}
.brand{font-size:15px;font-weight:600;letter-spacing:.01em}
.brand small{font-weight:400;color:var(--dim);margin-left:8px;font-size:13px}
nav{display:flex;gap:2px;margin-top:14px;border-bottom:1px solid var(--line)}
nav a{padding:8px 14px;font-size:14px;color:var(--dim);text-decoration:none;
      border-bottom:2px solid transparent;margin-bottom:-1px}
nav a.on{color:var(--fg);border-bottom-color:var(--accent);font-weight:600}
.tab{display:none;padding-top:22px}
.tab.on{display:block}

.dot{display:inline-block;width:7px;height:7px;border-radius:99px;background:var(--ok);
     margin-right:7px;vertical-align:1px}
.statline{color:var(--dim);font-size:13px}

h2{font-size:12px;text-transform:uppercase;letter-spacing:.09em;color:var(--dim);
   margin:26px 0 10px;font-weight:600}
.box{background:var(--card);border:1px solid var(--line);border-radius:10px}
.box>.row{display:flex;flex-wrap:wrap;gap:10px;align-items:center;
          padding:11px 14px;border-top:1px solid var(--line)}
.box>.row:first-child{border-top:none}
.row .k{width:56px;color:var(--dim);font-size:13px;flex:none}
.row .v{flex:1;min-width:150px}
.row .hint{width:100%;color:var(--warn);font-size:12px;margin-top:-4px}
select,input{font:inherit;font-size:13px;padding:5px 8px;border-radius:7px;
             border:1px solid var(--line);background:var(--bg);color:var(--fg);max-width:100%}
select{min-width:210px}
button{font:inherit;font-size:13px;padding:5px 12px;border-radius:7px;border:1px solid var(--line);
       background:transparent;color:var(--fg);cursor:pointer}
button:hover{border-color:var(--accent);color:var(--accent)}
button:disabled{opacity:.45;cursor:default;border-color:var(--line);color:var(--dim)}
button.danger:hover{border-color:var(--warn);color:var(--warn)}
code{background:var(--soft);border-radius:4px;padding:1px 6px;font-size:13px}

.stats{display:flex;flex-wrap:wrap;gap:0}
.stat{flex:1;min-width:96px;padding:12px 14px;border-left:1px solid var(--line)}
.stat:first-child{border-left:none}
.stat b{display:block;font-size:19px;font-weight:600;font-variant-numeric:tabular-nums}
.stat span{font-size:12px;color:var(--dim)}
.stat.hot b{color:var(--warn)}

.m{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:13px 15px;margin-bottom:9px}
.mh{display:flex;flex-wrap:wrap;gap:8px;align-items:baseline}
.name{font-weight:600}
.meta{color:var(--dim);font-size:13px}
.tag{font-size:11px;padding:1px 7px;border-radius:99px;border:1px solid var(--line);color:var(--dim)}
.tag.only{border-color:var(--accent);color:var(--accent)}
.tag.use{border-color:var(--ok);color:var(--ok)}
.st{margin-left:auto;font-size:13px;font-weight:600}
.st.ok{color:var(--ok)}.st.no{color:var(--warn)}
.acts{margin-top:10px;display:flex;flex-wrap:wrap;gap:7px}
.panel{margin-top:10px;padding-top:10px;border-top:1px dashed var(--line);display:none}
.panel.open{display:block}
.u{display:flex;gap:8px;align-items:center;font-size:12px;
   font-family:ui-monospace,SFMono-Regular,Menlo,monospace;padding:3px 0}
.u span{overflow-wrap:anywhere;flex:1;color:var(--dim)}
.u b{color:var(--warn);font-weight:600;font-size:11px;white-space:nowrap}
.prog{margin-top:8px;font-size:12px;color:var(--dim)}
.bar{height:3px;background:var(--line);border-radius:2px;overflow:hidden;margin-top:4px}
.bar i{display:block;height:100%;background:var(--accent);width:0;transition:width .15s}
.drop{margin-top:8px;border:1.5px dashed var(--line);border-radius:8px;padding:14px;
      text-align:center;color:var(--dim);font-size:13px}
.drop.hot{border-color:var(--accent);color:var(--accent)}
.err{color:var(--warn);font-size:13px;margin-top:6px}
.note{color:var(--dim);font-size:12.5px;margin-top:8px}
</style>
</head>
<body>
<div class="wrap">
<header>
  <div class="brand">repeat-ai <small id="brandsub"></small></div>
  <nav>
    <a href="#overview" data-t="overview">概览</a>
    <a href="#models" data-t="models">模型</a>
    <a href="#settings" data-t="settings">设置</a>
  </nav>
</header>

<div class="tab" id="t-overview">
  <div class="statline" id="status">加载中…</div>

  <h2>当前生效</h2>
  <div class="box" id="sel"></div>
  <div class="note">这三个由服务器决定。手机上只显示、改不了——模型装在这台机器上，
    手机的清单里没有服务端专属的大模型。</div>

  <h2>手机连接</h2>
  <div class="box"><div class="row">
    <code id="lan">…</code>
    <button id="copylan">复制</button>
    <span class="meta">填到手机「AI 模型 → 远程推理 → 服务地址」</span>
  </div><div class="row">
    <code id="ttsurl">…</code>
    <button id="copytts">复制</button>
    <span class="meta">朗读链接：填到悬浮球「自定义动作 → 朗读 → TTS 设置 → TTS 服务链接」，每次实时合成</span>
  </div><div class="row">
    <code id="chaturl">…</code>
    <button id="copychat">复制</button>
    <span class="meta">问答地址：填到悬浮球「自定义动作 → 联网 → 服务地址」，要装一个通用 LLM（如 Qwen）</span>
  </div></div>

  <h2>最近推理</h2>
  <div class="box stats" id="stats"></div>
</div>

<div class="tab" id="t-models"><div id="list"></div></div>

<div class="tab" id="t-settings">
  <h2>下载源</h2>
  <div class="box">
    <div class="row">
      <span class="k">来源</span>
      <select id="src">
        <option value="official">官方（HuggingFace / GitHub 直连）</option>
        <option value="cn">国内镜像（hf-mirror.com + ghfast.top）</option>
        <option value="custom">自定义…</option>
      </select>
    </div>
    <div class="row" id="srccustom" hidden>
      <span class="k">自定义</span>
      <input id="hf" placeholder="hf 镜像域名" size="18">
      <input id="gh" placeholder="GitHub 加速前缀" size="22">
      <button id="srcsave">保存</button>
    </div>
  </div>
  <div class="note">切换后「模型」页列出的链接会按新源改写——展示的和服务端真会去下的是同一个地址。</div>

  <h2>运行环境</h2>
  <div class="box">
    <div class="row"><span class="k">目录</span><code id="root">…</code></div>
    <div class="row"><span class="k">线程</span><span id="threads">…</span>
      <span class="meta">默认 min(8, CPU 核数)，改 REPEAT_AI_THREADS 环境变量</span></div>
    <div class="row"><span class="k">清单</span><span class="meta" id="cver">…</span></div>
  </div>
</div>
</div>

<script>
const $ = (s,r)=>(r||document).querySelector(s);
const $$ = (s,r)=>[...(r||document).querySelectorAll(s)];
const MB = b => b>=1048576 ? (b/1048576).toFixed(0)+' MB' : (b/1024).toFixed(0)+' KB';
const ROLES = {asr:'识别', mt:'翻译', tts:'合成', vad:'判停'};
let DATA=null, SEL=null;

// ---- 标签页。用 hash 记住当前页，刷新不跳回概览（下载/上传时最容易踩到）
function tab(name){
  name = ['overview','models','settings'].includes(name) ? name : 'overview';
  $$('nav a').forEach(a=>a.classList.toggle('on', a.dataset.t===name));
  $$('.tab').forEach(t=>t.classList.toggle('on', t.id==='t-'+name));
}
addEventListener('hashchange', ()=>tab(location.hash.slice(1)));

async function load(){
  DATA = await (await fetch('/v1/catalog')).json();
  SEL  = await (await fetch('/v1/selection')).json();
  $('#brandsub').textContent = `${DATA.lan}:${DATA.port}`;
  $('#status').innerHTML = `<span class="dot"></span>运行中 · ${DATA.threads} 线程 · `
    + `已装 ${DATA.models.filter(m=>m.ok).length}/${DATA.models.length} · 占用 ${MB(DATA.diskUsage)}`;
  $('#lan').textContent = `http://${DATA.lan}:${DATA.port}`;
  $('#ttsurl').textContent = `http://${DATA.lan}:${DATA.port}/v1/tts`;
  $('#chaturl').textContent = `http://${DATA.lan}:${DATA.port}/v1/chat`;
  $('#root').textContent = DATA.root;
  $('#threads').textContent = DATA.threads;
  $('#cver').textContent = `v${DATA.catalogVersion} · ${DATA.models.length} 个模型`
    + `（含 ${DATA.models.filter(m=>m.localOnly).length} 个仅服务端）`;
  renderSel(); renderModels(); initSource(); loadStats();
  // 只在**真有任务在跑**时才起轮询。以前这里判的是"downloads 非空"，
  // 而 done/failed 的任务会一直留在里面，于是 load->poll->load 无限互调，
  // 一秒能打十几个请求。
  const jobs = await fetch('/v1/downloads').then(r=>r.json());
  if(Object.values(jobs).some(j=>j.state==='running')) startPoll();
}

// ---- 概览：当前生效
function renderSel(){
  const box = $('#sel'); box.innerHTML='';
  for(const role of ['asr','mt','tts']){
    const r = SEL.resolved[role];
    const opts = DATA.models.filter(m=>m.roles.includes(role) && m.ok);
    const row = document.createElement('div'); row.className='row';
    row.innerHTML = `<span class="k">${ROLES[role]}</span>
      <span class="v">${opts.length
        ? `<select data-role="${role}">${opts.map(m=>
            `<option value="${m.id}" ${r&&r.id===m.id?'selected':''}>${m.name}</option>`).join('')}</select>`
        : '<span style="color:var(--warn)">没有已安装的模型 — 去「模型」页装一个</span>'}</span>
      ${r&&r.fellBack?`<span class="hint">存的是 ${SEL[role]}，它现在担不了这个角色（被删了，或者本来就不支持），实际用的是 ${r.name}</span>`:''}`;
    box.appendChild(row);
  }
  // 多音色模型才显示这一行（MeloTTS 只有一个音色，摆着只会让人以为能换）
  const t = SEL.resolved.tts;
  if(t && t.speakers>1){
    const row = document.createElement('div'); row.className='row';
    row.innerHTML = `<span class="k">音色</span><span class="v">
      <select id="sid">${Array.from({length:t.speakers},(_,i)=>
        `<option value="${i}" ${i===SEL.ttsSid?'selected':''}>${(t.voices||[])[i]||i}</option>`).join('')}</select>
      </span><span class="meta">${t.name} 有 ${t.speakers} 个音色</span>`;
    box.appendChild(row);
  }
  box.onchange = async e=>{
    const s = e.target;
    const body = new FormData();
    if(s.dataset.role){ body.append('role', s.dataset.role); body.append('model', s.value); }
    else if(s.id==='sid'){ body.append('ttsSid', s.value); }
    else return;
    const r = await fetch('/v1/selection', {method:'POST', body});
    if(!r.ok){ alert((await r.json()).error); return; }
    SEL = await r.json(); renderSel(); renderModels();
  };
}

async function loadStats(){
  const s = await (await fetch('/v1/stats')).json();
  const box = $('#stats');
  if(!s.count){
    box.innerHTML = '<div class="stat"><span>还没跑过推理。手机上录一段就有了。</span></div>';
    return;
  }
  // 哪一步最慢就标红——"到底卡在哪"是这条链路上最常问的问题
  const worst = Math.max(s.asrMs, s.mtMs, s.ttsMs);
  const cell = (v,label,hot) =>
    `<div class="stat ${hot?'hot':''}"><b>${v}</b><span>${label}</span></div>`;
  box.innerHTML =
      cell(s.count, '次') + cell(s.totalMs+' ms', '平均总耗时')
    + cell(s.asrMs+' ms', '识别', s.asrMs===worst)
    + cell(s.mtMs+' ms', '翻译', s.mtMs===worst)
    + cell(s.ttsMs+' ms', '合成', s.ttsMs===worst);
}

// ---- 模型页
function renderModels(){
  const list = $('#list'); list.innerHTML = '';
  for (const role of ['asr','mt','tts','vad']){
    const ms = DATA.models.filter(m=>m.roles.includes(role));
    if(!ms.length) continue;
    const h = document.createElement('h2'); h.textContent = ROLES[role]; list.appendChild(h);
    for(const m of ms) list.appendChild(card(m, role));
  }
}

function usedFor(m){
  return ['asr','mt','tts'].filter(r=>SEL.resolved[r] && SEL.resolved[r].id===m.id);
}

function card(m, role){
  const el = document.createElement('div'); el.className='m'; el.dataset.id = m.id;
  const miss = m.missing.length, used = usedFor(m);
  el.innerHTML = `
    <div class="mh">
      <span class="name">${m.name}</span>
      <span class="meta">${MB(m.size)}</span>
      ${m.localOnly?'<span class="tag only">仅服务端</span>':''}
      ${used.map(r=>`<span class="tag use">✓ ${ROLES[r]}</span>`).join('')}
      <span class="st ${m.ok?'ok':'no'}">${m.ok?'已安装':(miss?`缺 ${miss} 个文件`:'未安装')}</span>
    </div>
    ${m.note?`<div class="meta">${m.note}</div>`:''}
    ${!m.ok && !m.downloadable
      ? '<div class="meta" style="color:var(--warn)">这个模型要先转格式，下载器装不了 — 在 server/ai 下跑 <code>python setup_mt.py</code></div>'
      : ''}
    <div class="acts">
      ${m.ok ? m.roles.filter(r=>r!=='vad' && !used.includes(r))
                 .map(r=>`<button data-a="use" data-r="${r}">设为${ROLES[r]}</button>`).join('') : ''}
      ${m.ok || !m.downloadable ? '' : '<button data-a="dl">下载</button>'}
      ${m.urls.length ? `<button data-a="urls">下载链接 (${m.urls.length})</button>` : ''}
      <button data-a="up">上传文件…</button>
      ${m.ok?'<button class="danger" data-a="del">删除</button>':''}
    </div>
    <div class="prog" data-p="dl" hidden><span></span><div class="bar"><i></i></div></div>
    <div class="panel" data-p="urls">
      <div class="acts"><button data-a="copyall">复制全部链接</button></div>
      ${m.urls.map(u=>`<div class="u"><span>${u.url}</span>${u.have?'':'<b>缺</b>'}
        <button data-a="copy" data-u="${u.url}">复制</button></div>`).join('')}
    </div>
    <div class="panel" data-p="up">
      <div class="drop">把下好的文件拖到这里，或 <button data-a="pick">选择文件</button><br>
        <span style="font-size:12px">按文件名自动归位，不用还原目录结构${
          m.archive?'；压缩包直接丢进来会自动解压':''}</span></div>
      <input type="file" multiple hidden>
      <div class="prog" hidden><span></span><div class="bar"><i></i></div></div>
      <div class="err" hidden></div>
    </div>`;

  el.addEventListener('click', async e=>{
    const b = e.target.closest('button'); if(!b) return;
    const a = b.dataset.a;
    if(a==='urls'||a==='up'){ $(`.panel[data-p="${a}"]`, el).classList.toggle('open'); return; }
    if(a==='copy'){ await copy(b.dataset.u, b); return; }
    if(a==='copyall'){ await copy(m.urls.map(u=>u.url).join('\\n'), b); return; }
    if(a==='pick'){ $('input[type=file]', el).click(); return; }
    if(a==='use'){
      const body = new FormData(); body.append('role', b.dataset.r); body.append('model', m.id);
      const r = await fetch('/v1/selection', {method:'POST', body});
      if(!r.ok){ alert((await r.json()).error); return; }
      SEL = await r.json(); renderSel(); renderModels(); return;
    }
    if(a==='dl'){
      const r = await fetch(`/v1/models/${m.id}/download`, {method:'POST'});
      if(!r.ok){ alert((await r.json()).error || '启动失败'); return; }
      startPoll(); return;
    }
    if(a==='cancel'){
      // 取消不是立刻生效：下载线程卡在 socket 读上，最多要十几秒才醒过来。
      // 不给反馈的话用户会以为按钮没反应，接着猛点。
      b.disabled = true; b.textContent = '取消中…';
      await fetch(`/v1/models/${m.id}/cancel`, {method:'POST'});
      return;
    }
    if(a==='del'){
      const u = usedFor(m);
      const warn = u.length ? `\\n\\n它正被用作${u.map(r=>ROLES[r]).join('、')}，删掉后会自动换成别的已装模型。` : '';
      if(!confirm(`删除 ${m.name}？服务器上的 ${MB(m.size)} 会被清掉。${warn}`)) return;
      await fetch(`/v1/models/${m.id}`, {method:'DELETE'}); await load(); return;
    }
  });

  const input = $('input[type=file]', el);
  input.addEventListener('change', ()=>upload(m, [...input.files], el));
  const drop = $('.drop', el);
  drop.addEventListener('dragover', e=>{e.preventDefault(); drop.classList.add('hot');});
  drop.addEventListener('dragleave', ()=>drop.classList.remove('hot'));
  drop.addEventListener('drop', e=>{
    e.preventDefault(); drop.classList.remove('hot'); upload(m, [...e.dataTransfer.files], el);
  });
  return el;
}

async function copy(text, btn){
  try{ await navigator.clipboard.writeText(text); }
  catch(_){ const t=document.createElement('textarea'); t.value=text; document.body.appendChild(t);
            t.select(); document.execCommand('copy'); t.remove(); }
  const old = btn.textContent; btn.textContent='已复制';
  setTimeout(()=>btn.textContent=old, 1200);
}

async function upload(m, files, el){
  if(!files.length) return;
  const prog = $('.panel[data-p="up"] .prog', el), bar = $('.panel[data-p="up"] .bar i', el);
  const err = $('.err', el), label = $('.panel[data-p="up"] .prog span', el);
  prog.hidden = false; err.hidden = true; bar.style.width='0';
  for(let i=0;i<files.length;i++){
    const f = files[i];
    label.textContent = `上传 ${i+1}/${files.length} · ${f.name} (${MB(f.size)})`;
    try{
      await put(`/v1/models/${m.id}/import`, f, p=>{
        bar.style.width = ((i + p) / files.length * 100).toFixed(1)+'%';
      });
    }catch(e){
      err.hidden=false; err.textContent = `${f.name}: ${e.message}`; prog.hidden=true; return;
    }
  }
  label.textContent = '校验中…';
  const d = await (await fetch(`/v1/models/${m.id}/complete`, {method:'POST'})).json();
  prog.hidden = true;
  if(!d.ok){ err.hidden=false; err.textContent = `还缺 ${d.missing.length} 个：${d.missing.join(', ')}`; }
  await load();
}

// 用 XHR 而不是 fetch：只有它能报上传进度，几百 MB 的文件没进度条没法用
function put(url, file, onProgress){
  return new Promise((res, rej)=>{
    const fd = new FormData(); fd.append('data', file, file.name);
    const x = new XMLHttpRequest();
    x.open('POST', url);
    x.upload.onprogress = e => e.lengthComputable && onProgress(e.loaded/e.total);
    x.onload = ()=> x.status<300 ? res() : rej(new Error(safeErr(x.responseText, x.status)));
    x.onerror = ()=> rej(new Error('网络中断'));
    x.send(fd);
  });
}
function safeErr(t, code){ try{ return JSON.parse(t).error || ('HTTP '+code); }catch(_){ return 'HTTP '+code; } }

// 有任务在跑就 1 秒一轮询。没有任务时完全不发请求，别白占带宽。
//
// polling 这个单飞标志是必须的：poll 结束时要刷新一次列表（下完的模型状态变了），
// 而 load 又会决定要不要起轮询——两边不设防就会无限互相调用。
let timer = null, polling = false;
function startPoll(){
  if(polling) return;
  polling = true;
  poll();
}
async function poll(){
  const jobs = await (await fetch('/v1/downloads')).json();
  let running = false;
  for(const m of DATA.models){
    const el = document.querySelector(`[data-id="${m.id}"]`);
    if(!el) continue;
    const box = $('.prog[data-p="dl"]', el), j = jobs[m.id];
    if(!j){ box.hidden = true; continue; }
    box.hidden = false;
    const label = $('span', box), bar = $('.bar i', box);
    if(j.state === 'running'){
      running = true;
      label.innerHTML = `下载中 ${j.fileIndex+1}/${j.fileTotal} · ${j.file} · `
        + `${MB(j.done)}${j.total?' / '+MB(j.total):''} `
        + ($('button[data-a=cancel]', box)?.disabled
            ? '<button data-a="cancel" disabled>取消中…</button>'
            : '<button data-a="cancel">取消</button>');
      bar.style.width = (j.total ? j.done/j.total*100 : 0).toFixed(1)+'%';
    } else if(j.state === 'failed'){
      label.innerHTML = `<span style="color:var(--warn)">下载失败：${j.error}</span>`
        + ` — 下不动就用上面的链接丢进加速器，下完从「上传文件」传回来`;
      bar.style.width = '0';
    } else if(j.state === 'done'){ label.textContent = '已完成'; }
  }
  clearTimeout(timer);
  if(running){
    timer = setTimeout(poll, 1000);
    return;
  }
  // 全跑完了：停掉轮询，再刷一次列表（装好的模型状态、磁盘占用都变了）。
  // 先把 polling 放掉，load 里那句 startPoll 才可能在有新任务时重新接上。
  polling = false;
  await load();
}

// ---- 下载源
function initSource(){
  const s = $('#src'), custom = $('#srccustom');
  s.value = DATA.source.kind;
  $('#hf').value = DATA.source.hfHost || '';
  $('#gh').value = DATA.source.ghPrefix || '';
  custom.hidden = s.value !== 'custom';
  s.onchange = async () => {
    custom.hidden = s.value !== 'custom';
    if(s.value !== 'custom') await saveSource();
  };
  $('#srcsave').onclick = saveSource;
}
async function saveSource(){
  const fd = new FormData();
  fd.append('kind', $('#src').value);
  fd.append('hfHost', $('#hf').value.trim());
  fd.append('ghPrefix', $('#gh').value.trim());
  await fetch('/v1/source', {method:'POST', body: fd});
  await load();   // 链接要按新源重新改写
}

$('#copylan').onclick = e => copy($('#lan').textContent, e.target);
$('#copytts').onclick = e => copy($('#ttsurl').textContent, e.target);
$('#copychat').onclick = e => copy($('#chaturl').textContent, e.target);
tab(location.hash.slice(1));
load();
// 手机在录音时这几个数字会动。切到别的标签页就停——没人看的时候没必要发请求。
setInterval(() => { if(!document.hidden) loadStats(); }, 5000);
</script>
</body></html>
"""
